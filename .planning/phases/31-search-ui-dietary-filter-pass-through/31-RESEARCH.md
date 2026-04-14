# Phase 31: Search UI + Dietary Filter Pass-Through - Research

**Researched:** 2026-04-14
**Domain:** SwiftUI search bar, TCA state management, Apollo iOS codegen, Spoonacular API parameter mapping
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Search bar placement & interaction**
- Sticky search bar always visible above DietaryChipBar, below the location pill toolbar
- Tapping focuses the bar and shows keyboard; popular feed scrolls beneath both
- Inline replace: card stack is replaced by search results in the same view when query is active
- X button clears text and restores popular feed — no separate Cancel button
- Keyboard dismissed on scroll (.scrollDismissesKeyboard(.interactively))
- No recent searches or suggestions when search bar is empty — empty bar = popular feed
- 3-character minimum and 300ms debounce fire silently — no hint text about minimum
- Result count shown below chips: "12 vegan chicken recipes found" (existing DietaryChipBar filter-description area)
- Search requires internet — show "Search requires internet" message when offline; popular feed still works from cache
- Tapping a search result opens the same RecipeDetailView with same zoom transition (iOS 18+)
- Inline spinner replaces card area while loading — chips and search bar stay visible
- New query clears old results immediately + shows spinner (no stale results confusion)

**Search results display**
- Scrollable vertical list of large recipe cards (same card component as popular feed)
- No swipe-to-bookmark in search results — tap to open detail instead
- Paginated: 20 results initially, auto-load more on scroll (cursor pagination via `first`/`after`)
- Auto-load triggers when user scrolls within ~3 cards of the bottom, with spinner at bottom
- Cards show: hero image, name, dietary tag badges, popularity score, time, calories, ingredient match %
- Small colored dietary tag badges on each card (e.g., [Vegan] [GF]) to confirm filter matches
- Empty state: friendly message "No recipes found for 'xyz'. Try a broader search or remove filters." with [Clear Filters] button when chips are active — reuses EmptyStateView component

**Diet vs intolerance mapping**
- Single chip bar (no visual split) — auto-map each chip to correct Spoonacular param behind the scenes
- Diet chips: Vegan, Vegetarian, Keto, Pescatarian, Low-Carb → `diets` param
- Intolerance chips: Gluten-Free, Dairy-Free, Nut-Free → `intolerances` param
- Halal, Kosher → `diets` param (Spoonacular treats these as diet types)
- Chips apply to BOTH popular feed AND search results — consistent behavior everywhere
- This replaces current client-side filtering with server-side filtering via searchRecipes

**Search-to-browse transition**
- Clearing the search bar (X button) restores the popular feed exactly as it was
- Popular feed state (cards, swiped IDs, cursor position) preserved in memory while search is active
- Dietary chip selections persist across search/browse mode transitions
- Swiped cards remain swiped when returning to browse mode

**Quota handling**
- If backend returns Spoonacular quota error, show "Recipe search is temporarily unavailable. Browse popular recipes instead."
- Search bar becomes disabled/grayed during quota exhaustion
- Popular feed continues working from pre-warmed cache

### Claude's Discretion
- Exact FeedMode enum design (browse vs search state management)
- SearchRecipesQuery GraphQL operation structure and codegen
- Whether to create a separate SearchResultCardView or adapt existing card for list layout
- Animation transitions between browse and search modes
- VoiceOver announcements for search state changes

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SEARCH-01 | User can search recipes by keyword via search bar in feed | SearchBar in FeedView, `searchQuery` in FeedReducer.State, `SearchRecipesQuery` Apollo operation |
| SEARCH-02 | Search results display with same card layout as popular recipes feed | Reuse `RecipeCard` model + `RecipeCard.from(searchRecipe:)` mapping, adapt card for list layout |
| SEARCH-03 | Search includes debounce (300ms+) to respect Spoonacular quota (150 req/day) | TCA `debounce(id:for:scheduler:)` on `.searchQueryChanged` action |
| FILTER-01 | Dietary filter chips pass parameters through GraphQL to Spoonacular API | `SearchRecipesInput` already has `diets` + `intolerances` params; replace `applyDietaryFilter` with server-side call |
| FILTER-02 | Diet vs intolerance tags are correctly classified for Spoonacular API mapping | Static mapping table: Diet=[Vegan,Vegetarian,Keto,Pescatarian,Low-Carb,Halal,Kosher], Intolerance=[Gluten-Free,Dairy-Free,Nut-Free] |
</phase_requirements>

---

## Summary

Phase 31 is a pure iOS wiring phase — the backend `searchRecipes` GraphQL resolver is already deployed, fully operational, and returns `RecipeConnection` (the same shape as `popularRecipes`). No backend changes are needed. The work is:

1. **Add a `SearchRecipes` GraphQL operation** to `FeedQueries.graphql`, run Apollo codegen, and get a `SearchRecipesQuery` Swift type in KindredAPI.
2. **Extend FeedReducer** with a `FeedMode` enum (browse/search), `searchQuery: String`, `searchResults: [RecipeCard]`, search pagination state, and debounce logic.
3. **Update FeedView** to add a sticky search bar above `DietaryChipBar`, toggle between swipe card stack and scrollable results list, and show inline spinner/empty state.
4. **Fix dietary filter pass-through**: replace `applyDietaryFilter()` (client-side) with server-side param mapping — the 10 chip labels map cleanly to `diets` or `intolerances` Spoonacular params.

The biggest risk is TCA `debounce` effect wiring combined with search pagination (the auto-load-more scroll trigger). Everything else is straightforward extension of existing patterns.

**Primary recommendation:** Add `SearchRecipes` to the existing `FeedQueries.graphql`, run codegen with the pre-built apollo-ios-cli tar, then extend FeedReducer with `FeedMode` enum before touching any views.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ComposableArchitecture (TCA) | Already in project | State, actions, debounce | Existing reducer architecture |
| Apollo iOS | ~2.0.6 (Package.swift) | GraphQL code generation + fetch | Already wired via `apolloClient` dependency |
| SwiftUI | iOS 17+ | Search bar, list layout, transitions | Native — no new dependencies |
| Kingfisher | Already in project | Async image loading in result cards | Already used in RecipeCardView |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Dependencies (TCA) | Already in project | `@Dependency(\.apolloClient)` | Accessing network in reducer effects |
| DesignSystem (internal) | N/A | EmptyStateView, ErrorStateView, KindredButton | Empty/error state in search mode |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| TCA `.debounce` | `Task.sleep` inside `.run` | TCA debounce is cancellable + testable; Task.sleep is an anti-pattern in TCA |
| Inline search bar (`searchable`) | Custom `TextField` | `.searchable` is navigation-scoped; custom TextField gives full control over position and styling matching the design |

**Installation:** No new packages needed.

---

## Architecture Patterns

### Recommended Project Structure

The entire phase touches only `FeedFeature` package + `NetworkClient/Sources/GraphQL/FeedQueries.graphql`. No new packages, no new files in other packages beyond the codegen output in `KindredAPI`.

```
FeedFeature/Sources/
├── Feed/
│   ├── FeedReducer.swift          # Extend: FeedMode enum, search state, search actions, debounce
│   ├── FeedView.swift             # Extend: search bar above DietaryChipBar, conditional content
│   ├── SearchResultsView.swift    # NEW: scrollable list of search result cards
│   └── SearchResultCardView.swift # NEW or ADAPTED: list-layout card (no swipe gesture)
└── Models/
    └── FeedModels.swift           # Add: RecipeCard.from(searchRecipe:) mapping, chip→param mapping

NetworkClient/Sources/GraphQL/
└── FeedQueries.graphql            # Add: SearchRecipes query

KindredAPI/Sources/Operations/Queries/
└── SearchRecipesQuery.graphql.swift  # GENERATED by apollo codegen
KindredAPI/Sources/Schema/InputObjects/
└── SearchRecipesInput.graphql.swift  # GENERATED by apollo codegen
```

### Pattern 1: FeedMode Enum in TCA State

**What:** A `FeedMode` enum with `.browse` and `.search(query: String)` cases or a separate flat state approach.
**When to use:** Whenever reducer needs to fork behavior between two mutually exclusive display modes.

**Recommended design (flat, Equatable-friendly):**
```swift
public enum FeedMode: Equatable {
    case browse
    case search
}

// In FeedReducer.State:
public var feedMode: FeedMode = .browse
public var searchQuery: String = ""
public var searchResults: [RecipeCard] = []
public var isSearching: Bool = false        // spinner while awaiting results
public var searchError: String? = nil
public var searchEndCursor: String? = nil
public var searchHasNextPage: Bool = true
public var isQuotaExhausted: Bool = false
```

**Why flat over nested enum:** TCA `@ObservableState` works better with flat state — `@Bindable` store properties are accessible without pattern matching.

### Pattern 2: TCA Debounce

**What:** Cancel previous search effect and re-fire after 300ms idle.
**Reference:** TCA `.debounce(id:for:scheduler:)` operator on Effects.

```swift
// In FeedReducer body:
case let .searchQueryChanged(query):
    state.searchQuery = query
    guard query.count >= 3 else {
        // Clear results, return to browse presentation
        state.feedMode = query.isEmpty ? .browse : .search
        state.searchResults = []
        return .cancel(id: SearchDebounceID.self)
    }
    state.feedMode = .search
    state.isSearching = true
    state.searchResults = []   // clear immediately on new query

    return .run { [query, filters = state.activeDietaryFilters] send in
        try await Task.sleep(nanoseconds: 300_000_000)  // 300ms
        await send(.executeSearch(query: query, filters: filters, cursor: nil))
    }
    .cancellable(id: SearchDebounceID.self, cancelInFlight: true)

// Debounce cancel ID
private enum SearchDebounceID: Hashable {}
```

**Note:** Prefer `.cancellable(id:cancelInFlight:true)` + `Task.sleep` over TCA's `debounce` operator for clearer control of the 3-char guard logic.

### Pattern 3: Apollo SearchRecipes GraphQL Operation

Add to `NetworkClient/Sources/GraphQL/FeedQueries.graphql`:

```graphql
query SearchRecipes($input: SearchRecipesInput!) {
  searchRecipes(input: $input) {
    edges {
      node {
        id
        name
        description
        prepTime
        cookTime
        calories
        imageUrl
        imageStatus
        popularityScore
        engagementLoves
        dietaryTags
        difficulty
        cuisineType
        ingredients {
          name
          quantity
          unit
          orderIndex
        }
      }
      cursor
    }
    pageInfo {
      hasNextPage
      endCursor
    }
    totalCount
  }
}
```

Then run codegen (uses pre-built binary):
```bash
cd Kindred
tar -xf .build/checkouts/apollo-ios/CLI/apollo-ios-cli.tar.gz
./apollo-ios-cli generate --path apollo-codegen-config.json
```

This produces `SearchRecipesQuery.graphql.swift` and `SearchRecipesInput.graphql.swift` in `KindredAPI/Sources/`.

### Pattern 4: Chip→Spoonacular Parameter Mapping

```swift
// In FeedModels.swift or FeedReducer.swift:
private let dietChips: Set<String> = ["Vegan", "Vegetarian", "Keto", "Pescatarian", "Low-Carb", "Halal", "Kosher"]
private let intoleranceChips: Set<String> = ["Gluten-Free", "Dairy-Free", "Nut-Free"]

// Spoonacular API param values (lowercase, no hyphen):
private let chipToSpoonacularDiet: [String: String] = [
    "Vegan": "vegan",
    "Vegetarian": "vegetarian",
    "Keto": "ketogenic",
    "Pescatarian": "pescetarian",
    "Low-Carb": "paleo",     // closest Spoonacular diet type
    "Halal": "halal",        // Spoonacular supports halal as diet
    "Kosher": "kosher"
]

private let chipToSpoonacularIntolerance: [String: String] = [
    "Gluten-Free": "gluten",
    "Dairy-Free": "dairy",
    "Nut-Free": "tree nut"
]

func mapChipsToSearchParams(_ chips: Set<String>) -> (diets: [String], intolerances: [String]) {
    var diets: [String] = []
    var intolerances: [String] = []
    for chip in chips {
        if let diet = chipToSpoonacularDiet[chip] { diets.append(diet) }
        else if let intolerance = chipToSpoonacularIntolerance[chip] { intolerances.append(intolerance) }
    }
    return (diets, intolerances)
}
```

### Pattern 5: Search Results List Layout

The existing `RecipeCardView` has swipe gestures baked in and is sized for card stack (340pt wide × 400pt). For search results, create a `SearchResultCardView` that:
- Uses same `RecipeCard` model + same image loading (Kingfisher KFImage)
- Full-width layout (no fixed 340pt width, no swipe gesture)
- Shows dietary tag badges inline (small colored pill labels using `DietaryChip` style)
- Tap → `store.send(.openRecipeDetail(recipe.id))`
- matchedTransitionSource for iOS 18+ zoom transition

Alternatively, a lightweight adaptation with a boolean `isSearchResult` flag on RecipeCardView works if the gesture is gated. A separate `SearchResultCardView` is cleaner (no conditional gesture logic pollution).

### Pattern 6: Preserve Browse State During Search

The popular feed state is **already stored** in `state.cardStack`, `state.allRecipes`, `state.swipedRecipeIDs`, `state.endCursor`, `state.hasNextPage`. Since FeedMode only switches the *display*, browse state is automatically preserved. When user clears search bar, view switches back to showing `state.cardStack` — no restore logic needed.

### Anti-Patterns to Avoid
- **Fetching on every keystroke:** Never call `searchRecipes` on every character change — the debounce + 3-char guard is mandatory for quota (150 req/day).
- **Replacing browse state on search:** Search results go into separate `state.searchResults` array, never touching `state.cardStack` or `state.allRecipes`.
- **Client-side filter after server-side search:** Once chips map to Spoonacular params, `applyDietaryFilter()` must NOT be applied on top of search results — that would double-filter.
- **Re-running codegen manually every time:** Only needed when `.graphql` files change. Check if `SearchRecipesQuery.graphql.swift` already exists before running.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Debounce | `DispatchQueue.asyncAfter` + cancel token | TCA `.cancellable(id:cancelInFlight:true)` + `Task.sleep` | Actor-safe, testable, cancels correctly on new input |
| GraphQL operation type | Manual `URLSession` call + JSON decode | Apollo codegen `SearchRecipesQuery` | Type-safe, cached, consistent with existing pattern |
| Empty state view | Custom VStack with icon + text | `EmptyStateView` from DesignSystem | Already exists with correct styling |
| Dietary badge pills | New component | Style from `DietaryChip` (same fill/stroke, smaller size) | Visual consistency with chip bar |
| Cursor pagination | Manual offset tracking | `pageInfo.endCursor` from `RecipeConnection` | Same pattern as `PopularRecipesQuery` |

---

## Common Pitfalls

### Pitfall 1: Spoonacular Diet Param Value Mismatch
**What goes wrong:** Passing "Keto" as-is to Spoonacular `diets` param returns 0 results — Spoonacular expects "ketogenic". Similarly "Pescatarian" → "pescetarian".
**Why it happens:** App chip labels are human-readable; Spoonacular API expects its own enum values.
**How to avoid:** Use the `chipToSpoonacularDiet` mapping table — never pass chip label strings directly.
**Warning signs:** Backend returns results but they don't match the selected diet; 0 results for chips that should have results.

### Pitfall 2: TCA Debounce with 3-Char Guard Race
**What goes wrong:** User types 2 chars fast, then 3rd char. If debounce fires before 3-char check, you waste a quota request.
**Why it happens:** Guard must run BEFORE the debounce clock starts.
**How to avoid:** Check `query.count >= 3` synchronously in the action handler (state layer), cancel any in-flight effect, and only start the debounce timer after the guard passes.

### Pitfall 3: Apollo Codegen Not Regenerated After Adding Operation
**What goes wrong:** `SearchRecipesQuery` Swift type not found, build fails. Happens when `.graphql` file is added but codegen isn't re-run.
**Why it happens:** KindredAPI is pre-generated; it doesn't auto-regenerate on build.
**How to avoid:** Always run codegen explicitly after modifying any `.graphql` file. Check that `SearchRecipesQuery.graphql.swift` appears in `KindredAPI/Sources/Operations/Queries/` and `SearchRecipesInput.graphql.swift` appears in `KindredAPI/Sources/Schema/InputObjects/`.

### Pitfall 4: Search Empty State When Chips Active — Wrong Copy
**What goes wrong:** User searches "xyz" with Vegan chip active, gets 0 results, sees generic "No results" message without [Clear Filters] button.
**Why it happens:** Empty state view doesn't know whether filters are active.
**How to avoid:** Pass `hasActiveFilters: Bool` to the search empty state and show the [Clear Filters] button when true. The copy should reference both the query and the filters.

### Pitfall 5: Quota Error Detection
**What goes wrong:** Backend falls back to popular recipes silently when quota is exhausted; app displays search results that aren't actually search results.
**Why it happens:** `searchRecipes` has a `getQuotaExhaustedFallback` path that returns HTTP 200 with popular recipes instead of an error.
**How to avoid:** The backend's `RecipeConnection` doesn't have a quota-exhausted flag. Check if returned results match the search query (heuristic: if `totalCount` is suspiciously high for a specific search, or if the backend adds a quota field in future). For now, treat any successful response as valid. Show quota message only if backend returns a GraphQL error with a specific message. Document this limitation.

### Pitfall 6: `SearchResultCardView` Zoom Transition Source ID Collision
**What goes wrong:** If search results use the same `heroNamespace` and `matchedTransitionSource(id: recipe.id)` as browse cards, and a recipe appears in both browse and search, SwiftUI may animate the wrong element.
**Why it happens:** `matchedTransitionSource` IDs are namespace-scoped but if IDs overlap across views, transitions can be ambiguous.
**How to avoid:** Use the same `heroNamespace` (passed from FeedView) — this is fine since browse and search are mutually exclusive views (one is hidden when the other is active). The IDs won't conflict in practice.

---

## Code Examples

### RecipeCard Mapping for Search Results

The existing `RecipeCard.from(popularRecipe:)` maps from `PopularRecipesQuery.Data.PopularRecipes.Edge.Node`. Search results will use `SearchRecipesQuery.Data.SearchRecipes.Edge.Node` which has the same `RecipeCard` GraphQL type. Add a parallel factory:

```swift
// In FeedModels.swift
public static func from(searchRecipe node: KindredAPI.SearchRecipesQuery.Data.SearchRecipes.Edge.Node) -> RecipeCard {
    return RecipeCard(
        id: node.id,
        name: node.name,
        description: node.description,
        prepTime: node.prepTime,
        cookTime: node.cookTime,
        calories: node.calories,
        imageUrl: node.imageUrl,
        popularityScore: node.popularityScore,
        engagementLoves: node.engagementLoves ?? 0,
        dietaryTags: node.dietaryTags ?? [],
        difficulty: node.difficulty?.rawValue,
        cuisineType: node.cuisineType.rawValue,
        ingredientNames: (node.ingredients ?? []).map { $0.name }
    )
}
```

### FeedReducer State Extensions

```swift
// New state fields (add to FeedReducer.State):
public var feedMode: FeedMode = .browse
public var searchQuery: String = ""
public var searchResults: [RecipeCard] = []
public var isSearching: Bool = false
public var searchEndCursor: String? = nil
public var searchHasNextPage: Bool = true
public var isQuotaExhausted: Bool = false
public var searchTotalCount: Int = 0

public enum FeedMode: Equatable {
    case browse
    case search
}
```

### DietaryChipBar: Result Count Area

The `DietaryChipBar` already has a `chipDescription` area showing "Showing X recipes" when filters are active. Phase 31 adds a `resultCount` parameter so search mode can show "12 vegan chicken recipes found" in the same area. The chip bar itself needs no visual changes — just pass an optional override string:

```swift
// DietaryChipBar: add optional resultCountOverride parameter
// In .search mode, FeedView passes: "12 recipes found" (or "12 vegan recipes found")
// In .browse mode, passes nil (existing chipDescription logic used)
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Client-side `applyDietaryFilter()` | Server-side `diets`+`intolerances` params | Phase 31 | Correct filtering vs Spoonacular DB, not just tag matching on 20 cards |
| No search in feed | `searchRecipes` endpoint wired to search bar | Phase 31 | Users can find specific recipes by name/ingredient |

**Deprecated/outdated:**
- `applyDietaryFilter()` and `normalizeDietaryTag()` in FeedReducer.swift: still needed for browse mode until chips also trigger server-side filtering. After Phase 31, when chips are active in browse mode, the popular feed should ideally also be server-side filtered. However, `popularRecipes` doesn't accept diet params — so for browse mode, client-side filtering of the pre-warmed popular cache is still used. Only in `.search` mode (query present) does server-side filtering via `searchRecipes` apply. **The client-side filter functions are NOT removed in Phase 31** — they remain for browse-mode chip filtering.

---

## Open Questions

1. **Browse-mode chip filtering: client-side vs server-side unification**
   - What we know: `popularRecipes` doesn't accept `diets`/`intolerances` params. `searchRecipes(query: nil, diets: [...])` might work for filter-only browse.
   - What's unclear: Does backend accept `searchRecipes` with no `query` and only `diets`/`intolerances`? The `SearchRecipesInput.query` is optional (nullable). The service code defaults `query = ''`. This may work as a "show me all vegan recipes" query.
   - Recommendation: CONTEXT.md says chips apply to BOTH modes. Investigate whether `searchRecipes(input: { diets: ["vegan"] })` (no query) returns sensible results. If yes, unify. If quota is a concern (browse mode would now also cost quota), keep client-side for browse + server-side for search. Document the decision in the plan. LOW confidence until tested.

2. **Result count in search: where to display**
   - What we know: CONTEXT.md says "12 vegan chicken recipes found" below chips. `RecipeConnection.totalCount` field is available.
   - What's unclear: `totalCount` from `searchRecipes` reflects cached results, not true Spoonacular count. May be 0 initially then update after background refresh.
   - Recommendation: Show `searchResults.count` (local count) rather than `totalCount` for accuracy. "20 recipes found" when first page loaded.

---

## Sources

### Primary (HIGH confidence)
- Direct codebase inspection — FeedReducer.swift, FeedView.swift, FeedModels.swift, DietaryChipBar.swift, RecipeCardView.swift
- Backend source — `search-recipes.input.ts`, `recipes.service.ts`, `recipes.resolver.ts`
- GraphQL schema — `backend/schema.gql` lines 356-395 (RecipeCard type), 440-459 (SearchRecipesInput)
- Apollo codegen config — `Kindred/apollo-codegen-config.json`
- Existing codegen output — `PopularRecipesQuery.graphql.swift` as pattern reference

### Secondary (MEDIUM confidence)
- TCA debounce pattern: project history (Phase 23+ patterns), TCA documentation pattern for cancellable effects with `cancelInFlight: true`
- Spoonacular diet/intolerance param names: inferred from backend `search-recipes.input.ts` field descriptions ("e.g., vegetarian, vegan, keto", "e.g., gluten, dairy, nuts")

### Tertiary (LOW confidence)
- `searchRecipes(query: nil, diets: [...])` for browse-mode unification: untested, needs verification against live backend

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already in project, no new dependencies
- Architecture: HIGH — patterns directly derived from existing FeedReducer/FeedView code
- GraphQL codegen: HIGH — `apollo-codegen-config.json` and existing `.graphql` operations inspected
- Pitfalls: HIGH for debounce/mapping, MEDIUM for quota detection (backend behavior partially opaque)
- Spoonacular param values: MEDIUM — values inferred from backend descriptions, not verified against live Spoonacular docs

**Research date:** 2026-04-14
**Valid until:** 2026-05-14 (stable iOS/TCA/Apollo stack — 30-day window)
