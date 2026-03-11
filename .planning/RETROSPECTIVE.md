# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v2.0 — iOS App

**Shipped:** 2026-03-11
**Phases:** 8 | **Plans:** 35

### What Was Built
- SwiftUI + TCA modular architecture with 7 SPM packages
- Swipeable recipe feed with guest browsing, location discovery, offline support
- AI voice narration streaming with background audio, lock screen controls, 500MB LRU cache
- Culinary DNA personalization (60/40 split after 50+ interactions)
- Google/Apple OAuth with guest-to-account conversion and sub-90s onboarding
- Free/Pro tiers with StoreKit 2, AdMob ads, voice slot enforcement
- WCAG AAA accessibility (VoiceOver, Dynamic Type, 7:1 contrast, Reduce Motion)
- Bilingual localization (English + Turkish, 98 strings)

### What Worked
- Modular SPM packages kept features isolated and fast to build
- TCA unidirectional data flow managed complex state (playback, auth, subscriptions)
- "Guest first, auth later" produced natural conversion flow
- Accessibility baked into feature phases (not just Phase 10)
- Gap closure pattern — audit found real gaps, Phase 11 closed them
- Device verification plans caught 6+ bugs that builds missed

### What Was Inefficient
- Phase 5 took ~17 hours vs Phase 4 at ~52 min — feed complexity underestimated
- AVPlayer debugging required 2 gap-closure plans (07-05, 07-06)
- VERIFICATION.md deferred for 4 phases, requiring retroactive writing
- ROADMAP progress table drifted out of sync during execution

### Patterns Established
- `#if DEBUG` URL pattern for backend endpoints
- TCA @DependencyClient for all external services (9 clients)
- @Presents for modal presentation (auth gate, onboarding, paywall)
- String(localized:) with Localizable.xcstrings String Catalog

### Key Lessons
1. Write VERIFICATION.md immediately after phase completion
2. Device verification plans are essential — standard practice going forward
3. Gap closure phases work well: audit → plan → execute → re-verify
4. AVPlayer requires waitForReadyToPlay before play()
5. Check project.yml INFOPLIST_FILE to find the real Info.plist

---

## Milestone: v1.5 — Backend & AI Pipeline

**Shipped:** 2026-03-01
**Phases:** 3 | **Plans:** 11 | **Sessions:** ~4

### What Was Built
- NestJS backend with GraphQL API, Prisma ORM, PostgreSQL with PostGIS geospatial support
- Recipe scraping pipeline (X API + Gemini AI parser) with multi-tier fallback strategy
- AI hero image generation (Imagen 4 Fast) with Cloudflare R2 zero-egress CDN storage
- Hyperlocal feed engine with velocity-based viral ranking, Mapbox geocoding, cursor pagination
- Voice cloning pipeline (ElevenLabs API, background processing, push notifications, tier enforcement)
- Recipe narration system (Gemini conversational rewriting + ElevenLabs streaming TTS ~75ms latency)

### What Worked
- Wave-based parallel execution: Phase 3 Wave 2 executed plans 03-02 and 03-03 simultaneously, cutting time in half
- Consistent service patterns: graceful initialization (ElevenLabs, Mapbox, Firebase all follow same pattern — log warning when API key missing, don't crash)
- In-memory queue pattern: simple background processing for MVP without Redis/BullMQ complexity, upgrade path documented
- Phase verification after execution caught integration issues (stale schema.gql) before milestone audit
- TDD for velocity scorer: 13 unit tests established confidence in ranking algorithm correctness

### What Was Inefficient
- Phase 1 executed before verification step existed — required retroactive verification during milestone audit
- SUMMARY frontmatter `requirements_completed` fields mostly empty — 3-source cross-reference had limited data from this source
- Progress table in ROADMAP.md fell out of sync (showed Phase 1 at 2/5 when actually 5/5)
- Schema.gql not regenerated after Phase 2/3 — committed artifact stale (runtime unaffected but codegen tools would be)

### Patterns Established
- Graceful service initialization: log warning when external API key missing, don't crash — enables local dev without all credentials
- Background queue pattern: in-memory for MVP with documented BullMQ upgrade path for multi-instance
- Chunked transfer encoding for streaming: enables low-latency audio playback before full download
- Per-recipe caching: NarrationScript table prevents redundant Gemini calls (~80% expected hit rate)
- REST for file uploads + GraphQL for CRUD: Multer requires REST; profile management uses GraphQL

### Key Lessons
1. Run phase verification immediately after execution — retroactive verification is slower and adds an extra audit cycle
2. In-memory queues work fine for MVP but must be documented as upgrade candidates before multi-instance deployment
3. NestJS code-first GraphQL requires app startup to regenerate schema.gql — include this in CI or post-execution checklist
4. Velocity scoring with time decay (exponential) is more useful than static engagement thresholds for viral detection

### Cost Observations
- Model mix: ~10% opus (orchestration), ~85% sonnet (execution/verification), ~5% haiku (quick checks)
- Sessions: ~4 (project init, phase 1 execution, phase 2 execution, phase 3 execution + audit + completion)
- Notable: Parallel wave execution (2 agents simultaneously) is the biggest time saver

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.5 | ~4 | 3 | First milestone — established patterns for verification, archival, retrospective |
| v2.0 | ~12 | 8 | Gap closure pattern, device verification standard, retroactive verification |

### Cumulative Quality

| Milestone | Tests | Coverage | Tech Debt Items |
|-----------|-------|----------|-----------------|
| v1.5 | 13 (velocity scorer) | Partial (unit tests only) | 4 (in-memory queues, stale schema, tier field TODO, Instagram placeholder) |
| v2.0 | 0 (UI app) | N/A | 3 (JWS SignedDataVerifier, GraphQL mock data, test ad IDs) |

### Top Lessons (Verified Across Milestones)

1. Run phase verification immediately after execution (confirmed in both milestones)
2. Device verification on physical device catches bugs builds miss (v2.0)
3. Gap closure phases are effective for catching integration issues post-audit (v2.0)
4. ROADMAP progress tables drift — automate or update per-plan (both milestones)
