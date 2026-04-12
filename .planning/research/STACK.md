# Stack Research

**Domain:** iOS cooking app — v5.1 Gap Closure feature additions
**Researched:** 2026-04-12
**Confidence:** HIGH

> **Scope:** This document covers ONLY the stack additions and changes required for v5.1 features.
> Existing validated stack (SwiftUI+TCA, Apollo iOS 2.0.6, AVPlayer, StoreKit 2, AdMob) is not repeated here.

---

## New Capabilities Required

| v5.1 Feature | Stack Need | Type |
|---|---|---|
| AVSpeechSynthesizer free-tier narration | AVFoundation (already linked) — new usage pattern | No new package |
| Voice tier routing (free→AVSpeech, Pro→ElevenLabs) | Logic in VoicePlaybackReducer keyed on `SubscriptionStatus` | No new package |
| Per-recipe sourceUrl wiring | Add `sourceUrl` field to `RecipeDetailQuery` + `RecipeDetail` model | GraphQL codegen update |
| Search UI wiring | New `SearchRecipesQuery` + `SearchReducer` in FeedFeature | GraphQL codegen update |
| Dietary filter pass-through to Spoonacular | Wire `diets`/`intolerances` params through `SearchRecipesInput` to backend | No new package |

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|---|---|---|---|
| AVSpeechSynthesizer | iOS 17+ (built-in AVFoundation) | Free-tier TTS narration | Zero-cost, offline-capable, no new dependency. Already linked via AVFoundation in VoicePlaybackFeature. Sufficient quality for free tier. |
| AVSpeechUtterance | iOS 17+ (built-in AVFoundation) | Utterance configuration (rate, pitch, voice) | Pairs with AVSpeechSynthesizer; controls `rate` (0.5 default), `pitchMultiplier`, and `postUtteranceDelay` for step gaps |
| Apollo iOS codegen | 2.0.6 (existing) | Generate `SearchRecipesQuery` and updated `RecipeDetailQuery` | No version bump needed — add `.graphql` operation files and re-run codegen |

### Supporting Libraries

No new SPM packages are required for any v5.1 feature.

| Library | Version | Purpose | When to Use |
|---|---|---|---|
| swift-tts (renaudjenny) | N/A | TCA-compatible AVSpeechSynthesizer wrapper | **Do not add.** Overkill for this use-case. A thin `SpeechSynthesizerClient` dependency wrapping `AVSpeechSynthesizer` directly is ~60 lines and matches the existing `AudioPlayerClient` pattern exactly. |

### Development Tools

| Tool | Purpose | Notes |
|---|---|---|
| Apollo iOS Codegen CLI | Regenerate `KindredAPI` Swift types after adding `.graphql` operation files | Run `apollo-ios-cli generate` from `Kindred/Packages/KindredAPI/` after adding `SearchRecipesQuery.graphql` and updating `RecipeDetailQuery.graphql` |

---

## Feature-Specific Integration Details

### 1. AVSpeechSynthesizer — Free-Tier Narration

**Approach:** Add a `SpeechSynthesizerClient` dependency to `VoicePlaybackFeature`, mirroring the existing `AudioPlayerClient` pattern.

**Key API usage:**
```swift
let synthesizer = AVSpeechSynthesizer()
let utterance = AVSpeechUtterance(string: stepsText)
utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
utterance.rate = 0.50  // AVSpeechUtteranceDefaultSpeechRate
utterance.pitchMultiplier = 1.0
synthesizer.speak(utterance)
```

**AVAudioSession interaction (CRITICAL):** `AVSpeechSynthesizer` manages its own audio session activation. When `usesApplicationAudioSession = true` (the default), the synthesizer respects the existing `.playback` category set in `AppDelegate`, and ducks or interrupts other audio correctly. After speech ends, the session stays active — the client must call `audioSession.setActive(false, options: .notifyOthersOnDeactivation)` to restore ducked audio. This is a known iOS behavioral quirk.

**Background playback:** `AVSpeechSynthesizer` continues in the background because Kindred already has `UIBackgroundModes: audio` in `Info.plist` (for AVPlayer). The background modes entitlement applies to the process, not per-player instance.

**Step-by-step narration:** Concatenate steps with `\n\n` pauses, or queue multiple `AVSpeechUtterance` objects via sequential `synthesizer.speak(_:)` calls (they queue automatically). The `AVSpeechSynthesizerDelegate.speechSynthesizer(_:didFinish:)` callback enables per-step UI highlighting — wire into an `AsyncStream<Int>` step-index publisher in the client.

### 2. Voice Tier Routing

**Decision point:** In `VoicePlaybackReducer.selectVoice` (or a new `routeNarration` action), branch on `state.subscriptionStatus`:
- `.free` → dispatch to `speechSynthesizerClient.speak(steps)`
- `.pro(...)` → existing ElevenLabs flow via `NarrationUrlQuery`
- `.unknown` → default to free tier (safe fallback — avoids blocking UX while StoreKit resolves)

**The "Kindred Voice" entry** already inserted at position 0 in `VoicePickerView` maps cleanly to the free AVSpeech path. When free tier is selected and subscription is `.pro(...)`, the voice picker should still offer the ElevenLabs voices. When subscription is `.free` or `.unknown`, ElevenLabs voices are hidden or show an upgrade gate.

**No new dependency needed.** The routing is pure reducer logic against the existing `SubscriptionStatus` enum (`.free`, `.pro`, `.unknown`).

### 3. sourceUrl Wiring in RecipeDetailQuery

**Backend status:** `sourceUrl` is already present on the `Recipe` GraphQL model (`recipe.model.ts` line 155). It is populated by `recipe-mapper.ts` from the Spoonacular `sourceUrl` field. The field is nullable (`String | null`).

**iOS gap:** `RecipeDetailQuery.graphql.swift` operation string does NOT include `sourceUrl`. The `RecipeDetail` model (`RecipeDetailModels.swift`) has no `sourceUrl` property. `RecipeDetailView` currently hardcodes `https://spoonacular.com/food-api` as the attribution link.

**Fix — two steps:**

Step 1: Update the operation document string in `RecipeDetailQuery.graphql.swift` to include `sourceUrl` in the selection (after `imageUrl`). Add `.field("sourceUrl", String?.self)` to `__selections` and `public var sourceUrl: String? { __data["sourceUrl"] }` to the `Recipe` selection set.

Step 2: Add `sourceUrl: String?` to `RecipeDetail` model and update `RecipeDetail.from(graphQL:)` to map it. In `RecipeDetailView`, replace the hardcoded `Link(destination: URL(string: "https://spoonacular.com/food-api")!)` with a conditional: show the per-recipe `sourceUrl` link when non-nil, fall back to the generic Spoonacular link otherwise.

**No full codegen run is required** since the generated files are committed directly in this project. Surgical edits to the generated file are acceptable.

### 4. Search UI Wiring

**Backend:** `searchRecipes(input: SearchRecipesInput)` returns `RecipeConnection` (same cursor-paginated type as `popularRecipes`). `SearchRecipesInput` fields: `query`, `cuisines`, `diets`, `intolerances`, `first`, `after`.

**iOS gap:** No `SearchRecipesQuery` exists in `KindredAPI`. No search UI exists in `FeedFeature`.

**New GraphQL operation to add** (new file in `KindredAPI/Sources/Operations/Queries/`):
```graphql
query SearchRecipes($input: SearchRecipesInput!) {
  searchRecipes(input: $input) {
    edges {
      node {
        id name prepTime calories imageUrl popularityScore
        engagementLoves dietaryTags cuisineType ingredientNames
      }
    }
    pageInfo { endCursor hasNextPage }
  }
}
```

After running Apollo codegen, this generates `SearchRecipesQuery` in `KindredAPI`. The `SearchRecipesInput` type likely needs to be added to the Apollo schema SDL as well (verify against backend introspection).

**New reducer:** Add `SearchReducer` as a child presented via `@Presents` in `FeedReducer`, following the existing `recipeDetail` and `paywall` pattern. The search state holds `query: String`, `results: [RecipeCard]`, `isSearching: Bool`, `searchCursor: String?`. The reducer calls `apolloClient.fetch(query: SearchRecipesQuery(...))`.

**UI integration:** Add a search entry point to `FeedView` — a search icon in the navigation bar that presents `SearchView`. Using SwiftUI's `searchable` modifier on the `NavigationStack` is an alternative but less compatible with the TCA `@Presents` pattern already in use.

**`RecipeCard.from(searchNode:)`** — add a new static factory on `RecipeCard` for the search result node type (analogous to existing `from(popularRecipe:)`).

### 5. Dietary Filter Pass-Through to Spoonacular

**Current state:** Dietary filtering is client-side only (`applyDietaryFilter` in `FeedReducer`). The `activeDietaryFilters: Set<String>` state holds values like `"Vegan"`, `"Keto"`, `"Gluten-Free"`.

**Backend:** `SearchRecipesInput.diets` accepts Spoonacular diet strings (`"vegan"`, `"ketogenic"`, `"glutenfree"` etc.) and `SearchRecipesInput.intolerances` accepts strings like `"gluten"`, `"dairy"`, `"tree nut"`.

**Mapping needed:** Kindred's internal tags → Spoonacular API parameter strings. Add a `DietaryTagMapper` utility to `FeedFeature/Sources/Utilities/`:

| Kindred tag | Spoonacular `diets` | Spoonacular `intolerances` |
|---|---|---|
| Vegan | `vegan` | — |
| Vegetarian | `vegetarian` | — |
| Keto | `ketogenic` | — |
| Halal | `halal` | — |
| Pescatarian | `pescatarian` | — |
| Gluten-Free | — | `gluten` |
| Dairy-Free | — | `dairy` |
| Nut-Free | — | `tree nut`, `peanut` |
| Low-Carb | `low carb` | — |
| Kosher | `kosher` | — |

The `SearchReducer` reads `activeDietaryFilters` from `FeedReducer.State` (or accepts them as a parameter), runs them through `DietaryTagMapper`, and populates `SearchRecipesInput.diets` and `.intolerances` accordingly.

**The existing `applyDietaryFilter` function is kept** for the feed (filters the cached 20-card stack client-side). Server-side filtering via `searchRecipes` is additive — it applies when the user explicitly searches and hits the backend.

---

## Installation

No new packages to install. All work is within existing packages.

```bash
# After modifying GraphQL operation files, regenerate Apollo types:
cd Kindred/Packages/KindredAPI
apollo-ios-cli generate --path apollo-codegen-config.json
```

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|---|---|---|
| Custom `SpeechSynthesizerClient` (~60 lines) | `swift-tts` SPM package | Only if the project needed AsyncStream progress tracking and didn't already have a matching client pattern. Adding a package for this is not justified. |
| Surgical edit to `RecipeDetailQuery.graphql.swift` | Full Apollo codegen re-run | Full codegen is better if a `.graphql` source file exists. In this project the generated files are committed directly — surgical edit is acceptable. |
| Present `SearchView` via TCA `.ifLet` | Extend `FeedReducer` with inline search state | Inline is also valid but `FeedReducer` is already ~900 lines. A presented child store cleanly separates concerns. |
| Server-side dietary filtering via `searchRecipes` + client-side `applyDietaryFilter` | Server-side only | Client-side filtering for the feed (20-card local cache) is instantaneous and offline-capable. Server-side filtering for search hits all 150-req/day Spoonacular data. Both modes are complementary and needed. |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|---|---|---|
| `AVSpeechSynthesizer.usesApplicationAudioSession = false` | Breaks the `.playback` AVAudioSession category, loses background audio and Now Playing controls | Keep `usesApplicationAudioSession = true` (the default); manage session deactivation manually after synthesis completes |
| Personal Voice API (`requestPersonalVoiceAuthorization`) | Requires users to have set up Personal Voice in iOS Accessibility settings. Fewer than 1% of users have this. It is an accessibility feature, not a product tier. | Use standard `AVSpeechSynthesisVoice(language: "en-US")` for free tier |
| `AVSpeechSynthesizer` for Pro tier | Quality gap versus ElevenLabs is the entire Pro value proposition. Same engine for both tiers destroys upgrade incentive. | Keep ElevenLabs cloned voices exclusively for Pro |
| Concurrent `AVSpeechSynthesizer` and `AVPlayer` | Both attempt to control `AVAudioSession`; concurrent use causes audio session conflicts and ducking artifacts | Gate via a single `isNarrating: Bool` state — stop synthesizer before starting AVPlayer and vice versa |

---

## Version Compatibility

| Package | Version | Compatibility Notes |
|---|---|---|
| AVSpeechSynthesizer | iOS 17.0+ | Min deployment target is iOS 17.0 — no availability guards needed |
| Apollo iOS | 2.0.6 | Adding new operation files does not require a version bump |
| TCA | 1.x (existing) | `SpeechSynthesizerClient` follows same `@DependencyClient` macro pattern as `AudioPlayerClient` — no compatibility concerns |
| AVAudioSession | iOS 17.0+ | `.playback` category already configured in `AppDelegate` — synthesizer inherits this when `usesApplicationAudioSession = true` |

---

## Sources

- [AVSpeechSynthesizer — Apple Developer Documentation](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer) — background audio behavior, `usesApplicationAudioSession` property (HIGH confidence)
- [Using Personal Voice in an iOS app — Ben Dodson, 2024](https://bendodson.com/weblog/2024/04/03/using-your-personal-voice-in-an-ios-app/) — Personal Voice API scope and limitations, confirms it is an accessibility feature not a general TTS replacement (HIGH confidence)
- [WWDC23: Extend Speech Synthesis with personal and custom voices](https://developer.apple.com/videos/play/wwdc2023/10033/) — iOS 17 AVSpeechSynthesizer capabilities overview (HIGH confidence)
- [swift-tts — renaudjenny/swift-tts](https://github.com/renaudjenny/swift-tts) — evaluated and rejected; overhead not justified for this use case
- [Apple Developer Forums: AVSpeechSynthesizer in background](https://developer.apple.com/forums/thread/27097) — background audio session behavior (MEDIUM confidence — forum post, corroborated by project's existing `UIBackgroundModes: audio`)
- Codebase inspection: `VoicePlaybackReducer.swift`, `FeedReducer.swift`, `RecipeDetailModels.swift`, `RecipeDetailQuery.graphql.swift`, `recipe.model.ts`, `recipes.resolver.ts`, `search-recipes.input.ts` — direct source of truth for all integration points (HIGH confidence)

---

*Stack research for: Kindred v5.1 Gap Closure (AVSpeechSynthesizer, voice tier routing, sourceUrl, search, dietary filters)*
*Researched: 2026-04-12*
