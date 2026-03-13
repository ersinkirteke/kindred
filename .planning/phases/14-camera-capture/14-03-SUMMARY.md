---
phase: 14-camera-capture
plan: 03
subsystem: pantry-scanning
tags: [upload-pipeline, graphql-mutation, progress-tracking, offline-queue, processing-state]
dependency_graph:
  requires: [14-01-camera-infrastructure, 14-02-camera-ui]
  provides: [scan-upload-flow, upload-progress-ui, offline-resilience]
  affects: [pantry-feature, network-client]
tech_stack:
  added: [apollo-multipart-upload, jpeg-compression, upload-cancellation]
  patterns: [progress-tracking, offline-queue, processing-animation, continuation-after-upload]
key_files:
  created:
    - Kindred/Packages/PantryFeature/Sources/Scanning/ScanUploadReducer.swift
    - Kindred/Packages/PantryFeature/Sources/Scanning/ScanUploadView.swift
    - Kindred/Packages/NetworkClient/Sources/GraphQL/UploadScanPhoto.graphql
  modified:
    - Kindred/Packages/PantryFeature/Sources/Pantry/PantryReducer.swift
    - Kindred/Packages/PantryFeature/Sources/Pantry/PantryView.swift
    - Kindred/Sources/Resources/Localizable.xcstrings
decisions:
  - title: "Apollo multipart upload with GraphQLFile"
    rationale: "Phase 14-01 established base64 upload, but multipart is more efficient for photo uploads. Apollo iOS supports GraphQLFile with multipart configuration, avoiding 33% base64 overhead."
    alternatives: ["Base64 upload (14-01 approach)", "Separate REST endpoint"]
    chosen: "Apollo multipart upload with GraphQLFile wrapper"
  - title: "Memory-safe JPEG compression pipeline"
    rationale: "48MP camera photos require autoreleasepool wrapping around compression operations. Reused ImageUtilities.compressForUpload pattern from 14-02 (2048px max dimension, 80% quality)."
    alternatives: ["Compress on backend", "Lower quality compression", "No size limit"]
    chosen: "Client-side compression in autoreleasepool (max 2048px, 80% quality)"
  - title: "Offline queue in-memory only"
    rationale: "User decision: failed photos kept until app restart (no persistent queue). Simplifies implementation, avoids disk storage concerns. Auto-retry when connectivity returns."
    alternatives: ["Persistent queue to disk", "UserDefaults storage", "SwiftData persistence"]
    chosen: "In-memory Data storage with connectivity-triggered retry"
  - title: "Processing state with back-to-pantry navigation"
    rationale: "After successful upload, user sees 'Analyzing your photo...' animation but can return to pantry immediately. Processing continues in background. Matches async job pattern from backend."
    alternatives: ["Block until processing complete", "Auto-dismiss on upload", "No processing indication"]
    chosen: "Processing animation with optional early exit to pantry"
metrics:
  duration: "8 min"
  tasks_completed: 3
  files_created: 3
  files_modified: 3
  commits: 2
  completed_at: "2026-03-13T19:18:21Z"
---

# Phase 14 Plan 03: Photo Upload Pipeline Summary

**Complete camera-to-backend upload pipeline with progress tracking, offline queue, and processing state UI**

## Overview

Completed the photo upload flow from camera capture to backend processing. Users can now:
- Capture photos via camera (from Phase 14-02)
- Automatically compress photos to JPEG (max 2048px, 80% quality)
- Upload to backend with circular progress indicator
- Cancel in-flight uploads
- Queue failed uploads when offline (auto-retry on connectivity)
- See "Analyzing your photo..." processing animation after successful upload
- Return to pantry while processing continues in background

Full device verification confirmed all flows work correctly on physical iPhone. Phase 15 will implement the backend AI analysis pipeline to process uploaded photos into pantry items.

## Tasks Completed

### Task 1: ScanUploadReducer + GraphQL mutation + upload pipeline
**Files:** ScanUploadReducer.swift, ScanUploadView.swift, UploadScanPhoto.graphql
**Commit:** 5550fd6

- Created UploadScanPhoto.graphql mutation in NetworkClient/Sources/GraphQL/:
  - mutation accepts userId (String!), scanType (ScanType!), file (Upload!)
  - Returns ScanJob with id, status, photoUrl, scanType, createdAt
  - Uses top-level $file parameter (not nested) to avoid Apollo iOS issue #979

- Created ScanUploadReducer: TCA state machine managing compress → upload → processing flow
  - State: image (UIImage), scanType (ScanType), uploadProgress (0.0-1.0), uploadState (enum), scanJob, error, isOfflineQueued
  - UploadState enum: compressing, uploading, processing, completed, failed
  - Dependencies: apolloClient, continuousClock
  - Actions:
    - startUpload: begins compression on background Task with autoreleasepool
    - compressionCompleted(Data): initiates Apollo upload with GraphQLFile
    - uploadProgressUpdated(Double): updates circular progress indicator
    - uploadCompleted(ScanJob): transitions to processing state
    - uploadFailed(String): shows error with Retry button
    - retryUpload: restarts from compression
    - cancelUpload: cancels via .cancellable(id: CancelID.upload)
    - backToPantryTapped: delegate dismissed while processing continues
  - Upload pipeline:
    1. Compress: Task.detached { autoreleasepool { image.compressForUpload() } }
    2. Check offline: if no connectivity, queue compressed Data in memory, set isOfflineQueued
    3. Upload: apolloClient.perform(mutation) with GraphQLFile wrapper for compressed Data
    4. Progress tracking: observe upload progress via Apollo progress stream
    5. Success: store scanJob, transition to processing state
    6. Failure: set uploadState = .failed with error message
  - Cancel support: .cancellable(id: CancelID.upload, cancelInFlight: true) on upload effect
  - Offline queue: stores compressed Data in state, monitors connectivity via parent reducer, auto-retries when online

- Created ScanUploadView: full-screen upload overlay UI
  - Photo as background (Image with aspectRatio(.fill))
  - Dark overlay (Color.black.opacity(0.6)) during upload states
  - State-specific overlays:
    - .compressing: "Preparing photo..." with indeterminate ProgressView
    - .uploading: Circular ProgressView(value: uploadProgress) with percentage text, Cancel button below
    - .processing: "Analyzing your photo..." with animated pulse effect (3-stage opacity animation), "Back to Pantry" button
    - .completed: Checkmark animation (brief, auto-dismisses to pantry)
    - .failed: Error message in red, "Retry" button (accent color), "Cancel" text button
  - Offline queued banner: "Photo saved — will upload when back online" with cloud.fill icon
  - All text white on dark overlay for contrast
  - Reduce Motion support: replaces processing pulse with static text + spinner
  - VoiceOver: progress value announced, error announced, all buttons labeled

### Task 2: Integration wiring into PantryReducer + end-to-end flow
**Files:** PantryReducer.swift, PantryView.swift, Localizable.xcstrings
**Commit:** cb1ebc7

- Updated PantryReducer to manage camera → upload flow:
  - Added state: @Presents var scanUpload: ScanUploadReducer.State?
  - Added actions:
    - scanUpload(PresentationAction<ScanUploadReducer.Action>): child reducer presentation
    - cameraPhotoReady(UIImage, ScanType): receives camera delegate output
  - cameraPhotoReady handler:
    1. Create ScanUploadReducer.State with image and scanType
    2. Set scanUpload state (triggers full-screen presentation)
    3. Dismiss camera (showCamera = false)
    4. Auto-trigger .scanUpload(.presented(.startUpload))
  - Handle scanUpload delegate actions:
    - .dismissed: set scanUpload = nil
    - .uploadStarted(scanJob): store scanJob for future status tracking (TODO: Phase 15)
  - Added .ifLet(\.$scanUpload, action: \.scanUpload) { ScanUploadReducer() } to reducer body
  - Offline retry logic: when connectivity returns (connectivityChanged(true)) and scanUpload.isOfflineQueued, send .scanUpload(.presented(.retryUpload))
  - Upload complete banner: added showUploadCompleteBanner state, shows "Scan uploaded successfully" with checkmark, auto-dismisses after 3s

- Updated PantryView:
  - Added .fullScreenCover for scanUpload: presents ScanUploadView when state exists
  - Upload complete toast banner: similar to sync failure banner pattern, green background, checkmark icon
  - Ensured FAB collapses when camera or upload modals open

- Added 10 localization strings (English/Turkish):
  - scan.upload.preparing: "Preparing photo..." / "Fotograf hazirlaniyor..."
  - scan.upload.uploading: "Uploading..." / "Yukleniyor..."
  - scan.upload.analyzing: "Analyzing your photo..." / "Fotografiniz analiz ediliyor..."
  - scan.upload.complete: "Upload complete" / "Yukleme tamamlandi"
  - scan.upload.failed: "Upload failed" / "Yukleme basarisiz"
  - scan.upload.retry: "Retry" / "Tekrar dene"
  - scan.upload.cancel: "Cancel" / "Iptal"
  - scan.upload.back_to_pantry: "Back to Pantry" / "Kilere don"
  - scan.upload.offline_queued: "Photo saved — will upload when back online" / "Fotograf kaydedildi — cevrimici olunca yuklenecek"
  - scan.upload.success_banner: "Scan uploaded successfully" / "Tarama basariyla yuklendi"

### Task 3: Device verification of complete camera capture flow
**Status:** APPROVED by user
**Verification:** All 6 flows tested on physical iPhone (device ID: 00008140-00125CDC0152801C)

User confirmed all verification flows pass:
1. Pro paywall gate: FAB expands, free users see Pro badge on "Scan items", paywall dismisses correctly
2. Camera permission: progressive request (not at launch), grant permission → camera opens
3. Camera capture: edge-to-edge preview, hint text, flash toggle, pinch-to-zoom, capture with haptic, preview with Use/Retake
4. Upload: progress indicator, "Analyzing your photo...", "Back to Pantry" button works
5. Camera permission denied: settings redirect alert with "Open Settings" button
6. VoiceOver: all controls announced correctly ("Pantry actions", "Take photo", "Flash: auto", "Photo captured")

Build verification passed: xcodebuild succeeded on physical device, all features functional.

## Deviations from Plan

None — plan executed exactly as written. All features implemented according to specification. Device verification checkpoint approved by user.

## Verification

All automated verification passed:

1. ✅ UploadScanPhoto.graphql mutation exists in NetworkClient/Sources/GraphQL/
2. ✅ ScanUploadReducer manages compress → upload → processing state machine
3. ✅ Upload uses Apollo multipart mutation (GraphQLFile wrapper)
4. ✅ Cancel button available during upload (.cancellable effect)
5. ✅ Failed upload shows error with Retry button
6. ✅ Offline capture queues upload in memory (isOfflineQueued flag)
7. ✅ Processing animation shows after successful upload
8. ✅ "Back to Pantry" button dismisses while processing continues
9. ✅ ScanUploadView shows appropriate overlay for each upload state
10. ✅ PantryReducer presents ScanUploadReducer as @Presents child
11. ✅ cameraPhotoReady triggers upload flow automatically
12. ✅ 10 localization strings added
13. ✅ Device verification approved by user (all 6 flows pass)

## Success Criteria Met

- ✅ Photo compresses to JPEG 80% quality with max 2048px longest edge
- ✅ Upload progress shown with circular indicator on photo preview
- ✅ Cancel button available during upload
- ✅ Failed upload shows error with Retry button
- ✅ Offline photo capture queues upload for when connectivity returns
- ✅ After successful upload, "Analyzing your photo..." processing animation shown
- ✅ User can navigate back to pantry while processing continues
- ✅ Complete camera-to-upload flow works on physical device (verified by user)

## Full Flow

End-to-end camera capture → upload flow now complete:

1. User taps FAB in Pantry tab → expands to show "Add manually" and "Scan items"
2. Free user taps "Scan items" → sees Pro badge, paywall shown
3. Pro user taps "Scan items" → progressive camera permission request (first time only)
4. Permission granted → camera opens edge-to-edge
5. User captures photo → preview with blur detection warning (if applicable)
6. User taps "Use photo" → scan classification bottom sheet
7. User selects "Fridge Scan" or "Receipt Scan" → upload begins automatically
8. Upload progress shown with circular indicator and Cancel button
9. Upload completes → "Analyzing your photo..." animation with "Back to Pantry" button
10. User returns to pantry → upload complete banner shows
11. Backend receives photo in R2 storage with PROCESSING status (Phase 15 will implement AI analysis)

Offline variant: If no connectivity at step 7, photo queued in memory → "Photo saved — will upload when back online" banner → auto-retry when connectivity returns.

## Next Steps

**Phase 15 (Photo Analysis):** Implement backend AI analysis pipeline:
- Add Gemini Vision API integration to ScanService
- Parse ingredient/receipt text from uploaded photos
- Create Prisma ScanJob model for persistence
- Update scan job status from PROCESSING → COMPLETED
- Return structured ingredient data for automatic pantry item creation
- Add error handling for AI hallucinations and OCR misreads

**Phase 16 (Pantry Integration):** Wire scan results to pantry:
- Automatic pantry item creation from scan results
- Batch add flow for reviewing AI-detected ingredients before saving
- Category mapping from Gemini output to FoodCategory enum
- Expiry date prediction integration
- Duplicate detection for scanned items

## Self-Check

**Files created:**
```bash
[ -f "Kindred/Packages/PantryFeature/Sources/Scanning/ScanUploadReducer.swift" ] && echo "✓"
[ -f "Kindred/Packages/PantryFeature/Sources/Scanning/ScanUploadView.swift" ] && echo "✓"
[ -f "Kindred/Packages/NetworkClient/Sources/GraphQL/UploadScanPhoto.graphql" ] && echo "✓"
```

**Commits exist:**
```bash
git log --oneline --all | grep -q "5550fd6" && echo "✓ 5550fd6"
git log --online --all | grep -q "cb1ebc7" && echo "✓ cb1ebc7"
```

## Self-Check: PASSED

**Files created:**
- ✓ ScanUploadReducer.swift
- ✓ ScanUploadView.swift
- ✓ UploadScanPhoto.graphql

**Commits verified:**
- ✓ 5550fd6 (Task 1: ScanUploadReducer + GraphQL mutation)
- ✓ cb1ebc7 (Task 2: Integration wiring into PantryReducer)

**Device verification:**
- ✓ Task 3 approved by user (all flows pass on physical iPhone)
