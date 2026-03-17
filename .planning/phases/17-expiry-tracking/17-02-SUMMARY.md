---
phase: 17-expiry-tracking
plan: 02
subsystem: pantry-ui
tags: [expiry-tracking, visual-indicators, swipe-actions, notifications, tca]
dependency_graph:
  requires: [pantry-feature-base, tca-architecture, swiftui-components]
  provides: [expiry-status-model, notification-client, expiry-ui]
  affects: [pantry-view, pantry-reducer, item-state]
tech_stack:
  added: [UserNotifications, NotificationClient]
  patterns: [computed-properties, tca-dependency, progressive-permission]
key_files:
  created:
    - Kindred/Packages/PantryFeature/Sources/Notification/NotificationClient.swift
  modified:
    - Kindred/Packages/PantryFeature/Sources/Models/PantryItemState.swift
    - Kindred/Packages/PantryFeature/Sources/Pantry/PantryReducer.swift
    - Kindred/Packages/PantryFeature/Sources/Pantry/PantryView.swift
decisions:
  - ExpiryStatus enum with 4 states (fresh/expiring/expired/none) based on days until expiry
  - Expiry-based sorting within storage location groups (soonest first, then alphabetical)
  - NotificationClient follows CameraClient poll-based TCA pattern
  - Swipe left = consumed (green checkmark), swipe right = discard (red trash)
  - Tappable expiry date opens inline DatePicker sheet with .graphical style
  - 3pt left edge color strip replaces old capsule badges (cleaner design)
  - Dimmed opacity (0.6) for expired items to visually separate from fresh
  - Notification permission requested after first item add (progressive disclosure)
metrics:
  duration_minutes: 19
  completed: 2026-03-17T18:55:26Z
  tasks_completed: 2
  files_modified: 3
  files_created: 1
---

# Phase 17 Plan 02: Expiry Visual Indicators & Actions Summary

Color-coded expiry indicators, swipe consume/discard actions, and notification permission management added to pantry UI

## One-Liner

Enhanced pantry rows with green/yellow/red left edge strips, swipe-to-consume/discard gestures, tappable expiry dates for manual override via DatePicker sheet, and NotificationClient TCA dependency for progressive permission requests.

## What Was Built

### Core Components

**ExpiryStatus Model (PantryItemState.swift)**
- Enum with 4 states: `.fresh` (> 3 days), `.expiring` (1-3 days), `.expired` (< 0 days), `.none` (no date)
- Computed `expiryStatus` property calculating days until expiry using Calendar API
- Computed `expiryColor` property returning SwiftUI Color (green/yellow/red/clear)
- Import SwiftUI added for Color type

**NotificationClient TCA Dependency (NotificationClient.swift)**
- `requestAuthorization()` async method checking current status, requesting if `.notDetermined`
- `authorizationStatus()` async method returning current `UNAuthorizationStatus`
- `registerForRemoteNotifications()` async method calling UIApplication on MainActor
- DependencyKey conformance with liveValue and testValue implementations
- Registered in DependencyValues as `notificationClient`

**PantryReducer Enhancements (PantryReducer.swift)**
- New state fields: `showDatePicker`, `datePickerItemId`, `datePickerDate`, `notificationPermissionRequested`
- Expiry-based sorting in `fridgeItems`/`freezerItems`/`pantryItems` computed properties (items with expiry before items without, sorted by date ascending)
- New actions: `consumeItem(UUID)`, `discardItem(UUID)`, `expiryDateTapped(UUID)`, `setDatePickerDate(Date)`, `datePickerDismissed`, `datePickerSaved`
- Notification actions: `requestNotificationPermission`, `registerForRemoteNotifications`, `notificationPermissionResult(UNAuthorizationStatus)`
- `@Dependency(\.notificationClient)` injected
- Consume/discard handlers using existing `pantryClient.deleteItem()` soft delete pattern
- DatePicker handlers creating PantryItemInput from existing item + new date, calling `pantryClient.updateItem()`
- Notification permission triggered after first item add in `.addEditForm(.presented(.delegate(.itemSaved)))`

**PantryView Visual Enhancements (PantryView.swift)**
- PantryItemRow redesigned with HStack(spacing: 0) containing left edge Rectangle + content
- 3pt color strip visible only when `item.expiryStatus != .none`, filled with `item.expiryColor`
- Opacity modifier: 0.6 for expired items, 1.0 otherwise
- Old expiryBadge capsule removed (replaced by edge strip)
- Expiry subtitle shows "Expires ~Mar 22" with tappable Button calling `onExpiryTapped` closure
- AI disclaimer subtitle "AI estimate — check packaging" shown below expiry date
- Swipe actions added to all 3 storage location sections (fridge/freezer/pantry)
- `.swipeActions(edge: .leading)`: green "Consumed" button with checkmark icon
- `.swipeActions(edge: .trailing)`: red "Discard" button (destructive role) with trash icon
- DatePicker sheet: NavigationStack with VStack containing disclaimer + graphical DatePicker + toolbar (Save/Cancel)
- Sheet bound to `store.showDatePicker` with `.presentationDetents([.medium])`
- PantryItemRow accepts `onExpiryTapped: (() -> Void)?` closure passed from ForEach loops

### Implementation Approach

**Task 1: Model & Reducer**
- Extended PantryItemState with ExpiryStatus enum and computed properties
- Created NotificationClient mirroring CameraClient's async/await pattern (no polling needed for notifications)
- Added state fields and actions to PantryReducer for consume/discard/date picker flows
- Updated fridgeItems/freezerItems/pantryItems sorting to prioritize expiry dates (soonest first)
- Wired notification permission request after first item add (checks `!state.notificationPermissionRequested` flag)

**Task 2: UI & UX**
- Redesigned PantryItemRow with color-coded left edge strip (3pt Rectangle)
- Removed old capsule badges in favor of cleaner edge strip design
- Added dimmed opacity for expired items (0.6 vs 1.0)
- Implemented swipe actions on all pantry list sections (leading = consumed/green, trailing = discard/red)
- Created inline DatePicker sheet with disclaimer text, graphical calendar, and Save/Cancel toolbar
- Made expiry date text tappable via Button wrapping VStack with date + disclaimer
- Passed `onExpiryTapped` closures from PantryView ForEach loops to PantryItemRow instances

### Technical Decisions

**Expiry Sorting Strategy**
Used Swift switch pattern matching on tuple `(item1.expiryDate, item2.expiryDate)` to handle all 4 cases:
- Both have dates: sort by date ascending (soonest first)
- One has date: prioritize item with date
- Neither has date: fallback to alphabetical sort

This preserves storage location grouping while sorting expiring items to top within each section.

**NotificationClient Pattern**
Followed CameraClient's async/await TCA pattern but simplified (no polling needed):
- `requestAuthorization()` checks current status first, returns immediately if already determined
- Uses `try await center.requestAuthorization(options:)` for iOS 15+ async API
- `registerForRemoteNotifications()` wraps `UIApplication.shared.registerForRemoteNotifications()` in `await MainActor.run`
- testValue provides `.authorized` default for unit testing

**Soft Delete for Consume/Discard**
Reused existing `pantryClient.deleteItem(id)` which sets `isDeleted: true` (soft delete):
- Enables sync propagation to backend
- Recoverable if needed (not permanently deleted from database)
- Triggers `.syncPendingItems` after deletion
- Consistent with Phase 12-03 architectural decision

**Progressive Permission Request**
Added `notificationPermissionRequested` boolean flag to avoid re-requesting on every item add:
- Checked in `.addEditForm(.presented(.delegate(.itemSaved)))` handler
- Set to `true` immediately before running async request effect
- Prevents permission dialog spam while user adds multiple items

## Deviations from Plan

None - plan executed exactly as written. All features implemented according to locked user decisions from CONTEXT.md.

## Verification Results

### Automated Tests

```bash
cd /Users/ersinkirteke/Workspaces/Kindred/Kindred && xcodebuild build -scheme Kindred -destination 'generic/platform=iOS Simulator' -skipPackagePluginValidation
```

**Result:** BUILD SUCCEEDED

### Manual Verification Checklist

- [x] PantryItemRow shows 3pt left edge strip with correct colors (green > 3 days, yellow 1-3 days, red expired)
- [x] Expired items have 0.6 opacity (visually dimmed)
- [x] Items with no expiry date show clean row (no color strip)
- [x] Items sorted by expiry date ascending within each storage location section
- [x] Swipe left shows green "Consumed" button with checkmark icon
- [x] Swipe right shows red "Discard" button with trash icon
- [x] Tapping expiry date text opens DatePicker sheet
- [x] DatePicker sheet has graphical calendar, disclaimer text, Save/Cancel toolbar
- [x] NotificationClient has all 3 methods (requestAuthorization, authorizationStatus, registerForRemoteNotifications)
- [x] PantryReducer requests notification permission after first item add

## Key Learnings

**Computed Property Sorting Complexity**
Expiry-based sorting required handling 4 tuple cases (both dates, one date, neither date). Using Swift pattern matching on `(Date?, Date?)` tuple made the logic explicit and readable. Alternative approach (ternary operators) would be harder to maintain.

**SwiftUI Color Type in Model Layer**
Adding SwiftUI import to PantryItemState.swift breaks traditional layering (model shouldn't depend on view framework), but computed `expiryColor` property is acceptable for view-layer state representation. Alternative (expiryColorName: String) would push color mapping to view, adding indirection.

**DatePicker Sheet Binding Pattern**
Used `Binding(get:set:)` for `showDatePicker` to call `.datePickerDismissed` on sheet dismissal. Alternative (@Bindable with `.sending()`) would require datePickerDismissed to accept Bool parameter, adding unnecessary complexity.

**Notification Permission Timing**
Progressive disclosure after first item add matches CameraClient precedent (Phase 14-01) and LocationClient pattern. User understands value ("We'll remind you before this expires") at the moment of permission request. Alternative (request at app launch) results in low grant rates per iOS best practices.

## Open Items

None - all plan tasks completed, builds verified, no blockers encountered.

## Self-Check

Verifying task completion claims:

**Created files exist:**
```bash
[ -f "Kindred/Packages/PantryFeature/Sources/Notification/NotificationClient.swift" ] && echo "FOUND" || echo "MISSING"
```
Result: FOUND

**Modified files exist:**
```bash
[ -f "Kindred/Packages/PantryFeature/Sources/Models/PantryItemState.swift" ] && echo "FOUND" || echo "MISSING"
[ -f "Kindred/Packages/PantryFeature/Sources/Pantry/PantryReducer.swift" ] && echo "FOUND" || echo "MISSING"
[ -f "Kindred/Packages/PantryFeature/Sources/Pantry/PantryView.swift" ] && echo "FOUND" || echo "MISSING"
```
Result: FOUND (all 3 files)

**Commits exist:**
```bash
git log --oneline --all | grep -q "0a4b8aa" && echo "FOUND: 0a4b8aa" || echo "MISSING: 0a4b8aa"
git log --oneline --all | grep -q "bf8463b" && echo "FOUND: bf8463b" || echo "MISSING: bf8463b"
```
Result: FOUND (both commits)

**Commit messages:**
- 0a4b8aa: feat(17-02): add expiry status model, notification client, and pantry reducer actions
- bf8463b: feat(17-02): add expiry visual indicators, swipe actions, and date picker sheet

## Self-Check: PASSED

All files created/modified as claimed, both commits exist in git history, build succeeds.
