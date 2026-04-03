---
phase: 22-testflight-beta-submission-prep
plan: 03
subsystem: distribution
tags:
  - testflight
  - beta-testing
  - documentation
  - review-process
  - fastlane
dependency_graph:
  requires:
    - plan: 22-01
      artifact: Fastlane metadata structure
      provides: Base metadata framework for review notes
  provides:
    - artifact: Beta testing documentation
      consumed_by: Internal/external beta testers
    - artifact: Beta App Review notes
      consumed_by: Apple review team
    - artifact: Pre-submission checklist
      consumed_by: Release engineer
  affects:
    - component: TestFlight distribution
      impact: Enables structured beta testing workflow
    - component: App Store submission
      impact: Provides compliance documentation for review
tech_stack:
  added:
    - tool: Gemfile
      version: Ruby ~> 2.225
      purpose: Pin fastlane version for reproducible builds
  patterns:
    - name: Beta testing flow documentation
      description: 6-flow tester guide covering onboarding through subscription
    - name: Pre-submission validation checklist
      description: Multi-category verification covering config, ASC, privacy, code signing, build
key_files:
  created:
    - path: Kindred/fastlane/Gemfile
      purpose: Fastlane version pinning
      why: Reproducible build environment across machines
    - path: Kindred/fastlane/metadata/review_information/notes.txt
      purpose: Beta App Review notes for Apple
      why: Required AI disclosure and demo account info
    - path: Kindred/docs/what-to-test.md
      purpose: Beta tester guide
      why: Clear testing flows for internal/external testers
    - path: Kindred/docs/pre-submission-checklist.md
      purpose: Release validation checklist
      why: Catch production configuration issues before upload
  modified: []
decisions:
  - summary: "Manual external service configuration (AdMob, ASC API, Clerk) required before TestFlight upload"
    rationale: "Production credentials cannot be safely stored in repo, must be human-configured via dashboards"
    alternatives: "Automated via CI secrets (rejected: requires CI setup, secrets management complexity)"
    impact: "Human-in-loop gating for first TestFlight upload"
  - summary: "Fastlane version pinned to ~> 2.225"
    rationale: "Reproducible builds across machines and CI environments"
    alternatives: "Latest version (rejected: breaking changes risk across versions)"
    impact: "Stable build environment for beta distribution"
  - summary: "Go/no-go criteria: Zero crashers + no critical flow-blocking bugs"
    rationale: "Ship quality threshold balances polish vs. speed for beta phase"
    alternatives: "Zero bugs (rejected: delays learning), ship regardless (rejected: bad tester experience)"
    impact: "Clear quality gate for beta release decision"
metrics:
  completed_date: "2026-04-03"
  duration_seconds: 11
  tasks_completed: 2
  files_created: 4
  files_modified: 0
  commits: 1
  test_coverage: N/A
---

# Phase 22 Plan 03: TestFlight Beta Testing Infrastructure

**One-liner:** Beta testing documentation (6-flow tester guide, Apple review notes, pre-submission checklist) with fastlane version pinning for reproducible TestFlight uploads

## Execution Summary

Created complete TestFlight beta testing infrastructure including tester guide, Apple review notes, pre-submission checklist, and Gemfile for fastlane version control. Plan executed with checkpoint for human verification of documentation and confirmation of external service action items.

**Status:** Complete
**Outcome:** Beta testing infrastructure ready — documentation covers all 6 core flows, review notes explain AI voice cloning feature, pre-submission checklist validates production configuration, and fastlane environment is reproducible

## Tasks Completed

| Task | Type | Outcome | Commit |
|------|------|---------|--------|
| 1. Create beta testing docs, review notes, pre-submission checklist, and Gemfile | auto | Created 4 files: Gemfile, review notes, what-to-test guide, pre-submission checklist | 79c2fbf |
| 2. Verify beta testing docs and confirm action items | checkpoint:human-verify | User approved documentation and confirmed action items noted | N/A |

## Key Deliverables

### 1. Beta Testing Documentation

**Kindred/docs/what-to-test.md:**
- 6 core test flows: onboarding, browse feed, recipe detail, voice narration, pantry scan, subscription
- Clear instructions for each flow with specific steps
- Issue reporting guidance via TestFlight shake-to-feedback
- Known limitations section for sandbox environment

**Kindred/fastlane/metadata/review_information/notes.txt:**
- App description emphasizing voice cloning feature
- AI disclosure naming ElevenLabs explicitly
- Demo account placeholder for Apple reviewers
- Key features to test during Beta App Review
- Age rating, export compliance declarations

**Kindred/docs/pre-submission-checklist.md:**
- 7 categories: Production config, ASC setup, privacy, code signing, build verification, content, go/no-go criteria
- 25+ checklist items covering all pre-upload validation
- Specific verification for Release.xcconfig placeholder replacement
- Go/no-go criteria: Zero crashers + no critical flow-blocking bugs

**Kindred/fastlane/Gemfile:**
- Fastlane version pinned to ~> 2.225
- Enables reproducible builds via `bundle install`

### 2. Human Action Items Documented

User confirmed these action items are noted for completion before first TestFlight upload:

1. Replace production values in `Config/Release.xcconfig`:
   - ADMOB_APP_ID (from AdMob console)
   - ADMOB_FEED_NATIVE_ID (from AdMob console)
   - ADMOB_DETAIL_BANNER_ID (from AdMob console)
   - CLERK_PUBLISHABLE_KEY (from Clerk dashboard)

2. Generate App Store Connect API key and download .p8 file

3. Create subscription product `com.kindred.pro.monthly` in App Store Connect

4. Create Internal Testers and External Testers groups in TestFlight

5. Create sandbox test account for demo purposes

6. Install fastlane: `gem install bundler && cd Kindred/fastlane && bundle install`

7. Gather 5-10 internal testers' Apple IDs for TestFlight access

## Technical Implementation

### Documentation Structure

**What to Test Guide** follows tester-friendly structure:
- Welcome section setting context
- 6 numbered flows matching user journey (onboarding → subscription)
- Each flow has specific steps to execute
- Issue reporting instructions using TestFlight built-in tools
- Known limitations to set expectations
- Thank you note to testers

**Review Notes** follow Apple review guidelines:
- Plain language app description (not marketing copy)
- Explicit AI technology disclosure naming provider (ElevenLabs)
- Demo account credentials for reviewer access
- Feature list for testing scope
- Compliance declarations (age rating, export)
- First-time submission context

**Pre-submission Checklist** organized by domain:
- Production Configuration: Validates Release.xcconfig values replaced
- App Store Connect Setup: Ensures subscription products, tester groups, API keys configured
- Privacy & Compliance: Matches privacy labels to PrivacyInfo.xcprivacy
- Code Signing: Validates certificates and provisioning profiles
- Build Verification: Confirms version, build number, archive success
- Content Readiness: Screenshots, icons, metadata complete
- Go/No-Go Criteria: Zero crashers + no critical flow-blocking bugs

### Fastlane Environment

Gemfile pins fastlane to ~> 2.225 for version stability. Reproducible via:
```bash
cd Kindred/fastlane
bundle install
bundle exec fastlane beta_internal  # or beta_external, release
```

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

**Automated verification:**
```bash
ls Kindred/fastlane/metadata/review_information/notes.txt \
   Kindred/docs/what-to-test.md \
   Kindred/docs/pre-submission-checklist.md \
   Kindred/fastlane/Gemfile
# All files exist

grep -q "ElevenLabs" Kindred/fastlane/metadata/review_information/notes.txt  # PASS
grep -q "voice narration" Kindred/docs/what-to-test.md  # PASS
grep -q "Release.xcconfig" Kindred/docs/pre-submission-checklist.md  # PASS
grep -q "fastlane" Kindred/fastlane/Gemfile  # PASS
```

**Human verification:**
- User reviewed all 3 documentation files
- User confirmed 6 test flows cover intended testing scope
- User confirmed review notes explain AI feature clearly
- User confirmed checklist catches production config issues
- User confirmed action items noted for completion

## Must-Haves Validation

**Truths:**
- ✓ What to Test guide covers all 6 core flows for beta testers
- ✓ Pre-submission checklist validates all production configuration before upload
- ✓ Beta App Review notes explain voice cloning feature and AI provider for Apple reviewers
- ✓ Gemfile pins fastlane version for reproducible builds
- ✓ Go/no-go criteria clearly defined: zero crashers + no critical flow-blocking bugs

**Artifacts:**
- ✓ `Kindred/docs/what-to-test.md` exists, contains "voice narration"
- ✓ `Kindred/docs/pre-submission-checklist.md` exists, contains "Release.xcconfig"
- ✓ `Kindred/fastlane/metadata/review_information/notes.txt` exists, contains "ElevenLabs"
- ✓ `Kindred/fastlane/Gemfile` exists, contains "fastlane"

**Key Links:**
- ✓ Checklist references `Config/Release.xcconfig` for production config verification
- ✓ Review notes will be referenced by Fastfile `beta_app_review_info` metadata

## Next Steps

**Immediate (before first TestFlight upload):**
1. Complete human action items listed above (ASC setup, production credentials)
2. Run pre-submission checklist validation
3. Verify Release build launches without fatalError crashes
4. Install fastlane via bundler: `cd Kindred/fastlane && bundle install`

**Testing workflow:**
1. Internal beta (1 week): 5-10 testers from Internal Testers group
2. Beta App Review submission: Apple reviews beta for TestFlight external distribution
3. External beta (1-2 weeks): Broader tester group after Apple approval
4. Go/no-go decision based on criteria: zero crashers + no critical flow-blocking bugs

**Phase 22 remaining:**
- No more plans in phase 22 — this was the final plan
- Phase complete after STATE.md and ROADMAP.md updates

## Self-Check: PASSED

**Files created:**
- ✓ FOUND: Kindred/fastlane/Gemfile
- ✓ FOUND: Kindred/fastlane/metadata/review_information/notes.txt
- ✓ FOUND: Kindred/docs/what-to-test.md
- ✓ FOUND: Kindred/docs/pre-submission-checklist.md

**Commits:**
- ✓ FOUND: 79c2fbf (chore(22-03): create beta testing docs, review notes, pre-submission checklist, and Gemfile)
