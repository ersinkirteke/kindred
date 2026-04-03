# Phase 22: TestFlight Beta & Submission Prep - Research

**Researched:** 2026-04-03
**Domain:** iOS App Store submission, TestFlight beta testing, App Store Connect automation
**Confidence:** HIGH

## Summary

Phase 22 prepares the Kindred app for App Store submission through TestFlight beta testing and submission preparation. This is a non-code phase focused on assets, metadata, testing, and automation setup. The primary technical challenges are screenshot creation with marketing overlays, App Store Connect metadata configuration with AI disclosure, TestFlight beta coordination, and fastlane automation for build distribution and submission.

Apple's 2026 requirements are stricter on AI transparency. Guideline 5.1.2(i) mandates explicit disclosure when sharing personal data with third-party AI services like ElevenLabs. Apps must clearly identify the AI provider by name and obtain user consent before first data transmission. The app already handles this with per-upload voice cloning consent (implemented in Phase 18), satisfying this requirement.

Screenshot submission is simplified in 2026 — only one device size is required (6.9" iPhone at 1320x2868px), and Apple auto-scales to smaller devices. Manual creation in Simulator + Figma is the correct approach for this phase, not fastlane snapshot automation.

**Primary recommendation:** Use fastlane for build automation and TestFlight distribution, but create screenshots manually in Simulator + design tools. Prioritize internal beta testing first (1 week, 5-10 testers) before external beta (1-2 weeks, 50-100 testers). External beta requires Apple's Beta App Review for first build, expect 24-48 hours approval time.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Screenshot Content & Composition:**
- 5 screenshots, feature highlights approach (one screenshot per killer feature)
- Order: Voice narration -> Recipe feed -> Pantry scan -> Dietary filters -> Recipe detail
- Voice narration screenshot: Recipe detail view with mini player at bottom (shows integration in cooking flow)
- Pantry screenshot: Camera scan in action (shows AI capability)
- Marketing overlays with text headlines above each screenshot + gradient background matching brand colors
- 6.9" iPhone only (1320x2868px) — no iPad screenshots (app is iPhone-only)
- English + Turkish localization (two sets of screenshots)
- Curated demo content (hand-picked recipes with appetizing photos, demo voice profile)
- Manual creation (Simulator + Figma/Photoshop), no fastlane snapshot automation
- Static screenshots only, no App Preview video for v1

**App Store Listing Copy:**
- Warm & personal tone — family-focused, emotional (matches voice cloning USP)
- Subtitle: "Recipes in Loved Ones' Voices" (30 chars)
- Category: Food & Drink (primary)
- AI disclosure: Full transparency — name ElevenLabs explicitly in description and AI disclosure fields
- English + Turkish full localization (description, keywords, what's new)
- Pricing: Free with in-app purchases — mention subscription tiers in description
- "What's New" text: Feature list approach ("Introducing Kindred! Voice narration, pantry scanning, trending recipes, and more.")
- Promotional text: Launch promo in warm/personal tone
- App icon: Needs creation — warm & cooking-themed style with warm colors (oranges, reds), suggesting home cooking and family
- Support URL: Needs to be created (email or support page)
- Privacy policy URL: Already hosted (from Phase 18)
- Keywords: Claude researches optimal keywords during planning

**Beta Testing Strategy:**
- Internal testers: 5-10 people already available (friends/family/team)
- External testers: 50-100 via public TestFlight link shared on social media, Reddit (r/cooking, r/iosapps), Product Hunt
- Internal testing: 1 week minimum before opening external beta
- External testing: 1-2 weeks after internal phase
- Test focus: Core flows end-to-end (onboarding, browse feed, open recipe, play voice narration, scan pantry, subscribe)
- Feedback collection: TestFlight built-in feedback only (shake to report)
- Written "What to Test" guide in TestFlight with specific flows to try
- Pre-loaded demo voice profile so testers can hear narration immediately
- Full production mirror — no feature gating, real subscriptions in sandbox mode
- Standard 90-day TestFlight build expiration
- First-time submitting for external TestFlight review — need extra prep for beta review process
- Go/no-go threshold: Zero crashers + no critical flow-blocking bugs. Minor UI issues are acceptable.

**Pre-Submission Checklist:**
- Age rating: 4+ (no sensitive content — cooking/recipes only)
- Export compliance: HTTPS only — standard encryption exemption applies
- Critical blocker definition: Any crash + broken onboarding/feed/voice/pantry/purchase flows. Ship with: UI glitches, minor layout issues, edge cases.
- Version: 1.0.0 (build 1)
- Submission: Fastlane automation (automated builds and submission)
- Release: Automatic (goes live immediately after Apple approval)
- Rollout: Immediate full release (no phased rollout)
- Availability: All countries worldwide
- App Store Connect: Developer account set up (Team ID: CV9G42QVG4), app record exists
- IAP products: Need to create subscription products in App Store Connect (local StoreKit config exists)
- AI disclosure concern: Ensure Apple's AI content generation guidelines are met for ElevenLabs voice cloning

### Claude's Discretion

- Exact screenshot overlay text headlines and gradient colors
- App Store keyword research and selection
- Promotional text copy
- "What to Test" guide content for beta testers
- Support page design/approach
- App icon design brief details
- Fastlane configuration specifics

### Deferred Ideas (OUT OF SCOPE)

- iPad native support — could be its own phase post-launch
- App Preview video — defer to post-launch update
- A/B testing for screenshots — defer until enough download volume
- Localization beyond English + Turkish — future milestone
- Phased release strategy — consider for major updates, not v1

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SUBMIT-01 | App Store screenshots created for required device sizes | Manual creation workflow (Simulator + Figma), 6.9" iPhone 1320x2868px requirement, 5 screenshots with marketing overlays |
| SUBMIT-02 | App Store metadata written with third-party AI disclosure | App Store Connect metadata fields, Apple Guideline 5.1.2(i) AI disclosure requirements, keyword research strategies |
| SUBMIT-03 | TestFlight beta testing completed with internal and external testers | TestFlight workflow (internal → external beta), Beta App Review process, feedback collection patterns, go/no-go criteria |

</phase_requirements>

## Standard Stack

### Core Tools

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| fastlane | 2.x | iOS build automation, TestFlight distribution, App Store submission | Industry standard for iOS CI/CD — used by Uber, Twitter, Pinterest. Handles code signing, metadata upload, screenshot framing. |
| App Store Connect | N/A | Metadata management, subscription setup, TestFlight coordination | Apple's official platform for app distribution — required for App Store submission |
| Xcode 26+ | 26.3 | Build generation with iOS 26 SDK | Apple requirement: As of April 28, 2026, all App Store uploads must use iOS 26 SDK or later |
| Simulator | iOS 17.0+ | Screenshot capture on 6.9" iPhone | Matches deployment target, provides exact device frame for screenshots |

### Supporting Tools

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| Figma/Photoshop | Latest | Marketing overlay design, gradient backgrounds | Manual screenshot composition with text headlines |
| fastlane match | 2.x | Code signing automation | Team collaboration, certificate sync across machines |
| fastlane deliver | 2.x | Metadata and screenshot upload | Automates App Store Connect metadata submission |
| fastlane pilot | 2.x | TestFlight build upload | Automates beta distribution to internal/external testers |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Manual screenshots | fastlane snapshot | Snapshot requires UI test automation — overkill for 5 static screenshots. Manual creation with curated demo content is faster for v1. |
| fastlane | Xcode Cloud | Xcode Cloud is Apple-native but less flexible for custom workflows. fastlane has better third-party integrations and free tier. |
| Manual metadata entry | App Store Connect API | API is overkill for one-time submission. fastlane deliver abstracts API complexity with simple DSL. |

**Installation:**

```bash
# Install fastlane
gem install fastlane

# Initialize fastlane in project
cd Kindred
fastlane init

# Install match for code signing (if needed)
fastlane match init
```

## Architecture Patterns

### Recommended Project Structure

```
Kindred/
├── fastlane/
│   ├── Fastfile                  # Lane definitions (beta, release, screenshots)
│   ├── Appfile                   # App Store Connect credentials
│   ├── Deliverfile               # Metadata configuration
│   ├── metadata/
│   │   ├── en-US/                # English metadata
│   │   │   ├── description.txt
│   │   │   ├── keywords.txt
│   │   │   ├── marketing_url.txt
│   │   │   ├── promotional_text.txt
│   │   │   ├── release_notes.txt
│   │   │   ├── subtitle.txt
│   │   │   └── support_url.txt
│   │   └── tr/                   # Turkish metadata
│   │       └── (same structure)
│   └── screenshots/
│       ├── en-US/
│       │   ├── 01-voice-narration.png
│       │   ├── 02-recipe-feed.png
│       │   ├── 03-pantry-scan.png
│       │   ├── 04-dietary-filters.png
│       │   └── 05-recipe-detail.png
│       └── tr/
│           └── (same structure)
├── Config/
│   ├── Debug.xcconfig            # Test AdMob IDs, test Clerk key
│   └── Release.xcconfig          # Production IDs (needs population)
└── Kindred.storekit              # Local subscription config (reference for ASC)
```

### Pattern 1: Fastlane Lane Structure

**What:** Separate lanes for beta distribution and release submission
**When to use:** Multi-stage release process (internal beta → external beta → App Store)
**Example:**

```ruby
# fastlane/Fastfile
default_platform(:ios)

platform :ios do
  desc "Build and upload to TestFlight (internal)"
  lane :beta_internal do
    increment_build_number(xcodeproj: "Kindred.xcodeproj")
    build_app(
      scheme: "Kindred",
      configuration: "Debug",
      export_method: "app-store"
    )
    upload_to_testflight(
      skip_waiting_for_build_processing: false,
      distribute_external: false,  # Internal only
      groups: ["Internal Testers"]
    )
  end

  desc "Build and upload to TestFlight (external)"
  lane :beta_external do
    increment_build_number(xcodeproj: "Kindred.xcodeproj")
    build_app(
      scheme: "Kindred",
      configuration: "Release",  # Production config
      export_method: "app-store"
    )
    upload_to_testflight(
      skip_waiting_for_build_processing: true,
      distribute_external: true,
      groups: ["External Testers"],
      beta_app_review_info: {
        contact_email: "beta@kindred.app",
        contact_first_name: "Ersin",
        contact_last_name: "Kirteke",
        contact_phone: "+1234567890",
        demo_account_name: "demo@kindred.app",
        demo_account_password: "TestDemo123!",
        notes: "Test the voice narration feature by browsing recipes and playing audio. Demo voice profile pre-loaded."
      }
    )
  end

  desc "Submit to App Store"
  lane :release do
    increment_build_number(xcodeproj: "Kindred.xcodeproj")
    build_app(
      scheme: "Kindred",
      configuration: "Release",
      export_method: "app-store"
    )
    upload_to_app_store(
      force: true,
      submit_for_review: true,
      automatic_release: true,
      submission_information: {
        add_id_info_uses_idfa: false,  # No IDFA tracking
        export_compliance_uses_encryption: true,
        export_compliance_encryption_updated: false,
        export_compliance_is_exempt: true  # Standard HTTPS exemption
      }
    )
  end
end
```

### Pattern 2: Metadata Directory Structure

**What:** Text files in `fastlane/metadata/{locale}/` for App Store Connect fields
**When to use:** Multi-locale apps requiring version-controlled metadata
**Example:**

```
fastlane/metadata/en-US/description.txt:
---
Hear your loved ones guide you through delicious recipes.

Kindred brings a personal touch to cooking by letting family members and friends narrate recipes in their own voices using AI voice cloning powered by ElevenLabs. Browse trending local recipes, scan ingredients from your pantry, and cook along with the comforting voice of someone special.

Features:
• Voice narration of recipes using AI-cloned voices
• Trending recipes based on your location
• Smart pantry scanning with camera
• Dietary filters and personalized recommendations
• Subscribe for ad-free experience and unlimited voice profiles

Kindred uses ElevenLabs AI voice technology to clone voices from short audio samples. All voice data is processed securely and requires your explicit consent before upload.

---

fastlane/metadata/en-US/keywords.txt:
---
recipe,cooking,voice,audio,narration,family,pantry,ingredients,food,meal,AI,ElevenLabs
---

fastlane/metadata/en-US/subtitle.txt:
---
Recipes in Loved Ones' Voices
---
```

### Pattern 3: Screenshot Workflow

**What:** Manual screenshot creation with Simulator + design overlay
**When to use:** Small screenshot count (5), curated demo content, marketing overlays
**Example workflow:**

```
1. Prepare demo data:
   - Backend: Create demo user with pre-loaded voice profile
   - Backend: Curate 10+ recipes with high-quality photos
   - App: Configure demo mode (if needed) or use production with demo account

2. Capture raw screenshots (Simulator):
   - Launch Xcode → Simulator (iPhone 16 Pro Max, iOS 17.0)
   - Navigate to each feature, capture with Cmd+S
   - Screenshots saved to ~/Desktop
   - Verify dimensions: 1320x2868px

3. Design marketing overlays (Figma/Photoshop):
   - Template: 1320x2868px canvas
   - Top 600px: Gradient background (brand colors)
   - Headline text: 80-100pt bold, white/contrast color
   - Bottom: Screenshot image (slight shadow/border)
   - Export as PNG, <10MB

4. Organize for fastlane:
   - Place in fastlane/screenshots/en-US/
   - Filename format: 01-voice-narration.png, 02-recipe-feed.png, etc.
   - Repeat for Turkish (tr/)

5. Upload with fastlane:
   fastlane deliver --skip_metadata --skip_binary_upload
```

### Pattern 4: Subscription Product Setup

**What:** App Store Connect in-app subscription creation from local StoreKit config
**When to use:** First-time App Store submission with subscriptions
**Example:**

```
1. Review local StoreKit config (Kindred.storekit):
   - Subscription group: "kindred_pro"
   - Product ID: "com.kindred.pro.monthly"
   - Price: $9.99/month
   - Localization: "Ad-free experience with unlimited voice profiles"

2. Create in App Store Connect:
   - Navigate to: App → Features → In-App Purchases
   - Create Subscription Group: "Kindred Pro"
   - Add Subscription: "Kindred Pro Monthly"
   - Product ID: com.kindred.pro.monthly (must match code)
   - Pricing: Tier 9.99 USD (auto-converts to other currencies)
   - Localization: English + Turkish
   - Review Information: Demo account credentials

3. Sync product IDs:
   - Verify MonetizationFeature uses exact product IDs
   - No code changes needed if IDs match

4. Set availability:
   - All countries/regions (default)
   - No introductory offers for v1
```

### Anti-Patterns to Avoid

- **Automated screenshot generation for marketing shots:** fastlane snapshot is for functional UI tests, not curated marketing content. Manual creation provides better control over demo data and overlays.
- **Hardcoded credentials in Fastfile:** Use environment variables or .env files for App Store Connect credentials. Never commit passwords to git.
- **Skipping Beta App Review:** First external TestFlight build requires review (24-48 hours). Don't promise beta access dates without accounting for review time.
- **Using Debug configuration for external beta:** External beta should mirror production. Use Release configuration with sandbox StoreKit for realistic testing.
- **Missing export compliance info:** Apps using HTTPS must declare encryption usage. Failing to provide export compliance info blocks submission.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Build automation | Custom shell scripts for archiving + uploading | fastlane gym + pilot | fastlane handles code signing complexities, retry logic, and App Store Connect API versioning. Custom scripts break on Xcode updates. |
| Code signing | Manual certificate management | fastlane match | Manual cert management causes "code signing identity not found" errors. match stores certs in git/cloud, syncs across team. |
| Screenshot framing | Custom image compositing scripts | Design tools (Figma) | Marketing screenshots need design finesse. Automated framing lacks overlay text, gradients, and brand polish. |
| Metadata localization | Spreadsheets + manual copy-paste | fastlane metadata text files | Text files are version-controlled, reviewable, and automated with deliver. Spreadsheets cause human error. |
| TestFlight distribution | Manual Xcode uploads | fastlane pilot | Pilot automates group assignment, beta review info, and changelog updates. Manual uploads miss metadata. |

**Key insight:** App Store submission has dozens of error-prone manual steps (archiving, code signing, metadata entry, screenshot upload, export compliance). fastlane automates 90% of this, reducing submission time from 2 hours to 10 minutes. The 10% that remains manual (screenshot design, metadata copy) requires human judgment.

## Common Pitfalls

### Pitfall 1: Missing Production Configuration Values

**What goes wrong:** Release.xcconfig contains placeholder values (REPLACE_WITH_PRODUCTION_APP_ID). Building with Release configuration crashes or shows test ads in production.
**Why it happens:** Developers forget to replace placeholders from earlier phases when focusing on code features.
**How to avoid:** Create a pre-submission checklist task that verifies all xcconfig values. Use fatalError in code if production values are missing (already implemented in AdClient.swift per Phase 20 decisions).
**Warning signs:**
- Release builds show Google test ads (ca-app-pub-3940256099942544)
- Clerk authentication fails with "invalid publishable key"
- App crashes on launch with "Unexpected nil" in config

### Pitfall 2: First External Beta Review Delay

**What goes wrong:** Developer expects immediate external beta access, but build sits "Waiting for Review" for 24-48 hours.
**Why it happens:** First external build requires Apple's Beta App Review. Subsequent builds for same version auto-approve.
**How to avoid:** Plan 1 week of internal testing BEFORE external beta. Submit first external build 2 days before planned external launch.
**Warning signs:**
- TestFlight shows "Waiting for Review" status
- External testers see "This beta isn't currently accepting testers"
- Timeline pressure mounts as launch date approaches

### Pitfall 3: Screenshot Dimension Mismatch

**What goes wrong:** Screenshots rejected during upload with "Invalid dimensions" error.
**Why it happens:** Designer exports at wrong resolution (e.g., 1284x2778 for iPhone 6.5" instead of 1320x2868 for 6.9").
**How to avoid:** Create Figma/Photoshop templates with exact dimensions (1320x2868px for 6.9" iPhone). Verify dimensions before export with Preview.app or `file` command.
**Warning signs:**
- fastlane deliver fails with dimension error
- Screenshots appear stretched/cropped in App Store Connect preview
- File size unusually large (>10MB) due to wrong export settings

### Pitfall 4: AI Disclosure Guideline Violation

**What goes wrong:** App rejected during App Store review for insufficient AI disclosure (Guideline 5.1.2(i)).
**Why it happens:** Developer mentions "AI voice technology" generically without naming ElevenLabs explicitly.
**How to avoid:** Name ElevenLabs in multiple places: app description, App Privacy section, and AI disclosure field (if available). Already implemented in-app consent (Phase 18) satisfies requirement.
**Warning signs:**
- Review rejection message cites Guideline 5.1.2(i)
- App description uses vague terms like "third-party AI provider"
- No explicit mention of ElevenLabs in public-facing text

### Pitfall 5: Missing Demo Account for Review

**What goes wrong:** App review team can't test subscription features, leading to "Need more information" rejection.
**Why it happens:** Developer forgets to provide demo account credentials with active subscription in beta_app_review_info.
**How to avoid:** Create dedicated demo account, purchase subscription in sandbox mode, provide credentials in fastlane beta_app_review_info. Document account in TestFlight "What to Test" notes.
**Warning signs:**
- Review notes request login credentials
- Rejection message: "We were unable to complete our review"
- Subscription paywall blocks reviewer from testing features

### Pitfall 6: Export Compliance Confusion

**What goes wrong:** Developer doesn't know whether to declare encryption usage, causing submission to hang.
**Why it happens:** "Encryption" sounds complex, but HTTPS is encryption. Apps using URLSession for HTTPS requests must declare usage.
**How to avoid:** For Kindred: Answer YES to encryption usage, YES to standard encryption (HTTPS-only), declare exemption. No additional documentation needed for standard HTTPS.
**Warning signs:**
- App Store Connect prompts for encryption documentation upload
- Submission stuck at "Preparing for Upload"
- Confusion about ITSAppUsesNonExemptEncryption key

## Code Examples

### Example 1: Fastfile Beta Lane with Review Info

```ruby
# fastlane/Fastfile
desc "Upload to TestFlight for external testing"
lane :beta_external do
  # Increment build number
  increment_build_number(xcodeproj: "Kindred.xcodeproj")

  # Build for App Store
  build_app(
    scheme: "Kindred",
    configuration: "Release",
    export_method: "app-store",
    export_options: {
      provisioningProfiles: {
        "com.ersinkirteke.kindred" => "match AppStore com.ersinkirteke.kindred"
      }
    }
  )

  # Upload to TestFlight
  upload_to_testflight(
    skip_waiting_for_build_processing: false,
    distribute_external: true,
    groups: ["External Testers"],
    beta_app_review_info: {
      contact_email: "beta@kindred.app",
      contact_first_name: "Ersin",
      contact_last_name: "Kirteke",
      contact_phone: "+1234567890",
      demo_account_name: "demo@kindred.app",
      demo_account_password: "TestDemo123!",
      notes: <<~NOTES
        Kindred is a cooking app with AI voice narration.

        KEY FEATURES TO TEST:
        1. Browse recipe feed (shows trending local recipes)
        2. Open recipe detail, tap Play button for voice narration
        3. Go to Pantry tab, tap camera icon to scan ingredients
        4. Subscribe via Settings > Subscription (sandbox mode)

        DEMO ACCOUNT:
        - Pre-loaded voice profile: "Kindred Voice"
        - Active subscription: Kindred Pro Monthly (sandbox)
        - Voice narration works immediately on all recipes

        AI DISCLOSURE:
        Voice cloning powered by ElevenLabs. Consent required before upload.
      NOTES
    },
    changelog: "Initial beta release. Test voice narration, pantry scanning, and subscription flow."
  )
end
```

### Example 2: Deliverfile for Metadata Upload

```ruby
# fastlane/Deliverfile

# App identifier
app_identifier "com.ersinkirteke.kindred"
username "ersin@kindred.app"
team_id "CV9G42QVG4"

# Metadata paths
metadata_path "./fastlane/metadata"
screenshots_path "./fastlane/screenshots"

# Submission configuration
force true  # Skip HTML preview confirmation
skip_binary_upload true  # Only upload metadata/screenshots
skip_app_version_update true  # Don't change version number

# Pricing
price_tier 0  # Free with IAP

# App details
platform "ios"
primary_category "FOOD_AND_DRINK"
secondary_category nil

# Release configuration
automatic_release true
phased_release false
submission_information({
  add_id_info_uses_idfa: false,
  export_compliance_uses_encryption: true,
  export_compliance_encryption_updated: false,
  export_compliance_is_exempt: true
})
```

### Example 3: Environment Variable Setup

```bash
# .env (gitignored)
# App Store Connect credentials
FASTLANE_USER="ersin@kindred.app"
FASTLANE_PASSWORD="app-specific-password-here"
FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD="app-specific-password-here"
FASTLANE_SESSION="session-cookie-from-fastlane-spaceauth"

# Match code signing
MATCH_PASSWORD="encryption-password-for-match-repo"
MATCH_GIT_URL="https://github.com/kindred/certificates"

# App Store Connect API Key (alternative to password auth)
APP_STORE_CONNECT_API_KEY_ID="ABC123DEF4"
APP_STORE_CONNECT_ISSUER_ID="12345678-1234-1234-1234-123456789012"
APP_STORE_CONNECT_API_KEY_FILEPATH="./AuthKey_ABC123DEF4.p8"
```

### Example 4: Increment Build Number Before Upload

```ruby
# Increment build number based on git commit count
lane :beta do
  # Ensure clean working directory
  ensure_git_status_clean

  # Get current build number from git
  build_number = number_of_commits
  increment_build_number(
    build_number: build_number,
    xcodeproj: "Kindred.xcodeproj"
  )

  # Build and upload
  gym(scheme: "Kindred")
  pilot(skip_waiting_for_build_processing: true)

  # Commit version bump
  commit_version_bump(
    message: "Bump build number to #{build_number} [skip ci]",
    xcodeproj: "Kindred.xcodeproj"
  )
  push_to_git_remote
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Upload all device sizes (10+ screenshot sets) | Upload 6.9" iPhone only, Apple auto-scales | Late 2024 | 80% less screenshot work, faster submission |
| Generic "AI technology" disclosure | Name third-party AI provider explicitly (e.g., ElevenLabs) | November 2025 (Guideline 5.1.2(i)) | Higher transparency bar, more detailed consent required |
| Manual code signing | fastlane match with cloud storage | 2016 (fastlane match launch) | Eliminates "works on my machine" code signing errors |
| Xcode upload to TestFlight | fastlane pilot with automation | 2015 (pilot launch) | Faster beta distribution, automated group assignment |
| iOS 25 SDK requirement | iOS 26 SDK requirement | April 28, 2026 | Must upgrade Xcode to 26.3+ before submission |

**Deprecated/outdated:**
- **iTunes Connect:** Renamed to App Store Connect in 2018. Documentation referencing iTunes Connect is outdated.
- **Application Loader:** Deprecated in 2019. Use Xcode upload or fastlane instead.
- **Manual metadata entry in web UI:** Still works but error-prone. fastlane deliver with text files is modern approach.
- **fastlane snapshot for marketing screenshots:** Technically works but overkill. UI test automation is for functional testing, not marketing assets.

## Open Questions

1. **App icon design timeline**
   - What we know: User decided "warm & cooking-themed, oranges/reds, home cooking feel"
   - What's unclear: Who creates the icon? Designer available? Budget for icon design service?
   - Recommendation: If no designer, use 99designs or Fiverr for $200-500. Turnaround: 3-5 days. Provide brief: "warm cooking app icon, family/home feel, orange/red palette, 1024x1024px PNG, no transparency."

2. **Support URL setup**
   - What we know: User wants email or support page
   - What's unclear: Email address preference? Simple static page vs. full support portal?
   - Recommendation: For v1, use simple static page hosted on Vercel/Netlify with mailto: link. Fast to deploy, looks professional. Support email: support@kindred.app (Gmail alias works).

3. **Production AdMob and Clerk keys**
   - What we know: Release.xcconfig has placeholders, production keys needed before submission
   - What's unclear: Are production AdMob unit IDs already created in AdMob console? Is production Clerk environment configured?
   - Recommendation: Create task to gather production keys from AdMob console and Clerk dashboard before first Release build. Document in plan.

4. **Turkish localization of metadata**
   - What we know: User wants English + Turkish for screenshots and metadata
   - What's unclear: Who translates? Native speaker available? Machine translation acceptable?
   - Recommendation: Use professional translator for metadata (description, keywords, promotional text). Machine translation risks awkward phrasing that hurts conversion. Cost: ~$100 for 500 words. Fiverr or Upwork.

5. **Demo voice profile backend setup**
   - What we know: Beta testers need pre-loaded demo voice profile for immediate testing
   - What's unclear: Does backend support creating demo profiles? Who provides demo audio sample?
   - Recommendation: Create backend demo user account with pre-generated voice profile. Use royalty-free voice sample or team member recording. Ensure profile ID is documented for TestFlight notes.

## Sources

### Primary (HIGH confidence)

- [Apple Developer - TestFlight Overview](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/) - TestFlight workflow and limits
- [Apple Developer - Screenshot Specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/) - 6.9" iPhone dimensions (1320x2868px)
- [Apple Developer - App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) - Current review guidelines
- [Apple Developer - Export Compliance](https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance/) - Encryption declaration requirements
- [fastlane docs - deliver](https://docs.fastlane.tools/actions/deliver/) - Metadata and screenshot upload
- [fastlane docs - pilot/upload_to_testflight](https://docs.fastlane.tools/actions/upload_to_testflight/) - TestFlight automation
- [fastlane docs - match](https://docs.fastlane.tools/actions/match/) - Code signing automation
- [Apple Developer - App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/) - Privacy Nutrition Labels

### Secondary (MEDIUM confidence)

- [Medium - Apple App Store Submission Changes April 2026](https://medium.com/@thakurneeshu280/apple-app-store-submission-changes-april-2026-5fa8bc265bbe) - iOS 26 SDK requirement verified with official sources
- [TechCrunch - Apple's AI Data Sharing Guidelines](https://techcrunch.com/2025/11/13/apples-new-app-review-guidelines-clamp-down-on-apps-sharing-personal-data-with-third-party-ai/) - Guideline 5.1.2(i) third-party AI disclosure
- [DEV Community - Apple Guideline 5.1.2(i) Analysis](https://dev.to/arshtechpro/apples-guideline-512i-the-ai-data-sharing-rule-that-will-impact-every-ios-developer-1b0p) - Detailed breakdown of AI disclosure requirements
- [Runway.team - Live App Store Review Times](https://www.runway.team/appreviewtimes) - Community-reported review times (24-48 hours for TestFlight beta)
- [Kodeco - TestFlight Best Practices](https://www.kodeco.com/books/ios-app-distribution-best-practices/v1.0/chapters/6-testflight) - Internal vs external testing strategies
- [Medium - App Store Screenshot Sizes 2026](https://medium.com/@AppScreenshotStudio/app-store-screenshot-sizes-2026-cheat-sheet-iphone-16-pro-max-google-play-specs-3cb210bf0756) - 6.9" iPhone dimensions verified
- [RevenueCat - StoreKit 2 Subscription Tutorial](https://www.revenuecat.com/blog/engineering/ios-in-app-subscription-tutorial-with-storekit-2-and-swift/) - Subscription setup in App Store Connect

### Tertiary (LOW confidence - needs validation)

- [Quora - TestFlight Review Time](https://www.quora.com/How-long-does-it-take-for-Apple-to-review-and-approve-TestFlight-Beta-App) - Anecdotal 24-48 hour estimate (verified with official docs)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - fastlane is industry standard, official Apple docs verify requirements
- Architecture: HIGH - Patterns sourced from fastlane official docs and Apple Developer documentation
- Pitfalls: MEDIUM - Based on community reports and developer forum discussions, cross-referenced with official docs

**Research date:** 2026-04-03
**Valid until:** 2026-05-03 (30 days - stable domain, but Apple guidelines can change quarterly)

---

**Next steps:** Planner creates PLAN.md files based on this research, addressing SUBMIT-01 (screenshots), SUBMIT-02 (metadata), and SUBMIT-03 (TestFlight beta testing).
