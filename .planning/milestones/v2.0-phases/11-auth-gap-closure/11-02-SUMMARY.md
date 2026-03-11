---
phase: 11-auth-gap-closure
plan: 02
subsystem: auth
tags: [tca, graphql, migration, guest-data, connectivity, ios]

# Dependency graph
requires:
  - phase: 11-auth-gap-closure
    plan: 01
    provides: Onboarding wired via @Presents, triggered after first sign-in
provides:
  - GuestMigrationClient with GraphQL operation file and local-only fallback
  - MigrationResult with count verification
  - pendingMigration flag persists across app restarts
  - Connectivity-based migration retry in AppReducer
  - City included in migration payload
  - Sign-out functionality (ProfileReducer + AppReducer + ProfileView)
  - Onboarding trigger fix (signInSucceeded routes through authStateChanged)
  - Mini player close button for tab bar accessibility
affects: [auth-flow, guest-migration, voice-playback-ui]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Local-only migration fallback until backend mutation exists"
    - "pendingMigration UserDefaults flag for cross-restart retry"
    - "Connectivity-based retry in connectivityChanged handler"

key-files:
  created:
    - Kindred/Packages/NetworkClient/Sources/GraphQL/MigrateGuestData.graphql
  modified:
    - Kindred/Packages/AuthFeature/Sources/Migration/GuestMigrationClient.swift
    - Kindred/Sources/App/AppReducer.swift
    - Kindred/Packages/ProfileFeature/Sources/ProfileReducer.swift
    - Kindred/Packages/ProfileFeature/Sources/ProfileView.swift
    - Kindred/Packages/VoicePlaybackFeature/Sources/Player/MiniPlayerView.swift

key-decisions:
  - "signInSucceeded must route through authStateChanged so onboarding trigger logic runs"
  - "Sign-out clears hasCompletedOnboarding, onboardingCurrentStep, guestMigrated, pendingMigration"
  - "Mini player close (X) button added for tab bar accessibility"
  - "Local-only migration fallback keeps data intact until backend mutation lands"

patterns-established:
  - "Auth gate sign-in completion routes through authStateChanged for centralized state handling"
  - "Sign-out resets all onboarding/migration flags for clean re-auth flow"

requirements-completed: [AUTH-05]

# Metrics
duration: ~45min
completed: 2026-03-11
---

# Phase 11 Plan 02: Guest Migration Trigger Summary

**Guest data migration hardened with GraphQL operation, connectivity retry, sign-out support, and on-device verification of full onboarding + migration flow**

## Performance

- **Duration:** ~45 min (including on-device verification)
- **Started:** 2026-03-08 (Task 1), verified 2026-03-11
- **Completed:** 2026-03-11
- **Tasks:** 2 (1 auto + 1 human-verify)
- **Files modified:** 6 (1 created, 5 modified)

## Accomplishments
- Guest data migration with GraphQL operation file ready for codegen
- Local-only fallback until backend `migrateGuestData` mutation lands
- pendingMigration flag survives app restarts for retry on next launch
- Connectivity-based retry when coming back online
- Full on-device verification: all 15 checklist items passed

## Bug Fixes During Verification
Three issues discovered and fixed during on-device testing:

1. **Onboarding not triggering after sign-in:** `signInSucceeded` handler directly set auth state without routing through `authStateChanged`, bypassing the onboarding presentation logic. Fixed by sending `.authStateChanged(.authenticated(user))` from `signInSucceeded`.

2. **No sign-out capability:** Clerk sessions persist in iOS keychain across app deletion. Added `signOutTapped` action to ProfileReducer, "Sign Out" button to ProfileView authenticated header, and sign-out handler in AppReducer that clears Clerk session + resets all onboarding/migration flags.

3. **Mini player blocking tab bar:** Mini player via `.safeAreaInset` had no dismiss button, preventing navigation to Me tab. Added X close button that sends `.dismiss` action.

## Task Commits

1. **Task 1: GraphQL operation file, migration wiring, connectivity retry** - `eebef17` (feat)
2. **Task 2: Human verification** - All 15 verification steps passed on device

## Files Created/Modified
- `Kindred/Packages/NetworkClient/Sources/GraphQL/MigrateGuestData.graphql` - **Created** - GraphQL mutation operation file
- `Kindred/Packages/AuthFeature/Sources/Migration/GuestMigrationClient.swift` - MigrationResult, city, pendingMigration flag, local-only fallback
- `Kindred/Sources/App/AppReducer.swift` - Onboarding trigger fix, sign-out handler, connectivity retry, checkPendingMigration
- `Kindred/Packages/ProfileFeature/Sources/ProfileReducer.swift` - Added signOutTapped action
- `Kindred/Packages/ProfileFeature/Sources/ProfileView.swift` - Sign Out button in authenticated header
- `Kindred/Packages/VoicePlaybackFeature/Sources/Player/MiniPlayerView.swift` - Close (X) button

## Verification Results

All 15 checklist items passed:
- Guest browsing, bookmarking, dietary prefs, city selection working
- Auth gate appears on gated action
- Sign-in triggers onboarding carousel (3 steps, no sign-in step)
- Personalized "Welcome, [name]!" greeting shown
- Dietary prefs and city pre-filled from guest data
- Onboarding completion updates feed
- Onboarding does not reappear after force-quit
- Bookmarks visible in profile tab after sign-in

## Self-Check: PASSED

---
*Phase: 11-auth-gap-closure*
*Completed: 2026-03-11*
