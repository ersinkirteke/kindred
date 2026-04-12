# Phase 28: Fastlane Release Automation - Research

**Researched:** 2026-04-08
**Domain:** iOS App Store submission automation with fastlane
**Confidence:** HIGH

## Summary

Phase 28 automates the final mile from "internal beta tested" to "Waiting for Review" in App Store Connect by executing the existing fastlane release lane, adding pre-flight validation, and documenting the release process. The fastlane infrastructure (Fastfile, Deliverfile, Appfile, metadata, screenshots, review notes) was implemented in Phase 22 and updated through Phases 27/27.1 for compliance. This phase is execution + hardening, not greenfield setup.

The user has Xcode 26.4 with iOS 26.4 SDK installed, meeting Apple's April 28, 2026 deadline for all App Store submissions. The deployment target stays at iOS 17.0 (preserving install base). Phase 27.1 closed the AdMob privacy gap (PrivacyInfo.xcprivacy + review notes + policy updated), so compliance artifacts are App Store-ready. The existing release lane uses `number_of_commits` for reproducible build numbering, API key authentication (avoiding password prompts), and `automatic_release: true` for instant publication upon approval.

**Primary recommendation:** Add a `precheck` lane that validates configuration files, metadata completeness, and screenshot presence before any upload. Wire it into both `beta_internal` and `release` lanes as a fail-fast gate. Execute a fresh TestFlight internal beta build, run a 48-72 hour bake with 3+ testers using the existing pre-submission-checklist.md go/no-go criteria, manually set Privacy Nutrition Labels in App Store Connect to match PrivacyInfo.xcprivacy + Phase 27.1 AdMob disclosures, then execute `fastlane release` for first-time submission. Document the post-release checklist (git tag, MILESTONES.md update, monitor review status) in `.planning/PROJECT.md`.

## User Constraints

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **TestFlight Beta Strategy**: Solo dev path — me + 2 friends/family. No external Beta App Review needed (uses existing Internal Testers TestFlight group from Phase 22). Bake duration: 48–72 hours minimum. Bug bar: Reuse `Kindred/docs/pre-submission-checklist.md` go/no-go criteria exactly. Ship if zero crashers + onboarding/feed/voice/pantry/purchase all work. Block if any crash in core flow. Minor UI glitches acceptable. Phase 28 starts by running `fastlane beta_internal` to upload a fresh build from current main (includes Phase 27.1 AdMob fixes + any post-Phase-22 changes). Do NOT reuse stale TestFlight builds. Sequence: `beta_internal` → 48–72hr bake → checklist passes → `fastlane release`.

- **SDK / Build Configuration**: Deployment target stays at iOS 17.0. Do NOT bump min iOS — preserves install base for users on older devices. Build with current Xcode 16.x against the latest available iOS SDK shipped with that Xcode. User confirms Xcode 16.x is already installed locally. Criterion #5 interpretation: ROADMAP says "Xcode 16 + iOS 26 SDK". Today (April 2026) the latest stable is whatever current Xcode 16.x ships with. Treat the criterion as "build with the latest available SDK" rather than literal iOS 26. Plan should detect actual SDK version during the build task and document what shipped. Phase 28 includes a task to scan and **fix all deprecation warnings** surfaced by building Release configuration with the new SDK. Not just compiler errors — fix the warnings too. Anything that can't be fixed cleanly gets logged as deferred for a future cleanup phase.

- **Release Lane Sequencing & Gates**: Keep `fastlane release` as one shot — increment_build → build_app → upload_to_app_store(submit_for_review: true, automatic_release: true). Already implemented in Fastfile from Phase 22, do NOT split. Keep `automatic_release: true`. App goes live the moment Apple approves. No manual "Release" click. Phased release stays deferred (Phase 22 decision). Keep `number_of_commits` strategy from existing Fastfile. Reproducible, monotonic, works for solo dev. Add a new `precheck` lane that `release` (and ideally `beta_internal`) calls before doing any work. Fail-fast safety. Must verify: (1) `Kindred/Config/Release.xcconfig` contains no `REPLACE_WITH_*` placeholder values, (2) `Kindred/fastlane/.env` exists and has all required keys (APP_STORE_CONNECT_API_KEY_ID, APP_STORE_CONNECT_ISSUER_ID, APP_STORE_CONNECT_API_KEY_FILEPATH), (3) The `.p8` file at the configured path is readable, (4) Required metadata files exist and are non-empty in both `metadata/en-US/` and `metadata/tr/`, (5) All 5 screenshots exist per locale in `screenshots/en-US/` and `screenshots/tr/`, (6) Git status is clean (already enforced by `before_all`). Tests in pre-flight: Skipped — no `xcodebuild test` in precheck. Keeps lane fast.

- **Metadata Re-validation & Privacy Labels**: Yes — re-read `metadata/en-US/description.txt`, `keywords.txt`, `promotional_text.txt`, `release_notes.txt` and cross-check against current `Kindred/PrivacyInfo.xcprivacy` + Phase 27.1 verification report. Phase 22 metadata was written before AdMob tracker reality was reconciled, so AdMob/tracker disclosure language may need updates. Same audit applies to `metadata/tr/` files (keep tr translation in sync if en-US changes). Privacy Nutrition Labels in ASC: Set **manually** in App Store Connect dashboard before running `fastlane release`. Phase 28 plan adds a manual checklist task: log into ASC → Privacy → set labels matching PrivacyInfo.xcprivacy + Phase 27.1 disclosures (AdMob Device ID, Advertising Data, Coarse Location with Tracking=true; ElevenLabs voice data; Firebase, Mapbox, Clerk). Deliverfile is NOT used to automate nutrition labels — fastlane's coverage of that surface is limited and manual is the standard for v1.

- **Release Checklist (criterion #6)**: New section in `.planning/PROJECT.md` called **"Release Process"**. Criterion #6 says "documented in PROJECT.md" — match the spec literally. Required post-release steps the checklist must enforce: (1) `git tag v1.0.0` + `git push origin v1.0.0`, (2) Update `.planning/MILESTONES.md` with v1.0.0 release entry (date, build number, App Store status), (3) Monitor App Store Connect daily until status transitions: `Waiting for Review` → `In Review` → `Approved` (or `Metadata Rejected` / `Binary Rejected`). Out of scope for the checklist: Slack/Twitter announcements, marketing playbook, milestone archive (`/gsd:complete-milestone` handles archive separately).

### Claude's Discretion
- Exact Fastfile syntax for the `precheck` lane (Ruby helpers, error messages)
- How to structure the metadata audit task (manual diff vs. scripted check)
- Exact wording of the PROJECT.md "Release Process" section (just hit the required steps)
- Ordering of tasks within the phase (but `precheck` lane and metadata audit should come BEFORE `beta_internal` upload)
- How to handle Xcode/SDK version detection (what command to run, where to record the result)

### Deferred Ideas (OUT OF SCOPE)
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
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| STORE-01 | Fastlane release lane automates binary upload, metadata sync, and submission | Existing Fastfile has complete `release` lane (increment_build, build_app, upload_to_app_store with submit_for_review: true). Research confirms upload_to_app_store automatically syncs metadata from fastlane/metadata/ directory. Add precheck lane for pre-flight validation. |
| STORE-04 | TestFlight internal beta test completed before App Store submission | Existing Fastfile has `beta_internal` lane using upload_to_testflight with distribute_external: false, groups: ["Internal Testers"]. Research confirms skip_waiting_for_build_processing: false means lane waits for build processing before returning. 48-72hr bake using existing pre-submission-checklist.md go/no-go criteria. |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| fastlane | ~> 2.225 | iOS/Android release automation | Industry standard for App Store/TestFlight automation — 42.9k GitHub stars, active 2026 development, official Apple documentation references |
| Bundler | Latest | Ruby dependency management | Recommended fastlane installation method (prevents version drift, locks Gemfile) |
| Xcode 26.4 | 26.4 (Build 17E192) | iOS SDK for building | Apple mandates Xcode 26 + iOS 26 SDK for all submissions after April 28, 2026. User has this installed. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| App Store Connect API | v2 | Passwordless authentication | Required for CI/CD, best practice for manual releases (avoids 2FA prompts). User already has .p8 key configured. |
| deliver (built into fastlane) | Latest | Metadata upload & submission | Automatically used by upload_to_app_store action |
| pilot (built into fastlane) | Latest | TestFlight upload | Automatically used by upload_to_testflight action |
| precheck (built into fastlane) | Latest | Metadata validation | Run via deliver by default, can run standalone. Limited rule set (profanity, placeholders, platform mentions). |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| fastlane | Manual Xcode Archive → Organizer → Upload | Manual process error-prone, no metadata sync, no pre-flight checks. fastlane automates entire flow. |
| App Store Connect API | Apple ID password auth | Password auth requires 2FA prompts, breaks CI/CD. API key is best practice. |
| number_of_commits build numbering | Timestamp-based (YYMMDDHHmm) | Timestamp allows multiple builds same day but harder to correlate with git history. Commits = reproducible, monotonic, git-aligned. |
| automatic_release: true | Manual release button click | Manual click adds human bottleneck after approval. Solo dev benefits from instant release. |

**Installation:**
```bash
# Already installed (Phase 22). Verify:
cd Kindred/fastlane
bundle install
bundle exec fastlane --version
# Expect: fastlane 2.225.x or later
```

## Architecture Patterns

### Recommended Project Structure
```
Kindred/
├── fastlane/
│   ├── Appfile                    # Team ID, bundle ID
│   ├── Deliverfile                # Submission config (category, automatic_release, export compliance)
│   ├── Fastfile                   # Lanes: beta_internal, beta_external, release, (NEW: precheck)
│   ├── .env                       # API keys (gitignored)
│   ├── .env.default               # Template
│   ├── Gemfile                    # fastlane version lock
│   ├── Gemfile.lock               # Dependency lock
│   ├── metadata/
│   │   ├── en-US/                 # English metadata
│   │   │   ├── name.txt
│   │   │   ├── subtitle.txt
│   │   │   ├── description.txt
│   │   │   ├── keywords.txt
│   │   │   ├── promotional_text.txt
│   │   │   ├── release_notes.txt
│   │   │   ├── support_url.txt
│   │   │   ├── privacy_url.txt
│   │   │   └── marketing_url.txt
│   │   ├── tr/                    # Turkish metadata (same files)
│   │   └── review_information/
│   │       └── notes.txt          # Reviewer instructions (ElevenLabs, AdMob, demo account)
│   └── screenshots/
│       ├── en-US/                 # 5 PNGs (01-voice through 05-recipe-detail)
│       └── tr/                    # 5 PNGs (same naming)
├── Config/
│   ├── Debug.xcconfig             # Dev AdMob IDs, Clerk test key, dev API URL
│   └── Release.xcconfig           # Prod AdMob IDs, Clerk prod key, prod API URL
├── Sources/
│   ├── PrivacyInfo.xcprivacy      # Privacy manifest (12 data types post-Phase 27.1)
│   └── Info.plist                 # Bundle ID, version, entitlements reference
├── docs/
│   ├── pre-submission-checklist.md  # Go/no-go criteria (146 lines, 8 sections)
│   ├── what-to-test.md             # Tester guide (6 core flows)
│   └── screenshot-guide.md         # Screenshot refresh guide (already executed)
└── .planning/
    ├── PROJECT.md                  # (WILL ADD: Release Process section)
    └── MILESTONES.md               # (WILL UPDATE: v1.0.0 entry post-approval)
```

### Pattern 1: Pre-Flight Validation Lane

**What:** A dedicated `precheck` lane that runs before any upload to catch configuration errors early.

**When to use:** Call from `beta_internal` and `release` lanes before `build_app` action. Fail fast if placeholders exist or files missing.

**Example:**
```ruby
# Source: Derived from fastlane best practices + Kindred context
desc "Pre-flight checks before upload (fail fast on config errors)"
lane :precheck do
  # 1. Verify Release.xcconfig has no placeholders
  release_config = File.read("../Config/Release.xcconfig")
  if release_config.include?("REPLACE_WITH_")
    UI.user_error!("❌ Release.xcconfig contains REPLACE_WITH_ placeholders. Fix before release.")
  end
  UI.success("✅ Release.xcconfig: No placeholders found")

  # 2. Verify .env file exists and has required keys
  env_path = File.join(Dir.pwd, ".env")
  unless File.exist?(env_path)
    UI.user_error!("❌ fastlane/.env file not found. Copy from .env.default and fill in values.")
  end

  env_content = File.read(env_path)
  required_keys = ["APP_STORE_CONNECT_API_KEY_ID", "APP_STORE_CONNECT_ISSUER_ID", "APP_STORE_CONNECT_API_KEY_FILEPATH"]
  required_keys.each do |key|
    unless env_content.include?(key)
      UI.user_error!("❌ fastlane/.env missing required key: #{key}")
    end
  end
  UI.success("✅ .env file: All required keys present")

  # 3. Verify .p8 API key file is readable
  p8_path = ENV["APP_STORE_CONNECT_API_KEY_FILEPATH"]
  unless File.exist?(p8_path) && File.readable?(p8_path)
    UI.user_error!("❌ .p8 API key file not found or not readable: #{p8_path}")
  end
  UI.success("✅ .p8 API key file: Readable at #{p8_path}")

  # 4. Verify metadata files exist and are non-empty for both locales
  %w[en-US tr].each do |locale|
    required_files = %w[name.txt subtitle.txt description.txt keywords.txt promotional_text.txt release_notes.txt support_url.txt privacy_url.txt marketing_url.txt]
    required_files.each do |file|
      path = File.join(Dir.pwd, "metadata", locale, file)
      unless File.exist?(path) && File.size(path) > 0
        UI.user_error!("❌ Missing or empty metadata file: metadata/#{locale}/#{file}")
      end
    end
  end
  UI.success("✅ Metadata files: All required files present for en-US and tr")

  # 5. Verify screenshots (5 per locale)
  %w[en-US tr].each do |locale|
    screenshot_dir = File.join(Dir.pwd, "screenshots", locale)
    screenshots = Dir.glob(File.join(screenshot_dir, "*.png"))
    unless screenshots.count == 5
      UI.user_error!("❌ Expected 5 screenshots in screenshots/#{locale}/, found #{screenshots.count}")
    end
  end
  UI.success("✅ Screenshots: 5 files present for en-US and tr")

  # 6. Git status clean (already checked in before_all, but belt-and-suspenders)
  ensure_git_status_clean

  UI.success("🎉 All pre-flight checks passed!")
end
```

**Integration into existing lanes:**
```ruby
lane :beta_internal do
  precheck  # NEW: Fail fast before building

  Dir.chdir("..") do
    increment_build_number(xcodeproj: "Kindred.xcodeproj", build_number: number_of_commits)
  end

  Dir.chdir("..") do
    build_app(scheme: "Kindred", configuration: "Release", export_method: "app-store")
  end

  upload_to_testflight(
    skip_waiting_for_build_processing: false,
    distribute_external: false,
    groups: ["Internal Testers"]
  )

  UI.success("Internal beta build uploaded successfully!")
end

lane :release do
  precheck  # NEW: Fail fast before building

  Dir.chdir("..") do
    increment_build_number(xcodeproj: "Kindred.xcodeproj", build_number: number_of_commits)
  end

  Dir.chdir("..") do
    build_app(scheme: "Kindred", configuration: "Release", export_method: "app-store")
  end

  upload_to_app_store(
    submit_for_review: true,
    automatic_release: true,
    submission_information: {
      add_id_info_uses_idfa: false,
      export_compliance_uses_encryption: true,
      export_compliance_encryption_updated: false,
      export_compliance_is_exempt: true
    }
  )

  UI.success("App submitted to App Store successfully!")
end
```

### Pattern 2: Build Number Management with Git Commits

**What:** Use `number_of_commits` action to derive build number from git commit count. Reproducible and monotonic.

**When to use:** Every build (beta, release). Already implemented in Kindred Fastfile.

**Example:**
```ruby
# Source: Existing Kindred/fastlane/Fastfile
increment_build_number(
  xcodeproj: "Kindred.xcodeproj",
  build_number: number_of_commits
)
```

**Why:** Build numbers must be unique and increasing. Git commit count guarantees both properties. Allows correlating builds with git history (`git log --oneline | wc -l` = build number).

### Pattern 3: Metadata Sync via Directory Convention

**What:** fastlane's `upload_to_app_store` automatically reads metadata from `fastlane/metadata/<locale>/` and syncs to App Store Connect.

**When to use:** Every release. Already configured in Kindred Deliverfile (`metadata_path "./fastlane/metadata"`).

**Example:**
```ruby
# Source: Kindred/fastlane/Deliverfile
metadata_path "./fastlane/metadata"
screenshots_path "./fastlane/screenshots"

# No explicit file passing needed — upload_to_app_store reads these paths automatically
```

**Files synced:**
- `name.txt` → App Name
- `subtitle.txt` → App Subtitle
- `description.txt` → App Description
- `keywords.txt` → Search Keywords (comma-separated)
- `promotional_text.txt` → Promotional Text (updatable without new version)
- `release_notes.txt` → What's New in This Version
- `support_url.txt`, `privacy_url.txt`, `marketing_url.txt` → URLs
- `review_information/notes.txt` → App Review Information (demo account, notes)

**Screenshots:** PNG files in `screenshots/<locale>/` are uploaded automatically. Must be named to indicate device size or use Deliver's naming convention (`01-*.png`, `02-*.png`, etc.).

### Anti-Patterns to Avoid

- **Committing `.env` or `.p8` files to git:** API keys are secrets. Use `.gitignore`. Template with `.env.default` instead.
- **Manual build number increments:** Error-prone, breaks on merge conflicts. Use `number_of_commits` or `app_store_build_number + 1` strategies.
- **Skipping git status check:** Dirty working tree = untracked changes in binary. Use `ensure_git_status_clean` in `before_all`.
- **Hardcoding API credentials in Fastfile:** Use environment variables (`ENV["KEY"]`) loaded from `.env` file.
- **Running `fastlane release` without testing beta first:** Always run `beta_internal` → test → fix → `release` sequence. Never submit untested builds.
- **Forgetting to set Privacy Nutrition Labels manually:** fastlane's `upload_app_privacy_details_to_app_store` action requires Apple ID password auth (no API key support) and has limited adoption. Manual ASC dashboard setup is the standard for v1.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Metadata upload to ASC | Custom script parsing metadata files and calling App Store Connect API | fastlane deliver (`upload_to_app_store` action) | Deliver handles ASC API authentication, metadata format conversion, screenshot upload, multi-locale sync, and submission. Custom scripts miss edge cases (special characters, multi-byte locales, API rate limits, incremental updates). |
| TestFlight beta distribution | Manual Xcode Organizer upload + manual tester group assignment | fastlane pilot (`upload_to_testflight` action) | Pilot waits for build processing, assigns tester groups, sets changelog, handles external review submission. Manual process requires watching ASC for "Processing" → "Ready to Submit" transition. |
| Build number increments | Shell script reading .xcodeproj, parsing pbxproj, incrementing, writing back | fastlane `increment_build_number` action | Action handles Xcode project parsing, multi-target updates, validation. Custom scripts break on xcodeproj format changes or XcodeGen regeneration. |
| Pre-flight config validation | No validation (discover errors during upload) | Dedicated `precheck` lane (custom Ruby checks) | Upload failures waste 10-30 minutes (build → archive → upload → reject). Pre-flight checks catch placeholder values, missing files, bad credentials in < 10 seconds. |
| Code signing | Manual certificate download, profile selection, `codesign` commands | Xcode Automatic Signing or fastlane match | Code signing is the #1 source of iOS build failures. Xcode Automatic Signing works for solo dev (already used by Kindred per project.yml). match scales to teams. Custom `codesign` scripts break on certificate expiry. |

**Key insight:** fastlane's actions encapsulate years of community battle-testing against App Store Connect API quirks, Xcode project format changes, and Apple policy updates. Re-implementing metadata upload, TestFlight distribution, or build number management manually means debugging the same edge cases (multi-byte characters in Turkish metadata, API token refresh timing, incremental screenshot updates) that fastlane already solved.

## Common Pitfalls

### Pitfall 1: Placeholder Values in Release.xcconfig Reaching Production

**What goes wrong:** Developer forgets to replace `REPLACE_WITH_PRODUCTION_ADMOB_APP_ID` in `Config/Release.xcconfig` before running `fastlane release`. Build succeeds, uploads to ASC, but app crashes on launch with `fatalError("AdMob App ID not configured")`.

**Why it happens:** No automated check catches placeholder values. Release build configuration isn't tested locally (devs use Debug config). Upload doesn't validate runtime config values.

**How to avoid:** Add placeholder check to `precheck` lane (pattern shown above). Grep `Release.xcconfig` for `REPLACE_WITH_` string and fail with clear error before building. Run Release configuration build on device before uploading to catch runtime crashes.

**Warning signs:** `fatalError` or `precondition` calls in code that check config values. TestFlight crash reports showing "App ID not configured" errors.

### Pitfall 2: Stale TestFlight Builds Used for Submission Validation

**What goes wrong:** Developer re-uses a 2-week-old TestFlight build for beta testing, assuming "it's already uploaded, save time." That build predates recent bug fixes (e.g., Phase 27.1 AdMob compliance updates). Beta testing passes on stale build, but `fastlane release` uploads a newer build with untested changes. Regression slips through.

**Why it happens:** Misunderstanding of build freshness. TestFlight shows "latest" build, but "latest uploaded" ≠ "latest committed code."

**How to avoid:** Phase 28 CONTEXT mandates "fresh build from current main" for beta testing. Always run `fastlane beta_internal` at start of submission sequence, not reuse old uploads. Build number increments on every commit, so build number mismatch = stale build.

**Warning signs:** Build number in TestFlight doesn't match `git log --oneline | wc -l`. Testers report "I don't see the fix you mentioned."

### Pitfall 3: Privacy Nutrition Labels Out of Sync with PrivacyInfo.xcprivacy

**What goes wrong:** Developer updates `PrivacyInfo.xcprivacy` to add AdMob tracking data types (Phase 27.1) but forgets to mirror changes in App Store Connect Privacy section. Submission succeeds, but App Store page shows incomplete privacy labels. Users see "This app may collect X" but label omits "Device ID for tracking."

**Why it happens:** Privacy labels are set in TWO places: `PrivacyInfo.xcprivacy` (runtime manifest for iOS 17+ Privacy Report) and ASC Privacy dashboard (public-facing nutrition labels). fastlane's `upload_app_privacy_details_to_app_store` action has limited adoption and requires password auth (no API key support). Developers assume one-time ASC setup persists across updates, but certain changes (new data types, tracking status flips) require manual re-entry.

**How to avoid:** Add manual checklist task: "Set Privacy Nutrition Labels in ASC before running `fastlane release`." Cross-reference `PrivacyInfo.xcprivacy` data types with ASC form. Phase 27.1 verification report lists exact entries to add (Device ID, Advertising Data, Coarse Location with Tracking=true). Schedule quarterly audit: `plutil -p PrivacyInfo.xcprivacy` → compare ASC dashboard.

**Warning signs:** iOS 17+ Privacy Report shows different data types than App Store privacy labels. User reviews mentioning "misleading privacy claims."

### Pitfall 4: App Store Connect API Key File (.p8) Expires or Moves

**What goes wrong:** User generates .p8 API key, saves to `/Users/ersinkirteke/Downloads/AuthKey_SW484SVH7L.p8`, configures path in `.env` file. Six months later, Downloads folder cleaned, .p8 deleted. `fastlane release` fails with "API key file not found" error mid-upload.

**Why it happens:** API keys don't expire (persist until revoked), but file storage is transient. Downloads folder auto-cleanup, system reinstalls, or drive migrations lose the file. `.env` hardcodes absolute path, breaking on file moves.

**How to avoid:** Store .p8 file in durable location (`~/.appstoreconnect/AuthKey_<ID>.p8`) or password manager. Add file existence check to `precheck` lane (pattern shown above). Document recovery: regenerate .p8 from App Store Connect → Users & Access → Integrations → API Keys if original lost.

**Warning signs:** `fastlane` errors with "authentication failed" or "file not found" on API key path. Worked yesterday, fails today after system change.

### Pitfall 5: Deprecation Warnings Ignored Until Xcode 26 SDK Blocks Submission

**What goes wrong:** App builds cleanly with Xcode 15 + iOS 25 SDK. Developer upgrades to Xcode 26 (mandated April 28, 2026) and suddenly sees 50+ deprecation warnings (`UIWebView` deprecated, `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)` signature changed). Warnings don't block compilation, so developer proceeds with upload. Apple rejects binary: "Uses deprecated APIs — update to iOS 26 equivalents."

**Why it happens:** Xcode 26 SDK deprecates APIs that worked in iOS 25 SDK. Warnings are noise until they become errors or rejection reasons. Developers disable "Treat Warnings as Errors" to ship faster, accumulating tech debt.

**How to avoid:** Phase 28 CONTEXT mandates "fix all deprecation warnings" as explicit task. Build with Release configuration + Xcode 26 SDK, export build log, grep for "deprecated" and "warning:", fix each instance. Enable `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES` in Release build settings (Phase 28 can add this). Anything unfixable gets logged as deferred cleanup ticket.

**Warning signs:** Xcode Issue Navigator shows yellow triangles. Build log contains "will be removed in future SDK" messages. Apple rejection reason: "Deprecated API usage."

### Pitfall 6: Metadata Contains Platform References (Android, Blackberry) Causing Rejection

**What goes wrong:** `metadata/en-US/description.txt` includes line "Available on Android soon!" or "Better than Android apps." fastlane `precheck` scans for platform mentions and warns, but developer ignores (warning, not error). Submission goes through, Apple rejects: "Metadata references other platforms."

**Why it happens:** Apple App Store Review Guidelines prohibit mentioning competing platforms in metadata. fastlane's built-in `precheck` action detects this (rule: `platform_references`) but defaults to `:warn`, not `:error`. Warnings scrolled past in fastlane output.

**How to avoid:** Review `metadata/en-US/description.txt` and `tr/description.txt` before submission. Remove "Android," "Google Play," "Blackberry," platform comparisons. Optionally configure Precheckfile to escalate platform_references to `:error` level. Phase 28 metadata audit task should explicitly check for this.

**Warning signs:** fastlane output shows "⚠️ Platform reference detected: Android." Apple rejection reason: "Your app's metadata mentions other mobile platforms."

## Code Examples

Verified patterns from official sources:

### Pre-Flight Configuration Validation

```ruby
# Source: Derived from fastlane best practices + Kindred-specific checks
desc "Pre-flight checks before upload"
lane :precheck do
  # Verify no placeholder values in Release.xcconfig
  release_config = File.read("../Config/Release.xcconfig")
  if release_config.include?("REPLACE_WITH_")
    UI.user_error!("❌ Release.xcconfig contains REPLACE_WITH_ placeholders")
  end

  # Verify .env file completeness
  required_keys = ["APP_STORE_CONNECT_API_KEY_ID", "APP_STORE_CONNECT_ISSUER_ID", "APP_STORE_CONNECT_API_KEY_FILEPATH"]
  env_content = File.read(".env")
  required_keys.each do |key|
    unless env_content.include?(key)
      UI.user_error!("❌ .env missing: #{key}")
    end
  end

  # Verify API key file exists
  p8_path = ENV["APP_STORE_CONNECT_API_KEY_FILEPATH"]
  unless File.exist?(p8_path)
    UI.user_error!("❌ .p8 file not found: #{p8_path}")
  end

  # Verify metadata completeness for both locales
  %w[en-US tr].each do |locale|
    %w[name.txt subtitle.txt description.txt keywords.txt].each do |file|
      path = "metadata/#{locale}/#{file}"
      unless File.exist?(path) && File.size(path) > 0
        UI.user_error!("❌ Missing/empty: #{path}")
      end
    end
  end

  UI.success("✅ All pre-flight checks passed")
end
```

### Upload to TestFlight (Existing)

```ruby
# Source: Kindred/fastlane/Fastfile (Phase 22 implementation)
desc "Build and distribute internal TestFlight beta"
lane :beta_internal do
  Dir.chdir("..") do
    increment_build_number(
      xcodeproj: "Kindred.xcodeproj",
      build_number: number_of_commits
    )
  end

  Dir.chdir("..") do
    build_app(
      scheme: "Kindred",
      configuration: "Release",
      export_method: "app-store"
    )
  end

  upload_to_testflight(
    skip_waiting_for_build_processing: false,  # Wait for ASC processing
    distribute_external: false,                # Internal testers only
    groups: ["Internal Testers"]              # Must exist in ASC
  )

  UI.success("Internal beta build uploaded successfully!")
end
```

### Upload to App Store with Submission (Existing)

```ruby
# Source: Kindred/fastlane/Fastfile (Phase 22 implementation)
desc "Build and submit to App Store"
lane :release do
  Dir.chdir("..") do
    increment_build_number(
      xcodeproj: "Kindred.xcodeproj",
      build_number: number_of_commits
    )
  end

  Dir.chdir("..") do
    build_app(
      scheme: "Kindred",
      configuration: "Release",
      export_method: "app-store"
    )
  end

  upload_to_app_store(
    submit_for_review: true,              # Automatically submit after upload
    automatic_release: true,              # Go live immediately upon approval
    submission_information: {
      add_id_info_uses_idfa: false,       # No IDFA for app functionality
      export_compliance_uses_encryption: true,
      export_compliance_encryption_updated: false,
      export_compliance_is_exempt: true  # HTTPS-only = exempt
    }
  )

  UI.success("App submitted to App Store successfully!")
end
```

### Detect Xcode and SDK Version

```bash
# Source: Standard Xcode command-line tools
# Run before first build to document what SDK shipped

# Get Xcode version
xcodebuild -version
# Output: Xcode 26.4 / Build version 17E192

# Get iOS SDK version
xcodebuild -showsdks | grep -i "iOS SDK"
# Output: iOS SDKs: iOS 26.4 -sdk iphoneos26.4

# Extract just version number for logging
SDK_VERSION=$(xcodebuild -showsdks | grep "iphoneos" | awk '{print $2}' | head -1)
echo "Building with iOS SDK: $SDK_VERSION"
```

### Scan for Deprecation Warnings

```bash
# Source: Standard Xcode build log analysis
# Run before first beta upload

# Build with Release config and capture build log
cd Kindred
xcodebuild clean build \
  -scheme Kindred \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  | tee /tmp/kindred-build.log

# Extract deprecation warnings
grep -i "deprecated" /tmp/kindred-build.log > /tmp/deprecations.txt
grep -i "warning:" /tmp/kindred-build.log | grep -i "will be removed" >> /tmp/deprecations.txt

# Count warnings
echo "Deprecation warnings found: $(wc -l < /tmp/deprecations.txt)"

# Review and fix each warning before proceeding to beta
```

### Post-Release Git Tagging

```ruby
# Source: fastlane add_git_tag action docs
desc "Tag release after App Store approval"
lane :tag_release do
  version = get_version_number(xcodeproj: "Kindred.xcodeproj", target: "Kindred")
  build = get_build_number(xcodeproj: "Kindred.xcodeproj")

  add_git_tag(
    tag: "v#{version}",
    message: "Release v#{version} (build #{build}) — Submitted to App Store"
  )

  push_git_tags

  UI.success("Tagged and pushed v#{version} to git")
end
```

**Note:** Phase 28 CONTEXT specifies manual `git tag v1.0.0 && git push origin v1.0.0` in post-release checklist. The `tag_release` lane above is optional automation for future releases.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Apple ID password auth for fastlane | App Store Connect API keys (.p8) | June 2023 (fastlane 2.213) | Eliminates 2FA prompts, enables CI/CD, better security (revocable keys). Kindred already uses API keys. |
| Manual Xcode Organizer upload | `upload_to_app_store` action | Industry standard since fastlane 1.0 (2015) | Automates metadata sync, screenshot upload, submission. 90%+ of production iOS apps use fastlane. |
| `precheck` default level `:warn` | Custom pre-flight lane with `:error` fails | Ongoing (fastlane precheck has limited rules) | Built-in precheck catches platform mentions, profanity, placeholders but as warnings. Custom lane adds hard fails for config-specific checks (Release.xcconfig placeholders, .env completeness). |
| offset-based pagination (`skip: N, take: M`) | Cursor-based pagination (`after: cursor, first: N`) | GraphQL best practice (2020+) | Not directly applicable to Phase 28 (App Store submission, not GraphQL). Mentioned for Kindred context continuity (Phases 23-26 use cursor pagination). |
| Privacy Nutrition Labels manual entry only | `upload_app_privacy_details_to_app_store` action | fastlane 2.199 (Nov 2021) | Action exists but has low adoption: requires Apple ID password auth (no API key support), complex JSON format, manual ASC dashboard still recommended for v1 submissions. |
| Xcode 25 SDK (pre-April 2026) | Xcode 26 SDK (mandated April 28, 2026) | Apple policy change (announced Jan 2026) | All submissions after April 28, 2026 MUST use Xcode 26 + iOS 26 SDK. User has Xcode 26.4 installed. Phase 28 documents SDK version used. |

**Deprecated/outdated:**
- **Apple ID password authentication for fastlane:** Replaced by App Store Connect API keys. Still works but triggers 2FA prompts and breaks automation.
- **`UIWebView` API (iOS 26 SDK):** Deprecated since iOS 12, removal warnings escalated in iOS 26 SDK. Use `WKWebView` instead. (Kindred doesn't use WebViews, so non-issue.)
- **Manual screenshot upload via App Store Connect web UI:** Replaced by `upload_to_app_store` screenshots_path. Kindred already automates this.
- **Phased release via Deliverfile:** Still supported (`phased_release: true`) but Kindred defers to future (Phase 22 decision, reaffirmed Phase 28).

## Open Questions

1. **Does the existing "Internal Testers" TestFlight group still exist in App Store Connect?**
   - What we know: Phase 22 setup created this group. Fastfile references it.
   - What's unclear: Group deletion or renaming since Phase 22 (completed 2026-04-03, 5 days ago).
   - Recommendation: Add manual verification step in first plan task: log into ASC → TestFlight → Internal Testing → verify "Internal Testers" group exists and has 3+ testers added. If missing, recreate group before running `fastlane beta_internal`.

2. **How many deprecation warnings will Xcode 26.4 surface on first Release build?**
   - What we know: Kindred codebase built with Xcode 26.x (user confirms installed). No recent deprecation cleanup passes.
   - What's unclear: Whether SwiftUI + TCA + Firebase + AdMob dependencies have Xcode 26 compatibility issues. SPM dependencies auto-update to latest, may already be compatible.
   - Recommendation: Allocate buffer time in first plan task for deprecation fixes. Run `xcodebuild build -configuration Release | grep deprecated` and triage. If > 20 warnings, split into "blocking" (prevents submission) vs "deferred" (technical debt). Log deferred items for future cleanup phase.

3. **Does current metadata language reference AdMob sufficiently for Apple reviewers?**
   - What we know: Phase 27.1 added AdMob disclosure to `review_information/notes.txt`. `description.txt` written in Phase 22 (pre-AdMob awareness).
   - What's unclear: Whether `description.txt` should explicitly mention "free tier shows ads" for user-facing clarity. Review notes cover reviewer-facing disclosure, but App Store page visible to users may benefit from ad transparency.
   - Recommendation: Phase 28 metadata audit task should review `description.txt` line ~31-32 (subscription section) and consider adding "Free tier includes ads" bullet if not already present. Check Phase 22 original text vs Phase 27.1 verification report recommendations. LOW confidence — may already be adequate.

4. **Will fastlane's metadata sync overwrite manual ASC Privacy Nutrition Label entries?**
   - What we know: `upload_to_app_store` syncs metadata files (description, keywords, etc.) but Privacy Labels are set via separate ASC Privacy dashboard. Research shows `upload_app_privacy_details_to_app_store` exists but requires password auth.
   - What's unclear: Whether running `upload_to_app_store` AFTER setting Privacy Labels manually will reset/clear those labels. fastlane docs don't clarify this interaction.
   - Recommendation: Set Privacy Labels manually in ASC AFTER first `fastlane release` completes metadata sync. If labels reset, re-enter. Future releases: verify labels persist across updates. Document in PROJECT.md Release Process checklist: "Re-verify Privacy Labels in ASC after each submission."

## Sources

### Primary (HIGH confidence)
- [fastlane Official Documentation](https://docs.fastlane.tools/) — Complete action reference, lane patterns, best practices
- [fastlane precheck action docs](https://docs.fastlane.tools/actions/precheck/) — Metadata validation rules and configuration
- [fastlane upload_to_testflight docs](https://docs.fastlane.tools/actions/upload_to_testflight/) — TestFlight automation parameters (distribute_external, groups, skip_waiting_for_build_processing, changelog)
- [fastlane iOS App Store deployment guide](https://docs.fastlane.tools/getting-started/ios/appstore-deployment/) — Recommended release lane structure
- [fastlane increment_build_number docs](https://docs.fastlane.tools/actions/increment_build_number/) — Build number strategies
- [fastlane number_of_commits docs](https://docs.fastlane.tools/actions/number_of_commits/) — Git commit-based build numbering
- [fastlane add_git_tag docs](https://docs.fastlane.tools/actions/add_git_tag/) — Post-release git tagging
- [fastlane uploading app privacy details](https://docs.fastlane.tools/uploading-app-privacy-details/) — Privacy Nutrition Labels automation limitations
- Kindred codebase files (PrivacyInfo.xcprivacy, Fastfile, Deliverfile, Release.xcconfig, pre-submission-checklist.md, Phase 27.1 verification report) — HIGH confidence, verified via Read tool
- `xcodebuild -version` output — Xcode 26.4 confirmed installed
- `xcodebuild -showsdks` output — iOS 26.4 SDK confirmed

### Secondary (MEDIUM confidence)
- [Apple Xcode 26 SDK Requirements (April 2026)](https://developer.apple.com/news/upcoming-requirements/?id=02212025a) — Mandated Xcode 26 deadline verified via multiple 2026 sources
- [How to build the perfect fastlane pipeline for iOS - Runway.team](https://www.runway.team/blog/how-to-build-the-perfect-fastlane-pipeline-for-ios) — Best practices from 2026 industry article
- [Apple App Store Submission Changes — April 2026 | Medium](https://medium.com/@thakurneeshu280/apple-app-store-submission-changes-april-2026-5fa8bc265bbe) — SDK requirement timeline confirmed
- [iOS 26 SDK Requirements: Complete Developer Migration Guide | Medium](https://ravi6997.medium.com/ios-26-sdk-requirements-what-developers-need-to-know-for-april-2026-16dec793c44d) — Deprecation handling guidance
- [Managing Version Numbers with Fastlane | Ben Scheirman](https://benscheirman.com/2020/10/managing-version-numbers-with-fastlane.html) — Build number best practices from recognized iOS expert

### Tertiary (LOW confidence)
- WebSearch results for "fastlane iOS release automation best practices 2026" — Multiple sources confirm fastlane as industry standard but no single canonical 2026 reference
- GitHub fastlane issues/discussions — Community patterns visible but not officially endorsed

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — fastlane official docs, user's existing setup verified, Xcode version confirmed
- Architecture: HIGH — Patterns derived from official fastlane guides + verified Kindred Fastfile
- Pitfalls: MEDIUM-HIGH — Based on common iOS/fastlane community issues + project-specific risks (placeholders, stale builds, privacy labels)
- Privacy Labels automation: MEDIUM — fastlane action exists but low adoption, manual approach confirmed as standard
- Deprecation warnings scope: LOW — Unknown until first Xcode 26 Release build runs. Could be 0 warnings (dependencies already compatible) or 50+ (breaking changes in SDK).

**Research date:** 2026-04-08
**Valid until:** 2026-05-08 (30 days — fastlane stable, Xcode 26 SDK final, Apple policies locked for April deadline)

---

*Research complete. Ready for planning.*
