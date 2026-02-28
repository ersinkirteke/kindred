# Project State: Kindred

**Last Updated:** 2026-02-28
**Current Phase:** Pre-planning
**Current Plan:** None
**Status:** Roadmap created, awaiting phase planning

---

## Project Reference

**Core Value:** Hearing a loved one's voice guide you through a trending local recipe — that emotional moment is what makes Kindred irreplaceable.

**Current Focus:** Roadmap defined with 10 phases covering iOS-first launch, Android fast-follow, and full feature parity. Ready to begin Phase 1 planning.

---

## Current Position

**Phase:** 01-foundation
**Plan:** 02 of 5
**Status:** In Progress
**Progress:** ██░░░░░░░░ 20% (1/5 plans complete in current phase, 0/10 phases complete)

---

## Performance Metrics

### Velocity
- **Phases completed:** 0
- **Plans completed:** 1
- **Average plans per phase:** TBD (only 1 plan completed)
- **Estimated completion:** TBD

### Quality
- **Requirement coverage:** 46/46 mapped (100%)
- **Success criteria defined:** Yes (2-5 per phase)
- **Blocked items:** 0

### Recent Metrics
| Phase-Plan | Duration | Tasks | Files | Completed |
|------------|----------|-------|-------|-----------|
| 01-01      | 19 min   | 3     | 38    | 2026-02-28 |

---

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

### Open Questions
1. ~~Backend choice: Firebase vs Supabase~~ RESOLVED: Custom NestJS backend (01-01)
2. Scraping strategy: Apify vs Browse AI vs building custom scraper with fallback
3. Voice quality: 30s sample vs 60s sample for ElevenLabs cloning
4. iOS min version: iOS 17.0 confirmed (SwiftData requirement)
5. Android min SDK: 26 confirmed (~98% device coverage)
6. Hosting platform: Cloud Run vs Railway vs Fly.io (to be decided after scraping workload analysis)

### Blockers
None

---

## Session Continuity

### What Just Happened
- Completed Plan 01-01: Backend Foundation
- Scaffolded NestJS 11.x project with TypeScript
- Defined complete Prisma 7 schema with 6 models (User, Recipe, Ingredient, RecipeStep, DeviceToken, Bookmark)
- Implemented GraphQL code-first API with Apollo Server 5
- Set up Docker development environment with PostgreSQL 15
- Created 3 commits (scaffold, schema, GraphQL API)
- Duration: 19 minutes, 38 files created

### What's Next
1. Plan 01-02: Clerk Authentication (implement auth guard, user sync webhook, protected queries)
2. Plan 01-03: Recipe Scraping Pipeline (X API integration, Instagram scraping, normalization)
3. Plan 01-04: AI Image Generation (Imagen 4 Fast, Cloudflare R2 upload)
4. Plan 01-05: Push Notifications (Firebase Cloud Messaging, APNs, device token management)

### Context for Next Session
- **Mode:** Interactive (user approval required for roadmap and plans)
- **Depth:** Comprehensive (5-10 plans per phase)
- **Platform strategy:** iOS first, Android fast-follow with shared backend
- **Critical path:** Phase 1 (Foundation) → Phase 2 (Feed Engine) → Phase 3 (Voice Core) → Phase 4 (iOS App) → Phase 9 (Android App)
- **AI services:** ElevenLabs (voice), Gemini 3 Flash (vision), Imagen 4 (images), Apify (scraping)
- **Cost target:** ~$0.06-0.35/user/month at scale (without video)
- **Legal constraint:** Voice cloning consent framework required before launch (Tennessee ELVIS Act, California AB 1836)

### Last Session
- **Date:** 2026-02-28
- **Duration:** 19 minutes
- **Stopped at:** Completed 01-01-PLAN.md (Backend Foundation)
- **Next action:** Execute Plan 01-02 (Clerk Authentication)

---

*State updated: 2026-02-28T21:17:00Z after completing Plan 01-01*
