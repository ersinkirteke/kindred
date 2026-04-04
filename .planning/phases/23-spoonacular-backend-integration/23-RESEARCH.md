# Phase 23: Spoonacular Backend Integration - Research

**Researched:** 2026-04-04
**Domain:** Recipe API integration, backend caching, quota management, batch job scheduling
**Confidence:** HIGH

## Summary

Phase 23 replaces the X/Instagram scraping pipeline with Spoonacular REST API as the recipe data source. The free tier provides **50 points/day** (rate limited to 1 req/s, 2 concurrent), requiring aggressive PostgreSQL caching and strategic use of bulk endpoints to stay within quota. The backend will proxy all Spoonacular responses, cache full recipe details with 6-hour TTL, and pre-warm 100 popular recipes via daily batch job at 2 AM UTC. New GraphQL queries (`searchRecipes`, `popularRecipes`) will be added alongside deprecated old queries, with iOS changes deferred to Phase 26.

**Key quota insight:** The **official Spoonacular free tier is 50 points/day**, not 150. The CONTEXT.md mentions "150 req/day" but the official pricing page (verified 2026-04-04) shows 50 points/day. This constraint makes the bulk endpoint (`getRecipeInformationBulk`: 1 point + 0.5 per additional recipe) and aggressive caching absolutely critical, not optional.

**Primary recommendation:** Implement PostgreSQL caching as table stakes (not optimization), use `getRecipeInformationBulk` for all multi-recipe fetches, implement circuit breaker after 5 consecutive failures, and track quota points (not just HTTP calls) to avoid 402 errors.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Recipe Data Mapping:**
- Evolve existing Recipe table (add Spoonacular fields, null out scraping-only fields)
- Add fields: `spoonacularId` (Int, unique), `popularityScore`, `sourceUrl`, `sourceName`, `plainText` (for Phase 24 voice narration)
- Remove geo fields: `latitude`, `longitude`, `location`, `distanceMiles`
- Delete all old scraped recipe data (clean slate migration)
- Keep nutrition to current 4 fields: calories, protein, carbs, fat
- Images: store Spoonacular CDN URL directly in `imageUrl`, set `imageStatus` to READY (no R2 upload)
- Map `readyInMinutes` to `prepTime`, set `cookTime` null
- Map Spoonacular `cuisines[0]` to `CuisineType` enum (first cuisine, default OTHER)
- Map `dishTypes` to `MealType` enum (best-effort, default DINNER)
- Map `diets` array to `dietaryTags` string array
- Map `aggregateLikes` to `popularityScore` field (replaces `engagementLoves`/`velocityScore`)
- Map `analyzedInstructions` steps to existing `RecipeStep` model (orderIndex, text). Drop duration/techniqueTag for Spoonacular recipes
- Use parsed ingredient fields (name, amount, unit) not `originalString`
- Store Spoonacular `summary` as plain text (strip HTML) in `description`
- Derive `difficulty` from readyInMinutes + step count heuristic (<30 min & <8 steps = BEGINNER, <60 min = INTERMEDIATE, else ADVANCED)
- Store `servings` from Spoonacular
- Skip recipes without analyzedInstructions (voice narration needs steps)
- Skip recipes without images (feed needs visuals)
- Validate each recipe before caching; skip malformed ones with warning log
- Take first cuisine from multi-cuisine array

**Quota Strategy:**
- Split: ~50 quota points for batch pre-warm / ~100 for user-initiated requests
- Use bulk endpoints (getRecipeInformationBulk: 1 point for up to 100 recipes) to maximize value
- Track actual Spoonacular quota points, not just HTTP call count
- PostgreSQL `api_quota_usage` table: date + point count, increment on each API call
- Check quota BEFORE making API call; if at limit, serve from cache immediately
- Cache hits are free (only live API calls decrement quota)
- At 80% threshold (120 points): log warning only, no throttling
- When quota exhausted: serve stale cache seamlessly. Banner only if cache empty AND quota exhausted (unlikely with pre-warming)
- Transparent caching: users never know about the quota. No "limit reached" messaging unless absolutely necessary
- Worst case (quota exhausted + empty cache for search): show "No recipes found for this search. Try browsing our popular recipes below!" with pre-warmed popular recipes as fallback
- 1-second delay between consecutive Spoonacular API calls (free tier rate limit)
- Health endpoint extended with: quota_remaining, quota_reset_at, cache_hit_rate

**Cache & Pre-warm Behavior:**
- 2 AM UTC batch job: full replace (delete all cached recipes, fetch fresh 100)
- Diverse popular mix: top recipes across ~10 cuisine categories by popularity
- Also pre-warm 10-15 popular search queries ('chicken', 'pasta', 'vegan', 'dessert', etc.)
- 6-hour TTL for both recipes and search query cache
- Stale-while-revalidate: serve stale cache immediately, refresh in background if TTL expired AND quota available
- Normalized cache keys: lowercase, trim whitespace, sort filter params alphabetically
- Separate `search_cache` table: maps (normalized_query -> recipe_ids[], cached_at, ttl)
- Recipes in Recipe table (one row per recipe, deduplicated by spoonacularId)
- If 2 AM batch fails: retry at 3 AM and 4 AM. After that, log critical error and serve yesterday's cache
- Simple circuit breaker: after 5 consecutive failures, stop calling Spoonacular for 15 minutes, serve cache only

**Search & Filter:**
- Search bar + filter chips: text keyword search + cuisine, diet, intolerances chips
- Auto-apply user's dietary preferences from onboarding as default filters (toggleable)
- Explicit submit (not debounced): user taps Search/Enter. Preserves quota
- Intolerances combined with dietary filters in same section (no separate UI)
- Default sort: popularity (aggregateLikes descending)
- Popularity only sort (no sort picker)
- 20 results per page, cursor-based pagination (matches existing RecipeConnection pattern)
- Guest accessible: no auth required for search or browse

**GraphQL API:**
- Add new queries: `searchRecipes`, `popularRecipes` alongside deprecated old ones
- Keep `viralRecipes` and location-based `feed` queries as @deprecated until Phase 26
- Recipe detail via existing `recipe(id:)` query using internal cuid ID
- Cache full recipe details during search (use getRecipeInformationBulk, 1 API point for up to 100 recipes)
- Flat fields for attribution: `sourceName` String?, `sourceUrl` String?
- Attribution: "Recipe from [sourceName] - Powered by Spoonacular" on detail view only (not cards)

**Error Handling & Resilience:**
- Spoonacular API down: serve stale cache, log error. User never notices
- 5-second timeout per API call
- Circuit breaker: 5 consecutive failures -> 15 min cooldown, cache-only
- All Spoonacular errors handled server-side; no Spoonacular-specific errors leak to iOS
- Log Spoonacular response times for performance monitoring
- Standard NestJS Logger: INFO for batch runs, WARN for quota/skipped recipes, ERROR for API failures
- Mock tests only (no real API calls in CI)

**Old Service Cleanup:**
- Delete: ScrapingService, XApiService, InstagramService, RecipeParserService, ScrapingScheduler
- Delete: ImageGenerationProcessor, image queue/BullMQ setup
- Delete: all tests for deleted services
- Remove: X_API_KEY, INSTAGRAM_* env vars from ConfigModule validation
- Remove: unused npm dependencies (X API SDK, Instagram scraper, AI image generation)
- Keep: GeocodingService (used by FeedResolver), VelocityScorer (used by FeedService until Phase 26)
- Keep: R2 storage service (used for voice uploads/narration)
- Keep: PostGIS extension in PostgreSQL

**Migration Strategy:**
- Single Prisma migration: add new fields, drop geo/scraping fields, delete all existing Recipe rows
- No feature flag: new queries are additive, old queries stay deprecated
- Trigger pre-warm immediately after deploy (one-time script/endpoint)
- SPOONACULAR_API_KEY in ConfigModule with Joi validation (user provides key)
- Backend only: no iOS changes in this phase (iOS schema update in Phase 26)
- Keep PostGIS extension installed
- Rollback plan: git revert + prisma migrate (accept empty feed if needed, old pipeline was being shut down)

### Claude's Discretion

- Exact Prisma schema field types and defaults
- SpoonacularService internal architecture (single service vs split)
- Cache cleanup/eviction strategy details
- Batch job implementation details (Cron decorator config)
- HTTP client choice for Spoonacular calls (axios, fetch, etc.)
- Search cache table exact schema
- Test fixture data structure

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| RECIPE-01 | User can search recipes by keyword via Spoonacular API | Spoonacular `complexSearch` endpoint supports `query` parameter for text search, costs 1 point + 0.01 per result. Returns recipe IDs that can be bulk-fetched with `getRecipeInformationBulk`. |
| RECIPE-02 | User can filter recipes by cuisine, diet type, and intolerances | `complexSearch` supports `cuisine`, `diet`, `intolerances` parameters. All three can be combined. Backend validates filters against Spoonacular's supported values. |
| RECIPE-03 | Recipe cards display images from Spoonacular CDN | Spoonacular returns `image` field with CDN URLs (636x393 size). Store directly in Recipe.imageUrl, set imageStatus=READY. No R2 upload needed. |
| RECIPE-06 | Recipe detail shows Spoonacular source attribution with link | Recipe response includes `sourceUrl` and `sourceName` fields. Store in Recipe table, display "Recipe from {sourceName} - Powered by Spoonacular" with clickable link. |
| CACHE-01 | Backend caches Spoonacular responses in PostgreSQL with 6-hour TTL | PostgreSQL cache table with `cached_at` timestamp + TTL check. Separate `search_cache` table maps queries to recipe IDs. Recipe table stores full details (deduplicated by spoonacularId). |
| CACHE-02 | Backend tracks daily Spoonacular API quota usage (150 req/day) | `api_quota_usage` table tracks daily points consumed. Check quota BEFORE API call. Quota resets daily at UTC midnight. **Note:** Official free tier is 50 points/day, not 150. |
| CACHE-03 | App shows graceful "daily limit reached" state when quota exhausted | When quota exhausted, serve stale cache. Only show banner if cache is ALSO empty (unlikely with pre-warming). Fallback: "Try browsing our popular recipes" with pre-warmed cache. |
| CACHE-04 | Backend pre-warms 100 popular recipes via scheduled batch job | NestJS `@Cron('0 2 * * *')` decorator at 2 AM UTC. Use `getRecipeInformationBulk` (1 point for 100 recipes). Diverse mix across 10 cuisines. Retry at 3 AM and 4 AM if fails. |

</phase_requirements>

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| @nestjs/axios | ^3.0.3 | HTTP client | Official NestJS wrapper for Axios, provides retry/timeout configuration via HttpModule |
| @nestjs/schedule | ^4.0.2 | Cron job scheduling | Official NestJS task scheduling, already used in project (pantry schedulers), supports `@Cron()` decorators |
| Prisma | ^7.4.2 | Database ORM | Already used throughout project, supports PostgreSQL with PostGIS extension |
| striptags | ^3.2.0 | HTML tag removal | Lightweight, fast, zero-config. Strips HTML from Spoonacular `summary` field to plain text |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| nestjs-axios-retry | ^1.0.0 | Enhanced Axios retry | If more sophisticated retry logic needed beyond basic HttpModule config (exponential backoff, per-status-code retry) |
| opossum | ^8.1.4 | Circuit breaker | If implementing circuit breaker pattern (5 consecutive failures → 15 min cooldown). Mature Node.js circuit breaker library |
| @nestjs/throttler | ^6.2.1 | Rate limiting | Already configured in project (100/min, expensive 10/min). Extend for Spoonacular 1 req/s limit |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| striptags | sanitize-html | sanitize-html allows selective tag preservation (keep `<b>`, `<a>` etc.), but Spoonacular summaries need full stripping for voice narration. striptags is simpler and faster. |
| @nestjs/axios | native fetch | fetch is built-in Node 18+, but @nestjs/axios provides NestJS DI integration, retry config, and timeout handling out of the box. |
| PostgreSQL cache | Redis | Redis has native TTL expiration, but adds infrastructure complexity. PostgreSQL already used, supports UNLOGGED tables for cache performance, and simplifies deployment. |
| @Cron decorator | BullMQ queue | BullMQ provides job queues with retry/persistence, but @nestjs/schedule is simpler for single daily job. BullMQ overhead not needed for batch pre-warm. |

**Installation:**
```bash
npm install @nestjs/axios @nestjs/schedule striptags
npm install --save-dev @types/striptags
```

## Architecture Patterns

### Recommended Project Structure

```
src/
├── spoonacular/
│   ├── spoonacular.module.ts          # Module with HttpModule config, cron job
│   ├── spoonacular.service.ts          # API client (search, bulk fetch, quota tracking)
│   ├── spoonacular-cache.service.ts    # Cache layer (check cache, store results)
│   ├── spoonacular-batch.scheduler.ts  # Daily 2 AM pre-warm job
│   ├── dto/
│   │   ├── spoonacular-recipe.dto.ts   # API response types
│   │   ├── search-filters.input.ts     # GraphQL input for filters
│   │   └── recipe-mapper.ts            # Spoonacular → Prisma Recipe mapping
│   └── spoonacular.spec.ts             # Mock tests (no real API calls)
├── recipes/
│   ├── recipes.resolver.ts             # Add searchRecipes, popularRecipes queries
│   ├── recipes.service.ts              # Orchestrate cache + Spoonacular calls
│   └── ...
└── config/
    └── env.validation.ts               # Add SPOONACULAR_API_KEY validation
```

### Pattern 1: Cache-First Retrieval with Stale-While-Revalidate

**What:** Check cache first, serve immediately if found (even if stale). If stale AND quota available, refresh in background.

**When to use:** All Spoonacular API calls (search, bulk fetch). Keeps responses fast, minimizes quota consumption.

**Example:**
```typescript
// Source: Research synthesis from NestJS caching patterns + Spoonacular quota constraints

async searchRecipes(query: string, filters: SearchFilters): Promise<Recipe[]> {
  // 1. Normalize cache key (lowercase, sorted filters)
  const cacheKey = this.normalizeCacheKey(query, filters);

  // 2. Check cache first
  const cached = await this.getCachedSearch(cacheKey);
  if (cached) {
    // 3. Serve immediately (stale-while-revalidate)
    const age = Date.now() - cached.cachedAt.getTime();
    const isStale = age > 6 * 60 * 60 * 1000; // 6 hours

    if (isStale && await this.hasQuotaRemaining()) {
      // Refresh in background
      this.refreshSearchInBackground(query, filters, cacheKey).catch(err =>
        this.logger.warn(`Background refresh failed: ${err.message}`)
      );
    }

    return cached.recipes;
  }

  // 4. Cache miss: check quota before API call
  if (!await this.hasQuotaRemaining()) {
    throw new Error('Daily quota exhausted, no cached results available');
  }

  // 5. Fetch from Spoonacular, cache results
  const results = await this.spoonacularService.search(query, filters);
  await this.cacheSearch(cacheKey, results);

  return results;
}
```

### Pattern 2: Quota-Aware API Client with Circuit Breaker

**What:** Track quota points before each call, implement circuit breaker after consecutive failures, respect rate limits.

**When to use:** Wrapping all Spoonacular API calls. Prevents quota exhaustion and cascading failures.

**Example:**
```typescript
// Source: NestJS circuit breaker pattern + Spoonacular quota tracking

@Injectable()
export class SpoonacularService {
  private consecutiveFailures = 0;
  private circuitOpenUntil: Date | null = null;
  private lastRequestTime = 0;

  constructor(
    private httpService: HttpService,
    private prisma: PrismaService,
    private logger: Logger,
  ) {}

  async getRecipeInformationBulk(ids: number[]): Promise<SpoonacularRecipe[]> {
    // 1. Circuit breaker check
    if (this.circuitOpenUntil && Date.now() < this.circuitOpenUntil.getTime()) {
      throw new Error('Circuit breaker open, serving cache only');
    }

    // 2. Quota check (before API call)
    const pointCost = 1 + (ids.length - 1) * 0.5; // Bulk endpoint cost
    const hasQuota = await this.checkQuota(pointCost);
    if (!hasQuota) {
      throw new Error('Daily quota exhausted');
    }

    // 3. Rate limit: 1 req/s
    const now = Date.now();
    const timeSinceLastRequest = now - this.lastRequestTime;
    if (timeSinceLastRequest < 1000) {
      await new Promise(resolve => setTimeout(resolve, 1000 - timeSinceLastRequest));
    }
    this.lastRequestTime = Date.now();

    try {
      // 4. Make API call
      const response = await this.httpService.get(
        `/recipes/informationBulk?ids=${ids.join(',')}`,
        { timeout: 5000 }
      ).toPromise();

      // 5. Success: reset circuit breaker, track quota usage
      this.consecutiveFailures = 0;
      await this.incrementQuotaUsage(pointCost);

      return response.data;
    } catch (error) {
      // 6. Failure: increment circuit breaker
      this.consecutiveFailures++;
      if (this.consecutiveFailures >= 5) {
        this.circuitOpenUntil = new Date(Date.now() + 15 * 60 * 1000); // 15 min
        this.logger.error('Circuit breaker OPEN: 5 consecutive failures');
      }
      throw error;
    }
  }

  private async checkQuota(pointCost: number): Promise<boolean> {
    const today = new Date().toISOString().split('T')[0];
    const usage = await this.prisma.apiQuotaUsage.findUnique({
      where: { date: today },
    });

    const used = usage?.pointsUsed || 0;
    const remaining = 50 - used; // Free tier: 50 points/day

    if (remaining < pointCost) {
      this.logger.warn(`Quota exhausted: ${used}/50 points used today`);
      return false;
    }

    if (used >= 40) {
      this.logger.warn(`Quota at 80%: ${used}/50 points used today`);
    }

    return true;
  }

  private async incrementQuotaUsage(points: number): Promise<void> {
    const today = new Date().toISOString().split('T')[0];
    await this.prisma.apiQuotaUsage.upsert({
      where: { date: today },
      create: { date: today, pointsUsed: points },
      update: { pointsUsed: { increment: points } },
    });
  }
}
```

### Pattern 3: Batch Pre-Warming with Retry Logic

**What:** Daily cron job fetches 100 popular recipes at 2 AM UTC, retries at 3 AM and 4 AM if fails.

**When to use:** Pre-warming cache to ensure users always have fresh content even when quota exhausted.

**Example:**
```typescript
// Source: NestJS @Cron decorator pattern + retry logic

@Injectable()
export class SpoonacularBatchScheduler {
  private readonly logger = new Logger(SpoonacularBatchScheduler.name);

  constructor(
    private readonly spoonacularService: SpoonacularService,
    private readonly prisma: PrismaService,
  ) {}

  @Cron('0 2 * * *', { name: 'prewarm-recipes', timeZone: 'UTC' })
  async prewarmRecipes() {
    await this.executePrewarm('2:00 AM UTC');
  }

  @Cron('0 3 * * *', { name: 'prewarm-retry-1', timeZone: 'UTC' })
  async retryPrewarm1() {
    const lastRun = await this.getLastSuccessfulRun();
    const hoursSinceSuccess = (Date.now() - lastRun.getTime()) / (1000 * 60 * 60);

    if (hoursSinceSuccess > 1) {
      this.logger.warn('2 AM job failed, retrying at 3 AM');
      await this.executePrewarm('3:00 AM UTC (retry 1)');
    }
  }

  @Cron('0 4 * * *', { name: 'prewarm-retry-2', timeZone: 'UTC' })
  async retryPrewarm2() {
    const lastRun = await this.getLastSuccessfulRun();
    const hoursSinceSuccess = (Date.now() - lastRun.getTime()) / (1000 * 60 * 60);

    if (hoursSinceSuccess > 2) {
      this.logger.error('2 AM and 3 AM jobs failed, final retry at 4 AM');
      await this.executePrewarm('4:00 AM UTC (retry 2)');
    }
  }

  private async executePrewarm(jobName: string): Promise<void> {
    this.logger.log(`Starting recipe pre-warm job: ${jobName}`);

    try {
      // 1. Fetch popular recipes across 10 cuisines (10 each)
      const cuisines = ['italian', 'mexican', 'chinese', 'indian', 'thai',
                        'french', 'japanese', 'mediterranean', 'american', 'korean'];

      const recipeIds: number[] = [];
      for (const cuisine of cuisines) {
        const results = await this.spoonacularService.search('', {
          cuisine,
          number: 10,
          sort: 'popularity'
        });
        recipeIds.push(...results.map(r => r.id));
      }

      // 2. Bulk fetch full details (1 point for 100 recipes)
      const recipes = await this.spoonacularService.getRecipeInformationBulk(recipeIds);

      // 3. Delete old cached recipes, insert fresh ones
      await this.prisma.$transaction([
        this.prisma.recipe.deleteMany({ where: { scrapedFrom: 'spoonacular' } }),
        this.prisma.recipe.createMany({ data: recipes.map(this.mapToPrisma) }),
      ]);

      // 4. Also pre-warm popular search queries
      const popularQueries = ['chicken', 'pasta', 'vegan', 'dessert', 'salad',
                              'soup', 'breakfast', 'quick dinner', 'healthy', 'keto'];
      for (const query of popularQueries) {
        await this.cacheSearch(query, {});
      }

      // 5. Mark successful run
      await this.markSuccessfulRun();

      this.logger.log(`Pre-warm complete: ${recipes.length} recipes, ${popularQueries.length} searches`);
    } catch (error) {
      this.logger.error(`Pre-warm failed (${jobName}): ${error.message}`, error.stack);
      throw error;
    }
  }
}
```

### Pattern 4: HTML Stripping for Voice Narration Prep

**What:** Strip HTML tags from Spoonacular `summary` field, generate `plainText` for AVSpeechSynthesizer.

**When to use:** During recipe import/caching. Phase 24 (AVSpeech) needs plain text, not HTML.

**Example:**
```typescript
// Source: striptags npm package + voice narration requirements

import striptags from 'striptags';

function mapSpoonacularToRecipe(spoon: SpoonacularRecipe): Prisma.RecipeCreateInput {
  // Strip HTML from summary
  const description = striptags(spoon.summary || '');

  // Generate plainText for voice narration (Phase 24)
  const ingredientsText = spoon.extendedIngredients
    .map(ing => `${ing.amount} ${ing.unit} ${ing.name}`)
    .join('. ');

  const stepsText = spoon.analyzedInstructions[0]?.steps
    .map(step => step.step)
    .join('. ') || '';

  const plainText = `Ingredients: ${ingredientsText}. Instructions: ${stepsText}`;

  return {
    name: spoon.title,
    description,
    plainText,
    spoonacularId: spoon.id,
    sourceUrl: spoon.sourceUrl,
    sourceName: spoon.sourceName,
    imageUrl: spoon.image, // Spoonacular CDN URL (636x393)
    imageStatus: 'READY', // No R2 upload needed
    prepTime: spoon.readyInMinutes,
    cookTime: null,
    servings: spoon.servings,
    calories: spoon.nutrition?.nutrients.find(n => n.name === 'Calories')?.amount,
    protein: spoon.nutrition?.nutrients.find(n => n.name === 'Protein')?.amount,
    carbs: spoon.nutrition?.nutrients.find(n => n.name === 'Carbohydrates')?.amount,
    fat: spoon.nutrition?.nutrients.find(n => n.name === 'Fat')?.amount,
    difficulty: deriveDifficulty(spoon.readyInMinutes, spoon.analyzedInstructions[0]?.steps.length || 0),
    cuisineType: mapCuisine(spoon.cuisines[0]),
    mealType: mapMealType(spoon.dishTypes),
    dietaryTags: spoon.diets,
    popularityScore: spoon.aggregateLikes,
    scrapedFrom: 'spoonacular',
    scrapedAt: new Date(),
  };
}

function deriveDifficulty(readyInMinutes: number, stepCount: number): DifficultyLevel {
  if (readyInMinutes < 30 && stepCount < 8) return 'BEGINNER';
  if (readyInMinutes < 60) return 'INTERMEDIATE';
  return 'ADVANCED';
}
```

### Anti-Patterns to Avoid

- **Fetching individual recipes in a loop:** Always use `getRecipeInformationBulk` (1 point for 100 recipes) instead of N separate calls (N points). This is the difference between exhausting quota in 50 recipes vs. 5000.
- **Debounced search (live-as-you-type):** Each keystroke costs quota points. Require explicit submit (tap Search button or Enter key) to preserve quota.
- **No quota tracking before API calls:** Must check quota BEFORE making request. Spoonacular returns 402 when exhausted, which is too late to serve cache gracefully.
- **Caching search results without full recipe details:** Must cache complete recipe information (use `addRecipeInformation=true` or bulk endpoint), not just recipe IDs. Otherwise, detail view triggers additional quota-consuming calls.
- **Not using normalized cache keys:** `"Chicken"` and `"chicken"` with filters `{diet: 'vegan', cuisine: 'italian'}` vs. `{cuisine: 'italian', diet: 'vegan'}` should hit same cache. Normalize: lowercase, trim, sort filter keys alphabetically.
- **Circuit breaker that blocks cache hits:** Circuit breaker should only prevent new API calls, not cache retrieval. Users should still get stale cache when circuit is open.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTTP retry logic with exponential backoff | Custom retry loops with setTimeout | @nestjs/axios with HttpModule config OR nestjs-axios-retry | Edge cases: concurrent requests, jitter, per-status-code retry, max attempts. Library handles all of this. |
| Circuit breaker state management | Custom failure counters + timers | opossum circuit breaker | Handles half-open state testing, concurrent request handling, event emission for monitoring. Hand-rolled version always has race conditions. |
| HTML tag stripping | Regex like `/<[^>]+>/g` | striptags | Regex breaks on edge cases: `<script>alert('</script>')</script>`, malformed HTML, nested tags. Library handles all HTML spec edge cases. |
| Cache key normalization | String concatenation + manual lowercasing | Structured function with sort + JSON.stringify | Easy to forget edge cases: filter order, whitespace, null vs undefined, array vs single value. Centralized function prevents cache miss bugs. |
| Daily quota reset logic | Manual date comparison + cleanup | PostgreSQL date-based partition OR TTL with daily key | Time zones, daylight saving, leap seconds. Use database date functions, not app-level logic. |
| Batch job retry scheduling | Nested setTimeout calls | @nestjs/schedule with separate @Cron jobs | Handling server restarts, multiple retries, logging, failure notifications. Cron jobs are declarative and survive restarts. |

**Key insight:** Quota management is the highest-risk area. Spoonacular's free tier (50 points/day) is VERY limited. A single bug in quota tracking or cache-miss logic can exhaust quota in minutes. Use battle-tested libraries for HTTP, caching, and scheduling. The complexity budget should go to business logic (recipe mapping, filter validation), not reinventing infrastructure.

## Common Pitfalls

### Pitfall 1: Confusing "requests" vs. "points" in quota tracking

**What goes wrong:** Tracking HTTP call count instead of Spoonacular points. 1 HTTP request can cost 1-50+ points depending on parameters (`addRecipeNutrition`, `addRecipeInstructions`, etc.).

**Why it happens:** Spoonacular docs use "requests" colloquially, but quota is point-based. Endpoints have variable costs.

**How to avoid:**
- Track points, not calls.
- Calculate point cost BEFORE API call: `complexSearch` costs 1 + 0.01/result + 1 (if nutrient filter) + 0.025/result (if `addRecipeInformation=true`).
- Log both calls and points consumed: `logger.info('API call: complexSearch, cost: 3.5 points, total today: 23/50')`

**Warning signs:**
- Quota exhausts faster than expected (50 calls/day should last, but exhausting in 10-20 calls).
- 402 errors appearing when your call counter shows remaining quota.
- Check Spoonacular response headers: `X-API-Quota-Used` shows actual points consumed.

### Pitfall 2: Missing rate limit delays between API calls

**What goes wrong:** Making rapid consecutive API calls (e.g., in a loop for batch pre-warm). Spoonacular free tier allows 1 req/s. Violating this causes 429 errors or temporary bans.

**Why it happens:** Bulk endpoint reduces quota cost but doesn't bypass rate limits. Even `getRecipeInformationBulk` (1 call for 100 recipes) still counts as 1 request against the 1 req/s limit.

**How to avoid:**
- Enforce 1-second delay between API calls: `await sleep(1000)` after each request.
- For batch jobs, this means 100 recipes (10 cuisines × 10 recipes) = 10 search calls + 1 bulk call = 11 seconds minimum.
- Use `lastRequestTime` tracker to ensure 1 req/s: `if (now - lastRequestTime < 1000) await sleep(1000 - elapsed)`.

**Warning signs:**
- 429 (Too Many Requests) errors in logs.
- Spoonacular API temporarily blocking requests (returns errors for 5-10 minutes).
- Batch job completes suspiciously fast (<10 seconds for 100 recipes).

### Pitfall 3: Serving 402 errors to iOS instead of stale cache

**What goes wrong:** Quota exhaustion reaches iOS as blank feed or error toast. User sees "Recipe search unavailable" instead of graceful degradation.

**Why it happens:** Checking quota AFTER API call fails (catch block serves error to client) instead of BEFORE call (serve cache if quota exhausted).

**How to avoid:**
- Check quota before API call: `if (!hasQuota) return getCachedResults()`.
- Stale-while-revalidate: serve expired cache immediately, background refresh if quota available.
- Only show quota exhaustion banner if BOTH quota exhausted AND cache empty (this should be rare with pre-warming).
- iOS should never see 402 or quota-related errors. Backend absorbs all quota complexity.

**Warning signs:**
- iOS shows "No recipes found" when cache should have pre-warmed popular recipes.
- Error logs show 402 responses proxied to GraphQL clients.
- Users report blank feed during quota exhaustion windows.

### Pitfall 4: Not skipping recipes without `analyzedInstructions`

**What goes wrong:** Caching recipes without step-by-step instructions. Phase 24 (AVSpeech narration) fails because no `plainText` to narrate.

**Why it happens:** Spoonacular returns recipes with incomplete data. Some have `summary` but no `analyzedInstructions`. Assuming all recipes are narration-ready.

**How to avoid:**
- Validate before caching: `if (!recipe.analyzedInstructions?.[0]?.steps?.length) { logger.warn('Skipping recipe: no instructions'); continue; }`
- Same for images: `if (!recipe.image) { logger.warn('Skipping recipe: no image'); continue; }`
- Log skip reasons for analytics: "Skipped 23 recipes: 15 missing instructions, 8 missing images"

**Warning signs:**
- Recipe detail views showing "No instructions available".
- Voice playback button missing or grayed out for Spoonacular recipes.
- User confusion: "Why can't I hear this recipe?"

### Pitfall 5: Forgetting to strip HTML from Spoonacular `summary`

**What goes wrong:** Recipe description displays HTML tags (`<b>`, `<a>`, `<p>`) in UI, or worse, voice narration reads out "opening tag bold delicious closing tag bold".

**Why it happens:** Spoonacular returns `summary` with HTML formatting. iOS renders plain text (not HTML) in RecipeCard and voice narration uses AVSpeech (which reads HTML tags aloud).

**How to avoid:**
- Strip HTML during import: `description: striptags(spoon.summary)`
- Test with a known HTML-heavy recipe (e.g., search "pasta" — summaries often have `<a href>` links).
- Verify in voice narration preview (Phase 24): listen to first 30 seconds, ensure no "opening tag" or "closing tag" spoken.

**Warning signs:**
- Recipe descriptions showing `<b>Rich</b> and <i>creamy</i> pasta` instead of "Rich and creamy pasta".
- Voice narration saying "opening tag bold rich closing tag bold".
- User reports about "weird text in recipes".

### Pitfall 6: Cache key collisions from filter order differences

**What goes wrong:** Identical search with filters in different order creates duplicate cache entries. `{diet: 'vegan', cuisine: 'italian'}` vs. `{cuisine: 'italian', diet: 'vegan'}` cache separately, wasting quota and storage.

**Why it happens:** Object key order varies by JavaScript engine. `JSON.stringify({a: 1, b: 2})` may differ from `JSON.stringify({b: 2, a: 1})` depending on insertion order.

**How to avoid:**
- Normalize cache keys: sort filter keys alphabetically before stringifying.
- Lowercase query text: `query.trim().toLowerCase()`.
- Example: `normalizeCacheKey(query, filters) { return JSON.stringify({ query: query.trim().toLowerCase(), filters: Object.keys(filters).sort().reduce((obj, key) => ({ ...obj, [key]: filters[key] }), {}) }); }`

**Warning signs:**
- Cache hit rate lower than expected (<80% for popular queries).
- Database query shows duplicate search cache entries with same semantic meaning.
- Quota exhausting despite aggressive caching.

## Code Examples

Verified patterns from official sources:

### NestJS HttpModule Configuration with Retry and Timeout

```typescript
// Source: https://docs.nestjs.com/techniques/http-module + nestjs-axios-retry patterns

import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';

@Module({
  imports: [
    HttpModule.register({
      baseURL: 'https://api.spoonacular.com',
      timeout: 5000, // 5 seconds
      maxRedirects: 0,
      params: {
        apiKey: process.env.SPOONACULAR_API_KEY,
      },
      headers: {
        'User-Agent': 'Kindred/5.0',
      },
    }),
  ],
  providers: [SpoonacularService],
  exports: [SpoonacularService],
})
export class SpoonacularModule {}
```

### Prisma Migration for Recipe Table Evolution

```typescript
// Source: Prisma schema evolution patterns + CONTEXT.md decisions

// prisma/schema.prisma additions

model Recipe {
  // ... existing fields ...

  // NEW: Spoonacular integration
  spoonacularId  Int?     @unique
  sourceUrl      String?
  sourceName     String?
  plainText      String?  // For voice narration (Phase 24)
  popularityScore Int?    // Maps to aggregateLikes

  // REMOVED: geo fields (set to nullable in migration, then drop)
  // latitude    Float?
  // longitude   Float?
  // location    String?

  // MODIFIED: scrapedFrom now includes 'spoonacular'
  scrapedFrom String // 'x' | 'instagram' | 'spoonacular'

  @@index([spoonacularId])
  @@index([popularityScore])
}

// NEW: Search cache table
model SearchCache {
  id            String   @id @default(cuid())
  normalizedKey String   @unique // Normalized query + filters
  recipeIds     String[] // Array of Recipe.id (cuids)
  cachedAt      DateTime @default(now())

  @@index([cachedAt])
}

// NEW: API quota tracking
model ApiQuotaUsage {
  id         String   @id @default(cuid())
  date       String   @unique // YYYY-MM-DD format
  pointsUsed Float    @default(0)
  createdAt  DateTime @default(now())
  updatedAt  DateTime @updatedAt

  @@index([date])
}
```

```bash
# Migration command
npx prisma migrate dev --name spoonacular-integration

# Migration file (generated)
-- Add Spoonacular fields
ALTER TABLE "Recipe" ADD COLUMN "spoonacularId" INTEGER UNIQUE;
ALTER TABLE "Recipe" ADD COLUMN "sourceUrl" TEXT;
ALTER TABLE "Recipe" ADD COLUMN "sourceName" TEXT;
ALTER TABLE "Recipe" ADD COLUMN "plainText" TEXT;
ALTER TABLE "Recipe" ADD COLUMN "popularityScore" INTEGER;

-- Drop geo fields (make nullable first for safety)
ALTER TABLE "Recipe" ALTER COLUMN "latitude" DROP NOT NULL;
ALTER TABLE "Recipe" ALTER COLUMN "longitude" DROP NOT NULL;
ALTER TABLE "Recipe" ALTER COLUMN "location" DROP NOT NULL;

-- Delete all existing recipes (clean slate)
DELETE FROM "Recipe";

-- Drop geo columns after deletion
ALTER TABLE "Recipe" DROP COLUMN "latitude";
ALTER TABLE "Recipe" DROP COLUMN "longitude";
ALTER TABLE "Recipe" DROP COLUMN "location";

-- Create new tables
CREATE TABLE "SearchCache" (
  "id" TEXT PRIMARY KEY,
  "normalizedKey" TEXT UNIQUE NOT NULL,
  "recipeIds" TEXT[] NOT NULL,
  "cachedAt" TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE "ApiQuotaUsage" (
  "id" TEXT PRIMARY KEY,
  "date" TEXT UNIQUE NOT NULL,
  "pointsUsed" FLOAT NOT NULL DEFAULT 0,
  "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
  "updatedAt" TIMESTAMP NOT NULL
);

-- Add indexes
CREATE INDEX "Recipe_spoonacularId_idx" ON "Recipe"("spoonacularId");
CREATE INDEX "Recipe_popularityScore_idx" ON "Recipe"("popularityScore");
CREATE INDEX "SearchCache_cachedAt_idx" ON "SearchCache"("cachedAt");
CREATE INDEX "ApiQuotaUsage_date_idx" ON "ApiQuotaUsage"("date");
```

### GraphQL Schema Extensions

```typescript
// Source: NestJS GraphQL code-first patterns + existing FeedResolver

// src/recipes/dto/search-recipes.input.ts
import { InputType, Field, Int } from '@nestjs/graphql';

@InputType()
export class SearchRecipesInput {
  @Field({ nullable: true, description: 'Search keyword (e.g., "pasta carbonara")' })
  query?: string;

  @Field(() => [String], { nullable: true, description: 'Cuisine types to filter by' })
  cuisines?: string[];

  @Field(() => [String], { nullable: true, description: 'Diet types (vegan, vegetarian, etc.)' })
  diets?: string[];

  @Field(() => [String], { nullable: true, description: 'Intolerances to exclude (gluten, dairy, etc.)' })
  intolerances?: string[];

  @Field(() => Int, { nullable: true, defaultValue: 20, description: 'Results per page' })
  first?: number;

  @Field({ nullable: true, description: 'Pagination cursor' })
  after?: string;
}

// src/recipes/recipes.resolver.ts
@Resolver(() => Recipe)
export class RecipesResolver {
  constructor(private recipesService: RecipesService) {}

  @Query(() => RecipeConnection, {
    description: 'Search recipes from Spoonacular with filters',
  })
  async searchRecipes(
    @Args('input', { type: () => SearchRecipesInput }) input: SearchRecipesInput,
  ): Promise<RecipeConnection> {
    return this.recipesService.searchRecipes(input);
  }

  @Query(() => RecipeConnection, {
    description: 'Get popular recipes across diverse cuisines',
  })
  async popularRecipes(
    @Args('first', { type: () => Int, nullable: true, defaultValue: 20 }) first: number,
    @Args('after', { type: () => String, nullable: true }) after?: string,
  ): Promise<RecipeConnection> {
    return this.recipesService.getPopularRecipes(first, after);
  }

  // DEPRECATED: Keep for backward compatibility until Phase 26
  @Query(() => [Recipe], {
    description: 'DEPRECATED: Use popularRecipes instead. Will be removed in Phase 26.',
    deprecationReason: 'Replaced by Spoonacular integration. Use `popularRecipes` query.',
  })
  async viralRecipes(@Args('location') location: string): Promise<Recipe[]> {
    // Return empty array or redirect to popularRecipes
    return [];
  }
}
```

### Environment Variable Validation

```typescript
// Source: Existing backend/src/config/env.validation.ts pattern

import { IsString, IsNotEmpty } from 'class-validator';

export class EnvironmentVariables {
  // ... existing fields ...

  // Spoonacular API
  @IsString()
  @IsNotEmpty()
  SPOONACULAR_API_KEY: string;
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Redis for caching | PostgreSQL UNLOGGED tables | 2024-2025 | PostgreSQL 14+ performance improvements (parallel queries, JIT compilation) make it viable for caching. UNLOGGED tables skip WAL overhead. Simpler deployment (no Redis infrastructure). |
| Manual quota tracking with cron cleanup | Date-based partition keys | 2025+ | PostgreSQL `date` type auto-indexes efficiently. Query `WHERE date = CURRENT_DATE` is fast. No cleanup cron needed — old rows harmless, can prune monthly. |
| BullMQ for all async jobs | @nestjs/schedule for simple cron | 2024+ | @nestjs/schedule improved in v4.x with better timezone support and error handling. BullMQ overhead only justified for complex retry/persistence (not simple daily batch). |
| Axios interceptors for retry | @nestjs/axios HttpModule config | 2025+ | HttpModule v3.x added first-class retry support via config (no manual interceptors). Cleaner DI integration. |
| Custom HTML sanitization | striptags library | Stable | Regex-based approaches always miss edge cases. striptags handles full HTML spec (nested tags, malformed markup, script injection). |

**Deprecated/outdated:**
- **RapidAPI Spoonacular tier:** Some old tutorials reference RapidAPI hosting of Spoonacular. Current best practice is direct Spoonacular API (better rate limits, lower latency, official support).
- **`searchRecipes` endpoint:** Spoonacular docs now recommend `complexSearch` for most use cases (combines filtering + search + sorting in one call, more quota-efficient).
- **Prisma 4.x migration patterns:** Prisma 7.x (current project version) improved migration safety with shadow database and introspection checks. Old "manual SQL + prisma db pull" patterns no longer needed.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Jest 29.7.0 + ts-jest 29.4.6 |
| Config file | package.json (inline `jest` key) |
| Quick run command | `npm test -- spoonacular.spec.ts` |
| Full suite command | `npm test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RECIPE-01 | Search recipes by keyword returns Spoonacular results | unit | `npm test -- spoonacular.service.spec.ts -t "searchRecipes"` | ❌ Wave 0 |
| RECIPE-02 | Filter by cuisine/diet/intolerances applies to API call | unit | `npm test -- spoonacular.service.spec.ts -t "filters"` | ❌ Wave 0 |
| RECIPE-03 | Recipe image URLs point to Spoonacular CDN | unit | `npm test -- recipe-mapper.spec.ts -t "imageUrl"` | ❌ Wave 0 |
| RECIPE-06 | Source attribution includes sourceName and sourceUrl | unit | `npm test -- recipe-mapper.spec.ts -t "attribution"` | ❌ Wave 0 |
| CACHE-01 | Cache returns cached results within 6-hour TTL | unit | `npm test -- spoonacular-cache.service.spec.ts -t "TTL"` | ❌ Wave 0 |
| CACHE-02 | Quota tracking increments on API call, blocks at limit | unit | `npm test -- spoonacular.service.spec.ts -t "quota"` | ❌ Wave 0 |
| CACHE-03 | Quota exhaustion serves stale cache gracefully | integration | `npm test -- recipes.service.spec.ts -t "quota exhausted"` | ❌ Wave 0 |
| CACHE-04 | Daily batch job pre-warms 100 recipes at 2 AM UTC | unit (mock cron) | `npm test -- spoonacular-batch.scheduler.spec.ts -t "prewarm"` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `npm test -- {modified-file}.spec.ts` (fast unit tests for changed modules)
- **Per wave merge:** `npm test` (full suite, should complete in <30 seconds with mocked Spoonacular)
- **Phase gate:** Full suite green + manual smoke test (search "pasta", verify cache, check quota tracking in logs)

### Wave 0 Gaps

- [ ] `src/spoonacular/spoonacular.service.spec.ts` — covers RECIPE-01, RECIPE-02, CACHE-02 (mock HTTP, verify API params, quota tracking)
- [ ] `src/spoonacular/spoonacular-cache.service.spec.ts` — covers CACHE-01 (TTL expiration, cache key normalization)
- [ ] `src/spoonacular/dto/recipe-mapper.spec.ts` — covers RECIPE-03, RECIPE-06 (Spoonacular → Prisma mapping, attribution fields)
- [ ] `src/recipes/recipes.service.spec.ts` — covers CACHE-03 (integration: quota exhausted scenario, serve stale cache)
- [ ] `src/spoonacular/spoonacular-batch.scheduler.spec.ts` — covers CACHE-04 (mock @Cron, verify pre-warm logic, retry flow)
- [ ] Mock fixtures: `test/fixtures/spoonacular-responses.json` — realistic Spoonacular API responses for deterministic tests

**No test framework install needed** — Jest already configured in package.json.

## Open Questions

1. **Free tier quota: 50 vs. 150 points/day**
   - What we know: Official Spoonacular pricing page (verified 2026-04-04) shows "50 points/day" for free tier. CONTEXT.md mentions "150 req/day" which may be from older tier or different source.
   - What's unclear: Where did "150 req/day" come from? Is there a different free tier via RapidAPI or educational discount?
   - Recommendation: Proceed with 50 points/day (official), but design system to be configurable (env var `SPOONACULAR_DAILY_QUOTA=50`). If user has higher quota, change env var. Code should work for any quota limit.

2. **Spoonacular `diets` array mapping to `dietaryTags` string array**
   - What we know: Spoonacular returns `diets: ['vegan', 'gluten free']`, project uses `dietaryTags: string[]`.
   - What's unclear: Do we need to normalize Spoonacular diet names to match existing tags? (e.g., "gluten free" → "gluten-free" or keep as-is?)
   - Recommendation: Store Spoonacular diet values as-is (no normalization). iOS can display them directly. If exact match needed for filtering, add mapping table in Wave 1.

3. **How to handle recipes with multiple cuisines**
   - What we know: CONTEXT.md says "take first cuisine from array". Spoonacular often returns 2-3 cuisines (e.g., `['italian', 'european', 'mediterranean']`).
   - What's unclear: Will "first cuisine" bias towards generic tags like 'european'? Should we prefer most specific (e.g., 'italian' over 'european')?
   - Recommendation: Take first cuisine as specified. If bias becomes problem in Phase 26 (iOS testing), add specificity ranking (Wave 1 refactor).

4. **Nutrition data completeness from Spoonacular**
   - What we know: Spoonacular provides `nutrition.nutrients` array. Need to extract calories, protein, carbs, fat.
   - What's unclear: Are these fields always present? Or do some recipes have incomplete nutrition?
   - Recommendation: Make all nutrition fields nullable (`calories?: Int`, etc.). Log warnings for recipes missing nutrition data. Filter out recipes with <2 nutrition fields in pre-warm (better UX).

5. **Voice narration `plainText` format**
   - What we know: Phase 24 uses AVSpeechSynthesizer with `plainText` field. CONTEXT.md says "concatenate ingredients + steps".
   - What's unclear: Optimal format for speech synthesis? Should we add pauses (SSML later)? Comma-separated vs. period-separated?
   - Recommendation: Use period-separated for now (`ingredient1. ingredient2. Step 1. Step 2.`). Natural pauses between sentences. Phase 24 can add SSML if needed without schema change.

## Sources

### Primary (HIGH confidence)

- [Spoonacular Official Pricing](https://spoonacular.com/food-api/pricing) - Free tier: 50 points/day, 1 req/s, verified 2026-04-04
- [Spoonacular API Documentation](https://spoonacular.com/food-api/docs) - Endpoint costs, parameters, response formats
- [NestJS Task Scheduling](https://docs.nestjs.com/techniques/task-scheduling) - @Cron decorator, timezone support
- [NestJS HTTP Module](https://docs.nestjs.com/techniques/http-module) - Axios wrapper, timeout/retry config
- [NestJS Caching](https://docs.nestjs.com/techniques/caching) - Cache-manager integration patterns
- [Prisma Schema Evolution](https://www.prisma.io/dataguide/types/relational/migration-strategies) - Expand-and-contract pattern, nullable fields
- [Prisma Customizing Migrations](https://www.prisma.io/docs/orm/prisma-migrate/workflows/customizing-migrations) - Manual SQL in migrations

### Secondary (MEDIUM confidence)

- [NestJS Circuit Breaker Pattern (Medium)](https://medium.com/@Abdelrahman_Rezk/circuit-breaker-pattern-a-comprehensive-guide-with-nest-js-application-41300462d579) - Implementation guide
- [PostgreSQL as Cache (Martin Heinz)](https://martinheinz.dev/blog/105) - UNLOGGED tables, TTL patterns
- [OneUpTime NestJS Caching Guide](https://oneuptime.com/blog/post/2026-02-02-nestjs-caching/view) - Cache strategies, 2026 best practices
- [DevZery Spoonacular Guide 2025](https://www.devzery.com/post/spoonacular-api-complete-guide-recipe-nutrition-food-integration) - complexSearch usage
- [striptags npm](https://www.npmjs.com/package/striptags) - HTML stripping library

### Tertiary (LOW confidence)

- Various WebSearch results about Spoonacular "150 requests/day" — could not verify with official docs, possibly outdated or third-party tier

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All libraries verified against official docs, versions match project package.json
- Architecture: HIGH - Patterns extracted from existing backend code (pantry schedulers, feed resolver), adapted for Spoonacular
- Pitfalls: MEDIUM - Quota management pitfalls inferred from free tier constraints + common caching mistakes, not Spoonacular-specific documentation

**Research date:** 2026-04-04
**Valid until:** 2026-05-04 (30 days — Spoonacular API stable, NestJS patterns mature)

**Critical correction:** Official Spoonacular free tier is **50 points/day**, not 150 req/day as mentioned in CONTEXT.md. This requires more aggressive caching and bulk endpoint usage than originally anticipated. Planning should account for this tighter constraint.
