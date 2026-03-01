---
gsd_state_version: 1.0
milestone: v1.5
milestone_name: milestone
current_phase: 03
current_plan: 01
status: in_progress
stopped_at: Completed 03-01-PLAN.md
last_updated: "2026-03-01T12:12:07.307Z"
progress:
  total_phases: 3
  completed_phases: 2
  total_plans: 11
  completed_plans: 9
  percent: 82
---

# Project State: Kindred

**Last Updated:** 2026-03-01
**Current Phase:** 03
**Current Plan:** 1 of 3
**Status:** In progress

---

## Project Reference

**Core Value:** Hearing a loved one's voice guide you through a trending local recipe — that emotional moment is what makes Kindred irreplaceable.

**Current Focus:** Phase 3 (Voice Core) in progress. Voice foundation complete with VoiceProfile schema, ElevenLabs API client, and R2 voice sample storage. Next: voice upload and narration.

---

## Current Position

**Phase:** 03-voice-core
**Plan:** 1 of 3
**Status:** In progress
**Progress:** [████████░░] 82% (9/11 plans complete)

---

## Performance Metrics

### Velocity
- **Phases completed:** 2
- **Plans completed:** 9
- **Average plans per phase:** 4.5 (Phase 1: 5 plans, Phase 2: 3 plans, Phase 3: 1 plan so far)
- **Estimated completion:** TBD

### Quality
- **Requirement coverage:** 46/46 mapped (100%)
- **Success criteria defined:** Yes (2-5 per phase)
- **Blocked items:** 0

### Recent Metrics
| Phase-Plan | Duration | Tasks | Files | Completed |
|------------|----------|-------|-------|-----------|
| 01-01      | 19 min   | 3     | 38    | 2026-02-28 |
| 01-02      | 4 min    | 2     | 10    | 2026-02-28 |
| 01-03      | 5 min    | 2     | 16    | 2026-02-28 |
| 01-04      | TBD      | TBD   | 4     | 2026-02-28 |
| 01-05      | 4 min    | 2     | 12    | 2026-02-28 |
| 02-01      | 5 min    | 2     | 9     | 2026-03-01 |
| 02-02      | 8 min    | 2     | 7     | 2026-03-01 |
| 02-03      | 4 min    | 2     | 8     | 2026-03-01 |
| 03-01      | 4 min    | 2     | 8     | 2026-03-01 |
| Phase 03 P01 | 4 | 2 tasks | 8 files |

## Accumulated Context

### Key Decisions Made
1. **Platform strategy:** iOS first (SwiftUI + TCA), Android fast-follow (Compose + MVVM/Clean/Hilt), shared backend/API
2. **AI video deferred:** Veo video generation OUT of v1 scope due to cost ($4.50-9/user/month) and latency (30-120s)
3. **Architecture:** iOS uses TCA for state management, Android uses MVVM + Clean Architecture
4. **Backend:** Custom NestJS backend with GraphQL API (decided in Phase 1 planning - not Firebase/Supabase)
5. **Voice:** ElevenLabs API with custom REST client (native SDKs immature)
6. **Vision:** Gemini 3 Flash via Firebase AI Logic SDK
7. **Design:** Warm cream/terracotta palette, 56dp touch targets, 18sp min body text (WCAG AAA)
8. **Depth:** Comprehensive (10 phases, 5-10 plans each estimated)
9. **Prisma 7 with PostgreSQL adapter:** Using @prisma/adapter-pg for direct database connections instead of Prisma Accelerate (01-01)
10. **GraphQL code-first schema:** Using NestJS decorators with explicit type annotations for nullable fields (01-01)
11. **Express 5 with Apollo Server 5:** Using @as-integrations/express5 for GraphQL integration (01-01)
12. **Clerk for OAuth:** Handles Google/Apple OAuth with refresh token rotation, eliminating need for custom OAuth implementation (01-02)
13. **Svix webhook verification:** Prevents unauthorized user creation by validating webhook signatures (01-02)
14. **Non-global auth guard:** ClerkAuthGuard applied per-resolver for guest browsing support - AUTH-01 (01-02)
15. **Gemini 2.0 Flash for recipe parsing:** Fast, cost-effective model (~$0.001/recipe) with JSON response mode for structured extraction (01-03)
16. **Instagram placeholder pattern:** Stub service allows X API pipeline to work immediately, Instagram added later without refactoring (01-03)
17. **City -> Country -> Global fallback:** INFR-04 graceful degradation - expands radius when hyperlocal scraping fails (01-03)
18. **4x/day scheduled scraping:** Balances freshness with API costs, covers US peak hours (8AM, 12PM, 6PM, 9PM UTC) (01-03)
19. **Imagen 4 Fast for hero images:** Cost-effective AI image generation (~$0.01/image vs $0.04 standard) with flat lay editorial prompts (01-04)
20. **Cloudflare R2 for image storage:** Zero-egress CDN delivery aligns with cost strategy (vs S3 $0.09/GB egress) (01-04)
21. **In-memory image queue for MVP:** Simple background processing without Redis/BullMQ - upgrade path documented for multi-instance scaling (01-04)
22. **Non-blocking image enrichment:** Recipes available immediately (imageStatus=PENDING), images populate asynchronously without blocking feed (01-04)
23. **Firebase Cloud Messaging:** Unified SDK for iOS (APNs) and Android (FCM) with automatic token management (01-05)
24. **Graceful Firebase initialization:** Local dev works without Firebase credentials - service logs warning instead of crashing (01-05)
25. **Multicast batch sending:** FCM limit is 500 tokens per multicast - handles large user bases efficiently (01-05)
26. **Platform-specific push payloads:** iOS requires APNs headers, Android requires FCM channel - separate construction ensures compatibility (01-05)
27. **GitHub Actions CI/CD:** Native GitHub integration for lint, type-check, build, and Docker image verification (01-05)
28. **Placeholder deployment commands:** Hosting platform choice deferred for scraping workload analysis - pipeline ready for Railway/Fly.io/Cloud Run (01-05)
29. **PostGIS spatial indexing:** GIST index on ST_MakePoint(longitude, latitude) enables performant 5-10 mile radius queries (02-01)
30. **Mapbox coordinate handling:** [lng, lat] order validated with ±90/±180 bounds - critical for spatial query correctness (02-01)
31. **CityLocation geocoding cache:** DB cache prevents redundant Mapbox API calls (~99% hit rate saves ~$1,825/year) (02-01)
32. **Graceful Mapbox degradation:** Local dev works without MAPBOX_ACCESS_TOKEN - service logs warning instead of crashing (02-01)
33. **Fine-grained cuisine classification:** 29 CuisineType values (28 cuisines + OTHER) per user locked decision enables precise feed filtering (02-01)
34. **Velocity scoring formula:** (engagement/hour) * (1 + e^(-age/24)) with viral threshold = 10/hour - combines raw engagement with exponential time decay (02-02)
35. **Velocity-based viral detection:** Replaces hardcoded threshold=1000 - engagement per hour in local area determines VIRAL status (02-02)
36. **AI cuisine/meal tagging:** Gemini parser extracts cuisineType (29 categories) and mealType (7 categories) - AI tagging enables feed filtering without manual categorization (02-02)
37. **Views weighted at 0.3x:** Passive engagement (views) weighted lower than active engagement (loves) for velocity calculation (02-02)
38. **Geocode city once per scrape:** Apply lat/lng to all recipes from same city - prevents N API calls when scraping N recipes (02-02)
39. **RecipeCard card-level fields only:** Detail fields (dietaryTags, cookTime, difficulty) excluded from feed cards to reduce GraphQL payload size and improve feed performance (02-03)
40. **Keyset pagination with velocityScore + id cursor:** Prevents page drift when feed updates, more efficient than offset pagination for velocity-ranked results (02-03)
41. **Expanded radius fallback (city -> country -> global):** Feed never returns empty per user requirement - progressively expands from 10mi -> 50mi -> 500mi -> global (02-03)
42. **Progressive filter relaxation:** When filters produce zero results, drop dietaryTags first, then mealTypes, then cuisineTypes - improves UX by showing partial matches (02-03)
43. **Cache-Control with stale-while-revalidate:** 5 min fresh (max-age=300), 24 hour stale (stale-while-revalidate=86400) for offline-first mobile clients with pull-to-refresh (02-03)
44. **VoiceStatus lifecycle:** PENDING → PROCESSING → READY → FAILED → DELETED provides clear state tracking for async voice cloning operations (03-01)
45. **GraphQL security for voice profiles:** VoiceProfileDto excludes internal fields (elevenLabsVoiceId, audioSampleUrl, consent data) to prevent leaking sensitive data to clients (03-01)
46. **Graceful ElevenLabs initialization:** Following Mapbox/Firebase pattern, service logs warning when ELEVENLABS_API_KEY missing instead of crashing - enables local dev without API credentials (03-01)
47. **eleven_flash_v2_5 model for TTS:** Ultra-low latency model (~75ms) with stability=0.5, similarity_boost=0.75 for real-time voice narration streaming (03-01)

### Open Questions
1. ~~Backend choice: Firebase vs Supabase~~ RESOLVED: Custom NestJS backend (01-01)
2. ~~Scraping strategy: Apify vs Browse AI vs building custom scraper with fallback~~ RESOLVED: Custom X API integration with Instagram placeholder (01-03)
3. Voice quality: 30s sample vs 60s sample for ElevenLabs cloning
4. iOS min version: iOS 17.0 confirmed (SwiftData requirement)
5. Android min SDK: 26 confirmed (~98% device coverage)
6. Hosting platform: Cloud Run vs Railway vs Fly.io (to be decided after scraping workload analysis)

### Blockers
None

---

## Session Continuity

### What Just Happened
- Completed Plan 03-01: Voice Foundation
- Added VoiceStatus enum with lifecycle states (PENDING → PROCESSING → READY → FAILED → DELETED)
- Created VoiceProfile Prisma model with status tracking, speaker metadata, and consent fields
- Added voiceProfiles relation to User model
- Created VoiceModule and registered in AppModule
- Created GraphQL DTOs (VoiceProfileDto excludes internal fields, UploadVoiceInput requires consentGiven)
- Implemented ElevenLabsService with cloneVoice, deleteVoice, generateSpeechStream, getVoice methods
- Extended R2StorageService with uploadVoiceSample and deleteVoiceSample methods
- Graceful initialization when ELEVENLABS_API_KEY missing (log warning, don't crash)
- Added ELEVENLABS_API_KEY to .env.example
- Created 03-01-SUMMARY.md with full documentation and self-check
- Updated STATE.md and ROADMAP.md with 03-01 progress
- Duration: 4 minutes
- **Phase 3 (Voice Core): 1/3 plans complete**

### What's Next
1. Plan 03-02: Voice upload GraphQL resolver with multipart file handling
2. Plan 03-03: Voice narration with TTS streaming

### Context for Next Session
- **Mode:** Interactive (user approval required for roadmap and plans)
- **Depth:** Comprehensive (5-10 plans per phase)
- **Platform strategy:** iOS first, Android fast-follow with shared backend
- **Critical path:** Phase 1 (Foundation) → Phase 2 (Feed Engine) → Phase 3 (Voice Core) → Phase 4 (iOS App) → Phase 9 (Android App)
- **AI services:** ElevenLabs (voice), Gemini 3 Flash (vision), Imagen 4 (images), Apify (scraping)
- **Cost target:** ~$0.06-0.35/user/month at scale (without video)
- **Legal constraint:** Voice cloning consent framework required before launch (Tennessee ELVIS Act, California AB 1836)

### Last Session
- **Date:** 2026-03-01
- **Duration:** 4 minutes
- **Stopped at:** Completed 03-01-PLAN.md
- **Next action:** Continue Phase 3 with plan 03-02 (Voice Upload) or 03-03 (Voice Narration)

---

*State updated: 2026-03-01T08:56:21Z after completing Plan 02-02*
