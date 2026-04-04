# Roadmap: Kindred

## Milestones

- ✅ **v1.5 Backend & AI Pipeline** — Phases 1-3 (shipped 2026-03-01)
- ✅ **v2.0 iOS App** — Phases 4-11 (shipped 2026-03-11)
- ✅ **v3.0 Smart Pantry** — Phases 12-17 (shipped 2026-03-29)
- ✅ **v4.0 App Store Launch Prep** — Phases 18-22 (shipped 2026-04-03)
- 🚧 **v5.0 Lean App Store Launch** — Phases 23-28 (in progress)

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

### 🚧 v5.0 Lean App Store Launch (In Progress)

**Milestone Goal:** Replace expensive backend dependencies with free alternatives and ship to App Store at $0/month SaaS costs.

- [ ] **Phase 23: Spoonacular Backend Integration** - REST-to-GraphQL proxy with aggressive caching
- [ ] **Phase 24: AVSpeechSynthesizer Free-Tier Voice** - On-device TTS for free users
- [ ] **Phase 25: Voice Tier Routing** - Strategy pattern selecting AVSpeech vs ElevenLabs
- [ ] **Phase 26: Feed UI Migration** - Update from "viral near you" to "popular recipes"
- [ ] **Phase 27: App Store Compliance Updates** - Privacy Labels for Spoonacular + screenshots
- [ ] **Phase 28: Fastlane Release Automation** - Automate App Store submission

## Phase Details

### Phase 23: Spoonacular Backend Integration
**Goal**: Backend serves recipes from Spoonacular API with PostgreSQL caching to stay under 150 req/day quota
**Depends on**: Phase 22
**Requirements**: RECIPE-01, RECIPE-02, RECIPE-03, RECIPE-06, CACHE-01, CACHE-02, CACHE-03, CACHE-04
**Success Criteria** (what must be TRUE):
  1. User can search recipes by keyword and see results from Spoonacular API
  2. User can filter recipes by cuisine, diet type, and intolerances
  3. Recipe cards display high-quality images from Spoonacular CDN
  4. Recipe detail view shows "Powered by Spoonacular" attribution with clickable link
  5. Backend caches all Spoonacular responses with 6-hour TTL to minimize quota usage
  6. App displays graceful "daily limit reached" message when quota exhausted (not crash or blank feed)
  7. Backend tracks daily quota usage and logs warning at 80% threshold
  8. Daily batch job pre-warms cache with 100 popular recipes at 2 AM UTC
**Plans**: 4 plans

Plans:
- [x] 23-01-PLAN.md -- Prisma schema evolution, SpoonacularService API client, recipe mapper, quota tracking
- [x] 23-02-PLAN.md -- Cache service with 6h TTL, searchRecipes and popularRecipes GraphQL queries
- [ ] 23-03-PLAN.md -- Batch pre-warm scheduler (2 AM UTC), health endpoint with quota metrics
- [ ] 23-04-PLAN.md -- Old service cleanup (scraping/image-gen deletion), end-to-end verification

### Phase 24: AVSpeechSynthesizer Free-Tier Voice
**Goal**: Free and guest users hear recipe narration via Apple's built-in text-to-speech with background audio support
**Depends on**: Phase 23 (backend needs plainText field for AVSpeech)
**Requirements**: VOICE-01, VOICE-02, VOICE-04, VOICE-05
**Success Criteria** (what must be TRUE):
  1. Free/guest user taps play on recipe and hears narration via AVSpeechSynthesizer (not ElevenLabs)
  2. AVSpeech narration continues playing when app is backgrounded with lock screen controls visible
  3. Narration pauses between recipe steps (SSML <break> tags) and emphasizes measurements (SSML <emphasis>)
  4. App suggests downloading enhanced iOS voices when user first plays narration (Settings → Accessibility → Live Speech)
  5. Narration gracefully handles iOS 17/18 AVSpeech bugs with fallback error message "Voice unavailable, showing text instead"
  6. Long recipes (>500 words) split into segments to avoid iOS synthesis crashes
**Plans**: TBD

Plans:
- [ ] 24-01: TBD
- [ ] 24-02: TBD

### Phase 25: Voice Tier Routing
**Goal**: Backend and iOS cooperate to route free users to AVSpeech and Pro users to ElevenLabs without breaking existing flows
**Depends on**: Phase 24 (iOS must handle tier-based responses)
**Requirements**: VOICE-03
**Success Criteria** (what must be TRUE):
  1. Pro subscriber taps play and hears cloned ElevenLabs voice (existing flow unchanged)
  2. Free user taps play and hears AVSpeechSynthesizer narration (not ElevenLabs)
  3. Backend narrationAudio query returns { url: null, plainText: instructions, tier: FREE } for free users
  4. Backend narrationAudio query returns { url: R2_CDN, plainText: null, tier: PRO } for Pro users
  5. Backend skips ElevenLabs API call entirely for free users (confirmed via cost monitoring dashboard showing $0 ElevenLabs usage for free tier)
  6. User upgrades from free to Pro and immediately hears cloned voice on next recipe play
**Plans**: TBD

Plans:
- [ ] 25-01: TBD

### Phase 26: Feed UI Migration
**Goal**: iOS feed displays "Popular Recipes" with popularity scores instead of "Viral near you" with viral badges
**Depends on**: Phase 25 (voice tiers must work before changing feed framing)
**Requirements**: RECIPE-04, RECIPE-05, RECIPE-07
**Success Criteria** (what must be TRUE):
  1. Feed heading shows "Popular Recipes" (not "Viral near you")
  2. Recipe cards show popularity score badge (not viral badge)
  3. Recipe cards show ingredient match % based on pantry via Spoonacular findByIngredients
  4. Feed loads recipes from popularRecipes GraphQL query (not viralRecipes)
  5. Deprecated viralRecipes query removed from backend after iOS 100% rollout confirmed
  6. Old scraping services (ScrapingService, XApiService, ImageGenerationProcessor) deleted from backend
**Plans**: TBD

Plans:
- [ ] 26-01: TBD
- [ ] 26-02: TBD

### Phase 27: App Store Compliance Updates
**Goal**: Privacy Labels, PrivacyInfo.xcprivacy, nutrition disclaimers, and screenshots updated for Spoonacular integration
**Depends on**: Phase 26 (screenshots must reflect final feed UI)
**Requirements**: STORE-02, STORE-03
**Success Criteria** (what must be TRUE):
  1. Privacy Policy lists Spoonacular as third-party data processor with link to Spoonacular Privacy Policy
  2. App Privacy Labels in App Store Connect list "Search Queries" shared with Spoonacular
  3. PrivacyInfo.xcprivacy manifest includes Spoonacular API domain
  4. Recipe detail view shows nutrition disclaimer "Estimates from Spoonacular. Not for medical use." in 12pt text
  5. App Store screenshots refreshed showing "Popular Recipes" feed (not "Viral near you")
  6. Screenshots include Spoonacular attribution badge visible on recipe detail view
**Plans**: TBD

Plans:
- [ ] 27-01: TBD

### Phase 28: Fastlane Release Automation
**Goal**: Fastlane release lane automates binary upload, metadata sync, and App Store submission with TestFlight validation
**Depends on**: Phase 27 (all compliance artifacts must exist before submission)
**Requirements**: STORE-01, STORE-04
**Success Criteria** (what must be TRUE):
  1. Running `fastlane release` builds IPA, uploads binary to App Store Connect, and submits for review
  2. Fastlane syncs metadata (description, keywords, screenshots, privacy labels) from fastlane/metadata/ directory
  3. TestFlight internal beta test completed with 3+ testers and no critical bugs before App Store submission
  4. App Store Connect shows "Waiting for Review" status after successful submission
  5. Build uses Xcode 16 + iOS 26 SDK (verified via TestFlight upload)
  6. Release checklist documented in PROJECT.md (tag version, update MILESTONES.md, monitor review status)
**Plans**: TBD

Plans:
- [ ] 28-01: TBD
- [ ] 28-02: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 23 → 24 → 25 → 26 → 27 → 28

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
| 23. Spoonacular Backend Integration | 1/4 | In Progress|  | - |
| 24. AVSpeechSynthesizer Free-Tier Voice | v5.0 | 0/TBD | Not started | - |
| 25. Voice Tier Routing | v5.0 | 0/TBD | Not started | - |
| 26. Feed UI Migration | v5.0 | 0/TBD | Not started | - |
| 27. App Store Compliance Updates | v5.0 | 0/TBD | Not started | - |
| 28. Fastlane Release Automation | v5.0 | 0/TBD | Not started | - |

---

*Roadmap created: 2026-02-28*
*v1.5 shipped: 2026-03-01*
*v2.0 shipped: 2026-03-11*
*v3.0 shipped: 2026-03-29*
*v4.0 shipped: 2026-04-03*
*v5.0 roadmap added: 2026-04-04*
