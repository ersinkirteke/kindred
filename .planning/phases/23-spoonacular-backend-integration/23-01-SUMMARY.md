---
phase: 23-spoonacular-backend-integration
plan: 01
subsystem: backend/spoonacular-integration
tags:
  - api-client
  - data-mapping
  - quota-management
  - circuit-breaker
  - prisma-schema
dependency_graph:
  requires: []
  provides:
    - spoonacular-api-client
    - recipe-mapper
    - quota-tracking
    - search-cache-schema
  affects:
    - recipe-model
    - graphql-schema
tech_stack:
  added:
    - "@nestjs/axios"
    - "axios"
    - "striptags"
  patterns:
    - circuit-breaker
    - rate-limiting
    - incremental-quota-tracking
key_files:
  created:
    - backend/src/spoonacular/spoonacular.service.ts
    - backend/src/spoonacular/spoonacular.module.ts
    - backend/src/spoonacular/dto/spoonacular-recipe.dto.ts
    - backend/src/spoonacular/dto/recipe-mapper.ts
    - backend/test/fixtures/spoonacular-responses.json
    - backend/src/spoonacular/spoonacular.service.spec.ts
    - backend/src/spoonacular/dto/recipe-mapper.spec.ts
  modified:
    - backend/prisma/schema.prisma
    - backend/src/graphql/models/recipe.model.ts
    - backend/src/config/env.validation.ts
    - backend/tsconfig.json
    - backend/package.json
decisions:
  - "Use atomic increment for quota tracking (better for concurrent requests)"
  - "Store Spoonacular CDN images as COMPLETED status (no generation needed)"
  - "Map first cuisine from array to CuisineType enum (Spoonacular returns multiple)"
  - "Set cookTime to null for Spoonacular recipes (only readyInMinutes available)"
  - "Validate recipes before mapping (reject if no instructions or no image)"
  - "Round calories to integer, keep protein/carbs/fat as float"
metrics:
  duration_minutes: 8
  tasks_completed: 2
  tests_added: 42
  test_pass_rate: "100%"
  files_created: 7
  files_modified: 4
  commits: 4
completed_date: "2026-04-04"
---

# Phase 23 Plan 01: Spoonacular Foundation Summary

**One-liner:** Quota-aware Spoonacular API client with circuit breaker, rate limiting, and recipe mapper transforming Spoonacular JSON to Prisma records with HTML stripping and nutrition extraction.

## What Was Built

### Task 1: SpoonacularService with Quota Tracking (TDD)
**Commit:** `0547c8d` (RED), `4f0cb79` (GREEN)

Built a production-ready API client for Spoonacular with:
- **search()**: Calls `/recipes/complexSearch` with query, cuisine, diet, intolerance filters
- **getRecipeInformationBulk()**: Fetches full recipe details with nutrition via `/recipes/informationBulk`
- **Quota tracking**: Incremental points tracking in `ApiQuotaUsage` table, blocks requests when quota exhausted
- **Circuit breaker**: Opens after 5 consecutive failures for 15 minutes, resets on success
- **Rate limiting**: Enforces 1-second delay between consecutive API calls
- **80% threshold warning**: Logs warning when approaching daily quota limit
- **Point cost calculation**: Accurate cost estimation based on Spoonacular pricing (search: 1 + 0.01*n + 0.025*n, bulk: 1 + (n-1)*0.5)

**Tests:** 10/10 passed (search params, filters, quota blocking, circuit breaker, rate limiting)

### Task 2: Recipe Mapper (TDD)
**Commit:** `d87fc35` (RED), `5d9ee14` (GREEN)

Built a comprehensive mapper transforming Spoonacular JSON to Prisma format with:
- **HTML stripping**: Uses `striptags` library to clean summary field
- **plainText generation**: Concatenates ingredients + instructions for Phase 24 AVSpeech narration
- **Difficulty derivation**: `<30min & <8 steps = BEGINNER`, `<60min = INTERMEDIATE`, `>=60min = ADVANCED`
- **Cuisine mapping**: Maps Spoonacular cuisine strings to CuisineType enum (Italian, Mediterranean, etc.) with fallback to OTHER
- **Meal type mapping**: Maps dishTypes to MealType enum (breakfast, lunch, dinner, dessert, etc.) with fallback to DINNER
- **Nutrition extraction**: Extracts calories (rounded), protein, carbs, fat from nutrients array
- **Ingredient mapping**: Maps extendedIngredients to Ingredient format with orderIndex
- **Step mapping**: Maps analyzedInstructions to RecipeStep format with orderIndex
- **Validation**: Rejects recipes without analyzedInstructions or images
- **Image handling**: Sets imageStatus to COMPLETED for Spoonacular CDN images (no generation needed)

**Tests:** 32/32 passed (mapping, HTML stripping, validation, difficulty derivation, enum mappings, nutrition extraction)

### Prisma Schema Evolution
**File:** `backend/prisma/schema.prisma`

**Recipe model changes:**
- Added `spoonacularId Int? @unique` (Spoonacular recipe ID)
- Added `popularityScore Int? @default(0)` (maps to aggregateLikes)
- Added `sourceUrl String?` (original recipe source URL)
- Added `sourceName String?` (source website name)
- Added `plainText String?` (for Phase 24 AVSpeech narration)
- Changed `location String` → `String?` (nullable for Spoonacular recipes without geo data)
- Added indexes on `spoonacularId` and `popularityScore`

**New models:**
```prisma
model SearchCache {
  id            String   @id @default(cuid())
  normalizedKey String   @unique
  recipeIds     String[]
  cachedAt      DateTime @default(now())
  @@index([cachedAt])
}

model ApiQuotaUsage {
  id         String   @id @default(cuid())
  date       String   @unique  // YYYY-MM-DD
  pointsUsed Float    @default(0)
  createdAt  DateTime @default(now())
  updatedAt  DateTime @updatedAt
  @@index([date])
}
```

**Migration status:** ⚠️ Schema updated, migration NOT applied (Docker not running). Migration will be created and applied when database is available. Migration must include:
```sql
-- Clean slate per user decision
DELETE FROM "Bookmark" WHERE "recipeId" IN (SELECT "id" FROM "Recipe");
DELETE FROM "NarrationScript";
DELETE FROM "Ingredient";
DELETE FROM "RecipeStep";
DELETE FROM "Recipe";
```

### GraphQL Schema Updates
**File:** `backend/src/graphql/models/recipe.model.ts`

Added fields:
- `spoonacularId: number | null`
- `popularityScore: number | null`
- `sourceUrl: string | null`
- `sourceName: string | null`
- `plainText: string | null`
- `location: string | null` (changed from required to nullable)

### Environment Configuration
**File:** `backend/src/config/env.validation.ts`

Added:
- `SPOONACULAR_API_KEY?: string` (optional for local dev, validated at service runtime)
- `SPOONACULAR_DAILY_QUOTA?: number` (default 50, configurable)

### Dependencies Installed
- `@nestjs/axios` + `axios` (HTTP client for Spoonacular API)
- `striptags` (HTML stripping for recipe summaries)

## Deviations from Plan

None - plan executed exactly as written. All 8 behaviors for SpoonacularService and all 18 behaviors for recipe mapper implemented and tested.

## Test Coverage

| Component | Tests | Status |
|-----------|-------|--------|
| SpoonacularService | 10 | ✅ All pass |
| Recipe Mapper | 32 | ✅ All pass |
| **Total** | **42** | **100%** |

**Test categories:**
- Search query params (query, cuisine, diet, intolerances, number, offset)
- Bulk recipe fetch (comma-joined IDs, nutrition included)
- Quota tracking (increment, block on exhausted, warn at 80%)
- Circuit breaker (open after 5 failures, reset on success)
- Rate limiting (1-second delay enforcement)
- Recipe mapping (all fields, HTML stripping, plainText generation)
- Difficulty derivation (time + step count logic)
- Enum mappings (cuisine, meal type with fallbacks)
- Nutrition extraction (calories rounded, others as-is)
- Validation (reject recipes without instructions or images)

## Key Decisions

1. **Atomic quota increment**: Used Prisma's `increment` operator instead of read-modify-write to handle concurrent requests safely
2. **First cuisine mapping**: Spoonacular returns multiple cuisines, we map the first one to CuisineType enum
3. **COMPLETED image status**: Spoonacular CDN images are already ready, no generation phase needed
4. **cookTime set to null**: Spoonacular only provides `readyInMinutes`, no separate cook time
5. **Validation before mapping**: Reject recipes without `analyzedInstructions` or `image` to ensure quality
6. **Calories rounding**: Round to integer for consistency with existing Recipe model patterns

## What's Next

**Blocked on:** Database migration (Docker not running)

**Action required:** Start PostgreSQL via `docker-compose up -d postgres`, then run:
```bash
cd backend
npx prisma migrate dev --create-only --name add_spoonacular_support
# Manually add DELETE statements to migration file
npx prisma migrate dev
```

**Enables:**
- Plan 23-02: Search endpoint with cache layer
- Plan 23-03: Recipe sync job
- Plan 23-04: Recommendation engine

## Dependencies Satisfied

**Requires:** None (foundation plan)

**Provides:**
- ✅ `spoonacular-api-client` (SpoonacularService with quota tracking)
- ✅ `recipe-mapper` (mapSpoonacularToRecipe with validation)
- ✅ `quota-tracking` (ApiQuotaUsage model + checkQuota/incrementQuotaUsage)
- ✅ `search-cache-schema` (SearchCache model ready for Plan 23-02)

**Affects:**
- ✅ Recipe model (evolved with Spoonacular fields)
- ✅ GraphQL schema (Recipe type updated)

## Requirements Traceability

| Requirement | Status | Evidence |
|-------------|--------|----------|
| RECIPE-01 | ✅ | SpoonacularService.search() implemented with filters |
| RECIPE-02 | ✅ | Recipe mapper transforms Spoonacular JSON to Prisma format |
| RECIPE-03 | ✅ | validateRecipe() rejects recipes without instructions/images |
| RECIPE-06 | ✅ | plainText field populated for voice narration |
| CACHE-02 | ✅ | ApiQuotaUsage model created, quota tracking implemented |

## Files Changed

**Created (7):**
- `backend/src/spoonacular/spoonacular.service.ts`
- `backend/src/spoonacular/spoonacular.module.ts`
- `backend/src/spoonacular/dto/spoonacular-recipe.dto.ts`
- `backend/src/spoonacular/dto/recipe-mapper.ts`
- `backend/test/fixtures/spoonacular-responses.json`
- `backend/src/spoonacular/spoonacular.service.spec.ts`
- `backend/src/spoonacular/dto/recipe-mapper.spec.ts`

**Modified (4):**
- `backend/prisma/schema.prisma` (Recipe model + SearchCache + ApiQuotaUsage)
- `backend/src/graphql/models/recipe.model.ts` (new fields)
- `backend/src/config/env.validation.ts` (Spoonacular config)
- `backend/tsconfig.json` (resolveJsonModule for test fixtures)

## Self-Check

✅ **Files created:**
```
backend/src/spoonacular/spoonacular.service.ts - FOUND
backend/src/spoonacular/spoonacular.module.ts - FOUND
backend/src/spoonacular/dto/spoonacular-recipe.dto.ts - FOUND
backend/src/spoonacular/dto/recipe-mapper.ts - FOUND
backend/test/fixtures/spoonacular-responses.json - FOUND
backend/src/spoonacular/spoonacular.service.spec.ts - FOUND
backend/src/spoonacular/dto/recipe-mapper.spec.ts - FOUND
```

✅ **Commits verified:**
```
0547c8d - test(23-01): add failing tests for SpoonacularService - FOUND
4f0cb79 - feat(23-01): implement SpoonacularService with quota tracking - FOUND
d87fc35 - test(23-01): add failing tests for recipe mapper - FOUND
5d9ee14 - feat(23-01): implement recipe mapper with HTML stripping - FOUND
```

✅ **Tests verified:**
```
npm test -- --testPathPattern="spoonacular" --no-coverage
✅ 42/42 tests pass
```

## Self-Check: PASSED
