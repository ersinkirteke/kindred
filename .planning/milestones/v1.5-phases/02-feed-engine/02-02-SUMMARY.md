---
phase: 02-feed-engine
plan: 02
subsystem: feed-engine
tags: [velocity-scoring, ai-tagging, geocoding, scraping, tdd]
requires: [02-01]
provides: [velocity-scorer, cuisine-meal-tagging, scraping-geocoding]
affects: [scraping-pipeline, recipe-parser, recipe-model]
tech_stack:
  added: [humanize-plus]
  patterns: [tdd-cycle, velocity-calculation, time-decay, ai-classification]
key_files:
  created:
    - backend/src/feed/utils/velocity-scorer.ts
    - backend/src/feed/utils/velocity-scorer.spec.ts
  modified:
    - backend/src/scraping/dto/scraped-recipe.dto.ts
    - backend/src/scraping/recipe-parser.service.ts
    - backend/src/scraping/scraping.service.ts
    - backend/src/scraping/scraping.module.ts
    - backend/package.json
decisions:
  - decision: "Velocity scoring formula: (engagement/hour) * (1 + e^(-age/24)) with viral threshold = 10/hour"
    rationale: "Combines raw engagement rate with exponential time decay - fresh content gets boost, older content needs higher raw engagement to overcome decay"
  - decision: "Views weighted at 0.3x compared to loves"
    rationale: "Views are passive engagement, loves are active - different signal strength for viral detection"
  - decision: "Minimum effective age of 0.5 hours prevents division by zero"
    rationale: "Very fresh content (< 30 min) could have extreme velocities due to low denominator - cap prevents instability"
  - decision: "Humanized engagement with time windows (this hour/today/this week)"
    rationale: "User-facing strings need context - '1.2k loves today' is more meaningful than raw numbers"
  - decision: "Gemini parser extracts cuisineType and mealType with 29 + 7 categories"
    rationale: "AI tagging enables feed filtering without manual categorization - fine-grained cuisine classification per user locked decision"
  - decision: "Geocode city once per scrape, apply lat/lng to all recipes from that city"
    rationale: "Efficient - prevents N geocoding API calls when scraping N recipes from same city"
  - decision: "Velocity-based viral detection replaces hardcoded threshold=1000"
    rationale: "User locked decision: engagement per hour within local area determines VIRAL status, not static raw counts"
metrics:
  duration: 8 min
  tasks_completed: 2
  files_created: 2
  files_modified: 5
  lines_added: 477
  commits: 2
  completed_at: "2026-03-01T08:54:34Z"
---

# Phase 02 Plan 02: Feed Ranking Algorithm Summary

**One-liner:** Velocity-based engagement scoring with AI cuisine/meal tagging and geocoding integration for viral detection and feed filtering.

## What Was Built

### Core Components

1. **VelocityScorer Utility (TDD)**
   - Pure TypeScript class (no NestJS decorators) for testable velocity calculation
   - Formula: `(engagement/hour) * (1 + e^(-age/24))` with viral threshold = 10/hour
   - Views weighted at 0.3x compared to loves (passive vs active engagement)
   - Minimum effective age: 0.5 hours (prevents division by zero for very fresh content)
   - Time decay factor: exponential over 24 hours (fresh content gets boost, older content needs higher raw engagement)
   - Humanized engagement strings with time windows: "1.2k loves today", "45 loves this hour", "5k loves this week"
   - **TDD Workflow:** 13 tests written first (RED), implementation (GREEN), all tests passing
   - Dependencies: `humanize-plus` for number formatting

2. **Extended ParsedRecipe DTO**
   - Added `cuisineType: string` - One of 29 CuisineType enum values
   - Added `mealType: string` - One of 7 MealType enum values
   - Enables AI-driven feed filtering without manual categorization

3. **AI Cuisine/Meal Tagging in RecipeParserService**
   - Extended Gemini 2.0 Flash prompt to extract `cuisineType` and `mealType`
   - 29 cuisine categories: Italian, Mexican, Chinese, Japanese, Sichuan, Cantonese, Indian, Thai, Korean, Vietnamese, Mediterranean, French, Spanish, Greek, Middle Eastern, Lebanese, Turkish, Moroccan, Ethiopian, American, Southern, Tex-Mex, Brazilian, Peruvian, Caribbean, British, German, Fusion, Other
   - 7 meal categories: Breakfast, Lunch, Dinner, Snack, Dessert, Appetizer, Drink
   - Prompt requirements: prioritize traditional origin (tacos = Mexican not Tex-Mex), base meal type on traditional serving time
   - Mapping functions: `mapToCuisineEnum()` and `mapToMealEnum()` convert AI output to Prisma enum format
     - "Middle Eastern" → MIDDLE_EASTERN
     - "Tex-Mex" → TEX_MEX
     - "Italian" → ITALIAN
   - Validation: defaults to OTHER for cuisineType, DINNER for mealType if unrecognized

4. **Geocoding Integration in ScrapingService**
   - Imported `GeocodingModule` in `ScrapingModule`
   - Injected `GeocodingService` in `ScrapingService` constructor
   - Geocode city **once per scrape cycle** (not per recipe) at start of `scrapeForCity()`
   - Apply `latitude` and `longitude` to all recipes from that city
   - Graceful degradation: if geocoding fails, recipes get null lat/lng and warning is logged

5. **Velocity Scoring in Scraping Pipeline**
   - Imported `VelocityScorer` utility
   - Calculate velocity for each new recipe: `VelocityScorer.calculate(engagementLoves, engagementViews, postedAt)`
   - Store `velocityScore` and `isViral` flag in database
   - **Removed hardcoded `viralThreshold = 1000`** - replaced with velocity-based detection
   - Log output includes velocity score: `✓ Stored recipe: Tacos (xyz123) - velocity: 12.34 [VIRAL]`

6. **Velocity Recalculation Method**
   - `recalculateVelocityScores()`: Batch updates velocity for all recipes within 7-day window
   - Fetches recipes with `scrapedAt >= sevenDaysAgo`
   - Recalculates velocity as content ages (decay factor decreases, velocity drops)
   - Updates `velocityScore` and `isViral` for each recipe
   - Exposed for scheduler to call during each scraping cycle (4x/day)
   - Logs viral count: `Velocity recalculation complete: 12 viral recipes out of 45`

### Integration Points

- **ScrapingModule**: Imports `GeocodingModule` (makes `GeocodingService` available for DI)
- **ScrapingService**: Uses `VelocityScorer.calculate()` and `GeocodingService.geocodeCity()`
- **RecipeParserService**: Extended Gemini prompt with cuisine/meal extraction and enum mapping
- **Recipe Model**: Stores `cuisineType`, `mealType`, `latitude`, `longitude`, `velocityScore` (all populated during scraping)

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

### Automated Checks
- ✅ `npx jest velocity-scorer --no-coverage` - All 13 tests passing (TDD RED-GREEN cycle complete)
- ✅ `npx tsc --noEmit` - TypeScript compiles with zero errors
- ✅ `npm run build` - Production build succeeds
- ✅ RecipeParserService prompt includes cuisineType and mealType extraction
- ✅ ScrapingService uses velocity-based viral detection (no hardcoded threshold)
- ✅ ScrapingService geocodes cities and stores lat/lng on recipes

### Success Criteria Met
- ✅ Velocity scoring formula implemented: `(engagement/hour) * (1 + e^(-age/24))`
- ✅ Views weighted 0.3x, min age 0.5h, viral threshold 10/hour
- ✅ Humanized engagement strings match user requirement ("1.2k loves today")
- ✅ Gemini parser extracts cuisine type (29 categories) and meal type (7 categories)
- ✅ Scraped recipes geocoded with lat/lng from city location
- ✅ Velocity recalculation available for batch updates during scraping cycle

## Requirements Satisfied

- **FEED-03**: Viral Badge - Velocity-based viral detection with threshold = 10 engagements/hour
- **FEED-06**: Cuisine/Meal Filtering - AI-tagged cuisineType and mealType enable feed query filters

## Key Technical Details

### Velocity Formula Breakdown

```typescript
// Example: Recipe scraped 2 hours ago with 100 loves
const ageHours = 2;
const effectiveAge = Math.max(ageHours, 0.5); // 2 hours
const totalEngagement = 100 + (0 * 0.3); // 100 (no views)
const rawVelocity = 100 / 2; // 50 per hour
const decayFactor = Math.exp(-2 / 24); // e^(-0.083) ≈ 0.920
const velocityScore = 50 * (1 + 0.920); // 50 * 1.920 ≈ 96
const isViral = 96 >= 10; // true
```

**Time Decay Impact:**
- Fresh (1 hour): decay = e^(-1/24) ≈ 0.959 → boost factor = 1.959
- Day old (24 hours): decay = e^(-1) ≈ 0.368 → boost factor = 1.368
- Week old (168 hours): decay = e^(-7) ≈ 0.001 → boost factor ≈ 1.001

Old content needs ~2x higher raw velocity to overcome lost decay boost.

### AI Tagging Prompt Engineering

**Key prompt requirements:**
- "cuisineType MUST be one of the listed categories (case-sensitive)"
- "If cuisine doesn't fit, use 'Fusion' for mixed or 'Other'"
- "For ambiguous dishes, prioritize traditional origin (tacos = Mexican not Tex-Mex)"
- "Base meal type on when dish is traditionally served"

**Why this matters:**
- Prevents AI hallucination of invalid categories (would break Prisma enum constraint)
- Consistent categorization across scraping cycles (same dish = same cuisine)
- User-facing filter values must be stable (not "Breakfast Tacos" cuisine type)

### Geocoding Efficiency

**Before (naive approach):**
- Scrape 20 recipes from Austin → 20 Mapbox API calls ($0.005 × 20 = $0.10)

**After (city-level caching):**
- Scrape 20 recipes from Austin → 1 geocoding call (DB cache hit) + 1 Mapbox call (cache miss) = $0.005
- Future scrapes: 0 Mapbox calls (DB cache hit) = $0

**Annual savings at scale:**
- 4 scrapes/day × 20 cities × 365 days = 29,200 scrapes/year
- Cache hit rate: ~99% after first day
- Cost: $0.005 × 292 (first day + 1% misses) = ~$1.46/year vs $146 without cache

### Velocity Recalculation Strategy

**Why recalculate?**
- Recipe scraped 1 hour ago with 100 loves: velocity ≈ 195 (viral)
- Same recipe 24 hours later: velocity ≈ 137 (still viral but decaying)
- Same recipe 7 days later: velocity ≈ 0.6 (no longer viral)

**Scheduler integration (future):**
```typescript
@Cron('0 8,12,18,21 * * *') // 4x/day at scraping times
async runScheduledScraping() {
  await this.scrapingService.scrapeWithFallback('Austin');
  await this.scrapingService.recalculateVelocityScores(); // Update existing recipes
}
```

## Testing Notes

### Manual Testing (Post-Deployment)

1. **Test velocity scoring:**
   - Scrape a fresh post with 200 loves → should be viral (velocity > 10)
   - Wait 7 days, recalculate → should no longer be viral (velocity < 10)

2. **Test AI cuisine tagging:**
   - Post with "authentic Italian pasta carbonara" → cuisineType = ITALIAN
   - Post with "Korean-Mexican fusion tacos" → cuisineType = FUSION (not MEXICAN or KOREAN)
   - Post with "Texas-style brisket tacos" → cuisineType = SOUTHERN or TEX_MEX (ambiguous, prioritize traditional)

3. **Test geocoding integration:**
   - Scrape from "Austin" → all recipes should have lat ≈ 30.27, lng ≈ -97.74
   - Check DB: CityLocation table should have cached entry for Austin
   - Second scrape from "Austin" → should use DB cache (no Mapbox API call)

4. **Test velocity recalculation:**
   - Run `recalculateVelocityScores()` → check logs for viral count
   - Query DB: recipes from 7 days ago should have velocityScore ≈ 0-1
   - Query DB: recipes from 1 hour ago should have velocityScore > 10 if engagement is high

### Unit Testing

- ✅ VelocityScorer has 13 passing tests covering:
  - Fresh content with moderate engagement → high velocity
  - Old content with same engagement → very low velocity
  - Viral threshold = 10/hour
  - Time decay exponential function
  - Minimum effective age = 0.5 hours
  - Views weighted at 0.3x
  - Humanized strings with time windows

## Next Steps

**Immediate (Plan 02-03):**
- Implement feed query resolver using PostGIS spatial queries and velocityScore sorting
- Add GraphQL filters for cuisineType and mealType
- Return humanized engagement strings in feed response

**Future Enhancements:**
- Adaptive viral threshold based on city population (e.g., 10/hour in NYC, 5/hour in smaller cities)
- Machine learning model to predict velocity trajectory (will this recipe go viral in next 6 hours?)
- A/B test different decay formulas (exponential vs linear vs logarithmic)

## Self-Check: PASSED

### Files Created
- ✅ FOUND: /Users/ersinkirteke/Workspaces/Kindred/backend/src/feed/utils/velocity-scorer.ts
- ✅ FOUND: /Users/ersinkirteke/Workspaces/Kindred/backend/src/feed/utils/velocity-scorer.spec.ts

### Files Modified
- ✅ FOUND: /Users/ersinkirteke/Workspaces/Kindred/backend/src/scraping/dto/scraped-recipe.dto.ts
- ✅ FOUND: /Users/ersinkirteke/Workspaces/Kindred/backend/src/scraping/recipe-parser.service.ts
- ✅ FOUND: /Users/ersinkirteke/Workspaces/Kindred/backend/src/scraping/scraping.service.ts
- ✅ FOUND: /Users/ersinkirteke/Workspaces/Kindred/backend/src/scraping/scraping.module.ts

### Commits
- ✅ FOUND: 7d4f239 - feat(02-02): add velocity scorer with TDD and extend ParsedRecipe DTO
- ✅ FOUND: 3192934 - feat(02-02): integrate AI cuisine/meal tagging, geocoding, and velocity scoring in scraping
