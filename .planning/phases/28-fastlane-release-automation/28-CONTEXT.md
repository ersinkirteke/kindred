# Phase 28: Fastlane Release Automation - Context

**Gathered:** 2026-04-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Take the app from "release lane exists and works locally" (Phase 22 prep) to "submitted to App Store Review" by executing the submission pipeline end-to-end against App Store Connect for the first time. Run a fresh internal TestFlight beta with 3+ testers, validate against the existing pre-submission checklist, then run `fastlane release` to upload the binary, sync metadata, and submit for review. Status target: App Store Connect shows "Waiting for Review" with automatic release on approval.

This phase is execution + automation hardening, not greenfield setup. The Fastfile, Deliverfile, metadata, screenshots, and review notes already exist from Phase 22.

</domain>

<decisions>
## Implementation Decisions

### TestFlight Beta Strategy
- **Tester pool**: Solo dev path — me + 2 friends/family. No external Beta App Review needed (uses existing Internal Testers TestFlight group from Phase 22).
- **Bake duration**: 48–72 hours minimum. Long enough for testers to run the 6 core flows from `Kindred/docs/what-to-test.md`, short enough to keep momentum.
- **Bug bar**: Reuse `Kindred/docs/pre-submission-checklist.md` go/no-go criteria exactly. Ship if zero crashers + onboarding/feed/voice/pantry/purchase all work. Block if any crash in core flow. Minor UI glitches acceptable.
- **Build freshness**: Phase 28 starts by running `fastlane beta_internal` to upload a fresh build from current main (includes Phase 27.1 AdMob fixes + any post-Phase-22 changes). Do NOT reuse stale TestFlight builds.
- **Sequence**: `beta_internal` → 48–72hr bake → checklist passes → `fastlane release`.

### SDK / Build Configuration
- **Deployment target**: Stays at iOS 17.0. Do NOT bump min iOS — preserves install base for users on older devices.
- **Build SDK**: Build with current Xcode 16.x against the latest available iOS SDK shipped with that Xcode. User confirms Xcode 16.x is already installed locally.
- **Criterion #5 interpretation**: ROADMAP says "Xcode 16 + iOS 26 SDK". Today (April 2026) the latest stable is whatever current Xcode 16.x ships with. Treat the criterion as "build with the latest available SDK" rather than literal iOS 26. Plan should detect actual SDK version during the build task and document what shipped.
- **Deprecation warnings**: Phase 28 includes a task to scan and **fix all deprecation warnings** surfaced by building Release configuration with the new SDK. Not just compiler errors — fix the warnings too. Anything that can't be fixed cleanly gets logged as deferred for a future cleanup phase.

### Release Lane Sequencing & Gates
- **Lane shape**: Keep `fastlane release` as one shot — increment_build → build_app → upload_to_app_store(submit_for_review: true, automatic_release: true). Already implemented in Fastfile from Phase 22, do NOT split.
- **Auto-release**: Keep `automatic_release: true`. App goes live the moment Apple approves. No manual "Release" click. Phased release stays deferred (Phase 22 decision).
- **Build number**: Keep `number_of_commits` strategy from existing Fastfile. Reproducible, monotonic, works for solo dev.
- **Pre-flight checks**: Add a new `precheck` lane that `release` (and ideally `beta_internal`) calls before doing any work. Fail-fast safety. Must verify:
  - `Kindred/Config/Release.xcconfig` contains no `REPLACE_WITH_*` placeholder values
  - `Kindred/fastlane/.env` exists and has all required keys (APP_STORE_CONNECT_API_KEY_ID, APP_STORE_CONNECT_ISSUER_ID, APP_STORE_CONNECT_API_KEY_FILEPATH)
  - The `.p8` file at the configured path is readable
  - Required metadata files exist and are non-empty in both `metadata/en-US/` and `metadata/tr/`
  - All 5 screenshots exist per locale in `screenshots/en-US/` and `screenshots/tr/`
  - Git status is clean (already enforced by `before_all`)
- **Tests in pre-flight**: Skipped — no `xcodebuild test` in precheck. Keeps lane fast.

### Metadata Re-validation & Privacy Labels
- **Metadata audit**: Yes — re-read `metadata/en-US/description.txt`, `keywords.txt`, `promotional_text.txt`, `release_notes.txt` and cross-check against current `Kindred/PrivacyInfo.xcprivacy` + Phase 27.1 verification report. Phase 22 metadata was written before AdMob tracker reality was reconciled, so AdMob/tracker disclosure language may need updates. Same audit applies to `metadata/tr/` files (keep tr translation in sync if en-US changes).
- **Privacy Nutrition Labels in ASC**: Set **manually** in App Store Connect dashboard before running `fastlane release`. Phase 28 plan adds a manual checklist task: log into ASC → Privacy → set labels matching PrivacyInfo.xcprivacy + Phase 27.1 disclosures (AdMob Device ID, Advertising Data, Coarse Location with Tracking=true; ElevenLabs voice data; Firebase, Mapbox, Clerk). Deliverfile is NOT used to automate nutrition labels — fastlane's coverage of that surface is limited and manual is the standard for v1.

### Release Checklist (criterion #6)
- **Location**: New section in `.planning/PROJECT.md` called **"Release Process"**. Criterion #6 says "documented in PROJECT.md" — match the spec literally.
- **Required post-release steps the checklist must enforce**:
  - `git tag v1.0.0` + `git push origin v1.0.0`
  - Update `.planning/MILESTONES.md` with v1.0.0 release entry (date, build number, App Store status)
  - Monitor App Store Connect daily until status transitions: `Waiting for Review` → `In Review` → `Approved` (or `Metadata Rejected` / `Binary Rejected`)
- **Out of scope for the checklist**: Slack/Twitter announcements, marketing playbook, milestone archive (`/gsd:complete-milestone` handles archive separately).

### Claude's Discretion
- Exact Fastfile syntax for the `precheck` lane (Ruby helpers, error messages)
- How to structure the metadata audit task (manual diff vs. scripted check)
- Exact wording of the PROJECT.md "Release Process" section (just hit the required steps)
- Ordering of tasks within the phase (but `precheck` lane and metadata audit should come BEFORE `beta_internal` upload)
- How to handle Xcode/SDK version detection (what command to run, where to record the result)

</decisions>

<specifics>
## Specific Ideas

- **Solo dev mode**: Phase 28 is one developer running through this for the first time. Optimize for "if I forget a step, the lane catches it" over "we have a release manager."
- **Phase 27.1 was just completed (2026-04-07)** — its AdMob tracker reconciliation is the most recent context that needs to flow into metadata copy and privacy labels.
- **Treat the existing Fastfile + Deliverfile as the source of truth.** The phase 22 implementation works in principle — phase 28 only needs to add `precheck`, run it for real, and patch anything that breaks at upload time.
- The user's `.env` file already has real API key values (`APP_STORE_CONNECT_API_KEY_ID=SW484SVH7L`, demo account `ersinkirteke+sandbox@gmail.com`). Don't regenerate, just verify access works.
- "It's the first real submission, so expect at least one round of fixes before `Waiting for Review`."

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Kindred/fastlane/Fastfile`: Already has 3 lanes — `beta_internal`, `beta_external`, `release`. Phase 28 extends with `precheck` lane and wires it into `beta_internal` + `release`.
- `Kindred/fastlane/Deliverfile`: Already configured with FOOD_AND_DRINK category, automatic_release, export compliance, metadata/screenshot paths. Reuse as-is.
- `Kindred/fastlane/Appfile`: Bundle ID `com.ersinkirteke.kindred`, Team ID `CV9G42QVG4` configured.
- `Kindred/fastlane/.env`: Real ASC API key + demo credentials already populated. Verify, don't recreate.
- `Kindred/fastlane/metadata/en-US/` + `tr/`: Full metadata set exists (description, keywords, subtitle, release_notes, promotional_text, support_url, privacy_url, marketing_url). Phase 28 audits + patches, doesn't recreate.
- `Kindred/fastlane/screenshots/en-US/` + `tr/`: 5 PNGs per locale (01-voice-narration through 05-recipe-detail) — exist on disk per `git status`.
- `Kindred/fastlane/metadata/review_information/notes.txt`: Already includes ElevenLabs disclosure, AdMob disclosure, demo account, age rating, export compliance.
- `Kindred/docs/pre-submission-checklist.md`: 146-line checklist with go/no-go criteria. Phase 28 reuses for the bug bar gate.
- `Kindred/docs/what-to-test.md`: Tester guide with 6 core flows. Phase 28 hands this to internal testers.
- `Kindred/docs/screenshot-guide.md`: Reference doc, screenshots already created so no-op for phase 28.

### Established Patterns
- **XcodeGen**: `Kindred/project.yml` is the source of truth for project config. `MARKETING_VERSION = "1.0.0"`, `CURRENT_PROJECT_VERSION = "1"`, `deploymentTarget.iOS = "17.0"`. Fastfile bumps build number directly via `increment_build_number(xcodeproj: "Kindred.xcodeproj", ...)`, NOT via project.yml.
- **Bundle ID / Team**: `com.ersinkirteke.kindred` / `CV9G42QVG4` — wired into Appfile, Deliverfile, and project.yml.
- **Build numbering**: `number_of_commits` (already implemented in all 3 lanes).
- **Release config**: `Kindred/Config/Release.xcconfig` contains production AdMob IDs, Clerk publishable key, API base URL. Pre-flight checks must grep this file for `REPLACE_WITH_` placeholders.
- **Privacy manifest**: `Kindred/PrivacyInfo.xcprivacy` is the source of truth for what's declared. ASC nutrition labels must match. Phase 27.1 verification report has the latest reconciled view.

### Integration Points
- **ASC API key path**: `Kindred/fastlane/.env` → `APP_STORE_CONNECT_API_KEY_FILEPATH=/Users/ersinkirteke/Downloads/AuthKey_SW484SVH7L.p8`. Pre-flight check must verify this path is readable.
- **Fastfile `before_all`**: Already enforces `ensure_git_status_clean` and chdir to project root. Reuse, do not rewrite.
- **`upload_to_testflight`**: Uses `Internal Testers` group for `beta_internal`. Group must already exist in App Store Connect (per pre-submission-checklist.md). Phase 28 verifies group exists as part of human checklist before first run.
- **`upload_to_app_store`**: In the `release` lane, takes `submission_information` for export compliance. Already configured. ASC nutrition labels are NOT in this call — set manually in dashboard.
- **PROJECT.md**: `.planning/PROJECT.md` line ~134 already mentions "Build: Fastlane with 3 lanes". Phase 28 adds new "Release Process" section.

</code_context>

<deferred>
## Deferred Ideas

- **External TestFlight beta** (50–100 testers, public link, Reddit/Product Hunt) — Phase 22 prep covered the metadata, but execution is deferred. Solo dev v1.0 ships without it.
- **Phased release** (1% → 100% over 7 days) — Phase 22 deferred for v1.0, Phase 28 keeps automatic full release.
- **Slack/Twitter launch announcement template + marketing playbook** — out of scope for the release checklist. Belongs in a separate launch comms doc.
- **Firebase Crashlytics zero-crash threshold as a gate** — would require Crashlytics being wired up and enough beta volume to be statistically meaningful. Reuse pre-submission-checklist.md instead.
- **`xcodebuild test` in the precheck lane** — skipped to keep the lane fast. Could be added later if the test suite stabilizes.
- **Splitting `release` into build + submit lanes** — declined for one-shot simplicity. Could be added later if the human-eyeball-before-Apple-review pattern becomes valuable.
- **Automating Privacy Nutrition Labels via Deliverfile** — fastlane's coverage is limited; phase 28 keeps it manual. Could revisit if fastlane adds better support.
- **Splitting deprecation warning fixes into a separate cleanup phase** — phase 28 owns this work as part of the SDK rebuild. If it explodes in scope during planning, can be reconsidered.
- **iPad native support** — Phase 22 deferred, phase 28 stays iPhone-only.
- **App Preview video** — Phase 22 deferred, no video for v1.0.
- **Localization beyond en-US + tr** — Phase 22 deferred, future milestone.
- **GSD milestone archive flow** (`/gsd:complete-milestone` for v5.0) — happens after phase 28 ships, not part of phase 28 itself.

</deferred>

---

*Phase: 28-fastlane-release-automation*
*Context gathered: 2026-04-08*
