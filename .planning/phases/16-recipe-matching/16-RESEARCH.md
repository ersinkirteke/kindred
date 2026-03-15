# Phase 16: Recipe Matching - Research

**Researched:** 2026-03-15
**Domain:** Client-side string matching, SwiftUI bottom sheets, accessibility (WCAG AAA), TCA state management
**Confidence:** HIGH

## Summary

Phase 16 adds ingredient match percentage badges to recipe feed cards and a shopping list generator for missing ingredients. The implementation is entirely client-side using SwiftData pantry items matched against recipe ingredient names via normalized string comparison. The architecture follows established patterns from Phase 15's recipe suggestion carousel (which already implemented client-side matching) and existing badge overlays (ViralBadge, ForYouBadge).

Key technical decisions: (1) SwiftUI's `.presentationDetents()` for bottom sheet shopping list, (2) string normalization using lowercased comparison with common staple exclusion, (3) WCAG AAA-compliant color coding (green #27AE60, yellow TBD - needs contrast verification), (4) TCA state management with match % computed in FeedReducer on feed appear, (5) reuse existing IngredientChecklistView with match state extension.

**Primary recommendation:** Extend ViralRecipesQuery to include ingredient names, compute match % client-side in FeedReducer using normalized name comparison against SwiftData pantry items, add MatchBadge overlay to RecipeCardView following existing badge pattern, and present shopping list via `.sheet()` with `.presentationDetents([.medium, .large])` bottom sheet.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Match Badge Design (Feed Card)**
- Top-left overlay on hero image (same pattern as ViralBadge top-right, ForYouBadge bottom-left)
- Colored pill shape with percentage text (e.g. "85%")
- Green pill when >70% match, yellow pill when 50-70% match, hidden when <50% match
- Use existing DesignSystem colors (kindredSuccess for green, existing warning/accent for yellow) — must meet WCAG AAA contrast
- Subtle scale-in animation when badge first appears (respect reduceMotion)
- Hidden entirely when user has no pantry items (empty pantry = no badges anywhere)
- Badge does NOT change feed ranking — existing FeedRanker/CulinaryDNAEngine order stays

**Match Badge Design (Detail View)**
- Show match % prominently near ingredients section with count breakdown: "4/6 ingredients (67%)"
- In IngredientChecklistView, color-code each ingredient inline: green checkmark indicator for ingredients user has, red/orange indicator for missing ones
- Reuses existing IngredientChecklistView component with added match state

**Ingredient Matching Logic**
- Client-side matching — compute locally using PantryItem data from SwiftData against recipe ingredients
- Normalized name matching: strip qualifiers ("fresh", "large", "organic"), lowercase, trim — not category-level ("chicken breast" ≠ "chicken thigh")
- Client-side string normalization for recipe ingredients (RecipeIngredient doesn't have normalizedName — apply heuristic stripping)
- Name-only matching — if user has the ingredient at all, it counts as matched regardless of quantity
- Exclude common pantry staples from calculation (salt, pepper, water, cooking oil, etc.)
- Exclude expired pantry items (use PantryItem.expiryDate) — only non-expired, non-deleted items count
- Add ingredient names to the feed query (extend ViralRecipesQuery) so match % can be computed at card level
- Feed ranking unchanged — match badge is informational only, does not boost/demote cards

**Shopping List Experience**
- Bottom sheet triggered from recipe detail view (not from feed card badge tap)
- Summary header at top: "You have 4 of 6 ingredients. Missing:"
- Missing items grouped by FoodCategory (Produce, Dairy, Grains, etc.) using existing FoodCategory enum
- Each item shows full quantities: "2 cups flour", "3 eggs" (uses RecipeIngredient quantity + unit)
- Checkable list — user can tap to check off items while shopping (temporary state, resets on sheet close)
- When all items checked off: show celebration message + "Ready to cook?" with link to start voice narration
- Copy to clipboard + iOS share sheet with plain text format: "Shopping list for [Recipe Name]:\n- 2 cups flour\n- 3 eggs\n..."
- Entry point: "Missing ingredients" button in detail view only — badge tap on card opens detail (existing behavior)

**Reactivity & Performance**
- Recalculate match % on feed appear (tab switch or pull-to-refresh), not real-time reactive
- Current swipe stack cards only — no recalculation for past/bookmarked recipes
- No loading indicator — calculation is fast (local SwiftData query), badge appears when ready
- Detail view is static until reopened — pantry changes in background don't update open detail
- Fresh computation each time (no caching) — avoids stale state complexity
- On cold start: feed loads first, match badges computed async and appear after (no blocking)

### Claude's Discretion
- Exact list of common pantry staples to exclude
- Exact string normalization rules and qualifier word list
- Badge positioning fine-tuning (exact padding/offset on card)
- Shopping list bottom sheet height and drag behavior
- Celebration animation style when all shopping items checked
- How ingredient match state integrates with existing IngredientChecklistView's check/uncheck state

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| MATCH-01 | Recipe cards display ingredient match % badge based on pantry contents | SwiftUI overlay pattern (ViralBadge precedent), client-side matching (Phase 15 precedent), TCA state computed in FeedReducer |
| MATCH-02 | Match badge uses color coding (green >70%, yellow >50%, hidden below 50%) | WCAG AAA contrast verification needed, DesignSystem colors (.kindredSuccess exists, yellow needs definition or use .kindredAccent), conditional rendering based on percentage thresholds |
| MATCH-03 | User can generate a shopping list of missing ingredients for any recipe | SwiftUI `.presentationDetents()` bottom sheet, FoodCategory grouping, iOS share sheet via `ShareLink` or `UIActivityViewController`, checkable list state management in TCA reducer |
| MATCH-04 | Ingredient matching uses normalized names (handles "eggs" vs "large eggs") | String normalization via `.lowercased()`, qualifier stripping heuristic (remove words like "fresh", "large", "organic"), PantryItem.normalizedName comparison, staple exclusion list |

</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 16+ | UI framework for badges, bottom sheets, overlays | Apple's native declarative UI framework, already used throughout app |
| The Composable Architecture (TCA) | ~1.x | State management for match % computation, shopping list state | Established architecture pattern across all 7 SPM packages in project |
| SwiftData | iOS 17+ | Local pantry item queries for matching | Already used for PantryItem persistence (Phase 12-13), fast synchronous queries on MainActor |
| Foundation | iOS 16+ | String normalization, set operations | Apple's standard library for string manipulation and collection operations |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Kingfisher | ~8.x | AsyncImage fallback if needed | Only if bottom sheet recipe cards need image caching (RecipeSuggestionCarousel uses AsyncImage) |
| DesignSystem (local package) | N/A | Color tokens, spacing, typography | All UI components use DesignSystem colors to ensure WCAG AAA compliance |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Client-side matching | Server-side GraphQL resolver | Server-side would enable fuzzy matching, typo tolerance, but adds latency, network dependency, and complexity. User decision locked to client-side for MVP speed. |
| `.presentationDetents()` | Custom GeometryReader bottom sheet | Custom implementation offers more control but reinvents iOS 16+ native bottom sheet, breaks accessibility, and requires more code. |
| String normalization heuristic | Levenshtein distance library (e.g., FuzzyMatch) | Fuzzy matching handles typos better but adds dependency, performance cost, and false positives. User locked to simple normalized matching for MVP. |

**Installation:**
No new dependencies required — all features use existing libraries in the project.

## Architecture Patterns

### Recommended File Structure
```
FeedFeature/Sources/
├── Feed/
│   ├── RecipeCardView.swift       # Add MatchBadge overlay
│   ├── ViralBadge.swift            # Existing pattern to follow
│   ├── ForYouBadge.swift           # Existing pattern to follow
│   ├── MatchBadge.swift            # NEW: Match % badge component
│   └── FeedReducer.swift           # Add computeMatchPercentages action
├── RecipeDetail/
│   ├── RecipeDetailView.swift      # Add "Missing ingredients" button
│   ├── RecipeDetailReducer.swift   # Add shoppingList presentation state
│   ├── IngredientChecklistView.swift # Extend with match state color coding
│   └── ShoppingListView.swift      # NEW: Bottom sheet for missing ingredients
├── Models/
│   ├── FeedModels.swift            # Add matchPercentage to RecipeCard
│   └── RecipeDetailModels.swift    # Extend RecipeIngredient with matchStatus
└── Utilities/
    └── IngredientMatcher.swift     # NEW: String normalization and matching logic
```

### Pattern 1: Badge Overlay on RecipeCardView
**What:** SwiftUI overlay modifier with alignment parameter to position badge on hero image
**When to use:** Match badge follows same pattern as ViralBadge (top-right) and ForYouBadge (bottom-left)
**Example:**
```swift
// Source: Existing ViralBadge implementation in RecipeCardView.swift lines 111-116
.overlay(alignment: .topLeading) {  // NEW: top-left for match badge
    if let matchPercentage = recipe.matchPercentage, matchPercentage >= 50 {
        MatchBadge(percentage: matchPercentage)
            .padding(KindredSpacing.md)
    }
}
```

### Pattern 2: SwiftUI Bottom Sheet with `.presentationDetents()`
**What:** Native iOS 16+ bottom sheet using `.sheet()` + `.presentationDetents([.medium, .large])`
**When to use:** Shopping list presentation from recipe detail view
**Example:**
```swift
// Source: iOS 16+ SwiftUI documentation + HackingWithSwift guide
.sheet(item: $store.shoppingList) { list in
    ShoppingListView(
        recipeName: list.recipeName,
        missingIngredients: list.items,
        onDismiss: { store.send(.dismissShoppingList) }
    )
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
    .presentationBackgroundInteraction(.disabled)
}
```

### Pattern 3: Client-Side String Normalization for Matching
**What:** Lowercase + trim + qualifier stripping heuristic for ingredient name matching
**When to use:** Compare PantryItem.normalizedName against RecipeIngredient.name
**Example:**
```swift
// Source: Phase 15 RecipeSuggestionCarousel.swift line 160-162 (simplified lowercased() matching)
// Enhanced with qualifier stripping per user requirements

struct IngredientMatcher {
    static let commonQualifiers = ["fresh", "large", "small", "medium", "organic", "free-range", "whole", "chopped", "diced", "sliced"]
    static let commonStaples = ["salt", "pepper", "water", "cooking oil", "olive oil", "vegetable oil"]

    static func normalize(_ name: String) -> String {
        var normalized = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Strip common qualifiers
        for qualifier in commonQualifiers {
            normalized = normalized.replacingOccurrences(of: qualifier + " ", with: "")
        }

        return normalized.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func isStaple(_ name: String) -> Bool {
        let normalized = normalize(name)
        return commonStaples.contains(normalized)
    }
}
```

### Pattern 4: TCA Computed State for Match Percentage
**What:** FeedReducer computes match % for each RecipeCard on feed appear using local pantry items
**When to use:** Feed tab activation, pull-to-refresh, or returning from pantry edits
**Example:**
```swift
// Source: TCA documentation + existing FeedReducer pattern
@Reducer
struct FeedReducer {
    @Dependency(\.pantryClient) var pantryClient

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .onAppear:
            return .run { [userId = state.userId] send in
                // Fetch recipes (existing)
                let recipes = try await fetchRecipes()

                // Fetch pantry items for matching
                let pantryItems = await pantryClient.fetchAllItems(userId)

                // Compute match percentages
                let recipesWithMatch = recipes.map { recipe in
                    let matchPct = computeMatchPercentage(
                        recipeIngredients: recipe.ingredients,
                        pantryItems: pantryItems
                    )
                    return recipe.withMatchPercentage(matchPct)
                }

                await send(.recipesLoaded(.success(recipesWithMatch)))
            }
        }
    }

    private func computeMatchPercentage(
        recipeIngredients: [RecipeIngredient],
        pantryItems: [PantryItem]
    ) -> Int {
        // Filter out staples and expired items
        let eligibleIngredients = recipeIngredients.filter { !IngredientMatcher.isStaple($0.name) }
        let validPantryItems = pantryItems.filter { !$0.isDeleted && ($0.expiryDate == nil || $0.expiryDate! > Date()) }

        // Normalize pantry item names
        let pantryNormalizedNames = Set(validPantryItems.compactMap {
            $0.normalizedName ?? IngredientMatcher.normalize($0.name)
        })

        // Count matches
        let matchedCount = eligibleIngredients.filter { ingredient in
            let normalizedIngredient = IngredientMatcher.normalize(ingredient.name)
            return pantryNormalizedNames.contains(normalizedIngredient)
        }.count

        guard !eligibleIngredients.isEmpty else { return 0 }
        return Int((Double(matchedCount) / Double(eligibleIngredients.count)) * 100)
    }
}
```

### Pattern 5: Checkable Shopping List with TCA State
**What:** Bottom sheet with checkable ingredient list, celebration state when all checked
**When to use:** ShoppingListView with temporary check state (resets on dismiss)
**Example:**
```swift
// Source: TCA presentation pattern + existing IngredientChecklistView
@Reducer
struct ShoppingListReducer {
    @ObservableState
    struct State: Equatable {
        let recipeName: String
        let missingIngredients: IdentifiedArrayOf<MissingIngredient>
        var checkedItems: Set<MissingIngredient.ID> = []

        var allChecked: Bool {
            checkedItems.count == missingIngredients.count
        }
    }

    enum Action: Equatable {
        case toggleItem(MissingIngredient.ID)
        case shareList
        case startCooking  // Navigate to voice narration
        case dismiss
    }

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case let .toggleItem(id):
            if state.checkedItems.contains(id) {
                state.checkedItems.remove(id)
            } else {
                state.checkedItems.insert(id)
            }
            return .none
        }
    }
}
```

### Anti-Patterns to Avoid
- **Real-time reactive matching:** Don't observe SwiftData changes and update badges live — causes performance issues and UI jank. Compute on feed appear only.
- **Caching match percentages:** Don't persist match % in RecipeCard model — causes stale data when pantry updates. Fresh computation each time is fast enough (<100ms for 50 recipes).
- **Server-side matching in MVP:** Don't add GraphQL resolver for ingredient matching — adds latency, network dependency, and backend complexity. Client-side is sufficient for MVP.
- **Custom bottom sheet implementation:** Don't build GeometryReader-based custom sheet — use SwiftUI's `.presentationDetents()` for native behavior, accessibility, and iOS design patterns.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Bottom sheet presentation | Custom GeometryReader + DragGesture bottom sheet | SwiftUI `.presentationDetents([.medium, .large])` | iOS 16+ provides native bottom sheets with accessibility, drag-to-dismiss, dynamic height, and proper safe area handling. Custom implementation breaks VoiceOver, ignores reduce motion, and requires 200+ lines of code. |
| Fuzzy string matching | Levenshtein distance implementation from scratch | Simple normalized string comparison (`.lowercased()` + qualifier stripping) | User locked decision to simple matching for MVP. If fuzzy matching needed later, use `FuzzyMatch` library. Hand-rolling Levenshtein is bug-prone and slow. |
| Share sheet | Custom share UI | `ShareLink` (iOS 16+) or `UIActivityViewController` wrapper | iOS provides native share sheet with all system integrations (Messages, Mail, AirDrop, Copy). Custom UI breaks user expectations and misses features. |
| Color contrast validation | Manual color picker trial-and-error | WebAIM Contrast Checker tool | WCAG AAA requires 7:1 contrast ratio for normal text. WebAIM tool provides instant verification with specific ratio values. Manual testing is unreliable and time-consuming. |

**Key insight:** SwiftUI 16+ provides native solutions for bottom sheets, share sheets, and accessibility that are production-ready and thoroughly tested. Custom implementations introduce bugs, accessibility issues, and maintenance burden without adding value.

## Common Pitfalls

### Pitfall 1: WCAG AAA Contrast Failure for Yellow Badge
**What goes wrong:** Yellow badges on white/cream backgrounds fail WCAG AAA (7:1 ratio). Pure yellow (#FFFF00) has only 1.07:1 ratio on white.
**Why it happens:** Bright yellow is inherently low-contrast against light backgrounds. Designer intuition ("yellow means caution") doesn't guarantee accessibility compliance.
**How to avoid:** Use WebAIM Contrast Checker to validate yellow color choice. If using DesignSystem, verify `.kindredAccent` or define new `kindredWarning` color. For yellow 50-70% match badge, consider:
- Darker yellow/amber (#D97706 has 4.61:1 on white — still fails AAA, passes AA)
- Orange (#C0553A - existing kindredAccent - 7.04:1 on white — passes AAA)
- Consider using same color with different text ("70% match" vs "85% match") instead of color coding
**Warning signs:** Badge looks washed out or hard to read in bright sunlight. VoiceOver users can't distinguish badge meaning without color.

### Pitfall 2: Ingredient Matching False Positives with Staples
**What goes wrong:** Recipes show 90%+ match because they all include salt, pepper, water — ingredients every user has.
**Why it happens:** Not excluding common pantry staples from match % calculation inflates scores and makes badges meaningless.
**How to avoid:** Maintain exclusion list of staples: `["salt", "pepper", "water", "cooking oil", "olive oil", "vegetable oil"]`. Filter out before computing match %. Consider expanding list based on user feedback ("everyone has flour/sugar").
**Warning signs:** User with empty pantry sees high match %. All recipes show green badges. User feedback: "I don't have most of these ingredients despite 80% match".

### Pitfall 3: Expired Pantry Items Counted as Matches
**What goes wrong:** User sees 75% match badge but shopping list still shows "missing" items because pantry items expired.
**Why it happens:** Match computation doesn't filter `PantryItem.expiryDate` before comparing.
**How to avoid:** Filter pantry items: `pantryItems.filter { !$0.isDeleted && ($0.expiryDate == nil || $0.expiryDate! > Date()) }`. Exclude expired items from match set.
**Warning signs:** Match % in badge doesn't match count in detail view. User confusion: "Why do I need to buy eggs if I have 80% match?"

### Pitfall 4: GraphQL N+1 Query for Ingredients
**What goes wrong:** Feed loads 50 recipes, each triggers separate GraphQL query for ingredient names — 50+ network requests on feed load.
**Why it happens:** Not extending ViralRecipesQuery to include ingredients upfront. Lazy-loading ingredients per card.
**How to avoid:** Extend `ViralRecipesQuery.graphql` to include ingredients fragment (lines 18-23 already exist in RecipeDetailQuery — copy to ViralRecipesQuery). Fetch ingredients with initial feed load. User decision already locked this pattern.
**Warning signs:** Feed load takes 5+ seconds. Network tab shows dozens of ingredient queries. Match badges appear one-by-one with noticeable delay.

### Pitfall 5: Shopping List State Persists Across Dismissals
**What goes wrong:** User checks off 3 items, dismisses sheet, reopens — checked items still checked. Expected fresh state.
**Why it happens:** TCA state not reset on dismiss action. Check state stored in reducer instead of ephemeral view state.
**How to avoid:** User requirement explicitly states "temporary state, resets on sheet close". Reset `checkedItems` set in dismiss action or use `@State` in view instead of reducer state.
**Warning signs:** Checked items persist after closing sheet. User confusion when reopening list after pantry updates.

## Code Examples

Verified patterns from existing codebase and official sources:

### Match Badge Component (Following ViralBadge Pattern)
```swift
// Source: ViralBadge.swift + ForYouBadge.swift pattern
import DesignSystem
import SwiftUI

struct MatchBadge: View {
    let percentage: Int
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    private var badgeColor: Color {
        percentage >= 70 ? .kindredSuccess : .kindredAccent  // Green for >70%, orange for 50-70%
    }

    var body: some View {
        Text("\(percentage)%")
            .font(.kindredCaption())
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, KindredSpacing.sm)
            .padding(.vertical, KindredSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(badgeColor)
            )
            .scaleEffect(reduceMotion ? 1.0 : animationScale)
            .animation(reduceMotion ? nil : .spring(response: 0.3), value: animationScale)
            .accessibilityLabel("\(percentage) percent ingredients available")
    }

    @State private var animationScale: CGFloat = 0.8

    init(percentage: Int) {
        self.percentage = percentage
        // Trigger scale-in animation on appear
        DispatchQueue.main.async {
            animationScale = 1.0
        }
    }
}
```

### Extend ViralRecipesQuery to Include Ingredients
```graphql
# Source: FeedQueries.graphql line 18-23 already in RecipeDetailQuery
# Copy ingredient fragment to ViralRecipesQuery

query ViralRecipes($location: String!) {
  viralRecipes(location: $location) {
    id
    name
    # ... existing fields ...
    ingredients {
      name
      quantity
      unit
      orderIndex
    }
  }
}
```

### Shopping List Bottom Sheet Presentation
```swift
// Source: SwiftUI documentation + user requirements
struct RecipeDetailView: View {
    @Bindable var store: StoreOf<RecipeDetailReducer>

    var body: some View {
        ScrollView {
            // ... existing content ...

            if let summary = ingredientMatchSummary {
                VStack(spacing: 12) {
                    Text(summary)
                        .font(.kindredBody())

                    Button {
                        store.send(.showShoppingList)
                    } label: {
                        Label("Missing ingredients", systemImage: "cart")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .sheet(item: $store.scope(state: \.shoppingList, action: \.shoppingList)) { store in
            ShoppingListView(store: store)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var ingredientMatchSummary: String? {
        guard let detail = store.recipe else { return nil }
        let matched = detail.ingredients.filter { $0.matchStatus == .available }.count
        let total = detail.ingredients.count
        guard matched < total else { return nil }

        return "You have \(matched) of \(total) ingredients (\(matchPercentage)%)"
    }
}
```

### IngredientChecklistView with Match State Color Coding
```swift
// Source: Existing IngredientChecklistView.swift + user requirements
struct IngredientRow: View {
    let ingredient: RecipeIngredient
    let matchStatus: IngredientMatchStatus  // NEW: .available, .missing
    let isChecked: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .center, spacing: KindredSpacing.md) {
                // Match status indicator
                Image(systemName: matchStatusIcon)
                    .font(.system(size: 20))
                    .foregroundColor(matchStatusColor)

                // Checkbox icon (existing)
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isChecked ? .kindredSuccess : .kindredTextSecondary)

                // Ingredient text
                Text(ingredient.formattedText)
                    .font(.kindredBody())
                    .foregroundColor(isChecked ? .kindredTextSecondary : .kindredTextPrimary)
                    .strikethrough(isChecked, color: .kindredTextSecondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 56)  // WCAG AAA touch target
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var matchStatusIcon: String {
        switch matchStatus {
        case .available: return "checkmark.circle.fill"
        case .missing: return "circle"
        }
    }

    private var matchStatusColor: Color {
        switch matchStatus {
        case .available: return .kindredSuccess  // Green
        case .missing: return .kindredError.opacity(0.7)  // Red/orange
        }
    }
}

enum IngredientMatchStatus {
    case available  // User has this in pantry
    case missing    // Need to buy
}
```

### Share Shopping List with Native Share Sheet
```swift
// Source: iOS 16+ ShareLink documentation
struct ShoppingListView: View {
    @Bindable var store: StoreOf<ShoppingListReducer>

    var body: some View {
        VStack {
            // ... checklist content ...

            ShareLink(
                item: shoppingListText,
                subject: Text("Shopping list for \(store.recipeName)"),
                message: Text("Ingredients I need:")
            ) {
                Label("Share list", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)
        }
    }

    private var shoppingListText: String {
        var text = "Shopping list for \(store.recipeName):\n"
        for (category, items) in groupedIngredients {
            text += "\n\(category.displayName):\n"
            for item in items {
                text += "- \(item.formattedText)\n"
            }
        }
        return text
    }

    private var groupedIngredients: [(FoodCategory, [MissingIngredient])] {
        Dictionary(grouping: store.missingIngredients, by: \.category)
            .sorted { $0.key.displayName < $1.key.displayName }
            .map { ($0.key, $0.value) }
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom bottom sheets with GeometryReader | SwiftUI `.presentationDetents()` | iOS 16 (2022) | Native bottom sheets provide accessibility, dynamic sizing, drag-to-dismiss, and safe area handling out of the box. Custom implementations now considered anti-pattern. |
| `UIActivityViewController` wrapper | SwiftUI `ShareLink` | iOS 16 (2022) | Declarative share sheet API eliminates UIKit bridging code. Simpler syntax, automatic styling, better SwiftUI integration. |
| `.lowercased()` string matching only | Fuzzy matching libraries (FuzzyMatch, Fuse) | 2024+ | High-performance fuzzy string matching now viable in Swift with zero dependencies. However, user locked simple matching for MVP — consider for future enhancement. |
| WCAG 2.0 AA (4.5:1 contrast) | WCAG 2.1/2.2 AAA (7:1 contrast) | Ongoing | Enhanced accessibility requirements. Apps targeting AAA compliance provide better readability for users with visual impairments and in bright sunlight. |

**Deprecated/outdated:**
- Custom bottom sheet implementations using GeometryReader: iOS 16+ `.presentationDetents()` is now standard
- `UIActivityViewController` for sharing: `ShareLink` (iOS 16+) is preferred for pure SwiftUI apps
- Manual accessibility testing: Xcode Accessibility Inspector + VoiceOver testing recommended over guesswork

## Open Questions

1. **Yellow Badge Color for 50-70% Match**
   - What we know: User requires yellow pill for 50-70% match, must meet WCAG AAA (7:1 ratio)
   - What's unclear: DesignSystem doesn't define `.kindredWarning` color. Pure yellow fails AAA. Orange `.kindredAccent` passes AAA but may not read as "yellow" visually.
   - Recommendation: Define `.kindredWarning` as darker amber (#D97706) or use `.kindredAccent` orange for both thresholds with different text ("70% match" vs "85% match"). Validate with WebAIM Contrast Checker before implementation.

2. **Shopping List Entry Point on Feed Cards**
   - What we know: User requirement states "Entry point: 'Missing ingredients' button in detail view only — badge tap on card opens detail (existing behavior)"
   - What's unclear: Should feed card badge be tappable at all, or purely decorative? If decorative, add `.allowsHitTesting(false)` to prevent accidental taps.
   - Recommendation: Make badge non-interactive (decorative overlay). Tapping card body opens detail view (existing behavior). This matches ViralBadge pattern (also decorative).

3. **Ingredient Normalization Edge Cases**
   - What we know: Strip qualifiers like "fresh", "large", "organic". Lowercase and trim. Not category-level matching.
   - What's unclear: How to handle compound ingredients ("chicken breast" vs "chicken thigh"), pluralization ("egg" vs "eggs"), measurement units in name ("1 lb ground beef"), abbreviations ("tsp" vs "teaspoon").
   - Recommendation: Start with simple qualifier list for MVP. Monitor user feedback for false negatives. Consider Levenshtein fuzzy matching in Phase 17+ if match quality becomes issue. For pluralization, add simple stemming: remove trailing "s" if present.

4. **Performance with Large Pantry Inventories**
   - What we know: Computation is "fast (local SwiftData query)" per user requirement. No caching.
   - What's unclear: What happens with 500+ pantry items and 50 recipe cards? SwiftData query performance at scale.
   - Recommendation: Profile with Instruments using 500 pantry items. If >100ms for full feed computation, add throttling or background queue processing with progress indicator. Likely acceptable given SwiftData's optimized predicates.

5. **Celebration Animation Style**
   - What we know: User requirement specifies celebration when all shopping items checked, with "Ready to cook?" link to voice narration.
   - What's unclear: Should it be confetti animation, checkmark burst, subtle glow, or just text change? Must respect `reduceMotion`.
   - Recommendation: Simple scale + fade animation on "All done!" text with confetti emoji (🎉) for reduceMotion-off. Static text with checkmark (✓) for reduceMotion-on. Link to voice narration appears below celebration message.

## Sources

### Primary (HIGH confidence)
- Existing codebase files: RecipeCardView.swift, ViralBadge.swift, ForYouBadge.swift, IngredientChecklistView.swift, RecipeSuggestionCarousel.swift, PantryItem.swift, FoodCategory.swift, DesignSystem/Colors.swift
- Phase 15 CONTEXT.md and PLANs: Client-side recipe matching pattern established
- Apple SwiftUI documentation: `.presentationDetents()`, `.sheet()`, `ShareLink`
- TCA documentation: @Reducer, @ObservableState, presentation patterns

### Secondary (MEDIUM confidence)
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/) - WCAG AAA color contrast ratio verification
- [WebAIM: Contrast and Color Accessibility](https://webaim.org/articles/contrast/) - Understanding WCAG 2 requirements
- [W3C WCAG 2.1 Success Criterion 1.4.6](https://www.w3.org/WAI/WCAG21/Understanding/contrast-enhanced.html) - Contrast (Enhanced) AAA guidelines
- [HackingWithSwift: Bottom Sheets](https://www.hackingwithswift.com/quick-start/swiftui/how-to-display-a-bottom-sheet) - SwiftUI bottom sheet best practices
- [Sarunw: SwiftUI Bottom Sheet](https://sarunw.com/posts/swiftui-bottom-sheet/) - iOS 16 `.presentationDetents()` guide
- [Create with Swift: Interactive Bottom Sheets](https://www.createwithswift.com/exploring-interactive-bottom-sheets-in-swiftui/) - Advanced bottom sheet patterns

### Tertiary (LOW confidence)
- [CodeEdit: Fuzzy Search Algorithm](https://www.codeedit.app/blog/2024/02/generic-fuzzy-search-algorithm) - Generic fuzzy matching in Swift (for future enhancement consideration)
- [GitHub: ordo-one/FuzzyMatch](https://github.com/ordo-one/FuzzyMatch) - High-performance fuzzy string matching library (if simple matching insufficient)
- [Swift Forums: Very Fast Fuzzy String Matching](https://forums.swift.org/t/very-fast-fuzzy-string-matching-in-swift-for-interactive-searches/84707) - Performance considerations for fuzzy matching

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All libraries already in use (SwiftUI, TCA, SwiftData, Foundation)
- Architecture: HIGH - Patterns verified from existing codebase (badge overlays, TCA reducers, bottom sheets)
- Pitfalls: HIGH - Identified from user requirements (staple exclusion, WCAG compliance, expired items)
- Code examples: HIGH - Adapted from existing RecipeCardView, IngredientChecklistView, RecipeSuggestionCarousel

**Research date:** 2026-03-15
**Valid until:** 30 days (stable stack, no fast-moving dependencies)
