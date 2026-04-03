---
phase: 22-testflight-beta-submission-prep
plan: 01
subsystem: build-automation
tags: [fastlane, app-store, metadata, localization, beta-distribution]
completed_date: 2026-04-03
duration_seconds: 190

dependencies:
  requires: []
  provides:
    - fastlane-infrastructure
    - app-store-metadata
    - beta-distribution-lanes
  affects:
    - TestFlight distribution
    - App Store submission
    - Build automation

tech_stack:
  added:
    - fastlane (build automation)
  patterns:
    - Environment-based credentials (API keys via .env)
    - Git commit count as build number
    - Multi-locale metadata structure

key_files:
  created:
    - Kindred/fastlane/Appfile
    - Kindred/fastlane/Deliverfile
    - Kindred/fastlane/Fastfile
    - Kindred/fastlane/.env.default
    - Kindred/fastlane/metadata/en-US/description.txt
    - Kindred/fastlane/metadata/en-US/keywords.txt
    - Kindred/fastlane/metadata/en-US/subtitle.txt
    - Kindred/fastlane/metadata/tr/description.txt
    - Kindred/fastlane/metadata/tr/keywords.txt
    - Kindred/fastlane/metadata/tr/subtitle.txt
  modified:
    - .gitignore

decisions:
  - key: Fastlane lane structure
    choice: Three lanes (beta_internal, beta_external, release) for different distribution contexts
    rationale: Separate lanes allow granular control over TestFlight internal vs external distribution and App Store release
    alternatives:
      - Single unified lane with parameters
      - Manual build + upload without automation

  - key: Build number source
    choice: Git commit count (number_of_commits)
    rationale: Reproducible, monotonically increasing, and automatically tracks project history
    alternatives:
      - Manual version bumping
      - Timestamp-based versioning
      - XcodeGen project.yml CURRENT_PROJECT_VERSION

  - key: Metadata tone
    choice: Warm, personal, family-focused language with emotional hooks
    rationale: Aligns with core value proposition of cooking with loved ones' voices
    alternatives:
      - Technical/feature-focused tone
      - Minimalist/concise approach

  - key: AI disclosure placement
    choice: Dedicated "ABOUT AI VOICE TECHNOLOGY" section in description with explicit ElevenLabs naming
    rationale: Satisfies Apple Guideline 5.1.2(i) requirement for AI transparency while maintaining readability
    alternatives:
      - Brief mention in features list
      - Separate legal disclaimer section

  - key: Keywords strategy
    choice: Mix of functional (recipe, cooking, pantry) and emotional (family, personal) terms, avoiding app name repetition
    rationale: Balances App Store SEO with Food & Drink category discovery optimization
    alternatives:
      - Feature-only keywords
      - Emotional-only keywords
      - Brand-heavy keywords

metrics:
  tasks_completed: 2
  files_created: 20
  files_modified: 1
  commits: 2
---

# Phase 22 Plan 01: Fastlane Build Automation & App Store Metadata Summary

**One-liner:** Established fastlane infrastructure with three distribution lanes and complete bilingual App Store metadata featuring warm family-focused tone and explicit ElevenLabs AI disclosure.

## Tasks Completed

### Task 1: Initialize fastlane with beta/release lanes
**Commit:** 0024291
**Files:** Kindred/fastlane/Appfile, Deliverfile, Fastfile, .env.default, .gitignore

Created complete fastlane infrastructure from scratch (no interactive `fastlane init` to avoid user prompts):

- **Appfile:** Configured with correct bundle ID (com.ersinkirteke.kindred) and Team ID (CV9G42QVG4). Uses App Store Connect API Key via environment variables instead of password auth.

- **Deliverfile:** Set Food & Drink category, export compliance (HTTPS-only encryption exempt), free pricing tier (IAP), automatic release, metadata/screenshot paths.

- **Fastfile:** Three fully-configured lanes:
  - `beta_internal`: Builds Release config, uploads to TestFlight, distributes to Internal Testers only, no external distribution
  - `beta_external`: Builds Release config, uploads to TestFlight with beta review info (contact details, demo account, AI disclosure notes), distributes to External Testers
  - `release`: Builds Release config, submits to App Store with automatic release and export compliance

- **Build numbering:** All lanes use `number_of_commits` for reproducible, monotonically-increasing build numbers. Added comment documenting that XcodeGen project.yml CURRENT_PROJECT_VERSION is separate from fastlane runtime numbering.

- **Directory handling:** Added `Dir.chdir("..")` blocks to ensure commands run from Kindred directory where .xcodeproj exists (fastlane runs from fastlane/ subdirectory).

- **.env.default:** Template for API key credentials (APP_STORE_CONNECT_API_KEY_ID, ISSUER_ID, FILEPATH) and beta review contact info. Force-added to git since `.env.*` rule would normally ignore it.

- **.gitignore:** Added fastlane-specific ignores (report.xml, Preview.html, screenshots/*.png, test_output, *.ipa, *.dSYM.zip, *.p8).

### Task 2: Write localized App Store metadata
**Commit:** f88bc98
**Files:** 15 metadata text files across en-US and tr locales

Created complete bilingual App Store metadata following Apple's text file conventions:

**English (en-US) — 9 files:**
- `name.txt`: "Kindred"
- `subtitle.txt`: "Recipes in Loved Ones' Voices" (exactly 30 characters per user decision)
- `description.txt`: 2,421 characters of warm, family-focused copy structured with:
  - Emotional opening hook (grandmother's voice, partner reading recipe)
  - Feature sections (Voice Narration, Discover Recipes, Smart Pantry Scanning)
  - **"ABOUT AI VOICE TECHNOLOGY" section with explicit ElevenLabs disclosure** (satisfies Apple Guideline 5.1.2(i)):
    - Names ElevenLabs as AI provider
    - States explicit consent required before upload
    - Confirms user control (delete from Settings anytime)
    - Mentions secure processing and voice privacy compliance
  - Subscription options (free with ads, Kindred Pro $9.99/month details)
  - Privacy & Terms section
  - Emotional closing call-to-action
- `keywords.txt`: "recipe,cooking,voice,narration,audio,family,personal,pantry,scan,ingredients,meal,food,AI,local" (95 characters, under 100-char limit)
- `promotional_text.txt`: 119-character launch promo in warm tone (updateable without app version)
- `release_notes.txt`: 5 bullet points introducing key features
- `support_url.txt`: "mailto:support@kindred.app" (placeholder)
- `marketing_url.txt`: Empty (no marketing site yet)
- `privacy_url.txt`: "https://kindred.app/privacy" (placeholder—needs real URL update)

**Turkish (tr) — 6 files:**
- `name.txt`: "Kindred" (brand name unchanged)
- `subtitle.txt`: "Sevdiklerinizin Sesiyle Tarifler" (35 characters—Turkish translation of subtitle)
- `description.txt`: Professional Turkish translation maintaining warm, family-focused tone. ElevenLabs name preserved (not translated). Full structural parity with English version including AI disclosure section.
- `keywords.txt`: "tarif,yemek,ses,narrasyon,sesli,aile,kişisel,kiler,malzeme,mutfak,AI,yerel,pratik" (95 characters)
- `promotional_text.txt`: Turkish translation of launch promo
- `release_notes.txt`: Turkish translation of 5 feature bullets

**Tone adherence:** Both locales use warm, personal, family-focused language emphasizing emotional connection ("cook with the voices that make a house feel like home" / "bir evi yuva yapan seslerle yemek yapın").

**Keyword strategy:** Mixed functional terms (recipe, cooking, pantry) with emotional terms (family, personal, loved ones) to balance SEO with category discovery. Avoided repeating "Kindred" or subtitle terms per App Store keyword best practices.

## Deviations from Plan

None—plan executed exactly as written.

## Verification Results

All automated checks passed:

1. Directory structure complete: `Kindred/fastlane/` contains Appfile, Deliverfile, Fastfile, .env.default, metadata/en-US/*.txt, metadata/tr/*.txt
2. `grep -c "lane" Fastfile` returns 6 (3 lane definitions × 2 occurrences each for `lane` and `desc`)
3. ElevenLabs AI disclosure present in both `en-US/description.txt` and `tr/description.txt`
4. Keywords under 100 characters: English 95 chars, Turkish 95 chars
5. Subtitle confirmed: "Recipes in Loved Ones' Voices" (exact match)

## Self-Check: PASSED

**Files created (verified):**
- FOUND: /Users/ersinkirteke/Workspaces/Kindred/Kindred/fastlane/Appfile
- FOUND: /Users/ersinkirteke/Workspaces/Kindred/Kindred/fastlane/Deliverfile
- FOUND: /Users/ersinkirteke/Workspaces/Kindred/Kindred/fastlane/Fastfile
- FOUND: /Users/ersinkirteke/Workspaces/Kindred/Kindred/fastlane/.env.default
- FOUND: /Users/ersinkirteke/Workspaces/Kindred/Kindred/fastlane/metadata/en-US/description.txt
- FOUND: /Users/ersinkirteke/Workspaces/Kindred/Kindred/fastlane/metadata/tr/description.txt
- FOUND: /Users/ersinkirteke/Workspaces/Kindred/.gitignore

**Commits (verified):**
- FOUND: 0024291 (Task 1: fastlane infrastructure)
- FOUND: f88bc98 (Task 2: localized metadata)

**Content verification:**
- ElevenLabs disclosure in English: ✓
- ElevenLabs disclosure in Turkish: ✓
- Keywords under 100 chars: ✓ (95 chars)
- Subtitle exact match: ✓
- 3 lanes in Fastfile: ✓ (beta_internal, beta_external, release)
- Correct bundle ID in Appfile: ✓ (com.ersinkirteke.kindred)
- FOOD_AND_DRINK category in Deliverfile: ✓

## Next Steps

Plan 22-02 will focus on creating App Store screenshots (6.7" iPhone 16 Pro Max simulator) with localized overlays for both English and Turkish. This metadata foundation enables immediate screenshot upload via `deliver` once visual assets are ready.

**Note for Phase 22-02:** Privacy URL placeholder needs updating to real privacy policy URL before App Store submission. Support URL can remain mailto or be replaced with web-based support portal.

**Fastlane usage:**
- `cd Kindred/fastlane && fastlane beta_internal` — Internal TestFlight build
- `cd Kindred/fastlane && fastlane beta_external` — External TestFlight build with beta review
- `cd Kindred/fastlane && fastlane release` — App Store submission

**Environment setup required before first build:**
1. Generate App Store Connect API Key at https://appstoreconnect.apple.com/access/integrations/api
2. Copy `.env.default` to `.env` and fill in API key values
3. Add demo account credentials for beta review
