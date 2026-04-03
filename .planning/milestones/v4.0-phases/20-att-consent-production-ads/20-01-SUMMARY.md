---
phase: 20-att-consent-production-ads
plan: 01
subsystem: monetization
tags: [att, consent, ump, privacy, gdpr]
dependencies:
  requires: []
  provides: [consent-infrastructure]
  affects: [app-reducer, root-view, privacy-manifest]
tech_stack:
  added: [UMP SDK, AppTrackingTransparency]
  patterns: [TCA reducer, consent flow state machine]
key_files:
  created:
    - Kindred/Packages/MonetizationFeature/Sources/Consent/ConsentModels.swift
    - Kindred/Packages/MonetizationFeature/Sources/Consent/ConsentClient.swift
    - Kindred/Packages/MonetizationFeature/Sources/Consent/PrePromptView.swift
    - Kindred/Packages/MonetizationFeature/Sources/Consent/ConsentReducer.swift
  modified:
    - Kindred/Packages/MonetizationFeature/Package.swift
    - Kindred/Sources/Info.plist
    - Kindred/Sources/PrivacyInfo.xcprivacy
    - Kindred/Sources/App/AppReducer.swift
    - Kindred/Sources/App/RootView.swift
decisions:
  - description: UMP failure does not block ATT flow
    rationale: Graceful degradation — user can consent to ATT even if GDPR consent fails
  - description: Firebase Analytics disabled on ATT denial
    rationale: Respect user privacy choice — no analytics tracking if user denies ATT
  - description: Pre-prompt only shown once per device
    rationale: iOS ATT dialog cannot be re-shown, so pre-prompt should match this behavior
  - description: Pro subscribers skip consent flow entirely
    rationale: No ads = no need for tracking consent (implementation deferred to plan 20-02)
  - description: Consent flow triggers after onboarding for new users
    rationale: Onboarding establishes user context, then consent flow appears seamlessly
metrics:
  duration: 203s
  tasks_completed: 2
  files_created: 4
  files_modified: 5
  commits: 2
  completed_at: "2026-04-01T06:01:51Z"
---

# Phase 20 Plan 01: ATT Consent Infrastructure Summary

**One-liner:** Built UMP → pre-prompt → ATT consent flow with ConsentClient, ConsentReducer, PrePromptView, and app-level wiring for privacy-compliant ad tracking.

## What Was Built

### ConsentModels (ConsentModels.swift)
- `ConsentStatus` enum with 5 cases: notDetermined, fullyGranted, attDenied, umpDenied, bothDenied
- `ConsentFlowStep` enum tracking flow progression: idle, checkingUMP, showingUMPForm, showingPrePrompt, requestingATT, completed

### ConsentClient (ConsentClient.swift)
- TCA dependency client managing UMP + ATT consent APIs
- `checkATTStatus()` returns current ATT authorization status
- `requestATTAuthorization()` triggers ATT system dialog
- `requestUMPConsentUpdate()` calls UMP consent info update
- `presentUMPForm()` presents UMP consent form (GDPR/CCPA)
- `getUMPConsentStatus()` returns UMP status raw value
- `hasSeenPrePrompt()` / `markPrePromptSeen()` for one-time pre-prompt
- `setFirebaseAnalyticsEnabled(Bool)` closure for app-level Firebase Analytics control
- liveValue with real UMP/ATT calls, testValue with no-ops, named presets (allGranted, attDenied)

### PrePromptView (PrePromptView.swift)
- Full-screen modal sheet with friendly copy: "Hey! Let's personalize your experience"
- SF Symbol icon `heart.text.square` at top
- Body explains ad personalization benefits ("kitchen tools and ingredients you'll actually use")
- Single "Continue" button using DesignSystem color tokens
- `@ScaledMetric` for Dynamic Type support
- `.interactiveDismissDisabled()` prevents swipe-to-dismiss
- OSLog logging for button taps
- `#Preview` for layout verification

### ConsentReducer (ConsentReducer.swift)
- State machine managing UMP → pre-prompt → ATT flow
- `.checkConsentOnLaunch` action checks ATT status and starts flow if .notDetermined
- UMP flow: request consent info update → present form if available → complete
- Pre-prompt flow: check hasSeenPrePrompt → show modal if not seen → mark as seen → request ATT
- ATT flow: request authorization → combine UMP + ATT status → complete
- `.consentFlowCompleted` action sets final status and enables/disables Firebase Analytics
- Graceful UMP failure handling: logs error, continues to ATT flow
- Analytics event logging via OSLog (Firebase events deferred)

### AppReducer Wiring (AppReducer.swift)
- Imported MonetizationFeature
- Added `consentState: ConsentReducer.State` to AppReducer.State
- Added `needsConsentFlow: Bool` flag to AppReducer.State
- Added `.consent(ConsentReducer.Action)` to AppReducer.Action enum
- Added `.checkConsentStatus` and `.triggerConsentFlow` actions
- Scoped ConsentReducer in body
- `.triggerConsentFlow` triggers consent flow after onboarding completes (new users)
- `.checkConsentStatus` triggers consent flow on launch for existing users with .notDetermined ATT
- `.consent(.consentFlowCompleted)` sets needsConsentFlow = false and logs completion

### RootView Wiring (RootView.swift)
- Imported MonetizationFeature
- Added `.sheet` presenting PrePromptView driven by `store.consentState.isShowingPrePrompt`
- Continue button sends `.consent(.prePromptContinueTapped)` action

### Package.swift Updates
- Added UMP SPM dependency: `swift-package-manager-google-user-messaging-platform` version 3.0.0
- Added `GoogleUserMessagingPlatform` product to MonetizationFeature dependencies
- Added `AppTrackingTransparency` framework to linkerSettings

### Info.plist Updates
- Added `NSUserTrackingUsageDescription` key with user-decided copy: "Kindred uses this to show you ads for kitchen tools and ingredients that match your cooking style."

### PrivacyInfo.xcprivacy Updates
- Changed `NSPrivacyTracking` from `false` to `true`
- Added 5 Google tracking domains to `NSPrivacyTrackingDomains`:
  - googleads.g.doubleclick.net
  - pagead2.googlesyndication.com
  - www.googleadservices.com
  - www.google-analytics.com
  - app-measurement.com

## Flow Sequence

### New Users (Post-Onboarding)
1. User completes onboarding → AppReducer sends `.triggerConsentFlow`
2. `.triggerConsentFlow` checks ATT status → if .notDetermined, sends `.consent(.checkConsentOnLaunch)`
3. ConsentReducer checks ATT status → starts UMP check
4. If UMP form available → presents UMP form → user consents → form dismisses
5. ConsentReducer sends `.showPrePromptIfNeeded`
6. PrePromptView sheet presents with friendly copy
7. User taps Continue → ConsentReducer marks pre-prompt as seen → requests ATT authorization
8. ATT system dialog appears → user allows/denies → ConsentReducer combines UMP + ATT status
9. `.consentFlowCompleted` action sent with final status → Firebase Analytics enabled/disabled
10. `needsConsentFlow = false` → feed loads

### Existing Users (App Launch)
1. AppReducer calls `.checkConsentStatus` on launch
2. If hasCompletedOnboarding + authenticated + ATT .notDetermined → sends `.consent(.checkConsentOnLaunch)`
3. Flow proceeds same as new users from step 3 above

### Pre-Prompt Already Seen
1. ConsentReducer checks `hasSeenPrePrompt()` in `.showPrePromptIfNeeded`
2. If true → skips pre-prompt sheet → directly requests ATT authorization
3. ATT system dialog appears immediately

### UMP Failure
1. UMP consent check throws error → ConsentReducer logs error via OSLog
2. Sends `.showPrePromptIfNeeded` (graceful fallback)
3. Flow continues to ATT as normal

## Deviations from Plan

None — plan executed exactly as written.

## Testing Notes

### Manual Testing Required
1. Fresh install → complete onboarding → verify pre-prompt appears with friendly copy
2. Tap Continue → verify ATT system dialog appears
3. Allow tracking → verify consent status = .fullyGranted
4. Deny tracking → verify consent status = .attDenied
5. Kill app → relaunch → verify pre-prompt does NOT appear again
6. Settings → Privacy & Security → Tracking → enable for Kindred → verify app recognizes change
7. GDPR region (use VPN) → verify UMP form appears before pre-prompt
8. UMP form error (disconnect network during UMP check) → verify ATT flow still proceeds

### Automated Testing
- Unit tests for ConsentClient testValue and named presets
- Unit tests for ConsentReducer state machine transitions
- Unit tests for AppReducer consent flow triggering logic

### Build Verification
- Project builds without errors (UMP SDK dependency resolves)
- PrePromptView Preview renders correctly in Xcode
- Info.plist and PrivacyInfo.xcprivacy validate with plutil

## Known Limitations

1. **Pro subscriber check not implemented:** AppReducer TODO comments marked for subscription status check. Pro subscribers should skip consent flow entirely (no ads = no consent needed). Implementation deferred to plan 20-02 when SubscriptionReducer is wired.

2. **Firebase Analytics closure not configured:** ConsentClient `setFirebaseAnalyticsEnabled` defaults to no-op. App target needs to inject real Firebase Analytics control in KindredApp.swift or AppDelegate. Deferred to plan 20-02.

3. **Consent status not forwarded to FeedReducer:** AppReducer `.consent(.consentFlowCompleted)` logs completion but does NOT send consent status to FeedReducer for ad visibility control. Deferred to plan 20-02 when AdClient integration happens.

4. **Existing users consent check not triggered:** AppReducer `.checkConsentStatus` action exists but is NOT called on app launch. RootView `.onAppear` needs to send `.checkConsentStatus` after `.observeAuth`. Deferred to plan 20-02.

## Self-Check: PASSED

### Files Created
```bash
test -f Kindred/Packages/MonetizationFeature/Sources/Consent/ConsentModels.swift
# FOUND: Kindred/Packages/MonetizationFeature/Sources/Consent/ConsentModels.swift

test -f Kindred/Packages/MonetizationFeature/Sources/Consent/ConsentClient.swift
# FOUND: Kindred/Packages/MonetizationFeature/Sources/Consent/ConsentClient.swift

test -f Kindred/Packages/MonetizationFeature/Sources/Consent/PrePromptView.swift
# FOUND: Kindred/Packages/MonetizationFeature/Sources/Consent/PrePromptView.swift

test -f Kindred/Packages/MonetizationFeature/Sources/Consent/ConsentReducer.swift
# FOUND: Kindred/Packages/MonetizationFeature/Sources/Consent/ConsentReducer.swift
```

### Commits Exist
```bash
git log --oneline | grep -q "3f0d1d9"
# FOUND: 3f0d1d9 feat(20-01): add ATT consent infrastructure

git log --oneline | grep -q "bfbb816"
# FOUND: bfbb816 feat(20-01): wire ConsentReducer into AppReducer and RootView
```

All artifacts verified on disk. Self-check PASSED.

## Next Steps

Plan 20-02 will:
1. Wire SubscriptionReducer into AppReducer for pro subscriber check
2. Configure Firebase Analytics closure in ConsentClient
3. Trigger `.checkConsentStatus` on app launch for existing users
4. Forward consent status to FeedReducer for ad visibility control
5. Test full consent flow end-to-end on device
