---
phase: 28-fastlane-release-automation
plan: 05
status: complete
started: 2026-04-12T20:30:00Z
completed: 2026-04-12T21:15:00Z
duration_minutes: 45
tasks_completed: 3
tasks_total: 3
commits: 2
deviations: 1
---

# Plan 28-05 Summary: App Store Submission

## What Was Built
Kindred v1.0.0 (build 527) submitted to the App Store. Privacy Nutrition Labels configured in ASC with 14 data types (12 from manifest + 2 conservative over-declarations). Age rating set to 4+ with advertising. Pricing set to Free across 174 regions. ASC status: **Waiting for Review** as of 2026-04-12 21:09 UTC.

## Tasks

| # | Task | Status | Commit |
|---|------|--------|--------|
| 1 | Set Privacy Nutrition Labels in ASC | Done | (manual ASC action) |
| 2 | Run fastlane release to upload binary | Done | (binary upload via fastlane) |
| 3 | Submit for review + create submission report | Done | docs(28-05) |

## Deviations

1. **submit_for_review done manually instead of via fastlane**: Fastlane 2.232.2 has two bugs with age rating attributes. Binary uploaded successfully via fastlane, submission completed manually in ASC web UI. Net effect: same outcome, different mechanism.

## Decisions

- [Phase 28-05]: Disable `app_rating_config_path` in Deliverfile due to fastlane 2.232.2 boolean bug
- [Phase 28-05]: Set `submit_for_review: false` in release lane until fastlane fixes upstream bug
- [Phase 28-05]: Over-declare privacy labels (14 vs 12 in manifest) for conservative review safety

## Key Files

### Created
- `.planning/phases/28-fastlane-release-automation/28-05-SUBMISSION-REPORT.md`
- `.planning/phases/28-fastlane-release-automation/28-05-SUMMARY.md`

### Modified
- `Kindred/fastlane/Fastfile` — submit_for_review: false, skip_metadata: true
- `Kindred/fastlane/Deliverfile` — app_rating_config_path commented out

## Self-Check: PASSED
- [x] Submission report created with all required fields
- [x] ASC shows "Waiting for Review" status
- [x] PROJECT.md already has Release Process section (commit e151796)
- [x] Build 527 binary uploaded and attached to v1.0.0
