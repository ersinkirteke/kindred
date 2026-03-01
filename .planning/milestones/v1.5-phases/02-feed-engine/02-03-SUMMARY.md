---
phase: 02-feed-engine
plan: 03
subsystem: feed-api
tags: [graphql, postgis, velocity-ranking, cursor-pagination, offline-first]
dependency_graph:
  requires:
    - 02-01-schema-geocoding
    - 02-02-velocity-scoring
  provides:
    - feed-graphql-api
    - spatial-queries
    - cursor-pagination
    - offline-cache-headers
  affects:
    - phase-04-ios-app
    - phase-09-android-app
tech_stack:
  added:
    - graphql-query-complexity
  patterns:
    - PostGIS ST_DWithin for radius queries
    - Relay-style cursor pagination with keyset (velocityScore + id)
    - Multi-category filter combination (AND across, OR within)
    - Expanded radius fallback (city -> country -> global)
    - Progressive filter relaxation for zero-result queries
    - Cache-Control headers for offline-first mobile
key_files:
  created:
    - backend/src/feed/dto/recipe-card.type.ts
    - backend/src/feed/dto/feed-connection.type.ts
    - backend/src/feed/dto/feed-filters.input.ts
    - backend/src/feed/feed.service.ts
    - backend/src/feed/feed.resolver.ts
    - backend/src/feed/feed.module.ts
  modified:
    - backend/src/app.module.ts
    - backend/package.json
decisions:
  - what: RecipeCard contains only card-level fields
    why: Detail fields (dietaryTags, cookTime, difficulty) excluded from feed cards per user decision
    impact: Reduces GraphQL payload size, improves feed performance
  - what: PostGIS ST_DWithin for spatial queries
    why: Enables performant 5-10 mile radius queries with GIST index
    impact: Scales to millions of recipes, falls back to non-spatial if PostGIS unavailable
  - what: Keyset pagination with velocityScore + id cursor
    why: Prevents page drift when feed updates, more efficient than offset pagination
    impact: Stable pagination even as velocityScore changes
  - what: Expanded radius fallback guarantees non-empty feed
    why: User decision - "Feed never returns empty"
    impact: Always returns results (city -> country -> global)
  - what: Progressive filter relaxation
    why: User decision - "When filters produce zero results, return nearest partial matches"
    impact: Improves UX by showing partial matches instead of empty state
  - what: Cache-Control with stale-while-revalidate
    why: Offline-first mobile clients need aggressive caching
    impact: 5 min fresh, 24 hour stale - supports pull-to-refresh UX
metrics:
  duration: 4 minutes
  tasks_completed: 2
  files_created: 6
  files_modified: 2
  commits: 2
  lines_added: ~750
  completed_at: "2026-03-01"
---

# Phase 02 Plan 03: Feed GraphQL API Summary

**One-liner:** PostGIS geo-radius feed with velocity ranking, cursor pagination, multi-category filters, offline cache headers, and graceful empty-state handling.

## What Was Built

Created complete feed GraphQL API that turns Phase 2's infrastructure (PostGIS schema, geocoding, velocity scoring, AI tagging) into a consumer-facing feed for iOS/Android apps.

### Task 1: Feed DTOs and Service with PostGIS Queries

**Created:**
- `RecipeCard` DTO - Summary-level recipe type for feed cards (excludes detail fields like dietaryTags, cookTime, difficulty per user decision)
- `RecipeConnection` - Relay-style cursor connection with edges, pageInfo, totalCount, lastRefreshed, expandedFrom/To, newSinceLastFetch, partialMatch, filtersRelaxed
- `FeedFiltersInput` - Multi-category filter input (cuisineTypes, mealTypes, dietaryTags)
- `FeedService` - Core feed engine with PostGIS spatial queries

**Key Implementation:**
- PostGIS `ST_DWithin` queries for 5-10 mile radius filtering
- 7-day rolling window for fresh content
- Keyset cursor pagination (velocityScore + id) prevents page drift
- Expanded radius fallback: 10mi -> 50mi (city) -> 500mi (country) -> global
- Progressive filter relaxation: drop dietaryTags -> mealTypes -> cuisineTypes
- Graceful fallback to non-spatial Prisma query if PostGIS unavailable
- Humanized engagement counts via VelocityScorer utility

**PostGIS Query Structure:**
```sql
SELECT id, name, "imageUrl", ...,
  ST_Distance(
    ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography,
    ST_SetSRID(ST_MakePoint($userLng, $userLat), 4326)::geography
  ) / 1609.34 as "distanceMiles"
FROM "Recipe"
WHERE ST_DWithin(
  ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography,
  ST_SetSRID(ST_MakePoint($userLng, $userLat), 4326)::geography,
  $radiusMeters
)
AND latitude IS NOT NULL AND longitude IS NOT NULL
AND "scrapedAt" > NOW() - INTERVAL '7 days'
ORDER BY "velocityScore" DESC, id ASC
LIMIT $first + 1
```

**Filter Logic:**
- CuisineTypes: OR within category (`"cuisineType" = ANY(ARRAY[...]::"CuisineType"[])`)
- MealTypes: OR within category (`"mealType" = ANY(ARRAY[...]::"MealType"[])`)
- DietaryTags: AND logic (`"dietaryTags" @> ARRAY[...]::text[]` - must have ALL tags)
- Across categories: AND

**Commit:** `8bd619b` - feat(02-03): create feed DTOs and service with PostGIS queries

### Task 2: Feed Resolver with GraphQL Queries and Cache Headers

**Created:**
- `FeedResolver` - GraphQL resolver with feed, cityName, searchCities queries
- `FeedModule` - NestJS module wiring FeedService, FeedResolver, PrismaModule, GeocodingModule

**GraphQL API:**
1. **`feed` query** - Main feed endpoint (FEED-01, FEED-02, FEED-03, FEED-06, FEED-09)
   - Parameters: latitude, longitude, first (1-50), after (cursor), filters, lastFetchedAt
   - Returns: RecipeConnection with velocity-ranked recipes
   - Validates coordinates: lat ∈ [-90, 90], lng ∈ [-180, 180]
   - Sets Cache-Control: `public, max-age=300, stale-while-revalidate=86400`
   - Generates ETag from edge IDs + velocityScores
   - Query complexity estimation: `first * 10 + 50` (DoS prevention)

2. **`cityName` query** - Reverse geocode for location badge (FEED-07)
   - Parameters: latitude, longitude
   - Returns: City name string (e.g., "Austin")

3. **`searchCities` query** - City autocomplete for manual location change (FEED-08)
   - Parameters: query, limit (default 5)
   - Returns: CitySuggestion[] with name, lat, lng

**Integration:**
- Registered FeedModule in AppModule
- Updated GraphQL context: `({ req, res }) => ({ req, res })` for Cache-Control header support
- Feed queries do NOT require authentication (per AUTH-01: guests can browse feed)

**Commit:** `0c7ed14` - feat(02-03): create feed resolver with GraphQL queries and cache headers

## Deviations from Plan

None - plan executed exactly as written. No auto-fixes, missing functionality, or blocking issues encountered.

## Requirements Fulfilled

| Requirement | Description | How Fulfilled |
|-------------|-------------|---------------|
| FEED-01 | 5-10 mile radius query | PostGIS ST_DWithin with default radiusMiles=10 |
| FEED-02 | Recipe card fields | RecipeCard DTO with imageUrl, name, prepTime, calories, engagementLoves humanized, isViral, cuisineType |
| FEED-03 | Viral badge | isViral field from velocity threshold (VelocityScorer.VIRAL_THRESHOLD = 10) |
| FEED-06 | Multi-category filters | FeedFiltersInput with AND across categories, OR within |
| FEED-07 | City name badge | cityName query via geocoding.reverseGeocode |
| FEED-08 | City search autocomplete | searchCities query via geocoding.searchCities |
| FEED-09 | Offline-first cache headers | Cache-Control with max-age=300, stale-while-revalidate=86400 + ETag |

Additional features delivered:
- Expanded radius fallback (city -> country -> global) guarantees non-empty feed
- Progressive filter relaxation for zero-result queries with partialMatch flag
- newSinceLastFetch count for pull-to-refresh UX
- Cursor-based pagination prevents page drift

## Technical Deep Dive

### PostGIS Spatial Query Performance

**GIST Index (from Plan 02-01):**
```sql
CREATE INDEX idx_recipe_location_gist ON "Recipe"
USING GIST (ST_SetSRID(ST_MakePoint(longitude, latitude), 4326));
```

**Query Optimization:**
- `ST_DWithin` uses geography type for meter-accurate radius queries
- GIST index enables efficient spatial lookups (O(log n) instead of O(n))
- 7-day window reduces search space: `"scrapedAt" > NOW() - INTERVAL '7 days'`
- Keyset pagination avoids offset scan penalty

**Coordinate Validation:**
- Lat: [-90, 90] (poles)
- Lng: [-180, 180] (dateline)
- ST_MakePoint(longitude, latitude) - LONGITUDE FIRST per PostGIS convention

### Cursor Pagination Strategy

**Keyset Approach:**
- Cursor: `{ id: string, velocity: number }` base64-encoded
- Condition: `("velocityScore" < velocity) OR ("velocityScore" = velocity AND id > id)`
- Handles tie-breaking when velocityScore equal
- Prevents page drift when velocityScore updates (unlike offset pagination)

**Fetch N+1 Pattern:**
- Query `LIMIT first + 1`
- If `recipes.length > first`: hasNextPage = true
- Return only first N results

### Cache Strategy for Offline-First Mobile

**Headers:**
```
Cache-Control: public, max-age=300, stale-while-revalidate=86400
ETag: "base64(edge_ids_and_velocities)"
```

**Semantics:**
- `max-age=300`: Fresh for 5 minutes (pull-to-refresh interval)
- `stale-while-revalidate=86400`: Serve stale cache for 24 hours while revalidating in background
- `ETag`: Enables conditional requests (`If-None-Match`) for bandwidth savings

**Mobile Client Flow:**
1. First fetch: Cache response with ETag
2. Pull-to-refresh: Send `If-None-Match: <etag>`
3. If unchanged: 304 Not Modified (no data transfer)
4. If changed: 200 with new data + new ETag

### Filter Relaxation Algorithm

**Progressive Relaxation Order:**
1. Drop dietaryTags (most restrictive - AND logic)
2. Drop mealTypes
3. Drop cuisineTypes

**Example:**
```
Query: cuisineTypes=[ITALIAN], mealTypes=[DINNER], dietaryTags=[gluten-free, vegan]
Zero results → Try without dietaryTags
Still zero → Try without mealTypes
Still zero → Try without cuisineTypes
Return with partialMatch=true, filtersRelaxed=["gluten-free", "vegan", "mealTypes", "cuisineTypes"]
```

### Expanded Radius Fallback

**Tier Strategy:**
1. User radius (default 10 miles): Hyperlocal
2. City-level (50 miles): Nearby recipes
3. Country-level (500 miles): Regional recipes
4. Global (all): Most viral recipes worldwide

**Response Flags:**
- `expandedFrom: 'city'` - Started at city-level
- `expandedTo: 'country'` - Expanded to country-level
- `expandedTo: 'global'` - Expanded to global

**Never Empty Guarantee:**
Global fallback queries all recipes with:
```typescript
orderBy: [{ velocityScore: 'desc' }, { id: 'asc' }]
```
Most viral recipes worldwide - always returns results.

## Self-Check: PASSED

**Files Created:**
```bash
✓ backend/src/feed/dto/recipe-card.type.ts
✓ backend/src/feed/dto/feed-connection.type.ts
✓ backend/src/feed/dto/feed-filters.input.ts
✓ backend/src/feed/feed.service.ts
✓ backend/src/feed/feed.resolver.ts
✓ backend/src/feed/feed.module.ts
```

**Files Modified:**
```bash
✓ backend/src/app.module.ts (FeedModule registered, GraphQL context includes res)
✓ backend/package.json (graphql-query-complexity added)
```

**Commits Exist:**
```bash
✓ 8bd619b: feat(02-03): create feed DTOs and service with PostGIS queries
✓ 0c7ed14: feat(02-03): create feed resolver with GraphQL queries and cache headers
```

**Verification Commands:**
```bash
cd backend
✓ npx tsc --noEmit (zero errors)
✓ npm run build (build succeeded)
```

## What's Next

**Immediate:**
- Phase 2 complete (3/3 plans done)
- Next phase: Phase 3 (Voice Core) or Phase 4 (iOS App)

**Integration Points:**
- iOS app (Phase 4) will call `feed` query from SwiftUI views
- Android app (Phase 9) will call `feed` query from Compose screens
- Both apps will use Cache-Control headers for offline-first UX
- cityName query powers location badge UI
- searchCities query powers location picker autocomplete

**Performance Considerations for Production:**
- Monitor PostGIS query performance as recipe count grows
- Consider Redis caching for hot feed queries (same lat/lng/filters)
- Add DataLoader for N+1 prevention if feed query extended with related data
- Tune `VIRAL_THRESHOLD` based on production engagement metrics

## Completion Summary

**Duration:** 4 minutes
**Tasks:** 2/2 completed
**Commits:** 2
- `8bd619b`: feat(02-03): create feed DTOs and service with PostGIS queries
- `0c7ed14`: feat(02-03): create feed resolver with GraphQL queries and cache headers

**Phase 2 Status:** Complete (3/3 plans)
- Plan 01: PostGIS schema + geocoding ✓
- Plan 02: Velocity scoring + AI tagging ✓
- Plan 03: Feed GraphQL API ✓

**Requirements Delivered:** FEED-01, FEED-02, FEED-03, FEED-06, FEED-07, FEED-08, FEED-09 (all 7 phase requirements)
