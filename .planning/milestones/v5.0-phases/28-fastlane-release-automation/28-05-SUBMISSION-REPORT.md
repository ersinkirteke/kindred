# Phase 28 Plan 05: App Store Submission Report

**Plan:** 28-05
**Status:** Submitted — Waiting for Review
**Submitted:** 2026-04-12 21:09 UTC

## Submission Details

| Field | Value |
|-------|-------|
| Version | 1.0.0 |
| Build | 527 |
| Submission ID | ee51fb3e-4926-4d67-9f5d-617f40ddd295 |
| Submitted By | Ersin Kirteke |
| ASC Status | Waiting for Review |
| Automatic Release | Yes |
| Price Tier | Free ($0.00) |
| Age Rating | 4+ (Advertising: Yes, all others: None/No) |

## Pre-Submission Checklist

- [x] Privacy Nutrition Labels set in ASC (14 data types, 3 tracking)
- [x] Build 527 uploaded via fastlane release lane
- [x] Export compliance answered (standard encryption, available in France)
- [x] Age rating questionnaire completed (4+)
- [x] Pricing set to Free, all 174 regions
- [x] App Review information populated (demo account, AI disclosure note)
- [x] Screenshots present for 6.5" and 6.9" displays (en-US and tr)
- [x] Metadata present (description, keywords, subtitle, release notes)

## Fastlane Release Lane Issues

Two fastlane 2.232.2 bugs encountered during submission:

1. **Age rating string/boolean mismatch**: `rating_config.json` uses NONE/FREQUENT_OR_INTENSE strings but ASC API now expects booleans for fields like `messagingAndChat`, `gambling`, `lootBox`. Workaround: commented out `app_rating_config_path` in Deliverfile, set age rating manually in ASC.

2. **submit_for_review requires age rating attributes**: Even with `skip_metadata: true`, the `submit_for_review` step calls `post_review_submission_item` which requires age rating attributes. Workaround: set `submit_for_review: false`, submitted manually via ASC web UI.

Both bugs are in fastlane's spaceship library and need upstream fixes. Binary upload works correctly.

## What Happens Next

Per PROJECT.md Release Process:
1. Monitor ASC daily: Waiting for Review > In Review > Ready for Sale (typically 24-48h)
2. If rejected: read Resolution Center, fix per the applicable Phase 28 plan, resubmit
3. After approval: `git tag v1.0.0 && git push origin v1.0.0`
4. Update .planning/MILESTONES.md with release date and build number
5. Smoke-test live app from App Store (not TestFlight)
