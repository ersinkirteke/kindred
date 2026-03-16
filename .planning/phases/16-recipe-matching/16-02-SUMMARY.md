---
phase: 16-recipe-matching
plan: 02
subsystem: recipe-matching-detail
tags: [recipe-detail, shopping-list, ingredient-matching, ui, tca]
dependency_graph:
  requires: [16-01-ingredient-matcher, pantry-feature, recipe-detail]
  provides: [ingredient-match-state, shopping-list-sheet, match-summary-ui]
  affects: [recipe-detail-view, ingredient-checklist-view]
tech_stack:
  added: []
  patterns: [tca-child-reducer, presentation-action, computed-properties, category-grouping-heuristic]
key_files:
  created:
    - Kindred/Packages/FeedFeature/Sources/RecipeDetail/ShoppingListReducer.swift
    - Kindred/Packages/FeedFeature/Sources/RecipeDetail/ShoppingListView.swift
    - Kindred/Packages/FeedFeature/Sources/RecipeDetail/RecipeDetailModels.swift
  modified:
    - Kindred/Packages/FeedFeature/Sources/RecipeDetail/RecipeDetailReducer.swift
    - Kindred/Packages/FeedFeature/Sources/RecipeDetail/RecipeDetailView.swift
    - Kindred/Packages/FeedFeature/Sources/RecipeDetail/IngredientChecklistView.swift
    - Kindred/Sources/Resources/Localizable.xcstrings
decisions:
  - Client-side ingredient matching in detail view reuses IngredientMatcher from Plan 01 for consistency
  - Simple keyword-to-FoodCategory heuristic for shopping list grouping avoids server dependency for MVP
  - ShareLink native iOS sharing (iOS 16+) provides system-wide share sheet integration
  - Celebration state with reduceMotion respect ensures accessible feedback for task completion
  - Checkable shopping list state is temporary (resets on dismiss) — no persistence overhead
  - @Presents pattern for shopping list child reducer maintains clean parent-child separation
metrics:
  duration_minutes: 8
  tasks_completed: 3
  files_created: 3
  files_modified: 4
  commits: 3
  completed_at: "2026-03-16T21:00:00Z"
---

# Phase 16 Plan 02: Detail View Match State and Shopping List Summary

**One-liner:** Ingredient match state in recipe detail with grouped shopping list bottom sheet and native share

## Overview

Extended RecipeDetailReducer with per-ingredient match computation (available/missing/staple), created ShoppingListReducer with checkable grouped list, and integrated match summary UI with native iOS share capabilities.

## What Was Built

### Task 1: Ingredient Match State in RecipeDetailReducer

**Files Modified:**
- `RecipeDetailReducer.swift` — Added pantryClient dependency, match computation logic, shopping list @Presents child state
- `RecipeDetailModels.swift` — Created IngredientMatchStatus enum (available/missing/staple)
- `RecipeDetailView.swift` — Added match summary text, "Missing ingredients" button, shopping list sheet presentation
- `IngredientChecklistView.swift` — Extended with match status indicators (green leaf for available, orange cart for missing)

**Key Implementation:**
- Match computation triggered on recipe load via `.computeIngredientMatch` action
- Fetches pantry items, filters expired/deleted, normalizes names via IngredientMatcher
- Per-ingredient status stored in `ingredientMatchStatuses` dictionary keyed by ingredient.id
- Computes `matchedCount`, `eligibleCount` (excludes staples), and `matchPercentage`
- Match summary shows "You have X of Y ingredients (Z%)" above ingredient list
- Color-coded indicators: green `leaf.circle.fill` for available, orange `cart.circle` for missing
- "Missing ingredients" button triggers shopping list presentation

**Commits:**
- cb89d7e: feat(16-02): add ingredient match state to recipe detail view
- adc030b: fix(16-02): fix ClerkUser type mismatch and missing font method

### Task 2: Shopping List Bottom Sheet

**Files Created:**
- `ShoppingListReducer.swift` — State management for checkable shopping list with celebration
- `ShoppingListView.swift` — Grouped list UI with share, copy, celebration

**Files Modified:**
- `Localizable.xcstrings` — Added English + Turkish shopping list strings

**Key Implementation:**
- ShoppingListReducer manages `checkedItems` Set, provides `allChecked` computed property
- Category grouping uses keyword-to-FoodCategory heuristic (e.g., "milk"→dairy, "chicken"→meat)
- Items grouped by FoodCategory, "Other" for unmatched
- Each row: checkbox, quantity+name formattedText, strikethrough when checked
- Celebration section appears when `allChecked == true` with "All done!" message
- ShareLink provides native iOS sharing with formatted text output
- Copy to clipboard button with "Copied!" feedback state
- Bottom sheet uses `.presentationDetents([.medium, .large])` for native iOS feel
- Full VoiceOver and Dynamic Type accessibility support

**Commits:**
- 6a1ffdc: feat(16-02): create shopping list bottom sheet with grouping and share

### Task 3: Device Verification (Human Checkpoint)

**Status:** Approved

**Verification Scope:**
- Feed card badges (Plan 01 integration check)
- Detail view match state with green/orange indicators
- Shopping list bottom sheet with grouping and check/uncheck
- Share and copy functionality
- Celebration state when all items checked
- VoiceOver and Dynamic Type accessibility

**User Feedback:** All flows verified working correctly on physical device (iPhone 16 Pro Max)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] ClerkUser type mismatch in auth state check**
- **Found during:** Task 1 — RecipeDetailReducer match computation
- **Issue:** Auth state check pattern didn't match actual ClerkUser type structure
- **Fix:** Updated auth state check to use correct Clerk SDK pattern for userId access
- **Files modified:** RecipeDetailReducer.swift
- **Commit:** adc030b

**2. [Rule 1 - Bug] Missing font scaling method in match summary**
- **Found during:** Task 1 — RecipeDetailView match summary text
- **Issue:** Font scaling method reference didn't match available DesignSystem API
- **Fix:** Updated to use correct KindredFont scaled font method
- **Files modified:** RecipeDetailView.swift
- **Commit:** adc030b

## Technical Highlights

**TCA Child Reducer Pattern:**
- Shopping list integrated as `@Presents` child state in RecipeDetailReducer
- `.ifLet(\.$shoppingList, action: \.shoppingList)` composition
- PresentationAction for dismiss handling

**Computed Properties for UX:**
- `allChecked` computed property triggers celebration state
- `matchPercentage` computed from eligible ingredient count (excludes staples)

**Category Grouping Heuristic:**
- Static keyword dictionary maps common ingredients to FoodCategory
- Fallback to "Other" category for unknown items
- Client-side only — no server dependency for MVP

**Accessibility:**
- VoiceOver labels: "in pantry" for available, "need to buy" for missing
- 56pt minimum touch targets (WCAG AAA)
- Dynamic Type support with scaled metrics
- reduceMotion respect for celebration animation

## Integration Points

**Upstream Dependencies:**
- IngredientMatcher from Plan 01 (normalize, isStaple, computeMatchPercentage)
- PantryClient.fetchAllItems for pantry data
- PantryItem model with normalizedName, foodCategory, expiryDate
- FoodCategory enum from PantryFeature

**Downstream Impact:**
- Recipe detail view now provides full ingredient matching flow
- Shopping list completes action-oriented recipe matching experience
- Phase 16 recipe matching feature complete (feed badges + detail state + shopping list)

## Known Limitations

**Category Grouping:**
- Simple keyword heuristic may miscategorize uncommon ingredients
- No fuzzy matching — requires exact keyword substring match
- Future: Server-side category assignment via IngredientCatalog

**Shopping List State:**
- Temporary only — resets on sheet dismiss
- No persistence for checked items across app sessions
- Future: Persistent shopping list with cart sync

**Match Computation:**
- Name-only matching (quantity-agnostic)
- Excludes staples from percentage but still shows them in checklist
- Future: Quantity-aware matching with partial match states

## Next Steps

Phase 16 recipe matching feature complete. All plans executed:
- 16-01: Ingredient match badges on feed cards
- 16-02: Detail view match state and shopping list

Phase 17 or next milestone plans can now leverage completed recipe matching infrastructure.

## Files Changed

**Created (3):**
- `Kindred/Packages/FeedFeature/Sources/RecipeDetail/ShoppingListReducer.swift` (93 lines)
- `Kindred/Packages/FeedFeature/Sources/RecipeDetail/ShoppingListView.swift` (247 lines)
- `Kindred/Packages/FeedFeature/Sources/RecipeDetail/RecipeDetailModels.swift` (15 lines)

**Modified (4):**
- `Kindred/Packages/FeedFeature/Sources/RecipeDetail/RecipeDetailReducer.swift` (+87 lines)
- `Kindred/Packages/FeedFeature/Sources/RecipeDetail/RecipeDetailView.swift` (+34 lines)
- `Kindred/Packages/FeedFeature/Sources/RecipeDetail/IngredientChecklistView.swift` (+28 lines)
- `Kindred/Sources/Resources/Localizable.xcstrings` (+18 string keys with EN/TR translations)

## Commits

- cb89d7e: feat(16-02): add ingredient match state to recipe detail view
- adc030b: fix(16-02): fix ClerkUser type mismatch and missing font method
- 6a1ffdc: feat(16-02): create shopping list bottom sheet with grouping and share

## Self-Check: PASSED

**Created files verification:**
```
FOUND: Kindred/Packages/FeedFeature/Sources/RecipeDetail/ShoppingListReducer.swift
FOUND: Kindred/Packages/FeedFeature/Sources/RecipeDetail/ShoppingListView.swift
FOUND: Kindred/Packages/FeedFeature/Sources/RecipeDetail/RecipeDetailModels.swift
```

**Commits verification:**
```
FOUND: cb89d7e
FOUND: adc030b
FOUND: 6a1ffdc
```

All claimed files and commits exist in repository.
