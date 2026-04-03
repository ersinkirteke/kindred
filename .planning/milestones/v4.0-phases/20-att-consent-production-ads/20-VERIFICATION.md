---
phase: 20-att-consent-production-ads
verified: 2026-04-03T19:45:00Z
status: gaps_found
score: 6/8 must-haves verified
gaps:
  - truth: "AdClient configures AdMob personalization state based on ConsentStatus"
    status: failed
    reason: "configurePersonalization closure exists but is never called from AppReducer"
    artifacts:
      - path: "Kindred/Sources/App/AppReducer.swift"
        issue: "Missing call to adClient.configurePersonalization() in .consent(.consentFlowCompleted) handler"
    missing:
      - "Wire adClient.configurePersonalization(status) in AppReducer's .consent(.consentFlowCompleted) handler"
  - truth: "Pro subscribers skip consent flow entirely (no ads = no consent needed)"
    status: partial
    reason: "TODO comment exists but subscription check not implemented"
    artifacts:
      - path: "Kindred/Sources/App/AppReducer.swift"
        issue: "checkConsentStatus and triggerConsentFlow have TODO comments for subscription check"
    missing:
      - "Check subscription status in checkConsentStatus and triggerConsentFlow actions, skip if .pro"
---

# Phase 20: ATT Consent & Production Ads Verification Report

**Phase Goal:** Users can opt into personalized ads through compliant ATT consent flow
**Verified:** 2026-04-03T19:45:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #   | Truth                                                                                                                    | Status      | Evidence                                                                                                                          |
| --- | ------------------------------------------------------------------------------------------------------------------------ | ----------- | --------------------------------------------------------------------------------------------------------------------------------- |
| 1   | User sees pre-prompt explanation screen before ATT system dialog explaining ad personalization benefits                 | ✓ VERIFIED  | PrePromptView exists with friendly copy, Continue button, ConsentReducer state machine triggers pre-prompt before ATT            |
| 2   | App coordinates UMP consent (GDPR/CCPA) before requesting ATT authorization                                             | ✓ VERIFIED  | ConsentReducer flow: checkingUMP → showingUMPForm → showingPrePrompt → requestingATT, UMP precedes ATT                           |
| 3   | Debug builds use Google test ad unit IDs, Release builds use production placeholder IDs                                 | ✓ VERIFIED  | Debug.xcconfig has test IDs, Release.xcconfig has REPLACE_WITH_PRODUCTION placeholders, AdModels reads from Info.plist           |
| 4   | Info.plist GADApplicationIdentifier reads from xcconfig variable $(ADMOB_APP_ID)                                        | ✓ VERIFIED  | Info.plist uses $(ADMOB_APP_ID), project.yml configFiles references Debug.xcconfig and Release.xcconfig                          |
| 5   | AdModels.swift reads ad unit IDs from Info.plist build settings (not hardcoded strings)                                 | ✓ VERIFIED  | AdUnitIDs computed properties use Bundle.main.object(forInfoDictionaryKey:), fatalError if REPLACE not removed in Release        |
| 6   | AdClient configures AdMob personalization state based on ConsentStatus                                                  | ✗ FAILED    | AdClient.configurePersonalization closure exists but is NEVER called from AppReducer .consent(.consentFlowCompleted) handler     |
| 7   | Pro subscribers skip consent flow entirely (no ads = no consent needed)                                                 | ⚠️ PARTIAL  | TODO comments in checkConsentStatus and triggerConsentFlow, subscription check not implemented                                   |
| 8   | User can navigate to iOS Settings tracking permission from Profile > Privacy & Data section                             | ✓ VERIFIED  | PrivacyDataSection has "Tracking Permission" row, ProfileReducer.trackingSettingsTapped opens UIApplication.openSettingsURLString |

**Score:** 6/8 truths verified (75%)

### Required Artifacts

| Artifact                                                                              | Expected                                                                     | Status      | Details                                                                                                                 |
| ------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- | ----------- | ----------------------------------------------------------------------------------------------------------------------- |
| `Kindred/Packages/MonetizationFeature/Sources/Consent/ConsentModels.swift`           | ConsentStatus enum with 5 cases, ConsentFlowStep enum                        | ✓ VERIFIED  | 21 lines, defines all 5 ConsentStatus cases and 6 ConsentFlowStep cases                                                |
| `Kindred/Packages/MonetizationFeature/Sources/Consent/ConsentClient.swift`           | TCA dependency for UMP + ATT coordination                                    | ✓ VERIFIED  | 125 lines, liveValue with real UMP/ATT, testValue, named presets (.allGranted, .attDenied)                             |
| `Kindred/Packages/MonetizationFeature/Sources/Consent/PrePromptView.swift`           | Full-screen modal pre-prompt screen with Continue button                    | ✓ VERIFIED  | 70 lines, friendly copy, heart.text.square icon, DesignSystem tokens, interactiveDismissDisabled                       |
| `Kindred/Packages/MonetizationFeature/Sources/Consent/ConsentReducer.swift`          | State machine managing UMP → pre-prompt → ATT flow                           | ✓ VERIFIED  | 214 lines, handles all actions, graceful UMP failure, Firebase Analytics control                                       |
| `Kindred/Sources/Info.plist`                                                          | NSUserTrackingUsageDescription key                                           | ✓ VERIFIED  | Key exists with user-decided copy about kitchen tools and cooking style                                                 |
| `Kindred/Sources/PrivacyInfo.xcprivacy`                                               | NSPrivacyTracking true, tracking domains                                     | ✓ VERIFIED  | NSPrivacyTracking=true, 5 Google tracking domains added                                                                 |
| `Kindred/Config/Debug.xcconfig`                                                       | Debug build settings with Google test ad unit IDs                            | ✓ VERIFIED  | 10 lines, contains ADMOB_APP_ID, ADMOB_FEED_NATIVE_ID, ADMOB_DETAIL_BANNER_ID with test values                         |
| `Kindred/Config/Release.xcconfig`                                                     | Release build settings with production placeholder IDs                       | ✓ VERIFIED  | 12 lines, contains REPLACE_WITH_PRODUCTION placeholders, TODO comment links to AdMob console                            |
| `Kindred/Packages/MonetizationFeature/Sources/Models/AdModels.swift`                 | AdUnitIDs reading from Bundle.main.object(forInfoDictionaryKey:)             | ✓ VERIFIED  | 42 lines, computed properties read from Info.plist, fatalError for unconfigured Release builds                         |
| `Kindred/Packages/MonetizationFeature/Sources/Ads/AdClient.swift`                    | AdClient with consent-aware ad personalization configuration                 | ⚠️ ORPHANED | configurePersonalization closure exists with correct logic (.enabled for fullyGranted, .disabled otherwise), NOT CALLED |
| `Kindred/Packages/ProfileFeature/Sources/PrivacyDataSection.swift`                   | Tracking settings deep link row                                              | ✓ VERIFIED  | "Tracking Permission" row with gear icon, calls onTrackingSettingsTapped callback                                       |
| `Kindred/Packages/MonetizationFeature/Tests/ConsentReducerTests.swift`               | TCA TestStore tests for ConsentReducer                                       | ✓ VERIFIED  | 415 lines, 10 comprehensive test scenarios covering all consent flow paths                                              |
| `Kindred/Packages/ProfileFeature/Sources/DebugMenu/ConsentDebugMenu.swift`           | Debug-only consent reset menu                                                | ✓ VERIFIED  | 62 lines, resets hasSeenATTPrePrompt UserDefaults, #if DEBUG guarded                                                    |

### Key Link Verification

| From                                      | To                                              | Via                                           | Status     | Details                                                                                                             |
| ----------------------------------------- | ----------------------------------------------- | --------------------------------------------- | ---------- | ------------------------------------------------------------------------------------------------------------------- |
| AppReducer                                | ConsentReducer                                  | Scoped child reducer                          | ✓ WIRED    | Line 113-114: Scope(state: \\.consentState, action: \\.consent) { ConsentReducer() }                               |
| ConsentReducer                            | ConsentClient                                   | @Dependency(\.consentClient)                  | ✓ WIRED    | Line 46, used throughout reducer body                                                                               |
| ConsentReducer.prePromptContinueTapped    | ATTrackingManager.requestTrackingAuthorization | TCA effect calling consentClient              | ✓ WIRED    | Line 151: await consentClient.requestATTAuthorization()                                                             |
| RootView                                  | PrePromptView                                   | .sheet(item: store.consentState)              | ✓ WIRED    | Line 119-122: sheet presents PrePromptView when isShowingPrePrompt=true                                             |
| Debug.xcconfig                            | Info.plist                                      | $(ADMOB_APP_ID) variable reference            | ✓ WIRED    | project.yml configFiles maps Debug to Config/Debug.xcconfig, Info.plist line 50 uses $(ADMOB_APP_ID)               |
| Info.plist                                | AdModels                                        | Bundle.main.object(forInfoDictionaryKey:)     | ✓ WIRED    | AdModels.swift lines 7, 22 read ADMOB_FEED_NATIVE_ID and ADMOB_DETAIL_BANNER_ID from Info.plist                    |
| AdClient.configurePersonalization         | ConsentStatus                                   | Consent-aware ad personalization config       | ✗ PARTIAL  | AdClient has correct logic (line 50-59) but AppReducer does NOT call configurePersonalization in consentFlowCompleted |
| ProfileView                               | ConsentDebugMenu                                | Long-press gesture on version label           | ✓ WIRED    | Line 208-210: .onLongPressGesture presents debug menu sheet                                                         |
| PrivacyDataSection.onTrackingSettingsTapped | UIApplication.openSettingsURLString           | ProfileReducer action handler                 | ✓ WIRED    | ProfileReducer line 430-437: trackingSettingsTapped opens Settings URL                                              |
| AppReducer.authStateChanged               | checkConsentStatus                              | Existing user launch consent trigger          | ✓ WIRED    | Line 183: .send(.checkConsentStatus) when authenticated + onboarding complete                                       |
| AppReducer.onboarding(.completed)         | triggerConsentFlow                              | New user post-onboarding consent trigger      | ✓ WIRED    | Line 334: .send(.triggerConsentFlow) after onboarding completes (unless voice upload active)                        |

### Requirements Coverage

| Requirement | Source Plan | Description                                                                               | Status     | Evidence                                                                                                           |
| ----------- | ----------- | ----------------------------------------------------------------------------------------- | ---------- | ------------------------------------------------------------------------------------------------------------------ |
| PRIV-01     | 20-01       | App shows ATT consent prompt with pre-prompt explanation before personalized ads          | ⚠️ PARTIAL | Pre-prompt + ATT flow works, but AdClient personalization NOT configured (missing call in AppReducer)              |
| BILL-03     | 20-02       | Production AdMob unit IDs replace test IDs in Info.plist and AdClient.swift               | ✓ SATISFIED | xcconfig infrastructure complete, Release.xcconfig has placeholders with TODO, AdModels reads from build settings  |

**Requirements Coverage:** 1/2 fully satisfied, 1/2 partially blocked

### Anti-Patterns Found

| File                                                  | Line  | Pattern                                                 | Severity   | Impact                                                                             |
| ----------------------------------------------------- | ----- | ------------------------------------------------------- | ---------- | ---------------------------------------------------------------------------------- |
| Kindred/Sources/App/AppReducer.swift                  | 380-385 | configurePersonalization never called                 | 🛑 BLOCKER | Ad personalization defaults to non-personalized regardless of ATT consent          |
| Kindred/Sources/App/AppReducer.swift                  | 363, 376 | TODO comments for subscription check                  | ⚠️ WARNING | Pro subscribers still see consent flow (no harm but suboptimal UX)                 |
| Kindred/Sources/App/AppReducer.swift                  | 382   | TODO comment for forwarding consent to FeedReducer      | ℹ️ INFO    | Consent status not propagated to FeedReducer for ad visibility control             |

### Human Verification Required

#### 1. ATT Consent Flow End-to-End

**Test:** Complete full consent flow on physical device (iPhone 16 Pro Max)
**Expected:**
- New user completes onboarding → UMP form (if GDPR region) → pre-prompt sheet → ATT system dialog
- Pre-prompt shows friendly copy with Continue button, no swipe-to-dismiss
- Tapping Continue triggers iOS ATT dialog
- Allowing ATT proceeds to feed, denying ATT proceeds to feed with non-personalized ads

**Why human:** ATT system dialog only appears on physical devices, not simulators. Requires manual interaction to verify UX flow.

**User Reported:** ✅ PASSED (7 test scenarios verified on device per 20-03-SUMMARY.md)

#### 2. Debug Menu Consent Reset

**Test:** Long-press version label in Profile → tap "Reset Consent Pre-Prompt" → restart app
**Expected:** Consent flow appears again on next launch

**Why human:** Requires physical device interaction and app restart to verify UserDefaults flag clearing.

**User Reported:** ✅ PASSED (Test 6 in 20-03-SUMMARY.md)

#### 3. Tracking Settings Deep Link

**Test:** Navigate to Profile > Privacy & Data → tap "Tracking Permission" row
**Expected:** iOS Settings app opens to app-specific settings showing ATT toggle

**Why human:** Deep linking to Settings requires physical device, simulator behavior differs.

**User Reported:** ✅ PASSED (Test 5 in 20-03-SUMMARY.md)

#### 4. Xcconfig Build Configuration

**Test:** Build in Debug config → verify test ad IDs used. Build in Release config → verify placeholder check prevents shipping.
**Expected:** Debug builds use test IDs from Debug.xcconfig, Release builds fatalError if placeholders not replaced

**Why human:** Requires Xcode build configuration switching and runtime verification.

**User Reported:** ✅ PASSED (Test 7 in 20-03-SUMMARY.md)

### Gaps Summary

**2 gaps block full goal achievement:**

#### Gap 1: AdClient personalization NOT configured (BLOCKER)
**Impact:** Ad personalization defaults to non-personalized regardless of user consent. User allows ATT tracking but still receives non-personalized ads, breaking PRIV-01 requirement intent.

**Root Cause:** Plan 20-02 created `AdClient.configurePersonalization` closure but Plan 20-01's AppReducer wiring never calls it. The `.consent(.consentFlowCompleted(status))` handler (line 380-385) logs completion but does NOT call `adClient.configurePersonalization(status)`.

**Fix Required:**
```swift
case .consent(.consentFlowCompleted(let status)):
    state.needsConsentFlow = false
    return .run { @MainActor in
        adClient.configurePersonalization(status)
    }
```

#### Gap 2: Pro subscriber check NOT implemented (WARNING)
**Impact:** Pro subscribers see consent flow even though no ads will be shown. Suboptimal UX but no functional harm (FeedReducer hides ads for pro users regardless of consent).

**Root Cause:** Plan 20-01 deferred subscription status check to future work. TODO comments exist in `checkConsentStatus` (line 363) and `triggerConsentFlow` (line 376) but implementation never added.

**Fix Required:**
```swift
case .checkConsentStatus:
    guard state.hasCompletedOnboarding else { return .none }
    guard case .authenticated = state.currentAuthState else { return .none }

    // Skip consent for pro subscribers
    if case .pro = state.profileState.subscriptionStatus {
        return .none
    }

    let attStatus = consentClient.checkATTStatus()
    guard attStatus == .notDetermined else { return .none }

    state.needsConsentFlow = true
    return .send(.consent(.checkConsentOnLaunch))
```

**Severity:** Gap 1 is a blocker for personalized ads functionality. Gap 2 is a quality issue but does not break core flow.

---

_Verified: 2026-04-03T19:45:00Z_
_Verifier: Claude (gsd-verifier)_
