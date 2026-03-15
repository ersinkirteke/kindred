# Phase 16: Recipe Matching - Context

**Gathered:** 2026-03-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Recipe feed cards display ingredient match percentage based on pantry contents. Users see a colored badge on each card showing how many ingredients they already have. In the recipe detail view, ingredients are color-coded as matched/missing, and a bottom sheet shopping list shows missing ingredients with share and checklist functionality. Match % recalculates automatically when pantry contents change.

</domain>

<decisions>
## Implementation Decisions

### Match Badge Design (Feed Card)
- Top-left overlay on hero image (same pattern as ViralBadge top-right, ForYouBadge bottom-left)
- Colored pill shape with percentage text (e.g. "85%")
- Green pill when >70% match, yellow pill when 50-70% match, hidden when <50% match
- Use existing DesignSystem colors (kindredSuccess for green, existing warning/accent for yellow) — must meet WCAG AAA contrast
- Subtle scale-in animation when badge first appears (respect reduceMotion)
- Hidden entirely when user has no pantry items (empty pantry = no badges anywhere)
- Badge does NOT change feed ranking — existing FeedRanker/CulinaryDNAEngine order stays

### Match Badge Design (Detail View)
- Show match % prominently near ingredients section with count breakdown: "4/6 ingredients (67%)"
- In IngredientChecklistView, color-code each ingredient inline: green checkmark indicator for ingredients user has, red/orange indicator for missing ones
- Reuses existing IngredientChecklistView component with added match state

### Ingredient Matching Logic
- Client-side matching — compute locally using PantryItem data from SwiftData against recipe ingredients
- Normalized name matching: strip qualifiers ("fresh", "large", "organic"), lowercase, trim — not category-level ("chicken breast" ≠ "chicken thigh")
- Client-side string normalization for recipe ingredients (RecipeIngredient doesn't have normalizedName — apply heuristic stripping)
- Name-only matching — if user has the ingredient at all, it counts as matched regardless of quantity
- Exclude common pantry staples from calculation (salt, pepper, water, cooking oil, etc.)
- Exclude expired pantry items (use PantryItem.expiryDate) — only non-expired, non-deleted items count
- Add ingredient names to the feed query (extend ViralRecipesQuery) so match % can be computed at card level
- Feed ranking unchanged — match badge is informational only, does not boost/demote cards

### Shopping List Experience
- Bottom sheet triggered from recipe detail view (not from feed card badge tap)
- Summary header at top: "You have 4 of 6 ingredients. Missing:"
- Missing items grouped by FoodCategory (Produce, Dairy, Grains, etc.) using existing FoodCategory enum
- Each item shows full quantities: "2 cups flour", "3 eggs" (uses RecipeIngredient quantity + unit)
- Checkable list — user can tap to check off items while shopping (temporary state, resets on sheet close)
- When all items checked off: show celebration message + "Ready to cook?" with link to start voice narration
- Copy to clipboard + iOS share sheet with plain text format: "Shopping list for [Recipe Name]:\n- 2 cups flour\n- 3 eggs\n..."
- Entry point: "Missing ingredients" button in detail view only — badge tap on card opens detail (existing behavior)

### Reactivity & Performance
- Recalculate match % on feed appear (tab switch or pull-to-refresh), not real-time reactive
- Current swipe stack cards only — no recalculation for past/bookmarked recipes
- No loading indicator — calculation is fast (local SwiftData query), badge appears when ready
- Detail view is static until reopened — pantry changes in background don't update open detail
- Fresh computation each time (no caching) — avoids stale state complexity
- On cold start: feed loads first, match badges computed async and appear after (no blocking)

### Claude's Discretion
- Exact list of common pantry staples to exclude
- Exact string normalization rules and qualifier word list
- Badge positioning fine-tuning (exact padding/offset on card)
- Shopping list bottom sheet height and drag behavior
- Celebration animation style when all shopping items checked
- How ingredient match state integrates with existing IngredientChecklistView's check/uncheck state

</decisions>

<specifics>
## Specific Ideas

- Badge should feel like a natural extension of the existing ViralBadge/ForYouBadge overlay pattern — same visual weight, just different position
- Shopping list celebration when all items checked should connect to voice narration feature ("Ready to cook?")
- The inline ingredient color-coding in detail view should be subtle — green/red indicators alongside existing checklist, not replacing it

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ViralBadge` / `ForYouBadge`: Overlay badge pattern on RecipeCardView — new MatchBadge follows same pattern
- `IngredientChecklistView`: Existing ingredient list with check/uncheck — extend with match state color coding
- `RecipeIngredient`: Has `name`, `quantity`, `unit`, `formattedText` — all needed for shopping list display
- `PantryItem`: SwiftData model with `normalizedName`, `foodCategory`, `expiryDate`, `isDeleted` — all matching inputs
- `PantryClient`: `fetchAllItems(userId:)` returns all pantry items for matching
- `FoodCategory` enum: Used for grouping shopping list items by category
- `DesignSystem` colors: `kindredSuccess`, `kindredAccent`, `kindredTextSecondary` for badge colors

### Established Patterns
- TCA (The Composable Architecture) for state management — matching logic lives in a reducer
- SwiftData for local persistence (PantryItem) — queries are fast and synchronous on MainActor
- Kingfisher for image loading (KFImage)
- `@ScaledMetric` for Dynamic Type support throughout card views
- `reduceMotion` environment check for animation accessibility

### Integration Points
- `RecipeCardView` — add MatchBadge overlay (top-left position)
- `FeedReducer` — trigger match % calculation on feed appear
- `RecipeDetailReducer` — compute match state for detail view ingredients
- `RecipeDetailView` — add match summary + shopping list button near ingredients section
- `ViralRecipesQuery` (GraphQL) — extend to include ingredient names per recipe
- `FeedModels.RecipeCard` — add ingredients field for client-side matching

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 16-recipe-matching*
*Context gathered: 2026-03-15*
