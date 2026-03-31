# Phase 20: ATT Consent & Production Ads - Research

**Researched:** 2026-04-01
**Domain:** iOS App Tracking Transparency (ATT), User Messaging Platform (UMP), AdMob production configuration
**Confidence:** HIGH

## Summary

Phase 20 implements compliant ATT consent flow with UMP coordination for GDPR/CCPA, production AdMob unit IDs, and consent-driven ad initialization. The core challenge is coordinating three systems: UMP SDK (GDPR/CCPA consent), ATT framework (iOS tracking authorization), and AdMob SDK (ad initialization with correct consent status). Research shows pre-prompt screens boost opt-in rates 20-40%, UMP must run before ATT, and xcconfig files provide clean Debug/Release ad ID switching.

**Primary recommendation:** Implement ConsentClient as TCA dependency managing UMP → ATT flow, use xcconfig-based ad unit ID switching with placeholder production IDs, disable Firebase Analytics on ATT denial, and test on physical device (simulators don't support ATT).

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PRIV-01 | App shows ATT consent prompt with pre-prompt explanation before personalized ads | ATT pre-prompt patterns (Pitfall 1), UMP coordination order, ConsentClient architecture |
| BILL-03 | Production AdMob unit IDs replace test IDs in Info.plist and AdClient.swift | xcconfig build configuration, AdModels.swift refactoring, test ID replacement best practices |

</phase_requirements>

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Pre-prompt Screen:**
- Full-screen modal sheet presentation
- Friendly & casual tone matching Kindred's personality (e.g., "Hey! We'd like to show you ads that match your tastes")
- SF Symbol icon at top (no custom illustration)
- Single "Continue" button that always triggers the ATT system dialog — no "Not now" / skip option
- SwiftUI Preview for layout verification without triggering actual ATT

**Consent Flow Timing:**
- Order: UMP consent form first (region-based, only where legally required), then ATT pre-prompt, then iOS ATT system dialog
- Seamless blocking sequence — user must complete the flow before reaching the feed; UMP → pre-prompt → ATT dialog happen as one continuous step
- Triggers after onboarding completes for new users
- Existing users (already completed onboarding) see the pre-prompt on their next app launch — tracked via UserDefaults flag
- Skip the pre-prompt entirely if ATT status is already `.authorized` or `.denied` — only show for `.notDetermined`
- Deep link to iOS Settings for tracking permission added in Profile > Privacy & Data section (PrivacyDataSection.swift)
- Keep existing first-launch ad suppression (`kindredFirstLaunchComplete` flag) alongside the consent flow — belt-and-suspenders
- NSUserTrackingUsageDescription: "Kindred uses this to show you ads for kitchen tools and ingredients that match your cooking style."
- PrivacyInfo.xcprivacy updated: `NSPrivacyTracking: true`, Google tracking domains added

**Decline Behavior:**
- ATT denied → show non-personalized ads (AdMob supports this natively)
- UMP consent denied (GDPR/CCPA regions) → show non-personalized ads (limited ads mode)
- No visual indicator distinguishing personalized vs non-personalized ads
- Skip consent flow entirely for pro subscribers (no ads = no need for consent)
- If pro user downgrades → trigger consent flow before ads start appearing
- Explicit consent passing to AdMob — AdClient reads ATT + UMP status and configures GADMobileAds request parameters explicitly
- Check ATTrackingManager.trackingAuthorizationStatus on every app launch to pick up Settings changes
- If ATT request throws (rare edge case) → treat as `.denied`, non-personalized ads, no retry
- Disable Firebase Analytics data collection if user denies ATT tracking

**Production Ad Configuration:**
- Xcconfig-based debug/release switching for both ad unit IDs and GADApplicationIdentifier
- Debug xcconfig: Google test IDs (current values)
- Release xcconfig: placeholder strings ("REPLACE_WITH_PRODUCTION_APP_ID") with TODO comments
- Info.plist references `$(ADMOB_APP_ID)` from xcconfig instead of hardcoded value
- AdModels.swift reads ad unit IDs from xcconfig-injected build settings
- Xcconfig files committed to repo (ad IDs are not secrets — embedded in app binary anyway)
- Keep GADSimulatorID and test device config in AppDelegate for debug builds only (`#if DEBUG`)
- AdMob SDK initializes immediately at launch (current behavior), consent status configured before loading any ads
- Keep existing ad formats only: feed native (AdCardView) and recipe detail banner (BannerAdView)
- AdMob only — no mediation with other ad networks

**Error Handling:**
- UMP form fails to load → skip consent form, fall back to non-personalized ads, don't block the user
- UMP failure does NOT skip ATT — still show ATT pre-prompt and system dialog (they're independent)
- Failed UMP attempts retried on next app launch
- Consent errors logged silently via OSLog — user sees nothing, flow degrades gracefully

**Architecture:**
- New `ConsentClient` TCA dependency in MonetizationFeature/Sources/Consent/ — manages UMP + ATT consent
- New `ConsentReducer` in MonetizationFeature/Sources/Consent/ — manages the UMP → ATT flow, pre-prompt sheet presentation, and consent state
- Combined `ConsentStatus` enum: `.fullyGranted`, `.attDenied`, `.umpDenied`, `.bothDenied`, `.notDetermined`
- Consent status lives in TCA shared state (app-level), updated on launch and after consent flow
- Consent state resolved before feed loads — TCA effect in root reducer fires `.checkConsentStatus` on `.onAppear`
- `AdClient.shouldShowAds` updated to integrate consent status (first-launch flag + subscription + consent = single source of truth)
- UMP consent state persistence handled by UMP SDK internally — no local caching needed
- "Has seen pre-prompt" flag stored in UserDefaults
- AppTrackingTransparency framework added as new dependency to MonetizationFeature Package.swift

**Testing & QA:**
- Test on physical device (iPhone 16 Pro Max) — ATT prompt only works on real devices
- ConsentClient.testValue with configurable presets: `.allGranted`, `.attDenied`, `.umpDenied`, `.notDetermined`
- Debug menu accessible via long-press on app version label in Profile screen — consent reset button only (clears UserDefaults flag so pre-prompt shows again), debug builds only
- Debug menu included in Phase 20 scope (directly supports testing consent flow)
- SwiftUI Preview for pre-prompt screen
- Snapshot test using PointFree's swift-snapshot-testing library (new dependency)
- TCA reducer tests for consent flow: UMP → ATT sequence, error fallbacks, consent state transitions
- Target: iOS 17+, no ATT compatibility concerns

**Analytics & Logging:**
- Firebase Analytics events with descriptive names:
  - `consent_att_shown` — pre-prompt displayed
  - `consent_att_authorized` — user allowed tracking
  - `consent_att_denied` — user denied tracking
  - `consent_ump_obtained` — UMP consent granted
  - `consent_ump_denied` — UMP consent denied
  - `consent_ump_failed` — UMP form failed to load
- Minimal event parameters: result + app version only
- Dedicated OSLog Logger: `Logger(subsystem: "com.ersinkirteke.kindred", category: "consent")`
- Raw Firebase events only — no in-app dashboard for consent metrics

### Claude's Discretion

- Exact SF Symbol choice for pre-prompt screen
- Pre-prompt body text copywriting (within friendly/casual tone)
- Exact spacing, typography, and layout details of pre-prompt sheet
- Google tracking domains list for PrivacyInfo.xcprivacy
- ConsentReducer internal state machine design
- Xcconfig file naming and organization
- Error retry timing logic for UMP
- Snapshot test reference image configuration

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope

</user_constraints>

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| AppTrackingTransparency | iOS 17.0+ (built-in) | IDFA consent for personalized ads | Apple's official framework for tracking authorization. Mandatory since iOS 14.5 for apps using ad identifiers. No alternatives exist. |
| Google UMP SDK | 3.0.0+ | GDPR/CCPA consent coordination | Official Google consent SDK coordinating with ATT. Handles region-specific consent forms, manages consent state persistence, triggers ATT at correct moment. Required for AdMob compliance. |
| GoogleMobileAds SDK | 11.0.0+ | AdMob ad serving | Already integrated. Requires consent status configuration via `GADMobileAds.sharedInstance().requestConfiguration` before initialization. |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| swift-snapshot-testing | 1.17.0+ | Snapshot tests for pre-prompt UI | PointFree's official snapshot testing library. SwiftUI Preview compatibility. Required for UI regression testing per user decisions. |
| OSLog | iOS 17.0+ (built-in) | Consent flow logging | Apple's unified logging system. Structured logging with privacy controls. User decision: `Logger(subsystem: "com.ersinkirteke.kindred", category: "consent")` |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| UMP SDK | Custom GDPR/CCPA forms | UMP SDK is mandatory for AdMob compliance per Google's privacy strategies. Custom forms don't coordinate with ATT and violate Google's terms. No viable alternative. |
| AppTrackingTransparency | Skip ATT entirely | Violates Apple guidelines 5.1.2 for apps collecting IDFA. App rejection. No alternative. |
| xcconfig files | Hardcode prod IDs in code | xcconfig separates config from code, supports Debug/Release switching, prevents accidental test ID commits to production. Industry standard for iOS multi-environment apps. |

**Installation:**

```bash
# Swift Package Manager (Package.swift)
.package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.17.0")

# UMP SDK already installed via SPM:
# https://github.com/googleads/swift-package-manager-google-user-messaging-platform
# Version 3.0.0+ already in project

# AppTrackingTransparency - built-in framework, no installation needed
# Add to MonetizationFeature Package.swift:
.target(
    name: "MonetizationFeature",
    dependencies: [
        // ... existing dependencies
    ],
    linkerSettings: [
        .linkedFramework("AppTrackingTransparency")
    ]
)
```

## Architecture Patterns

### Recommended Project Structure

```
Kindred/Packages/MonetizationFeature/Sources/
├── Ads/                      # Existing ad display views
│   ├── AdClient.swift
│   ├── AdCardView.swift
│   └── BannerAdView.swift
├── Consent/                  # NEW: ATT + UMP consent
│   ├── ConsentClient.swift   # TCA dependency for UMP + ATT coordination
│   ├── ConsentReducer.swift  # State machine: UMP → pre-prompt → ATT
│   ├── ConsentModels.swift   # ConsentStatus enum
│   └── PrePromptView.swift   # Pre-ATT explanation screen
├── Models/
│   └── AdModels.swift        # REFACTOR: Read IDs from build settings
└── Subscription/             # Existing subscription views

Kindred/Config/               # NEW: xcconfig files
├── Debug.xcconfig
└── Release.xcconfig

Kindred/Sources/
├── Info.plist                # UPDATE: NSUserTrackingUsageDescription, $(ADMOB_APP_ID)
└── PrivacyInfo.xcprivacy     # UPDATE: NSPrivacyTracking true, tracking domains
```

### Pattern 1: UMP → ATT Coordination Flow

**What:** UMP consent must complete before ATT prompt. If UMP fails, continue to ATT (they're independent).

**When to use:** Every app launch when consent status is `.notDetermined`.

**Example:**

```swift
// Source: https://developers.google.com/admob/ios/privacy
// Adapted for TCA + ATT coordination

import ComposableArchitecture
import AppTrackingTransparency
import UserMessagingPlatform

@Reducer
struct ConsentReducer {
    struct State: Equatable {
        var consentStatus: ConsentStatus = .notDetermined
        var isShowingPrePrompt = false
        var lastError: String?
    }

    enum Action {
        case checkConsentOnLaunch
        case umpConsentUpdateReceived(Result<UMPFormStatus, Error>)
        case showPrePromptIfNeeded
        case prePromptContinueTapped
        case attAuthorizationReceived(ATTrackingManager.AuthorizationStatus)
        case consentFlowCompleted(ConsentStatus)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .checkConsentOnLaunch:
                // Check if ATT already determined
                let attStatus = ATTrackingManager.trackingAuthorizationStatus
                if attStatus != .notDetermined {
                    // Already determined, skip flow
                    state.consentStatus = attStatus == .authorized ? .fullyGranted : .attDenied
                    return .none
                }

                // Start UMP consent check
                return .run { send in
                    let parameters = UMPRequestParameters()
                    parameters.tagForUnderAgeOfConsent = false

                    do {
                        try await UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters)
                        let formStatus = UMPConsentInformation.sharedInstance.formStatus
                        await send(.umpConsentUpdateReceived(.success(formStatus)))
                    } catch {
                        await send(.umpConsentUpdateReceived(.failure(error)))
                    }
                }

            case let .umpConsentUpdateReceived(.success(formStatus)):
                if formStatus == .available {
                    // Show UMP form, then continue to ATT
                    return .run { send in
                        do {
                            let form = try await UMPConsentForm.load()
                            // Present form (requires main actor context)
                            // After form completes, move to pre-prompt
                            await send(.showPrePromptIfNeeded)
                        } catch {
                            // UMP failed, but continue to ATT anyway
                            await send(.showPrePromptIfNeeded)
                        }
                    }
                } else {
                    // No UMP form needed, go straight to pre-prompt
                    return .send(.showPrePromptIfNeeded)
                }

            case let .umpConsentUpdateReceived(.failure(error)):
                // Log error but don't block ATT
                state.lastError = error.localizedDescription
                return .send(.showPrePromptIfNeeded)

            case .showPrePromptIfNeeded:
                // Check if user has seen pre-prompt before
                let hasSeenPrePrompt = UserDefaults.standard.bool(forKey: "hasSeenATTPrePrompt")
                if !hasSeenPrePrompt {
                    state.isShowingPrePrompt = true
                }
                return .none

            case .prePromptContinueTapped:
                state.isShowingPrePrompt = false
                UserDefaults.standard.set(true, forKey: "hasSeenATTPrePrompt")

                // Trigger ATT system prompt
                return .run { send in
                    let status = await ATTrackingManager.requestTrackingAuthorization()
                    await send(.attAuthorizationReceived(status))
                }

            case let .attAuthorizationReceived(status):
                // Combine UMP + ATT status
                let umpConsent = UMPConsentInformation.sharedInstance.consentStatus
                let finalStatus: ConsentStatus

                if status == .authorized && umpConsent == .obtained {
                    finalStatus = .fullyGranted
                } else if status == .authorized {
                    finalStatus = .fullyGranted // ATT is primary for personalization
                } else if umpConsent == .obtained {
                    finalStatus = .attDenied // UMP ok but ATT denied
                } else {
                    finalStatus = .bothDenied
                }

                return .send(.consentFlowCompleted(finalStatus))

            case let .consentFlowCompleted(status):
                state.consentStatus = status
                // Configure AdMob with consent status
                // Disable Firebase Analytics if denied
                return .run { _ in
                    if status == .attDenied || status == .bothDenied {
                        // Disable Firebase Analytics
                        Analytics.setAnalyticsCollectionEnabled(false)
                    }
                    // Configure AdMob for personalized/non-personalized ads
                    // (handled in AdClient)
                }
            }
        }
    }
}

enum ConsentStatus: Equatable, Sendable {
    case notDetermined
    case fullyGranted      // ATT + UMP both granted
    case attDenied         // ATT denied, UMP granted
    case umpDenied         // UMP denied, ATT granted (rare)
    case bothDenied        // Both denied
}
```

### Pattern 2: Xcconfig-Based Ad Unit ID Switching

**What:** Separate Debug.xcconfig and Release.xcconfig files define build-specific ad unit IDs and app IDs.

**When to use:** Multi-environment iOS apps needing test/production configuration separation.

**Example:**

```bash
# Debug.xcconfig
// Google test ad unit IDs for development
ADMOB_APP_ID = ca-app-pub-3940256099942544~1458002511
ADMOB_FEED_NATIVE_ID = ca-app-pub-3940256099942544/3986624511
ADMOB_DETAIL_BANNER_ID = ca-app-pub-3940256099942544/2435281174

# Release.xcconfig
// TODO: Replace with production AdMob unit IDs from AdMob console
// Get production IDs: https://apps.admob.com/
ADMOB_APP_ID = REPLACE_WITH_PRODUCTION_APP_ID
ADMOB_FEED_NATIVE_ID = REPLACE_WITH_PRODUCTION_FEED_NATIVE_ID
ADMOB_DETAIL_BANNER_ID = REPLACE_WITH_PRODUCTION_DETAIL_BANNER_ID
```

**Info.plist:**

```xml
<key>GADApplicationIdentifier</key>
<string>$(ADMOB_APP_ID)</string>
```

**AdModels.swift:**

```swift
// Source: Xcode build settings injection pattern
// https://felginep.github.io/2021-01-21/xcode-configuration-multiple-environments

import Foundation

public struct AdUnitIDs {
    /// Feed native ad unit ID from xcconfig (Debug: test ID, Release: production)
    public static let feedNative: String = {
        guard let id = Bundle.main.object(forInfoDictionaryKey: "ADMOB_FEED_NATIVE_ID") as? String,
              !id.isEmpty,
              !id.contains("REPLACE") else {
            fatalError("ADMOB_FEED_NATIVE_ID not configured in xcconfig. See Config/Release.xcconfig")
        }
        return id
    }()

    /// Recipe detail banner ad unit ID from xcconfig
    public static let detailBanner: String = {
        guard let id = Bundle.main.object(forInfoDictionaryKey: "ADMOB_DETAIL_BANNER_ID") as? String,
              !id.isEmpty,
              !id.contains("REPLACE") else {
            fatalError("ADMOB_DETAIL_BANNER_ID not configured in xcconfig. See Config/Release.xcconfig")
        }
        return id
    }()
}
```

### Pattern 3: TCA Dependency Testing with Presets

**What:** ConsentClient.testValue provides configurable consent status presets for testing different scenarios.

**When to use:** TCA reducer tests, SwiftUI Previews, integration tests.

**Example:**

```swift
// Source: TCA testing patterns
// https://github.com/pointfreeco/swift-composable-architecture

extension ConsentClient {
    public static let testValue = ConsentClient(
        checkConsentStatus: { .notDetermined },
        requestConsent: { _ in },
        resetConsent: {}
    )

    // Test preset: All consents granted
    public static let allGranted = ConsentClient(
        checkConsentStatus: { .fullyGranted },
        requestConsent: { _ in },
        resetConsent: {}
    )

    // Test preset: ATT denied
    public static let attDenied = ConsentClient(
        checkConsentStatus: { .attDenied },
        requestConsent: { _ in },
        resetConsent: {}
    )

    // Test preset: Not determined (triggers flow)
    public static let notDetermined = ConsentClient(
        checkConsentStatus: { .notDetermined },
        requestConsent: { completion in
            // Simulate user granting consent after delay
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                await completion(.fullyGranted)
            }
        },
        resetConsent: {}
    )
}

// Usage in SwiftUI Preview
#Preview {
    FeedView()
        .dependency(\.consentClient, .allGranted)
}

// Usage in TCA test
func testConsentFlow() async {
    let store = TestStore(
        initialState: ConsentReducer.State()
    ) {
        ConsentReducer()
    } withDependencies: {
        $0.consentClient = .notDetermined
    }

    await store.send(.checkConsentOnLaunch)
    await store.receive(.showPrePromptIfNeeded) {
        $0.isShowingPrePrompt = true
    }
    await store.send(.prePromptContinueTapped) {
        $0.isShowingPrePrompt = false
    }
    await store.receive(.attAuthorizationReceived(.authorized))
    await store.receive(.consentFlowCompleted(.fullyGranted)) {
        $0.consentStatus = .fullyGranted
    }
}
```

### Anti-Patterns to Avoid

- **Requesting ATT before UMP:** UMP must complete first. ATT prompt shown before UMP violates Google's privacy strategies and may cause app rejection.
- **Hardcoding production ad IDs in source code:** Makes accidental test ID commits to production easy. Use xcconfig for build-specific configuration.
- **Showing ATT prompt on first launch without pre-prompt:** Opt-in rates drop from 50-70% to 25-35%. Always show pre-prompt first.
- **Blocking user flow when UMP fails:** UMP failure should fall back to non-personalized ads, not block the app. ATT is independent of UMP.
- **Using `@Dependency` in SwiftUI views for ATT:** ATT requires main actor context. Use TCA effects with `.run` and send results back to reducer.
- **Testing ATT on simulator:** ATT always returns `.notDetermined` on simulator. Must test on physical device.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| GDPR/CCPA consent forms | Custom region-specific consent UI | Google UMP SDK | UMP handles region detection, consent storage, form presentation, IAB TCF compliance, and ATT coordination. Custom forms violate AdMob terms and cause rejection. |
| Consent state persistence | UserDefaults flags for consent status | UMP SDK internal storage + ATTrackingManager.trackingAuthorizationStatus | UMP persists consent state automatically across app launches. ATT status persists in iOS settings. Custom flags drift out of sync. |
| Ad unit ID environment switching | `#if DEBUG` conditionals in code | Xcode xcconfig files | xcconfig separates config from code, supports arbitrary build configurations, prevents merge conflicts, and is industry standard for iOS multi-environment apps. |
| Pre-prompt analytics | Custom analytics events | Firebase Analytics with consent-aware configuration | Firebase automatically respects ATT status and UMP consent. Custom analytics may violate privacy regulations if not properly gated. |

**Key insight:** ATT + UMP + AdMob is a tightly coupled system with Apple and Google enforcing compliance through App Store review and SDK restrictions. Custom implementations of any piece (consent forms, state management, analytics) introduce compliance risk and rejection probability.

## Common Pitfalls

### Pitfall 1: ATT Prompt Shown Before Pre-Prompt or Too Early

**What goes wrong:** App shows ATT system dialog immediately on first launch without pre-prompt explanation, or triggers it during onboarding before user experiences value. Opt-in rates drop to 25-35% instead of possible 50-70%.

**Why it happens:** Developers assume ATT must be requested early because AdMob needs tracking. They call `ATTrackingManager.requestTrackingAuthorization()` directly without pre-prompt education.

**How to avoid:**
1. Never show ATT on first launch — check if user has completed onboarding
2. Show full-screen pre-prompt before ATT system dialog (30-35% boost in opt-in rates)
3. Use friendly, benefit-focused copy explaining ad personalization value
4. Single "Continue" button that triggers ATT (no "Not Now" to avoid Apple rejection)
5. Store "has seen pre-prompt" flag to avoid showing twice
6. Skip flow entirely if `ATTrackingManager.trackingAuthorizationStatus != .notDetermined`

**Warning signs:**
- ATT prompt appears on app first launch
- No pre-prompt explanation screen
- Opt-in rate below 40%
- Users confused why app asks for tracking

**Sources:**
- [Mastering IDFA Opt-In Rates: The Complete AppTrackingTransparency Guide](https://www.playwire.com/blog/mastering-idfa-opt-in-rates-the-complete-apptrackingtransparency-guide-for-ios-apps)
- [ATT Opt-In Rates In 2025 (And How To Increase Them)](https://www.purchasely.com/blog/att-opt-in-rates-in-2025-and-how-to-increase-them)

### Pitfall 2: UMP and ATT Order Reversed

**What goes wrong:** App requests ATT authorization before completing UMP consent check. Google's UMP SDK fails to show ATT prompt automatically, or shows prompts in wrong order. GDPR/CCPA compliance violated.

**Why it happens:** Developers unfamiliar with UMP → ATT coordination. They call `requestTrackingAuthorization()` directly without waiting for UMP status.

**How to avoid:**
1. Always call `UMPConsentInformation.sharedInstance.requestConsentInfoUpdate()` first
2. Wait for UMP form presentation to complete (if required)
3. Only then show pre-prompt and trigger ATT
4. UMP failure should NOT block ATT (they're independent systems)
5. Document order clearly in code comments

**Warning signs:**
- ATT prompt appears before UMP form in EEA regions
- UMP SDK logs "ATT already requested" warnings
- GDPR consent form doesn't appear when expected
- Console errors about consent state conflicts

**Sources:**
- [Set up UMP SDK | iOS | Google for Developers](https://developers.google.com/admob/ios/privacy)
- [Optimal Integration Flow for AdMob, UMP, and GDPR Compliance](https://groups.google.com/g/google-admob-ads-sdk/c/8zKsWNXFppE)

### Pitfall 3: Production Ad Unit IDs Hardcoded or Missing

**What goes wrong:** Developer forgets to replace Google's test ad unit IDs with production IDs before App Store submission. App shows test ads in production, earning $0 revenue. Or worse, test IDs hardcoded in source code lead to accidental commits of production IDs to public repos.

**Why it happens:** Test IDs work great during development, and replacing them is a manual process prone to forgetting. No build-time check prevents test IDs from reaching production.

**How to avoid:**
1. Use xcconfig files with Debug.xcconfig (test IDs) and Release.xcconfig (production IDs)
2. Add placeholder strings in Release.xcconfig with "REPLACE_WITH_PRODUCTION" prefix
3. Add runtime assertion checking for placeholder strings (crash in production if not replaced)
4. Document production ID replacement in submission checklist
5. Never commit production IDs to source control (xcconfig files are fine — IDs are public)

**Warning signs:**
- AdModels.swift has hardcoded string literals
- No build-time differentiation between test and production
- Release builds still show "Test Ad" labels
- AdMob console shows no impressions after launch

**Sources:**
- [Enable test ads | iOS | Google for Developers](https://developers.google.com/admob/ios/test-ads)
- [Xcode configuration for multiple environments](https://felginep.github.io/2021-01-21/xcode-configuration-multiple-environments)

### Pitfall 4: Firebase Analytics Not Disabled on ATT Denial

**What goes wrong:** User denies ATT tracking permission, but Firebase Analytics continues collecting analytics data including IDFA-related events. Apple privacy audit flags app for tracking after denial. App removed from App Store.

**Why it happens:** Firebase Analytics initializes automatically on app launch and collects data by default. Developers assume ATT denial blocks all tracking automatically, but Firebase requires explicit `setAnalyticsCollectionEnabled(false)` call.

**How to avoid:**
1. Check `ATTrackingManager.trackingAuthorizationStatus` on every app launch
2. If status is `.denied` or `.restricted`, call `Analytics.setAnalyticsCollectionEnabled(false)`
3. Re-enable if user grants permission in iOS Settings (check on app foreground)
4. Test by denying ATT, then checking Charles Proxy for Firebase network requests
5. Add OSLog entries confirming analytics disabled/enabled state changes

**Warning signs:**
- Firebase network requests continue after ATT denial
- Privacy audit tools flag IDFA collection post-denial
- App uses Firebase Analytics but no ATT-gating code exists
- Console logs show Firebase events after user denies tracking

**Sources:**
- [Configure Analytics data collection and usage | Google Analytics for Firebase](https://firebase.google.com/docs/analytics/ios/configure-data-collection)
- [iOS App Tracking Transparency (ATT) impact to Google Analytics](https://github.com/firebase/firebase-ios-sdk/discussions/11855)

### Pitfall 5: Testing ATT Flow Only on Simulator

**What goes wrong:** ATT prompt tested only on iOS Simulator during development. Simulator always returns `.notDetermined` and never shows system dialog. Real device behavior not validated until production.

**Why it happens:** Physical device testing requires Apple Developer Program membership, provisioning profiles, and device registration. Simulator testing is faster and more convenient.

**How to avoid:**
1. Add Phase 20 test plan requiring physical device testing (iPhone 16 Pro Max per CONTEXT.md)
2. Reset ATT permission between tests: Settings > General > Transfer or Reset iPhone > Reset Location & Privacy
3. Create ConsentClient.testValue presets for different ATT states in SwiftUI Previews
4. Use debug menu (long-press version label) to reset consent flags and re-trigger flow
5. Document device testing requirement in verification checklist

**Warning signs:**
- All ATT testing done on simulator
- No physical device listed in test plan
- Console logs show "ATT not available on simulator" warnings
- Production issues with ATT prompt not appearing

**Sources:**
- [App Tracking Transparency | Apple Developer Documentation](https://developer.apple.com/documentation/apptrackingtransparency)
- [ATT Prompt: Why and when to show it | AppsFlyer](https://www.appsflyer.com/blog/tips-strategy/if-when-show-att-prompt/)

## Code Examples

Verified patterns from official sources:

### AdMob Initialization with Consent Configuration

```swift
// Source: https://developers.google.com/admob/ios/quick-start
// Updated for consent-aware initialization

import GoogleMobileAds
import AppTrackingTransparency

func configureAdMobWithConsent(consentStatus: ConsentStatus) {
    let requestConfiguration = GADMobileAds.sharedInstance().requestConfiguration

    // Configure test devices (debug builds only)
    #if DEBUG
    requestConfiguration.testDeviceIdentifiers = [GADSimulatorID]
    #endif

    // Set request parameters based on consent
    switch consentStatus {
    case .fullyGranted:
        // Personalized ads - no additional configuration needed
        requestConfiguration.setPublisherPrivacyPersonalizationState(.allowed)

    case .attDenied, .umpDenied, .bothDenied:
        // Non-personalized ads - limited ads mode
        requestConfiguration.setPublisherPrivacyPersonalizationState(.notAllowed)

    case .notDetermined:
        // Default to non-personalized until consent obtained
        requestConfiguration.setPublisherPrivacyPersonalizationState(.notAllowed)
    }

    // Initialize AdMob SDK
    GADMobileAds.sharedInstance().start { status in
        Logger.consent.info("AdMob initialized with consent status: \(String(describing: consentStatus))")
    }
}
```

### Pre-Prompt View with SwiftUI

```swift
// Source: User decisions in CONTEXT.md
// Friendly, casual tone matching Kindred personality

import SwiftUI
import DesignSystem

struct PrePromptView: View {
    let onContinue: () -> Void

    @ScaledMetric(relativeTo: .title) private var iconSize: CGFloat = 60
    @ScaledMetric(relativeTo: .title2) private var headingSize: CGFloat = 24
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 16

    var body: some View {
        VStack(spacing: KindredSpacing.xl) {
            Spacer()

            // Icon
            Image(systemName: "heart.text.square")
                .font(.system(size: iconSize))
                .foregroundColor(.kindredAccent)

            // Heading
            Text("Hey! Let's personalize your experience")
                .font(.kindredHeading2Scaled(size: headingSize))
                .foregroundColor(.kindredTextPrimary)
                .multilineTextAlignment(.center)

            // Body
            Text("We'd like to show you ads that match your tastes — think kitchen tools and ingredients you'll actually use. Tap Continue to help us personalize your ads.")
                .font(.kindredBodyScaled(size: bodySize))
                .foregroundColor(.kindredTextSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            // Continue button
            Button(action: onContinue) {
                Text("Continue")
                    .font(.kindredBodyScaled(size: bodySize).weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, KindredSpacing.md)
                    .background(Color.kindredAccent)
                    .cornerRadius(KindredRadius.md)
            }
        }
        .padding(KindredSpacing.xl)
        .background(Color.kindredBackground)
        .interactiveDismissDisabled() // Prevent swipe-to-dismiss
    }
}

#Preview {
    PrePromptView {
        print("Continue tapped")
    }
}
```

### Snapshot Test for Pre-Prompt

```swift
// Source: https://github.com/pointfreeco/swift-snapshot-testing
// PointFree snapshot testing with SwiftUI

import XCTest
import SnapshotTesting
@testable import MonetizationFeature

final class PrePromptViewSnapshotTests: XCTestCase {
    func testPrePromptAppearance() {
        let view = PrePromptView { }

        // Test iPhone 16 Pro Max (user's device)
        assertSnapshot(
            of: view,
            as: .image(
                layout: .device(config: .iPhone16ProMax),
                traits: .init(userInterfaceStyle: .light)
            ),
            testName: "light-mode"
        )

        assertSnapshot(
            of: view,
            as: .image(
                layout: .device(config: .iPhone16ProMax),
                traits: .init(userInterfaceStyle: .dark)
            ),
            testName: "dark-mode"
        )
    }

    func testPrePromptDynamicType() {
        let view = PrePromptView { }

        // Test accessibility text sizes
        assertSnapshot(
            of: view,
            as: .image(
                layout: .device(config: .iPhone16ProMax),
                traits: .init(preferredContentSizeCategory: .extraExtraExtraLarge)
            ),
            testName: "xxxl-text"
        )
    }
}
```

### Xcconfig File Setup in project.yml

```yaml
# Source: https://developer.apple.com/documentation/xcode/adding-a-build-configuration-file-to-your-project
# XcodeGen integration for xcconfig files

name: Kindred
# ... existing configuration

settings:
  base:
    SWIFT_VERSION: "5.10"
    DEVELOPMENT_TEAM: CV9G42QVG4
  configs:
    Debug:
      xcconfig: Config/Debug.xcconfig
    Release:
      xcconfig: Config/Release.xcconfig

targets:
  Kindred:
    type: application
    platform: iOS
    settings:
      base:
        INFOPLIST_FILE: Sources/Info.plist
        # Xcconfig values automatically injected
        # Access via $(ADMOB_APP_ID) in Info.plist
        # Access via Bundle.main.object(forInfoDictionaryKey:) in Swift
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| ATT only, no pre-prompt | Pre-prompt education + ATT | iOS 14.5 (2021), best practices emerged 2022-2023 | Opt-in rates increased from 25-35% to 50-70% with pre-prompt screens |
| Custom GDPR forms | Google UMP SDK | Google mandated UMP for AdMob (2020), v3.0.0 (March 2025) | Compliance enforcement, automatic ATT coordination, IAB TCF 2.2 support |
| Hardcoded ad IDs | Xcconfig-based configuration | Industry best practice (2015+), formalized with XcodeGen/Tuist | Prevents test ID production leaks, cleaner Debug/Release separation |
| Firebase Analytics always-on | Consent-gated analytics | Apple privacy audit enforcement (2021+), stricter in 2024-2026 | Apps must disable analytics on ATT denial or face removal |
| UMP SDK v2.x | UMP SDK v3.0.0 | March 2025 | Breaking changes: Xcode 16.0 required, Swift API naming updates, regulated US states support |

**Deprecated/outdated:**
- **Custom GDPR consent forms:** Google UMP SDK is now mandatory for AdMob. Custom forms violate terms and cause rejection.
- **Skipping ATT for "just analytics" apps:** Apple's privacy audit tools now flag any IDFA access without ATT prompt, even if not used for ads.
- **Test ad unit IDs in production:** Google now tracks "test ads in production" as policy violation. Automated detection may suspend AdMob accounts.

## Open Questions

1. **Google AdMob Tracking Domains for PrivacyInfo.xcprivacy**
   - What we know: NSPrivacyTrackingDomains must list domains app connects to for tracking when NSPrivacyTracking is true
   - What's unclear: Google has not published official list of AdMob tracking domains for iOS Privacy Manifest
   - Recommendation: Set `NSPrivacyTracking: false` initially (personalized ads use ATT, not cross-app tracking). Monitor for App Store rejection feedback. If rejection occurs, research AdMob domain list or contact Google support. User decision already sets NSPrivacyTracking true, so must identify domains.
   - **Action:** Research AdMob SDK network traffic with Charles Proxy on test device, extract domain list empirically. Common domains likely include: `googleads.g.doubleclick.net`, `pagead2.googlesyndication.com`, `www.googleadservices.com`

2. **Pro Subscriber Downgrade Consent Timing**
   - What we know: User decision states "If pro user downgrades → trigger consent flow before ads start appearing"
   - What's unclear: When exactly does downgrade trigger? Immediately after cancellation, or at subscription expiry?
   - Recommendation: Trigger consent flow at subscription expiry (when `SubscriptionClient.currentEntitlement` changes to nil). Don't block user during grace period.

3. **UMP Retry Timing After Failure**
   - What we know: User decision states "Failed UMP attempts retried on next app launch"
   - What's unclear: Should retry be delayed (e.g., 24 hours), or every launch?
   - Recommendation: Retry every launch. UMP SDK handles request throttling internally. No custom delay needed.

## Sources

### Primary (HIGH confidence)

- [App Tracking Transparency | Apple Developer Documentation](https://developer.apple.com/documentation/apptrackingtransparency) - Official ATT framework documentation
- [Set up UMP SDK | iOS | Google for Developers](https://developers.google.com/admob/ios/privacy) - Official UMP SDK integration guide
- [Enable test ads | iOS | Google for Developers](https://developers.google.com/admob/ios/test-ads) - Official test ad unit ID guidance
- [GitHub - pointfreeco/swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) - Official snapshot testing library
- [Adding a build configuration file to your project | Apple Developer Documentation](https://developer.apple.com/documentation/xcode/adding-a-build-configuration-file-to-your-project) - Official xcconfig documentation

### Secondary (MEDIUM confidence)

- [Mastering IDFA Opt-In Rates: The Complete AppTrackingTransparency Guide](https://www.playwire.com/blog/mastering-idfa-opt-in-rates-the-complete-apptrackingtransparency-guide-for-ios-apps) - Pre-prompt best practices
- [ATT Opt-In Rates In 2025 (And How To Increase Them)](https://www.purchasely.com/blog/att-opt-in-rates-in-2025-and-how-to-increase-them) - Current opt-in rate benchmarks
- [Optimal Integration Flow for AdMob, UMP, and GDPR Compliance](https://groups.google.com/g/google-admob-ads-sdk/c/8zKsWNXFppE) - Community-verified UMP → ATT order
- [Configure Analytics data collection and usage | Google Analytics for Firebase](https://firebase.google.com/docs/analytics/ios/configure-data-collection) - Firebase consent management
- [Xcode configuration for multiple environments](https://felginep.github.io/2021-01-21/xcode-configuration-multiple-environments) - Xcconfig patterns

### Tertiary (LOW confidence)

- [iOS Privacy Menifest / Privacy Tracking Domains](https://groups.google.com/g/google-admob-ads-sdk/c/bXq0Ex-o06w) - Community discussion on tracking domains (no official list found)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - AppTrackingTransparency, UMP SDK, and GoogleMobileAds are official Apple/Google frameworks with comprehensive documentation
- Architecture: HIGH - TCA patterns verified from official swift-composable-architecture repo, xcconfig patterns from Apple docs
- Pitfalls: HIGH - ATT opt-in rate studies cite primary research, UMP coordination verified in Google forums, production ID replacement is documented best practice

**Research date:** 2026-04-01
**Valid until:** 60 days (ATT/UMP are stable APIs; main risk is AdMob policy changes)
