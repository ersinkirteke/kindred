# Roadmap: Kindred

## Milestones

- ✅ **v1.5 Backend & AI Pipeline** — Phases 1-3 (shipped 2026-03-01)
- ✅ **v2.0 iOS App** — Phases 4-11 (shipped 2026-03-11)
- ✅ **v3.0 Smart Pantry** — Phases 12-17 (shipped 2026-03-29)
- ✅ **v4.0 App Store Launch Prep** — Phases 18-22 (shipped 2026-04-03)
- ✅ **v5.0 Lean App Store Launch** — Phases 23-28 (shipped 2026-04-12)

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

<details>
<summary>✅ v4.0 App Store Launch Prep (Phases 18-22) — SHIPPED 2026-04-03</summary>

- [x] Phase 18: Privacy Compliance & Consent (4/4 plans) — Voice consent, privacy manifest, nutrition labels, privacy policy
- [x] Phase 19: Backend Production Hardening (4/4 plans) — JWS verification, rate limiting, narration URL resolver, push delivery
- [x] Phase 20: ATT Consent & Production Ads (4/4 plans) — ATT flow, UMP SDK, production AdMob IDs, consent testing
- [x] Phase 21: Voice Playback & Monetization Integration (4/4 plans) — R2 CDN audio, paywall wiring, navigation, SwiftData fix
- [x] Phase 22: TestFlight Beta & Submission Prep (3/3 plans) — Fastlane, metadata, screenshots, beta testing

**Total:** 5 phases, 19 plans, 20/20 requirements satisfied
**Archive:** `.planning/milestones/v4.0-ROADMAP.md`

</details>

<details>
<summary>✅ v5.0 Lean App Store Launch (Phases 23-28) — SHIPPED 2026-04-12</summary>

- [x] Phase 23: Spoonacular Backend Integration (4/4 plans) — REST-to-GraphQL proxy, PostgreSQL caching, batch pre-warm, scraping cleanup
- [x] Phase 26: Feed UI Migration (3/3 plans) — PopularRecipes query, PopularityBadge, cursor pagination, viralRecipes cleanup
- [x] Phase 27: App Store Compliance Updates (4/4 plans) — PrivacyInfo.xcprivacy, compliance footer, privacy policy v2.0, screenshots
- [x] Phase 27.1: Reconcile AdMob Tracker Docs (1/1 plan) — AdMob privacy manifest entries, policy v2.1, verification correction
- [x] Phase 28: Fastlane Release Automation (5/5 plans) — Preflight lane, metadata audit, release build, TestFlight bake, App Store submission
- [ ] Phase 24: AVSpeechSynthesizer Free-Tier Voice — **DEFERRED** to next milestone
- [ ] Phase 25: Voice Tier Routing — **DEFERRED** to next milestone

**Total:** 5 executed phases, 17 plans, 13/18 requirements satisfied (5 VOICE deferred)
**Deferred:** Phases 24-25 (AVSpeech free-tier voice + tier routing) carry to next milestone
**Archive:** `.planning/milestones/v5.0-ROADMAP.md`

</details>

## Progress

| Phase | Milestone | Plans | Status | Completed |
|-------|-----------|-------|--------|-----------|
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
| 18. Privacy Compliance | v4.0 | 4/4 | Complete | 2026-03-30 |
| 19. Backend Hardening | v4.0 | 4/4 | Complete | 2026-03-30 |
| 20. ATT & Ads | v4.0 | 4/4 | Complete | 2026-04-03 |
| 21. Voice & Monetization | v4.0 | 4/4 | Complete | 2026-04-03 |
| 22. TestFlight & Submission | v4.0 | 3/3 | Complete | 2026-04-03 |
| 23. Spoonacular Backend | v5.0 | 4/4 | Complete | 2026-04-04 |
| 24. AVSpeech Free-Tier | v5.0 | 0/TBD | Deferred | - |
| 25. Voice Tier Routing | v5.0 | 0/TBD | Deferred | - |
| 26. Feed UI Migration | v5.0 | 3/3 | Complete | 2026-04-06 |
| 27. App Store Compliance | v5.0 | 4/4 | Complete | 2026-04-07 |
| 27.1. AdMob Docs Reconcile | v5.0 | 1/1 | Complete | 2026-04-07 |
| 28. Fastlane Release | v5.0 | 5/5 | Complete | 2026-04-12 |

---

*Roadmap created: 2026-02-28*
*v1.5 shipped: 2026-03-01*
*v2.0 shipped: 2026-03-11*
*v3.0 shipped: 2026-03-29*
*v4.0 shipped: 2026-04-03*
*v5.0 shipped: 2026-04-12*
