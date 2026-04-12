# Phase 23: Spoonacular Backend Integration - Context

**Gathered:** 2026-04-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace the current X/Instagram scraping pipeline with Spoonacular REST API as the recipe data source. Backend proxies and caches all responses in PostgreSQL to stay under the 150 req/day free quota. New GraphQL queries (searchRecipes, popularRecipes) are added alongside deprecated old queries. iOS changes deferred to Phase 26.

</domain>

<decisions>
## Implementation Decisions

### Recipe Data Mapping
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

### Quota Strategy
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

### Cache & Pre-warm Behavior
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

### Search & Filter
- Search bar + filter chips: text keyword search + cuisine, diet, intolerances chips
- Auto-apply user's dietary preferences from onboarding as default filters (toggleable)
- Explicit submit (not debounced): user taps Search/Enter. Preserves quota
- Intolerances combined with dietary filters in same section (no separate UI)
- Default sort: popularity (aggregateLikes descending)
- Popularity only sort (no sort picker)
- 20 results per page, cursor-based pagination (matches existing RecipeConnection pattern)
- Guest accessible: no auth required for search or browse

### GraphQL API
- Add new queries: `searchRecipes`, `popularRecipes` alongside deprecated old ones
- Keep `viralRecipes` and location-based `feed` queries as @deprecated until Phase 26
- Recipe detail via existing `recipe(id:)` query using internal cuid ID
- Cache full recipe details during search (use getRecipeInformationBulk, 1 API point for up to 100 recipes)
- Flat fields for attribution: `sourceName` String?, `sourceUrl` String?
- Attribution: "Recipe from [sourceName] - Powered by Spoonacular" on detail view only (not cards)

### Error Handling & Resilience
- Spoonacular API down: serve stale cache, log error. User never notices
- 5-second timeout per API call
- Circuit breaker: 5 consecutive failures -> 15 min cooldown, cache-only
- All Spoonacular errors handled server-side; no Spoonacular-specific errors leak to iOS
- Log Spoonacular response times for performance monitoring
- Standard NestJS Logger: INFO for batch runs, WARN for quota/skipped recipes, ERROR for API failures
- Mock tests only (no real API calls in CI)

### Old Service Cleanup
- Delete: ScrapingService, XApiService, InstagramService, RecipeParserService, ScrapingScheduler
- Delete: ImageGenerationProcessor, image queue/BullMQ setup
- Delete: all tests for deleted services
- Remove: X_API_KEY, INSTAGRAM_* env vars from ConfigModule validation
- Remove: unused npm dependencies (X API SDK, Instagram scraper, AI image generation)
- Keep: GeocodingService (used by FeedResolver), VelocityScorer (used by FeedService until Phase 26)
- Keep: R2 storage service (used for voice uploads/narration)
- Keep: PostGIS extension in PostgreSQL

### Migration Strategy
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

</decisions>

<specifics>
## Specific Ideas

- Use Spoonacular's `getRecipeInformationBulk` endpoint (1 point for up to 100 recipes) to maximize quota efficiency
- Pre-warm should cover cuisine diversity: ~10 recipes each from 10 different cuisines
- "Recipe from Foodista.com - Powered by Spoonacular" attribution pattern with link to sourceUrl
- Store `plainText` (concatenated ingredients + steps) during import so Phase 24 (AVSpeechSynthesizer) has narration text ready immediately
- Use largest image size (636x393) from Spoonacular CDN for crisp display on all devices
- Difficulty estimation heuristic: <30 min & <8 steps = BEGINNER, <60 min = INTERMEDIATE, else ADVANCED

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `RecipesService` / `RecipesResolver`: existing recipe CRUD, will be updated to work with Spoonacular-cached data
- `FeedService` / `FeedResolver`: PostGIS feed with cursor pagination, RecipeConnection type, filter relaxation — stays as-is until Phase 26
- `RecipeCard` / `RecipeCardEdge` / `RecipeConnection` / `PageInfo` GraphQL types: reuse for new queries
- `FeedFiltersInput`: existing filter input type with cuisineTypes, mealTypes, dietaryTags
- `ScheduleModule`: already configured with `@nestjs/schedule` for Cron jobs
- `PrismaService`: database access layer, Prisma ORM
- `ConfigModule`: env validation pattern with Joi, add SPOONACULAR_API_KEY here
- `RequestIdInterceptor`: request tracing, works automatically
- `ThrottlerModule`: rate limiting already configured (default 100/min, expensive 10/min)
- `HealthModule`: extend with quota metrics

### Established Patterns
- Code-first GraphQL with `@nestjs/graphql` + Apollo
- Prisma ORM for all database access
- NestJS Logger for structured logging
- `@Cron()` decorators for scheduled tasks (see pantry schedulers)
- Cursor-based pagination with base64-encoded cursors

### Integration Points
- `AppModule`: add new SpoonacularModule, remove ScrapingModule/ImagesModule
- `schema.prisma`: evolve Recipe model, add api_quota_usage + search_cache tables
- `/health` endpoint: extend with quota metrics
- GraphQL schema: add searchRecipes + popularRecipes queries
- `.env` / ConfigModule: add SPOONACULAR_API_KEY, remove scraping keys

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 23-spoonacular-backend-integration*
*Context gathered: 2026-04-04*
