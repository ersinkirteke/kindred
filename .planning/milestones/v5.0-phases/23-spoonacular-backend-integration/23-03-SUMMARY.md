---
phase: 23-spoonacular-backend-integration
plan: 03
subsystem: backend/spoonacular-integration
tags:
  - batch-scheduler
  - cron-jobs
  - quota-monitoring
  - health-endpoint
  - cache-prewarming
dependency_graph:
  requires:
    - spoonacular-api-client
    - recipe-mapper
    - search-cache-schema
  provides:
    - batch-prewarm-scheduler
    - quota-health-metrics
  affects:
    - health-graphql-schema
tech_stack:
  added: []
  patterns:
    - cron-scheduling
    - retry-logic
    - stale-while-revalidate
key_files:
  created:
    - backend/src/spoonacular/spoonacular-batch.scheduler.ts
    - backend/src/spoonacular/spoonacular-batch.scheduler.spec.ts
    - backend/src/health/dto/spoonacular-health.dto.ts
  modified:
    - backend/src/spoonacular/spoonacular.module.ts
    - backend/src/health/health.resolver.ts
    - backend/src/health/health.module.ts
    - backend/src/recipes/recipes.service.ts
decisions:
  - "Batch pre-warm runs at 2/3/4 AM UTC to ensure recipes available when quota exhausted"
  - "Pre-warm 100 recipes across 10 diverse cuisines for geographic diversity"
  - "Pre-warm 10 popular search queries (chicken, pasta, vegan, etc.) for common use cases"
  - "Retry logic uses time-based checks (1hr, 2hr) to prevent duplicate executions"
  - "Health endpoint queries Prisma directly (no SpoonacularService dependency for simplicity)"
  - "Calculate quotaResetAt as next midnight UTC (Spoonacular resets daily at 00:00 UTC)"
metrics:
  duration_minutes: 6
  tasks_completed: 2
  tests_added: 10
  test_pass_rate: "100%"
  files_created: 3
  files_modified: 4
  commits: 4
completed_date: "2026-04-04"
---

# Phase 23 Plan 03: Batch Pre-warming Scheduler Summary

**One-liner:** Daily cron job pre-warming 100 recipes across 10 cuisines with retry logic, plus health endpoint exposing quota metrics and cache counts for monitoring.

## What Was Built

### Task 1: Batch Pre-warm Scheduler with Retry Logic (TDD)
**Commits:** `1bb07b6` (RED), `5d8863d` (GREEN)

Built a production-ready batch scheduler that pre-warms the cache daily:

**Core Features:**
- **Daily pre-warm**: Cron at 2 AM UTC fetches 100 recipes across 10 diverse cuisines (Italian, Mexican, Chinese, Indian, Thai, French, Japanese, Mediterranean, American, Korean)
- **Retry logic**: Automatic retries at 3 AM and 4 AM if initial run fails
- **Popular queries**: Pre-warms 10 common search terms (chicken, pasta, vegan, dessert, salad, soup, breakfast, quick dinner, healthy, keto)
- **Validation**: Skips invalid recipes (missing instructions/images) with warning logs
- **Bulk fetching**: Uses search + getRecipeInformationBulk pattern to minimize API calls
- **State tracking**: Tracks lastSuccessfulRun to prevent duplicate retry executions

**Implementation Details:**
1. Searches each cuisine to collect recipe IDs (10 API calls, ~10 points)
2. Fetches full recipe data via getRecipeInformationBulk (1 call, ~50 points for 100 recipes)
3. Validates each recipe, maps to Prisma format, stores via SpoonacularCacheService
4. Pre-warms 10 search queries with full recipe data (10 API calls, ~10 points)
5. Total estimated cost: ~70 points (within 150/day quota with margin for user searches)

**Retry Strategy:**
- `shouldRetry(minHours)`: Returns true if lastSuccessfulRun is null or older than minHours
- Retry 1 (3 AM): Executes if >1 hour since last success
- Retry 2 (4 AM): Executes if >2 hours since last success
- Prevents duplicate work if earlier run succeeded

**Tests:** 10/10 passed
- Fetches recipes from 10 cuisines via search()
- Calls getRecipeInformationBulk with collected IDs
- Validates/maps recipes, skips invalid ones with warnings
- Stores via cacheService.upsertRecipes()
- Pre-warms 10 popular queries via cacheService.cacheSearchResults()
- Retry logic executes based on time since last success
- Logs success/error messages appropriately

### Task 2: Health Endpoint with Quota Metrics
**Commit:** `fa71e5b`

Extended GraphQL health endpoint with Spoonacular monitoring:

**New Query: `spoonacularHealth`**
Returns `SpoonacularHealthStatus` with:
- `quotaUsed: Float` - API points consumed today
- `quotaLimit: Float` - Daily quota limit (default 50, configurable via env)
- `quotaRemaining: Float` - Points remaining for today
- `quotaResetAt: String` - ISO timestamp of next midnight UTC (when quota resets)
- `cachedRecipeCount: Int` - Total recipes cached from Spoonacular
- `cachedSearchCount: Int` - Total cached search results

**Implementation:**
- Queries `ApiQuotaUsage` table for today's usage (YYYY-MM-DD format)
- Calculates quotaRemaining = limit - used
- Computes next midnight UTC: `Date.UTC(year, month, day+1, 0, 0, 0, 0)`
- Counts recipes where `scrapedFrom = 'spoonacular'`
- Counts all rows in `SearchCache` table
- Uses ConfigService for quota limit (defaults to 50)

**Design Decision:**
Kept implementation simple by querying Prisma directly instead of injecting SpoonacularService. The circuit breaker state is in-memory and would add module dependency complexity for limited value in a health check. Future enhancement: expose circuit breaker state via dedicated monitoring endpoint.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed SearchFilters type mismatch in recipes.service.ts**
- **Found during:** Task 2 verification (TypeScript build)
- **Issue:** RecipesService passed comma-joined strings to search() but SearchFilters expects arrays
- **Root cause:** Lines 65-67 used `.join(',')` on cuisines/diets/intolerances arrays
- **Fix:** Removed `.join(',')` and passed arrays directly
- **Files modified:** `backend/src/recipes/recipes.service.ts`
- **Commit:** `577e039`
- **Rationale:** Type error blocked build (Rule 1 - auto-fix bugs that prevent completion)

## Test Coverage

| Component | Tests | Status |
|-----------|-------|--------|
| SpoonacularBatchScheduler | 10 | ✅ All pass |
| **Total** | **10** | **100%** |

**Test categories:**
- Cuisine batch fetching (10 cuisines searched)
- Bulk recipe information fetch (getRecipeInformationBulk called with IDs)
- Recipe validation (skip invalid, log warnings)
- Cache storage (upsertRecipes, cacheSearchResults)
- Popular query pre-warming (10 queries cached)
- Retry logic (time-based execution checks)
- Error handling (logs errors, continues gracefully)

## Key Decisions

1. **Pre-warm at 2 AM UTC**: Off-peak hours to ensure cache is fresh for morning users across all timezones
2. **100 recipes across 10 cuisines**: Balances diversity with quota budget (~70 points/day leaves ~80 for user searches)
3. **Retry at 3 AM and 4 AM**: Provides two recovery opportunities if initial run fails (network, quota spike, etc.)
4. **Time-based retry checks**: Prevents duplicate retries if earlier run succeeded after the retry cron started
5. **10 popular queries**: Covers common search patterns (protein, diet, meal type, speed)
6. **Bulk fetch pattern**: Minimizes API calls (search for IDs, bulk fetch details) vs. individual fetches
7. **Graceful degradation**: Errors in individual cuisines/queries don't fail entire job
8. **Simple health endpoint**: No circuit breaker state exposure (in-memory, would require module coupling)

## What's Next

**Enables:**
- Plan 23-04: Recipe recommendation engine (can rely on pre-warmed cache)
- Phase 26: Admin dashboard (spoonacularHealth query provides monitoring data)

**Operational:**
- Monitor `spoonacularHealth` query daily to track quota usage patterns
- Adjust cuisine list or query list based on user search analytics
- Consider adding manual trigger endpoint for one-time pre-warm after deployments

## Dependencies Satisfied

**Requires:**
- ✅ `spoonacular-api-client` (SpoonacularService from Plan 01)
- ✅ `recipe-mapper` (mapSpoonacularToRecipe, validateRecipe from Plan 01)
- ✅ `search-cache-schema` (SearchCache model from Plan 01, SpoonacularCacheService from Plan 02)

**Provides:**
- ✅ `batch-prewarm-scheduler` (SpoonacularBatchScheduler with cron jobs)
- ✅ `quota-health-metrics` (spoonacularHealth GraphQL query)

**Affects:**
- ✅ Health GraphQL schema (new SpoonacularHealthStatus type)

## Requirements Traceability

| Requirement | Status | Evidence |
|-------------|--------|----------|
| CACHE-04 | ✅ | Batch pre-warm scheduler runs daily at 2/3/4 AM UTC |
| CACHE-02 | ✅ | Health endpoint reports quota metrics from ApiQuotaUsage |
| RECIPE-01 | ✅ | Batch job fetches recipes across diverse cuisines |

## Files Changed

**Created (3):**
- `backend/src/spoonacular/spoonacular-batch.scheduler.ts` (172 lines)
- `backend/src/spoonacular/spoonacular-batch.scheduler.spec.ts` (314 lines)
- `backend/src/health/dto/spoonacular-health.dto.ts` (19 lines)

**Modified (4):**
- `backend/src/spoonacular/spoonacular.module.ts` (+4 lines: added SpoonacularBatchScheduler provider)
- `backend/src/health/health.resolver.ts` (+51 lines: spoonacularHealth query)
- `backend/src/health/health.module.ts` (+2 lines: PrismaModule import)
- `backend/src/recipes/recipes.service.ts` (+3 lines: fixed SearchFilters type usage)

## Self-Check

✅ **Files created:**
```
backend/src/spoonacular/spoonacular-batch.scheduler.ts - FOUND
backend/src/spoonacular/spoonacular-batch.scheduler.spec.ts - FOUND
backend/src/health/dto/spoonacular-health.dto.ts - FOUND
```

✅ **Commits verified:**
```
1bb07b6 - test(23-03): add failing tests for batch pre-warm scheduler - FOUND
5d8863d - feat(23-03): implement batch pre-warm scheduler with retry logic - FOUND
fa71e5b - feat(23-03): extend health endpoint with Spoonacular quota metrics - FOUND
577e039 - fix(23-03): correct SearchFilters type usage in recipes service - FOUND
```

✅ **Tests verified:**
```
npm test -- --testPathPattern="spoonacular-batch" --no-coverage
✅ 10/10 tests pass
```

✅ **Build verified:**
```
npm run build
✅ TypeScript compiles without errors
```

## Self-Check: PASSED
