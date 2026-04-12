# Milestones

## v5.0 Lean App Store Launch (Shipped: 2026-04-12)

**Phases completed:** 5 executed phases (+ 2 deferred), 17 plans, 26 tasks
**Requirements:** 13/18 satisfied (5 VOICE requirements deferred to next milestone)
**Git range:** feat(23-01) → docs(28-05) (95 commits)
**LOC:** +17,544 / -2,412 (163 files modified)
**Timeline:** 9 days (2026-04-04 → 2026-04-12)

**Key accomplishments:**
- Spoonacular REST-to-GraphQL backend proxy with PostgreSQL caching (6h TTL, batch pre-warm) replacing X API scraping + Imagen 4 at $0/month SaaS costs
- Feed UI migration from "Viral near you" to "Popular Recipes" with cursor pagination and popularity score badges
- App Store compliance: PrivacyInfo.xcprivacy with 11 data types, privacy policy v2.1, Spoonacular attribution footer, nutrition disclaimers, refreshed screenshots
- AdMob compliance gap closure: 4 tracking data types added to privacy manifest, policy updated with Google AdMob disclosure
- Fastlane release automation with preflight validation lane, metadata sync, and App Store submission — Kindred v1.0.0 (build 527) submitted, Waiting for Review

### Known Gaps (Deferred)
- VOICE-01-05: AVSpeechSynthesizer free-tier narration (Phases 24-25 not executed — carry to next milestone)
- RECIPE-06: Per-recipe sourceUrl not wired in iOS RecipeDetailQuery (static Spoonacular link works)
- RECIPE-01/02: Search UI not wired to backend searchRecipes endpoint
- Recipe filtering: Dietary chips don't pass parameters to Spoonacular filter queries

---

## v4.0 App Store Launch Prep (Shipped: 2026-04-03)

**Phases completed:** 5 phases, 19 plans, 16 tasks
**Requirements:** 20/20 satisfied
**Git range:** cd7b24e → bef0040 (58 commits)
**LOC:** ~25,632 Swift + ~11,812 TypeScript (+20,833 lines added)
**Timeline:** 4 days (2026-03-30 → 2026-04-03)

**Key accomplishments:**
- Voice cloning consent framework with GDPR-compliant per-upload consent, ElevenLabs AI provider disclosure, and backend audit trail (userId, timestamp, IP, appVersion)
- Privacy manifest (PrivacyInfo.xcprivacy) with Required Reason API codes (CA92.1, C617.1) and 7 data type declarations across 5 SDK providers
- Backend production hardening: SignedDataVerifier x5c chain validation, named rate limiting, request tracing, structured error codes, narration URL resolver with R2 CDN
- ATT consent flow with UMP SDK (GDPR/CCPA), pre-prompt explanation screen, production AdMob unit IDs via xcconfig, and pro subscriber consent skip
- Production voice playback: GraphQL integration replacing TestAudioGenerator with cache-first R2 CDN audio, paywall purchase wiring, recipe carousel navigation with fuzzy ingredient matching
- App Store submission package: fastlane automation (3 distribution lanes), bilingual metadata with AI disclosure, screenshot guides, and beta testing plan

---

## v3.0 Smart Pantry (Shipped: 2026-03-29)

**Phases completed:** 6 phases, 17 plans, 19 tasks
**Requirements:** 26/26 satisfied (24 clean, 2 checkbox discrepancies fixed)
**Git range:** feat(12-01) → feat(17-03) (33 feat commits, 78 total)
**LOC:** ~23,105 Swift + ~8,113 TypeScript (+30,669 lines added)
**Timeline:** 7 days (2026-03-11 → 2026-03-17)

**Key accomplishments:**
- Persistent digital pantry with local-first SwiftData CRUD, offline-first sync (last-write-wins), and grouped storage location views
- AI fridge photo scanning via Gemini 2.0 Flash with confidence-based ingredient checklist and IngredientCatalog normalization (Pro)
- Receipt scanning with VisionKit live OCR + Gemini parsing to auto-populate pantry items (Pro)
- Client-side recipe-ingredient matching with colored match % badges on feed cards and grouped shopping list generation
- AI-estimated expiry tracking with color-coded visual indicators, push notification alerts, and consume/discard swipe gestures
- Custom AVCaptureSession camera pipeline with blur detection, R2 upload, expandable FAB, and Pro paywall gate

### Known Gaps (Tech Debt)
- EXPIRY-02 partial: device token registered but not sent to backend for push delivery
- ScanPaywallView subscribe button placeholder — not wired to MonetizationFeature purchase flow
- Recipe suggestion carousel card tap does not navigate to recipe detail view
- 8 manual test scenarios in Phase 13 pending human execution

---

## v2.0 iOS App (Shipped: 2026-03-11)

**Phases completed:** 8 phases, 35 plans
**Requirements:** 33/33 verified
**Git range:** feat(04-01) → feat(11-02) (162 commits)
**LOC:** 13,319 Swift (107 source files, excluding generated)
**Timeline:** 9 days (2026-03-01 → 2026-03-09)

**Key accomplishments:**
- SwiftUI + TCA modular architecture with 7 SPM packages (DesignSystem, NetworkClient, AuthClient, FeedFeature, ProfileFeature, VoicePlaybackFeature, MonetizationFeature)
- Swipeable recipe feed with guest browsing, location-based discovery, dietary filtering, and offline support
- AI voice narration streaming with background audio, lock screen controls, step highlighting, and 500MB LRU cache
- Culinary DNA personalization engine learning from implicit feedback (60/40 personalization/discovery split after 50+ interactions)
- Google/Apple OAuth via Clerk with guest-to-account conversion, sub-90s onboarding carousel, and data migration
- Free/Pro subscription tiers with StoreKit 2, AdMob ads (native + banner), and voice slot enforcement
- WCAG AAA accessibility: VoiceOver navigation, Dynamic Type @ScaledMetric, 7:1 contrast, Reduce Motion fallbacks
- Bilingual localization (English + Turkish, 98 strings, 100% coverage) with os.log structured logging

---

## v1.5 Backend & AI Pipeline (Shipped: 2026-03-01)

**Phases completed:** 3 phases, 11 plans, 8 tasks

**Key accomplishments:**
- NestJS backend with GraphQL API, Prisma ORM, PostgreSQL, Docker, Clerk auth with JWT session persistence
- Recipe scraping pipeline (X API + Gemini AI parser) with city→country→global fallback and 4x/day scheduling
- AI hero image generation (Imagen 4 Fast) with Cloudflare R2 zero-egress CDN storage
- Hyperlocal feed engine with PostGIS geospatial queries, velocity-based viral ranking, Mapbox geocoding with DB cache
- Voice cloning pipeline (ElevenLabs API, R2 storage, background processing, push notifications, tier enforcement)
- Recipe narration system (Gemini conversational rewriting + ElevenLabs streaming TTS ~75ms latency, per-recipe caching)

**Stats:**
- 21 feat commits, 123 files, ~6,066 LOC TypeScript
- Timeline: 2 days (2026-02-28 → 2026-03-01)
- Requirements: 20/20 satisfied (INFR-01-04,06 + AUTH-05 + FEED-01-03,06-09 + VOICE-01-07)

---

