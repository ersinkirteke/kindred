# Phase 1: Foundation - Context

**Gathered:** 2026-02-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Backend API serving both iOS and Android platforms with authentication, database, recipe scraping pipeline, AI image generation pipeline, and push notification infrastructure operational. Requirements: INFR-01, INFR-02, INFR-03, INFR-04, INFR-06, AUTH-05.

</domain>

<decisions>
## Implementation Decisions

### Backend Platform
- Custom NestJS (TypeScript) backend — not Firebase or Supabase
- PostgreSQL database with Prisma ORM
- Auth0 or Clerk for authentication (Claude's discretion on which)
- Google/Apple OAuth support required for mobile sign-in

### API Design
- GraphQL API (not REST)
- URL versioning (/v1/) for the GraphQL endpoint
- WebSockets for real-time push (expiry alerts, feed updates)
- OpenAPI/Swagger for API contract documentation shared between iOS and Android teams

### Scraping Approach
- API-first strategy: use official APIs where available (X API paid tier), scrape only as supplement/fallback
- City-level location granularity for trending detection (not neighborhood-level)
- Refresh frequency: 4-6 times per day
- Fallback on no data: expand radius (city → country → global trending)

### AI Image Pipeline
- Imagen 4 Fast for hero image generation (~$0.02/image)
- Pre-generate images when recipe is scraped (not on-demand)
- Flat lay editorial style: top-down, ingredients arranged artistically, Instagram-friendly, clean
- Cloudflare R2 + CDN for storage and serving (zero egress fees)

### Recipe Data Model
- Hybrid step storage: AI parses scraped freeform text into structured steps (order, text, duration, technique tag)
- Normalized ingredients: separate fields for name, quantity, unit — enables pantry matching
- AI-estimated nutritional info (calories, protein, carbs, fat) via Gemini
- Metadata tracked: engagement metrics (loves, bookmarks, views), AI-estimated difficulty level, auto-detected dietary tags (vegan, gluten-free, keto, halal, etc.)
- No source attribution stored (scraping is supplement, not content pipeline)

### Caching Strategy
- Offline-first architecture: cache feed + images + voice locally
- Cache last 50 recipes with images (~50MB)
- Cache all played voice narrations locally for offline replay
- Image TTL: 30 days with LRU eviction for oldest

### DevOps & CI/CD
- GitHub Actions for CI/CD pipeline
- Docker containerized deployment
- Two environments: Staging + Production

### Claude's Discretion
- Clerk vs Auth0 final selection (optimize for mobile-first, cost, DX)
- Hosting platform choice (Cloud Run, Railway, Fly.io, etc.)
- Push notification implementation (FCM for Android, APNs for iOS)
- GraphQL schema design and query structure
- WebSocket implementation details
- Docker base images and multi-stage build strategy
- Monitoring and error tracking tooling (Sentry, New Relic, etc.)
- Database migration strategy
- Rate limiting and security middleware

</decisions>

<specifics>
## Specific Ideas

- Recipe images should match the mockup aesthetic: high-quality, warm tones, cinematic food photography — but specifically flat lay / top-down editorial style
- The app must work fully offline with last-synced data — elderly users may have spotty connections
- Voice narrations once played should be available offline forever (cached locally)
- GraphQL chosen for flexible queries as mobile UI evolves across iOS and Android

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- None — greenfield project, no existing codebase

### Established Patterns
- None — patterns will be established in this phase

### Integration Points
- This phase creates the foundation that all subsequent phases build on
- iOS app (Phase 4) and Android app (Phase 9) will consume the GraphQL API
- Voice Core (Phase 3) will integrate with the recipe data model
- Feed Engine (Phase 2) will build on the scraping pipeline

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-foundation*
*Context gathered: 2026-02-28*
