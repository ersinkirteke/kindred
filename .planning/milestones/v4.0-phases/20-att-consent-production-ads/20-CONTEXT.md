# Phase 20: ATT Consent & Production Ads - Context

**Gathered:** 2026-04-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Users can opt into personalized ads through a compliant ATT consent flow. This phase delivers: a pre-prompt explanation screen before the iOS ATT system dialog, UMP consent coordination (GDPR/CCPA) before ATT authorization, production AdMob unit IDs replacing test IDs, and AdMob initialization with correct consent status for personalized or non-personalized ads.

Requirements: PRIV-01, BILL-03

</domain>

<decisions>
## Implementation Decisions

### Pre-prompt Screen
- Full-screen modal sheet presentation
- Friendly & casual tone matching Kindred's personality (e.g., "Hey! We'd like to show you ads that match your tastes")
- SF Symbol icon at top (no custom illustration)
- Single "Continue" button that always triggers the ATT system dialog — no "Not now" / skip option
- SwiftUI Preview for layout verification without triggering actual ATT

### Consent Flow Timing
- Order: UMP consent form first (region-based, only where legally required), then ATT pre-prompt, then iOS ATT system dialog
- Seamless blocking sequence — user must complete the flow before reaching the feed; UMP → pre-prompt → ATT dialog happen as one continuous step
- Triggers after onboarding completes for new users
- Existing users (already completed onboarding) see the pre-prompt on their next app launch — tracked via UserDefaults flag
- Skip the pre-prompt entirely if ATT status is already `.authorized` or `.denied` — only show for `.notDetermined`
- Deep link to iOS Settings for tracking permission added in Profile > Privacy & Data section (PrivacyDataSection.swift)
- Keep existing first-launch ad suppression (`kindredFirstLaunchComplete` flag) alongside the consent flow — belt-and-suspenders
- NSUserTrackingUsageDescription: "Kindred uses this to show you ads for kitchen tools and ingredients that match your cooking style."
- PrivacyInfo.xcprivacy updated: `NSPrivacyTracking: true`, Google tracking domains added

### Decline Behavior
- ATT denied → show non-personalized ads (AdMob supports this natively)
- UMP consent denied (GDPR/CCPA regions) → show non-personalized ads (limited ads mode)
- No visual indicator distinguishing personalized vs non-personalized ads
- Skip consent flow entirely for pro subscribers (no ads = no need for consent)
- If pro user downgrades → trigger consent flow before ads start appearing
- Explicit consent passing to AdMob — AdClient reads ATT + UMP status and configures GADMobileAds request parameters explicitly
- Check ATTrackingManager.trackingAuthorizationStatus on every app launch to pick up Settings changes
- If ATT request throws (rare edge case) → treat as `.denied`, non-personalized ads, no retry
- Disable Firebase Analytics data collection if user denies ATT tracking

### Production Ad Configuration
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

### Error Handling
- UMP form fails to load → skip consent form, fall back to non-personalized ads, don't block the user
- UMP failure does NOT skip ATT — still show ATT pre-prompt and system dialog (they're independent)
- Failed UMP attempts retried on next app launch
- Consent errors logged silently via OSLog — user sees nothing, flow degrades gracefully

### Architecture
- New `ConsentClient` TCA dependency in MonetizationFeature/Sources/Consent/ — manages UMP + ATT consent
- New `ConsentReducer` in MonetizationFeature/Sources/Consent/ — manages the UMP → ATT flow, pre-prompt sheet presentation, and consent state
- Combined `ConsentStatus` enum: `.fullyGranted`, `.attDenied`, `.umpDenied`, `.bothDenied`, `.notDetermined`
- Consent status lives in TCA shared state (app-level), updated on launch and after consent flow
- Consent state resolved before feed loads — TCA effect in root reducer fires `.checkConsentStatus` on `.onAppear`
- `AdClient.shouldShowAds` updated to integrate consent status (first-launch flag + subscription + consent = single source of truth)
- UMP consent state persistence handled by UMP SDK internally — no local caching needed
- "Has seen pre-prompt" flag stored in UserDefaults
- AppTrackingTransparency framework added as new dependency to MonetizationFeature Package.swift

### Testing & QA
- Test on physical device (iPhone 16 Pro Max) — ATT prompt only works on real devices
- ConsentClient.testValue with configurable presets: `.allGranted`, `.attDenied`, `.umpDenied`, `.notDetermined`
- Debug menu accessible via long-press on app version label in Profile screen — consent reset button only (clears UserDefaults flag so pre-prompt shows again), debug builds only
- Debug menu included in Phase 20 scope (directly supports testing consent flow)
- SwiftUI Preview for pre-prompt screen
- Snapshot test using PointFree's swift-snapshot-testing library (new dependency)
- TCA reducer tests for consent flow: UMP → ATT sequence, error fallbacks, consent state transitions
- Target: iOS 17+, no ATT compatibility concerns

### Analytics & Logging
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

</decisions>

<specifics>
## Specific Ideas

- Pre-prompt tone: "Hey! We'd like to show you ads that match your tastes" — warm, conversational, matching Kindred's cooking-app personality
- NSUserTrackingUsageDescription: "Kindred uses this to show you ads for kitchen tools and ingredients that match your cooking style."
- Consent flow should feel like one continuous step — UMP → pre-prompt → ATT with no return to app between steps
- Debug menu via long-press on version label in Profile — a common iOS pattern for hidden developer tools

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AdClient.swift` (MonetizationFeature): TCA dependency for AdMob SDK init and ad suppression logic — will be extended with consent integration
- `AdModels.swift`: AdUnitIDs struct with test IDs — will be refactored to read from xcconfig
- `AdCardView.swift` / `BannerAdView.swift`: Existing ad display views — no changes needed, just need correct consent config
- `PrivacyDataSection.swift` (ProfileFeature): Existing privacy section in Profile — add tracking settings deep link here
- `PrivacyInfo.xcprivacy`: Privacy manifest already exists with data types declared — needs NSPrivacyTracking update

### Established Patterns
- TCA dependency pattern: `AdClient` with `liveValue` / `testValue` — follow same pattern for `ConsentClient`
- First-launch suppression: `kindredFirstLaunchComplete` UserDefaults flag in AppDelegate — consent flow adds alongside this
- App-level TCA effect pattern: Root reducer `.onAppear` effects for initialization (audio session, location, ads)
- MonetizationFeature package structure: Ads/ and Subscription/ subdirectories — add Consent/ subdirectory

### Integration Points
- `AppDelegate.swift`: AdMob SDK init (line 48-50), test device config — add `#if DEBUG` guard, reference xcconfig
- `Info.plist`: `GADApplicationIdentifier` (line 49-50) — switch to `$(ADMOB_APP_ID)` variable
- `FeedReducer.swift`: `adVisibilityDetermined` action (line 735) — needs consent status input
- `OnboardingReducer.swift`: Onboarding completion — trigger consent flow after
- `PrivacyDataSection.swift`: Add tracking permission row with Settings deep link
- Root reducer / KindredApp.swift: Add consent status check on launch

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 20-att-consent-production-ads*
*Context gathered: 2026-04-01*
