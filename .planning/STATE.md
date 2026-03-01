---
gsd_state_version: 1.0
milestone: v1.5
milestone_name: milestone
current_phase: 03
current_plan: 2 of 3
status: executing
stopped_at: Completed 03-03-PLAN.md
last_updated: "2026-03-01T12:24:02.122Z"
progress:
  total_phases: 3
  completed_phases: 3
  total_plans: 11
  completed_plans: 11
  percent: 91
---

# Project State: Kindred

**Last Updated:** 2026-03-01
**Current Phase:** 03
**Current Plan:** 2 of 3
**Status:** In progress

---

## Project Reference

**Core Value:** Hearing a loved one's voice guide you through a trending local recipe — that emotional moment is what makes Kindred irreplaceable.

**Current Focus:** Phase 3 (Voice Core) in progress. Voice upload pipeline complete with REST file upload, background cloning queue, tier enforcement, and GraphQL management API. Next: voice narration with TTS streaming.

---

## Current Position

**Phase:** 03-voice-core
**Plan:** 2 of 3
**Status:** In progress
**Progress:** [█████████░] 91% (10/11 plans complete)

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
| Phase 03 P02 | 5 | 2 tasks | 8 files |
| Phase 03 P03 | 5 | 2 tasks | 6 files |

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
48. **In-memory voice cloning queue:** Following ImageGenerationProcessor pattern, using simple in-memory queue for async voice cloning - future upgrade path to BullMQ documented (03-02)
49. **FREE tier voice limit:** 1 active voice profile per user (PRO tier unlimited) with VOICE_SLOT_LIMIT error code and upgrade CTA when limit exceeded (03-02)
50. **REST for voice file uploads:** Multer file upload requires REST endpoints (GraphQL doesn't support multipart/form-data natively) - voice profile management uses GraphQL for queries/mutations (03-02)
51. **Push notification on clone completion:** Voice cloning is async (10-30s) - push notification sent when status=READY improves UX by alerting user when voice is ready to use (03-02)
52. **Re-record flow updates existing profile:** replaceVoice() deletes old assets and re-enqueues cloning instead of creating new profile - implements VOICE-07 requirement (03-02)
53. **Gemini temperature=0.7 for narration:** Higher temperature (vs 0.1 for parsing) produces natural, warm conversational tone while keeping costs low (~$0.001/recipe) (03-03)
54. **Per-recipe narration caching:** NarrationScript table caches by recipeId (voice-independent) to prevent redundant Gemini calls - expected 80% cache hit rate for popular recipes (03-03)
55. **Chunked transfer encoding for audio:** Enables low-latency playback on mobile - client can start playing before full audio downloads (03-03)
56. **Speaker metadata via HTTP headers:** X-Speaker-Name, X-Speaker-Relationship, X-Recipe-Name headers travel with audio stream for "Narrated by Mom" UI display (03-03)

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
- Completed Plan 03-02: Voice Upload Pipeline
- Created VoiceCloningProcessor with in-memory queue for async voice cloning (same pattern as ImageGenerationProcessor)
- Created VoiceService with tier enforcement (FREE tier: 1 active voice, PRO: unlimited)
- Created VoiceController with REST endpoints for file upload (POST /voice/upload, POST /voice/:id/replace)
- Created VoiceResolver with GraphQL queries (myVoiceProfiles, voiceProfile) and mutations (deleteVoiceProfile, updateVoiceProfileName)
- Wired VoiceModule with all providers (VoiceService, VoiceCloningProcessor, VoiceResolver) and imports (PushModule)
- Push notification sent on voice clone completion (VOICE_READY event)
- Consent validation on server side (consentGiven required, IP address tracked)
- Re-record flow (VOICE-07) via replaceVoice() method
- Installed @types/multer for file upload support
- Fixed VoiceProfileDto to use Prisma VoiceStatus enum (not duplicate)
- Created 03-02-SUMMARY.md with full documentation and self-check
- Updated STATE.md and ROADMAP.md with 03-02 progress
- Duration: 5 minutes
- **Phase 3 (Voice Core): 2/3 plans complete**

### What's Next
1. Plan 03-03: Voice narration with TTS streaming (may already be complete based on summary file presence)
2. Phase 4: iOS app development (or next phase in roadmap)

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
- **Duration:** 5 minutes
- **Stopped at:** Completed 03-02-PLAN.md
- **Next action:** Phase 3 complete (all 3 plans done). Begin Phase 4 (iOS app) or next phase in roadmap.

---

*State updated: 2026-03-01T08:56:21Z after completing Plan 02-02*
