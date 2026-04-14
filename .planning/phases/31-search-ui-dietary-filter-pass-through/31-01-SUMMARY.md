---
phase: 31-search-ui-dietary-filter-pass-through
plan: 01
subsystem: api
tags: [apollo, graphql, tca, search, dietary-filters, spoonacular]

requires:
  - phase: 29-source-attribution-wiring
    provides: Apollo codegen pipeline and FeedFeature package structure

provides:
  - SearchRecipes GraphQL operation in FeedQueries.graphql
  - SearchRecipesQuery.graphql.swift and SearchRecipesInput.graphql.swift Apollo types
  - RecipeCard.from(searchRecipe:) factory method
  - mapChipsToSearchParams() chip-to-Spoonacular parameter mapping (7 diets, 3 intolerances)
  - FeedMode enum (browse/search) in FeedReducer
  - Search state fields in FeedReducer.State
  - 5 search actions with debounce, pagination, and quota error handling in FeedReducer

affects:
  - 31-02 (search UI will bind to search actions and FeedMode)
  - FeedFeature consumers that present search results

tech-stack:
  added: []
  patterns:
    - "SearchDebounceID enum with .debounce case for TCA cancellable search"
    - "mapChipsToSearchParams() pure function at file scope in FeedModels.swift"
    - "apolloClient.fetch with .networkOnly cache policy for search queries"
    - "Pagination via cursor: nil = fresh search (replace), cursor != nil = append"

key-files:
  created:
    - Kindred/Packages/KindredAPI/Sources/Operations/Queries/SearchRecipesQuery.graphql.swift
    - Kindred/Packages/KindredAPI/Sources/Schema/InputObjects/SearchRecipesInput.graphql.swift
  modified:
    - Kindred/Packages/NetworkClient/Sources/GraphQL/FeedQueries.graphql
    - Kindred/Packages/FeedFeature/Sources/Models/FeedModels.swift
    - Kindred/Packages/FeedFeature/Sources/Feed/FeedReducer.swift

key-decisions:
  - "SearchDebounceID uses enum case (.debounce) not type for TCA .cancel(id:) — type-based approach rejected by Swift compiler"
  - "executeSearch uses .networkOnly cache policy — search results must always be fresh"
  - "dietaryFilterChanged in search mode re-triggers server-side executeSearch instead of client-side applyDietaryFilter"
  - "mapChipsToSearchParams is file-scoped public func (not method) to match plan spec and enable independent testing"

patterns-established:
  - "Chip mapping: chipToSpoonacularDiet and chipToSpoonacularIntolerance private dicts with public mapChipsToSearchParams()"
  - "Search pagination: cursor==nil means fresh (replace), cursor!=nil means pagination (append)"

requirements-completed:
  - SEARCH-01
  - SEARCH-03
  - FILTER-01
  - FILTER-02

duration: 18min
completed: 2026-04-14
---

# Phase 31 Plan 01: Search + Dietary Filter Data Layer Summary

**SearchRecipes Apollo operation + FeedReducer search state/actions/debounce with chip-to-Spoonacular parameter mapping**

## Performance

- **Duration:** ~18 min
- **Started:** 2026-04-14T14:27:00Z
- **Completed:** 2026-04-14T14:45:24Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added `SearchRecipes` GraphQL query to FeedQueries.graphql and ran apollo-ios-cli codegen to generate `SearchRecipesQuery.graphql.swift` and `SearchRecipesInput.graphql.swift`
- Added `RecipeCard.from(searchRecipe:)` factory and `mapChipsToSearchParams()` mapping all 10 dietary chips to correct Spoonacular diet/intolerance param values
- Extended FeedReducer with `FeedMode` enum, 8 search state fields, 5 search actions, 300ms debounce with 3-char guard, cursor pagination, quota error detection, and search-mode chip filter re-trigger

## Task Commits

1. **Task 1: Add SearchRecipes GraphQL operation and run Apollo codegen** - `ce50412` (feat)
2. **Task 2: Extend FeedReducer with search state, actions, debounce, and chip mapping** - `af2e31c` (feat)

## Files Created/Modified

- `Kindred/Packages/NetworkClient/Sources/GraphQL/FeedQueries.graphql` - Added SearchRecipes query operation
- `Kindred/Packages/KindredAPI/Sources/Operations/Queries/SearchRecipesQuery.graphql.swift` - Generated Apollo query type
- `Kindred/Packages/KindredAPI/Sources/Schema/InputObjects/SearchRecipesInput.graphql.swift` - Generated Apollo input type
- `Kindred/Packages/FeedFeature/Sources/Models/FeedModels.swift` - Added `from(searchRecipe:)` factory + chip mapping functions
- `Kindred/Packages/FeedFeature/Sources/Feed/FeedReducer.swift` - Added FeedMode, search state fields, 5 search actions, debounce, pagination, quota handling

## Decisions Made

- **SearchDebounceID enum case pattern**: Used `enum SearchDebounceID: Hashable { case debounce }` with `.cancel(id: SearchDebounceID.debounce)` instead of empty enum + `.cancel(id: SearchDebounceID.self)` — Swift compiler rejects empty enum type as Hashable in TCA context
- **networkOnly for search**: Search queries always use `.networkOnly` to avoid stale Apollo cache results
- **dietaryFilterChanged re-triggers search**: When `feedMode == .search && searchQuery.count >= 3`, chip filter change sends `.executeSearch` instead of applying `applyDietaryFilter` client-side; browse mode path unchanged

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed SearchDebounceID empty enum Hashable conformance failure**
- **Found during:** Task 2 (FeedReducer search actions)
- **Issue:** Plan specified `private enum SearchDebounceID: Hashable {}` (empty enum) and `cancel(id: SearchDebounceID.self)` — Swift compiler error: "type 'FeedReducer.SearchDebounceID.Type' cannot conform to 'Hashable'"
- **Fix:** Added `.debounce` case to the enum and used `cancel(id: SearchDebounceID.debounce)` / `cancellable(id: SearchDebounceID.debounce, cancelInFlight: true)` — matching the pattern used by VoicePlaybackReducer's `CancelID` enum
- **Files modified:** `FeedReducer.swift`
- **Verification:** Build succeeded (BUILD SUCCEEDED)
- **Committed in:** `af2e31c` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** Necessary correctness fix for TCA cancel ID pattern. No scope creep.

## Issues Encountered

None beyond the SearchDebounceID fix above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Search data layer complete — FeedReducer has all search state and actions ready for UI wiring
- Plan 31-02 can bind SearchBar UI to `searchQueryChanged`, display `searchResults` in search mode, and show `isSearching` spinner
- `mapChipsToSearchParams` and `FeedMode` are exported from FeedFeature package — no additional exports needed

---
*Phase: 31-search-ui-dietary-filter-pass-through*
*Completed: 2026-04-14*
