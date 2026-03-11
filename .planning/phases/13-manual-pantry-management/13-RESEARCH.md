# Phase 13: Manual Pantry Management - Research

**Researched:** 2026-03-11
**Domain:** SwiftUI + TCA forms, SwiftData local-first persistence, offline-first sync
**Confidence:** HIGH

## Summary

Phase 13 builds full CRUD functionality for pantry items on top of the existing SwiftData infrastructure from Phase 12. The codebase already has all persistence, models, and GraphQL operations in place—this phase focuses on **UI layer only**: add/edit forms via bottom sheets, enhanced list display, and wiring existing sync mechanisms to user-visible indicators.

The tech stack is already locked: SwiftUI + TCA for UI, SwiftData for local persistence (via `PantryStore` singleton), GraphQL mutations via NetworkClient for backend sync. The pattern follows established project conventions: `@Presents` for sheet state, `PantryClient` dependency injection, `IdentifiedArray` for list state, and localized strings via `Localizable.xcstrings`.

**Primary recommendation:** Reuse existing `PantryItem`, `PantryClient`, and `PantryStore` infrastructure. Create a new `AddEditItemReducer` for form state management, present via `@Presents` sheet in `PantryReducer`, and wire GraphQL sync on background via NetworkClient without blocking UI (isSynced flag + cloud-slash icon for visual feedback).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Bottom sheet presentation (`.sheet` modifier)
- Required fields: item name and storage location only
- Quantity defaults to "1", everything else optional
- Storage location selected via segmented control (Fridge | Freezer | Pantry)
- Batch add mode: after adding, form clears fields but retains storage location; Done button to dismiss
- Quantity is free text input (supports "500", "2.5", "1/2")
- Unit selection via predefined picker (kg, g, L, ml, pcs, bunch, can, bottle, bag)
- Food category auto-suggested from item name (e.g., "milk" → dairy), user can override or skip
- Expiry date: quick shortcut buttons (Tomorrow, 3 days, 1 week, 1 month) plus standard date picker
- Notes field hidden behind "Add notes" link — tap to reveal text area
- Success feedback: subtle haptic + form clears, item appears in list behind sheet
- Duplicate warning: show "You already have Milk in Fridge" but allow adding anyway
- Autocomplete from previously added item names — reuses category/unit from last entry
- Tap item row to open edit form
- Reuse same bottom sheet form as add, pre-filled with current values; Save button instead of Add
- All fields editable (name, quantity, unit, storage, category, expiry, notes)
- Changing storage location moves item to new section on save (not immediately)
- Delete button at bottom of edit form (red, destructive style) in addition to swipe-to-delete
- Delete requires confirmation alert ("Delete Milk?")
- Save directly — no confirmation dialog for saves
- Dismiss with unsaved changes shows "Discard changes?" alert
- Section headers show item count: e.g., "Fridge (12 items)"
- Items sorted alphabetically by name within each section
- Color-coded expiry badges: red for expired, orange for expiring within 3 days, no badge otherwise
- Search bar at top (iOS `.searchable` modifier) — filter items by name
- Enhanced item rows: show expiry date and first line of notes below quantity/category
- Empty storage location sections are hidden (current behavior preserved)
- Pull-to-refresh to re-fetch from SwiftData and trigger backend sync
- Sections are not collapsible — always expanded
- Per-item cloud-slash icon on unsynced items (existing pattern)
- Subtle sync indicator in toolbar when syncing
- Sync triggered on every add/edit/delete AND on app foreground
- Last-write-wins conflict resolution
- Auto-retry failed syncs silently; after 3 retries, show unobtrusive banner: "Unable to sync. Will retry."
- Changes batched and sent together when connectivity is available
- Subtle offline indicator in navigation bar when no connectivity
- Two-way sync: push local changes AND pull server changes on foreground

### Claude's Discretion
- Loading skeleton design during initial fetch
- Exact spacing, typography, and color choices within DesignSystem constraints
- Category auto-suggest algorithm implementation details
- Sync retry interval timing
- Exact autocomplete matching logic (prefix vs fuzzy)

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

This phase implements all v3.0 manual pantry requirements:

| ID | Description | Research Support |
|----|-------------|-----------------|
| PANTRY-01 | User can add a pantry item with name, quantity, and unit | SwiftUI form + TCA reducer + PantryClient.addItem |
| PANTRY-02 | User can edit existing pantry items (name, quantity, unit, category) | Reuse form reducer, pre-fill state, PantryClient.updateItem |
| PANTRY-03 | User can delete pantry items individually | Existing swipe-to-delete + confirmation AlertState + PantryClient.deleteItem |
| PANTRY-04 | User can categorize items by storage location (fridge, freezer, pantry) | StorageLocation enum + segmented picker in form |
| PANTRY-05 | Pantry data persists locally and syncs to backend across devices | SwiftData (already working) + GraphQL mutations via NetworkClient |
| PANTRY-06 | User can view their pantry as a list grouped by storage location | Existing PantryView sections + enhanced row display |
| PANTRY-07 | Pantry works offline with changes synced when connectivity returns | isSynced flag + background sync worker polling unsaved items |
</phase_requirements>

## Standard Stack

### Core (Already in Project)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | Declarative UI framework | Apple's modern UI framework, required for modern iOS dev |
| Composable Architecture (TCA) | 1.15+ | State management, side effects | Project standard, already used across all features |
| SwiftData | iOS 17+ | Local persistence | Apple's modern CoreData replacement, already integrated in Phase 12 |
| Apollo iOS | 1.15+ | GraphQL client | Project standard for backend communication via NetworkClient |
| DesignSystem (SPM) | N/A | Shared UI components | Project-specific design system package |

### Supporting (Already in Project)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Dependencies | TCA built-in | Dependency injection | All TCA reducers use `@Dependency` for testability |
| IdentifiedArray | TCA built-in | List state management | Lists with stable IDs (recipes, pantry items) |
| swift-case-paths | TCA dependency | Enum navigation | Required by TCA for state routing |

**Installation:** No new dependencies required. All libraries already integrated in Phase 12.

## Architecture Patterns

### TCA Sheet Presentation Pattern

**What:** Use `@Presents` property wrapper in parent state, present child reducer via `.sheet(item:)` binding

**When to use:** Modal forms, detail views, any content presented over current context

**Example from FeedReducer:**
```swift
// Parent State
@ObservableState
public struct State: Equatable {
    @Presents public var paywall: SubscriptionReducer.State?
}

// Parent Action
public enum Action {
    case showPaywall
    case paywall(PresentationAction<SubscriptionReducer.Action>)
}

// Parent Reducer
case .showPaywall:
    state.paywall = SubscriptionReducer.State()
    return .none

// Parent body
var body: some ReducerOf<Self> {
    Reduce { state, action in
        // handle actions
    }
    .ifLet(\.$paywall, action: \.paywall) {
        SubscriptionReducer()
    }
}

// View
.sheet(item: $store.scope(state: \.paywall, action: \.paywall)) { paywallStore in
    PaywallView(store: paywallStore)
}
```

### SwiftData Local-First CRUD Pattern

**What:** All mutations write to SwiftData first (instant UI feedback), then queue for backend sync

**When to use:** Offline-first features where user shouldn't wait for network

**Pattern:**
```swift
// 1. Write to SwiftData (instant)
func addItem(_ input: PantryItemInput) async throws {
    let item = PantryItem(/* map input */, isSynced: false)
    modelContext.insert(item)
    try modelContext.save() // Returns immediately
}

// 2. Sync to backend (background, non-blocking)
.run { send in
    try await networkClient.syncPantryItems(userId)
    await send(.syncCompleted)
}
```

### TCA Form State Management

**What:** Dedicated child reducer for form state, validation, and submission

**When to use:** Non-trivial forms with validation, multi-field state

**Pattern:**
```swift
@Reducer
struct AddEditItemReducer {
    @ObservableState
    struct State: Equatable {
        var mode: Mode // .add or .edit(id)
        var name: String = ""
        var quantity: String = "1"
        var unit: String?
        var storageLocation: StorageLocation = .pantry
        var foodCategory: FoodCategory?
        var expiryDate: Date?
        var notes: String?
        var showNotesField: Bool = false
        var isSubmitting: Bool = false
        var validationError: String?
        @Presents var confirmDiscard: AlertState<Action.Alert>?
    }

    enum Action {
        case nameChanged(String)
        case quantityChanged(String)
        case storageLocationChanged(StorageLocation)
        case submitTapped
        case cancelTapped
        // ... other field actions
        case delegate(Delegate)
        enum Delegate {
            case itemSaved
            case cancelled
        }
    }
}
```

### Autocomplete from History

**What:** Fetch distinct item names from SwiftData, filter by prefix match, suggest on typing

**Pattern:**
```swift
// In PantryStore
func fetchDistinctItemNames(userId: String, prefix: String) async -> [String] {
    let descriptor = FetchDescriptor<PantryItem>(
        predicate: #Predicate<PantryItem> { item in
            item.userId == userId && !item.isDeleted && item.name.localizedStandardContains(prefix)
        },
        sortBy: [SortDescriptor(\PantryItem.updatedAt, order: .reverse)]
    )
    // Return unique names
}

// In Reducer
case .nameChanged(let text):
    state.name = text
    guard text.count >= 2 else { return .none }
    return .run { send in
        let suggestions = await pantryClient.fetchSuggestions(text)
        await send(.suggestionsLoaded(suggestions))
    }
```

### Category Auto-Suggest via IngredientCatalog

**What:** Query backend IngredientCatalog GraphQL for normalized ingredient → use defaultCategory

**Pattern:**
```swift
// NetworkClient already has IngredientSearch query from Phase 12
query IngredientSearch($query: String!, $lang: String = "en") {
    ingredientSearch(query: $query, lang: $lang) {
        defaultCategory  // maps to FoodCategory enum
    }
}

// In form reducer
case .nameChanged(let text):
    state.name = text
    return .run { send in
        let result = await networkClient.searchIngredient(text)
        if let category = result?.defaultCategory {
            await send(.categorySuggested(category))
        }
    }
```

### Offline Sync Worker

**What:** Background Effect that polls for `isSynced == false` items, batches GraphQL mutations

**Pattern:**
```swift
// In PantryReducer
case .onAppear:
    return .merge(
        .send(.loadItems),
        .run { [userId] send in
            for await _ in clock.timer(interval: .seconds(30)) {
                await send(.syncPendingItems)
            }
        }
    )

case .syncPendingItems:
    guard networkMonitor.isConnected else { return .none }
    return .run { [userId] send in
        let unsyncedItems = await pantryClient.fetchUnsyncedItems(userId)
        guard !unsyncedItems.isEmpty else { return }

        await send(.syncInProgress(true))
        do {
            for item in unsyncedItems {
                try await networkClient.syncItem(item)
                await pantryClient.markAsSynced(item.id)
            }
            await send(.syncCompleted)
        } catch {
            await send(.syncFailed(error))
        }
    }
```

### Anti-Patterns to Avoid

- **Blocking UI on network calls:** Always write to SwiftData first, sync in background
- **Hard-coding validation in View layer:** Move validation logic to Reducer for testability
- **Mutating @Bindable state directly in complex forms:** Use dedicated Reducer actions for each field change (enables time-travel debugging, testing)
- **Missing unsaved changes warning:** Always track `isDirty` state, show AlertState on dismiss attempt

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Form validation logic | Custom string validators, regex checks | TCA reducer validation + computed `isValid` state | Testable, time-travel debuggable, composable |
| Autocomplete UI | Custom dropdown view | `.searchable` modifier + filtered list | Native iOS behavior, accessibility built-in |
| Date shortcuts (Tomorrow, 3 days, etc.) | Manual date math scattered in views | Computed Date extension methods | Reusable, unit testable |
| Offline queue | Custom CoreData queue, manual retry logic | SwiftData + isSynced flag + TCA Effect polling | Leverage existing SwiftData, simpler state management |
| Debouncing search input | Manual Timer, Combine debounce | TCA `.debounce` effect | Built into TCA, cancellation handled automatically |

**Key insight:** SwiftUI + TCA already provide robust form building blocks. The challenge is **composition** (sheet presentation, form state, validation, submission) not low-level primitives.

## Common Pitfalls

### Pitfall 1: SwiftData + CloudKit Unique Constraints

**What goes wrong:** App crashes or sync fails when using `@Attribute(.unique)` with CloudKit sync

**Why it happens:** CloudKit doesn't support unique constraints. SwiftData allows it for local-only persistence, but sync breaks.

**How to avoid:** Phase 12 already uses non-unique `id: UUID` field. Don't add `.unique` to any other fields if future CloudKit sync is planned.

**Warning signs:** Sync errors mentioning "unique constraint", CloudKit console errors

**Source:** [Offline Sync Strategies: Core Data + CloudKit + SwiftData in iOS Apps](https://ravi6997.medium.com/offline-sync-strategies-core-data-cloudkit-swiftdata-in-ios-apps-3760684567fd)

### Pitfall 2: TCA Sheet Dismiss Breaks on iOS 16

**What goes wrong:** Navigation push animations break after presenting/dismissing a sheet

**Why it happens:** iOS 16 bug where first navigation after modal loses animation

**How to avoid:** Phase 13 doesn't use NavigationStack inside sheets, so not directly affected. If future phases add navigation-in-sheet, add explicit animation modifiers.

**Warning signs:** Janky transitions after sheet dismiss

**Source:** [Navigation push animation breaks after presenting a sheet · Issue #3833](https://github.com/pointfreeco/swift-composable-architecture/issues/3833)

### Pitfall 3: Race Condition on Rapid Add → Dismiss → Fetch

**What goes wrong:** User adds item, sheet dismisses, but item doesn't appear in list (eventual consistency delay)

**Why it happens:** SwiftData save happens async, list fetch might run before save completes

**How to avoid:** Use optimistic UI updates — insert `PantryItemState` into `state.items` immediately on `.itemSaved`, don't wait for re-fetch. Mark as `isSynced: false` until backend confirms.

**Warning signs:** Flaky tests, items disappear then reappear

### Pitfall 4: Form Field Binding Performance

**What goes wrong:** TextField typing feels laggy, keyboard stutters

**Why it happens:** Sending TCA action on every keystroke can be slow if reducer does heavy work

**How to avoid:** Use `@FocusState` bindings for TextFields, only send `.nameChanged` action on commit or with debounce. For simple text input, direct binding is fine.

**Warning signs:** Profiler shows high CPU on text input, user complaints about lag

**Source:** [The Ultimate Guide To Validation Patterns In SwiftUI](https://azamsharp.com/2024/12/18/the-ultimate-guide-to-validation-patterns-in-swiftui.html)

### Pitfall 5: SwiftData Predicate Limitations

**What goes wrong:** Fetch queries crash with "unsupported expression" errors

**Why it happens:** SwiftData `#Predicate` macro doesn't support all Swift expressions (complex string operations, computed properties)

**How to avoid:** Keep predicates simple: equality checks, basic comparisons. For complex filtering, fetch broader set and filter in Swift code.

**Warning signs:** Compile-time errors in `#Predicate`, runtime crashes on fetch

**Source:** [Key Considerations Before Using SwiftData](https://fatbobman.com/en/posts/key-considerations-before-using-swiftdata/)

## Code Examples

### TCA Sheet Presentation (Add/Edit Form)

```swift
// Source: Project existing pattern (FeedReducer paywall)
// PantryReducer.swift

@ObservableState
public struct State: Equatable {
    // ... existing state
    @Presents public var addEditForm: AddEditItemReducer.State?
}

public enum Action {
    case addItemTapped
    case editItemTapped(UUID)
    case addEditForm(PresentationAction<AddEditItemReducer.Action>)
}

case .addItemTapped:
    guard let userId = state.userId else {
        return .send(.delegate(.authGateRequested))
    }
    state.addEditForm = AddEditItemReducer.State(
        mode: .add,
        userId: userId,
        storageLocation: .pantry // or smart default based on last add
    )
    return .none

case .editItemTapped(let id):
    guard let item = state.items[id: id] else { return .none }
    state.addEditForm = AddEditItemReducer.State(
        mode: .edit(id),
        userId: state.userId!,
        name: item.name,
        quantity: item.quantity,
        unit: item.unit,
        storageLocation: item.storageLocation,
        foodCategory: item.foodCategory,
        expiryDate: item.expiryDate,
        notes: item.notes
    )
    return .none

case .addEditForm(.presented(.delegate(.itemSaved))):
    state.addEditForm = nil
    return .send(.onAppear) // Re-fetch to show new item

var body: some ReducerOf<Self> {
    Reduce { state, action in
        // ... existing logic
    }
    .ifLet(\.$addEditForm, action: \.addEditForm) {
        AddEditItemReducer()
    }
}
```

### Form View with Segmented Picker

```swift
// Source: SwiftUI best practices
// AddEditItemView.swift

struct AddEditItemFormView: View {
    @Bindable var store: StoreOf<AddEditItemReducer>

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Item name", text: $store.name)
                        .textInputAutocapitalization(.words)

                    HStack {
                        TextField("Quantity", text: $store.quantity)
                            .keyboardType(.decimalPad)
                            .frame(maxWidth: 100)

                        Picker("Unit", selection: $store.unit) {
                            Text("—").tag(nil as String?)
                            Text("kg").tag("kg" as String?)
                            Text("g").tag("g" as String?)
                            Text("L").tag("L" as String?)
                            Text("ml").tag("ml" as String?)
                            Text("pcs").tag("pcs" as String?)
                            Text("bunch").tag("bunch" as String?)
                            Text("can").tag("can" as String?)
                            Text("bottle").tag("bottle" as String?)
                            Text("bag").tag("bag" as String?)
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section {
                    Picker("Storage", selection: $store.storageLocation) {
                        ForEach(StorageLocation.allCases, id: \.self) { location in
                            Label(location.displayName, systemImage: location.iconName)
                                .tag(location)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if let category = store.foodCategory {
                    Section {
                        HStack {
                            Text("Category")
                            Spacer()
                            Text(category.displayName)
                                .foregroundStyle(.secondary)
                            Button("Change") {
                                store.send(.changeCategoryTapped)
                            }
                        }
                    }
                }

                Section {
                    if store.showNotesField {
                        TextField("Notes", text: $store.notes ?? "", axis: .vertical)
                            .lineLimit(3...6)
                    } else {
                        Button("Add notes") {
                            store.send(.showNotesFieldTapped)
                        }
                    }
                }
            }
            .navigationTitle(store.mode == .add ? "Add Item" : "Edit Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        store.send(.cancelTapped)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(store.mode == .add ? "Add" : "Save") {
                        store.send(.submitTapped)
                    }
                    .disabled(!store.isValid)
                }
            }
        }
    }
}
```

### Expiry Date Shortcuts

```swift
// Source: SwiftUI DatePicker best practices
// Date+Extensions.swift

extension Date {
    static var tomorrow: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }

    static func daysFromNow(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
    }

    static var oneWeekFromNow: Date { daysFromNow(7) }
    static var oneMonthFromNow: Date {
        Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    }
}

// In form view
Section("Expiry Date") {
    HStack(spacing: 8) {
        Button("Tomorrow") {
            store.send(.expiryDateChanged(.tomorrow))
        }
        Button("3 days") {
            store.send(.expiryDateChanged(.daysFromNow(3)))
        }
        Button("1 week") {
            store.send(.expiryDateChanged(.oneWeekFromNow))
        }
        Button("1 month") {
            store.send(.expiryDateChanged(.oneMonthFromNow))
        }
    }
    .buttonStyle(.bordered)

    DatePicker(
        "Specific date",
        selection: Binding(
            get: { store.expiryDate ?? .tomorrow },
            set: { store.send(.expiryDateChanged($0)) }
        ),
        in: Date()...,
        displayedComponents: .date
    )
}
```

### SwiftData Fetch with Filtering

```swift
// Source: Project existing pattern (PantryStore)
// PantryStore.swift

func fetchItemsByNamePrefix(userId: String, prefix: String) async -> [PantryItem] {
    let descriptor = FetchDescriptor<PantryItem>(
        predicate: #Predicate<PantryItem> { item in
            item.userId == userId
                && !item.isDeleted
                && item.name.localizedStandardContains(prefix)
        },
        sortBy: [SortDescriptor(\PantryItem.updatedAt, order: .reverse)]
    )
    do {
        return try modelContext.fetch(descriptor)
    } catch {
        return []
    }
}
```

### Batch Add Mode (Clear Fields, Retain Storage)

```swift
// In AddEditItemReducer

case .submitTapped:
    guard state.isValid else { return .none }
    state.isSubmitting = true
    let input = PantryItemInput(/* map from state */)

    return .run { [mode = state.mode, storage = state.storageLocation] send in
        try await pantryClient.addItem(input)
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        if mode == .add {
            // Batch add mode: clear fields but keep storage location
            await send(.itemAdded(retainStorage: storage))
        } else {
            await send(.delegate(.itemSaved))
        }
    }

case .itemAdded(let retainStorage):
    state.name = ""
    state.quantity = "1"
    state.unit = nil
    state.foodCategory = nil
    state.expiryDate = nil
    state.notes = nil
    state.showNotesField = false
    state.storageLocation = retainStorage // Keep for next item
    state.isSubmitting = false
    return .none
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| CoreData + manual sync queue | SwiftData + isSynced flag + TCA Effects | iOS 17 (2023) | Simpler persistence code, type-safe queries, less boilerplate |
| Combine publishers for form state | TCA Reducer actions + @Bindable | TCA 1.0 (2023) | More testable, time-travel debugging, less Combine overhead |
| Manual validation in didSet | Computed `isValid` property from state | SwiftUI maturity (2024+) | Declarative validation, easier to reason about |
| UIKit UIAlertController | TCA AlertState + .alert modifier | TCA standard | Reducer controls alerts, testable, state-driven |

**Deprecated/outdated:**
- **WithViewStore for @ObservableState:** TCA 1.0+ uses `@Bindable` directly, no need for WithViewStore wrapper
- **EnvironmentObject for dependencies:** Use TCA `@Dependency` instead for testability
- **CoreData NSManagedObject:** SwiftData `@Model` is preferred for new iOS 17+ projects

## Open Questions

1. **Category auto-suggest latency tolerance**
   - What we know: IngredientSearch GraphQL query exists, returns defaultCategory
   - What's unclear: Should we show category suggestion while typing, or only on submit? What's acceptable latency?
   - Recommendation: Debounce 500ms, show subtle suggestion label below name field, don't block form submission

2. **Autocomplete UI pattern**
   - What we know: SwiftUI `.searchable` works for filtering existing list, not for inline autocomplete
   - What's unclear: Show autocomplete as dropdown overlay, or as filtered suggestion chips below TextField?
   - Recommendation: Use suggestion chips (similar to DietaryChipBar pattern) — less intrusive, iOS-native feel

3. **Sync failure retry strategy**
   - What we know: User decision says "after 3 retries, show unobtrusive banner"
   - What's unclear: Exponential backoff? Fixed interval? What's the interval?
   - Recommendation: Exponential backoff (30s, 60s, 120s), then show banner. Reset retry count on successful sync.

4. **Duplicate detection algorithm**
   - What we know: "show warning but allow adding anyway"
   - What's unclear: Case-insensitive match? Normalized match using `normalizedName`? Exact match only?
   - Recommendation: Case-insensitive exact match within same storage location. Don't warn for "Milk" in Fridge vs "Milk" in Freezer.

## Validation Architecture

> **Note:** `.planning/config.json` does not have `workflow.nyquist_validation` set, so validation architecture is optional. However, documenting test strategy for future reference.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (built into Xcode) |
| Config file | N/A (standard Xcode test targets) |
| Quick run command | `xcodebuild test -scheme PantryFeature -destination 'platform=iOS Simulator,name=iPhone 16 Pro'` |
| Full suite command | `xcodebuild test -scheme Kindred -destination 'platform=iOS Simulator,name=iPhone 16 Pro'` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PANTRY-01 | Add pantry item with name, quantity, unit | Unit (TCA reducer) | `swift test --filter AddEditItemReducerTests.testAddItem` | ❌ Wave 0 |
| PANTRY-02 | Edit existing pantry item | Unit (TCA reducer) | `swift test --filter AddEditItemReducerTests.testEditItem` | ❌ Wave 0 |
| PANTRY-03 | Delete pantry item with confirmation | Unit (TCA reducer) | `swift test --filter PantryReducerTests.testDeleteWithConfirmation` | ❌ Wave 0 |
| PANTRY-04 | Storage location categorization | Unit (model) | `swift test --filter PantryItemTests.testStorageLocation` | ❌ Wave 0 |
| PANTRY-05 | Local persistence + backend sync | Integration (SwiftData + NetworkClient mock) | Manual verification (requires GraphQL mock) | ❌ Wave 0 |
| PANTRY-06 | Grouped list display | Unit (TCA reducer state) | `swift test --filter PantryReducerTests.testGroupedItems` | ❌ Wave 0 |
| PANTRY-07 | Offline sync queue | Integration (NetworkClient mock) | Manual verification (requires connectivity simulation) | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `swift test --filter PantryFeature` (fast unit tests only, ~10s)
- **Per wave merge:** Full PantryFeature test suite including integration tests (~30s)
- **Phase gate:** All tests green + manual UI verification on device

### Wave 0 Gaps
- [ ] `PantryFeatureTests/AddEditItemReducerTests.swift` — covers PANTRY-01, PANTRY-02
- [ ] `PantryFeatureTests/PantryReducerTests.swift` — covers PANTRY-03, PANTRY-06
- [ ] `PantryFeatureTests/SyncWorkerTests.swift` — covers PANTRY-07 (with NetworkClient mock)
- [ ] Test fixtures for mock PantryItems, mock GraphQL responses

## Sources

### Primary (HIGH confidence)
- **Codebase analysis:** PantryFeature package (Phase 12 deliverables) — models, store, client, GraphQL operations all verified working
- **Official TCA docs:** [pointfreeco/swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture) — `@Presents` pattern confirmed current as of TCA 1.15+
- **Apple SwiftData docs:** WWDC23 session "Meet SwiftData" — `@Model` macro, FetchDescriptor, ModelContainer patterns

### Secondary (MEDIUM confidence)
- [Offline Sync Strategies: Core Data + CloudKit + SwiftData in iOS Apps](https://ravi6997.medium.com/offline-sync-strategies-core-data-cloudkit-swiftdata-in-ios-apps-3760684567fd) — CloudKit unique constraint limitation verified
- [The Ultimate Guide To Validation Patterns In SwiftUI](https://azamsharp.com/2024/12/18/the-ultimate-guide-to-validation-patterns-in-swiftui.html) — Form validation via view modifiers, avoid hand-rolled regex
- [Master SwiftUI Forms: The Complete Guide to TextFields, Pickers & Validation](https://dev.to/swift_pal/master-swiftui-forms-the-complete-guide-to-textfields-pickers-validation-4jlj) — Picker in Form best practices

### Tertiary (LOW confidence)
- [Navigation push animation breaks after presenting a sheet · Issue #3833](https://github.com/pointfreeco/swift-composable-architecture/issues/3833) — iOS 16 sheet bug (not directly affecting Phase 13, but good to know)
- [Key Considerations Before Using SwiftData](https://fatbobman.com/en/posts/key-considerations-before-using-swiftdata/) — SwiftData predicate limitations (community blog, but matches Apple's docs)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — All libraries already integrated, no new dependencies
- Architecture: HIGH — Project patterns established across 7 SPM packages, TCA sheet presentation verified in FeedReducer
- Pitfalls: MEDIUM-HIGH — SwiftData/CloudKit constraint verified in Apple docs, TCA sheet bug from GitHub Issues (recent), form performance from community best practices

**Research date:** 2026-03-11
**Valid until:** 2026-04-11 (30 days — stable tech stack, no major iOS updates expected before WWDC24)

---

**Ready for Planning:** All research complete. Planner can now create PLAN.md files for Wave-based implementation.
