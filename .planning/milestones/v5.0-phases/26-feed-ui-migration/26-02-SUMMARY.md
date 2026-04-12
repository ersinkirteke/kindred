---
phase: 26-feed-ui-migration
plan: 02
subsystem: FeedFeature iOS
tags: [ui, migration, query-replacement, badge-swap, cursor-pagination]
dependency_graph:
  requires:
    - 26-01-PLAN.md (PopularRecipesQuery data layer)
  provides:
    - FeedReducer using PopularRecipesQuery with cursor pagination
    - PopularityBadge UI integrated across feed and detail views
    - "Popular Recipes" heading on feed
  affects:
    - FeedFeature package (7 files modified, 1 deleted)
tech_stack:
  added: []
  patterns: [cursor-based pagination, Relay-compatible pagination]
key_files:
  created: []
  modified:
    - Kindred/Packages/FeedFeature/Sources/Feed/FeedReducer.swift
    - Kindred/Packages/FeedFeature/Sources/Feed/RecipeCardView.swift
    - Kindred/Packages/FeedFeature/Sources/Feed/FeedView.swift
    - Kindred/Packages/FeedFeature/Sources/RecipeDetail/RecipeDetailModels.swift
    - Kindred/Packages/FeedFeature/Sources/RecipeDetail/ParallaxHeader.swift
    - Kindred/Packages/FeedFeature/Sources/RecipeDetail/RecipeDetailView.swift
    - Kindred/Packages/FeedFeature/Sources/Personalization/FeedRanker.swift
  deleted:
    - Kindred/Packages/FeedFeature/Sources/Feed/ViralBadge.swift
decisions:
  - decision: "Use endCursor/hasNextPage instead of offset-based pagination"
    rationale: "Cursor pagination is more robust for dynamic data and prevents duplicate items on page boundaries"
    alternatives: []
  - decision: "Show PopularityBadge when popularityScore >= 50"
    rationale: "Consistent threshold with MatchBadge visibility, ensures only truly popular recipes get the badge"
    alternatives: []
  - decision: "Reset cursor to nil when changing location or refreshing"
    rationale: "Location/refresh operations should start from page 1, not continue from previous cursor"
    alternatives: []
metrics:
  duration_minutes: 9
  tasks_completed: 2
  files_modified: 7
  files_deleted: 1
  commits: 2
  lines_changed: 175
  completed_date: "2026-04-06"
---

# Phase 26 Plan 02: Feed UI Migration with Cursor Pagination

Atomically migrated FeedReducer from ViralRecipesQuery to PopularRecipesQuery at all 4 call sites, swapped RecipeCardView badges from ViralBadge to PopularityBadge, added "Popular Recipes" heading to FeedView, and cleaned up all viral references across FeedFeature.

## Tasks Completed

### Task 1: FeedReducer Atomic Query Migration and Cursor Pagination
**Duration:** ~4 minutes
**Commit:** 525eec8

**Changes:**
- Replaced `currentPage: Int` with `endCursor: String?` in FeedReducer State
- Replaced `hasMorePages` with `hasNextPage` in State
- Updated `moreRecipesLoaded` action to carry cursor metadata: `newCursor: String?`, `hasMore: Bool`
- Added `updatePaginationCursor` internal action for setting cursor state

**4 ViralRecipesQuery Call Sites Migrated:**
1. **onAppear** (line 241): Changed to `PopularRecipesQuery(first: 20, after: nil)` with `.cacheFirst` policy
2. **refreshFeed** (line 461): Changed to `PopularRecipesQuery` with `.networkOnly`, resets cursor to nil
3. **changeLocation** (line 518): Changed to `PopularRecipesQuery` with `.networkOnly`, resets cursor
4. **connectivityChanged** (line 543): Changed to `PopularRecipesQuery` with `.networkOnly`

**Pagination Logic:**
- `loadMoreRecipes` now uses `endCursor` from state instead of page offset
- `moreRecipesLoaded` handler updates both cursor and hasNextPage flags
- Initial loads always use `after: nil` to start from beginning
- Connection metadata (`pageInfo.endCursor`, `pageInfo.hasNextPage`) extracted from GraphQL response

**Mapping Updates:**
- All calls use `connection.edges.map { RecipeCard.from(popularRecipe: $0.node) }`
- Fixed RecipesQuery and FeedFilteredQuery extension methods to use `popularityScore: nil`
- Removed all references to `isViral`, `velocityScore`, `currentPage`, `hasMorePages`

**Verification:** `grep -c "ViralRecipesQuery\|viralRecipes\|isViral\|velocityScore\|currentPage\|hasMorePages" FeedReducer.swift` returns 0

### Task 2: RecipeCardView Badge Swap, FeedView Heading, RecipeDetail/FeedRanker Cleanup
**Duration:** ~5 minutes
**Commit:** ecee8d8

**RecipeCardView Changes:**
- Replaced ViralBadge with PopularityBadge in topTrailing overlay
- Condition: `if let popularityScore = recipe.popularityScore, popularityScore >= 50`
- Updated accessibility label: `", \(popScore) percent popular"` instead of `", Viral recipe"`

**FeedView Changes:**
- Added "Popular Recipes" heading between DietaryChipBar and SwipeCardStack
- Font: `.kindredHeading1`
- Foreground: `.kindredTextPrimary`
- Padding: `.horizontal(KindredSpacing.lg)`

**RecipeDetailModels Changes:**
- Replaced `isViral: Bool` with `popularityScore: Int?` in RecipeDetail struct
- Updated init signature to accept `popularityScore`
- Updated `from(graphQL:)` mapping to set `popularityScore: nil` (RecipeDetailQuery doesn't have field yet)

**ParallaxHeader Changes:**
- Replaced `let isViral: Bool` with `let popularityScore: Int?`
- Updated badge overlay: `if let score = popularityScore, score >= 50 { PopularityBadge(percentage: score) }`

**RecipeDetailView Changes:**
- Updated ParallaxHeader call site: `popularityScore: recipe.popularityScore`

**FeedRanker Changes:**
- Updated comment: "Discovery ratio: 40% weight on popularity/variety" (was "velocity/virality")
- Replaced `velocityScore` normalization with `popularityScore` normalization
- Changed logic:
  ```swift
  let maxPopularity = recipes.compactMap(\.popularityScore).max() ?? 100
  let normalizedPopularity = Double(recipe.popularityScore ?? 0) / popularityNormalizer
  ```

**ViralBadge Deletion:**
- Deleted `Kindred/Packages/FeedFeature/Sources/Feed/ViralBadge.swift`

**Final Sweep:**
- Remaining reference: deprecated `from(graphQL recipe: ViralRecipesQuery.Data.ViralRecipe)` mapping in FeedModels.swift (intentional, will be removed in Plan 26-03)

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

**Manual Verification:**
1. `grep -r "ViralRecipesQuery\|ViralBadge\|isViral\|velocityScore" FeedFeature/Sources/ --include="*.swift"` → Only deprecated mapping method remains (expected)
2. `grep -c "PopularRecipesQuery" FeedReducer.swift` → 4 matches (all call sites migrated)
3. `grep "Popular Recipes" FeedView.swift` → Heading exists
4. `test ! -f ViralBadge.swift` → ViralBadge deleted

**Build Verification:**
- FeedFeature package compiles successfully (verified via xcodebuild)
- Note: VoicePlaybackFeature has unrelated build error (VoiceProfilesQuery missing) - out of scope for this plan

## Implementation Notes

**Cursor Pagination Flow:**
1. Initial load: Query with `after: nil`, store `endCursor` and `hasNextPage` from response
2. Load more: Query with `after: endCursor`, update cursor from new response
3. Refresh/location change: Reset cursor to nil, start from beginning
4. Deduplication: Existing logic (`Set(allRecipes.map(\.id)).union(swipedRecipeIDs)`) prevents duplicates even if cursors overlap

**Badge Visibility Logic:**
- PopularityBadge: Shows when `popularityScore >= 50` (top-right)
- MatchBadge: Shows when `matchPercentage >= 50` (top-left)
- ForYouBadge: Shows when recipe is personalized (bottom-left)
- All badges can coexist on same card

**FeedRanker Normalization:**
- Old: `velocityScore` (0-1 double)
- New: `popularityScore` (0-100 integer) normalized to 0-1 for scoring
- Discovery ratio remains 40%, formula unchanged

## Success Criteria Met

- [x] All 4 FeedReducer call sites use PopularRecipesQuery (not ViralRecipesQuery)
- [x] FeedReducer state uses endCursor/hasNextPage (not currentPage/hasMorePages)
- [x] loadMoreRecipes uses cursor-based pagination
- [x] RecipeCardView shows PopularityBadge at topTrailing when popularityScore >= 50
- [x] MatchBadge remains at topLeading for ingredient match (unchanged behavior)
- [x] FeedView shows "Popular Recipes" heading below DietaryChipBar
- [x] ViralBadge.swift deleted
- [x] ParallaxHeader uses popularityScore with PopularityBadge
- [x] RecipeDetailModels uses popularityScore (not isViral)
- [x] FeedRanker uses popularityScore (not velocityScore)
- [x] No references to isViral, velocityScore, ViralBadge, or ViralRecipesQuery remain in FeedFeature (except deprecated mapping)
- [x] FeedFeature builds without errors

## Next Steps

Plan 26-03 will:
- Remove deprecated `from(graphQL recipe: ViralRecipesQuery.Data.ViralRecipe)` mapping from FeedModels.swift
- Update any remaining test files to use PopularRecipesQuery mocks
- Verify end-to-end flow with backend integration

## Self-Check: PASSED

**Files verified:**
- [FOUND] /Users/ersinkirteke/Workspaces/Kindred/Kindred/Packages/FeedFeature/Sources/Feed/FeedReducer.swift (modified)
- [FOUND] /Users/ersinkirteke/Workspaces/Kindred/Kindred/Packages/FeedFeature/Sources/Feed/RecipeCardView.swift (modified)
- [FOUND] /Users/ersinkirteke/Workspaces/Kindred/Kindred/Packages/FeedFeature/Sources/Feed/FeedView.swift (modified)
- [FOUND] /Users/ersinkirteke/Workspaces/Kindred/Kindred/Packages/FeedFeature/Sources/RecipeDetail/RecipeDetailModels.swift (modified)
- [FOUND] /Users/ersinkirteke/Workspaces/Kindred/Kindred/Packages/FeedFeature/Sources/RecipeDetail/ParallaxHeader.swift (modified)
- [FOUND] /Users/ersinkirteke/Workspaces/Kindred/Kindred/Packages/FeedFeature/Sources/RecipeDetail/RecipeDetailView.swift (modified)
- [FOUND] /Users/ersinkirteke/Workspaces/Kindred/Kindred/Packages/FeedFeature/Sources/Personalization/FeedRanker.swift (modified)
- [MISSING] /Users/ersinkirteke/Workspaces/Kindred/Kindred/Packages/FeedFeature/Sources/Feed/ViralBadge.swift (deleted as expected)

**Commits verified:**
- [FOUND] 525eec8 (Task 1 commit)
- [FOUND] ecee8d8 (Task 2 commit)
