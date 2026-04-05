# Phase 26: Feed UI Migration - Context

**Gathered:** 2026-04-05
**Status:** Ready for planning

<domain>
## Phase Boundary

iOS feed switches from "Viral near you" branding to "Popular Recipes" with popularity scores. Recipe cards show popularity score badge (replacing viral badge) and ingredient match % based on pantry. Feed loads from the new `popularRecipes` GraphQL query (replacing deprecated `viralRecipes`). Backend cleanup removes deprecated scraping services, X API service, image generation processor, and the viralRecipes query.

</domain>

<decisions>
## Implementation Decisions

### Popularity Badge Design
- Percentage badge with flame icon: show `🔥 85%` format (SF Symbol: flame.fill)
- Position: top-right of recipe card image (same position as current ViralBadge)
- Threshold: only show at 50%+ popularity score (matches MatchBadge threshold pattern)
- Color coding: same as MatchBadge — `kindredSuccess` (green) at 70%+, `kindredAccent` at 50-69%
- Both popularity badge and MatchBadge show simultaneously when both qualify (different corners)
- Differentiation between badges: position only (top-left vs top-right), flame icon distinguishes popularity
- Accessibility label: "[X]% popular" (e.g., "85 percent popular")

### Feed Heading & Layout
- Static "Popular Recipes" section header above the card stack, below dietary chip bar
- Use `kindredHeading1` font for the heading (larger than card titles for visual hierarchy)
- Location pill in toolbar stays as-is (no change)
- Loves count stays in metadata row (clock + time, flame + calories, heart + loves)

### Pagination
- Switch from offset-based to cursor-based pagination to match backend's `RecipeConnection` (first/after)
- Eliminates duplicate recipes on page boundaries

### Data Model
- Remove `isViral: Bool` from RecipeCard, replace with `popularityScore: Int?`
- Remove `velocityScore: Double` (no longer relevant)
- Include `popularityScore` field in the new PopularRecipesQuery GraphQL definition
- Include ingredient names in the feed query response (same pattern as current viralRecipes)

### Ingredient Match
- Keep local IngredientMatcher.swift (no Spoonacular findByIngredients API calls)
- Hide match badge for guest users (current behavior — pantry requires auth)
- Keep 50% threshold for showing MatchBadge
- Keep current staples exclusion list unchanged
- Recompute match percentages on tab switch only (current behavior)
- Match badge shows percentage only (no detail popup or long-press)
- Ingredient data comes from GraphQL response (included in feed query)

### Query Migration
- Create new `PopularRecipesQuery.graphql` targeting backend's `popularRecipes` query
- All ViralRecipesQuery call sites in FeedReducer switch to PopularRecipesQuery simultaneously (atomic migration)
- Remove `RecipeCard.from(graphQL:)` mapping for ViralRecipesQuery, create new mapping for PopularRecipesQuery
- Delete `ViralRecipesQuery.graphql.swift` from KindredAPI package

### Backend Cleanup (same phase, after iOS changes)
- Delete ScrapingService, XApiService, ImageGenerationProcessor — entire modules (service, tests, DTOs, module files)
- Remove `viralRecipes` GraphQL resolver and `findViral` method from RecipesService
- Clean up `app.module.ts` imports to remove references to deleted modules
- Delete associated test/spec files for all removed services
- TestFlight verification = rollout confirmed (pre-launch app, no App Store backward compat needed)

### Claude's Discretion
- Exact animation for popularity badge appearance (spring vs fade)
- Loading skeleton adjustments for the new layout
- Error state wording updates
- Cursor pagination state management details in FeedReducer

</decisions>

<specifics>
## Specific Ideas

- Popularity badge replaces ViralBadge in the exact same position — minimal visual disruption
- The badge should feel like MatchBadge's sibling — same shape, same color system, just different icon and position
- "Popular Recipes" heading should feel like a clear section label, not a navigation title

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `MatchBadge.swift`: Pattern for percentage badge with color coding (green 70%+, accent 50-69%), spring animation, accessibility label — directly reusable for PopularityBadge
- `ForYouBadge.swift`: Simple text badge pattern with accessibility hidden — reference for badge styling
- `ViralBadge.swift`: Will be replaced/deleted — current position and overlay pattern shows where new badge goes
- `IngredientMatcher.swift`: Complete local matching logic with staples exclusion — no changes needed
- `DietaryChipBar.swift`: Horizontal scrolling chip bar — heading goes below this component

### Established Patterns
- TCA (ComposableArchitecture) for state management — FeedReducer handles all feed logic
- Apollo GraphQL client with `.cacheFirst` / `.networkOnly` policies
- Kingfisher for image loading (KFImage)
- DesignSystem package provides spacing (KindredSpacing), colors (.kindredAccent, .kindredSuccess), typography (.kindredHeading1, etc.)
- Recipe card overlay pattern: `.overlay(alignment: .topTrailing)` for badges on hero image

### Integration Points
- `FeedReducer.swift`: 4 places call ViralRecipesQuery (onAppear, refreshFeed, changeLocation, connectivityChanged) — all switch atomically
- `RecipeCardView.swift`: ViralBadge overlay (line 112-116) → replaced with PopularityBadge
- `FeedModels.swift`: RecipeCard struct + `from(graphQL:)` mapping → new mapping for PopularRecipesQuery
- `KindredAPI/Sources/Operations/Queries/`: ViralRecipesQuery.graphql.swift → replaced by PopularRecipesQuery.graphql.swift
- Backend: `recipes.resolver.ts` has `popularRecipes` query ready, `viralRecipes` marked deprecated

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 26-feed-ui-migration*
*Context gathered: 2026-04-05*
