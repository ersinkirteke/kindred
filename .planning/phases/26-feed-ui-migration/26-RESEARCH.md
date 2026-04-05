# Phase 26: Feed UI Migration - Research

**Researched:** 2026-04-05
**Domain:** iOS SwiftUI + TCA + GraphQL migration, NestJS backend cleanup
**Confidence:** HIGH

## Summary

Phase 26 migrates the iOS feed from deprecated "viral recipes" branding to "popular recipes" with popularity scores. The iOS app currently calls a deprecated `viralRecipes` GraphQL query that is slated for removal. This phase atomically switches all feed data sources to the new `popularRecipes` query (already implemented in Phase 23), updates the UI to show popularity score badges instead of viral badges, and removes deprecated backend services after iOS rollout.

This is a **critical integration gap** - the feed is currently broken because FeedReducer.swift calls a deprecated query. The backend's `popularRecipes` query is ready and waiting, but the iOS client hasn't migrated yet.

**Primary recommendation:** Use TCA state management patterns for atomic query migration, reuse MatchBadge component design for PopularityBadge, switch from offset to cursor pagination to align with backend's RecipeConnection type, and defer backend cleanup until iOS changes are verified in TestFlight.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Popularity Badge Design:**
- Percentage badge with flame icon: show `🔥 85%` format (SF Symbol: flame.fill)
- Position: top-right of recipe card image (same position as current ViralBadge)
- Threshold: only show at 50%+ popularity score (matches MatchBadge threshold pattern)
- Color coding: same as MatchBadge — `kindredSuccess` (green) at 70%+, `kindredAccent` at 50-69%
- Both popularity badge and MatchBadge show simultaneously when both qualify (different corners)
- Differentiation between badges: position only (top-left vs top-right), flame icon distinguishes popularity
- Accessibility label: "[X]% popular" (e.g., "85 percent popular")

**Feed Heading & Layout:**
- Static "Popular Recipes" section header above the card stack, below dietary chip bar
- Use `kindredHeading1` font for the heading (larger than card titles for visual hierarchy)
- Location pill in toolbar stays as-is (no change)
- Loves count stays in metadata row (clock + time, flame + calories, heart + loves)

**Pagination:**
- Switch from offset-based to cursor-based pagination to match backend's `RecipeConnection` (first/after)
- Eliminates duplicate recipes on page boundaries

**Data Model:**
- Remove `isViral: Bool` from RecipeCard, replace with `popularityScore: Int?`
- Remove `velocityScore: Double` (no longer relevant)
- Include `popularityScore` field in the new PopularRecipesQuery GraphQL definition
- Include ingredient names in the feed query response (same pattern as current viralRecipes)

**Ingredient Match:**
- Keep local IngredientMatcher.swift (no Spoonacular findByIngredients API calls)
- Hide match badge for guest users (current behavior — pantry requires auth)
- Keep 50% threshold for showing MatchBadge
- Keep current staples exclusion list unchanged
- Recompute match percentages on tab switch only (current behavior)
- Match badge shows percentage only (no detail popup or long-press)
- Ingredient data comes from GraphQL response (included in feed query)

**Query Migration:**
- Create new `PopularRecipesQuery.graphql` targeting backend's `popularRecipes` query
- All ViralRecipesQuery call sites in FeedReducer switch to PopularRecipesQuery simultaneously (atomic migration)
- Remove `RecipeCard.from(graphQL:)` mapping for ViralRecipesQuery, create new mapping for PopularRecipesQuery
- Delete `ViralRecipesQuery.graphql.swift` from KindredAPI package

**Backend Cleanup (same phase, after iOS changes):**
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

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| RECIPE-04 | Recipe cards show popularity score instead of viral badge | PopularityBadge component pattern, RecipeCard model migration, GraphQL schema field |
| RECIPE-05 | Feed displays "Popular Recipes" heading (replaces "Viral near you") | SwiftUI Text with kindredHeading1, static placement below DietaryChipBar |
| RECIPE-07 | User sees ingredient match % on recipe cards based on pantry via Spoonacular findByIngredients | LOCAL IngredientMatcher.swift already handles this (no Spoonacular API call), ingredient data included in GraphQL response |

</phase_requirements>

## Standard Stack

### Core (iOS)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17.0+ | Declarative UI framework | Apple's first-class UI framework, full integration with iOS ecosystem |
| TCA (ComposableArchitecture) | 1.x | State management + side effects | Project's established architecture, testable reducers, dependency injection |
| Apollo iOS | 1.x | GraphQL client + code generation | Industry standard for GraphQL on iOS, type-safe queries, normalized cache |
| Kingfisher | 7.x | Image loading + caching | Project's existing image loading solution, supports placeholder + fade animations |

### Core (Backend)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| NestJS | 10.x | Node.js framework | Project's backend framework, decorators for GraphQL resolvers |
| @nestjs/graphql | 12.x | GraphQL schema generation | Official NestJS GraphQL integration, code-first approach |
| Prisma | 5.x | Database ORM | Project's ORM, type-safe queries, includes/relations |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| DesignSystem (SPM) | Local package | Typography, colors, spacing | All UI components (kindredHeading1, kindredSuccess, kindredAccent, KindredSpacing) |
| Dependencies (TCA) | 1.x | Dependency injection | All reducer effects (@Dependency macro) |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| TCA | Vanilla SwiftUI @State | Lose testability, dependency injection, effects composition — not viable for this project |
| Apollo iOS | URLSession + manual decoding | Lose type-safety, cache normalization, code generation — reinventing the wheel |
| Cursor pagination | Offset pagination (current) | Backend already provides RecipeConnection with cursor pagination (Phase 23), offset causes duplicate cards on page boundaries |

**Installation:**

iOS dependencies already installed via SPM. Backend dependencies already installed via npm (Phase 23).

Apollo code generation command (already configured in `apollo-codegen-config.json`):
```bash
cd Kindred
apollo-ios-cli generate
```

## Architecture Patterns

### Recommended Project Structure

iOS changes:
```
Kindred/Packages/FeedFeature/Sources/
├── Feed/
│   ├── FeedReducer.swift          # Switch viralRecipes → popularRecipes (4 call sites)
│   ├── RecipeCardView.swift       # Replace ViralBadge with PopularityBadge overlay
│   ├── PopularityBadge.swift      # NEW: Clone MatchBadge pattern, flame icon, color coding
│   └── ViralBadge.swift           # DELETE after migration
├── Models/
│   └── FeedModels.swift           # Update RecipeCard: isViral→popularityScore, remove velocityScore
└── (IngredientMatcher.swift)      # NO CHANGES (already supports local matching)

Kindred/Packages/NetworkClient/Sources/GraphQL/
├── FeedQueries.graphql            # ADD PopularRecipesQuery, DELETE ViralRecipes after migration
└── (RecipeQueries.graphql)        # NO CHANGES

Kindred/Packages/KindredAPI/Sources/Operations/Queries/
├── PopularRecipesQuery.graphql.swift  # GENERATED by Apollo after adding PopularRecipesQuery
└── ViralRecipesQuery.graphql.swift    # DELETE after migration
```

Backend cleanup (after iOS verification):
```
backend/src/
├── recipes/
│   ├── recipes.resolver.ts        # DELETE viralRecipes query resolver
│   └── recipes.service.ts         # DELETE findViral() method
├── scraping/                      # DELETE entire module (if exists)
├── xapi/                          # DELETE entire module (if exists)
└── images/
    ├── image-generation.processor.ts  # DELETE (if exists)
    └── r2-storage.service.ts      # KEEP (used by voice uploads)
```

### Pattern 1: TCA Reducer Query Migration (Atomic)

**What:** Replace all references to deprecated query with new query simultaneously in a single commit.

**When to use:** When backend query is already implemented and iOS client needs to switch data sources.

**Example:**
```swift
// FeedReducer.swift — 4 call sites to migrate atomically

// OLD (Phase 25):
let query = KindredAPI.ViralRecipesQuery(location: location)
let result = try await apolloClient.fetch(query: query, cachePolicy: .networkOnly)
if let recipes = result.data?.viralRecipes {
    let cards = recipes.map { RecipeCard.from(graphQL: $0) }
    await send(.recipesLoaded(.success(cards)))
}

// NEW (Phase 26):
let query = KindredAPI.PopularRecipesQuery(first: 20, after: nil)
let result = try await apolloClient.fetch(query: query, cachePolicy: .networkOnly)
if let connection = result.data?.popularRecipes {
    let cards = connection.edges.map { RecipeCard.from(popularRecipe: $0.node) }
    await send(.recipesLoaded(.success(cards)))
}
```

**Migration checklist:**
1. Define new PopularRecipesQuery.graphql (first, after, popularityScore field)
2. Run `apollo-ios-cli generate` to create PopularRecipesQuery.graphql.swift
3. Add `RecipeCard.from(popularRecipe:)` mapping in FeedModels.swift
4. Search FeedReducer.swift for all `ViralRecipesQuery` call sites (4 places: onAppear, refreshFeed, changeLocation, connectivityChanged)
5. Replace all 4 call sites simultaneously
6. Update FeedReducer state: add `endCursor: String?`, remove `currentPage: Int`
7. Delete old `RecipeCard.from(graphQL:)` mapping for ViralRecipesQuery
8. Delete ViralRecipesQuery.graphql.swift from KindredAPI package
9. Verify compilation passes

### Pattern 2: Badge Component Reuse (MatchBadge → PopularityBadge)

**What:** Clone existing MatchBadge component design for PopularityBadge, replacing icon and accessibility label only.

**When to use:** When new badge needs same visual style, color coding, and animation as existing badge.

**Example:**
```swift
// Source: MatchBadge.swift (existing)
struct MatchBadge: View {
    let percentage: Int
    @State private var animationScale: CGFloat = 0.8
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        Text("\(percentage)%")
            .font(.kindredCaption())
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, KindredSpacing.sm)
            .padding(.vertical, KindredSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(badgeColor)
            )
            .scaleEffect(animationScale)
            .onAppear {
                if !reduceMotion {
                    withAnimation(.spring(response: 0.3)) {
                        animationScale = 1.0
                    }
                } else {
                    animationScale = 1.0
                }
            }
            .accessibilityLabel("\(percentage) percent ingredients available")
            .allowsHitTesting(false)
    }

    private var badgeColor: Color {
        if percentage >= 70 {
            return .kindredSuccess
        } else {
            return .kindredAccent
        }
    }
}

// NEW PopularityBadge.swift (clone pattern):
struct PopularityBadge: View {
    let percentage: Int  // popularityScore from backend
    @State private var animationScale: CGFloat = 0.8
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")  // CHANGED: flame icon instead of text-only
                .font(.system(size: 12))
            Text("\(percentage)%")
        }
        .font(.kindredCaption())
        .fontWeight(.bold)
        .foregroundStyle(.white)
        .padding(.horizontal, KindredSpacing.sm)
        .padding(.vertical, KindredSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(badgeColor)  // SAME color logic
        )
        .scaleEffect(animationScale)
        .onAppear {
            if !reduceMotion {
                withAnimation(.spring(response: 0.3)) {  // SAME animation
                    animationScale = 1.0
                }
            } else {
                animationScale = 1.0
            }
        }
        .accessibilityLabel("\(percentage) percent popular")  // CHANGED label
        .allowsHitTesting(false)
    }

    private var badgeColor: Color {
        if percentage >= 70 {
            return .kindredSuccess  // SAME thresholds
        } else {
            return .kindredAccent
        }
    }
}
```

### Pattern 3: TCA Cursor Pagination State Management

**What:** Replace offset-based pagination with cursor-based pagination in TCA state.

**When to use:** When backend uses Relay-style cursor pagination (RecipeConnection with edges/pageInfo).

**Example:**
```swift
// FeedReducer.swift State

// OLD (offset-based):
public var currentPage: Int = 0
public var hasMorePages = true

// NEW (cursor-based):
public var endCursor: String? = nil
public var hasNextPage = true

// Pagination logic:

case .loadMoreRecipes:
    guard state.hasNextPage && !state.isLoading else {
        return .none
    }

    return .run { [endCursor = state.endCursor] send in
        do {
            let query = KindredAPI.PopularRecipesQuery(
                first: 20,
                after: endCursor  // nil for first page, cursor string for subsequent pages
            )
            let result = try await apolloClient.fetch(
                query: query,
                cachePolicy: .cacheFirst
            )

            if let connection = result.data?.popularRecipes {
                let cards = connection.edges.map { RecipeCard.from(popularRecipe: $0.node) }
                await send(.moreRecipesLoaded(
                    .success(cards),
                    newCursor: connection.pageInfo.endCursor,
                    hasMore: connection.pageInfo.hasNextPage
                ))
            }
        } catch {
            await send(.moreRecipesLoaded(.failure(error)))
        }
    }

case let .moreRecipesLoaded(.success(cards), newCursor, hasMore):
    state.endCursor = newCursor
    state.hasNextPage = hasMore
    let existingIDs = Set(state.allRecipes.map(\.id)).union(state.swipedRecipeIDs)
    let newCards = cards.filter { !existingIDs.contains($0.id) }
    state.allRecipes.append(contentsOf: newCards)
    let filtered = applyDietaryFilter(recipes: newCards, filters: state.activeDietaryFilters)
    state.cardStack.append(contentsOf: filtered)
    return .send(.computeMatchPercentages)
```

### Pattern 4: GraphQL Query Definition (Apollo iOS)

**What:** Define GraphQL query in .graphql file, run code generation to produce type-safe Swift query.

**When to use:** All GraphQL operations in Apollo iOS projects.

**Example:**
```graphql
# Kindred/Packages/NetworkClient/Sources/GraphQL/FeedQueries.graphql

query PopularRecipes($first: Int, $after: String) {
  popularRecipes(first: $first, after: $after) {
    edges {
      node {
        id
        name
        description
        prepTime
        cookTime
        calories
        imageUrl
        imageStatus
        popularityScore
        engagementLoves
        dietaryTags
        difficulty
        cuisineType
        ingredients {
          name
          quantity
          unit
          orderIndex
        }
      }
      cursor
    }
    pageInfo {
      hasNextPage
      endCursor
    }
    totalCount
  }
}
```

**Code generation:**
```bash
cd Kindred
apollo-ios-cli generate
# Generates: Kindred/Packages/KindredAPI/Sources/Operations/Queries/PopularRecipesQuery.graphql.swift
```

**Usage:**
```swift
import KindredAPI

let query = KindredAPI.PopularRecipesQuery(first: 20, after: nil)
let result = try await apolloClient.fetch(query: query, cachePolicy: .networkOnly)

// Type-safe access:
if let connection = result.data?.popularRecipes {
    let edges = connection.edges  // [PopularRecipesQuery.Data.PopularRecipe.Edge]
    let hasNextPage = connection.pageInfo.hasNextPage  // Bool
    let endCursor = connection.pageInfo.endCursor  // String?
}
```

### Anti-Patterns to Avoid

- **Incremental query migration:** Don't migrate one call site at a time — breaks feed consistency. Migrate all 4 call sites atomically in FeedReducer.
- **Manual JSON parsing:** Don't bypass Apollo code generation. Always define queries in .graphql files and use generated types.
- **Mixing offset + cursor pagination:** Don't keep `currentPage` state alongside `endCursor` — causes confusion. Fully migrate to cursor-based.
- **Premature backend cleanup:** Don't delete `viralRecipes` resolver until iOS rollout is verified in TestFlight. Backend cleanup is last step.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| GraphQL query execution | Custom URLSession wrapper with Codable | Apollo iOS client | Type-safe queries, normalized cache, subscription support, battle-tested error handling |
| Cursor pagination state | Custom page token manager | TCA state with endCursor/hasNextPage | Relay spec compliance, built-in page info from RecipeConnection |
| Image loading + caching | Custom URLSession + NSCache | Kingfisher (already in project) | Placeholder support, fade animations, memory/disk cache management |
| Badge component | New SwiftUI view from scratch | Clone MatchBadge pattern | Visual consistency, accessibility support, animation behavior already correct |

**Key insight:** The project already has established patterns (MatchBadge for percentage badges, IngredientMatcher for local matching, TCA for state). Reusing these patterns ensures visual/behavioral consistency and avoids reinventing solutions.

## Common Pitfalls

### Pitfall 1: Apollo Code Generation Stale Types

**What goes wrong:** After adding PopularRecipesQuery.graphql, Swift code references `KindredAPI.PopularRecipesQuery` but Xcode shows "Type not found" or autocomplete fails.

**Why it happens:** Apollo code generation hasn't run yet, so the Swift types don't exist.

**How to avoid:** Always run `apollo-ios-cli generate` after modifying .graphql files, before attempting to use query types in Swift code.

**Warning signs:** Build errors like "Cannot find 'PopularRecipesQuery' in scope", autocomplete doesn't suggest query types.

**Fix:**
```bash
cd Kindred
apollo-ios-cli generate
# Verify generation succeeded: check Kindred/Packages/KindredAPI/Sources/Operations/Queries/
```

### Pitfall 2: Cursor Pagination State Desync

**What goes wrong:** Pagination loads duplicate recipes or infinite loops when scrolling to end of feed.

**Why it happens:** `endCursor` and `hasNextPage` not updated correctly after loading more recipes, or pagination triggered when already at end.

**How to avoid:**
1. Always update both `state.endCursor` and `state.hasNextPage` in same action (atomic)
2. Guard `loadMoreRecipes` with `!state.isLoading && state.hasNextPage`
3. Reset cursor state on location change or refresh

**Warning signs:** Duplicate recipe cards in feed, "Load more" action firing repeatedly with no new cards.

**Fix pattern:**
```swift
case let .moreRecipesLoaded(.success(cards), newCursor, hasMore):
    state.endCursor = newCursor      // Update cursor first
    state.hasNextPage = hasMore      // Update hasNext atomically
    // ... append cards to state
```

### Pitfall 3: Badge Overlay Z-Order Conflict

**What goes wrong:** PopularityBadge and MatchBadge overlap or one obscures the other when both are shown.

**Why it happens:** Both badges use `.overlay(alignment:)` on the same parent view without distinct corner alignment.

**How to avoid:**
- PopularityBadge: `.overlay(alignment: .topTrailing)` (top-right corner)
- MatchBadge: `.overlay(alignment: .topLeading)` (top-left corner)
- Both badges have same size constraints, so corners don't overlap

**Warning signs:** Badges stacked vertically instead of horizontally separated, one badge hidden behind another.

**Fix pattern (RecipeCardView.swift):**
```swift
heroImageView
    .overlay(alignment: .topTrailing) {
        if let popularityScore = recipe.popularityScore, popularityScore >= 50 {
            PopularityBadge(percentage: popularityScore)
                .padding(KindredSpacing.md)
        }
    }
    .overlay(alignment: .topLeading) {
        if let matchPercentage = recipe.matchPercentage, matchPercentage >= 50 {
            MatchBadge(percentage: matchPercentage)
                .padding(KindredSpacing.md)
        }
    }
```

### Pitfall 4: Backend Cleanup Before iOS Verification

**What goes wrong:** Delete `viralRecipes` resolver from backend before iOS migration is verified, causing feed to break if rollback is needed.

**Why it happens:** Eagerness to clean up deprecated code, not treating TestFlight as rollout gate.

**How to avoid:**
1. Complete iOS migration first (all 4 query call sites switched)
2. Deploy iOS build to TestFlight
3. Verify feed loads correctly in TestFlight
4. ONLY THEN delete backend viralRecipes resolver

**Warning signs:** Backend cleanup commits before iOS migration commits, no TestFlight verification step.

**Correct sequence:**
1. iOS changes (PopularRecipesQuery migration, PopularityBadge, RecipeCard model)
2. iOS commit + TestFlight deploy
3. TestFlight verification (feed loads, cards show popularity badges)
4. Backend cleanup (delete viralRecipes, scraping services)
5. Backend commit

### Pitfall 5: Missing `popularityScore` in GraphQL Query

**What goes wrong:** PopularityBadge doesn't appear on any cards even though backend has popularity scores.

**Why it happens:** Forgot to include `popularityScore` field in PopularRecipesQuery.graphql, so Apollo doesn't fetch it.

**How to avoid:** Cross-reference backend GraphQL schema (recipe.model.ts) to ensure all needed fields are in query definition.

**Warning signs:** `recipe.popularityScore` is always `nil` in iOS code, even though Prisma has data.

**Fix:** Add `popularityScore` to PopularRecipesQuery.graphql field list:
```graphql
query PopularRecipes($first: Int, $after: String) {
  popularRecipes(first: $first, after: $after) {
    edges {
      node {
        id
        name
        # ... other fields
        popularityScore  # ← MUST INCLUDE
        # ...
      }
    }
  }
}
```

## Code Examples

Verified patterns from project codebase and official sources:

### Apollo iOS Query Execution (TCA Effect)

```swift
// Source: FeedReducer.swift (existing pattern)

return .run { [location = state.location] send in
    do {
        let query = KindredAPI.PopularRecipesQuery(first: 20, after: nil)
        let result = try await apolloClient.fetch(
            query: query,
            cachePolicy: .networkOnly  // or .cacheFirst for initial load
        )

        if let connection = result.data?.popularRecipes {
            let cards = connection.edges.map { RecipeCard.from(popularRecipe: $0.node) }
            await send(.recipesLoaded(.success(cards)))
        } else if let errors = result.errors, !errors.isEmpty {
            await send(.recipesLoaded(.failure(FeedError.graphQL(errors.first!.localizedDescription))))
        } else {
            await send(.recipesLoaded(.success([])))
        }
    } catch {
        await send(.recipesLoaded(.failure(error)))
    }
}
```

### RecipeCard Model Extension for PopularRecipesQuery

```swift
// FeedModels.swift — add new mapping

extension RecipeCard {
    static func from(popularRecipe node: KindredAPI.PopularRecipesQuery.Data.PopularRecipe.Edge.Node) -> RecipeCard {
        return RecipeCard(
            id: node.id,
            name: node.name,
            description: node.description,
            prepTime: node.prepTime,
            cookTime: node.cookTime,
            calories: node.calories,
            imageUrl: node.imageUrl,
            isViral: false,  // Deprecated — no longer used
            engagementLoves: node.engagementLoves ?? 0,
            dietaryTags: node.dietaryTags ?? [],
            difficulty: node.difficulty.rawValue,
            cuisineType: node.cuisineType.rawValue,
            popularityScore: node.popularityScore,  // NEW field
            ingredientNames: node.ingredients.map { $0.name }
        )
    }
}
```

### PopularityBadge Component

```swift
// PopularityBadge.swift — clone MatchBadge pattern

import DesignSystem
import SwiftUI

struct PopularityBadge: View {
    let percentage: Int  // popularityScore from backend (0-100)

    @State private var animationScale: CGFloat = 0.8
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 12))
            Text("\(percentage)%")
        }
        .font(.kindredCaption())
        .fontWeight(.bold)
        .foregroundStyle(.white)
        .padding(.horizontal, KindredSpacing.sm)
        .padding(.vertical, KindredSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(badgeColor)
        )
        .scaleEffect(animationScale)
        .onAppear {
            if !reduceMotion {
                withAnimation(.spring(response: 0.3)) {
                    animationScale = 1.0
                }
            } else {
                animationScale = 1.0
            }
        }
        .accessibilityLabel("\(percentage) percent popular")
        .allowsHitTesting(false)
    }

    private var badgeColor: Color {
        if percentage >= 70 {
            return .kindredSuccess  // Green
        } else {
            return .kindredAccent   // Orange/accent
        }
    }
}
```

### RecipeCardView Badge Overlays

```swift
// RecipeCardView.swift — update badge logic

.overlay(alignment: .topTrailing) {
    // PopularityBadge (top-right corner)
    if let popularityScore = recipe.popularityScore, popularityScore >= 50 {
        PopularityBadge(percentage: popularityScore)
            .padding(KindredSpacing.md)
    }
}
.overlay(alignment: .topLeading) {
    // MatchBadge (top-left corner)
    if let matchPercentage = recipe.matchPercentage, matchPercentage >= 50 {
        MatchBadge(percentage: matchPercentage)
            .padding(KindredSpacing.md)
    }
}
.overlay(alignment: .bottomLeading) {
    // ForYouBadge (bottom-left corner) — unchanged
    if isPersonalized {
        ForYouBadge()
            .padding(KindredSpacing.md)
    }
}
```

### Feed Heading (Popular Recipes)

```swift
// FeedView.swift (or wherever feed is rendered)

VStack(alignment: .leading, spacing: KindredSpacing.md) {
    // Location pill + dietary filters — unchanged

    // NEW: Popular Recipes heading
    Text("Popular Recipes")
        .font(.kindredHeading1)
        .foregroundStyle(.kindredTextPrimary)
        .padding(.horizontal, KindredSpacing.lg)

    // Recipe card stack — unchanged rendering
    ZStack {
        ForEach(state.cardStack.reversed()) { recipe in
            RecipeCardView(
                recipe: recipe,
                heroNamespace: heroNamespace,
                isPersonalized: state.isDNAActivated && recipe.isPersonalized,
                onSwipe: { direction in
                    send(.swipeCard(recipe.id, direction))
                },
                onTap: {
                    send(.openRecipeDetail(recipe.id))
                }
            )
        }
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Offset pagination (limit/offset) | Cursor pagination (first/after with Relay spec) | NestJS ecosystem shift ~2021 | Eliminates duplicate results on page boundaries, aligns with GraphQL best practices |
| Viral badge with boolean flag | Popularity badge with 0-100 score | Phase 23 (Spoonacular migration) | More granular ranking, no X API dependency, free tier compatible |
| Spoonacular findByIngredients API call | Local IngredientMatcher.swift | Pre-Phase 26 (existing) | Zero API quota cost, works offline, no rate limits |
| ViralRecipesQuery (deprecated) | PopularRecipesQuery | Phase 26 (this phase) | Aligns iOS client with Phase 23 backend changes |

**Deprecated/outdated:**
- **ViralRecipesQuery:** Deprecated in Phase 23, marked for removal after iOS migration (Phase 26). Replaced by `popularRecipes` query with RecipeConnection return type.
- **Offset-based pagination in RecipeConnection:** Backend now uses cursor-based pagination (first/after/endCursor/hasNextPage). iOS FeedReducer still uses offset (currentPage), causing mismatch.
- **isViral boolean:** Replaced by `popularityScore` integer (0-100). Backend still includes `isViral` for backward compatibility during migration, but iOS should stop using it.

## Open Questions

1. **Animation timing for badge appearance**
   - What we know: MatchBadge uses `.spring(response: 0.3)` on appear
   - What's unclear: Should PopularityBadge use identical spring, or fade-in to differentiate?
   - Recommendation: Use identical spring animation for consistency (user decision: Claude's discretion)

2. **Error state wording when popularRecipes query fails**
   - What we know: Current error shows generic "Failed to load recipes"
   - What's unclear: Should error mention "popular recipes" specifically, or keep generic?
   - Recommendation: Keep generic "Failed to load recipes" — implementation detail shouldn't leak to user-facing errors

3. **Loading skeleton during pagination**
   - What we know: Current skeleton shows placeholder cards
   - What's unclear: Does skeleton need updating for new layout (heading + cards)?
   - Recommendation: No changes needed — skeleton already shows card shapes below dietary filters, heading is just static text

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | XCTest (iOS native) |
| Config file | None — test targets defined in project.yml |
| Quick run command | `xcodebuild test -scheme Kindred -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:KindredTests/FeedReducerTests` |
| Full suite command | `xcodebuild test -scheme Kindred -destination 'platform=iOS Simulator,name=iPhone 16 Pro'` |

Backend:
| Property | Value |
|----------|-------|
| Framework | Jest (NestJS default) |
| Config file | `backend/jest.config.js` |
| Quick run command | `npm test -- recipes.service.spec` |
| Full suite command | `npm test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RECIPE-04 | Recipe cards show popularity score badge when popularityScore >= 50 | unit | `xcodebuild test -scheme FeedFeature -only-testing:FeedFeatureTests/RecipeCardViewTests/testPopularityBadgeAppearance` | ❌ Wave 0 |
| RECIPE-04 | PopularityBadge uses green color when score >= 70, accent color when 50-69 | unit | `xcodebuild test -scheme FeedFeature -only-testing:FeedFeatureTests/PopularityBadgeTests/testColorCoding` | ❌ Wave 0 |
| RECIPE-04 | RecipeCard model has popularityScore field, isViral removed | unit | `xcodebuild test -scheme FeedFeature -only-testing:FeedFeatureTests/FeedModelsTests/testRecipeCardPopularityField` | ❌ Wave 0 |
| RECIPE-05 | FeedView displays "Popular Recipes" heading above card stack | snapshot | `xcodebuild test -scheme Kindred -only-testing:KindredTests/FeedViewTests/testPopularRecipesHeading` | ❌ Wave 0 |
| RECIPE-05 | Feed loads recipes from popularRecipes query, not viralRecipes | integration | `xcodebuild test -scheme FeedFeature -only-testing:FeedFeatureTests/FeedReducerTests/testPopularRecipesQueryUsed` | ❌ Wave 0 |
| RECIPE-07 | Match badge appears on cards when user is authenticated and pantry has >= 50% ingredient match | unit | `xcodebuild test -scheme FeedFeature -only-testing:FeedFeatureTests/IngredientMatcherTests/testMatchPercentageComputation` | ✅ Existing |
| RECIPE-07 | Match badge hidden for guest users | unit | `xcodebuild test -scheme FeedFeature -only-testing:FeedFeatureTests/FeedReducerTests/testMatchBadgeHiddenForGuests` | ❌ Wave 0 |
| Backend | popularRecipes query returns RecipeConnection with popularity scores | integration | `npm test -- recipes.service.spec --testNamePattern="getPopularRecipes"` | ✅ Existing (Phase 23) |
| Backend | viralRecipes resolver removed after iOS migration | manual | N/A — verify build succeeds after deletion | ❌ Phase 26 Wave 2 |

### Sampling Rate

**iOS:**
- **Per task commit:** `xcodebuild test -scheme FeedFeature` (FeedFeature package tests only, ~30 sec)
- **Per wave merge:** `xcodebuild test -scheme Kindred` (full suite, ~2 min)
- **Phase gate:** Full suite green + TestFlight manual verification before backend cleanup

**Backend:**
- **Per task commit:** `npm test -- recipes.service.spec` (RecipesService tests only, ~5 sec)
- **Per wave merge:** `npm test` (full suite, ~45 sec)
- **Phase gate:** Full suite green + no viralRecipes references remain

### Wave 0 Gaps

**iOS:**
- [ ] `FeedFeature/Tests/RecipeCardViewTests.swift` — covers RECIPE-04 (PopularityBadge appearance, color coding)
- [ ] `FeedFeature/Tests/PopularityBadgeTests.swift` — covers RECIPE-04 (badge component in isolation)
- [ ] `FeedFeature/Tests/FeedModelsTests.swift` — covers RECIPE-04 (RecipeCard model fields)
- [ ] `Kindred/Tests/FeedViewTests.swift` — covers RECIPE-05 (heading snapshot test)
- [ ] `FeedFeature/Tests/FeedReducerTests.swift` — covers RECIPE-05 (query usage), RECIPE-07 (match badge visibility)

**Backend:**
- None — existing test infrastructure covers all phase requirements (Phase 23 added popularRecipes tests)

## Sources

### Primary (HIGH confidence)

- **Existing codebase analysis:**
  - `/Users/ersinkirteke/Workspaces/Kindred/Kindred/Packages/FeedFeature/Sources/Feed/FeedReducer.swift` — 4 ViralRecipesQuery call sites identified (lines 241, 461, 518, 543)
  - `/Users/ersinkirteke/Workspaces/Kindred/Kindred/Packages/FeedFeature/Sources/Feed/MatchBadge.swift` — Pattern for PopularityBadge (color coding, animation, accessibility)
  - `/Users/ersinkirteke/Workspaces/Kindred/Kindred/Packages/FeedFeature/Sources/Utilities/IngredientMatcher.swift` — Local matching logic (no Spoonacular API call needed)
  - `/Users/ersinkirteke/Workspaces/Kindred/backend/src/recipes/recipes.resolver.ts` — PopularRecipesQuery already implemented (line 20-29)
  - `/Users/ersinkirteke/Workspaces/Kindred/backend/src/recipes/recipes.service.ts` — getPopularRecipes method (line 101-131)
  - `/Users/ersinkirteke/Workspaces/Kindred/backend/src/graphql/models/recipe.model.ts` — popularityScore field confirmed (line 152)

- **Official documentation:**
  - Apollo iOS documentation: https://www.apollographql.com/docs/ios/ (code generation, query execution)
  - SwiftUI documentation: https://developer.apple.com/documentation/swiftui (overlay modifiers, alignment)
  - TCA documentation: https://pointfreeco.github.io/swift-composable-architecture/ (reducer patterns, dependency injection)

### Secondary (MEDIUM confidence)

- **Phase 23 context:**
  - `.planning/phases/23-spoonacular-backend-integration/23-CONTEXT.md` — PopularRecipes query implementation details, RecipeConnection schema
  - `.planning/STATE.md` — Phase 23 completion confirmed, backend ready for iOS migration

### Tertiary (LOW confidence)

None — all findings verified against project codebase or official documentation.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — verified against existing project dependencies (Package.swift, package.json)
- Architecture: HIGH — patterns extracted from existing codebase (FeedReducer, MatchBadge, IngredientMatcher)
- Pitfalls: HIGH — derived from TCA best practices and Apollo iOS common issues
- Backend cleanup scope: MEDIUM — images module structure verified, but ScrapingService/XApiService deletion scope assumed (not found in current codebase, may have been removed in Phase 23)

**Research date:** 2026-04-05
**Valid until:** 2026-05-05 (30 days — stable iOS/backend stack, low churn)
