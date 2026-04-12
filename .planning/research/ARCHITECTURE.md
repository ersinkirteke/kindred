# Architecture Research

**Domain:** iOS cooking app — v5.1 Gap Closure integration
**Researched:** 2026-04-12
**Confidence:** HIGH (all findings sourced from live codebase)

## Standard Architecture

### System Overview

```
┌──────────────────────────────────────────────────────────────┐
│                       iOS App (SwiftUI + TCA)                 │
├──────────────┬────────────────┬──────────────────────────────┤
│  FeedFeature │ VoicePlayback  │  MonetizationFeature         │
│  FeedReducer │  Feature       │  SubscriptionStatus          │
│  FeedView    │  VoicePlayback │  SubscriptionClient          │
│  DietaryChip │  Reducer       │  .free / .pro(expiresDate:)  │
│  SearchUI    │  AudioPlayer   │                              │
│  (MISSING)   │  Client        │                              │
├──────────────┴────────────────┴──────────────────────────────┤
│              KindredAPI (Apollo iOS 2.0.6)                    │
│  Generated: PopularRecipesQuery, RecipeDetailQuery,           │
│  NarrationUrlQuery, VoiceProfilesQuery                        │
│  MISSING: SearchRecipesQuery                                  │
├──────────────────────────────────────────────────────────────┤
│              NetworkClient (GraphQL .graphql files)           │
│  FeedQueries.graphql, RecipeQueries.graphql                   │
│  sourceUrl NOT in RecipeDetailQuery yet                       │
└─────────────────────┬────────────────────────────────────────┘
                      │ Apollo GraphQL over HTTPS
┌─────────────────────▼────────────────────────────────────────┐
│              NestJS Backend (api.kindredcook.app)             │
├──────────────┬────────────────┬──────────────────────────────┤
│  RecipesRe-  │  FeedService   │  SpoonacularService          │
│  solver      │  (PostGIS      │  150 req/day quota           │
│  searchRe-   │  spatial       │  cache-first pattern         │
│  cipes()     │  filtering)    │  6h TTL PostgreSQL cache     │
│  popularRe-  │  dietary tags  │                              │
│  cipes()     │  from DB only  │                              │
├──────────────┴────────────────┴──────────────────────────────┤
│  PostgreSQL 15 + PostGIS                                      │
│  Recipe.sourceUrl (Spoonacular attribution, mapped, stored)   │
│  Recipe.dietaryTags (PostgreSQL array, filter with @>)        │
└──────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Status for v5.1 |
|-----------|----------------|-----------------|
| `VoicePlaybackReducer` | Orchestrates narration: voice picker, cache-first GraphQL fetch, AVPlayer streaming | Needs tier routing branch |
| `AudioPlayerClient` | TCA dependency wrapping `AudioPlayerManager` (AVPlayer actor) | Interface is correct; new `AVSpeechClient` needed alongside it |
| `AudioPlayerManager` | AVPlayer actor: play/pause/seek/streams | No change needed |
| `FeedReducer` | Feed load, dietary filter (client-side), location, pagination | dietaryFilterChanged is client-only; no change to filter action |
| `RecipeDetailReducer` | Apollo `RecipeDetailQuery` fetch, listenTapped delegate | sourceUrl field missing from query and model |
| `RecipeDetailModels.RecipeDetail` | Domain model mapped from GraphQL | Add `sourceUrl: String?` field |
| `FeedQueries.graphql` | PopularRecipesQuery, FeedFilteredQuery | No change needed |
| `RecipeQueries.graphql` | RecipeDetailQuery | Add `sourceUrl` field to query |
| `NestJS RecipesResolver` | `searchRecipes(input: SearchRecipesInput)` endpoint | Already exists, not wired in iOS |
| `NestJS FeedService` | `buildFilterClause` applies dietaryTags via PostgreSQL `@>` operator | Already working; filters serve cached Spoonacular data |
| `SearchRecipesInput` DTO | `query, cuisines, diets, intolerances, first, after` | Already exists in backend |
| `MonetizationFeature.SubscriptionStatus` | `.free` / `.pro(expiresDate:, isInGracePeriod:)` | No change needed |

## Recommended Project Structure Changes

```
Kindred/Packages/VoicePlaybackFeature/Sources/
├── AudioPlayer/
│   ├── AudioPlayerClient.swift          [existing — no change]
│   ├── AudioPlayerManager.swift         [existing — no change]
│   └── AVSpeechClient.swift             [NEW — mirrors AudioPlayerClient interface]
├── Player/
│   └── VoicePlaybackReducer.swift       [modify — add tier routing]
└── Models/                              [existing — no change]

Kindred/Packages/NetworkClient/Sources/GraphQL/
├── RecipeQueries.graphql                [modify — add sourceUrl field]
└── SearchQueries.graphql                [NEW — SearchRecipes operation]

Kindred/Packages/KindredAPI/Sources/Operations/Queries/
├── RecipeDetailQuery.graphql.swift      [regenerate — add sourceUrl]
└── SearchRecipesQuery.graphql.swift     [NEW — generated from new .graphql file]

Kindred/Packages/FeedFeature/Sources/
├── RecipeDetail/
│   ├── RecipeDetailModels.swift         [modify — add sourceUrl to RecipeDetail struct]
│   └── RecipeDetailView.swift           [modify — show sourceUrl link]
├── Feed/
│   └── FeedView.swift                   [modify — wire search UI entry point]
└── Search/
    ├── SearchReducer.swift              [NEW — TCA reducer for search]
    └── SearchView.swift                 [NEW — search bar + results]
```

### Structure Rationale

- **`AVSpeechClient.swift` alongside `AudioPlayerClient.swift`:** Both are TCA DependencyKey-conforming structs. Keeping them adjacent makes the audio backend abstraction obvious.
- **`Search/` as a new folder in FeedFeature:** Search is feed-adjacent (shares RecipeCard model, taps into RecipeDetail), but has independent state lifecycle. A sibling folder prevents bloat in `Feed/`.
- **`SearchQueries.graphql` in NetworkClient:** All GraphQL operation source files live here; codegen picks them up.

## Architectural Patterns

### Pattern 1: Tier-Routing with Inline Subscription Check

**What:** In `VoicePlaybackReducer.selectVoice`, branch on `subscriptionStatus` before deciding which audio backend to use. Free tier synthesises locally with AVSpeech; Pro tier fetches from backend R2 CDN via existing `NarrationUrlQuery`.

**When to use:** Any time feature access depends on subscription tier within an existing TCA effect.

**Trade-offs:** Keeps all routing logic inside the reducer (testable). No new state shape required beyond what already exists (`subscriptionStatus` is already in `VoicePlaybackReducer.State`).

```swift
// In VoicePlaybackReducer, case .selectVoice(let voiceId):
// The kindred-default voice ID is the AVSpeech entry point for free users.
// Pro users see kindred-default plus cloned voices.

let isFree = state.subscriptionStatus == .free
          || state.subscriptionStatus == .unknown
          || voiceId == "kindred-default"

if isFree {
    // NEW branch — synthesise steps locally, no network call
    await send(.narrationReady(avSpeechMetadata))
} else {
    // EXISTING Pro path — voiceCache.getCachedAudio then NarrationUrlQuery
}
```

### Pattern 2: AVSpeechClient Mirroring AudioPlayerClient

**What:** A new TCA `DependencyKey`-conforming struct `AVSpeechClient` that wraps `AVSpeechSynthesizer`. It exposes `statusStream` and `progressStream` so `VoicePlaybackReducer` can consume it without knowing which backend is active.

**When to use:** Whenever a second audio backend is needed without forking the reducer's stream observation logic.

**Trade-offs:** `AVSpeechSynthesizer` does not expose `currentTime` natively. Use `AVSpeechSynthesizerDelegate.willSpeakRangeOfSpeechString` to compute approximate progress. Step-sync will be word-boundary accurate for AVSpeech, not millisecond-accurate like ElevenLabs. Duration is estimated from character count (~130 WPM at `AVSpeechUtteranceDefaultSpeechRate`).

**Key constraint:** `AVSpeechSynthesizer` and its delegate must be accessed from `@MainActor`. Inside TCA `.run` effects, use `await MainActor.run { ... }`.

```swift
// AVSpeechClient.swift — new file
public struct AVSpeechClient {
    // Takes steps array directly (not a URL)
    public var speak: @Sendable ([String]) async -> Void
    public var pause: @Sendable () async -> Void
    public var resume: @Sendable () async -> Void
    public var stop: @Sendable () async -> Void
    public var setRate: @Sendable (Float) async -> Void
    public var statusStream: @Sendable () async -> AsyncStream<PlaybackStatus>
    public var progressStream: @Sendable () async -> AsyncStream<Double>  // 0.0-1.0
    public var cleanup: @Sendable () async -> Void
}
```

The `narrationReady` metadata for the AVSpeech path sets `audioURL = "avs://local"` (sentinel value distinguishing it from a real CDN URL) and `duration` is estimated at synthesis time.

### Pattern 3: GraphQL Operation Addition for Search

**What:** Add `SearchQueries.graphql` to `NetworkClient/Sources/GraphQL/`, re-run Apollo codegen, which generates `SearchRecipesQuery.graphql.swift` in `KindredAPI`. Wire a new `SearchReducer` that holds independent state (query, results, isLoading, error).

**When to use:** Any new backend endpoint requires a `.graphql` operation file before Apollo-generated types are available.

**Trade-offs:** Apollo codegen must be re-run (existing project script handles this). The `SearchRecipesInput` maps directly to the existing backend DTO with no backend changes.

```graphql
# SearchQueries.graphql — new file
query SearchRecipes($input: SearchRecipesInput!) {
  searchRecipes(input: $input) {
    edges {
      node {
        id
        name
        description
        prepTime
        calories
        imageUrl
        popularityScore
        dietaryTags
        cuisineType
        ingredients { name quantity unit orderIndex }
      }
      cursor
    }
    pageInfo { hasNextPage endCursor }
    totalCount
  }
}
```

### Pattern 4: sourceUrl Field Addition

**What:** The backend `Recipe` GraphQL type already has `sourceUrl` with `@Field` decorator (confirmed at `recipe.model.ts:154`). The Prisma schema has `sourceUrl String?`. The Spoonacular mapper sets it from `spoon.sourceUrl`. The only gap is on the iOS side.

**Changes required:**
1. `RecipeQueries.graphql` — add `sourceUrl` and `sourceName` to the `recipe` query selection set
2. Re-run Apollo codegen
3. `RecipeDetail` struct — add `sourceUrl: String?` and update `from(graphQL:)` mapping
4. `RecipeDetailView` — render a tappable `Link` when `sourceUrl` is non-nil

## Data Flow

### Voice Tier Routing Flow (New)

```
RecipeDetailView.listenTapped
    ↓
RecipeDetailReducer.listenTapped
    → .delegate(.authGateRequested) if guest
    ↓ (authenticated)
AppReducer → VoicePlaybackReducer.startPlayback(recipeId:, recipeName:, steps:)
    → fetch voiceProfiles (existing GraphQL call)
    → fetch subscriptionStatus (existing subscriptionClient call)
    ↓
VoicePlaybackReducer.selectVoice(voiceId)
    [NEW BRANCH]
    subscriptionStatus == .free || voiceId == "kindred-default"
        → AVSpeechClient.speak(state.recipeSteps)
        → send .narrationReady(NarrationMetadata with audioURL = "avs://local")
    [EXISTING PRO BRANCH]
    subscriptionStatus == .pro && voiceId != "kindred-default"
        → voiceCache.getCachedAudio (existing)
        → OR NarrationUrlQuery → AVPlayer (existing)
    ↓
VoicePlaybackReducer.narrationReady
    → if metadata.audioURL == "avs://local":
        skip audioPlayer.play(url)
        start observing AVSpeechClient.statusStream + progressStream
    → else (existing path):
        audioPlayer.play(url)
        observe audioPlayer streams
```

### Search Flow (New)

```
FeedView search entry point (NEW — search icon or bar)
    ↓
SearchReducer.queryChanged(text)
    → debounce 300ms
    → SearchReducer.search(query, diets: activeDietaryFilters)
        → apolloClient.fetch(SearchRecipesQuery(input:))
        → SearchReducer.resultsLoaded([RecipeCard])
    ↓
SearchView shows results list
    → tap → FeedReducer.openRecipeDetail(recipeId)  [existing]
```

### Dietary Filter Pass-Through (Enhancement)

```
DietaryChipBar → FeedReducer.dietaryFilterChanged(Set<String>)
    → applyDietaryFilter(allRecipes, filters)  [client-side, existing, instant]
    → state.cardStack updated immediately

Enhancement (when client set is thin):
    if state.cardStack.count < 5 && !newFilters.isEmpty:
        → dispatch SearchRecipesQuery(input: { diets: mapToSpoonacular(newFilters) })
        → merge results into allRecipes (deduplicate by ID)
        → re-apply applyDietaryFilter

Mapping required (FeedReducer string → Spoonacular diet param):
    "Vegan"       → "vegan"
    "Vegetarian"  → "vegetarian"
    "Keto"        → "ketogenic"
    "Gluten-Free" → "gluten free"
    "Dairy-Free"  → (Spoonacular: use intolerances: "dairy")
    "Nut-Free"    → (Spoonacular: use intolerances: "tree nut,peanut")
```

### sourceUrl Display Flow (New)

```
RecipeDetailReducer.onAppear
    → apolloClient.fetch(RecipeDetailQuery)  [existing, now includes sourceUrl]
    → RecipeDetail.from(graphQL:)  [modified, maps sourceUrl]
    ↓
RecipeDetailView
    → recipe.sourceUrl != nil:
        Link("View Recipe Source", destination: URL(string: sourceUrl)!)
            opens in SFSafariViewController or external browser
```

## Integration Points

### New vs Modified Components

| Component | New / Modified | What Changes |
|-----------|---------------|--------------|
| `AVSpeechClient.swift` | NEW | TCA DependencyKey wrapping AVSpeechSynthesizer with statusStream + progressStream |
| `VoicePlaybackReducer.swift` | MODIFY | Tier check in `selectVoice`; AVSpeech path in `narrationReady` |
| `SearchQueries.graphql` | NEW | GraphQL operation for searchRecipes |
| `SearchRecipesQuery.graphql.swift` | NEW (generated) | Apollo codegen output |
| `SearchReducer.swift` | NEW | TCA reducer for search state |
| `SearchView.swift` | NEW | Search bar + results SwiftUI view |
| `RecipeQueries.graphql` | MODIFY | Add `sourceUrl`, `sourceName` to RecipeDetailQuery selection set |
| `RecipeDetailQuery.graphql.swift` | REGENERATE | Apollo codegen after .graphql change |
| `RecipeDetailModels.swift` | MODIFY | Add `sourceUrl: String?` to `RecipeDetail`; update `from(graphQL:)` |
| `RecipeDetailView.swift` | MODIFY | Render sourceUrl as tappable Link |
| `FeedView.swift` | MODIFY | Add search bar entry point / navigation to SearchView |

### External Service Boundaries

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| AVSpeechSynthesizer | Direct iOS framework, MainActor required | No internet needed; works offline; ~130 WPM at normal rate |
| Backend `searchRecipes` | Apollo `SearchRecipesQuery`, existing `apolloClient` dep | Already deployed; just needs iOS GraphQL operation |
| Backend `recipe.sourceUrl` | Apollo `RecipeDetailQuery` field addition | Field has `@Field` in GraphQL schema — zero backend work |
| Spoonacular (via backend) | Indirect — `SearchRecipesInput.diets` passes through `SpoonacularService.search()` | Backend already maps diet names to Spoonacular parameter |

### Internal Module Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| `FeedFeature` → `VoicePlaybackFeature` | `listenTapped` delegate → `AppReducer` → `startPlayback` | No change to this boundary |
| `VoicePlaybackFeature` → `MonetizationFeature` | `subscriptionClient.currentEntitlement()` | Already wired; `subscriptionStatus` already in `VoicePlaybackReducer.State` |
| `VoicePlaybackFeature` → `AVFoundation` | `AudioPlayerClient` (AVPlayer) + new `AVSpeechClient` (AVSpeechSynthesizer) | Both are TCA dependencies — injectable for tests |
| `FeedFeature.SearchReducer` → `KindredAPI` | `apolloClient.fetch(SearchRecipesQuery)` | Same `apolloClient` dependency used everywhere |
| Apollo cache on `RecipeDetailQuery` | Adding `sourceUrl` field changes the cache key | First load after app update fetches from network; subsequent loads are cached |

## Suggested Build Order

Build order respects dependency chains. Each phase is independently shippable.

**Phase 1 — sourceUrl (no new dependencies, pure field addition, ~30 min):**
1. Add `sourceUrl`, `sourceName` to `RecipeQueries.graphql` selection set
2. Re-run Apollo codegen
3. Add `sourceUrl: String?` to `RecipeDetail` struct + `from(graphQL:)` mapping
4. Add `Link("View Original", destination:)` in `RecipeDetailView` (guard on non-nil)

**Phase 2 — AVSpeechClient + tier routing (new dependency, modifies existing reducer, ~2 hrs):**
5. Implement `AVSpeechClient.swift` — `speak(steps:)`, delegate-based status/progress streams
6. Register `AVSpeechClient` in `DependencyValues`
7. In `VoicePlaybackReducer.selectVoice`: add tier branch
8. In `VoicePlaybackReducer.narrationReady`: handle AVSpeech path (skip `audioPlayer.play`, observe `avSpeechClient.statusStream`)
9. `VoicePickerView`: hide cloned voice slots from free-tier users (show only `kindred-default`)

**Phase 3 — Search UI wired to backend (~1.5 hrs):**
10. Add `SearchQueries.graphql` → re-run Apollo codegen
11. Implement `SearchReducer` + `SearchView`
12. Wire search entry point in `FeedView`

**Phase 4 — Dietary filter server-side supplement (depends on Phase 3, ~1 hr):**
13. In `dietaryFilterChanged`: check `state.cardStack.count < 5`; dispatch `SearchRecipesQuery` with diet mapping; merge and deduplicate results

## Anti-Patterns

### Anti-Pattern 1: Routing AVSpeech Through a Temp File and AVPlayer

**What people do:** Generate AVSpeech to a temp `.caf` file, then play that file via the existing `AudioPlayerClient` (AVPlayer) to avoid changing `VoicePlaybackReducer`.

**Why it's wrong:** `AVSpeechSynthesizer` writing audio to a file is not a public iOS API at iOS 17. The synthesizer only supports real-time playback via `speak()`. Writing to `AVAudioFile` requires an `AVAudioEngine` tap — significantly more complex, higher latency, more memory.

**Do this instead:** Implement `AVSpeechClient` as a parallel TCA dependency with its own streams. Let `VoicePlaybackReducer` activate one or the other based on tier.

### Anti-Pattern 2: Calling AVSpeechSynthesizer Off Main Thread

**What people do:** Call `AVSpeechSynthesizer.speak()` inside a TCA `.run` effect without `@MainActor` isolation, assuming async contexts are fine.

**Why it's wrong:** `AVSpeechSynthesizer` and its delegate methods are MainActor-bound. Calling from a background context causes silent failures or crashes on iOS 17.

**Do this instead:** In `AVSpeechClient.liveValue`, use `await MainActor.run { synthesizer.speak(utterance) }` inside async closures. All `AVSpeechSynthesizerDelegate` callbacks must be received on MainActor before being forwarded to `AsyncStream.Continuation`.

### Anti-Pattern 3: Bloating FeedReducer with Search State

**What people do:** Add `searchQuery: String`, `searchResults: [RecipeCard]`, `isSearching: Bool` directly to `FeedReducer.State`.

**Why it's wrong:** `FeedReducer.State` already has 20+ fields. Search has independent lifecycle from feed pagination, location, and DNA reranking. Every search keystroke would cause unnecessary TCA state comparisons against all feed state.

**Do this instead:** `SearchReducer` is a sibling reducer, either presented via `@Presents` from `FeedReducer` or as a separate coordinator-level feature. Its lifecycle is fully independent.

### Anti-Pattern 4: Client-Side Only Dietary Filtering

**What people do:** Rely entirely on `applyDietaryFilter(allRecipes:)` and consider the feature complete.

**Why it's wrong:** `allRecipes` is populated from `PopularRecipesQuery` (20 recipes, no diet-aware ordering). Filtering 20 generic popular recipes by "Vegan + Keto" may return 0 results, creating a dead feed. The current implementation even explicitly avoids server round-trips (`// Client-side filtering — no server round-trip needed` comment in FeedReducer).

**Do this instead:** Client-side filter is correct and should remain for instant response. Add a server-side supplement via `SearchRecipesQuery` with `diets` parameter when the filtered card stack drops below a threshold (e.g. 5 cards). This makes the dietary filter actually useful without removing the instant client-side UX.

## Sources

- Live codebase: `VoicePlaybackReducer.swift` — `subscriptionStatus` already in state, `selectVoice` is the routing point
- Live codebase: `AudioPlayerClient.swift` — interface shape to mirror for `AVSpeechClient`
- Live codebase: `FeedReducer.swift` — `applyDietaryFilter` is client-only (line 668 comment confirms intentional)
- Live codebase: `RecipeDetailModels.swift` — `sourceUrl` field absent from `RecipeDetail` struct
- Live codebase: `RecipeQueries.graphql` — `sourceUrl` not in RecipeDetailQuery selection set
- Live codebase: `backend/src/graphql/models/recipe.model.ts:154` — `sourceUrl` has `@Field` decorator (confirmed exposed)
- Live codebase: `backend/src/recipes/recipes.resolver.ts` — `searchRecipes` endpoint deployed
- Live codebase: `backend/src/feed/dto/feed-filters.input.ts` — `dietaryTags` in FeedFiltersInput but used only for DB filtering, not Spoonacular
- Live codebase: `MonetizationFeature/Sources/Models/SubscriptionModels.swift` — `SubscriptionStatus.free` / `.pro`
- Apple AVFoundation docs: `AVSpeechSynthesizer` MainActor requirement, delegate-based progress

---
*Architecture research for: Kindred iOS v5.1 Gap Closure*
*Researched: 2026-04-12*
