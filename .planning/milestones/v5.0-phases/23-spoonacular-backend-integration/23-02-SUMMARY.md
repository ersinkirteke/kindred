---
phase: 23-spoonacular-backend-integration
plan: 02
subsystem: backend/search-cache
tags:
  - cache-layer
  - graphql-queries
  - stale-while-revalidate
  - quota-management
  - pagination
dependency_graph:
  requires:
    - spoonacular-api-client
    - recipe-mapper
    - quota-tracking
    - search-cache-schema
  provides:
    - search-recipes-query
    - popular-recipes-query
    - cache-first-pattern
    - cursor-pagination
  affects:
    - feed-module
    - graphql-schema
tech_stack:
  added: []
  patterns:
    - cache-first-retrieval
    - stale-while-revalidate
    - background-refresh
    - cursor-pagination
    - graceful-degradation
key_files:
  created:
    - backend/src/spoonacular/spoonacular-cache.service.ts
    - backend/src/spoonacular/spoonacular-cache.service.spec.ts
    - backend/src/recipes/dto/search-recipes.input.ts
    - backend/src/recipes/recipes.service.spec.ts
  modified:
    - backend/src/spoonacular/spoonacular.module.ts
    - backend/src/recipes/recipes.service.ts
    - backend/src/recipes/recipes.resolver.ts
    - backend/src/recipes/recipes.module.ts
    - backend/src/app.module.ts
decisions:
  - "Cache TTL set to 6 hours (balances quota conservation with freshness)"
  - "Stale cache served immediately with background refresh (non-blocking UX)"
  - "Quota exhaustion falls back to popular pre-warmed recipes (graceful degradation)"
  - "Cleanup threshold 24 hours (prevents unbounded cache growth)"
  - "Cursor pagination uses base64-encoded offsets (Relay-compatible)"
  - "Legacy viralRecipes query marked deprecated (removed in Phase 26)"
metrics:
  duration_minutes: 8
  tasks_completed: 2
  tests_added: 20
  test_pass_rate: "100%"
  files_created: 4
  files_modified: 5
  commits: 4
completed_date: "2026-04-04"
---

# Phase 23 Plan 02: Search Cache & GraphQL Queries Summary

**One-liner:** Cache-first searchRecipes and popularRecipes GraphQL queries with 6-hour TTL, stale-while-revalidate pattern, and graceful quota exhaustion fallback to pre-warmed popular recipes.

## What Was Built

### Task 1: SpoonacularCacheService (TDD)
**Commit:** `5aeb09b` (RED), `c14023f` (GREEN)

Built a production-ready cache layer with:
- **6-hour TTL**: Fresh cache served directly, stale cache triggers background refresh
- **Stale-while-revalidate**: Returns stale data immediately while fetching fresh data asynchronously
- **Normalized cache keys**: Lowercase query + sorted filters (prevents duplicate caching for semantically identical queries)
- **Recipe deduplication**: Upserts by `spoonacularId` (avoids duplicate recipes in database)
- **Transactional updates**: Deletes old ingredients/steps before upserting recipe (prevents orphaned relations)
- **Cleanup threshold**: Removes SearchCache entries older than 24 hours (prevents unbounded growth)

**Cache methods:**
- `getCachedSearch(normalizedKey)`: Returns `{ recipes, isStale }` or `null` on miss
- `cacheSearchResults(normalizedKey, recipes)`: Upserts SearchCache + Recipe records
- `normalizeCacheKey(query, filters)`: Produces consistent keys (`{ q: "chicken", f: { cuisine: "italian", diet: "vegan" } }`)
- `isStale(cachedAt)`: Checks if cache entry exceeds 6-hour TTL
- `cleanExpiredCache()`: Deletes SearchCache entries >24 hours old

**Tests:** 11/11 passed (cache hit/miss, staleness detection, normalization, deduplication, cleanup)

### Task 2: GraphQL Queries with Cache-First Pattern (TDD)
**Commit:** `9ee48ec` (RED), `a62ab62` (GREEN)

Built two new GraphQL queries:

#### searchRecipes(input: SearchRecipesInput): RecipeConnection
Cache-first search with stale-while-revalidate and quota-aware fallback.

**Flow:**
1. Normalize cache key from query + filters
2. Check cache:
   - **Fresh cache** → Return immediately
   - **Stale cache** → Return stale data immediately + trigger background refresh (non-blocking)
   - **Cache miss** → Check quota
3. If quota available: Call Spoonacular API → validate → map → cache → return
4. If quota exhausted: Return popular pre-warmed recipes (graceful degradation)

**Input fields:**
- `query`: Search query for recipe name/ingredients
- `cuisines`: Array of cuisine types (Italian, Mexican, etc.)
- `diets`: Array of diet types (vegetarian, vegan, keto, etc.)
- `intolerances`: Array of intolerances (gluten, dairy, nuts, etc.)
- `first`: Number of results (default 20)
- `after`: Cursor for pagination (base64-encoded offset)

**Output:** `RecipeConnection` with edges, pageInfo, totalCount, lastRefreshed

#### popularRecipes(first: Int, after: String): RecipeConnection
Pre-warmed popular recipes sorted by `popularityScore` DESC.

**Flow:**
1. Query Recipe table directly (no API call)
2. Filter by `spoonacularId IS NOT NULL` AND `popularityScore IS NOT NULL`
3. Order by `popularityScore DESC`
4. Apply cursor pagination

**No Spoonacular API call** — uses pre-warmed cache from batch job (Plan 23-03).

#### Cursor Pagination
Base64-encoded offsets for Relay-style pagination:
- `encodeCursor(offset)`: `Buffer.from(offset.toString()).toString('base64')`
- `decodeCursor(cursor)`: `parseInt(Buffer.from(cursor, 'base64').toString('utf-8'), 10)`
- `PageInfo`: `hasNextPage`, `hasPreviousPage`, `startCursor`, `endCursor`

#### Legacy Queries (Deprecated)
- `viralRecipes(location)`: Marked as deprecated, will be removed in Phase 26
- Kept for backward compatibility during migration

**Tests:** 9/9 passed (cache hit/miss, stale refresh, quota exhaustion, pagination, popularity sorting)

### Module Wiring
**RecipesModule** imports **SpoonacularModule** (provides SpoonacularService + SpoonacularCacheService).
**AppModule** imports **SpoonacularModule** (makes services available globally).

### GraphQL Schema Updates
New queries added to schema:
```graphql
type Query {
  searchRecipes(input: SearchRecipesInput!): RecipeConnection!
  popularRecipes(first: Int = 20, after: String): RecipeConnection!
  viralRecipes(location: String!): [Recipe!]! @deprecated(reason: "Use popularRecipes query instead. Viral detection replaced by popularity scoring in v5.0.")
}

input SearchRecipesInput {
  query: String
  cuisines: [String!]
  diets: [String!]
  intolerances: [String!]
  first: Int = 20
  after: String
}
```

## Deviations from Plan

None - plan executed exactly as written. All 20 tests pass (11 cache + 9 service).

## Test Coverage

| Component | Tests | Status |
|-----------|-------|--------|
| SpoonacularCacheService | 11 | ✅ All pass |
| RecipesService | 9 | ✅ All pass |
| **Total** | **20** | **100%** |

**Test categories:**
- Cache TTL & staleness detection
- Normalized cache keys (case, filter order)
- Recipe deduplication by spoonacularId
- Transactional upserts with cleanup
- Cache hit/miss patterns
- Stale-while-revalidate (background refresh)
- Quota exhaustion graceful degradation
- Cursor pagination (base64 encoding)
- Popularity sorting

## Key Decisions

1. **6-hour TTL**: Balances quota conservation (150 req/day) with freshness. Research shows recipe metadata rarely changes within 6 hours.
2. **Stale-while-revalidate**: Immediate response for stale cache (no user-facing latency) + background refresh ensures eventual consistency.
3. **Quota exhaustion fallback**: Serves popular pre-warmed recipes instead of throwing error (graceful degradation, better UX).
4. **24-hour cleanup threshold**: Prevents unbounded cache growth while allowing reasonable revalidation window.
5. **Cursor pagination**: Base64-encoded offsets (Relay-compatible, future-proof for iOS GraphQL client).
6. **viralRecipes deprecation**: Spoonacular has no geolocation, viral detection replaced by popularity scoring.

## What's Next

**Enables:**
- Plan 23-03: Batch pre-warm job (populate popular recipes for quota-exhausted fallback)
- Plan 23-04: iOS integration (FeedFeature GraphQL migration)

**Migration path:**
- iOS `FeedFeature` currently uses scraping-based feed
- Phase 24: Migrate to `searchRecipes` and `popularRecipes` queries
- Phase 26: Remove deprecated `viralRecipes` query

## Dependencies Satisfied

**Requires (from Plan 23-01):**
- ✅ `spoonacular-api-client` (SpoonacularService)
- ✅ `recipe-mapper` (mapSpoonacularToRecipe)
- ✅ `quota-tracking` (checkQuota/incrementQuotaUsage)
- ✅ `search-cache-schema` (SearchCache Prisma model)

**Provides:**
- ✅ `search-recipes-query` (searchRecipes GraphQL query)
- ✅ `popular-recipes-query` (popularRecipes GraphQL query)
- ✅ `cache-first-pattern` (SpoonacularCacheService)
- ✅ `cursor-pagination` (buildRecipeConnection with base64 cursors)

**Affects:**
- ✅ Feed module (new GraphQL queries available)
- ✅ GraphQL schema (searchRecipes, popularRecipes, SearchRecipesInput types)

## Requirements Traceability

| Requirement | Status | Evidence |
|-------------|--------|----------|
| RECIPE-01 | ✅ | searchRecipes filters by cuisine, diet, intolerances |
| RECIPE-02 | ✅ | Recipe mapper transforms Spoonacular JSON (used in cache) |
| RECIPE-03 | ✅ | validateRecipe ensures quality before caching |
| RECIPE-06 | ✅ | plainText field available for voice narration |
| CACHE-01 | ✅ | 6-hour TTL with stale-while-revalidate pattern |
| CACHE-03 | ✅ | Normalized cache keys prevent duplicate caching |

## Files Changed

**Created (4):**
- `backend/src/spoonacular/spoonacular-cache.service.ts` (256 lines)
- `backend/src/spoonacular/spoonacular-cache.service.spec.ts` (352 lines)
- `backend/src/recipes/dto/search-recipes.input.ts` (21 lines)
- `backend/src/recipes/recipes.service.spec.ts` (352 lines)

**Modified (5):**
- `backend/src/spoonacular/spoonacular.module.ts` (added SpoonacularCacheService)
- `backend/src/recipes/recipes.service.ts` (rewrote with cache-first pattern)
- `backend/src/recipes/recipes.resolver.ts` (added searchRecipes, popularRecipes)
- `backend/src/recipes/recipes.module.ts` (import SpoonacularModule)
- `backend/src/app.module.ts` (import SpoonacularModule)

## Self-Check

✅ **Files created:**
```
backend/src/spoonacular/spoonacular-cache.service.ts - FOUND
backend/src/spoonacular/spoonacular-cache.service.spec.ts - FOUND
backend/src/recipes/dto/search-recipes.input.ts - FOUND
backend/src/recipes/recipes.service.spec.ts - FOUND
```

✅ **Commits verified:**
```
5aeb09b - test(23-02): add failing tests for SpoonacularCacheService - FOUND
c14023f - feat(23-02): implement SpoonacularCacheService with stale-while-revalidate - FOUND
9ee48ec - test(23-02): add failing tests for searchRecipes and popularRecipes - FOUND
a62ab62 - feat(23-02): implement searchRecipes and popularRecipes GraphQL queries - FOUND
```

✅ **Tests verified:**
```
npm test -- --testPathPattern="(spoonacular-cache|recipes.service)" --no-coverage
✅ 20/20 tests pass
```

✅ **Build verified:**
```
npm run build
✅ TypeScript compiles without errors
```

## Self-Check: PASSED
