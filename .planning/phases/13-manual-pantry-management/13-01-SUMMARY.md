---
phase: 13-manual-pantry-management
plan: 01
subsystem: pantry-ui
tags: [crud, forms, tca, swiftui, offline-first]
dependency_graph:
  requires: [pantry-client, pantry-store, ingredient-catalog]
  provides: [add-edit-item-ui, autocomplete, duplicate-detection]
  affects: [pantry-reducer]
tech_stack:
  added: [AddEditItemReducer, AddEditItemFormView, AutocompleteSuggestion]
  patterns: [tca-sheet-presentation, debounced-search, batch-add-mode]
key_files:
  created:
    - Kindred/Packages/PantryFeature/Sources/Models/PantryItemState.swift
    - Kindred/Packages/PantryFeature/Sources/AddEditItem/AddEditItemReducer.swift
    - Kindred/Packages/PantryFeature/Sources/AddEditItem/AddEditItemFormView.swift
  modified:
    - Kindred/Packages/PantryFeature/Sources/Pantry/PantryReducer.swift
    - Kindred/Packages/PantryFeature/Sources/PantryClient/PantryClient.swift
    - Kindred/Packages/PantryFeature/Sources/PantryClient/PantryStore.swift
    - Kindred/Packages/PantryFeature/Package.swift
decisions:
  - choice: Extract PantryItemState into Models directory
    rationale: Separation of concerns, added notes field for edit form
    alternatives: Keep in PantryReducer.swift (original location)
    trade_offs: Extra file but cleaner architecture
  - choice: Use debounced search with 300ms delay for autocomplete
    rationale: Balance between responsiveness and API call efficiency
    alternatives: Instant search (too many calls), 500ms delay (feels sluggish)
    trade_offs: 300ms is imperceptible to users but saves network calls
  - choice: SwiftData predicates don't support .lowercased() - filter in Swift code
    rationale: SwiftData limitation, case-insensitive matching required
    alternatives: Server-side filtering (adds network dependency)
    trade_offs: Fetch all user items then filter locally (acceptable for pantry scale)
  - choice: Map GraphQL defaultCategory to FoodCategory enum in PantryClient
    rationale: Keep reducer decoupled from Apollo/NetworkClient
    alternatives: Import Apollo in reducer (tight coupling)
    trade_offs: Extra closure but cleaner dependency boundaries
metrics:
  duration_minutes: 15
  tasks_completed: 2
  files_created: 3
  files_modified: 4
  commits: 2
  completed_at: "2026-03-11T22:39:00Z"
---

# Phase 13 Plan 01: AddEditItem Form Infrastructure Summary

**One-liner:** TCA-powered add/edit form with debounced autocomplete, category auto-suggest via IngredientCatalog, duplicate warnings, and batch add mode.

## What Was Built

Created the full AddEditItem CRUD UI layer for pantry management:

1. **PantryItemState Model** — Extracted from PantryReducer into Models directory with notes field added for edit form pre-fill.

2. **PantryClient Extensions** — Added three new closures:
   - `fetchSuggestions`: Autocomplete from previously added item names with unit/category reuse
   - `checkDuplicate`: Case-insensitive duplicate detection within storage location
   - `searchIngredientCategory`: GraphQL IngredientCatalog query for category auto-suggest

3. **PantryStore Methods** — Implemented backing logic:
   - `fetchDistinctItemNames`: Prefix-filtered autocomplete with SwiftData fetch
   - `checkDuplicate`: Case-insensitive duplicate check (SwiftData predicate limitation workaround)

4. **AddEditItemReducer** — Comprehensive TCA reducer with:
   - Mode enum (add/edit)
   - Debounced search (300ms) for autocomplete + duplicate check + category suggest
   - Form validation (name required)
   - Batch add mode (clears fields, retains storage location)
   - Unsaved changes detection with discard confirmation
   - Delete confirmation for edit mode
   - Haptic feedback on successful add

5. **AddEditItemFormView** — SwiftUI form broken into sections to avoid compiler timeout:
   - Segmented picker for storage location
   - Autocomplete suggestion chips
   - Duplicate warning display
   - Expiry date shortcuts (Tomorrow, 3 days, 1 week, 1 month)
   - Category suggestion accept/skip UI
   - Notes toggle field
   - Delete button for edit mode

## Deviations from Plan

None — plan executed exactly as written.

## Verification

✅ **Task 1:** PantryClient has fetchSuggestions, checkDuplicate, searchIngredientCategory closures. PantryItemState includes notes field. PantryStore implements backing methods. Build succeeds.

✅ **Task 2:** AddEditItemReducer handles all form actions (name with debounced autocomplete/category-suggest/duplicate-check, field changes, submit for add/edit modes, batch add clearing, cancel with unsaved changes warning, delete with confirmation). AddEditItemFormView renders full form with segmented storage picker, expiry shortcuts, autocomplete chips, notes toggle. Build succeeds.

## Technical Decisions

### SwiftData Predicate Limitation Workaround

**Problem:** SwiftData `#Predicate` macro doesn't support `.lowercased()` for case-insensitive string matching.

**Solution:** Fetch all items for user in storage location via simple predicate, compare names in Swift code:

```swift
let items = try modelContext.fetch(descriptor)
let lowercaseName = name.lowercased()
return items.contains { $0.name.lowercased() == lowercaseName }
```

**Trade-off:** Fetches more data than necessary, but pantry item count per user is small (typically <100), so performance impact is negligible.

### Debounce Timing

300ms debounce for autocomplete/duplicate/category search balances responsiveness (feels instant) with efficiency (avoids excessive API calls). Users type ~5 chars/sec, so 300ms = 1-2 chars before triggering search.

### Apollo Dependency Isolation

Added `searchIngredientCategory` closure to PantryClient instead of importing Apollo directly in AddEditItemReducer. This keeps the reducer testable and decoupled from GraphQL implementation details. The closure wraps `apolloClient.searchIngredients()` and maps defaultCategory string to FoodCategory enum.

### Batch Add Mode UX

After successful add, form clears all fields EXCEPT storage location. This supports the "just got home from grocery shopping" use case — user adds 10 items to Fridge without re-selecting storage each time. Haptic feedback confirms add without blocking UI.

## Files Modified

### Created
- `Kindred/Packages/PantryFeature/Sources/Models/PantryItemState.swift` — View-layer state with notes field
- `Kindred/Packages/PantryFeature/Sources/AddEditItem/AddEditItemReducer.swift` — 363 lines, full TCA reducer
- `Kindred/Packages/PantryFeature/Sources/AddEditItem/AddEditItemFormView.swift` — 358 lines, SwiftUI form with sections

### Modified
- `Kindred/Packages/PantryFeature/Sources/Pantry/PantryReducer.swift` — Removed PantryItemState definition
- `Kindred/Packages/PantryFeature/Sources/PantryClient/PantryClient.swift` — Added 3 new closures, wired to Apollo/PantryStore
- `Kindred/Packages/PantryFeature/Sources/PantryClient/PantryStore.swift` — Added fetchDistinctItemNames and checkDuplicate methods
- `Kindred/Packages/PantryFeature/Package.swift` — Added Apollo dependency for searchIngredientCategory

## Integration Points

**Next Step (Plan 02):** Wire AddEditItemReducer into PantryReducer via `@Presents` sheet pattern. Replace `addItemTapped` placeholder alert with `state.addEditForm = AddEditItemReducer.State(mode: .add, ...)`. Implement `editItemTapped(UUID)` action to open edit form.

**Blockers:** None. All infrastructure in place. Plan 02 is pure UI wiring + enhanced list display.

## Performance Notes

- Autocomplete suggestions fetched from local SwiftData, no network call — instant response
- Category auto-suggest queries GraphQL but is non-blocking, wrapped in `try?` — form submission doesn't wait
- Duplicate check also local SwiftData — instant response
- All three operations debounced together in single `.run` effect — efficient

## Self-Check: PASSED

✅ Created files exist:
```
FOUND: Kindred/Packages/PantryFeature/Sources/Models/PantryItemState.swift
FOUND: Kindred/Packages/PantryFeature/Sources/AddEditItem/AddEditItemReducer.swift
FOUND: Kindred/Packages/PantryFeature/Sources/AddEditItem/AddEditItemFormView.swift
```

✅ Commits exist:
```
FOUND: 5c6d9b5 (Task 1 - PantryClient extensions)
FOUND: 3891651 (Task 2 - AddEditItem reducer and view)
```

✅ Build verification:
```
BUILD SUCCEEDED (Xcode project compiles without errors)
```

---

**Plan Status:** ✅ Complete
**Completed:** 2026-03-11
**Duration:** 15 minutes
**Commits:** 5c6d9b5, 3891651
