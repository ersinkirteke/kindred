# Pitfalls Research

**Domain:** iOS Recipe App - v5.1 Gap Closure (AVSpeechSynthesizer free-tier narration, voice tier routing, search wiring, dietary filter pass-through)
**Researched:** 2026-04-12
**Confidence:** HIGH

---

## Critical Pitfalls

### Pitfall 1: AVSpeechSynthesizer Deactivates the Shared Audio Session, Breaking Subsequent AVPlayer Playback

**What goes wrong:**
Free user triggers AVSpeechSynthesizer narration (free tier). It plays. User later upgrades or switches to a Pro ElevenLabs voice. AVPlayer fails to play — buffering spinner hangs forever or audio session throws "Session is not active" error. The shared `AVAudioSession` is left in a deactivated or inconsistent state because `AVSpeechSynthesizer` activates the session on its own but does NOT deactivate it after finishing. Depending on iOS version (17.x is worst), the session is also silently "ducked" — other audio remains at reduced volume permanently after AVSpeech completes.

**Why it happens:**
`AVSpeechSynthesizer` and `AVPlayer` both rely on `AVAudioSession.sharedInstance()`. The synthesizer calls `setActive(true)` internally. On iOS 13+ it also attempts to deactivate the session a few seconds after the synthesizer instance is created (not after speech finishes — after creation). This races with `AVPlayer` setup. Apple explicitly documented `usesApplicationAudioSession` to address this, but the default behavior (`true`) causes interference. Apple stated in TSIs that there is "no workaround" for the iOS 17 deactivation timing bug — it is a platform bug under investigation.

**How to avoid:**
1. Never let AVSpeechSynthesizer and AVPlayer use the audio session simultaneously. In `VoicePlaybackReducer`, call `audioPlayer.cleanup()` (which pauses and nils the AVPlayer) before constructing the synthesizer, and vice versa.
2. After AVSpeech narration ends (via `didFinish` delegate), manually re-activate the session: `try? AVAudioSession.sharedInstance().setActive(true)` before calling `AVPlayer.play()`.
3. Set `synthesizer.usesApplicationAudioSession = true` (the default) AND manually call `setActive(true)` before each AVPlayer use — do not assume it persists active across synthesizer lifecycle.
4. Design `SpeechClient` as a separate TCA `@DependencyClient` with its own lifecycle, completely decoupled from `AudioPlayerClient`. The reducer dispatches to one or the other based on tier — never both at once.
5. Test the exact sequence on a real iOS 17 device: AVSpeech narrates → user switches to Pro voice → AVPlayer must play without re-launching the app.

**Warning signs:**
- AVPlayer hangs in `.buffering` status after a free-tier narration session.
- `AVAudioSession` logs: "Session deactivated while another client was using it."
- Background music from other apps remains at reduced volume after narration ends.
- Works in Simulator but fails on iOS 17.x physical device.

**Phase to address:**
Phase 1: AVSpeechSynthesizer Integration (must test audio session handoff as an explicit acceptance criterion before moving to search work)

---

### Pitfall 2: AVSpeechSynthesizer iOS 17 Audio Unit Failures Cause Silent Non-Playback

**What goes wrong:**
On iOS 17.0–17.4, `AVSpeechSynthesizer.speak()` returns immediately (always does) but no audio is produced. The console shows "Couldn't find audio unit for request" or "Could not instantiate audio unit" (TTSErrorDomain Code -4010). The `AVSpeechSynthesizerDelegate.speechSynthesizer(_:didFinish:)` may still fire, making the failure completely invisible in the TCA reducer — the playback appears to complete successfully from the reducer's perspective while the user heard nothing.

**Why it happens:**
The iOS 17 TTS system has a documented bug where the audio unit chain for speech synthesis fails to initialize on certain device/voice combinations. This is a platform-level failure that cannot be caught via the `AVSpeechSynthesizer` API because neither `speak()` nor the delegate exposes failure at this level. Apple acknowledged the bug in TSIs with no workaround.

**How to avoid:**
1. Set an expected duration window. For recipe steps, narration should take at minimum `(word_count / 2.5)` seconds. Start a timer in `didStart`. If `didFinish` fires more than 40% earlier than the minimum expected duration, treat it as a failure and show an error state.
2. Add a completion timeout: if `didStart` is never called within 3 seconds of `speak()`, fire `narrationFailed`.
3. Instrument with OSLog: log iOS version + voice identifier + result (started/finished/timeout) to every narration attempt.
4. On first narration failure, try a fallback compact voice (e.g., `AVSpeechSynthesisVoice(language: "en-US")`) before surfacing an error.
5. Document in acceptance criteria: test on a minimum of iOS 17.0 + iOS 17.6 + iOS 18.x real devices. The v5.0 PITFALLS.md already flagged this; treat it as a hard blocker for this phase.

**Warning signs:**
- Narration "completes" in under 1 second for a 200-word recipe.
- `didStart` never fires; `didFinish` fires immediately.
- No audio heard, but no error surfaced in the reducer.
- Only reproducible on real iOS 17 device, works in Simulator.

**Phase to address:**
Phase 1: AVSpeechSynthesizer Integration (build failure detection as a first-class concern, not an afterthought)

---

### Pitfall 3: VoicePlaybackReducer Tier Routing Leaves Orphaned Stream Observers

**What goes wrong:**
VoicePlaybackReducer currently starts three long-running stream effects (`timeObserver`, `statusObserver`, `durationObserver`) backed by an `AVPlayer` via `AudioPlayerClient`. When introducing AVSpeechSynthesizer for free users, a second set of streams is needed. If the routing logic dispatches `selectVoice` to the wrong path, or if a voice switch happens mid-playback, the old streams continue running and compete with new ones. Specifically: a free→Pro switch mid-recipe starts AVPlayer streams while AVSpeech streams are still active. Both call `.timeUpdated`, producing duplicate time events. The `currentPlayback.currentTime` stutters and jumps. The `.statusChanged(.stopped)` from AVSpeech fires after AVPlayer starts, triggering the 2-second auto-dismiss even though Pro audio is playing.

**Why it happens:**
The reducer uses named `CancelID` (`timeObserver`, `statusObserver`, `durationObserver`) but the cancellation logic only fires on explicit actions (`dismiss`, `showVoiceSwitcher`). There is no cancellation on `selectVoice` when switching backends. Adding a second audio backend without refactoring the stream lifecycle will create race conditions that are very hard to reproduce in tests.

**How to avoid:**
1. In `selectVoice`, before dispatching to either backend path, cancel all three stream IDs unconditionally:
   ```swift
   return .concatenate(
       .cancel(id: CancelID.timeObserver),
       .cancel(id: CancelID.statusObserver),
       .cancel(id: CancelID.durationObserver),
       .run { /* route to AVSpeech or AVPlayer */ }
   )
   ```
2. Introduce a `CancelID.speechObserver` to track AVSpeech-specific observation. Cancel it when switching to AVPlayer path and vice versa.
3. Add a `currentAudioBackend: AudioBackend` field to `State` (`.avSpeech` / `.avPlayer` / `.none`). State transitions through this field enforce that only one backend is active at a time.
4. Write a test: `send(.selectVoice("kindred-default"))` then immediately `send(.selectVoice("elevenlabs-id"))`. Assert that `currentAudioBackend` is `.avPlayer` and no orphaned `.timeUpdated` actions arrive after the switch.

**Warning signs:**
- `currentPlayback.currentTime` jumps backward or forward erratically after a voice switch.
- Auto-dismiss fires while Pro voice is actively playing.
- Two simultaneous "Now Playing" lock screen entries appear.
- `CancelID.timeObserver` cancelled in logs but time events still arrive.

**Phase to address:**
Phase 1: AVSpeechSynthesizer Integration (design backend enum into State before writing any AVSpeech code)

---

### Pitfall 4: AVSpeechSynthesizer Blocks Background Playback for Free Users, Creating Asymmetric UX

**What goes wrong:**
`AVSpeechSynthesizer` background audio is unreliable on iOS 16–18 even with `UIBackgroundModes: audio` and `.playback` audio session category. Speech stops when the app backgrounds. `AVPlayer`-backed Pro narration continues correctly in the background. Free users discover this difference organically — they lock their phone and audio stops — and write 1-star reviews. The asymmetry is more damaging than a consistent limitation because it makes free tier feel broken rather than limited.

**Why it happens:**
This is the same platform bug documented in the v5.0 PITFALLS.md (Pitfall 10). The root cause is an Apple bug, not a configuration issue. AVPlayer has a robust background audio path; AVSpeechSynthesizer does not.

**How to avoid:**
1. Before shipping, communicate the limitation proactively: after the first free narration completes, show a tooltip: "Keep Kindred open while listening. Upgrade to Pro for background playback."
2. Implement `UIApplication.shared.isIdleTimerDisabled = true` while AVSpeech narration is active — keeps screen on and prevents backgrounding if user doesn't explicitly switch apps. Restore on `didFinish`.
3. Listen for `UIApplication.didEnterBackgroundNotification` during AVSpeech playback. If fired, stop the synthesizer and show a local notification: "Return to Kindred to continue."
4. Do NOT attempt `UIBackgroundModes` hacks — Apple rejects apps that misuse background modes. Document this as expected behavior, not a bug to fix.

**Warning signs:**
- TestFlight tester: "Audio stops when I switch apps."
- Pro users don't report this; only free users do.
- `UIApplication.didEnterBackgroundNotification` fires without synthesizer stopping gracefully.
- App Store review time increases if reviewer tests background audio during review.

**Phase to address:**
Phase 1: AVSpeechSynthesizer Integration (add proactive communication + screen-awake fallback as acceptance criteria)

---

### Pitfall 5: Apollo Codegen Not Re-Run After Adding SearchRecipesQuery, Causing Build Failures

**What goes wrong:**
`SearchRecipesInput` and `searchRecipes` query exist in the backend GraphQL schema and `RecipesResolver`. The iOS `KindredAPI` package has no `SearchRecipesQuery.graphql.swift` generated file. Developer writes a `.graphql` operation file and references `KindredAPI.SearchRecipesQuery` in `FeedReducer`, but the generated Swift types don't exist because codegen was not re-run. Build fails with `cannot find type 'SearchRecipesQuery' in scope`. Apollo codegen is NOT automatic — it must be run as an explicit step when operations are added or modified.

**Why it happens:**
Apollo iOS 2.x deliberately removed the build-phase codegen run (it was removed from recommendations to avoid slowing down every build). The generated Swift files in `KindredAPI/Sources/Operations/Queries/` are checked in to source control and must be manually regenerated via the Codegen CLI when `.graphql` operation definitions change. Developers who are new to the project or unfamiliar with this step skip it and get cryptic build errors.

**How to avoid:**
1. After writing a new `.graphql` operation file, always run Apollo codegen before touching any Swift files that reference the new types:
   ```bash
   cd Kindred/Packages/KindredAPI
   npx apollo-ios-cli generate
   ```
2. Check the `apollo-codegen-configuration.json` for the correct schema URL and output paths before running — the schema must be reachable (backend must be running).
3. The generated file must appear in `KindredAPI/Sources/Operations/Queries/` and be added to the Package.swift sources target. Verify after generation.
4. If the backend schema changed (new fields on `Recipe` like `sourceUrl`), download an updated schema file first: `npx apollo-ios-cli fetch-schema`.

**Warning signs:**
- Build error: `cannot find type 'SearchRecipesQuery' in scope`.
- Build error: `value of type 'KindredAPI.RecipeDetailQuery.Data.Recipe' has no member 'sourceUrl'`.
- `KindredAPI/Sources/Operations/Queries/` missing the new operation file.
- Schema introspection diff shows new fields but generated Swift types still have old fields.

**Phase to address:**
Phase 2: Search UI Wiring (codegen is step 0 before any Swift that references new operations)

---

### Pitfall 6: RecipeDetail `sourceUrl` Field Missing from GraphQL Schema and Generated Types

**What goes wrong:**
The iOS `RecipeDetailQuery.graphql.swift` selects: `id name description prepTime cookTime ... steps`. The `sourceUrl` field is not in the selection set. Even though the backend `Recipe` model has a `sourceUrl` field (Spoonacular populates it), the iOS app gets `nil` for every recipe because it's never requested. Developer adds `sourceUrl` to `RecipeDetailModels.swift` and `RecipeDetail.from(graphQL:)` but gets a compile error because `KindredAPI.RecipeDetailQuery.Data.Recipe` has no `sourceUrl` property — it was never in the generated code.

**Why it happens:**
Apollo iOS strictly generates only the fields present in the `.graphql` operation document. Adding a field to `RecipeDetailModels.swift` without updating the `.graphql` document and regenerating code is a two-step process developers routinely forget. The backend `recipe` query resolver already returns `sourceUrl` — the field exists in the schema. The only work needed is adding it to the iOS operation selection set and regenerating.

**How to avoid:**
1. Edit the operation document first (the `.graphql` source file, not the generated `.graphql.swift`). The pattern: find the original `.graphql` operation, add `sourceUrl` to the selection set, then run codegen.
2. Note: The existing `RecipeDetailQuery.graphql.swift` is fully generated — there is no separate `.graphql` source file checked in for this project. The operation string is embedded as `operationDocument`. This means the codegen config must be reviewed to understand where the operation source lives, or the `.graphql.swift` file must be regenerated with the new selection set.
3. After adding `sourceUrl` to `RecipeDetail` model, add it to the `RecipeDetail.from(graphQL:)` factory method in `RecipeDetailModels.swift`.
4. Verify the backend `Recipe` GraphQL type actually exposes `sourceUrl` via `@Field(() => String, { nullable: true })`. Confirm this in `backend/src/graphql/models/recipe.model.ts` before writing iOS code.

**Warning signs:**
- `recipe.sourceUrl` always nil in RecipeDetailView even for recipes with known Spoonacular source URLs.
- Compile error: `value of type '...Recipe' has no member 'sourceUrl'` in RecipeDetailModels.swift.
- Backend GraphQL playground shows `sourceUrl` populated; iOS shows nil.

**Phase to address:**
Phase 2: Source URL Wiring (verify backend schema first, update operation doc + regenerate, then add to model)

---

### Pitfall 7: Spoonacular `diet` Parameter Accepts Only One Value — Multiple Filters Silently Drop to First

**What goes wrong:**
The `SearchRecipesInput` DTO accepts `diets: [String]` (an array). iOS UI sends multiple dietary filters: `["vegan", "gluten-free"]`. `SpoonacularService.search()` contains this code:
```typescript
if (filters.diets && filters.diets.length > 0) {
  params.diet = filters.diets[0]; // Spoonacular only accepts one diet
}
```
The comment is correct — Spoonacular's `/complexSearch` endpoint accepts only a single `diet` value. But the second filter (`gluten-free`) is silently dropped. Users who selected both vegan AND gluten-free receive results that match only `vegan`, and some of those results contain gluten. This produces incorrect filtering with no error — the most dangerous kind of bug.

**Why it happens:**
The Spoonacular API design: `diet` accepts one diet name (e.g., `vegetarian`, `vegan`, `ketogenic`). Intolerances (e.g., `gluten`, `dairy`) are a separate parameter `intolerances` and DO accept comma-separated multiple values. Developers conflate dietary tags (which users may apply as a combined set) with the API's diet/intolerances split.

**How to avoid:**
1. On the backend, classify each iOS dietary filter tag into either `diet` (at most one) or `intolerances` (comma-separated list). Example mapping:
   - `"vegan"`, `"vegetarian"`, `"keto"`, `"paleo"` → `diet` (use the most restrictive one)
   - `"gluten-free"`, `"dairy-free"`, `"nut-free"`, `"halal"` → `intolerances`
2. If multiple `diet` values are passed, select the most restrictive (vegan > vegetarian > other). Log a warning when more than one diet is sent.
3. Update `SearchRecipesInput` or add a comment documenting this constraint so future developers don't assume multi-diet works.
4. On the iOS side, enforce single-diet selection in the UI. If the dietary chip bar allows multi-select, add logic: selecting a second diet deselects the first.
5. Verify behavior: fetch 10 recipes with `vegan + gluten-free` selected. Manually inspect the result set for gluten-containing ingredients.

**Warning signs:**
- User selects "Vegan" + "Gluten-Free"; results contain non-gluten-free items.
- Backend logs show only one diet param in the Spoonacular request despite two being sent from iOS.
- No error surfaced — results just look wrong.
- `SearchRecipesInput.diets` has more than one element at the backend breakpoint.

**Phase to address:**
Phase 3: Dietary Filter Pass-Through (design the iOS→backend→Spoonacular tag classification before implementing)

---

### Pitfall 8: Search Query Triggers Spoonacular API Call Per Keystroke, Exhausting 150 req/day Quota Within Minutes

**What goes wrong:**
Search UI is wired to `searchRecipes` GraphQL endpoint. Developer naively sends a query on every `onChange` of the search text field. User types "chicken tikka masala" — 18 keystrokes = 18 Spoonacular API calls, each costing 1 + 0.01×20 = 1.2 points. 18 keystrokes × 1.2 = 21.6 points. Five users typing one search each exhausts the 150-point daily budget before lunch. The quota exhaustion fallback serves only popular pre-warmed recipes, making search return irrelevant results.

**Why it happens:**
`RecipeDetailQuery`, `PopularRecipesQuery`, and all existing queries are one-shot fetches triggered by navigation. Search is the first user-input-driven continuous query in the app. Developers accustomed to instant-search patterns (common in web apps) apply the same pattern without accounting for the shared Spoonacular quota.

**How to avoid:**
1. Debounce search input with a minimum 500ms delay before sending the GraphQL query. In TCA, use `Effect.run` with `Task.sleep(nanoseconds: 500_000_000)` wrapped in `.cancellable(id: CancelID.searchDebounce, cancelInFlight: true)`.
2. Enforce a minimum query length of 3 characters before firing a Spoonacular request.
3. Add a backend cache layer for search queries: `SpoonacularCacheService.normalizeCacheKey(query, filters)` already exists — verify it's called in `searchRecipes`. Check that identical query+filter combinations hit the cache and not Spoonacular.
4. Show results from the existing `popularRecipes` PostgreSQL cache while the debounced search is pending. Transition to search results when they arrive.
5. Add quota consumption logging per search request. Track daily search query volume in the backend dashboard.

**Warning signs:**
- Backend logs show a Spoonacular API call for every character typed.
- Daily quota exhausted before expected (check `SpoonacularQuotaUsage` table).
- Search results return "popular recipes fallback" even for specific queries.
- `normalizeCacheKey` not called in `searchRecipes` code path.

**Phase to address:**
Phase 3: Search UI Wiring (implement debounce and cache verification before connecting iOS to backend)

---

### Pitfall 9: FeedReducer `dietaryFilterChanged` Currently Does Client-Side Filtering — Backend Pass-Through Changes Semantics

**What goes wrong:**
`FeedReducer` already has `dietaryFilterChanged(Set<String>)` and `filteredRecipesLoaded(Result<[RecipeCard], Error>)` actions. There is an `allRecipes` array for "unfiltered full list for client-side filtering." The current filtering almost certainly performs client-side tag matching against `RecipeCard.dietaryTags`. Adding backend dietary filter pass-through to `searchRecipes` changes the source of truth: filtered results now come from Spoonacular via backend, not from the local `allRecipes` array. If this distinction is not handled carefully, the reducer ends up with two competing filtered lists: the client-filtered `allRecipes` subset AND the backend-search results. Cards disappear and reappear unexpectedly when filters are toggled.

**Why it happens:**
The existing client-side filtering was sufficient when all recipes were in `allRecipes`. Backend-driven search returns a new, different set of recipes. Mixing both in `cardStack` produces inconsistent ordering, duplicate recipe IDs (a recipe in both `allRecipes` and search results), and confusing swipe-and-reset behavior.

**How to avoid:**
1. Define a clear mode: `FeedMode.browse` (popular recipes, no query, client-side diet filtering) vs. `FeedMode.search(query: String, filters: Set<String>)` (backend search results, backend filtering). Add this to `FeedReducer.State`.
2. In `browse` mode, continue using `allRecipes` + client-side filtering. Only dispatch to `searchRecipes` endpoint when the user is actively typing a search query.
3. When entering `search` mode, clear `cardStack` and populate from backend search results. When exiting `search` mode, restore `allRecipes` + apply current client-side filters.
4. Dietary filter changes in `browse` mode update the existing client-side filter. In `search` mode, they re-trigger the debounced `searchRecipes` call with updated filter params.
5. Ensure `swipedRecipeIDs` is consulted when populating from search results to prevent showing already-swiped recipes.

**Warning signs:**
- Dietary filter toggle in the feed causes all cards to disappear and reload from scratch.
- Same recipe card appears twice in the stack.
- Undo last swipe restores a card from the popular feed while search results are visible.
- `allRecipes` count differs from `cardStack` count for no clear reason.

**Phase to address:**
Phase 3: Search UI Wiring (define FeedMode enum in State before touching any filter logic)

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Inline AVSpeechSynthesizer in VoicePlaybackReducer instead of `SpeechClient` TCA dependency | Less code (no new client struct) | Cannot mock in tests, cannot cleanly swap implementation, harder to add voice speed/pitch controls | Never — always extract to `@DependencyClient` |
| Route by subscription status check inline in `selectVoice` | Simple if/else | Subscription status may be `.unknown` at selection time, causing wrong backend selection | Never — check status before offering voice picker, not during narration start |
| Client-side dietary filtering only (skip backend pass-through) | Faster to implement | Filters only recipes already in cache — misses Spoonacular's full catalog for specific diets | Never for this milestone — pass-through is the explicit requirement |
| Search without debounce | Instant results feel snappy | Quota exhaustion within days | Never — 500ms debounce is non-negotiable |
| Reuse `AudioPlayerClient` for AVSpeech (awkward wrapper) | No new dependency to define | Mismatched semantics (AVPlayer streams vs. AVSpeech delegate callbacks), fragile synchronization | Never — two separate clients with a common `PlaybackStatus` model |
| Skip `FeedMode` enum, just add another `Result` action | Less refactoring | Dual-list confusion (allRecipes + search results) corrupts card stack | Never for this milestone — mode distinction is critical |

---

## Integration Gotchas

Common mistakes when connecting to external services.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| AVSpeechSynthesizer | Call `speak()` without checking `AVSpeechSynthesisVoice.speechVoices()` for availability | Always verify the target voice exists before constructing `AVSpeechUtterance`. Enhanced voices (100MB) may not be downloaded. Fall back to `AVSpeechSynthesisVoice(language: "en-US")` if not found. |
| AVSpeechSynthesizer | Assume `didFinish` means audio was heard | `didFinish` fires even on the iOS 17 silent failure bug. Validate against expected duration. |
| AVSpeechSynthesizer + AVPlayer | Don't re-activate audio session before AVPlayer after AVSpeech session | Call `try? AVAudioSession.sharedInstance().setActive(true)` before each AVPlayer `play()` when AVSpeech ran recently. |
| Apollo iOS codegen | Edit `.graphql.swift` directly | These are generated — edits are overwritten. Edit the source `.graphql` operation document, then regenerate. |
| Apollo iOS codegen | Run codegen without backend running | `fetch-schema` needs the backend GraphQL endpoint live. Start backend + Postgres before running CLI. |
| Spoonacular `diet` param | Send `["vegan", "gluten-free"]` as multi-value diet | Only first value used. Map intolerances (gluten-free, dairy-free) to `intolerances` param, not `diet`. |
| Spoonacular search + quota | Wire search directly without checking cache first | `RecipesService.searchRecipes` already implements cache-first — verify the cache key normalization covers dietary filter combinations. |
| `searchRecipes` GraphQL query | Forget to re-generate `SearchRecipesQuery.graphql.swift` in KindredAPI package | Build fails with "cannot find type". Run `npx apollo-ios-cli generate` after writing the `.graphql` operation file. |

---

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Search on every keystroke | Daily Spoonacular quota (150 pts) exhausted in <10 minutes of usage | 500ms debounce + 3-char minimum + cache-first check | First session where >1 user actively types in the search field |
| AVSpeech utterance over 500 words | Truncation at ~300 words on iOS 17 (documented bug), incomplete recipe narration | Split recipe steps into per-step utterances, speak sequentially with delegate `didFinish` chaining | Recipes with >15 steps or verbose instructions |
| Regenerating Apollo types on every build | Xcode build times increase 30-60 seconds each clean build | Apollo already recommends against build-phase codegen. Only run when operations change. | Daily development iteration |
| Dietary filter changes triggering full `allRecipes` re-fetch from backend | Feed flashes empty then repopulates on every filter toggle | Client-side filter in browse mode, backend filter only for search mode | Every filter toggle in browse mode |

---

## Security Mistakes

Domain-specific security issues beyond general web security.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Expose `diet` filter values constructed from raw user input directly to Spoonacular | Spoonacular returns 400 or ignores invalid values, but malformed values could cause unexpected query behavior | Validate diet/intolerance values against an allowlist on the backend before passing to Spoonacular params |
| Cache search results that include user-specific dietary preferences without scoping cache key | User A's "vegan" search served to User B who has no dietary filter | `normalizeCacheKey` must include dietary params. Verify the cache key includes `diets` and `intolerances` sorted consistently. |
| Return `sourceUrl` (third-party recipe blog URL) without validation | Phishing if Spoonacular data is manipulated or contains injected URLs | Validate `sourceUrl` is a well-formed HTTPS URL before returning from GraphQL. Reject non-HTTPS URLs. |

---

## UX Pitfalls

Common user experience mistakes in this domain.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Free narration UI identical to Pro narration UI | User confused when free narration stops on backgrounding; thinks app is broken | Visually differentiate: show "Built-in voice" label for AVSpeech, "Cloned voice" for ElevenLabs. One word explains the difference. |
| Search results replace feed without back navigation | User finishes search, has no way to return to popular feed | Implement search as an overlay or modal — main feed card stack persists underneath. Dismiss search to return. |
| Dietary filter chip bar sends backend query for every chip toggle | Feed flickers on every filter change; feels slow | Client-side filtering in browse mode (instant) vs. backend search (debounced). Filter chip changes in browse mode = instant local filter. |
| Show "No results" immediately while search is debouncing | Distracting flicker as user types | Show "searching..." skeleton state during debounce window. Only show "No results" after backend responds. |
| `sourceUrl` displayed as raw URL string | Ugly, untrustworthy | Show recipe source domain only (e.g., "allrecipes.com"), tappable link opens Safari. |
| AVSpeech voice selection UI identical to ElevenLabs voice picker | Free user sees "Kindred Voice" as only option, wonders where cloned voices went | If user is free tier, show only "Built-in Narration" option. Voice picker for custom clones is Pro-only. |

---

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **AVSpeechSynthesizer narration:** Plays in dev → verify on iOS 17.0 real device (not Simulator). Confirm `didStart` fires within 3 seconds; confirm duration is within 40% of expected.
- [ ] **Voice tier routing:** Routes correctly in code → verify audio session is torn down and re-activated correctly when switching free→Pro within the same recipe detail session.
- [ ] **Search wiring:** Returns results → verify debounce is active (type fast, check backend logs show only one Spoonacular call per search, not one per keystroke).
- [ ] **Dietary filter pass-through:** Filters applied → verify multi-diet scenario. Select "vegan" + "gluten-free" → inspect returned recipes for gluten-containing ingredients.
- [ ] **Source URL wiring:** `sourceUrl` field in RecipeDetailView → verify field is in the GraphQL operation selection set (not just in `RecipeDetailModels.swift`). Check backend returns non-null value for a known Spoonacular recipe.
- [ ] **Apollo codegen:** New operations compile → verify generated `.graphql.swift` file was committed to source control (not just regenerated locally without committing).
- [ ] **Search + browse coexistence:** Both modes work → verify toggling a dietary chip in browse mode does NOT trigger a `searchRecipes` backend call. Check backend logs during chip toggle while search bar is empty.
- [ ] **AVSpeech background behavior:** Narration plays → verify the screen-awake (`isIdleTimerDisabled`) is restored to `false` after `didFinish` fires. Screen should dim normally after narration completes.

---

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| AVSpeech silent failure on iOS 17 in production | MEDIUM | 1. Release hotfix detecting iOS 17.0–17.4 builds, auto-fallback to text-only mode. 2. Add user-facing message: "Voice narration unavailable on this iOS version. Update to iOS 17.5+ for best results." 3. Track impact via analytics. |
| Audio session broken after AVSpeech → AVPlayer switch | HIGH | 1. Hotfix: On `audioPlayer.play()` throw, call `AVAudioSession.sharedInstance().setActive(true)` before retrying once. 2. If retry fails, show error state with "Tap to retry." 3. Long-term: Implement `SpeechClient` TCA dependency that owns the session lifecycle. |
| Quota exhausted by search on launch day | MEDIUM | 1. Disable live search immediately (feature flag). 2. Search falls back to local `allRecipes` filter only. 3. Increase search debounce to 1500ms and re-enable. |
| `SearchRecipesQuery` types missing (codegen not run) | LOW | 1. Run `npx apollo-ios-cli generate` with backend running. 2. Commit generated file. 3. Rebuild. Takes 10-15 minutes. |
| Dietary filter silently dropping second filter value | MEDIUM | 1. Hotfix backend: map dietary tags to correct `diet`/`intolerances` params. 2. Add validation test for multi-filter search. 3. Update iOS UI to enforce single diet selection. |
| Feed broken after search/browse mode mixing | HIGH | 1. Revert `FeedReducer.dietaryFilterChanged` to client-side-only. 2. Disable search feature flag. 3. Redesign with proper `FeedMode` enum before re-enabling. |

---

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| AVSpeech deactivates audio session → breaks AVPlayer | Phase 1: AVSpeechSynthesizer Integration | Test sequence: free narration → switch to Pro voice → AVPlayer plays without re-launching app. On iOS 17 real device. |
| AVSpeech iOS 17 silent audio unit failure | Phase 1: AVSpeechSynthesizer Integration | Duration validation in `SpeechClient.play()`. Test on iPhone with iOS 17.0 and 17.6. |
| Orphaned stream observers on backend switch | Phase 1: AVSpeechSynthesizer Integration | State has `currentAudioBackend` field. `selectVoice` cancels all streams before routing. TCA test asserts no post-switch `.timeUpdated` events. |
| AVSpeech background audio stops | Phase 1: AVSpeechSynthesizer Integration | `isIdleTimerDisabled = true` during narration. Proactive tooltip shown after first narration. |
| Apollo codegen not re-run | Phase 2: Source URL + Search Wiring | Generated `.graphql.swift` file present in repo. Build succeeds on clean checkout without running codegen. |
| `sourceUrl` not in selection set | Phase 2: Source URL Wiring | Backend GraphQL playground query includes `sourceUrl`. iOS RecipeDetailView shows tappable source attribution. |
| Spoonacular single-diet limitation | Phase 3: Dietary Filter Pass-Through | Backend maps iOS tags to correct `diet`/`intolerances` params. Multi-tag integration test asserts correct Spoonacular params. |
| Search per-keystroke quota exhaustion | Phase 3: Search UI Wiring | Backend logs show single Spoonacular call per completed search. Debounce TCA test asserts cancel-in-flight behavior. |
| Dual-list confusion (browse vs. search modes) | Phase 3: Search UI Wiring | `FeedMode` enum in `FeedReducer.State`. Dietary chip toggle in browse mode: zero backend calls. TCA test verifies. |

---

## Sources

### AVSpeechSynthesizer iOS 17/18 Bugs
- [AVSpeechSynthesizer Broken on iOS 17 — Apple Developer Forums](https://developer.apple.com/forums/thread/737685)
- [AVSpeechSynthesizer is broken on iOS 17 in Xcode 15 — Apple Developer Forums](https://developer.apple.com/forums/thread/738048)
- [AVSpeechSynthesizer & iOS 17 — Apple Developer Forums](https://developer.apple.com/forums/thread/735618)
- [AVSpeechSynthesizer Leaking Memory — Apple Developer Forums](https://developer.apple.com/forums/thread/730639)
- [Why has AVSpeechSynthesizer quit speaking — Apple Developer Forums](https://developer.apple.com/forums/thread/746735)
- [AVSpeechSynthesizer doesn't notify — Apple Developer Forums](https://developer.apple.com/forums/thread/759553)

### AVSpeechSynthesizer Audio Session Coexistence
- [usesApplicationAudioSession — Apple Developer Documentation](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer/usesapplicationaudiosession)
- [AVSpeechSynthesizer — Apple Developer Documentation](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer)
- [AVSpeechSynthesizer tries to deactivate app audio session — Apple Developer Forums](https://developer.apple.com/forums/thread/120956)
- [Is AVSpeechSynthesizer incompatible with audio playback — Apple Developer Forums](https://developer.apple.com/forums/thread/659975)
- [Handling audio interruptions — Apple Developer Documentation](https://developer.apple.com/documentation/avfaudio/handling-audio-interruptions)
- [expo/expo PR #18374 — Add option for using application audio session](https://github.com/expo/expo/pull/18374)

### Apollo iOS Codegen
- [Codegen configuration — Apollo GraphQL Docs](https://www.apollographql.com/docs/ios/code-generation/codegen-configuration)
- [Get started with Apollo iOS codegen — Apollo GraphQL Docs](https://www.apollographql.com/docs/ios/tutorial/codegen-getting-started)

### Spoonacular API Constraints
- [spoonacular recipe and food API — Official Docs](https://spoonacular.com/food-api/docs)
- Project source: `backend/src/spoonacular/spoonacular.service.ts` line 67–69 (single-diet comment confirmed in codebase)

### Project Codebase Observations (HIGH confidence — read directly)
- `Kindred/Packages/VoicePlaybackFeature/Sources/Player/VoicePlaybackReducer.swift` — current stream lifecycle and CancelID design
- `Kindred/Packages/VoicePlaybackFeature/Sources/AudioPlayer/AudioPlayerManager.swift` — AVPlayer audio session management
- `Kindred/Packages/FeedFeature/Sources/Feed/FeedReducer.swift` — `allRecipes`, `dietaryFilterChanged`, existing pagination
- `Kindred/Packages/KindredAPI/Sources/Operations/Queries/RecipeDetailQuery.graphql.swift` — missing `sourceUrl` in selection set confirmed
- `backend/src/recipes/recipes.resolver.ts` — `searchRecipes` endpoint confirmed live
- `backend/src/recipes/dto/search-recipes.input.ts` — `SearchRecipesInput` with `diets: [String]` array confirmed
- `backend/src/spoonacular/spoonacular.service.ts` lines 63–69 — single-diet Spoonacular constraint confirmed in code

---
*Pitfalls research for: v5.1 Gap Closure — AVSpeechSynthesizer free-tier narration, voice tier routing, source URL wiring, search UI, dietary filter pass-through*
*Researched: 2026-04-12*
