# Pre-Submission Checklist

Use this checklist before ANY TestFlight or App Store upload. Complete every item to ensure production readiness.

---

## 1. Production Configuration

Verify all production values are configured correctly in `Kindred/Config/Release.xcconfig`:

- [ ] **ADMOB_APP_ID** is replaced with production value (NOT "REPLACE_WITH_PRODUCTION_APP_ID")
- [ ] **ADMOB_FEED_NATIVE_ID** is replaced with production value (NOT "REPLACE_WITH_PRODUCTION_FEED_NATIVE_ID")
- [ ] **ADMOB_DETAIL_BANNER_ID** is replaced with production value (NOT "REPLACE_WITH_PRODUCTION_DETAIL_BANNER_ID")
- [ ] **CLERK_PUBLISHABLE_KEY** is replaced with production value (NOT "REPLACE_WITH_PRODUCTION_CLERK_KEY")
- [ ] **Verify:** Build with Release configuration launches without fatalError crashes
- [ ] **Verify:** No Google test ad IDs (ca-app-pub-3940256099942544) appear in Release build logs

---

## 2. App Store Connect Setup

Verify all App Store Connect configuration is complete:

- [ ] App record exists in App Store Connect (bundle ID: com.ersinkirteke.kindred)
- [ ] Subscription product created: **com.kindred.pro.monthly** ($9.99/month)
- [ ] Subscription group created: **Kindred Pro**
- [ ] English (en-US) subscription localization added with name and description
- [ ] Turkish (tr) subscription localization added with name and description
- [ ] **Internal Testers** group created in TestFlight
- [ ] **External Testers** group created in TestFlight
- [ ] Sandbox test account created and credentials documented for demo account
- [ ] App Store Connect API key generated and .p8 file downloaded
- [ ] API key ID, Issuer ID, and .p8 file path added to `Kindred/fastlane/.env`

---

## 3. Privacy & Compliance

Verify all privacy and legal requirements are met:

- [ ] Privacy Nutrition Labels in App Store Connect match PrivacyInfo.xcprivacy declarations
- [ ] Privacy policy URL is live and accessible at the URL specified in metadata
- [ ] Age rating is set to **4+** (Food & Drink, no sensitive content)
- [ ] Export compliance: HTTPS-only exemption declared (no custom encryption)
- [ ] **ITSAppUsesNonExemptEncryption** = NO in Info.plist or handled via Deliverfile submission_information
- [ ] Voice cloning consent copy reviewed by legal counsel for compliance (Tennessee ELVIS Act, California AB 1836)

---

## 4. Code Signing

Verify code signing certificates and profiles are valid:

- [ ] Distribution certificate is valid (check in Keychain Access or Xcode Preferences → Accounts)
- [ ] App Store provisioning profile matches bundle ID (com.ersinkirteke.kindred)
- [ ] Provisioning profile is not expired
- [ ] Entitlements file (`Kindred/Sources/Kindred.entitlements`) includes **Sign in with Apple** capability
- [ ] Team ID is correct: **CV9G42QVG4**

---

## 5. Build Verification

Verify the build is production-ready:

- [ ] Marketing version is **1.0.0** (MARKETING_VERSION in `Kindred/project.yml`)
- [ ] Build number is incremented for each upload (CURRENT_PROJECT_VERSION or fastlane number_of_commits)
- [ ] Archive builds successfully: `cd Kindred && xcodebuild archive -scheme Kindred -configuration Release -archivePath ./build/Kindred.xcarchive`
- [ ] No compiler warnings in Release mode
- [ ] App launches successfully on a physical device (iPhone 16 Pro Max or similar)
- [ ] Onboarding flow completes without errors on physical device
- [ ] Voice playback works on physical device (test with "Kindred Voice" demo profile)

---

## 6. Content Readiness

Verify all app store content is complete:

- [ ] **5 screenshots** per locale (en-US, tr) in `Kindred/fastlane/screenshots/` or uploaded to App Store Connect
- [ ] App icon (1024x1024px) exists in `Kindred/Assets.xcassets/AppIcon.appiconset/`
- [ ] All metadata text files populated in `Kindred/fastlane/metadata/en-US/` (name, subtitle, description, keywords, release_notes, etc.)
- [ ] All metadata text files populated in `Kindred/fastlane/metadata/tr/`
- [ ] Demo voice profile ("Kindred Voice") is accessible in production backend for Apple reviewers
- [ ] Beta App Review notes (review_information/notes.txt) include demo account credentials

---

## 7. Fastlane Environment

Verify fastlane is properly configured:

- [ ] `Kindred/fastlane/.env` file exists (copied from `.env.default` and filled in)
- [ ] APP_STORE_CONNECT_API_KEY_ID is set in .env
- [ ] APP_STORE_CONNECT_ISSUER_ID is set in .env
- [ ] APP_STORE_CONNECT_API_KEY_FILEPATH points to valid .p8 file
- [ ] Demo account email and password are set in .env (for beta_app_review_info)
- [ ] Fastlane dependencies installed: `cd Kindred/fastlane && bundle install`
- [ ] Fastlane version is pinned: `bundle exec fastlane --version` shows ~> 2.225

---

## 8. Go/No-Go Criteria

**Ship if:**
- Zero crashers (no crashes in core flows on physical device)
- No critical flow-blocking bugs (onboarding, feed, voice playback, pantry, purchase all work)

**Ship with (acceptable):**
- Minor UI glitches (layout shifts, non-critical visual issues)
- Edge cases that don't affect core flows

**Block if:**
- Any crash occurs during core flows
- Onboarding doesn't complete
- Feed doesn't load recipes
- Voice narration doesn't play audio
- Pantry scan doesn't detect items
- Subscription purchase fails or doesn't remove ads

---

## Final Checks Before Upload

- [ ] All sections above are complete (every checkbox checked)
- [ ] Physical device testing completed successfully
- [ ] Demo account credentials tested and verified working
- [ ] .env file is NOT committed to git (verify with `git status`)
- [ ] .p8 API key file is NOT committed to git
- [ ] Release.xcconfig production values are committed to git

---

**Ready to ship?** Run the appropriate fastlane lane:

```bash
cd Kindred/fastlane
bundle exec fastlane beta_internal  # Internal TestFlight (no review)
bundle exec fastlane beta_external  # External TestFlight (requires Beta App Review)
bundle exec fastlane release        # App Store submission
```

---

**Note:** This checklist should be reviewed before EVERY upload. Do not skip steps. Shipping with placeholder configuration values or missing content will result in rejection or app malfunction.
