# Feature Research: App Store Launch Readiness

**Domain:** iOS App Store Submission & Production Deployment
**Researched:** 2026-03-30
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = App Store rejection or production incidents.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Privacy Policy URL | App Store guideline 5.1.1 requirement | LOW | Must be accessible in-app and in App Store Connect metadata |
| Privacy Nutrition Labels | iOS 14.3+ requirement, mandatory since 2020 | MEDIUM | 14 data categories to declare: contact info, health, financial, location, sensitive info, contacts, user content, browsing history, search history, identifiers, purchases, usage data, diagnostics, other |
| ATT Consent Flow (for AdMob) | Required before tracking for ads | MEDIUM | Pre-prompt explanation + system dialog. One chance only - no re-prompts allowed |
| NSUserTrackingUsageDescription | Required for ATT prompt | LOW | Info.plist key with 8th-grade reading level explanation |
| NSMicrophoneUsageDescription | Required for voice recording | LOW | Info.plist key explaining why app needs microphone access |
| Production AdMob Unit IDs | Test IDs cause invalid traffic flags | LOW | Replace test IDs before submission to avoid account suspension |
| StoreKit 2 JWS Verification | Server-side receipt validation | HIGH | Verify x5c certificate chain against Apple's root/intermediate certs |
| App Store Screenshots | 6.9" iPhone + 13" iPad mandatory | MEDIUM | 1320x2868px iPhone, 2064x2752px iPad. PNG/JPEG, max 10 per locale |
| TestFlight Beta Testing | Pre-submission bug discovery | MEDIUM | Internal testers (instant), external testers (24-48hr review). Builds expire after 90 days |
| Distribution Certificate & Profile | Code signing for App Store | MEDIUM | Valid for 1 year. Must match App ID and bundle identifier |
| Push Notification Token → Backend | Device token must reach backend for delivery | MEDIUM | APNs token → FCM token → backend storage. Currently missing in EXPIRY-02 |
| Voice Cloning Consent (Legal) | ELVIS Act (TN), AB 1836 (CA), NY Right of Publicity | HIGH | Explicit written consent required. Must be revocable, scope-specific, documented |
| Voice Cloning Consent (UI) | User trust & App Store AI guidelines 5.1.2(i) | HIGH | Explain data sharing before upload, show terms, get explicit opt-in |
| Demo Account (if login required) | App Review needs testable account | LOW | Provide in App Review Information if auth is mandatory |

### Differentiators (Competitive Advantage)

Features that set production-ready apps apart. Not required, but increase trust and reduce rejection risk.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Pre-ATT Value Demonstration | 2-3x higher opt-in rates | LOW | Show "first win" before ATT prompt. Delay until user experiences benefit |
| Custom Pre-Prompt Screen | Explain "why" in friendly language | LOW | "Help us keep the app free and relevant" before system dialog |
| Localized Permission Strings | Builds trust in non-English markets | LOW | NSUserTrackingUsageDescription and NSMicrophoneUsageDescription in all supported languages |
| Voice Data Deletion Button | User control increases trust | LOW | "Delete Voice Data" in Settings, with confirmation dialog |
| Transparent Voice Usage Policy | Reduces legal risk | MEDIUM | Plain-English explanation: what's collected, how long stored, who accesses, how to revoke |
| Transaction.currentEntitlements | Real-time subscription validation | MEDIUM | StoreKit 2 API for instant entitlement checks without server round-trip |
| App Store Server API Integration | Robust subscription status | HIGH | JWT-authenticated queries for subscription status, refunds, renewals |
| TestFlight Feedback Channel | Faster bug discovery | LOW | Discord/Slack channel for real-time beta feedback vs formal reports |
| Privacy Manifest (PrivacyInfo.xcprivacy) | Proactive compliance | MEDIUM | Declares API usage with approved reason codes. Prevents 2026 rejections |
| Staged ATT Rollout | Measure impact before full launch | MEDIUM | Show ATT to 10-20% of users, measure retention/revenue before expanding |
| Voice Consent Audit Trail | Legal protection | HIGH | Log consent timestamp, IP, terms version, voice file hash |
| AdMob Test Device Configuration | Safer pre-launch testing | LOW | Configure device IDs for test ads with production unit IDs |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems during App Store submission.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Force ATT Accept | Maximize ad revenue | Apple views as "nagging", causes rejection under guideline 5.1.1(iv) | Pre-prompt explanation with balanced UI, accept one-time "no" |
| Skip StoreKit Validation | Faster implementation | Fraud risk, subscription abuse, revenue loss | Use on-device JWS validation + server-side App Store Server API |
| Vague Privacy Labels | Minimize user concern | Causes rejection under guideline 5.1.2 | Accurate disclosure. Under-reporting worse than transparency |
| Hidden Subscription Terms | Reduce friction | Rejection under guideline 3.1.2. Pricing/billing must be visible without scrolling | Upfront pricing card with clear terms |
| ATT Prompt at Launch | Get consent early | Lowest opt-in rates (10-20%), poor UX | Delay until after "first win" moment |
| Base64url JWS Only | MVP simplicity | Production fraud risk. No x5c verification means fake receipts accepted | Full x5c chain validation with Apple root certs |
| Test AdMob IDs in Production | "Just launch quickly" | Account flagged for invalid traffic, permanent suspension risk | Always use production unit IDs. Use test device IDs instead |
| Single Screenshot Size | Minimize design work | Rejection. 6.9" iPhone + 13" iPad mandatory since 2024 | Design once at 1320x2868px, scale down for other sizes |
| Implicit Voice Consent | Reduce onboarding friction | Legal liability (ELVIS Act, AB 1836), App Store rejection under 5.1.2(i) | Explicit consent screen with terms, checkbox, recordkeeping |
| ElevenLabs Free Plan for Production | Cost savings | Cannot use commercially, must attribute. Violates ToS | Paid plan required for commercial use and ownership rights |

## Feature Dependencies

```
Privacy Policy URL (written)
    └──requires──> Privacy Nutrition Labels (App Store Connect questionnaire)
                       └──requires──> Third-Party SDK Audit (know what data is collected)

ATT Consent Flow
    └──requires──> NSUserTrackingUsageDescription (Info.plist)
    └──requires──> Pre-Prompt Screen (optional but recommended)
    └──requires──> Privacy Nutrition Labels (must declare tracking)

AdMob Production Ads
    └──requires──> ATT Consent Flow (if tracking users)
    └──requires──> Production Unit IDs (replace test IDs)
    └──requires──> Test Device Configuration (for safe pre-launch testing)

Voice Cloning Feature
    └──requires──> NSMicrophoneUsageDescription (Info.plist)
    └──requires──> Voice Cloning Consent UI (legal compliance)
    └──requires──> Voice Usage Policy (user transparency)
    └──requires──> ElevenLabs Paid Plan (commercial use rights)
    └──requires──> Consent Audit Trail (legal protection)

StoreKit 2 Production Billing
    └──requires──> JWS Verification (x5c chain validation)
    └──requires──> App Store Server API (subscription status)
    └──requires──> Transaction.currentEntitlements (real-time checks)

Push Notifications
    └──requires──> APNs Device Token (iOS system)
    └──requires──> FCM Token Mapping (cross-platform)
    └──requires──> Backend Token Storage (delivery pipeline)
    └──requires──> Backend → FCM API Integration (send notifications)

App Store Submission
    └──requires──> TestFlight Beta Testing (catch bugs first)
    └──requires──> Screenshots (6.9" iPhone + 13" iPad)
    └──requires──> Demo Account (if login required)
    └──requires──> Distribution Certificate (code signing)
    └──requires──> Privacy Manifest (PrivacyInfo.xcprivacy for 2026 compliance)
```

### Dependency Notes

- **ATT Consent Flow requires Pre-Prompt Screen:** While technically optional, pre-prompt screens increase opt-in rates by 2-3x. Showing value first is the difference between 10-20% opt-in (immediate prompt) and 30-60% opt-in (delayed prompt).
- **Voice Cloning requires ElevenLabs Paid Plan:** Free plan users cannot use outputs commercially and must attribute ElevenLabs. This violates the product's core value proposition.
- **StoreKit 2 Production requires x5c Verification:** Current base64url decoding without x5c chain validation is MVP-only. Production fraud risk is unacceptable.
- **Push Notifications require Backend Integration:** EXPIRY-02 registers device token locally but doesn't send to backend. Without backend storage, no notifications can be delivered.
- **Privacy Manifest required for 2026:** Failing to declare API usage (file timestamps, user defaults, disk space, etc.) with approved reason codes is a common 2026 rejection cause.

## MVP Definition

### Launch With (v4.0 App Store Launch Prep)

Minimum viable submission package — what's needed to pass App Store Review.

- [x] Privacy Policy URL — [Essential: guideline 5.1.1 requirement]
- [x] Privacy Nutrition Labels — [Essential: declare all data collection for AdMob, Clerk, ElevenLabs, Firebase]
- [x] ATT Consent Flow — [Essential: NSUserTrackingUsageDescription + pre-prompt + system dialog]
- [x] Production AdMob Unit IDs — [Essential: replace test IDs to avoid account suspension]
- [x] NSMicrophoneUsageDescription — [Essential: required for voice upload feature]
- [x] Voice Cloning Consent UI — [Essential: legal compliance (ELVIS Act, AB 1836) + Apple 5.1.2(i)]
- [x] Voice Usage Policy — [Essential: transparency for data sharing with ElevenLabs]
- [x] Push Notification Backend Integration — [Essential: device token → backend for expiry alerts]
- [x] StoreKit 2 JWS x5c Verification — [Essential: production fraud protection]
- [x] App Store Screenshots — [Essential: 6.9" iPhone + 13" iPad mandatory]
- [x] TestFlight Beta Testing — [Essential: catch crashes/bugs before submission]
- [x] Distribution Certificate & Profile — [Essential: code signing for App Store]
- [x] Demo Account — [Essential: if auth is required for app review]
- [x] Privacy Manifest — [Essential: 2026 compliance for API usage declaration]

### Add After Validation (v4.x)

Features to add once core submission is approved and app is live.

- [ ] App Store Server API Integration — [Trigger: subscription abuse or refund issues detected]
- [ ] Transaction.currentEntitlements — [Trigger: entitlement check latency issues]
- [ ] Voice Consent Audit Trail — [Trigger: legal consultation or compliance audit]
- [ ] Staged ATT Rollout — [Trigger: measure impact on retention/revenue]
- [ ] TestFlight Feedback Channel — [Trigger: beta tester engagement is low]
- [ ] Localized Permission Strings — [Trigger: expanding to non-English markets]
- [ ] Voice Data Deletion Button — [Trigger: user requests or GDPR compliance needed]

### Future Consideration (v5+)

Features to defer until App Store presence is established.

- [ ] Advanced Subscription Analytics — [Why defer: not needed until scaling]
- [ ] Multi-Region Privacy Compliance — [Why defer: focus on US launch first]
- [ ] Automated Certificate Renewal — [Why defer: manual renewal sufficient for MVP]

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Privacy Policy URL | HIGH | LOW | P1 |
| Privacy Nutrition Labels | HIGH | MEDIUM | P1 |
| ATT Consent Flow | HIGH | MEDIUM | P1 |
| Production AdMob Unit IDs | HIGH | LOW | P1 |
| Voice Cloning Consent UI | HIGH | HIGH | P1 |
| Push Notification Backend | HIGH | MEDIUM | P1 |
| StoreKit 2 x5c Verification | HIGH | HIGH | P1 |
| App Store Screenshots | HIGH | MEDIUM | P1 |
| TestFlight Beta Testing | HIGH | MEDIUM | P1 |
| Distribution Certificate | HIGH | MEDIUM | P1 |
| Privacy Manifest | HIGH | MEDIUM | P1 |
| Pre-Prompt Value Demo | MEDIUM | LOW | P2 |
| Custom Pre-Prompt Screen | MEDIUM | LOW | P2 |
| Voice Usage Policy | HIGH | MEDIUM | P2 |
| App Store Server API | MEDIUM | HIGH | P2 |
| Transaction.currentEntitlements | MEDIUM | MEDIUM | P2 |
| Voice Consent Audit Trail | MEDIUM | HIGH | P3 |
| TestFlight Feedback Channel | LOW | LOW | P3 |
| Localized Permission Strings | MEDIUM | LOW | P3 |
| Voice Data Deletion Button | MEDIUM | LOW | P3 |
| Staged ATT Rollout | LOW | MEDIUM | P3 |

**Priority key:**
- P1: Must have for launch (blocks App Store submission or creates legal/fraud risk)
- P2: Should have when possible (improves trust, reduces risk, but not blocking)
- P3: Nice to have, future consideration (optimization or expansion features)

## Competitor Feature Analysis

| Feature | Recipe Apps (Yummly, Tasty) | Voice Apps (Voice.ai, Speechify) | Our Approach |
|---------|----------------------------|-----------------------------------|--------------|
| ATT Consent | Pre-prompt with "personalized recommendations" value prop | Pre-prompt with "improve voice accuracy" value prop | Pre-prompt with "keep app free and relevant" tied to recipe discovery |
| Privacy Labels | Tracking (identifiers, usage data), linked to user | Voice recordings (user content, audio data), linked to user | Tracking (AdMob), voice (ElevenLabs), location (Mapbox), identifiers (Clerk), purchases (StoreKit) |
| Voice Consent | N/A (no voice cloning) | Explicit consent screen with ToS checkbox, "I own this voice or have permission" | Explicit consent screen with ELVIS Act disclosure, ElevenLabs ToS, revocation instructions |
| Billing Validation | StoreKit 1 legacy receipt validation | StoreKit 2 with server-side App Store Server API | StoreKit 2 client-side + x5c verification (MVP), Server API (v4.x) |
| Screenshots | 10 screenshots showing recipe browsing, filtering, cooking steps | 5-6 screenshots showing voice samples, playback, settings | 8-10 screenshots showing feed, voice playback, pantry, personalization |
| TestFlight | Internal testing only, short cycles | External beta with 1000+ testers, long cycles | Internal testing (catch obvious bugs), external beta (50-100 testers, 1-2 weeks) |
| Push Notifications | Recipe suggestions, new content | Voice processing complete, weekly summaries | Expiry alerts (critical), engagement nudges (optional) |

## Known Gaps in Current Implementation

### Critical (Blocks App Store Submission)

1. **Privacy Policy URL:** Not written or hosted yet
2. **Privacy Nutrition Labels:** Not filled in App Store Connect (need to declare AdMob tracking, ElevenLabs voice data, Clerk identifiers, location data)
3. **ATT Consent Flow:** Not implemented (NSUserTrackingUsageDescription missing, no pre-prompt, no system dialog call)
4. **Production AdMob Unit IDs:** Still using test IDs in AdClient.swift
5. **NSMicrophoneUsageDescription:** Missing or placeholder in Info.plist
6. **Voice Cloning Consent UI:** Not implemented (no consent screen, no ToS link, no legal disclosure)
7. **Voice Usage Policy:** Not written (no explanation of ElevenLabs data sharing)
8. **StoreKit 2 x5c Verification:** Using base64url decoding only (backend/src/billing/jws.ts)
9. **App Store Screenshots:** Not created (6.9" iPhone + 13" iPad mandatory)
10. **Distribution Certificate:** May need renewal (check expiration)
11. **Privacy Manifest:** PrivacyInfo.xcprivacy not created (2026 requirement)

### High Priority (Reduces Risk)

12. **Push Notification Backend Integration:** Device token registered locally (EXPIRY-02) but not sent to backend
13. **TestFlight Beta Testing:** Not set up yet (need internal testers first)
14. **Demo Account:** Not created for App Review testing
15. **Voice Consent Audit Trail:** No logging of consent events

### Medium Priority (Improves UX)

16. **Pre-Prompt Value Demonstration:** ATT prompt timing not optimized
17. **Custom Pre-Prompt Screen:** No explanation before system ATT dialog
18. **Voice Data Deletion Button:** Not implemented in Settings

## Sources

### App Store Guidelines & Submission
- [App Review Guidelines - Apple Developer](https://developer.apple.com/app-store/review/guidelines/)
- [iOS App Store Review Guidelines 2026: Requirements, Rejections & Submission Guide](https://theapplaunchpad.com/blog/app-store-review-guidelines)
- [App Store Requirements: iOS & Android Submission Guide 2026](https://natively.dev/articles/app-store-requirements)
- [User Privacy and Data Use - App Store - Apple Developer](https://developer.apple.com/app-store/user-privacy-and-data-use/)
- [Submitting - App Store - Apple Developer](https://developer.apple.com/app-store/submitting/)

### Privacy & ATT
- [Mobile App Consent for iOS: A Deep Dive (2025)](https://secureprivacy.ai/blog/mobile-app-consent-ios-2025)
- [App Tracking Transparency (ATT): Apple's User Privacy Framework](https://adapty.io/blog/app-tracking-transparency/)
- [Opt-in design do's and don'ts for Apple's App Tracking Transparency | Adjust](https://www.adjust.com/blog/opt-in-design-for-apple-app-tracking-transparency-att-ios14/)
- [Best practices: iOS tracking message – Sourcepoint](https://docs.sourcepoint.com/hc/en-us/articles/4401990990355-Best-practices-iOS-tracking-message)
- [App Privacy Details - App Store - Apple Developer](https://developer.apple.com/app-store/app-privacy-details/)
- [Privacy - Labels - Apple](https://www.apple.com/privacy/labels/)

### Voice Cloning & AI Consent
- [Synthetic Media & Voice Cloning: Right of Publicity Risks for 2026](https://holonlaw.com/entertainment-law/synthetic-media-voice-cloning-and-the-new-right-of-publicity-risk-map-for-2026/)
- [Is Voice Cloning Legal? State-by-State Guide (2026 Update)](https://www.soundverse.ai/blog/article/is-voice-cloning-legal-state-by-state-guide-1041)
- [ElevenLabs Voice Cloning Consent Policy 2026: Legal Requirements & Commercial Use](https://terms.law/forum/thread/elevenlabs-voice-clone-legal.html)
- [Apple clamps down on third-party AI data sharing in App Store](https://www.techbuzz.ai/articles/apple-clamps-down-on-third-party-ai-data-sharing-in-app-store)
- [California's Digital Replica Law: What AI Filmmakers Need...](https://studio.aifilms.ai/blog/california-digital-replica-law-2026)

### StoreKit & Billing
- [How to validate server-side transactions with Apple's App Store Server API | Adapty](https://adapty.io/blog/validating-iap-with-app-store-server-api/)
- [How to Validate iOS and macOS In-App Purchases Using StoreKit 2 and Server-Side Swift | Medium](https://medium.com/@ronaldmannak/how-to-validate-ios-and-macos-in-app-purchases-using-storekit-2-and-server-side-swift-98626641d3ea)
- [Mastering StoreKit 2 in SwiftUI: A Complete Guide to In-App Purchases (2025) | Medium](https://medium.com/@dhruvinbhalodiya752/mastering-storekit-2-in-swiftui-a-complete-guide-to-in-app-purchases-2025-ef9241fced46)
- [currentEntitlements | Apple Developer Documentation](https://developer.apple.com/documentation/storekit/transaction/currententitlements)

### Push Notifications
- [Registering your app with APNs | Apple Developer Documentation](https://developer.apple.com/documentation/usernotifications/registering-your-app-with-apns)
- [Get started with Firebase Cloud Messaging in Apple platform apps](https://firebase.google.com/docs/cloud-messaging/ios/client)
- [Detail Guide to IOS Push Notification with Google Firebase Cloud Messaging(FCM) | Medium](https://medium.com/@itsuki.enjoy/detail-guide-to-ios-push-notification-with-google-firebase-cloud-messaging-fcm-50944e0c2c45)

### AdMob
- [Enable test ads | iOS | Google for Developers](https://developers.google.com/admob/ios/test-ads)
- [Add test AdMob app ID and ad unit IDs | GitHub Gist](https://gist.github.com/prakashpun/d19e34c5710f8b7f40f828c7df3e887c)

### Screenshots & Metadata
- [Screenshot specifications - Apple Developer](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
- [Apple App Store screenshot sizes & guidelines (2026) | MobileAction](https://www.mobileaction.co/guide/app-screenshot-sizes-and-guidelines-for-the-app-store/)
- [App Store Screenshot Sizes 2026 Cheat Sheet | Medium](https://medium.com/@AppScreenshotStudio/app-store-screenshot-sizes-2026-cheat-sheet-iphone-16-pro-max-google-play-specs-3cb210bf0756)

### TestFlight
- [TestFlight - Apple Developer](https://developer.apple.com/testflight/)
- [TestFlight Beta Testing: The Complete Guide for iOS Developers](https://iossubmissionguide.com/testflight-beta-testing-complete-guide/)
- [iOS & iPhone App Distribution Guide 2026](https://foresightmobile.com/blog/ios-app-distribution-guide-2026)

### Code Signing & Deployment
- [A Complete Guide to iOS Deployment Certificates | Medium](https://medium.com/@soumyamishra637/a-complete-guide-to-ios-deployment-certificates-code-signing-provisioning-and-publishing-e6e1c8fcb86b)
- [iOS Code Signing, Apple Certificates and Provisioning Profiles | Appcircle](https://appcircle.io/use-cases/ios-certificates-provisioning)

### Permissions
- [NSMicrophoneUsageDescription | Apple Developer Documentation](https://developer.apple.com/documentation/BundleResources/Information-Property-List/NSMicrophoneUsageDescription)
- [Requesting authorization to capture and save media | Apple Developer](https://developer.apple.com/documentation/avfoundation/requesting-authorization-to-capture-and-save-media)
- [3 Design Considerations for Effective Mobile-App Permission Requests - NN/G](https://www.nngroup.com/articles/permission-requests/)

---
*Feature research for: iOS App Store Launch Readiness*
*Researched: 2026-03-30*
*Confidence: HIGH (based on official Apple documentation, current 2026 guidelines, and verified industry best practices)*
