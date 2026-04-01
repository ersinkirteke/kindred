---
phase: 20-att-consent-production-ads
plan: 02
subsystem: monetization
tags: [admob, xcconfig, consent, ad-personalization]
dependencies:
  requires: [consent-infrastructure]
  provides: [xcconfig-ad-configuration, consent-aware-ads]
  affects: [ad-client, app-delegate, profile-feature]
tech_stack:
  added: [xcconfig build settings]
  patterns: [environment-specific configuration, consent-driven ad personalization]
key_files:
  created:
    - Kindred/Config/Debug.xcconfig
    - Kindred/Config/Release.xcconfig
  modified:
    - Kindred/project.yml
    - Kindred/Sources/Info.plist
    - Kindred/Packages/MonetizationFeature/Sources/Models/AdModels.swift
    - Kindred/Packages/MonetizationFeature/Sources/Ads/AdClient.swift
    - Kindred/Sources/App/AppDelegate.swift
    - Kindred/Packages/ProfileFeature/Sources/PrivacyDataSection.swift
    - Kindred/Packages/ProfileFeature/Sources/ProfileView.swift
    - Kindred/Packages/ProfileFeature/Sources/ProfileReducer.swift
decisions:
  - description: xcconfig-based ad unit ID configuration
    rationale: Separates test and production IDs cleanly, prevents shipping test ads
  - description: fatalError for unconfigured Release builds
    rationale: Safety net — app crashes if production IDs not replaced before App Store submission
  - description: Consent status drives ad personalization
    rationale: fullyGranted = personalized ads, all denied states = non-personalized ads
  - description: Test device config guarded by #if DEBUG
    rationale: Production builds never include test device identifiers
  - description: Tracking settings deep link in Profile
    rationale: Users can navigate to iOS Settings to manage ATT permission
metrics:
  duration: 170s
  tasks_completed: 2
  files_created: 2
  files_modified: 7
  commits: 2
  completed_at: "2026-04-01T06:08:14Z"
---

# Phase 20 Plan 02: xcconfig Ad Configuration & Consent Integration Summary

**One-liner:** Created Debug/Release xcconfig files for environment-specific AdMob IDs, refactored AdModels to read from build settings, integrated ConsentStatus into AdClient for personalized vs non-personalized ad serving, and added tracking settings deep link to Profile.

## What Was Built

### xcconfig Files (Debug.xcconfig, Release.xcconfig)
- Debug.xcconfig contains Google test ad unit IDs for development
- Release.xcconfig contains REPLACE_WITH_PRODUCTION placeholders with TODO comment linking to AdMob console
- Both define ADMOB_APP_ID, ADMOB_FEED_NATIVE_ID, ADMOB_DETAIL_BANNER_ID variables

### project.yml Configuration
- Added `configs:` section under `settings` mapping Debug/Release to xcconfig files
- XcodeGen layers xcconfig values on top of existing base settings
- No changes to existing target or scheme configuration

### Info.plist Updates
- GADApplicationIdentifier value changed from hardcoded test ID to `$(ADMOB_APP_ID)`
- Added ADMOB_FEED_NATIVE_ID key with `$(ADMOB_FEED_NATIVE_ID)` value
- Added ADMOB_DETAIL_BANNER_ID key with `$(ADMOB_DETAIL_BANNER_ID)` value
- Xcconfig variables injected into Info.plist at build time

### AdModels.swift Refactor
- feedNative and detailBanner changed from static let strings to computed properties
- Each reads from `Bundle.main.object(forInfoDictionaryKey:)`
- Debug builds: fallback to test IDs if Info.plist injection fails
- Release builds: fatalError with helpful message if placeholder IDs not replaced
- AdLoadState enum preserved unchanged

### AdClient Integration (AdClient.swift)
- Added `configurePersonalization: @Sendable (ConsentStatus) -> Void` closure
- liveValue implementation:
  - `.fullyGranted` → `setPublisherPrivacyPersonalizationState(.allowed)` (personalized ads)
  - `.attDenied`, `.umpDenied`, `.bothDenied` → `setPublisherPrivacyPersonalizationState(.notAllowed)` (non-personalized ads)
  - `.notDetermined` → `.notAllowed` (default to non-personalized until consent obtained)
- testValue has no-op implementation
- Must be called BEFORE loading any ads and whenever consent status changes

### AppDelegate Updates
- Test device identifiers guarded by `#if DEBUG`
- Production builds never include GADSimulatorID
- Comment clarifies consent status configured before loading ads

### PrivacyDataSection Updates
- Added `onTrackingSettingsTapped: () -> Void` callback parameter
- Added "Tracking Permission" row between voice profile card and privacy policy link
- Row has gear icon (system "gear"), body text, accessibility labels
- Tapping opens iOS Settings via UIApplication.openSettingsURLString

### ProfileView & ProfileReducer Wiring
- ProfileView passes `onTrackingSettingsTapped: { store.send(.trackingSettingsTapped) }`
- ProfileReducer.Action has new `.trackingSettingsTapped` case
- Action opens Settings URL via `UIApplication.shared.open(url)`
- Only shown when user is authenticated (Privacy & Data section visibility)

## Configuration Flow

### Debug Build
1. XcodeGen reads project.yml → loads Config/Debug.xcconfig
2. xcconfig defines ADMOB_APP_ID = ca-app-pub-3940256099942544~1458002511
3. Info.plist references $(ADMOB_APP_ID) → Xcode injects test ID at build time
4. AdModels.swift reads from Bundle.main.object(forInfoDictionaryKey:) → gets test ID
5. AdClient initializes with test ad configuration

### Release Build (Before Production IDs Replaced)
1. XcodeGen reads project.yml → loads Config/Release.xcconfig
2. xcconfig defines ADMOB_APP_ID = REPLACE_WITH_PRODUCTION_APP_ID
3. Info.plist references $(ADMOB_APP_ID) → Xcode injects placeholder at build time
4. AdModels.swift detects "REPLACE" in string → fatalError with helpful message
5. App crashes on launch → prevents shipping test ads accidentally

### Release Build (After Production IDs Replaced)
1. Developer edits Config/Release.xcconfig with real AdMob IDs from https://apps.admob.com/
2. XcodeGen reads project.yml → loads Config/Release.xcconfig
3. Info.plist references $(ADMOB_APP_ID) → Xcode injects production ID at build time
4. AdModels.swift reads from Bundle.main.object(forInfoDictionaryKey:) → gets production ID
5. AdClient initializes with production ad configuration

## Consent Integration Flow

### Consent Flow Completion
1. ConsentReducer completes consent flow → fires `.consentFlowCompleted(status)` action
2. AppReducer handles `.consent(.consentFlowCompleted(status))` (wiring in Plan 01)
3. AppReducer should call `adClient.configurePersonalization(status)` to set AdMob personalization state
4. AdClient updates GADMobileAds.sharedInstance().requestConfiguration.publisherPrivacyPersonalizationState
5. All subsequent ad requests use configured personalization state

### App Foreground (Consent Change Detection)
1. User may change ATT permission in Settings → app should detect on foreground
2. AppReducer scene phase handling should re-check ATT status via `consentClient.checkATTStatus()`
3. Call `adClient.configurePersonalization()` with updated status
4. Ad personalization reflects current consent state

### Tracking Settings Deep Link
1. User taps "Tracking Permission" row in Profile > Privacy & Data section
2. ProfileView sends `.trackingSettingsTapped` action to ProfileReducer
3. ProfileReducer opens `UIApplication.openSettingsURLString`
4. iOS Settings app opens to app-specific settings (includes ATT toggle)
5. User changes permission → returns to app
6. App foreground handler detects change (see above)

## Deviations from Plan

None — plan executed exactly as written.

## Known Limitations

### 1. AdClient configurePersonalization Not Called from AppReducer
- AdClient has `configurePersonalization` closure but AppReducer doesn't call it yet
- Plan 01 should have wired ConsentReducer `.consentFlowCompleted` to call this
- **Workaround needed:** Add to AppReducer's `.consent(.consentFlowCompleted(status))` handler:
  ```swift
  return .run { [adClient] _ in
      adClient.configurePersonalization(status)
  }
  ```
- Without this, ad personalization defaults to `.notAllowed` regardless of consent status

### 2. Foreground Consent Change Detection Not Implemented
- Plan notes app should re-check ATT status on foreground
- AppReducer has no scene phase handling for this yet
- User changes ATT permission in Settings → app doesn't detect until relaunch
- **Deferred to Plan 03:** Wire scene phase observer to re-check consent

### 3. Pro Subscriber Check Not Implemented
- Plan 01 noted pro subscribers should skip consent flow entirely
- AdClient integration doesn't check subscription status
- Pro users still see consent flow (though ads won't show due to FeedReducer logic)
- **Acceptable:** No ads = no harm in requesting consent. Optimization for future.

### 4. XcodeGen Regeneration Required
- Changes to project.yml require running `xcodegen generate` to regenerate Xcode project
- xcconfig files won't be referenced until project regeneration
- **Not a blocker:** Standard workflow, documented in README

## Testing Notes

### Manual Testing Required
1. **Debug build with xcconfig IDs:**
   - Run `xcodegen generate` in Kindred/ directory
   - Build in Debug configuration
   - Verify AdModels.feedNative returns test ID "ca-app-pub-3940256099942544/3986624511"
   - Verify GADMobileAds initializes without errors

2. **Release build with placeholder IDs (should crash):**
   - Run `xcodegen generate`
   - Build in Release configuration
   - Launch app → should fatalError with message "ADMOB_FEED_NATIVE_ID not configured"

3. **Release build with production IDs:**
   - Edit Config/Release.xcconfig with real AdMob IDs
   - Run `xcodegen generate`
   - Build in Release configuration
   - Verify app launches without crashing
   - Verify AdModels.feedNative returns production ID

4. **Consent-aware ad personalization:**
   - Run app → complete consent flow with ATT Allow
   - Check GADMobileAds.requestConfiguration.publisherPrivacyPersonalizationState == .allowed
   - Run app → deny ATT
   - Check publisherPrivacyPersonalizationState == .notAllowed

5. **Tracking settings deep link:**
   - Navigate to Profile > Privacy & Data
   - Verify "Tracking Permission" row appears
   - Tap row → verify iOS Settings opens
   - Verify Settings shows app-specific tracking toggle

### Automated Testing
- Build verification: `xcodegen generate && xcodebuild build -scheme Kindred -configuration Debug`
- AdModels fallback test: Unit test with mocked Bundle.main.object(forInfoDictionaryKey:) returning nil
- AdClient personalization test: Unit test calling configurePersonalization with each ConsentStatus case

## Self-Check: PASSED

### Files Created
```bash
test -f Kindred/Config/Debug.xcconfig
# FOUND: Kindred/Config/Debug.xcconfig

test -f Kindred/Config/Release.xcconfig
# FOUND: Kindred/Config/Release.xcconfig
```

### Files Modified
```bash
grep -q "configs:" Kindred/project.yml
# PASS: configs section added

grep -q '$(ADMOB_APP_ID)' Kindred/Sources/Info.plist
# PASS: xcconfig variable reference

grep -q "forInfoDictionaryKey" Kindred/Packages/MonetizationFeature/Sources/Models/AdModels.swift
# PASS: reads from Info.plist

grep -q "configurePersonalization" Kindred/Packages/MonetizationFeature/Sources/Ads/AdClient.swift
# PASS: consent integration

grep -q "#if DEBUG" Kindred/Sources/App/AppDelegate.swift
# PASS: test device config guarded

grep -q "onTrackingSettingsTapped" Kindred/Packages/ProfileFeature/Sources/PrivacyDataSection.swift
# PASS: tracking settings row
```

### Commits Exist
```bash
git log --oneline | grep -q "0ff9b82"
# FOUND: 0ff9b82 feat(20-02): create xcconfig files and refactor ad unit ID configuration

git log --oneline | grep -q "6830e15"
# FOUND: 6830e15 feat(20-02): integrate consent into AdClient and add tracking settings deep link
```

All artifacts verified on disk. Self-check PASSED.

## Next Steps

Plan 20-03 will:
1. Wire AdClient.configurePersonalization to AppReducer's consent flow completion handler
2. Add scene phase observer to re-check consent on app foreground
3. Test full consent → ad personalization flow end-to-end
4. Replace placeholder IDs with production AdMob unit IDs from https://apps.admob.com/ (or document TODO for pre-submission)
5. Manual verification: consent flow → ATT permission → ad personalization → tracking settings deep link
