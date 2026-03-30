# Roadmap: Kindred

## Milestones

- ✅ **v1.5 Backend & AI Pipeline** — Phases 1-3 (shipped 2026-03-01)
- ✅ **v2.0 iOS App** — Phases 4-11 (shipped 2026-03-11)
- ✅ **v3.0 Smart Pantry** — Phases 12-17 (shipped 2026-03-29)
- 🚧 **v4.0 App Store Launch Prep** — Phases 18-22 (in progress)

## Phases

<details>
<summary>✅ v1.5 Backend & AI Pipeline (Phases 1-3) — SHIPPED 2026-03-01</summary>

- [x] Phase 1: Foundation (5/5 plans) — Backend API, auth, scraping, image gen, push notifications
- [x] Phase 2: Feed Engine (3/3 plans) — PostGIS geospatial, velocity ranking, feed GraphQL API
- [x] Phase 3: Voice Core (3/3 plans) — ElevenLabs cloning, voice upload pipeline, narration streaming

**Total:** 3 phases, 11 plans, 20/20 requirements satisfied
**Archive:** `.planning/milestones/v1.5-ROADMAP.md`

</details>

<details>
<summary>✅ v2.0 iOS App (Phases 4-11) — SHIPPED 2026-03-11</summary>

- [x] Phase 4: Foundation & Architecture (4/4 plans) — SwiftUI + TCA, Apollo GraphQL, design system
- [x] Phase 5: Guest Browsing & Feed (4/4 plans) — Guest mode, swipe cards, location, offline
- [x] Phase 6: Dietary Filtering & Personalization (3/3 plans) — Dietary chips, Culinary DNA
- [x] Phase 7: Voice Playback & Streaming (6/6 plans) — AVPlayer, background audio, cache, step sync
- [x] Phase 8: Authentication & Onboarding (4/4 plans) — Clerk OAuth, onboarding carousel, auth gate
- [x] Phase 9: Monetization & Voice Tiers (5/5 plans) — StoreKit 2, AdMob, voice slot enforcement
- [x] Phase 10: Accessibility & Polish (7/7 plans) — WCAG AAA, VoiceOver, Dynamic Type, localization
- [x] Phase 11: Auth Gap Closure (2/2 plans) — Onboarding wiring, guest migration verification

**Total:** 8 phases, 35 plans, 33/33 requirements verified
**Archive:** `.planning/milestones/v2.0-ROADMAP.md`

</details>

<details>
<summary>✅ v3.0 Smart Pantry (Phases 12-17) — SHIPPED 2026-03-29</summary>

- [x] Phase 12: Pantry Infrastructure (3/3 plans) — Backend GraphQL pantry API, ingredient normalization, PantryFeature SPM package
- [x] Phase 13: Manual Pantry Management (3/3 plans) — Local-first SwiftData CRUD, offline-first sync, storage categorization
- [x] Phase 14: Camera Capture (3/3 plans) — Progressive permission, AVCaptureSession, R2 upload, Pro paywall gate
- [x] Phase 15: AI Scanning (3/3 plans) — Gemini 2.0 Flash fridge scanning, VisionKit receipt OCR, Pro paywall
- [x] Phase 16: Recipe Matching (2/2 plans) — Match % badges on feed cards, shopping list generation
- [x] Phase 17: Expiry Tracking (3/3 plans) — AI expiry estimation, push notifications, visual indicators

**Total:** 6 phases, 17 plans, 26/26 requirements satisfied
**Archive:** `.planning/milestones/v3.0-ROADMAP.md`

</details>

<details open>
<summary>🚧 v4.0 App Store Launch Prep (Phases 18-22) — IN PROGRESS</summary>

- [x] **Phase 18: Privacy Compliance & Consent Infrastructure** - Privacy policy, nutrition labels, voice consent, privacy manifest (gap closure in progress) (completed 2026-03-30)
- [ ] **Phase 19: Backend Production Hardening** - JWS verification, device token API, narration URL resolver
- [ ] **Phase 20: ATT Consent & Production Ads** - ATT flow, production AdMob unit IDs, pre-prompt screen
- [ ] **Phase 21: Voice Playback & Monetization Integration** - R2 URLs wiring, paywall triggering, navigation, SwiftData fix
- [ ] **Phase 22: TestFlight Beta & Submission Prep** - Screenshots, metadata, beta testing, final validation

</details>

## Phase Details

<details open>
<summary><strong>v4.0 App Store Launch Prep (Phases 18-22)</strong></summary>

### Phase 18: Privacy Compliance & Consent Infrastructure
**Goal**: App meets all privacy disclosure and consent requirements for App Store submission

**Depends on**: Nothing (foundational compliance work)

**Requirements**: PRIV-02, PRIV-03, PRIV-04, PRIV-05, PRIV-06, PRIV-07

**Success Criteria** (what must be TRUE):
1. User sees clear voice cloning consent screen before first voice upload naming ElevenLabs as AI provider
2. User can delete their voice profile from Settings with confirmation dialog
3. Privacy Policy is publicly accessible and linked in app Settings and App Store Connect
4. Privacy Nutrition Labels accurately declare all data collection across 14 categories (AdMob, ElevenLabs, Firebase, Mapbox, Clerk)
5. PrivacyInfo.xcprivacy manifest exists declaring tracking domains and API usage with approved reason codes

**Plans**: 4 plans

Plans:
- [x] 18-01-PLAN.md — Voice consent modal + backend audit trail (PRIV-04, PRIV-05)
- [x] 18-02-PLAN.md — PrivacyInfo.xcprivacy manifest + nutrition labels checklist (PRIV-02, PRIV-03)
- [x] 18-03-PLAN.md — Voice profile deletion in Settings + hosted privacy policy (PRIV-06, PRIV-07)
- [ ] 18-04-PLAN.md — Gap closure: iOS appVersion in voice upload form data (PRIV-05)

---

### Phase 19: Backend Production Hardening
**Goal**: Backend is production-ready with fraud prevention and push notification delivery

**Depends on**: Nothing (parallel to Phase 18, backend work)

**Requirements**: BILL-01, PUSH-01, PUSH-02, VOICE-03

**Success Criteria** (what must be TRUE):
1. Backend validates StoreKit 2 JWS transactions using SignedDataVerifier with x5c certificate chain verification
2. Device FCM tokens are registered with backend via GraphQL mutation on app launch
3. Backend stores device tokens per user and can deliver push notifications to registered devices
4. Narration URL GraphQL query returns Cloudflare R2 CDN URLs from NarrationAudio cache lookup

**Plans**: 4 plans

Plans:
- [ ] 19-01-PLAN.md -- Prisma schema (TransactionHistory, NotificationPreferences, NotificationLog, NarrationAudio.durationMs), error codes, request ID interceptor, ThrottlerModule named contexts
- [ ] 19-02-PLAN.md -- StoreKit 2 JWS verification with SignedDataVerifier, ClerkAuthGuard on SubscriptionResolver, Apple Server Notifications V2 webhook (BILL-01)
- [ ] 19-03-PLAN.md -- Push notification preference checks, engagement notification scheduler, notification preferences GraphQL resolver (PUSH-01, PUSH-02)
- [ ] 19-04-PLAN.md -- narrationUrl GraphQL query, MP3 duration computation, hash-based R2 keys, cascade delete (VOICE-03)

---

### Phase 20: ATT Consent & Production Ads
**Goal**: Users can opt into personalized ads through compliant ATT consent flow

**Depends on**: Phase 18 (Privacy Manifest, NSUserTrackingUsageDescription)

**Requirements**: PRIV-01, BILL-03

**Success Criteria** (what must be TRUE):
1. User sees pre-prompt explanation screen before ATT system dialog explaining ad personalization benefits
2. App coordinates UMP consent (GDPR/CCPA) before requesting ATT authorization
3. Production AdMob unit IDs are active in Info.plist and AdClient.swift (test IDs removed)
4. AdMob initializes with correct consent status showing personalized or non-personalized ads

**Plans**: TBD

---

### Phase 21: Voice Playback & Monetization Integration
**Goal**: Voice narration plays from production URLs and all monetization paths are connected

**Depends on**: Phase 19 (backend narration URL resolver)

**Requirements**: VOICE-01, VOICE-02, BILL-02, NAV-01, DATA-01

**Success Criteria** (what must be TRUE):
1. Voice playback streams audio from backend R2 CDN URLs (TestAudioGenerator removed)
2. All GraphQL voice profile TODO markers are resolved with real backend data
3. User tapping "Subscribe" in ScanPaywallView triggers MonetizationFeature purchase flow
4. User tapping recipe suggestion carousel card navigates to recipe detail view
5. SwiftData uses named ModelConfiguration committed with PantryStore/GuestStore separation

**Plans**: TBD

---

### Phase 22: TestFlight Beta & Submission Prep
**Goal**: App is tested, validated, and ready for App Store submission

**Depends on**: Phases 18-21 (all features complete)

**Requirements**: SUBMIT-01, SUBMIT-02, SUBMIT-03

**Success Criteria** (what must be TRUE):
1. App Store screenshots created for required device sizes (6.9" iPhone 1320x2868px, 13" iPad 2064x2752px)
2. App Store metadata completed with third-party AI disclosure and privacy labels validated
3. TestFlight internal testing completed with 5-10 testers (1 week minimum)
4. TestFlight external testing completed with 50-100 beta testers (1-2 weeks minimum)
5. All critical bugs from beta feedback are resolved with no known crashers or blockers

**Plans**: TBD

</details>

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation | v1.5 | 5/5 | Complete | 2026-02-28 |
| 2. Feed Engine | v1.5 | 3/3 | Complete | 2026-03-01 |
| 3. Voice Core | v1.5 | 3/3 | Complete | 2026-03-01 |
| 4. Foundation & Architecture | v2.0 | 4/4 | Complete | 2026-03-01 |
| 5. Guest Browsing & Feed | v2.0 | 4/4 | Complete | 2026-03-02 |
| 6. Dietary Filtering | v2.0 | 3/3 | Complete | 2026-03-03 |
| 7. Voice Playback | v2.0 | 6/6 | Complete | 2026-03-03 |
| 8. Authentication | v2.0 | 4/4 | Complete | 2026-03-06 |
| 9. Monetization | v2.0 | 5/5 | Complete | 2026-03-08 |
| 10. Accessibility | v2.0 | 7/7 | Complete | 2026-03-08 |
| 11. Auth Gap Closure | v2.0 | 2/2 | Complete | 2026-03-09 |
| 12. Pantry Infrastructure | v3.0 | 3/3 | Complete | 2026-03-11 |
| 13. Manual Pantry Management | v3.0 | 3/3 | Complete | 2026-03-12 |
| 14. Camera Capture | v3.0 | 3/3 | Complete | 2026-03-13 |
| 15. AI Scanning | v3.0 | 3/3 | Complete | 2026-03-15 |
| 16. Recipe Matching | v3.0 | 2/2 | Complete | 2026-03-16 |
| 17. Expiry Tracking | v3.0 | 3/3 | Complete | 2026-03-17 |
| 18. Privacy Compliance | 4/4 | Complete    | 2026-03-30 | - |
| 19. Backend Hardening | v4.0 | 0/4 | Not started | - |
| 20. ATT & Ads | v4.0 | 0/TBD | Not started | - |
| 21. Voice & Monetization | v4.0 | 0/TBD | Not started | - |
| 22. TestFlight & Submission | v4.0 | 0/TBD | Not started | - |

---

*Roadmap created: 2026-02-28*
*v1.5 shipped: 2026-03-01*
*v2.0 shipped: 2026-03-11*
*v3.0 shipped: 2026-03-29*
*v4.0 started: 2026-03-30*
