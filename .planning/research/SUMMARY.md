# Project Research Summary

**Project:** Kindred v5.1 — Gap Closure
**Domain:** iOS cooking app (SwiftUI + TCA) — closing five deferred v5.0 gaps
**Researched:** 2026-04-12
**Confidence:** HIGH

## Executive Summary

Kindred v5.0 shipped with five documented gaps that must close before the next App Store submission: free-tier voice narration (all users hit ElevenLabs and fail silently), voice tier routing (no gate between free and Pro audio paths), per-recipe `sourceUrl` attribution (Spoonacular ToS compliance), search UI (backend endpoint exists but iOS has no wiring), and dietary filter pass-through (client-side only against a 20-card cache). All five are verified against live codebase source — no backend work is required for any of them. The backend `searchRecipes` resolver, `sourceUrl` field, and dietary filter params are already deployed and operational.

The recommended approach is a four-phase build ordered by dependency chain. `sourceUrl` wiring is independent and touches the fewest files — do it first to clear Spoonacular attribution risk. AVSpeechSynthesizer integration and tier routing come next because all three voice-related pitfalls (audio session conflicts, iOS 17 silent failure, orphaned stream observers) must be designed out before search work begins. Search UI and dietary filter pass-through share a single `SearchRecipesQuery` GraphQL operation and a `FeedMode` state enum, so they belong together in the same phase to avoid running Apollo codegen twice and to prevent dual-list corruption in `FeedReducer`.

The primary risks are not implementation complexity but platform instability: `AVSpeechSynthesizer` on iOS 17.0–17.4 has two documented Apple-acknowledged bugs (silent failure without delegate error, audio session interference with AVPlayer) that require defensive coding as first-class acceptance criteria, not afterthoughts. Spoonacular's 150-request-per-day quota will be exhausted within minutes if search is wired without 500ms debounce and cache-first validation. These are the two issues most likely to cause a production incident within days of shipping.

## Key Findings

### Recommended Stack

No new SPM packages are needed for any v5.1 feature. All five gaps close within the existing tech stack (SwiftUI + TCA, Apollo iOS 2.0.6, AVFoundation, StoreKit 2). The only new code artifact is an `AVSpeechClient.swift` TCA dependency (~80 lines) mirroring the existing `AudioPlayerClient` pattern.

**Core technologies:**
- `AVSpeechSynthesizer` (iOS 17+, built-in AVFoundation): Free-tier TTS narration — zero cost, offline-capable, already linked. Use Enhanced voice (`AVSpeechSynthesisVoice.quality == .enhanced`) with Compact fallback. No new package; framework already imported in `AudioPlayerManager.swift`.
- Apollo iOS codegen (2.0.6, existing): Generates `SearchRecipesQuery` and updated `RecipeDetailQuery` — no version bump needed. Add `.graphql` operation files and re-run `apollo-ios-cli generate` from `Kindred/Packages/KindredAPI/`.
- `VoicePlaybackReducer` routing (existing TCA): Single branch on `subscriptionStatus` in `selectVoice` action dispatches to `AVSpeechClient` (free/unknown) or the existing ElevenLabs/AVPlayer path (Pro).

### Expected Features

**Must have (table stakes — v5.1 launch blockers):**
- AVSpeechSynthesizer narration path — free users currently hear nothing; this destroys the app's core hook for the majority of users before they can evaluate upgrading
- Voice tier routing gate — wrong routing silently gives Pro users system TTS instead of ElevenLabs (conversion funnel break)
- `sourceUrl` + `sourceName` attribution in RecipeDetailView — Spoonacular ToS compliance, potential App Store rejection if audited; field exists in backend `recipe.model.ts:154` but is missing from the iOS GraphQL query selection set
- Search UI wired to `searchRecipes` backend — a search bar that does nothing is worse than no search bar; backend resolver is deployed and accepts `query`, `diets`, `intolerances`, `cuisines`, `first`, `after`
- Dietary filter pass-through to `searchRecipes` — current client-side filter on 20 popular cards returns 0 results for specific diets ("Vegan + Keto"); this is a hidden bug, not a missing feature

**Should have (competitive advantage):**
- `FeedMode` enum (`browse` / `search`) in `FeedReducer.State` — prevents dual-list corruption when toggling between popular feed and search results
- `DietaryTagMapper` utility — classifies Kindred chip tags into Spoonacular `diet` param (one value allowed, use most restrictive) vs. `intolerances` param (comma-separated, supports multiple)
- Enhanced AVSpeech voice (`quality == .enhanced`) — meaningfully better than Compact; auto-downloaded on iOS 16+; fall back gracefully if not present

**Defer to v5.2+:**
- Step-sync for AVSpeech (`willSpeakRangeOfSpeechString` delegate) — word-boundary step highlighting; add only after AVSpeech adoption is confirmed working on real devices
- Search result pantry match % badge — requires async join with local pantry; not blocking v5.1
- Persistent search history in UserDefaults — low urgency; add when user demand is confirmed

**Defer to v6+:**
- Natural language dietary search via LLM prompt → `SearchRecipesInput` — adds latency and cost
- Cuisine + meal-type filter chips in search — surface area expansion, not blocking

### Architecture Approach

The five gaps map to four independent change clusters that each touch distinct parts of the codebase with no cross-cutting side effects. `sourceUrl` is a pure GraphQL selection + model + view change. AVSpeechSynthesizer introduces a new TCA `@DependencyClient` (`AVSpeechClient`) alongside the existing `AudioPlayerClient` — not a replacement — and a tier branch in `VoicePlaybackReducer.selectVoice`. Search lives in a new `Search/` sibling folder inside `FeedFeature` (new `SearchReducer` + `SearchView`) to avoid bloating the already 900-line `FeedReducer`. Dietary filter pass-through reuses `SearchRecipesQuery` from the search phase and adds a `FeedMode` branch to `FeedReducer`.

**Major components:**
1. `AVSpeechClient.swift` (NEW in `VoicePlaybackFeature/Sources/AudioPlayer/`) — TCA `@DependencyClient` wrapping `AVSpeechSynthesizer`; exposes `speak([String])`, `pause`, `resume`, `stop`, `statusStream: AsyncStream<PlaybackStatus>`, `progressStream: AsyncStream<Double>`. Must call `synthesizer.speak()` via `await MainActor.run {}`.
2. `VoicePlaybackReducer.swift` (MODIFY) — Adds `currentAudioBackend: AudioBackend` (`.avSpeech` / `.avPlayer` / `.none`) to `State`. Tier check in `selectVoice`: cancels all three `CancelID` stream observers unconditionally before routing. `subscriptionStatus == .free || voiceId == "kindred-default"` → `AVSpeechClient` path; else → existing ElevenLabs/AVPlayer path.
3. `SearchReducer.swift` + `SearchView.swift` (NEW in `FeedFeature/Sources/Search/`) — Independent TCA feature presented from `FeedReducer` via `@Presents`. Holds `query`, `results`, `isLoading`, `error`. Fires `SearchRecipesQuery` after 500ms debounce + 3-char minimum.
4. `FeedReducer.swift` (MODIFY) — Adds `FeedMode` enum. `dietaryFilterChanged` in `.browse` mode keeps client-side filter (instant). In `.search` mode re-triggers debounced `SearchRecipesQuery` with diet mapping via `DietaryTagMapper`.

### Critical Pitfalls

1. **AVSpeechSynthesizer deactivates the shared `AVAudioSession`, breaking subsequent AVPlayer playback** — After AVSpeech narration ends, call `try? AVAudioSession.sharedInstance().setActive(true)` before each AVPlayer `play()`. Never run both backends simultaneously. Use `currentAudioBackend` state as a mutex.

2. **iOS 17.0–17.4 silent AVSpeech failure: `didFinish` fires immediately but no audio was produced** — Platform bug (TTSErrorDomain Code -4010), no Apple workaround. Mitigate with duration validation: if `didFinish` fires in under 40% of expected time (`word_count / 2.5` seconds), surface an error state. Add 3-second `didStart` timeout. Simulator does not reproduce this — test on real iOS 17.0 and 17.6 devices.

3. **Orphaned stream observers when switching audio backends mid-session** — Cancel all `CancelID` values (`timeObserver`, `statusObserver`, `durationObserver`, new `speechObserver`) unconditionally at the start of `selectVoice` before dispatching to either backend. Write a TCA test for the race condition: `selectVoice("kindred-default")` immediately followed by `selectVoice("elevenlabs-id")` — assert no orphaned `.timeUpdated` actions arrive after switch.

4. **Search on every keystroke exhausts Spoonacular 150 req/day quota within minutes** — 500ms debounce + 3-char minimum are non-negotiable. Verify backend `SpoonacularCacheService.normalizeCacheKey` includes dietary filter params in its cache key. Check that identical query+filter combinations hit PostgreSQL cache rather than calling Spoonacular.

5. **Spoonacular `diet` param accepts only one value; multi-diet selection silently drops all but the first** — `SpoonacularService.search()` already has `params.diet = filters.diets[0]` (one value, by design). Map Kindred chip tags: intolerance-type tags (`Gluten-Free`, `Dairy-Free`, `Nut-Free`) go to `intolerances` param (comma-separated, supports multiple); diet-type tags (`Vegan`, `Vegetarian`, `Keto`, etc.) go to `diet` param (most restrictive if multiple selected).

6. **`FeedMode` omission causes dual-list corruption in `FeedReducer`** — Without `.browse` vs. `.search` mode, `allRecipes` and search results compete to populate `cardStack`. Result: duplicate cards, inconsistent ordering, undo-swipe restores wrong card. Define `FeedMode` in `State` before writing any filter or search logic.

## Implications for Roadmap

Based on the dependency graph and pitfall landscape, four phases are recommended:

### Phase 1: sourceUrl Attribution Wiring
**Rationale:** Zero dependencies on other v5.1 features. Touches the fewest files (four). Clears the Spoonacular ToS compliance risk immediately. Apollo codegen runs once here for `RecipeDetailQuery` — this is isolated from the `SearchRecipesQuery` codegen in Phase 3.
**Delivers:** `sourceUrl` and `sourceName` displayed in `RecipeDetailView` as a tappable `Link` to the original recipe source. Nil-safe: falls back to static "Powered by Spoonacular" text when field is null.
**Addresses:** Spoonacular attribution gap (ToS compliance, potential App Store rejection risk)
**Files touched:** `RecipeQueries.graphql`, `RecipeDetailQuery.graphql.swift` (regenerated), `RecipeDetailModels.swift`, `RecipeDetailView.swift`
**Avoids:** Apollo codegen pitfall — run codegen before touching Swift; verify backend schema first (`recipe.model.ts:154`)
**Research flag:** Skip — well-documented GraphQL field addition pattern already used in this project.

### Phase 2: AVSpeechClient + Voice Tier Routing
**Rationale:** The audio session interaction between `AVSpeechSynthesizer` and `AVPlayer` is the highest-risk integration in v5.1. This phase must be completed and hardware-validated before any other feature ships. The `currentAudioBackend` state enum and stream cancellation design must be in place before search work begins — not because of a code dependency but because the audio session is a shared process resource.
**Delivers:** Free-tier users hear recipe steps via system TTS. Pro users continue to receive ElevenLabs cloned voices. The voice picker hides cloned voice slots from free-tier users (only "Built-in Narration" shown). Background audio limitation communicated proactively (tooltip + screen-awake fallback).
**Addresses:** Free-tier narration (table stakes), voice tier routing (conversion funnel dependency)
**Uses:** `AVSpeechClient.swift` (new TCA `@DependencyClient`), `VoicePlaybackReducer.selectVoice` tier branch, `currentAudioBackend: AudioBackend` in `State`
**Avoids:** Audio session deactivation pitfall (Pitfall 1), iOS 17 silent failure pitfall (Pitfall 2), orphaned stream observer pitfall (Pitfall 3), background audio asymmetry pitfall (Pitfall 4)
**Acceptance criteria must include:** Test on iOS 17.0 real device. `didStart` fires within 3 seconds. Duration validation against expected word count. Free → switch to Pro voice → AVPlayer plays correctly without session reinit.
**Research flag:** Skip — all edge cases fully documented in ARCHITECTURE.md and PITFALLS.md with concrete code patterns.

### Phase 3: Search UI + Dietary Filter Pass-Through
**Rationale:** Search and dietary filter pass-through share one `SearchRecipesQuery` GraphQL operation and the `FeedMode` state enum. Separating them would require two Apollo codegen runs and risks `FeedMode` inconsistency. Build `FeedMode` enum first, then `SearchReducer`/`SearchView`, then dietary filter pass-through as a sub-task within the same phase.
**Delivers:** Text search bar in `FeedView` with backend-powered results. Dietary filter chips trigger `searchRecipes` with mapped Spoonacular params instead of client-side filtering against 20 cached cards. `FeedMode.browse` preserves instant client-side filter for the popular feed; `FeedMode.search` uses backend results.
**Addresses:** Search UI (table stakes), dietary filter pass-through (hidden bug)
**Uses:** `SearchQueries.graphql` (new), `SearchRecipesQuery.graphql.swift` (Apollo generated), `SearchReducer.swift` (new), `SearchView.swift` (new), `FeedMode` enum in `FeedReducer.State`, `DietaryTagMapper` utility
**Avoids:** Quota exhaustion pitfall — 500ms debounce + 3-char minimum (Pitfall 8); dual-list corruption — FeedMode enforces single source of truth (Pitfall 9); multi-diet Spoonacular param — intolerance vs. diet classification (Pitfall 7)
**Research flag:** Skip — backend endpoints confirmed deployed. During implementation: verify `SpoonacularCacheService.normalizeCacheKey` includes `diets` and `intolerances` in its cache key.

### Phase 4: End-to-End Verification on Real Devices
**Rationale:** Platform bugs and interaction effects (audio session hand-off, Spoonacular quota, iOS 17 TTS audio unit failures) cannot be caught in unit tests or Simulator. A dedicated verification pass validates the complete user journey on hardware.
**Delivers:** Release-ready v5.1 build. All five gaps confirmed closed on real iOS 17.0 and iOS 18.x devices. Quota stress test passed (search debounce active, backend logs show single Spoonacular call per search). Attribution links open correct URLs. "Looks Done But Isn't" checklist from PITFALLS.md cleared.
**Addresses:** Background audio UX (proactive tooltip + `isIdleTimerDisabled` while narrating), `sourceUrl` nil handling, empty search state UI, AVSpeech duration validation
**Research flag:** Skip — acceptance criteria explicitly documented in PITFALLS.md "Looks Done But Isn't" checklist.

### Phase Ordering Rationale

- `sourceUrl` first because it is the most independent change with the lowest implementation risk and clears a compliance obligation immediately.
- AVSpeechSynthesizer before search because audio session correctness is a shared process concern that cannot be retroactively validated; the `currentAudioBackend` state design affects reducer architecture globally.
- Search and dietary filter in the same phase because they share one GraphQL operation file, one state enum, and one `DietaryTagMapper` utility — splitting them doubles codegen overhead and risks `FeedMode` inconsistency.
- Dedicated hardware verification last because iOS 17 platform bugs require real-device time that is separate from implementation confidence; this is not a perfunctory QA step.

### Research Flags

Phases needing `/gsd:research-phase` during planning:
- None — all four phases have sufficient research from live codebase inspection. All integration points verified against deployed source.

Phases with standard, well-documented patterns (skip research-phase):
- **Phase 1 (sourceUrl):** Apollo GraphQL field addition is an established pattern already used elsewhere in this project.
- **Phase 2 (AVSpeechClient):** `AudioPlayerClient.swift` is the exact interface template to mirror. All edge cases are documented in PITFALLS.md with concrete code.
- **Phase 3 (Search):** TCA `@Presents` pattern is already used for `recipeDetail` and `paywall` in `FeedReducer`. Backend endpoint is confirmed deployed.
- **Phase 4 (Verification):** Acceptance criteria are fully enumerated in PITFALLS.md "Looks Done But Isn't" checklist.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All integration points verified against live codebase source files. No new packages. AVSpeechSynthesizer capabilities confirmed via Apple documentation and WWDC23. Apollo codegen process verified against existing project configuration. |
| Features | HIGH | Five gaps verified against live code: `FeedReducer` line 668 comment confirms client-side-only filter was intentional; `RecipeDetailQuery.graphql.swift` confirms `sourceUrl` absent from selection set; `VoicePlaybackReducer` confirms no free-tier branch exists. Backend resolver deployed (confirmed via `recipes.resolver.ts`). |
| Architecture | HIGH | All proposed components follow existing patterns in this codebase (`AudioPlayerClient`, `@Presents` child stores, Apollo fetch effects). `subscriptionStatus` is already in `VoicePlaybackReducer.State`. No new architectural patterns are introduced — only extensions of existing ones. |
| Pitfalls | HIGH | iOS 17 AVSpeechSynthesizer bugs documented via Apple TSIs, Apple Developer Forums, and WWDC23 session. Spoonacular single-diet constraint verified directly in `SpoonacularService` backend source (`params.diet = filters.diets[0]`). Apollo codegen manual step confirmed from existing project setup. Quota constraint verified against Spoonacular pricing docs. |

**Overall confidence:** HIGH

### Gaps to Address

- **AVSpeech Enhanced voice availability on fresh install:** Enhanced neural voices (100MB) require download and may not be present on a fresh TestFlight install. Implementation must call `AVSpeechSynthesisVoice.speechVoices()` to check for `.enhanced` quality before constructing the utterance and fall back to `.compact` if not found. Validate on a fresh TestFlight install in Phase 4.

- **Spoonacular cache key coverage for dietary params:** `SpoonacularCacheService.normalizeCacheKey` may not include `diets` and `intolerances` as sorted cache key components. If uncovered, identical dietary searches from different users bypass the cache and each consume quota. Verify during Phase 3 implementation; add dietary params to the cache key if missing.

- **`FeedMode.browse` restore with swiped IDs:** When returning from `FeedMode.search` to `FeedMode.browse`, `allRecipes` must be re-filtered by both the current dietary chips AND already-swiped IDs. This three-way state interaction (mode, filters, swipedRecipeIDs) needs explicit attention during Phase 3 to ensure undo-swipe does not restore cards that were already swiped before search mode was entered.

## Sources

### Primary (HIGH confidence)
- Live codebase: `VoicePlaybackFeature/Sources/Player/VoicePlaybackReducer.swift` — narration flow, `subscriptionStatus` in State, `selectVoice` as the routing entry point
- Live codebase: `FeedFeature/Sources/Feed/FeedReducer.swift:649-672` — `applyDietaryFilter` client-side only, confirmed by inline comment "Client-side filtering — no server round-trip needed"
- Live codebase: `NetworkClient/Sources/GraphQL/RecipeQueries.graphql` — `sourceUrl` absent from `RecipeDetailQuery` selection set
- Live codebase: `backend/src/graphql/models/recipe.model.ts:154-155` — `sourceUrl` has `@Field` decorator, nullable String, confirmed deployed
- Live codebase: `backend/src/recipes/recipes.resolver.ts` — `searchRecipes(input: SearchRecipesInput)` endpoint deployed
- Live codebase: `backend/src/recipes/dto/search-recipes.input.ts` — `SearchRecipesInput` fields: `query`, `cuisines`, `diets`, `intolerances`, `first`, `after`
- Live codebase: `MonetizationFeature/Sources/Models/SubscriptionModels.swift` — `SubscriptionStatus.free` / `.pro(expiresDate:, isInGracePeriod:)` / `.unknown`
- [AVSpeechSynthesizer — Apple Developer Documentation](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer) — background audio behavior, `usesApplicationAudioSession`, MainActor requirement
- [WWDC23: Extend Speech Synthesis with personal and custom voices](https://developer.apple.com/videos/play/wwdc2023/10033/) — iOS 17 AVSpeechSynthesizer capabilities overview

### Secondary (MEDIUM confidence)
- [Apple Developer Forums: AVSpeechSynthesizer in background](https://developer.apple.com/forums/thread/27097) — background audio session behavior; corroborated by project's existing `UIBackgroundModes: audio`
- [Using Personal Voice in an iOS app — Ben Dodson, 2024](https://bendodson.com/weblog/2024/04/03/using-your-personal-voice-in-an-ios-app/) — Personal Voice API scope confirmed as accessibility-only feature; not a product tier candidate

### Tertiary (LOW confidence — validate during implementation)
- Apple TSI references (not directly linked) — iOS 17 AVSpeechSynthesizer audio unit failure (TTSErrorDomain Code -4010) and deactivation timing bug referenced in PITFALLS.md. Treat as probable; must validate on real iOS 17.0 and 17.6 hardware during Phase 2. Simulator does not reproduce.

---
*Research completed: 2026-04-12*
*Ready for roadmap: yes*
