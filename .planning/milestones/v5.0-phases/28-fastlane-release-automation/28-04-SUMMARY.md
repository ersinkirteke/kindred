---
phase: 28-fastlane-release-automation
plan: 04
subsystem: infra
tags: [fastlane, testflight, beta, app-store-connect, code-signing]

# Dependency graph
requires:
  - phase: 28-01
    provides: Preflight lane with fail-fast checks wired into beta_internal
  - phase: 28-02
    provides: Metadata audit — en-US and tr locale files complete
  - phase: 28-03
    provides: Clean Release build verified against Xcode 26 + iOS 26 SDK
provides:
  - Build 509 processed and distributed in TestFlight Internal Testers group
  - 28-04-BETA-REPORT.md with GO decision gating Plan 28-05
  - Bake validation: all 6 core flows passing, zero crashes, 72h elapsed
affects:
  - 28-05-fastlane-release (directly gated on this GO decision)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Manual ASC web UI distribution as workaround for fastlane pilot bug #28630"
    - "Bake window tracking via epoch timestamp written to /tmp at lane start"

key-files:
  created:
    - .planning/phases/28-fastlane-release-automation/28-04-BETA-REPORT.md
  modified: []

key-decisions:
  - "Build 509 distributed manually via ASC web UI (sidestepping fastlane pilot bug #28630 — internal distribution triggers beta-review submission endpoint)"
  - "Populated Beta App Description in ASC TestFlight Test Information (app-wide, one-time) to unblock future fastlane pilot distribute calls"
  - "Renamed precheck lane to preflight to avoid collision with fastlane built-in precheck tool"
  - "GO decision recorded after 72h bake: zero crashes, all 6 core flows passed, all checklist items PASS"
  - "6 Apollo generated-code warnings deferred (backend schema deprecations, not blocking per 28-03 decision)"

patterns-established:
  - "Beta bake report template: Upload Details + Bake Schedule + Tester Coverage + Checklist Results + Bugs Found + Bake Duration + GO/NO-GO Decision"
  - "Always verify manual ASC distribution before starting 48h bake clock"

requirements-completed: [STORE-04]

# Metrics
duration: 3 days (72h bake window — wall clock)
completed: 2026-04-11
---

# Phase 28 Plan 04: Beta Internal Bake Report Summary

**Build 509 baked 72h on TestFlight (Internal Testers), all 6 core flows passed with zero crashes — GO decision recorded for Plan 28-05 App Store submission**

## Performance

- **Duration:** ~72 hours (wall clock bake window, 2026-04-08 to 2026-04-11)
- **Started:** 2026-04-08T14:39:00Z (build distributed to Internal Testers)
- **Completed:** 2026-04-11T21:34:01Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Build 509 uploaded to TestFlight (2026-04-08 15:12:40 UTC, `fastlane beta_internal`) and distributed to Internal Testers group via ASC web UI
- 72-hour internal bake completed: all 6 core flows (onboarding, feed, voice playback, pantry, purchase, account) exercised with zero crashes
- All pre-submission-checklist.md items evaluated PASS — production config, code signing, metadata, privacy labels all confirmed
- GO decision recorded in 28-04-BETA-REPORT.md, unblocking Plan 28-05 App Store submission

## Task Commits

Each task committed atomically:

1. **Task 1: Upload build 509 to TestFlight** - `8a0f15f` (docs) — confirmed distribution + preflight rename
2. **Task 2: Complete beta bake with GO decision** - `db9030d` (docs) — bake results + checklist + GO

**Plan metadata:** see final commit below

## Files Created/Modified

- `.planning/phases/28-fastlane-release-automation/28-04-BETA-REPORT.md` — Primary artifact: upload details, bake schedule, tester coverage, full pre-submission checklist results, bugs found (none), bake duration (72h), GO/NO-GO decision (GO)

## Decisions Made

- **Manual ASC distribution**: fastlane pilot bug #28630 causes internal-only distribution to trigger `post_beta_app_review_submissions`, which rejects when Beta App Description is empty. Resolved by: (a) distributing build 509 manually via ASC web UI, (b) populating Beta App Description in ASC TestFlight Test Information app-wide so future runs work cleanly. No Fastfile changes needed.
- **Preflight rename**: The fastlane `precheck` lane name collides with fastlane's own built-in `precheck` tool. Renamed to `preflight` and updated all call sites in `beta_internal` and `release` lanes. Applied in commit `8a0f15f`.
- **GO after 72h bake**: Zero crashes across all 6 core flows. All checklist items PASS. Plan 28-05 unblocked.

## Deviations from Plan

None - plan executed as written. The fastlane pilot bug #28630 workaround (manual ASC distribution) was pre-documented in the beta report's "Current State" section. The preflight rename was a correctness fix applied during Task 1 (Rule 1 — bug in lane naming).

## Issues Encountered

- **Fastlane pilot bug #28630**: `upload_to_testflight` with `distribute_external: false` still calls `post_beta_app_review_submissions`, rejecting with "Beta App Description is missing". Build was already uploaded successfully; only the group distribution step failed. Resolved by distributing manually via ASC web UI and populating the Beta App Description one-time in ASC. Future `beta_internal` runs will pass cleanly.
- **Lane naming collision**: `precheck` lane name conflicted with fastlane's built-in tool. Renamed to `preflight`.

## User Setup Required

None — all infrastructure was in place from Phases 28-01/02/03. Build upload and distribution were automated except for the one-time manual distribution workaround for fastlane pilot bug #28630.

## Next Phase Readiness

- **Plan 28-05 is fully unblocked.** GO decision recorded, build 509 is in TestFlight, all checklist items pass.
- Next action: Run `fastlane release` to submit build for App Store review (Plan 28-05).
- Privacy Nutrition Labels confirmed matching PrivacyInfo.xcprivacy (Phase 27.1 completed).
- No blockers.

---
*Phase: 28-fastlane-release-automation*
*Completed: 2026-04-11*
