# Milestones

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

