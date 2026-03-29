# Requirements: Kindred v4.0 App Store Launch Prep

**Defined:** 2026-03-30
**Core Value:** Hearing a loved one's voice guide you through a trending local recipe — that emotional moment is what makes Kindred irreplaceable.

## v4.0 Requirements

Requirements for App Store submission readiness. Each maps to roadmap phases.

### Privacy & Consent

- [ ] **PRIV-01**: App shows ATT consent prompt with pre-prompt explanation before personalized ads
- [ ] **PRIV-02**: Privacy Nutrition Labels accurately declare all data collection in App Store Connect
- [ ] **PRIV-03**: PrivacyInfo.xcprivacy manifest declares tracking domains and API usage with approved reason codes
- [ ] **PRIV-04**: Voice cloning consent screen shown before first voice upload naming ElevenLabs as AI provider
- [ ] **PRIV-05**: Voice consent audit trail stores userId, timestamp, IP, and app version in backend
- [ ] **PRIV-06**: User can delete voice profile from Settings with confirmation dialog
- [ ] **PRIV-07**: Privacy Policy hosted at public URL and linked in App Store Connect

### Voice Playback

- [ ] **VOICE-01**: Voice narration plays from backend R2 CDN URLs replacing TestAudioGenerator
- [ ] **VOICE-02**: All GraphQL voice profile TODO markers resolved with real backend data
- [ ] **VOICE-03**: Narration URL returned via GraphQL query with NarrationAudio cache lookup

### Billing & Monetization

- [ ] **BILL-01**: Backend validates StoreKit 2 JWS transactions using SignedDataVerifier with x5c chain
- [ ] **BILL-02**: ScanPaywallView subscribe button triggers MonetizationFeature purchase flow
- [ ] **BILL-03**: Production AdMob unit IDs replace test IDs in Info.plist and AdClient.swift

### Push Notifications

- [ ] **PUSH-01**: Device FCM token registered with backend via GraphQL mutation on app launch
- [ ] **PUSH-02**: Backend stores FCM token per user and uses it for push notification delivery

### Navigation

- [ ] **NAV-01**: Recipe suggestion carousel card tap navigates to recipe detail view

### Data Persistence

- [ ] **DATA-01**: SwiftData named ModelConfiguration committed (PantryStore/GuestStore separation)

### App Store Submission

- [ ] **SUBMIT-01**: App Store screenshots created for required device sizes
- [ ] **SUBMIT-02**: App Store metadata written with third-party AI disclosure
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
| PRIV-01 | — | Pending |
| PRIV-02 | — | Pending |
| PRIV-03 | — | Pending |
| PRIV-04 | — | Pending |
| PRIV-05 | — | Pending |
| PRIV-06 | — | Pending |
| PRIV-07 | — | Pending |
| VOICE-01 | — | Pending |
| VOICE-02 | — | Pending |
| VOICE-03 | — | Pending |
| BILL-01 | — | Pending |
| BILL-02 | — | Pending |
| BILL-03 | — | Pending |
| PUSH-01 | — | Pending |
| PUSH-02 | — | Pending |
| NAV-01 | — | Pending |
| DATA-01 | — | Pending |
| SUBMIT-01 | — | Pending |
| SUBMIT-02 | — | Pending |
| SUBMIT-03 | — | Pending |

**Coverage:**
- v4.0 requirements: 19 total
- Mapped to phases: 0
- Unmapped: 19 (pending roadmap creation)

---
*Requirements defined: 2026-03-30*
*Last updated: 2026-03-30 after initial definition*
