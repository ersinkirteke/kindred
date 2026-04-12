---
phase: 28-fastlane-release-automation
plan: 03
subsystem: build-toolchain
tags: [xcode, deprecations, ios-sdk, release-build]
dependency_graph:
  requires: []
  provides: [sdk-version-documentation, deprecation-triage, clean-release-build]
  affects: [28-04-beta-upload]
tech_stack:
  added: []
  patterns: [maxPhotoDimensions-migration, perception-tracking-removal]
key_files:
  created:
    - .planning/phases/28-fastlane-release-automation/28-03-BUILD-LOG.md
  modified:
    - Kindred/Packages/PantryFeature/Sources/Camera/CameraManager.swift
    - Kindred/Packages/PantryFeature/Sources/Scanning/ReceiptScannerView.swift
    - Kindred/Packages/PantryFeature/Sources/Scanning/ScanResultsView.swift
decisions:
  - Defer Apollo generated code warnings (backend schema deprecations, not iOS SDK issues)
  - Use maxPhotoDimensions with max resolution selection instead of isHighResolutionCaptureEnabled
  - Remove WithPerceptionTracking wrappers (not needed on iOS 17+ deployment target)
metrics:
  duration_minutes: 16
  completed_date: "2026-04-08"
  tasks_completed: 2
  files_modified: 4
  deprecations_fixed: 3
  deprecations_deferred: 6
---

# Phase 28 Plan 03: SDK Version & Deprecation Cleanup Summary

**One-liner:** Xcode 26.4 + iOS SDK 26.4 build verified clean; fixed 3 iOS deprecations (WithPerceptionTracking, isHighResolutionCaptureEnabled); deferred 6 Apollo backend schema warnings

## What Was Built

Detected build toolchain versions, ran clean Release build, triaged 9 deprecation warnings, fixed 3 non-blocking iOS SDK deprecations, and documented 6 deferred backend API warnings in Apollo generated code.

**Toolchain verified:**
- Xcode 26.4 (Build 17E192)
- iOS SDK 26.4 (iphoneos26.4)
- Swift 6.x (Xcode default)
- Deployment target: iOS 17.0 (unchanged per CONTEXT.md)

**Criterion #5 satisfied:** "Build uses Xcode 16 + iOS 26 SDK" - Xcode 26.4 with iOS 26.4 SDK meets requirement.

**Deprecation triage:**
- Pre-fix: 9 warnings
- Fixed: 3 (iOS SDK deprecations)
- Deferred: 6 (Apollo generated code, backend schema deprecations)
- Post-fix: 6 warnings (all non-blocking)

**Build outcome:** Exit code 0 (success) on both pre-fix and post-fix builds. Safe to proceed to Plan 28-04 beta upload.

## Tasks Completed

### Task 1: Capture Xcode/SDK versions and run Release build
**Duration:** ~5 minutes
**Outcome:** Clean build, toolchain documented

- Detected Xcode 26.4 + iOS SDK 26.4
- Ran clean Release build: exit code 0
- Created 28-03-BUILD-LOG.md with toolchain info
- Captured full build log at /tmp/kindred-28-03-build.log
- Satisfies ROADMAP criterion #5 (Xcode 16 + iOS 26 SDK)

**Commit:** 23e96d2

### Task 2: Triage deprecation warnings, fix fixable ones, defer the rest
**Duration:** ~11 minutes
**Outcome:** 3 iOS SDK deprecations fixed, 6 backend warnings deferred

- Extracted 9 unique deprecation warnings from build log
- Triaged into buckets: 3 NON-BLOCKING-FIX, 6 DEFERRED
- Applied 3 fixes (all mechanical, low-risk):
  1. Removed `WithPerceptionTracking` from ReceiptScannerView (iOS 17+ doesn't need it)
  2. Removed `WithPerceptionTracking` from ScanResultsView (iOS 17+ doesn't need it)
  3. Replaced `isHighResolutionCaptureEnabled` with `maxPhotoDimensions` in CameraManager (iOS 16 deprecation)
- Re-ran build: 6 warnings (down from 9), no new errors
- All remaining warnings are Apollo generated code (backend schema deprecations)
- Updated 28-03-BUILD-LOG.md with triage table, fixes, deferred items, and decision

**Commit:** baf522e

## Deviations from Plan

None - plan executed exactly as written.

## Decisions Made

### 1. Defer Apollo generated code warnings
**Context:** 6/9 deprecation warnings were in Apollo-generated GraphQL files (.graphql.swift) for deprecated `userId` arguments.

**Decision:** DEFERRED - do not hand-edit generated code. These are backend schema deprecations (userId is "Derived from auth token"). Will resolve when backend removes the deprecated fields and Apollo codegen is re-run.

**Rationale:** Generated files should not be hand-edited (changes get overwritten on next codegen run). These are backend API evolution warnings, not iOS SDK errors. Fields still work, no submission risk.

**Impact:** 6 warnings remain in post-fix build, all non-blocking.

### 2. Use maxPhotoDimensions with max resolution selection
**Context:** `isHighResolutionCaptureEnabled` deprecated in iOS 16 with replacement API `maxPhotoDimensions`.

**Decision:** Select highest supported photo dimensions via `device.activeFormat.supportedMaxPhotoDimensions.max(by: { $0.width * $0.height < $1.width * $1.height })`.

**Rationale:** Direct 1:1 migration path documented in Apple deprecation message. Behavior equivalent (capture at maximum resolution), API modernized.

**Impact:** CameraManager.swift modified, 1 deprecation warning resolved.

### 3. Remove WithPerceptionTracking wrappers
**Context:** TCA's `WithPerceptionTracking` deprecated in iOS 17+ with message "WithPerceptionTracking is no longer needed in iOS 17+".

**Decision:** Remove wrapper from ReceiptScannerView and ScanResultsView bodies.

**Rationale:** Deployment target is iOS 17.0. SwiftUI's observation system in iOS 17+ automatically tracks perception without explicit wrappers. Mechanical removal, no behavior change.

**Impact:** 2 SwiftUI views simplified, 2 deprecation warnings resolved.

## Verification

- [x] `.planning/phases/28-fastlane-release-automation/28-03-BUILD-LOG.md` exists and documents Xcode + iOS SDK versions
- [x] `/tmp/kindred-28-03-build.log` exists (pre-fix) and `/tmp/kindred-28-03-build-post-fix.log` exists (post-fix)
- [x] Release build succeeds with exit code 0 (both pre-fix and post-fix)
- [x] BUILD-LOG.md contains Triage Table, Fixes Applied, Deferred Items, Decision for Submission sections
- [x] Swift source files modified to fix deprecations are listed in git diff and cross-referenced in BUILD-LOG.md
- [x] Post-fix deprecation count (6) ≤ pre-fix count (9)

## Self-Check: PASSED

**Created files:**
```bash
# .planning/phases/28-fastlane-release-automation/28-03-BUILD-LOG.md
$ test -f .planning/phases/28-fastlane-release-automation/28-03-BUILD-LOG.md && echo "FOUND: 28-03-BUILD-LOG.md"
FOUND: 28-03-BUILD-LOG.md
```

**Commits:**
```bash
$ git log --oneline --grep="28-03" -2
baf522e fix(28-03): resolve 3 iOS SDK deprecation warnings
23e96d2 feat(28-03): capture Xcode 26.4 and iOS 26.4 SDK versions
```

All artifacts verified. Build log exists, commits exist, deprecation count reduced, no new errors introduced.

## Next Steps

Plan 28-04 can proceed with beta_internal upload. SDK version documented (Xcode 26.4 + iOS 26.4), build is clean (exit 0), all blocking deprecations resolved. Deferred Apollo warnings are backend schema issues that will resolve when backend updates GraphQL schema.

**Handoff to Plan 28-04:**
- SDK version: iOS 26.4 (satisfies criterion #5)
- Build state: Clean (6 non-blocking deferred warnings, all in generated code)
- Build log location: /tmp/kindred-28-03-build-post-fix.log (or re-run build for fresh log)
- Decision: Safe to upload beta build to TestFlight
