# Feature Research

**Domain:** iOS cooking app — v5.1 Gap Closure features
**Researched:** 2026-04-12
**Confidence:** HIGH (all findings verified against live codebase + backend source)

---

## Context: What This Milestone Closes

v5.0 shipped with five known deferred gaps. This research documents each gap's exact state in the codebase, the expected behavior after the fix, complexity, and dependencies.

| Gap | Current State | Target State |
|-----|--------------|--------------|
| Free-tier voice narration | No audio for free users (ElevenLabs-only path, fails if no profile) | AVSpeechSynthesizer speaks recipe steps in-app |
| Voice tier routing | All users hit ElevenLabs backend; no tier gate | Free → AVSpeech, Pro → ElevenLabs |
| Per-recipe sourceUrl wiring | `RecipeDetailQuery` omits `sourceUrl` + `sourceName` fields | Detail view footer links to real source URL |
| Search UI wiring | No search bar in FeedView; `searchRecipes` GraphQL endpoint exists but unused | Search bar in feed → `searchRecipes` query with text + dietary params |
| Dietary filter pass-through | Chips trigger client-side filter on cached `allRecipes`; no server round-trip | Chip toggle calls `searchRecipes` with `diets`/`intolerances` params |

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing = product feels broken.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Voice narration for free users | Pro gate on the app's core hook destroys conversion; users abandon before paying | MEDIUM | `AVSpeechSynthesizer` is built into iOS, zero cost. Must speak recipe `steps[].text` in order. No backend required. |
| Clickable source attribution | Spoonacular API terms require attribution. Recipe detail currently shows a static "Powered by Spoonacular" footer — not linked to the actual recipe source. | LOW | `sourceUrl` + `sourceName` already exist in backend `Recipe` GraphQL model (nullable). GraphQL query just needs the two fields added. iOS detail view needs `Link` or `SafariView`. |
| Search that returns results | A visible search bar (to be added) that does nothing is worse than no search bar. `searchRecipes` backend endpoint exists with `query`, `diets`, `intolerances`, `cuisines` params. | MEDIUM | New `SearchRecipesQuery.graphql` operation needed. `FeedReducer` needs search state + debounced effect. `FeedView` needs `.searchable` modifier wiring. |
| Dietary filters that actually filter | Chips currently do client-side filtering on the 20 cached cards. Switching from "Vegan" off to "Vegan" on returns the same 20 cards subset — server has thousands of Spoonacular-indexed vegan recipes. | MEDIUM | `dietaryFilterChanged` action needs to call `searchRecipes(diets: [...])` instead of `applyDietaryFilter(recipes: unswiped, filters: newFilters)`. Mapping required: `"Vegan"` → `"vegan"`, `"Gluten-Free"` → `"gluten free"` (Spoonacular naming). |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Seamless tier routing (AVSpeech → ElevenLabs) | User hears narration immediately as a free user, then hears the emotional uplift of a cloned voice when they upgrade. This is the conversion funnel: AVSpeech is free-tier bait, ElevenLabs is the aha moment. | LOW | Routing lives entirely in `VoicePlaybackReducer.selectVoice`. If `voiceId == "kindred-default"` AND `subscriptionStatus != .pro` → use `AVSpeechSynthesizer` path. If `subscriptionStatus == .pro` AND user has a cloned profile → use ElevenLabs path. The "Kindred Voice" default option already exists in the picker. |
| Dietary search (not just filter) | User can type "keto pasta" and get Spoonacular-backed results, not just filter the 20 cached popular recipes. | LOW | Composing the search text with dietary params into a single `searchRecipes` call gives this for free once search is wired. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Personal Voice integration (iOS 17 `requestPersonalVoiceAuthorization`) | Sounds more personal than generic TTS | Requires explicit user authorization, only works if user has created a Personal Voice on-device (Settings > Accessibility > Personal Voice). Near-zero adoption among general users. Adds auth flow complexity. | Use `AVSpeechSynthesisVoice` with `en-US` enhanced quality — significantly better than Compact, available on-device without extra auth |
| Streaming AVSpeech (speak steps one-at-a-time with delay) | Feels more like a real narrator | `AVSpeechSynthesizer` has no real streaming. Queuing utterances with `.speak()` in sequence means no seekbar, no duration, no step timestamps. The existing MiniPlayer UI (seekbar, skip +/-15s, step highlight) breaks entirely. | Speak full concatenated text as one utterance, or speak step-by-step using delegate callbacks (`speechSynthesizer(_:didFinish:)`) and advance step index manually |
| Per-step pausing (auto-pause after each step awaiting "next") | Cookbooks do this | Adds a confirmation UI pattern that conflicts with the "ambient narration while cooking" UX. If users have dirty hands, they can't tap "Next". | Support `.skipForward` to jump to next step via existing 30s skip button |
| Re-ranking search results by pantry match | Surfaces recipes user can cook from their pantry | Requires merging `searchRecipes` results with local pantry — extra async join step. Not critical for v5.1. | Pantry match % badge already shown on feed cards; apply same logic to search result cards post-fetch |

---

## Feature Dependencies

```
[Voice Tier Routing]
    └──requires──> [AVSpeechSynthesizer Narration] (free path must exist before routing can branch)
    └──reads──> [subscriptionStatus in VoicePlaybackReducer.State] (already present)
    └──reads──> [voiceId == "kindred-default"] (already present in picker)

[Dietary Filter Pass-through]
    └──requires──> [Search UI Wiring] (both use searchRecipes query; share same GraphQL operation)
    └──shares──> [SearchRecipesQuery.graphql] (one new operation file serves both features)

[Search UI Wiring]
    └──requires──> [SearchRecipesQuery.graphql operation] (new file in NetworkClient/Sources/GraphQL/)
    └──requires──> [Apollo codegen re-run] (generates KindredAPI.SearchRecipesQuery Swift type)
    └──writes──> [FeedReducer search state] (searchText, isSearching, searchResults)

[sourceUrl Wiring]
    └──requires──> [RecipeDetailQuery.graphql add 2 fields] (sourceUrl, sourceName)
    └──requires──> [Apollo codegen re-run] (updates RecipeDetailQuery fragment)
    └──requires──> [RecipeDetailModels update] (RecipeDetail struct needs sourceUrl: String?)
    └──requires──> [RecipeDetailView update] (render footer Link)
```

### Dependency Notes

- **AVSpeechSynthesizer requires no new dependencies:** Framework is in `AVFoundation`, already imported in `AudioPlayerManager.swift`. No new SPM package needed.
- **Search and dietary filter share one GraphQL operation:** Write `SearchRecipesQuery.graphql` once; both features use `KindredAPI.SearchRecipesQuery`. This means they should be implemented in the same plan to avoid two Apollo codegen runs.
- **sourceUrl wiring is independent:** Can be done in a separate plan with zero risk to other features. The backend field exists, nullable, and resolves correctly (verified in `recipe.model.ts:155`).
- **Apollo codegen must run after any `.graphql` file change:** The generated `API.swift` / module sources in `KindredAPI` package must regenerate before Swift compilation succeeds.

---

## MVP Definition

### v5.1 Launch With

All five gaps must close before the next App Store build is submitted:

- [ ] AVSpeechSynthesizer narration path in `VoicePlaybackReducer` — free users hear recipe steps spoken by system TTS
- [ ] Voice tier routing gate — `subscriptionStatus == .pro` check routes to ElevenLabs; `.free`/`.unknown` routes to AVSpeech for "kindred-default" voice
- [ ] `sourceUrl` + `sourceName` added to `RecipeDetailQuery.graphql`, `RecipeDetail` model, and detail view footer
- [ ] `SearchRecipesQuery.graphql` operation file + Apollo codegen
- [ ] `FeedReducer` search state + debounced `searchRecipes` effect + clear action
- [ ] `FeedView` `.searchable` modifier or custom search bar wired to `FeedReducer`
- [ ] `dietaryFilterChanged` calls `searchRecipes` with mapped `diets` params instead of client-side filter

### Add After Validation (v5.2+)

- [ ] Step-sync for AVSpeech narration — use `AVSpeechSynthesizerDelegate.speechSynthesizer(_:willSpeakRangeOfSpeechString:utterance:)` to advance `currentStepIndex` live — trigger: AVSpeech adoption is confirmed working
- [ ] Search result pantry match % — apply `IngredientMatcher` to search results — trigger: search adoption confirmed
- [ ] Persistent search history — store recent queries in `UserDefaults` — trigger: user requests

### Future Consideration (v6+)

- [ ] Natural language dietary search ("low calorie breakfast without gluten") via Gemini prompt → `SearchRecipesInput` transformation — defer: adds latency and cost
- [ ] Cuisine + meal-type filter chips in search — extend `SearchRecipesInput.cuisines` — defer: surface area, not blocking

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| AVSpeechSynthesizer free-tier narration | HIGH — unblocks the core hook for non-Pro users | MEDIUM — new client + TCA dependency + audio session wiring | P1 |
| Voice tier routing | HIGH — conversion funnel depends on it; wrong routing = Pro users get TTS instead of ElevenLabs | LOW — single branch in `selectVoice` action after AVSpeech is built | P1 |
| sourceUrl wiring | MEDIUM — Spoonacular ToS attribution requirement; App Store rejection risk if audited | LOW — 2 GraphQL fields + 1 model field + 1 view change | P1 |
| Search UI wiring | HIGH — feed search is expected table stakes for any recipe app | MEDIUM — new GraphQL op + reducer state + debounce + FeedView UI | P1 |
| Dietary filter pass-through | HIGH — current client-side filtering is a hidden bug (wrong recipe set returned) | LOW-MEDIUM — shares SearchRecipesQuery; mapping layer needed for Spoonacular diet names | P1 |

---

## Implementation Notes Per Feature

### 1. AVSpeechSynthesizer Narration

**What to build:** A new `AVSpeechNarrationClient` (TCA dependency) that wraps `AVSpeechSynthesizer`. Must:
- Accept `[String]` of step text strings
- Support `speak()`, `pause()`, `resume()`, `stop()`, `setRate(Float)`
- Emit a step-completion stream so the reducer can advance `currentStepIndex`
- No seekbar support — `AVSpeechSynthesizer` does not support seeking by time offset. The MiniPlayer seekbar must be hidden or replaced with a step counter for AVSpeech playback.

**Key constraint:** `AVSpeechSynthesizer` cannot be bridged into the existing `audioPlayerClient` dependency because it does not produce a URL-based audio stream. The reducer needs a parallel code path — not a replacement — for when `voiceId == "kindred-default"` AND free tier. The existing ElevenLabs path remains unchanged.

**Voice quality:** `AVSpeechSynthesisVoice(language: "en-US")` defaults to Compact quality. Prefer `AVSpeechSynthesisVoice.speechVoices().first { $0.language == "en-US" && $0.quality == .enhanced }` which uses the neural Enhanced voice (auto-downloaded on iOS 16+). Fall back to Compact if Enhanced not available.

**Audio session:** The existing `AudioSessionConfigurator` in `VoicePlaybackFeature` already sets `.playback` category. `AVSpeechSynthesizer` respects the active audio session. No additional session configuration is needed.

**Step advancement:** Implement `AVSpeechSynthesizerDelegate.speechSynthesizer(_:didFinish:)` to emit a `stepFinished` event. The reducer maintains a `currentStepIndex` counter for AVSpeech playback. This gives coarse step tracking without byte-level timestamps.

### 2. Voice Tier Routing

**Routing logic in `selectVoice` action:**

```
if voiceId == "kindred-default" {
    if subscriptionStatus is .pro → fetch from backend (ElevenLabs default voice)
    else → use AVSpeech path with recipeSteps
} else {
    // user-cloned voice — only reachable if Pro (picker already enforces paywall for free users)
    → fetch from backend (ElevenLabs)
}
```

**Important:** The "Kindred Voice" default profile (`id: "kindred-default"`) is already prepended to the voice picker for all users. The paywall is already shown when a non-Pro user taps a cloned voice. The routing gate belongs only in `selectVoice`, not in picker logic.

### 3. sourceUrl Wiring

**GraphQL change** — add to `RecipeQueries.graphql` inside the `recipe(id: $id)` selection:
```graphql
sourceUrl
sourceName
```

**Model change:** `RecipeDetail` struct in `RecipeDetailModels.swift` needs `sourceUrl: String?` and `sourceName: String?`.

**View change:** In `RecipeDetailView`, the existing static Spoonacular attribution footer becomes a `Link("View on \(sourceName ?? "Spoonacular")", destination: url)` where `url = URL(string: sourceUrl ?? "https://spoonacular.com")`. Guard against nil and malformed URL.

**Backend reality:** `sourceUrl` is populated by the Spoonacular mapper (`recipe-mapper.ts:31`). It is nullable — some pre-Spoonacular recipes in the DB may lack it. The view must handle nil gracefully (fall back to static text).

### 4. Search UI Wiring

**New GraphQL operation** (suggested path `NetworkClient/Sources/GraphQL/SearchQueries.graphql`):
```graphql
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

**FeedReducer state additions:**
- `searchText: String = ""`
- `isSearching: Bool = false`
- `searchResults: [RecipeCard] = []`
- New actions: `searchTextChanged(String)`, `searchResultsLoaded(Result<[RecipeCard], Error>)`, `clearSearch`

**Debounce:** 350ms debounce on `searchTextChanged` before firing GraphQL query. Use TCA `CancelID` pattern (already established in this reducer).

**FeedView:** Add `.searchable(text: $store.searchText.sending(\.searchTextChanged))` to the `NavigationStack`. When `isSearching` is true, replace `SwipeCardStack` with a `LazyVStack` of search result cards.

**Empty state:** When search returns 0 results, show "No recipes found for '...'". When `searchText` is empty, revert to normal popular feed (`PopularRecipesQuery`).

### 5. Dietary Filter Pass-through

**Spoonacular diet name mapping** (required — Spoonacular uses lowercase with different spellings):

| App chip tag | Spoonacular `diets` param | Notes |
|---|---|---|
| `"Vegan"` | `"vegan"` | |
| `"Vegetarian"` | `"vegetarian"` | |
| `"Gluten-Free"` | via `intolerances: ["gluten"]` | Spoonacular uses intolerances, not diets |
| `"Dairy-Free"` | via `intolerances: ["dairy"]` | Same as above |
| `"Keto"` | `"ketogenic"` | Spoonacular spelling |
| `"Halal"` | `"halal"` | |
| `"Nut-Free"` | via `intolerances: ["tree nut", "peanut"]` | |
| `"Kosher"` | `"kosher"` | |
| `"Low-Carb"` | no direct equivalent | Pass as empty; rely on text search |
| `"Pescatarian"` | `"pescetarian"` | Spoonacular spelling differs |

**Behavior change in `dietaryFilterChanged`:** Instead of `applyDietaryFilter(recipes: unswiped, filters: newFilters)`, dispatch a `searchRecipes` call with mapped `diets` + `intolerances` params. When all filters are cleared, revert to `PopularRecipesQuery`. This means dietary filter and free-text search share the same `searchResults` display path and the same `isSearching` state flag.

**Compose with search text:** If `searchText` is non-empty AND dietary filters are active, compose both into one `searchRecipes(input: SearchRecipesInput(query: searchText, diets: mapped, intolerances: mapped))` call. `SearchRecipesInput` supports this natively.

---

## Sources

- `VoicePlaybackFeature/Sources/Player/VoicePlaybackReducer.swift` — current narration flow (ElevenLabs-only path, no free-tier branch)
- `FeedFeature/Sources/Feed/FeedReducer.swift:649-672` — current dietary filter (client-side only, `applyDietaryFilter`)
- `FeedFeature/Sources/Feed/DietaryChipBar.swift` — chip tag names (Title Case, 10 tags)
- `NetworkClient/Sources/GraphQL/RecipeQueries.graphql` — `RecipeDetailQuery` missing `sourceUrl`
- `NetworkClient/Sources/GraphQL/FeedQueries.graphql` — `PopularRecipesQuery` shape
- `backend/src/recipes/recipes.resolver.ts` — `searchRecipes` resolver exists and is live
- `backend/src/recipes/dto/search-recipes.input.ts` — `SearchRecipesInput` with `query`, `diets`, `intolerances`, `cuisines`, `first`, `after`
- `backend/src/graphql/models/recipe.model.ts:155` — `sourceUrl` field exists in GraphQL schema (nullable String)
- [AVSpeechSynthesizer — Apple Developer Documentation](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer)
- [Using Personal Voice in an iOS app — Ben Dodson, 2024](https://bendodson.com/weblog/2024/04/03/using-your-personal-voice-in-an-ios-app/)
- [Extend Speech Synthesis with personal and custom voices — WWDC23](https://developer.apple.com/videos/play/wwdc2023/10033/)

---

*Feature research for: Kindred v5.1 Gap Closure*
*Researched: 2026-04-12*
