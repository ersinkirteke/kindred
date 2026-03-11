# Phase 13: Manual Pantry Management - Context

**Gathered:** 2026-03-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Users can manually add, edit, delete, and view their pantry inventory with offline-first persistence. Items are stored locally via SwiftData and synced to the backend via GraphQL when online. This phase makes the existing pantry skeleton (list, empty state, delete) fully functional with add/edit flows.

</domain>

<decisions>
## Implementation Decisions

### Add Item Form
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

### Edit Item Flow
- Tap item row to open edit form
- Reuse same bottom sheet form as add, pre-filled with current values; Save button instead of Add
- All fields editable (name, quantity, unit, storage, category, expiry, notes)
- Changing storage location moves item to new section on save (not immediately)
- Delete button at bottom of edit form (red, destructive style) in addition to swipe-to-delete
- Delete requires confirmation alert ("Delete Milk?")
- Save directly — no confirmation dialog for saves
- Dismiss with unsaved changes shows "Discard changes?" alert

### List Display & Grouping
- Section headers show item count: e.g., "Fridge (12 items)"
- Items sorted alphabetically by name within each section
- Color-coded expiry badges: red for expired, orange for expiring within 3 days, no badge otherwise
- Search bar at top (iOS `.searchable` modifier) — filter items by name
- Enhanced item rows: show expiry date and first line of notes below quantity/category
- Empty storage location sections are hidden (current behavior preserved)
- Pull-to-refresh to re-fetch from SwiftData and trigger backend sync
- Sections are not collapsible — always expanded

### Offline Sync Behavior
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

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PantryItem` (SwiftData @Model): Full data model with all fields — name, quantity, unit, storageLocation, foodCategory, notes, expiryDate, isSynced, isDeleted, source
- `PantryItemInput`: DTO struct for add/update operations — maps directly to PantryItem fields
- `PantryItemState`: View-layer state struct for IdentifiedArray — already used in PantryReducer
- `PantryClient`: TCA dependency with addItem, updateItem, deleteItem, fetchAllItems, fetchItemsByLocation, markAsSynced — all wired to PantryStore
- `PantryStore`: SwiftData-backed store with full CRUD operations — MainActor, shared singleton
- `StorageLocation` enum: fridge/freezer/pantry with displayName and iconName
- `FoodCategory` enum: 10 categories (dairy, produce, meat, seafood, grains, baking, spices, beverages, snacks, condiments) with displayName
- `ItemSource` enum: manual/fridgeScan/receiptScan
- `PantryEmptyStateView`: Empty state with guest/auth variants — already functional
- `PantryItemRow`: Existing row component showing name, quantity, unit, category, sync icon
- `PantryView`: NavigationStack with grouped list, floating + button, toolbar + button, swipe-to-delete

### Established Patterns
- TCA (ComposableArchitecture) for state management: Reducer + State + Action pattern
- SwiftData for local persistence via PantryStore singleton
- IdentifiedArray for list state management
- `@Dependency` for injecting PantryClient
- AlertState for TCA-managed alerts
- Localized strings via `String(localized:bundle:)` pattern
- DesignSystem package imported for shared styles
- `.insetGrouped` list style
- Accessibility labels on interactive elements

### Integration Points
- `PantryReducer.addItemTapped` currently shows "coming soon" alert — replace with sheet presentation
- `PantryReducer` needs new actions: editItemTapped, saveItem, form state management
- `PantryClient` already has addItem/updateItem — wire to form submission
- GraphQL operations exist in NetworkClient (PantryQueries.graphql, PantryMutations.graphql, PantryNetworkOperations.swift) — sync layer connects here
- `PantryReducer.deleteItem` exists but needs confirmation alert before executing

</code_context>

<specifics>
## Specific Ideas

- Batch add mode should feel natural for "just got home from grocery shopping" — add 10 items quickly without dismissing the sheet each time
- Category auto-suggest makes adding feel smart without being slow
- Quick expiry shortcuts avoid date picker friction for common patterns
- Autocomplete from history makes re-adding common items (milk, eggs, bread) nearly instant

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 13-manual-pantry-management*
*Context gathered: 2026-03-11*
