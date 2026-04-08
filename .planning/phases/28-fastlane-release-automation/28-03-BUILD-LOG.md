# Phase 28 Plan 03: Build Log

**Date:** 2026-04-08
**Status:** Build clean - Warnings only

## Toolchain

- **Xcode:** 26.4 (Build version 17E192)
- **iOS SDK:** iOS 26.4 (iphoneos26.4)
- **Swift:** Xcode default (Swift 6.x)
- **Deployment target:** iOS 17.0 (unchanged per CONTEXT.md)

## Criterion #5 Resolution

ROADMAP criterion #5: "Build uses Xcode 16 + iOS 26 SDK (verified via TestFlight upload)"
CONTEXT.md interpretation: Treat as "build with the latest available SDK" — literal iOS 26 not required if Xcode ships with a different minor version.
Actual build used: Xcode 26.4 with iOS 26.4 SDK → satisfies criterion.

## Build Command

```bash
cd Kindred && xcodebuild clean build \
  -scheme Kindred \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath .build/DerivedData \
  2>&1 | tee /tmp/kindred-28-03-build.log
```

**Result:** 0 (success)
**Build log location:** /tmp/kindred-28-03-build.log (ephemeral, recreated on rerun)

## Deprecation Warnings Summary

- **Pre-fix count:** 9
- **Fixed:** 3
- **Deferred:** 6
- **Post-fix count:** 6

## Triage Table

| # | File:Line | Warning | Bucket | Notes |
|---|-----------|---------|--------|-------|
| 1 | Packages/KindredAPI/Sources/Operations/Mutations/AnalyzeReceiptTextMutation.graphql.swift:35 | Argument 'userId' deprecated | DEFERRED | Apollo generated code - re-run codegen when upstream removes field |
| 2 | Packages/KindredAPI/Sources/Operations/Mutations/AnalyzeScanMutation.graphql.swift:35 | Argument 'userId' deprecated | DEFERRED | Apollo generated code - re-run codegen when upstream removes field |
| 3 | Packages/KindredAPI/Sources/Operations/Mutations/DeletePantryItemMutation.graphql.swift:35 | Argument 'userId' deprecated | DEFERRED | Apollo generated code - re-run codegen when upstream removes field |
| 4 | Packages/KindredAPI/Sources/Operations/Mutations/UpdatePantryItemMutation.graphql.swift:39 | Argument 'userId' deprecated | DEFERRED | Apollo generated code - re-run codegen when upstream removes field |
| 5 | Packages/KindredAPI/Sources/Operations/Mutations/UploadScanPhotoMutation.graphql.swift:39 | Argument 'userId' deprecated | DEFERRED | Apollo generated code - re-run codegen when upstream removes field |
| 6 | Packages/KindredAPI/Sources/Operations/Queries/PantryItemsQuery.graphql.swift:35 | Argument 'userId' deprecated | DEFERRED | Apollo generated code - re-run codegen when upstream removes field |
| 7 | Packages/PantryFeature/Sources/Camera/CameraManager.swift:57 | isHighResolutionCaptureEnabled deprecated in iOS 16 | NON-BLOCKING-FIX | Replaced with maxPhotoDimensions |
| 8 | Packages/PantryFeature/Sources/Scanning/ReceiptScannerView.swift:13 | WithPerceptionTracking deprecated in iOS 17 | NON-BLOCKING-FIX | Removed wrapper (not needed iOS 17+) |
| 9 | Packages/PantryFeature/Sources/Scanning/ScanResultsView.swift:14 | WithPerceptionTracking deprecated in iOS 17 | NON-BLOCKING-FIX | Removed wrapper (not needed iOS 17+) |

## Fixes Applied

### Fix 1: PantryFeature/Sources/Scanning/ReceiptScannerView.swift:13
**Before:**
```swift
public var body: some View {
    WithPerceptionTracking {
        ZStack(alignment: .bottom) {
            // ... content
        }
    }
}
```
**After:**
```swift
public var body: some View {
    ZStack(alignment: .bottom) {
        // ... content
    }
}
```
**Reason:** `WithPerceptionTracking` deprecated in iOS 17 with message "WithPerceptionTracking is no longer needed in iOS 17+". SwiftUI's observation system in iOS 17+ automatically tracks perception without explicit wrappers. Deployment target is iOS 17.0, so this is safe to remove.

### Fix 2: PantryFeature/Sources/Scanning/ScanResultsView.swift:14
**Before:**
```swift
public var body: some View {
    WithPerceptionTracking {
        ZStack(alignment: .bottom) {
            // ... content
        }
    }
}
```
**After:**
```swift
public var body: some View {
    ZStack(alignment: .bottom) {
        // ... content
    }
}
```
**Reason:** Same as Fix 1 - `WithPerceptionTracking` not needed on iOS 17+.

### Fix 3: PantryFeature/Sources/Camera/CameraManager.swift:57
**Before:**
```swift
// Add photo output
if self.session.canAddOutput(self.output) {
    self.session.addOutput(self.output)
    // Enable high-resolution photo capture
    self.output.isHighResolutionCaptureEnabled = true
}
```
**After:**
```swift
// Add photo output
if self.session.canAddOutput(self.output) {
    self.session.addOutput(self.output)
    // Enable high-resolution photo capture via maxPhotoDimensions
    if let maxDimensions = device.activeFormat.supportedMaxPhotoDimensions.max(by: { $0.width * $0.height < $1.width * $1.height }) {
        self.output.maxPhotoDimensions = maxDimensions
    }
}
```
**Reason:** `isHighResolutionCaptureEnabled` deprecated in iOS 16.0 with message "Use maxPhotoDimensions instead". Replacement uses `supportedMaxPhotoDimensions` to select the highest resolution available on the device's active format.

## Deferred Items

| File:Line | Warning | Reason Deferred | Future Phase |
|-----------|---------|-----------------|--------------|
| KindredAPI/Sources/Operations/Mutations/AnalyzeReceiptTextMutation.graphql.swift:35 | userId argument deprecated | Apollo generated code - should not hand-edit | Backend schema cleanup |
| KindredAPI/Sources/Operations/Mutations/AnalyzeScanMutation.graphql.swift:35 | userId argument deprecated | Apollo generated code - should not hand-edit | Backend schema cleanup |
| KindredAPI/Sources/Operations/Mutations/DeletePantryItemMutation.graphql.swift:35 | userId argument deprecated | Apollo generated code - should not hand-edit | Backend schema cleanup |
| KindredAPI/Sources/Operations/Mutations/UpdatePantryItemMutation.graphql.swift:39 | userId argument deprecated | Apollo generated code - should not hand-edit | Backend schema cleanup |
| KindredAPI/Sources/Operations/Mutations/UploadScanPhotoMutation.graphql.swift:39 | userId argument deprecated | Apollo generated code - should not hand-edit | Backend schema cleanup |
| KindredAPI/Sources/Operations/Queries/PantryItemsQuery.graphql.swift:35 | userId argument deprecated | Apollo generated code - should not hand-edit | Backend schema cleanup |

**Context:** All 6 deferred items are GraphQL API deprecations in Apollo-generated files. The backend GraphQL schema marked `userId` arguments as deprecated (reason: "Derived from auth token"). These warnings will resolve when:
1. Backend removes the deprecated `userId` fields from the schema
2. GraphQL operation files (.graphql) are updated to remove userId arguments
3. Apollo iOS codegen is re-run to regenerate the .graphql.swift files

These are backend API evolution warnings, not iOS SDK deprecations. Safe to defer - the fields still work, and hand-editing generated code would be overwritten on next codegen run.

## Decision for Submission

All blocking-fix items resolved. Deferred items are non-blocking (backend API deprecations in generated code, not iOS SDK errors). Safe to proceed to Plan 28-04 beta upload.

**Post-fix build:** Exit code 0, no new errors introduced, deprecation count reduced from 9 to 6.
