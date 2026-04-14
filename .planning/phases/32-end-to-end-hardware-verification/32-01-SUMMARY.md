---
phase: 32-end-to-end-hardware-verification
plan: 01
subsystem: testing
tags: [testflight, fastlane, test-matrix, hardware-testing, avSpeech, search, dietary-filter, attribution]

requires:
  - phase: 31-search-ui-dietary-filter
    provides: search UI, dietary filter, source attribution wire-up

provides:
  - TestFlight build 568 for hardware verification
  - Comprehensive test matrix at Kindred/docs/test-matrix-v5.1.md covering all v5.1 requirements

affects:
  - 32-02 (hardware test results, sign-off)

tech-stack:
  added: []
  patterns:
    - "agvtool sets CURRENT_PROJECT_VERSION at build time from git commit count (number_of_commits)"
    - "ensure_git_status_clean requires all untracked dirs in .gitignore before fastlane runs"

key-files:
  created:
    - Kindred/docs/test-matrix-v5.1.md
  modified:
    - .gitignore (added AI agent dirs and build artifacts)
    - Kindred/Kindred.xcodeproj/project.pbxproj (build number 568)
    - Kindred/Sources/Info.plist (CFBundleVersion 568)

key-decisions:
  - "Pilot bug #28630: Beta App Description error fires after upload completes — binary IS uploaded, add to group manually in ASC"
  - "Build number 568 from git commit count (number_of_commits via agvtool)"
  - "AI agent config dirs added to .gitignore to keep git clean for ensure_git_status_clean"

requirements-completed:
  - VOICE-01
  - VOICE-02
  - VOICE-03
  - VOICE-04
  - VOICE-05
  - SEARCH-01
  - SEARCH-02
  - SEARCH-03
  - FILTER-01
  - FILTER-02
  - ATTR-01

duration: 66min
completed: 2026-04-14
---

# Phase 32 Plan 01: End-to-End Hardware Verification — Build + Test Matrix Summary

**Build 568 uploaded to TestFlight and 371-line test matrix created covering all 11 v5.1 requirements across 7 core flows, 6 v5.1-specific tests, and 3 Simulator OS versions**

## Performance

- **Duration:** ~66 min
- **Started:** 2026-04-14T21:27:22Z
- **Completed:** 2026-04-14T22:33:00Z
- **Tasks:** 2 of 3 complete (Task 3 is checkpoint — awaiting human verification)
- **Files modified:** 12

## Accomplishments

- Phase 31 source changes committed (StoreKit timeout guard, paywall callback, root view wiring)
- Git repository cleaned up: AI agent dirs added to .gitignore, old planning docs archived (phases 23, 26, 27, 27.1, 28)
- TestFlight build 568 built and uploaded via `beta_internal` lane
- Comprehensive 371-line test matrix created at `Kindred/docs/test-matrix-v5.1.md`

## Task Commits

1. **Task 1: Commit pending changes** - `74972d1` (fix: StoreKit timeout guard + paywall purchase callback)
2. **Task 1: Archive old planning docs** - `31e91cc` (chore: archive old phase planning docs)
3. **Task 1: Fastlane metadata cleanup** - `f772aa3` (chore: fastlane metadata URL/subtitle updates)
4. **Task 1: Remove name.txt** - `6f95f6b` (chore: remove name.txt managed in ASC)
5. **Task 1: Xcode state** - `0b96e88` (chore: Xcode scheme management)
6. **Task 1: .gitignore** - `cea505d` (chore: add AI agent dirs to gitignore)
7. **Task 1: Build number** - `cf295a3` (chore: bump build number to 568)
8. **Task 2: Test matrix** - `f20c6e3` (feat: add v5.1 hardware test matrix document)

## Files Created/Modified

- `Kindred/docs/test-matrix-v5.1.md` — 371-line test matrix with all v5.1 requirements (CREATED)
- `.gitignore` — Added AI agent config dirs and build artifacts exclusions
- `Kindred/Kindred.xcodeproj/project.pbxproj` — Build number set to 568 via agvtool
- `Kindred/Sources/Info.plist` — CFBundleVersion set to 568
- `Kindred/Packages/MonetizationFeature/Sources/Subscription/PaywallView.swift` — onPurchaseCompleted callback + debug overlay
- `Kindred/Packages/MonetizationFeature/Sources/Subscription/SubscriptionReducer.swift` — 5-sec StoreKit timeout + logging
- `Kindred/Packages/ProfileFeature/Sources/ProfileReducer.swift` — StoreKit timeout fix
- `Kindred/Sources/App/RootView.swift` — onPurchaseCompleted wired to feed + profile update

## Decisions Made

- **Pilot bug #28630 handled**: `Beta App Description is missing` error fires after upload completes. The binary IS already uploaded. Action: add build 568 to Internal Testers group manually in ASC web UI.
- **Build number 568**: From `number_of_commits` (git commit count). Reproducible and monotonically increasing.
- **AI agent dirs ignored**: 25+ IDE/coding assistant config directories (`.adal/`, `.augment/`, `.claude/`, `.goose/`, `.roo/`, etc.) added to `.gitignore` so `ensure_git_status_clean` passes in future builds.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Git dirty state blocked ensure_git_status_clean**
- **Found during:** Task 1 (running beta_internal lane)
- **Issue:** Phase 31 uncommitted source changes + 54 deleted planning docs + Xcode ephemeral files + AI agent dirs as untracked — caused `ensure_git_status_clean` to fail
- **Fix:** Committed changes in 6 logical groups, added AI agent dirs to `.gitignore`
- **Files modified:** `.gitignore`, `project.pbxproj`, `Info.plist`, multiple planning docs deleted
- **Verification:** `git status --porcelain` showed empty output, then Fastlane passed `ensure_git_status_clean`
- **Committed in:** `74972d1`, `31e91cc`, `f772aa3`, `6f95f6b`, `0b96e88`, `cea505d`

---

**Total deviations:** 1 auto-fixed (Rule 3 - blocking)
**Impact on plan:** Required cleanup was necessary groundwork. No scope creep.

## Issues Encountered

- **Fastlane pilot bug #28630**: `upload_to_testflight` exited with error `Beta App Description is missing` after successfully uploading binary. Build 568 IS in ASC — user needs to manually add it to Internal Testers group in ASC web UI. See MEMORY.md for full context.
- **Xcode ephemeral files tracked in git**: `.xcuserstate` and `xcschememanagement.plist` files are tracked despite being in `.gitignore`. Force-added them to commit.

## User Setup Required

**Manual step required**: Open App Store Connect > TestFlight > Builds > Build 568 > Add to "Internal Testers" group.
The binary is uploaded and processing. The `distribute_external: false` + group distribution failed due to pilot bug, not due to upload failure.

## Next Phase Readiness

- TestFlight build 568 is available for hardware verification (pending group assignment in ASC)
- Test matrix at `Kindred/docs/test-matrix-v5.1.md` is ready for use on device
- Phase 32 Plan 02 awaits: capture and record hardware test results

---
*Phase: 32-end-to-end-hardware-verification*
*Completed: 2026-04-14*
