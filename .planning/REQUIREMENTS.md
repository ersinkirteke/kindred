# Requirements: Kindred v4.0 App Store Launch Prep

**Defined:** 2026-03-30
**Core Value:** Hearing a loved one's voice guide you through a trending local recipe — that emotional moment is what makes Kindred irreplaceable.

## v4.0 Requirements

Requirements for App Store submission readiness. Each maps to roadmap phases.

### Privacy & Consent

- [x] **PRIV-01**: App shows ATT consent prompt with pre-prompt explanation before personalized ads
- [x] **PRIV-02**: Privacy Nutrition Labels accurately declare all data collection in App Store Connect
- [x] **PRIV-03**: PrivacyInfo.xcprivacy manifest declares tracking domains and API usage with approved reason codes
- [x] **PRIV-04**: Voice cloning consent screen shown before first voice upload naming ElevenLabs as AI provider
- [x] **PRIV-05**: Voice consent audit trail stores userId, timestamp, IP, and app version in backend
- [x] **PRIV-06**: User can delete voice profile from Settings with confirmation dialog
- [x] **PRIV-07**: Privacy Policy hosted at public URL and linked in App Store Connect

### Voice Playback

- [x] **VOICE-01**: Voice narration plays from backend R2 CDN URLs replacing TestAudioGenerator
- [x] **VOICE-02**: All GraphQL voice profile TODO markers resolved with real backend data
- [x] **VOICE-03**: Narration URL returned via GraphQL query with NarrationAudio cache lookup

### Billing & Monetization

- [x] **BILL-01**: Backend validates StoreKit 2 JWS transactions using SignedDataVerifier with x5c chain
- [x] **BILL-02**: ScanPaywallView subscribe button triggers MonetizationFeature purchase flow
- [x] **BILL-03**: Production AdMob unit IDs replace test IDs in Info.plist and AdClient.swift

### Push Notifications

- [x] **PUSH-01**: Device FCM token registered with backend via GraphQL mutation on app launch
- [x] **PUSH-02**: Backend stores FCM token per user and uses it for push notification delivery

### Navigation

- [x] **NAV-01**: Recipe suggestion carousel card tap navigates to recipe detail view

### Data Persistence

- [x] **DATA-01**: SwiftData named ModelConfiguration committed (PantryStore/GuestStore separation)

### App Store Submission

- [x] **SUBMIT-01**: App Store screenshots created for required device sizes
- [x] **SUBMIT-02**: App Store metadata written with third-party AI disclosure
- [ ] **SUBMIT-03**: TestFlight beta testing completed with internal and external testers

## Future Requirements

Deferred to post-launch. Tracked but not in current roadmap.

### Subscription Management

- **SUB-01**: App Store Server API integration for refund and subscription lifecycle events
- **SUB-02**: Staged ATT rollout with A/B testing for opt-in rate optimization

### Localization

- **LOC-01**: Localized permission strings for non-English markets
- **LOC-02**: Localized voice consent copy for Turkish

### Analytics

- **ANAL-01**: Advanced subscription analytics dashboard
- **ANAL-02**: ATT acceptance rate tracking by cohort

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Force ATT Accept | Apple views as "nagging", causes rejection under guideline 5.1.1(iv) |
| Skip StoreKit Validation | Fraud risk, subscription abuse, revenue loss |
| RevenueCat integration | @apple/app-store-server-library sufficient for v4.0 launch |
| Android parity | iOS-first strategy, Android is separate milestone |
| AI cooking video (Veo) | $4.50-9/user/month cost, 30-120s latency |
| Social features | Not core to emotional utility |
| Custom ATT-only (no UMP) | UMP already integrated, provides GDPR/CCPA coverage |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| PRIV-01 | Phase 20 | Complete |
| PRIV-02 | Phase 18 | Complete |
| PRIV-03 | Phase 18 | Complete |
| PRIV-04 | Phase 18 | Complete |
| PRIV-05 | Phase 18 | Complete |
| PRIV-06 | Phase 18 | Complete |
| PRIV-07 | Phase 18 | Complete |
| VOICE-01 | Phase 21 | Complete |
| VOICE-02 | Phase 21 | Complete |
| VOICE-03 | Phase 19 | Complete |
| BILL-01 | Phase 19 | Complete |
| BILL-02 | Phase 21 | Complete |
| BILL-03 | Phase 20 | Complete |
| PUSH-01 | Phase 19 | Complete |
| PUSH-02 | Phase 19 | Complete |
| NAV-01 | Phase 21 | Complete |
| DATA-01 | Phase 21 | Complete |
| SUBMIT-01 | Phase 22 | Complete |
| SUBMIT-02 | Phase 22 | Complete |
| SUBMIT-03 | Phase 22 | Pending |

**Coverage:**
- v4.0 requirements: 20 total
- Mapped to phases: 20
- Unmapped: 0

**Phase distribution:**
- Phase 18 (Privacy Compliance): 6 requirements (PRIV-02, PRIV-03, PRIV-04, PRIV-05, PRIV-06, PRIV-07)
- Phase 19 (Backend Hardening): 4 requirements (BILL-01, PUSH-01, PUSH-02, VOICE-03)
- Phase 20 (ATT & Ads): 2 requirements (PRIV-01, BILL-03)
- Phase 21 (Voice & Monetization): 5 requirements (VOICE-01, VOICE-02, BILL-02, NAV-01, DATA-01)
- Phase 22 (TestFlight & Submission): 3 requirements (SUBMIT-01, SUBMIT-02, SUBMIT-03)

---
*Requirements defined: 2026-03-30*
*Last updated: 2026-03-30 after roadmap creation*
