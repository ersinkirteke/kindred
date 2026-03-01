# Milestones

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

