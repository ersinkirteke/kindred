---
phase: 16-recipe-matching
plan: 01
subsystem: feed
tags: [ingredient-matching, swiftui, tca, pantry-integration]

# Dependency graph
requires:
  - phase: 13-manual-pantry-management
    provides: PantryFeature SPM package with PantryClient and PantryItem model
  - phase: 05-guest-browsing-feed
    provides: RecipeCard model and FeedReducer architecture
provides:
  - IngredientMatcher utility for normalized string matching with staple exclusion
  - MatchBadge component with color-coded match percentage display
  - RecipeCard model extension with ingredientNames and matchPercentage fields
  - FeedReducer match computation on feed load, refresh, and tab switch
affects: [17-expiry-tracking, recipe-detail-matching]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Client-side ingredient matching using normalized name comparison"
    - "Reactive match percentage computation on pantry changes"
    - "Conditional badge rendering based on auth state and pantry contents"

key-files:
  created:
    - Kindred/Packages/FeedFeature/Sources/Utilities/IngredientMatcher.swift
    - Kindred/Packages/FeedFeature/Sources/Feed/MatchBadge.swift
  modified:
    - Kindred/Packages/FeedFeature/Package.swift
    - Kindred/Packages/FeedFeature/Sources/Models/FeedModels.swift
    - Kindred/Packages/FeedFeature/Sources/Feed/RecipeCardView.swift
    - Kindred/Packages/FeedFeature/Sources/Feed/FeedReducer.swift

key-decisions:
  - "Use client-side matching instead of server-side to minimize latency and enable offline matching"
  - "Exclude common pantry staples (salt, pepper, water, oil) from match calculation to avoid inflated scores"
  - "Hide match badge entirely for guest users and empty pantry (authentication/pantry required)"
  - "Match % recalculates on tab switch to reflect pantry changes from other tabs"
  - "Use name-only matching (quantity-agnostic) for MVP - if user has ingredient at all, it counts"
  - "Apply normalization heuristics (strip qualifiers, lowercase, simple plurals) for fuzzy matching"

patterns-established:
  - "Badge overlay pattern: top-left for match %, top-right for viral, bottom-left for For You"
  - "IngredientMatcher.normalize() for consistent string comparison across app"
  - "withMatchPercentage() pattern for immutable struct updates in TCA"

requirements-completed: [MATCH-01, MATCH-02, MATCH-04]

# Metrics
duration: 26 min
completed: 2026-03-16
---

# Phase 16 Plan 01: Ingredient Match Percentage Badges Summary

**Client-side ingredient matching with normalized name comparison, colored match % badges (green >=70%, amber 50-69%), and reactive computation on feed load and tab switch**

## Performance

- **Duration:** 26 min
- **Started:** 2026-03-16T07:31:28Z
- **Completed:** 2026-03-16T07:44:47Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Recipe feed cards display match % badge showing pantry ingredient overlap
- IngredientMatcher utility normalizes ingredient names (strips qualifiers, handles plurals)
- Match % excludes common staples (salt, pepper, water, oil) and expired pantry items
- Badge uses WCAG AAA accessible colors (kindredSuccess green, kindredAccent amber)
- Match % recalculates automatically on feed load, refresh, pagination, and tab switch
- Guest users and empty pantry skip match computation (no badges shown)

## Task Commits

Each task was committed atomically:

1. **Tasks 1 & 2: Match badge + computation logic** - `0e66cb8` (feat)

**Plan metadata:** (pending - will be created in final commit)

_Note: Tasks 1 and 2 were tightly coupled (badge + computation), so they were committed together_

## Files Created/Modified

- `Kindred/Packages/FeedFeature/Package.swift` - Added PantryFeature dependency
- `Kindred/Packages/FeedFeature/Sources/Utilities/IngredientMatcher.swift` - String normalization, staple exclusion, match % computation
- `Kindred/Packages/FeedFeature/Sources/Models/FeedModels.swift` - Added ingredientNames and matchPercentage fields, withMatchPercentage() method
- `Kindred/Packages/FeedFeature/Sources/Feed/MatchBadge.swift` - Colored pill badge component (green/amber based on %)
- `Kindred/Packages/FeedFeature/Sources/Feed/RecipeCardView.swift` - Top-left MatchBadge overlay, accessibility label update
- `Kindred/Packages/FeedFeature/Sources/Feed/FeedReducer.swift` - computeMatchPercentages and matchPercentagesComputed actions, pantryClient dependency

## Decisions Made

1. **Client-side matching over server-side:** Local computation minimizes latency and enables offline matching. PantryItem data already synced locally via SwiftData, so no need for server roundtrip.

2. **Staple exclusion logic:** Exclude salt, pepper, water, cooking oil, butter, sugar, flour, garlic, onion from match calculation. These inflate scores since most users have them but they don't represent meaningful ingredient overlap.

3. **Name-only matching (quantity-agnostic):** If user has the ingredient at all in their pantry, it counts as matched regardless of quantity. Quantity comparison deferred to shopping list feature.

4. **Normalization heuristics:** Strip qualifiers ("fresh", "large", "organic"), lowercase, trim whitespace, simple plural removal (trailing "s" if length > 3). Balances fuzzy matching with simplicity.

5. **Hide badges for guest users:** Guest users have no pantry data, so match badges are meaningless. Only authenticated users with populated pantries see badges.

6. **Tab switch recalculation:** When user switches back to feed tab (onAppear with existing cards), recompute match % to reflect pantry changes made in Pantry tab.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

**1. Build error: Optional chaining on non-optional ingredients field**
- **Found during:** Task 1 (RecipeCard model extension)
- **Issue:** GraphQL ViralRecipesQuery.Data.ViralRecipe.ingredients is non-optional array, but code used `recipe.ingredients?.map`
- **Fix:** Removed optional chaining - changed to `recipe.ingredients.map { $0.name }`
- **Files modified:** FeedModels.swift
- **Verification:** Build succeeded after fix
- **Impact:** Minor - simple fix, caught by compiler

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Recipe feed cards display match % badges as designed
- IngredientMatcher utility ready for reuse in detail view and shopping list
- RecipeCard model carries ingredient names from GraphQL for matching
- Match % computation wired into feed lifecycle events
- Ready for plan 16-02 (detail view match state and shopping list generation)

## Self-Check: PASSED

Verified:
- IngredientMatcher.swift exists
- MatchBadge.swift exists
- Commit 0e66cb8 exists in git history

---
*Phase: 16-recipe-matching*
*Completed: 2026-03-16*
