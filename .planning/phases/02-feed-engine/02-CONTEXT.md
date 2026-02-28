# Phase 2: Feed Engine - Context

**Gathered:** 2026-03-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Backend API that serves hyperlocal viral recipe discovery. Users can discover trending recipes near them, filter by cuisine/meal/dietary tags, change location, and receive cached content offline. This phase builds the feed engine API that mobile apps (Phase 4 iOS, Phase 9 Android) will consume. No mobile UI is built in this phase.

</domain>

<decisions>
## Implementation Decisions

### Feed Ranking
- Trending-first ranking by engagement velocity (loves/views per hour) — hottest recipes surface first
- Pure trending, no discovery mix — 100% ranked by engagement velocity
- Velocity-based viral badge: engagement per hour within the local area determines VIRAL status (e.g., 200 loves in 2 hours beats 1000 loves over a week)
- Humanized engagement counts: "1.2k loves this week" or "342 loves today" — relative timeframe to show recency
- 7-day rolling window for feed content — recipes older than 7 days fade from the feed unless still trending

### Location Model
- GPS auto-detect: app requests location permission, backend maps coordinates to city/area
- City-level display in location badge (e.g., "Austin", not "East Austin, Austin")
- True geo-radius for 5-10 mile proximity: store lat/lng on recipes, use PostGIS for distance queries
- Geocoding required for all scraped recipes (assign lat/lng based on location string)
- Search-by-city for manual location change (FEED-08): type city name with autocomplete suggestions

### Filtering & Categories
- AI-tagged during scraping: extend Gemini parser to also tag cuisine type and meal type
- Fine-grained cuisine categories (30+): Italian, Mexican, Chinese, Japanese, Sichuan, Cantonese, Indian, Thai, Korean, Vietnamese, Mediterranean, French, Spanish, Greek, Middle Eastern, Lebanese, Turkish, Moroccan, Ethiopian, American, Southern, Tex-Mex, Brazilian, Peruvian, Caribbean, British, German, etc.
- Meal types: Breakfast, Lunch, Dinner, Snack, Dessert, Appetizer, Drink
- Combinable AND filters: user can select 'Italian' + 'Dinner' + 'Gluten-free' simultaneously
- Dietary tags already exist in schema — reuse for filtering

### Offline & Caching
- Cache headers + staleness field: API returns Cache-Control/ETag headers, responses include 'lastRefreshed' timestamp
- Cursor-based pagination: return cursor token for next page (replace current offset-based approach) — better for infinite scroll
- Cached + expanded radius fallback when scraping fails: return cached local recipes first, then expand (city -> country -> global). Response includes scope field so app knows results are expanded
- Pull-to-refresh only — no background polling. Battery-friendly, user-controlled. 4x/day scraping means real-time isn't critical
- Query-only GraphQL, no subscriptions for Phase 2
- Engagement counts recalculated during scraping cycle (4x/day)

### Recipe Card Data
- Summary view for feed: return only card-level fields (id, name, imageUrl, prepTime, calories, engagementLoves, isViral, cuisineType). Full recipe details fetched on tap
- Show recipes with pending/failed images using a styled placeholder — don't hide recipes waiting for image generation
- Card displays: prep time + calories only (no difficulty or cook time on card — those go in detail view)
- Dietary tags shown only in detail view, not on cards — keep cards clean for elderly users

### Feed Updates
- Feed response includes 'newSinceLastFetch' count when client sends a timestamp — enables "Pull to see 5 new recipes" badge

### Empty States
- Never return empty feed: auto-expand location (city -> country -> global) with 'expandedFrom/expandedTo' flags
- Show even 1 recipe — any data is better than none
- When filters produce zero results: return nearest partial matches with 'partialMatch: true' flag and which filters were relaxed

### Claude's Discretion
- Exact velocity scoring formula and weights
- PostGIS setup and spatial indexing strategy
- Geocoding service choice (Google Maps, Mapbox, etc.)
- Cursor implementation details (opaque token encoding)
- Cache-Control header values and staleness thresholds
- Partial match ranking algorithm for filter relaxation

</decisions>

<specifics>
## Specific Ideas

- Feed should feel like TikTok's "For You" — what's hot surfaces first, engagement velocity determines what's trending
- Fallback strategy should be seamless — user should never see an empty feed, just a note about expanded scope
- "Loves this week" with humanized counts creates social proof and urgency

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `RecipesService` (backend/src/recipes/recipes.service.ts): Has findAll, findViral, findRecent, countByLocation — needs refactoring from offset to cursor pagination and adding geo-queries
- `RecipesResolver` (backend/src/recipes/recipes.resolver.ts): Has recipes, recipe, viralRecipes queries — needs extension for feed query with filters
- `ScrapingService` (backend/src/scraping/scraping.service.ts): Already has city->country->global fallback logic — extend with geocoding and velocity calculation
- `RecipeParserService` (backend/src/scraping/recipe-parser.service.ts): Gemini-based parser — extend to tag cuisine type and meal type

### Established Patterns
- GraphQL code-first with NestJS decorators and explicit type annotations
- Prisma 7 with PostgreSQL adapter for database access
- Background processing via in-memory queue (ImageGenerationProcessor pattern)
- Non-blocking enrichment: recipes available immediately, images populate async

### Integration Points
- Recipe model (prisma/schema.prisma): Needs new fields — cuisineType, mealType, latitude, longitude
- ScrapingScheduler: 4x/day cron — hook velocity recalculation into this cycle
- Existing engagement fields (engagementLoves, engagementBookmarks, engagementViews) — used for velocity calculation
- Existing isViral boolean + viralThreshold — replace with velocity-based calculation

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-feed-engine*
*Context gathered: 2026-03-01*
