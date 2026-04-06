---
phase: 26-feed-ui-migration
plan: 03
subsystem: cleanup
tags: [graphql, deprecation, deletion, backend, ios, apollo-codegen]

# Dependency graph
requires:
  - phase: 26-feed-ui-migration
    provides: [popular-recipes-query, popularity-badge-component, feedreducer-cursor-pagination]
provides:
  - clean-codebase-no-viral-references
  - simplified-recipes-resolver-without-deprecated-paths
affects: [phase-27-app-store-compliance, phase-28-final-submission]

# Tech tracking
tech-stack:
  added: []
  patterns: [delete-after-verify-handoff]

key-files:
  created:
    - .planning/phases/26-feed-ui-migration/26-03-SUMMARY.md
  modified:
    - backend/src/recipes/recipes.resolver.ts
    - backend/src/recipes/recipes.service.ts
    - backend/src/recipes/recipes.service.spec.ts
    - Kindred/Packages/NetworkClient/Sources/GraphQL/FeedQueries.graphql
    - Kindred/Packages/FeedFeature/Sources/Models/FeedModels.swift
    - Kindred/Packages/FeedFeature/Sources/Feed/FeedReducer.swift
  deleted:
    - Kindred/Packages/KindredAPI/Sources/Operations/Queries/ViralRecipesQuery.graphql.swift
    - Kindred/Packages/KindredAPI/Sources/Operations/Queries/RecipesQuery.graphql.swift
    - Kindred/Packages/NetworkClient/Sources/Schema/Sources/Operations/Queries/ViralRecipesQuery.graphql.swift
    - Kindred/Packages/NetworkClient/Sources/Schema/Sources/Operations/Queries/RecipesQuery.graphql.swift

key-decisions:
  - "Also remove deprecated `Recipes` (offset-based) query — superseded by cursor-based PopularRecipes and confirmed dead via grep"
  - "Delete duplicate generated files in NetworkClient/Sources/Schema/Sources/Operations/Queries/ in addition to canonical KindredAPI location, since both compile into separate modules and were both stale"
  - "Skip `apollo-ios-cli generate` regen — binary not on PATH and no schema changes (deletions only); manual file removal is equivalent and matches actual state"
  - "Delete dead `from(graphQL: ViralRecipesQuery)` and `from(recipesQuery:)` extension methods rather than leave dangling references"

patterns-established:
  - "Verify-then-cleanup checkpoint pattern: human-verify gate before destructive deprecation removals (Phase 26 used this for the viralRecipes → popularRecipes migration)"

requirements-completed: [RECIPE-04, RECIPE-05, RECIPE-07]

# Metrics
duration: 4min
completed: 2026-04-06
---

# Phase 26 Plan 03: Deprecated Viral/Recipes Query Removal Summary

**Removed all deprecated viralRecipes and Recipes (offset-based) query paths from backend resolver, service, tests, GraphQL schema definitions, generated Apollo iOS files, and dead Swift extension mappings — feed migration to popularRecipes/cursor pagination is now the only path.**

## Performance

- **Duration:** ~4 min (Task 2 only — Task 1 was a verification-only checkpoint completed by prior agent)
- **Started:** 2026-04-06T12:50:55Z
- **Completed:** 2026-04-06T12:54:36Z
- **Tasks:** 2 (Task 1: human-verify checkpoint, Task 2: deletion sweep)
- **Files modified:** 6
- **Files deleted:** 4

## Accomplishments

- Backend `viralRecipes` GraphQL resolver and `findViral` service method fully removed; resolver now exposes only `searchRecipes`, `popularRecipes`, `recipes`, and `recipe` queries
- iOS GraphQL operation definitions for `query ViralRecipes` and `query Recipes` removed from `FeedQueries.graphql`; generated Apollo Swift files deleted in both canonical (`KindredAPI`) and stale duplicate (`NetworkClient/Sources/Schema/Sources/Operations/Queries`) locations
- Dead Swift extension methods `RecipeCard.from(graphQL: ViralRecipesQuery.Data.ViralRecipe)` and `RecipeCard.from(recipesQuery: RecipesQuery.Data.Recipe)` deleted (zero callers)
- Backend builds clean, all 85 tests pass
- iOS FeedFeature scheme builds clean (zero errors)
- Phase 26 milestone (Feed UI Migration) complete: 3/3 plans done

## Task Commits

Each task was committed atomically:

1. **Task 1: Verify feed works on device after Plans 26-01 and 26-02** - no commit (verification-only checkpoint, human approved)
2. **Task 2: Remove deprecated viralRecipes resolver, findViral service method, and ViralRecipesQuery files** - `4ca5302` (refactor)

## Files Created/Modified

### Backend (3 modified)

- `backend/src/recipes/recipes.resolver.ts` — Removed `@Query` `viralRecipes` resolver method and its `deprecationReason` annotation
- `backend/src/recipes/recipes.service.ts` — Removed `findViral(location)` method that filtered by `isViral: true`
- `backend/src/recipes/recipes.service.spec.ts` — Removed the single `findViral` test case (`it('should mark deprecated viralRecipes query as returning empty array', ...)`)

### iOS (3 modified, 4 deleted)

- `Kindred/Packages/NetworkClient/Sources/GraphQL/FeedQueries.graphql` — Deleted `query ViralRecipes` and `query Recipes` operation definitions; kept `query PopularRecipes` and `query FeedFiltered`
- `Kindred/Packages/FeedFeature/Sources/Models/FeedModels.swift` — Removed deprecated `from(graphQL recipe: KindredAPI.ViralRecipesQuery.Data.ViralRecipe)` static factory method
- `Kindred/Packages/FeedFeature/Sources/Feed/FeedReducer.swift` — Removed dead `from(recipesQuery: KindredAPI.RecipesQuery.Data.Recipe)` extension method; updated `// MARK:` comment from "Recipes Query" to "Feed Query"
- `Kindred/Packages/KindredAPI/Sources/Operations/Queries/ViralRecipesQuery.graphql.swift` — DELETED (canonical Apollo-generated file)
- `Kindred/Packages/KindredAPI/Sources/Operations/Queries/RecipesQuery.graphql.swift` — DELETED (canonical Apollo-generated file)
- `Kindred/Packages/NetworkClient/Sources/Schema/Sources/Operations/Queries/ViralRecipesQuery.graphql.swift` — DELETED (stale duplicate from older codegen run)
- `Kindred/Packages/NetworkClient/Sources/Schema/Sources/Operations/Queries/RecipesQuery.graphql.swift` — DELETED (stale duplicate from older codegen run)

## Decisions Made

1. **Deleted the `Recipes` (offset-based) query alongside `ViralRecipes`** — The plan listed `RecipesQuery.graphql.swift` as conditional ("only if no other code imports it"). Grep confirmed only the dead `from(recipesQuery:)` extension referenced it, so both query and extension were removed for full cleanup. The backend `recipes` resolver itself was kept (per plan: "the recipes resolver may be used by other features").
2. **Deleted duplicate generated files in `NetworkClient/Sources/Schema/Sources/Operations/Queries/`** — These are stale artifacts from a previous codegen run (separate from the canonical `KindredAPI` package output configured in `apollo-codegen-config.json`). Both copies compile into different module namespaces (`KindredAPI.RecipesQuery` vs `NetworkClient.RecipesQuery`), and only the `KindredAPI` symbol was actually referenced. Both deletions were necessary for true cleanup.
3. **Did not run `apollo-ios-cli generate`** — `apollo-ios-cli` is not installed on PATH and the only available binary is the `.tar.gz` inside `.build/checkouts/`. Since the schema changes are deletions (not field additions), regenerating from `backend/schema.gql` would only re-delete the same files. Manual deletion is equivalent and verified by a successful build.
4. **Used `iPhone 17 Pro` simulator instead of `iPhone 16 Pro`** — Plan specifies iPhone 16 Pro but it's not installed on this Mac (same situation as the prior agent for Task 1). iPhone 17 Pro on iOS Simulator 26.4 SDK is the closest substitute and matches the precedent set by Task 1's automated check.

## Deviations from Plan

None substantive. The plan listed `RecipesQuery.graphql.swift` deletion as conditional ("only if unused"); confirmed unused via grep and deleted. The duplicate Swift files in `NetworkClient/Sources/Schema/Sources/Operations/Queries/` were not explicitly listed in the plan but were obviously stale (not produced by the active `apollo-codegen-config.json`) and were removed for full cleanup. No auto-fixes triggered (Rules 1-4 did not apply).

## Issues Encountered

None. All deletions were straightforward, builds passed on first attempt.

## Verification Results

**Backend (`cd backend && npm run build && npm test`):**
- `npm run build` — Clean (no errors, no warnings)
- `npm test` — All 85 tests across 7 suites passed in 38.2s
- Pre-existing notice: A worker process did not exit gracefully ("force exited") — pre-existing tech debt unrelated to this plan

**iOS (`xcodebuild build -scheme FeedFeature -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`):**
- `** BUILD SUCCEEDED **`
- Zero `error:` lines in build log
- All compilation steps for `FeedReducer.swift`, `FeedView.swift`, `RecipeCardView.swift`, `LocationPickerView.swift`, etc. completed normally

**Reference cleanup (grep):**
```
backend/src    — viralRecipes|findViral         → 0 files
Kindred/Packages — ViralRecipesQuery|ViralBadge → 0 swift files
Kindred/Packages — \bRecipesQuery\b             → 0 swift files
```

**File deletion (ls):**
- `Kindred/Packages/KindredAPI/Sources/Operations/Queries/ViralRecipesQuery.graphql.swift` → No such file
- `Kindred/Packages/KindredAPI/Sources/Operations/Queries/RecipesQuery.graphql.swift` → No such file
- `Kindred/Packages/NetworkClient/Sources/Schema/Sources/Operations/Queries/ViralRecipesQuery.graphql.swift` → No such file
- `Kindred/Packages/NetworkClient/Sources/Schema/Sources/Operations/Queries/RecipesQuery.graphql.swift` → No such file

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- **Phase 26 milestone (Feed UI Migration) is complete.** All 3 plans done (26-01 data layer, 26-02 UI migration, 26-03 deprecation cleanup).
- The iOS feed now has a single canonical query path: `PopularRecipesQuery` with cursor pagination, `PopularityBadge` UI, and "Popular Recipes" heading. Zero references to legacy `viralRecipes`, `findViral`, `isViral`, `velocityScore`, `ViralBadge`, or the old offset-based `Recipes` query remain in active code.
- **Ready for Phase 27** (App Store Compliance) — no carry-over blockers from Phase 26.
- One pre-existing tech debt item to track (unrelated to this plan): backend Jest "worker process did not exit gracefully" warning. Recommend revisiting in a dedicated test infrastructure phase.

## Self-Check

**Created files exist:**
```bash
[ -f .planning/phases/26-feed-ui-migration/26-03-SUMMARY.md ] && echo "FOUND" || echo "MISSING"
```
FOUND

**Commits exist:**
```bash
git log --oneline --all | grep 4ca5302
```
FOUND: `4ca5302 refactor(26-03): remove deprecated viralRecipes and Recipes query paths`

**Deleted files confirmed gone (4):**
- ViralRecipesQuery.graphql.swift (KindredAPI) — gone
- RecipesQuery.graphql.swift (KindredAPI) — gone
- ViralRecipesQuery.graphql.swift (NetworkClient/Schema) — gone
- RecipesQuery.graphql.swift (NetworkClient/Schema) — gone

## Self-Check: PASSED

All success criteria met. Backend and iOS both build clean, all tests pass, zero references to deprecated symbols remain, all 4 generated query files deleted in both canonical and duplicate locations.

---
*Phase: 26-feed-ui-migration*
*Completed: 2026-04-06*
