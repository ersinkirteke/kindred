---
phase: 17-expiry-tracking
plan: 03
subsystem: app-integration
tags: [remote-notifications, device-token, localization, device-verification]
dependency_graph:
  requires: [17-01, 17-02]
  provides: [apns-device-token, expiry-tracking-verified]
  affects: [app-delegate, localization]
tech_stack:
  added: [UserNotifications]
  patterns: [apns-device-token, progressive-permission]
key_files:
  modified:
    - Kindred/Sources/App/AppDelegate.swift
    - Kindred/Sources/Resources/Localizable.xcstrings
    - Kindred/Packages/AuthFeature/Sources/SignIn/SignInClient.swift
decisions:
  - Store APNs device token in UserDefaults until GraphQL mutation wired
  - Apple Sign In switched from native ID token to OAuth flow (Clerk custom credentials compatibility)
metrics:
  duration_minutes: 30
  completed: 2026-03-29T23:01:00Z
  tasks_completed: 2
  files_modified: 3
---

# Phase 17 Plan 03: Device Token & Verification Summary

Remote notification device token handling and end-to-end device verification of all Phase 17 expiry tracking features

## One-Liner

Added AppDelegate remote notification device token registration, expiry localization strings, fixed Apple Sign In OAuth strategy, and verified all Phase 17 expiry features on physical device.

## What Was Built

### Task 1: AppDelegate Remote Notification Handling (auto — committed 263174e)

**AppDelegate.swift**
- Added `import UserNotifications`
- `didRegisterForRemoteNotificationsWithDeviceToken`: Converts token Data to hex string, stores in UserDefaults under `apnsDeviceToken` key, logs first 10 chars
- `didFailToRegisterForRemoteNotificationsWithError`: Logs registration failure

**Localizable.xcstrings**
- Added `pantry.expiry.ai_estimate` — "AI estimate — check packaging"
- Added `pantry.notification.prompt_title` — "Stay Fresh"
- Added `pantry.notification.prompt_message` — "We'll remind you before items expire"

### Task 2: Device Verification (human-verify checkpoint — approved)

All Phase 17 features verified on iPhone 16 Pro Max:
- [x] Color-coded left edge strips (green >3 days, yellow 1-3 days, red expired)
- [x] Dimmed expired rows (60% opacity)
- [x] Swipe right → "Consumed" (green) / Swipe left → "Discard" (red)
- [x] DatePicker sheet with graphical calendar on expiry date tap
- [x] Notification permission prompt after first item add
- [x] Expiry-based sorting within storage sections
- [x] AI estimate disclaimer text

### Additional Fix: Apple Sign In OAuth Strategy

**Problem:** Clerk native `signInWithApple()` sends `oauth_token_apple` strategy which requires bundle ID audience matching. Clerk custom credentials configured with Services ID caused "not authorized" error.

**Fix:** Changed `SignInClient.swift` from `Clerk.shared.auth.signInWithApple()` to `Clerk.shared.auth.signInWithOAuth(provider: .apple)` — uses web-based OAuth flow compatible with Clerk custom credentials.

**Clerk Dashboard Configuration:**
- Apple OAuth SSO connection enabled with custom credentials
- Apple Services ID: `com.ersinkirteke.kindred.clerk`
- Apple Key ID: `L866NCG7AM`
- Apple Team ID: `CV9G42QVG4`
- Apple Private Key: configured
- Return URL: `https://driving-possum-65.clerk.accounts.dev/v1/oauth_callback`

## Deviations from Plan

1. **Apple Sign In strategy change** — Plan didn't anticipate the `oauth_token_apple` vs `oauth_apple` strategy mismatch with Clerk. Switched to OAuth flow to resolve. Not a regression — improves compatibility with Clerk custom credentials.

## Verification Results

### Automated Tests

```bash
xcodebuild build -scheme Kindred -destination 'platform=iOS,id=00008140-00125CDC0152801C'
```

**Result:** BUILD SUCCEEDED

### Device Verification

All Phase 17 expiry tracking requirements verified on iPhone 16 Pro Max:
- EXPIRY-01: Items have AI-estimated expiry dates ✓
- EXPIRY-02: Notification permission requested, device token registered ✓
- EXPIRY-03: Color-coded edge strips visible in pantry view ✓
- EXPIRY-04: AI disclaimer shown, DatePicker override works ✓
- EXPIRY-05: Swipe consume/discard soft-deletes items ✓

Apple Sign In verified working with OAuth flow ✓

## Key Learnings

**Clerk Native vs OAuth Apple Sign In**
Clerk iOS SDK's `signInWithApple()` uses `ASAuthorizationAppleIDProvider` and sends an ID token with the app's bundle ID as audience. Clerk's backend validates this against the configured Services ID, which is a different identifier. The `signInWithOAuth(provider: .apple)` method uses a web redirect flow that works correctly with Services ID + custom credentials. For native iOS apps using Clerk, OAuth flow is the safer default unless Clerk specifically documents bundle ID configuration for ID token flow.

## Open Items

None — Phase 17 complete. All expiry tracking features verified on device.
