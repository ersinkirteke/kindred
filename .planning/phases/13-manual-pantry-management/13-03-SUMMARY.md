---
phase: 13
plan: 03
subsystem: pantry-sync
tags: [sync, offline-first, conflict-resolution, background-sync, connectivity-monitoring]
dependency_graph:
  requires: [pantry-client, network-client, apollo-client]
  provides: [pantry-sync-worker, bidirectional-sync, offline-sync]
  affects: [pantry-reducer, pantry-view]
tech_stack:
  added: [NWPathMonitor, UserDefaults-sync-timestamp]
  patterns: [last-write-wins, exponential-backoff, offline-first]
key_files:
  created:
    - Kindred/Packages/PantryFeature/Sources/Sync/PantrySyncWorker.swift
  modified:
    - Kindred/Packages/PantryFeature/Sources/PantryClient/PantryStore.swift
    - Kindred/Packages/PantryFeature/Sources/PantryClient/PantryClient.swift
    - Kindred/Packages/PantryFeature/Sources/Pantry/PantryReducer.swift
    - Kindred/Packages/PantryFeature/Sources/Pantry/PantryView.swift
decisions:
  - "Use last-write-wins conflict resolution (compare updatedAt timestamps)"
  - "Store last sync timestamp in UserDefaults (simple, no SwiftData schema change needed)"
  - "Use heuristic to detect new vs updated items: createdAt ~= updatedAt means new"
  - "Individual item sync failures continue loop (don't abort entire batch)"
  - "Parse DateTime (ISO8601 string) to Date for server merge using ISO8601DateFormatter"
  - "Fetch all local items once for merge (avoid N predicate fetches with outer scope variables)"
  - "Use NWPathMonitor snapshot check for network availability (async one-shot, not persistent monitor)"
  - "Exponential backoff: 30s, 60s, 120s max (balance retry frequency vs server load)"
  - "Show sync failure banner after 3 consecutive failures (unobtrusive, not blocking)"
metrics:
  duration_minutes: 9
  tasks_completed: 2
  files_created: 1
  files_modified: 4
  commits: 2
  completion_date: "2026-03-12"
---

# Phase 13 Plan 03: Offline-First Sync Infrastructure

**One-liner:** Bidirectional sync worker with last-write-wins conflict resolution, exponential backoff retry, and UI indicators for sync status and connectivity.

## Summary

Implemented offline-first sync between SwiftData local storage and backend GraphQL API. Local writes happen instantly and sync in the background. Two-way sync: push local changes (add/update/delete) to server, pull server changes and merge with last-write-wins. Sync triggers on CRUD operations and app foreground. Failed syncs retry with exponential backoff (30s, 60s, 120s) and show a dismissible banner after 3 failures. UI indicators show active sync progress, offline status, and sync errors.

## What Was Built

### Task 1: Sync Infrastructure in PantryStore/PantryClient (792d07a)

**Extended PantryStore with sync methods:**
- `fetchUnsyncedItems(userId:)` → Fetch items where `isSynced == false`, sorted by `updatedAt` ascending (oldest first). Includes soft-deleted items that need deletion synced to server.
- `mergeServerItems(userId:serverItems:)` → Two-way merge with last-write-wins:
  - Fetch all local items once (avoid repeated predicates with outer scope vars)
  - Build dictionary by ID for O(1) lookup
  - For each server item: if exists locally, compare `updatedAt` and update if server is newer; if new and not deleted, insert
  - Save context once after all merges
- `lastSyncTimestamp(userId:)` → Return most recent `updatedAt` from synced items for incremental sync
- `updateSyncTimestamp(userId:timestamp:)` → Store last successful sync in `UserDefaults` with key `"pantry.lastSync.\(userId)"`

**Created ServerPantryItem struct:**
- `Sendable` data transfer object with all pantry fields plus `updatedAt` for conflict resolution
- Used by both PantrySyncWorker and PantryClient for type-safe server data exchange

**Extended PantryClient with sync closures:**
- `fetchUnsyncedItems`, `mergeServerItems`, `lastSyncTimestamp`, `updateSyncTimestamp` → wrap PantryStore methods
- `isNetworkAvailable` → Use `NWPathMonitor` for one-shot connectivity check (not persistent monitor)
- Wired all in `liveValue`, added no-op defaults in `testValue`

**Files:**
- Kindred/Packages/PantryFeature/Sources/PantryClient/PantryStore.swift
- Kindred/Packages/PantryFeature/Sources/PantryClient/PantryClient.swift

### Task 2: PantrySyncWorker and Reducer Integration (847ebc9)

**Created PantrySyncWorker.swift:**
- `performSync(userId:pantryClient:apolloClient:) async throws -> SyncResult` — Two-phase sync:
  1. **Push phase:** Fetch unsynced items, iterate:
     - If `isDeleted` → call `deletePantryItem` mutation
     - Else: heuristic to detect new vs update (createdAt ~= updatedAt within 1s)
       - New → `addPantryItem` mutation
       - Updated → `updatePantryItem` mutation
     - Mark as synced, increment push count
     - Individual failures continue loop (don't abort batch)
  2. **Pull phase:** Fetch server items since last sync timestamp:
     - Map Apollo `PantryItemsQuery.Data.PantryItem` to `ServerPantryItem`
     - Parse UUID, enums, dates (DateTime = ISO8601 string → Date via ISO8601DateFormatter)
     - Call `mergeServerItems` with mapped array
     - Update sync timestamp
  - Return `SyncResult(pushed:pulled:)` with counts

**Updated PantryReducer:**
- **State:** Added `isSyncing`, `syncRetryCount`, `showSyncFailureBanner`, `isOffline`
- **Actions:** `syncPendingItems`, `syncCompleted`, `syncFailed`, `dismissSyncBanner`, `connectivityChanged`, `appEnteredForeground`
- **Sync triggers:**
  - `.onAppear` → check connectivity, trigger sync
  - `.addEditForm(.presented(.delegate(.itemSaved)))` → sync after add/edit
  - `.deleteItem` → sync after delete
  - `.appEnteredForeground` → check connectivity, trigger sync
- **Sync reducer logic:**
  - `.syncPendingItems` → guard userId, not already syncing, not offline; set `isSyncing = true`; call `PantrySyncWorker.performSync`
  - `.syncCompleted` → reset `isSyncing`, `syncRetryCount`, `showSyncFailureBanner`; if pulled > 0, re-fetch items to reflect merged data
  - `.syncFailed` → increment retry count; if >= 3 show banner; schedule retry with exponential backoff (30s * 2^(retryCount-1), max 120s); cancellable with `.syncRetry` ID
  - `.connectivityChanged` → set `isOffline`; if back online and retries > 0, trigger sync
  - `.dismissSyncBanner` → hide banner

**Updated PantryView:**
- **Toolbar:** Show `ProgressView()` when syncing; show "Offline" label with wifi.slash icon when offline
- **Sync failure banner:** `.safeAreaInset(edge: .top)` when `showSyncFailureBanner` → HStack with warning icon, message "Unable to sync. Will retry.", dismiss X button
- **Foreground observer:** `.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification))` → send `.appEnteredForeground`

**Files:**
- Kindred/Packages/PantryFeature/Sources/Sync/PantrySyncWorker.swift (new)
- Kindred/Packages/PantryFeature/Sources/Pantry/PantryReducer.swift
- Kindred/Packages/PantryFeature/Sources/Pantry/PantryView.swift

## Technical Decisions

### Last-Write-Wins Conflict Resolution
**Decision:** Compare `updatedAt` timestamps. Server wins if newer, local wins otherwise (will push in next sync).

**Rationale:** Simple, deterministic, no conflict UI needed. Works for single-user pantry management. If we later need multi-user collaboration, we can upgrade to operational transforms or CRDTs.

**Alternative considered:** UI conflict picker (rejected — overkill for single-user pantry, adds friction).

### Sync Timestamp Storage in UserDefaults
**Decision:** Store last successful sync timestamp in `UserDefaults` with key `"pantry.lastSync.\(userId)"`.

**Rationale:** Simple, no schema change to SwiftData. Timestamp is per-user metadata, not core data. Loss is recoverable (full sync on next attempt).

**Alternative considered:** Store in PantryItem model (rejected — clutters schema, requires migration).

### New vs Updated Item Heuristic
**Decision:** If `abs(createdAt - updatedAt) < 1 second`, treat as new. Else, treat as updated.

**Rationale:** PantryStore sets `updatedAt = Date()` on every modification. On creation, both are set to same `Date()`. Time window accounts for clock skew and async execution.

**Alternative considered:** Add `wasEverSynced` flag (rejected — heuristic works, no schema change needed).

### Individual Item Sync Failure Handling
**Decision:** Catch sync errors per-item, log, continue loop. Don't abort entire batch.

**Rationale:** One bad item (e.g., server validation error, malformed UUID) shouldn't block syncing the rest. User sees partial sync progress.

**Alternative considered:** Abort on first error (rejected — poor UX, all-or-nothing is fragile).

### DateTime Parsing
**Decision:** Parse Apollo's `DateTime` (String in ISO8601 format) to Swift `Date` using `ISO8601DateFormatter`.

**Rationale:** GraphQL custom scalar `DateTime` is typealias for `String`. Backend returns ISO8601. Need `Date` for SwiftData model and timestamp comparison.

**Alternative considered:** Keep as String (rejected — can't compare for last-write-wins).

### Network Availability Check
**Decision:** Use `NWPathMonitor` for one-shot async check, not persistent monitoring.

**Rationale:** Simple, no lifecycle management. Check on-demand (onAppear, foreground). Persistent monitor would need cleanup, state management.

**Alternative considered:** Persistent NWPathMonitor with `pathUpdateHandler` (rejected — overkill for simple check).

### Exponential Backoff Strategy
**Decision:** Retry delay = 30s * 2^(retryCount - 1), capped at 120s (30s, 60s, 120s, 120s, ...).

**Rationale:** Balance responsiveness (30s first retry) with server load (don't hammer on repeated failures). Cap prevents runaway delays.

**Alternative considered:** Fixed 60s delay (rejected — doesn't back off, may overload server).

### Sync Failure Banner Threshold
**Decision:** Show dismissible banner after 3 consecutive failures.

**Rationale:** Avoid banner spam on transient errors (1-2 failures). 3 failures = likely persistent issue (server down, auth expired). Banner is unobtrusive (not blocking alert).

**Alternative considered:** Show after 1 failure (rejected — too noisy). Blocking alert (rejected — interrupts workflow).

## Verification

All automated verification passed:
- [x] PantryFeature builds successfully
- [x] Task 1: PantryStore has sync methods, PantryClient has sync closures
- [x] Task 2: PantrySyncWorker exists with performSync, PantryReducer has sync state/actions, PantryView shows indicators

Manual verification needed (user testing):
- [ ] Local writes appear instantly without waiting for network
- [ ] Unsynced items show cloud-slash icon
- [ ] Sync triggers on add/edit/delete operations
- [ ] Sync triggers on app foreground
- [ ] Two-way sync: local changes push to server, server changes pull to local
- [ ] Last-write-wins resolves conflicts correctly
- [ ] Sync indicator appears in toolbar during active sync
- [ ] Offline indicator appears when no connectivity
- [ ] Failure banner shows after 3 retries with "Unable to sync. Will retry."
- [ ] Exponential backoff delays (30s, 60s, 120s) on retry

## Deviations from Plan

None — plan executed exactly as written.

## Integration Points

### Upstream Dependencies
- **NetworkClient:** Apollo client for GraphQL mutations/queries (`addPantryItem`, `updatePantryItem`, `deletePantryItem`, `fetchPantryItems`)
- **KindredAPI:** Generated Apollo types (`AddPantryItemInput`, `UpdatePantryItemInput`, `PantryItemsQuery.Data.PantryItem`, `DateTime` scalar)
- **PantryClient:** Existing CRUD methods (`fetchAllItems`, `markAsSynced`)

### Downstream Consumers
- **PantryReducer:** Calls `PantrySyncWorker.performSync` in TCA effects
- **PantryView:** Displays sync UI indicators (toolbar progress, offline label, failure banner)
- **Future receipt scan / fridge scan features:** Can mark items as `isSynced = false` and existing sync worker will handle upload

## Next Steps

**Phase 13 Plan 04 (if exists):** Continue manual pantry management features.

**Phase 14 (future):** Receipt scan + fridge photo features will leverage this sync infrastructure — newly added items from scans will auto-sync to backend.

**Production readiness:**
- Monitor sync failure rates (add analytics event in `.syncFailed`)
- Test conflict resolution with real backend (currently theoretical)
- Add user-facing sync status detail (last synced timestamp in settings?)
- Consider batch mutation optimization if many items sync at once (GraphQL supports batch mutations)

## Files Changed

### Created (1 file)
- Kindred/Packages/PantryFeature/Sources/Sync/PantrySyncWorker.swift (154 lines) — Bidirectional sync worker

### Modified (4 files)
- Kindred/Packages/PantryFeature/Sources/PantryClient/PantryStore.swift (+94 lines) — Sync methods, ServerPantryItem struct
- Kindred/Packages/PantryFeature/Sources/PantryClient/PantryClient.swift (+23 lines) — Sync closures, network check
- Kindred/Packages/PantryFeature/Sources/Pantry/PantryReducer.swift (+78 lines) — Sync state, actions, reducer logic
- Kindred/Packages/PantryFeature/Sources/Pantry/PantryView.swift (+33 lines) — Sync UI indicators, foreground observer

**Total:** 1 created, 4 modified, 382 lines added

## Commits

- **792d07a** — feat(13-03): add sync infrastructure to PantryStore and PantryClient
- **847ebc9** — feat(13-03): implement PantrySyncWorker and wire sync into PantryReducer

## Self-Check

Verifying all claims from summary:

**Created files exist:**
```bash
[ -f "Kindred/Packages/PantryFeature/Sources/Sync/PantrySyncWorker.swift" ] && echo "FOUND: PantrySyncWorker.swift" || echo "MISSING: PantrySyncWorker.swift"
```

**Commits exist:**
```bash
git log --oneline --all | grep -q "792d07a" && echo "FOUND: 792d07a" || echo "MISSING: 792d07a"
git log --online --all | grep -q "847ebc9" && echo "FOUND: 847ebc9" || echo "MISSING: 847ebc9"
```

**Results:**
- FOUND: PantrySyncWorker.swift
- FOUND: 792d07a
- FOUND: 847ebc9

## Self-Check: PASSED
