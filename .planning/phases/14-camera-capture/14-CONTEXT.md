# Phase 14: Camera Capture - Context

**Gathered:** 2026-03-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Users can capture photos from the camera with progressive permission request and memory-safe processing. Photos upload to Cloudflare R2 via the backend. Pro paywall gates the scanning feature for free-tier users. This phase builds the capture + upload pipeline; AI analysis (fridge recognition, receipt OCR) is Phase 15.

Requirements: INFRA-04 (progressive camera permission), SCAN-06 (Pro paywall for scanning features).

</domain>

<decisions>
## Implementation Decisions

### Camera Entry Points
- Expandable FAB in Pantry tab with two options: "Add manually" (existing flow) and "Scan items" (new)
- "Scan items" option has camera icon with app accent color
- "Pro" badge visible on scan option for free users; no badge for Pro users
- Light haptic impact on FAB expand
- Single entry point: Pantry FAB only (no other screens)
- Camera only — no photo library picker (library offered only as fallback when camera permission denied)
- Permission prompt on first camera tap (progressive disclosure, follows location permission pattern)
- If permission denied: Settings redirect with explanation (no photo library fallback as primary)

### Capture Experience
- Custom AVCaptureSession viewfinder (not UIImagePickerController)
- Edge-to-edge camera preview with floating controls on subtle dark gradient
- Classic white circle capture button with scale pulse animation
- Flash toggle top-right: auto → on → off cycle
- X close button top-left
- Portrait orientation only
- Rear camera only (no flip button)
- Pinch-to-zoom supported (no visible slider)
- Subtle text hint at top: "Take a clear photo" (generic, disappears after 3 seconds)
- No crop/aspect ratio guide — full-frame capture
- Single photo per scan (no batch capture)
- Preview with retake: after capture, show photo full-screen with "Use photo" and "Retake" buttons
- Capture button debounced (1 second) to prevent double-tap

### Scan Classification
- After "Use photo": bottom sheet slides up over dimmed photo preview
- Two large tappable cards: fridge icon + "Fridge Scan", receipt icon + "Receipt Scan"
- "Retake" link on sheet to return to camera
- Pull-down dismiss to cancel entirely
- After selection: sheet dismisses, photo zooms to fill screen, processing overlay fades in

### Upload + Feedback
- Photo compressed to JPEG 80% quality
- Downscale longest edge to max 2048px (handles 48MP cameras, keeps detail for AI)
- Upload through backend via Apollo iOS multipart GraphQL mutation (not presigned URL)
- R2StorageService handles storage on backend side (already exists)
- Progress overlay on photo preview during upload (circular progress indicator)
- Cancel button available during upload
- No file size / estimated time text — just progress indicator
- Photo saved in app's temp/cache only (not to user's photo library)
- Failed upload: save photo locally, show error with "Retry" button, auto-retry when connectivity returns
- Failed photo kept until app restart (no persistent disk storage for retries)
- Backend returns scan job ID + status URL (async processing — AI happens in Phase 15)
- After successful upload: "Analyzing your photo..." processing animation with back button to return to pantry
- Background upload continues via URLSession background task if app backgrounded
- No scan limit for free users (paywall blocks before camera opens)

### Offline Handling
- Allow photo capture offline, queue upload for when connectivity returns
- In-app toast/banner when queued upload completes (not push notification)
- Scanned items invisible in pantry until AI processing complete (no "pending" cards)

### Pro Paywall
- Paywall appears BEFORE camera opens (free user taps "Scan items" → paywall immediately)
- Reuse existing MonetizationFeature fullScreenCover paywall UI
- Scan-specific copy listing both scan types: "Fridge scanning, Receipt scanning, Smart ingredient detection"
- "Restore Purchase" always visible (App Store requirement)
- Show free trial if available
- "Pro" badge on FAB is sufficient soft-sell (no extra preview step)
- After successful subscription: dismiss paywall, open camera immediately
- Paywall dismiss: return to pantry, collapse FAB
- No cooldown on paywall (user actively chooses to tap each time)
- Same paywall for lapsed Pro users (no special "welcome back" variant)

### Error & Edge Cases
- Low light detection: subtle banner "Low light detected — try turning on flash"
- Blur detection: after capture, check sharpness. If below threshold: "Photo may be blurry. Retake?"
- Storage low (<100MB): show warning, allow capture anyway (photo is small after compression)
- Thermal state: Claude's discretion (iOS handles throttling)
- No scan history screen (scans are one-shot: capture → upload → results in pantry)

### Accessibility
- VoiceOver: announce all controls ("Take photo", "Flash: auto", "Close camera"), announce "Photo captured" on capture
- Medium haptic impact on capture button tap (confirms photo taken)
- Dynamic Type: hint text scales with accessibility settings; capture button fixed size
- Reduce Motion: replace scanning animation with static progress indicator + text
- Follow Phase 10 WCAG AAA patterns for color-blind support (icons + text labels, no color-only indicators)
- High contrast mode: increase dark gradient opacity behind camera controls
- Expandable FAB: VoiceOver group ("Pantry actions: Add manually, Scan items"), Reduce Motion replaces expand animation with instant appear
- FAB works normally with VoiceOver (no special shortcut needed)

### Claude's Discretion
- R2 upload key/path structure (follow existing patterns: recipes/{id}/hero.jpg, voice-samples/{userId}/...)
- Analytics/logging for capture attempts
- Memory pipeline design (autoreleasepool, sequential processing per roadmap)
- Thermal state handling
- Exact processing animation design

</decisions>

<specifics>
## Specific Ideas

- FAB expansion pattern similar to popular iOS apps (Things 3, Todoist) — animated circular expansion
- Camera viewfinder should feel native/familiar — like the system camera but branded
- Processing animation should convey "intelligence" — scanning/analyzing feel
- The flow should feel fast: capture → classify → upload → processing should be smooth with minimal waiting

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `R2StorageService` (backend/src/images/r2-storage.service.ts): S3-compatible upload to Cloudflare R2. Already handles images and voice samples. Extend with pantry scan photo uploads.
- `MonetizationFeature` package: Existing Pro paywall UI (fullScreenCover pattern). Reuse for scan paywall with custom copy.
- `LocationClient.swift` / `LocationManager.swift`: Progressive permission pattern for location. Mirror this pattern for camera permission.
- `PantryFeature` package: Existing FAB button in PantryView. Extend from single-action to expandable multi-option.

### Established Patterns
- TCA (The Composable Architecture) for all feature reducers
- SPM package per feature (AuthFeature, FeedFeature, PantryFeature, etc.)
- @Dependency for TCA dependency injection
- fullScreenCover for modal presentations (auth gate, onboarding)
- Apollo iOS for GraphQL communication with backend
- SwiftData for local persistence

### Integration Points
- PantryReducer: Add scan actions (openCamera, captureComplete, uploadProgress, scanJobCreated)
- PantryView: Extend FAB from single button to expandable with "Add manually" + "Scan items"
- AppReducer: May need camera permission state management (similar to location permission)
- NetworkClient: Add GraphQL mutation for photo upload (multipart) and scan job creation
- Backend ImagesModule: Extend or create parallel module for pantry scan photo handling

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 14-camera-capture*
*Context gathered: 2026-03-12*
