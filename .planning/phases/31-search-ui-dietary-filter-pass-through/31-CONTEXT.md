# Phase 31: Search UI + Dietary Filter Pass-Through - Context

**Gathered:** 2026-04-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire the search bar to the backend `searchRecipes` GraphQL endpoint and fix dietary chip filtering to pass Spoonacular-native `diets` and `intolerances` params instead of client-side filtering a 20-card local cache. No new backend work — all endpoints are deployed and operational.

</domain>

<decisions>
## Implementation Decisions

### Search bar placement & interaction
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

### Search results display
- Scrollable vertical list of large recipe cards (same card component as popular feed)
- No swipe-to-bookmark in search results — tap to open detail instead
- Paginated: 20 results initially, auto-load more on scroll (cursor pagination via `first`/`after`)
- Auto-load triggers when user scrolls within ~3 cards of the bottom, with spinner at bottom
- Cards show: hero image, name, dietary tag badges, popularity score, time, calories, ingredient match %
- Small colored dietary tag badges on each card (e.g., [Vegan] [GF]) to confirm filter matches
- Empty state: friendly message "No recipes found for 'xyz'. Try a broader search or remove filters." with [Clear Filters] button when chips are active — reuses EmptyStateView component

### Diet vs intolerance mapping
- Single chip bar (no visual split) — auto-map each chip to correct Spoonacular param behind the scenes
- Diet chips: Vegan, Vegetarian, Keto, Pescatarian, Low-Carb → `diets` param
- Intolerance chips: Gluten-Free, Dairy-Free, Nut-Free → `intolerances` param
- Halal, Kosher → `diets` param (Spoonacular treats these as diet types)
- Chips apply to BOTH popular feed AND search results — consistent behavior everywhere
- This replaces current client-side filtering with server-side filtering via searchRecipes

### Search-to-browse transition
- Clearing the search bar (X button) restores the popular feed exactly as it was
- Popular feed state (cards, swiped IDs, cursor position) preserved in memory while search is active
- Dietary chip selections persist across search/browse mode transitions
- Swiped cards remain swiped when returning to browse mode

### Quota handling
- If backend returns Spoonacular quota error, show "Recipe search is temporarily unavailable. Browse popular recipes instead."
- Search bar becomes disabled/grayed during quota exhaustion
- Popular feed continues working from pre-warmed cache

### Claude's Discretion
- Exact FeedMode enum design (browse vs search state management)
- SearchRecipesQuery GraphQL operation structure and codegen
- Whether to create a separate SearchResultCardView or adapt existing card for list layout
- Animation transitions between browse and search modes
- VoiceOver announcements for search state changes

</decisions>

<specifics>
## Specific Ideas

- Search bar should feel like the iOS App Store search — always there, inline results replace content
- Diet tag badges on cards should use the same chip styling as the DietaryChipBar for visual consistency
- The "both modes" decision means PopularRecipesQuery can potentially be replaced by searchRecipes(query: nil, diets: [...]) for filtered browse mode — unifying the data path

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `DietaryChipBar` (FeedFeature): Horizontal scrollable chip bar with 10 dietary tags, FlowLayout for AX sizes, clear-all button. Needs no visual changes — just needs to send filters to backend instead of client-side
- `DietaryChip` (FeedFeature): Individual chip component with selected/unselected styling
- `EmptyStateView` (DesignSystem): Reusable empty state with icon + message — use for no-results
- `RecipeCard` model: Already has `dietaryTags: [String]` and `ingredientNames: [String]` for client-side matching
- `RecipeDetailView` + `RecipeDetailReducer`: Full detail view with navigation, zoom transition on iOS 18+

### Established Patterns
- TCA reducer pattern: FeedReducer handles all feed state, actions, effects
- Apollo GraphQL with cursor pagination: `PopularRecipesQuery(first:, after:)` pattern already implemented
- Client-side dietary filtering: `applyDietaryFilter(recipes:filters:)` — will be replaced by server-side
- `FeedFiltersInput` GraphQL input: has `cuisineTypes`, `dietaryTags`, `mealTypes` — but backend `SearchRecipesInput` has `diets` + `intolerances` (separate params)

### Integration Points
- `FeedReducer.State`: needs search query string, search results array, feed mode enum (browse/search)
- `FeedReducer.Action`: needs search text changed, search results loaded, clear search actions
- `FeedView`: search bar above `DietaryChipBar`, conditional content based on feed mode
- `NetworkClient` or direct Apollo: needs `SearchRecipesQuery` GraphQL operation (codegen required)
- Backend `searchRecipes` resolver: accepts `SearchRecipesInput(query, cuisines, diets, intolerances, first, after)` and returns `RecipeConnection` (same shape as `popularRecipes`)

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 31-search-ui-dietary-filter-pass-through*
*Context gathered: 2026-04-14*
