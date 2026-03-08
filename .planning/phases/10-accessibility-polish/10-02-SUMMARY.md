---
phase: 10-accessibility-polish
plan: 02
subsystem: app-infrastructure
tags:
  - connectivity
  - performance
  - background-tasks
  - voiceover
dependency_graph:
  requires:
    - FeedFeature/NetworkMonitorClient (reused existing TCA dependency)
    - DesignSystem/OfflineBanner (created in 10-01)
  provides:
    - AppReducer.isOffline (shared connectivity state)
    - Logger extensions (appLifecycle, performance, background)
    - MetricKit production monitoring
    - BGAppRefreshTask (15-min recipe refresh)
  affects:
    - RootView (shows OfflineBanner)
    - FeedReducer (receives refreshFeed on reconnect)
tech_stack:
  added:
    - MetricKit (performance monitoring)
    - BackgroundTasks (BGAppRefreshTask)
    - OSLog (Logger for production logging)
  patterns:
    - TCA shared state (isOffline flows from AppReducer)
    - AsyncStream connectivity monitoring
    - VoiceOver announcements via UIAccessibility.post
key_files:
  created: []
  modified:
    - Kindred/Sources/App/AppReducer.swift (connectivity state + actions)
    - Kindred/Sources/App/RootView.swift (OfflineBanner integration)
    - Kindred/Sources/App/AppDelegate.swift (MetricKit + BGTaskScheduler)
    - Kindred/Sources/Info.plist (BGTaskSchedulerPermittedIdentifiers + fetch mode)
    - Kindred/Packages/DesignSystem/Sources/DesignSystem.swift (export OfflineBanner)
decisions:
  - title: "Reuse NetworkMonitorClient from FeedFeature"
    rationale: "Already a TCA dependency providing connectivity stream - no need to duplicate"
    alternatives: "Create new AppNetworkMonitor"
    outcome: "Clean dependency reuse, minimal code"
  - title: "15-minute BGAppRefreshTask interval"
    rationale: "Balances freshness with battery life per iOS best practices"
    alternatives: "5 min (too aggressive), 1 hour (stale content)"
    outcome: "Placeholder scheduled, actual fetch depends on Apollo client availability"
  - title: "MetricKit histogram bucket counts instead of averages"
    rationale: "MXHistogram API doesn't expose average - totalBucketCount indicates distribution"
    alternatives: "Iterate histogram buckets for custom calculation"
    outcome: "Simple logging, sufficient for production monitoring"
metrics:
  duration_minutes: 16
  completed_date: "2026-03-08"
  tasks_completed: 2
  files_modified: 5
  commits:
    - hash: 595f653
      message: "feat(10-02): add shared connectivity state with VoiceOver announcements"
    - hash: 349377a
      message: "feat(10-02): integrate MetricKit, BGAppRefreshTask, and Logger"
---

# Phase 10 Plan 02: App-level Infrastructure Summary

**One-liner:** App-level connectivity state with VoiceOver announcements, MetricKit production monitoring, and background recipe refresh.

## What Was Built

**Task 1: Shared connectivity state with VoiceOver announcements**

- Added `isOffline: Bool` to `AppReducer.State`
- Created `startConnectivityMonitor` and `connectivityChanged(Bool)` actions
- Integrated `NetworkMonitorClient` dependency (reused from FeedFeature)
- VoiceOver announces "You're offline" / "Back online" on connectivity changes via `UIAccessibility.post`
- Auto-refresh feed when connectivity returns (sends `.feed(.refreshFeed)`)
- RootView shows `OfflineBanner` at top when offline
- Exported `OfflineBanner` from DesignSystem package (component created in 10-01)

**Task 2: MetricKit, BGAppRefreshTask, and Logger**

- AppDelegate conforms to `MXMetricManagerSubscriber`
- Implemented `didReceive(_ payloads: [MXMetricPayload])`:
  - Logs launch time histogram buckets
  - Logs hang histogram buckets
  - Logs abnormal exit counts (background + foreground)
- Implemented `didReceive(_ payloads: [MXDiagnosticPayload])`:
  - Logs crash diagnostics
  - Logs hang diagnostics
- Registered BGAppRefreshTask with identifier `com.ersinkirteke.kindred.recipe-refresh`
- Background refresh scheduled on `applicationDidEnterBackground` (15-minute interval)
- Created `Logger` extensions:
  - `Logger.appLifecycle` (app lifecycle events)
  - `Logger.performance` (MetricKit data)
  - `Logger.background` (background task execution)
- Info.plist updated:
  - Added `BGTaskSchedulerPermittedIdentifiers` array
  - Added `fetch` to `UIBackgroundModes`
- All logging uses `Logger` (no print statements remain)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed incorrect FeedReducer action name**
- **Found during:** Build verification after Task 1
- **Issue:** Used `.feed(.fetchRecipes)` but FeedReducer.Action doesn't have that case
- **Fix:** Changed to `.feed(.refreshFeed)` (correct action name)
- **Files modified:** `Kindred/Sources/App/AppReducer.swift`
- **Commit:** 349377a (amended Task 2 commit)

**2. [Rule 1 - Bug] Fixed MetricKit histogram API usage**
- **Found during:** Build verification after Task 2
- **Issue:** `MXHistogram<UnitDuration>` doesn't have `.average` property - tried to use non-existent API
- **Fix:** Use `.totalBucketCount` instead to log histogram distribution
- **Files modified:** `Kindred/Sources/App/AppDelegate.swift`
- **Commit:** 349377a (amended Task 2 commit)

## Verification

**Automated checks:**
- ✅ AppReducer.State has `isOffline: Bool` property
- ✅ AppReducer handles `.connectivityChanged` with VoiceOver announcement
- ✅ RootView shows OfflineBanner when isOffline
- ✅ AppDelegate conforms to MXMetricManagerSubscriber
- ✅ Info.plist has BGTaskSchedulerPermittedIdentifiers
- ✅ No print() statements remain in AppDelegate
- ✅ Project builds successfully (BUILD SUCCEEDED on device)

**Manual verification needed:**
- VoiceOver announcement behavior (requires device with VoiceOver enabled)
- MetricKit payloads (only delivered in production after 24 hours)
- Background refresh task (requires background launch simulation)

## Integration Points

**Upstream dependencies:**
- NetworkMonitorClient from FeedFeature (AsyncStream<Bool> connectivity updates)
- OfflineBanner from DesignSystem (created in 10-01)

**Downstream consumers:**
- All child features can observe `AppReducer.State.isOffline`
- FeedReducer receives `.refreshFeed` when connectivity returns
- MetricKit data will be available in production builds via Xcode Organizer

**Future work:**
- Implement actual Apollo GraphQL fetch in `handleRecipeRefresh` (currently placeholder)
- Add MPNowPlayingInfoCenter lock screen controls (Phase 10 plan 03)
- Implement offline cache fallback UX (future accessibility plan)

## Self-Check: PASSED

**Created files:**
- None (all created files were from 10-01)

**Modified files exist:**
- ✅ FOUND: Kindred/Sources/App/AppReducer.swift
- ✅ FOUND: Kindred/Sources/App/RootView.swift
- ✅ FOUND: Kindred/Sources/App/AppDelegate.swift
- ✅ FOUND: Kindred/Sources/Info.plist
- ✅ FOUND: Kindred/Packages/DesignSystem/Sources/DesignSystem.swift

**Commits exist:**
- ✅ FOUND: 595f653 (Task 1)
- ✅ FOUND: 349377a (Task 2)

All claims verified. Plan execution complete.
