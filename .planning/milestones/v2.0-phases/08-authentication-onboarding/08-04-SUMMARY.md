---
phase: 08-authentication-onboarding
plan: 04
subsystem: Verification
tags: [checkpoint, device-testing, verification]
dependency_graph:
  requires:
    - 08-01 (AuthFeature package)
    - 08-02 (Onboarding carousel)
    - 08-03 (Auth gate integration)
  provides:
    - Phase 8 verification complete
  affects: []
tech_stack:
  added: []
  patterns: []
key_files:
  created: []
  modified:
    - Kindred/Packages/AuthFeature/Sources/SignIn/SignInClient.swift
    - Kindred/Packages/AuthFeature/Sources/SignIn/SignInGateView.swift
    - Kindred/Packages/AuthFeature/Sources/Onboarding/Steps/SignInStepView.swift
decisions:
  - decision: "Replaced native SignInWithAppleButton with custom styled button"
    rationale: "Native button auto-presents Apple's ASAuthorization sheet which conflicts with Clerk SDK's own auth flow, causing screen shake"
  - decision: "Added ClerkConfigurationState guard before accessing Clerk.shared"
    rationale: "Clerk.shared triggers assertionFailure when not configured, crashing the app on sign-in button tap"
  - decision: "Removed loading/disabled state from sign-in buttons"
    rationale: "Fast-fail from unconfigured Clerk caused rapid isSigningIn toggle creating visual border bounce"
metrics:
  duration_minutes: 30
  tasks_completed: 2
  files_created: 0
  files_modified: 3
  commits: 0
  completed_at: "2026-03-06"
---

# Phase 08 Plan 04: Device Verification Summary

**One-liner:** Human-verified onboarding carousel and auth gate on device, fixed sign-in button crashes and visual glitches

## Status: APPROVED

**Verified by user on device (iPhone 16 Pro Max)**

## Verification Results

### Task 1: Onboarding Flow — APPROVED
- Onboarding carousel appears on fresh install (replaces WelcomeCardView)
- 4 horizontal steps with dots indicator work correctly
- Step 1 (Sign-in): Apple + Google buttons visible, "Continue as guest" link
- Step 2 (Dietary): Chip grid for dietary preferences
- Step 3 (Location): "Use my location" and "Enter city manually" buttons
- Step 4 (Voice): Teaser with "Try it now" / "Set up later"
- Onboarding completion persists across app restarts

### Task 2: Auth Gate — APPROVED
- Auth gate appears when guest taps bookmark or listen
- Gate cooldown works (prevents re-show within 5 minutes)
- Sign-in buttons show error message instead of crashing (Clerk not yet configured)
- No lock icons on gated buttons (discovery-on-tap pattern)

## Bugs Found and Fixed During Verification

### Bug 1: Sign-in buttons crash app
**Root cause:** `Clerk.shared` triggers `assertionFailure` when accessed before `Clerk.configure()` is called. No publishable key is configured yet.
**Fix:** Added `ClerkConfigurationState.isConfigured` guard in `SignInClient.swift` that checks a flag before accessing `Clerk.shared`. Shows user-friendly error message instead of crashing.

### Bug 2: Apple sign-in button shakes screen
**Root cause:** `SignInWithAppleButton` (native iOS control) automatically presents Apple's ASAuthorization sign-in sheet when tapped. This conflicts with Clerk SDK which handles its own ASAuthorization flow. The native sheet appearing/disappearing rapidly caused screen shake.
**Fix:** Replaced `SignInWithAppleButton` with a custom styled `Button` in both `SignInStepView` and `SignInGateView`. Clerk SDK will handle its own auth flow when configured.

### Bug 3: Google sign-in button border bounces
**Root cause:** `isSigningIn` state toggled rapidly (true → false) when Clerk guard failed instantly. The `KindredButton` `isLoading` and `isDisabled` parameters caused layout changes (text ↔ spinner swap, opacity toggle) creating visible border bounce.
**Fix:** Removed `isLoading` and `isDisabled` bindings from sign-in buttons. Buttons now have no reactive visual state tied to `isSigningIn`.

## Known Limitations
- Sign-in with Apple/Google won't work until real Clerk publishable key is configured in AppDelegate.swift
- Guest migration to backend is placeholder (logs data, doesn't call GraphQL)
- ProfileFeature has duplicate AuthState enum (works via module qualification)

## Self-Check: PASSED
- User approved both verification tasks on physical device
- All bugs found during verification were fixed and re-verified
- Phase 8 requirements (AUTH-02 through AUTH-06) verified to extent possible without Clerk configuration
