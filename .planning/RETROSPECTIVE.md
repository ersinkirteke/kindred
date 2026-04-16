# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v5.1 — Gap Closure

**Shipped:** 2026-04-16
**Phases:** 4 | **Plans:** 8

### What Was Built
- Source attribution: sourceUrl/sourceName wired from Spoonacular GraphQL through Apollo codegen into RecipeDetailView as SFSafariViewController-backed in-app link
- AVSpeechClient TCA dependency with TextPreprocessor (HTML/markdown strip, fraction expansion, cooking abbreviation expansion), language-aware voice selection via NLLanguageRecognizer, and iOS 17 silent failure retry
- Voice tier routing in VoicePlaybackReducer: free/guest users auto-play AVSpeech, Pro users route to ElevenLabs, with isAVSpeechActive flag branching all playback actions
- VoicePickerView with Free/Pro sections, Kindred Voice on-device branding, step highlighting with tap-to-jump, NowPlaying lock screen controls, VoiceOver accessibility
- Search UI: SearchRecipes GraphQL operation, FeedReducer search state with 300ms debounce, cursor pagination, dietary chip-to-Spoonacular parameter mapping (7 diets, 3 intolerances), search/browse mode switching
- End-to-end hardware verification: build 583, 17/19 tests passed on iPhone 16 Pro Max (iOS 26.3.1), 6 bugs found and fixed during testing cycle

### What Worked
- iOS-only scope (no backend work) kept velocity high: 4 phases in 3 days
- Device verification during Phase 30 and Phase 32 caught 12+ bugs that Simulator builds missed (language detection, sheet conflicts, pause race conditions, missing translations)
- NLLanguageRecognizer solved the Turkish-device-English-content voice mismatch elegantly with zero config
- TextPreprocessor pipeline (6 stages) significantly improved TTS readability for cooking recipes
- Search and filter in same phase was correct: shared SearchRecipesQuery + FeedMode enum avoided double codegen overhead

### What Was Inefficient
- Phase 32 testing cycle went through 15 build numbers (568 to 583) due to incremental bug fixes discovered on device
- Fastlane pilot bug #28630 still requires manual TestFlight group assignment in ASC (known since v5.0, still not upstream-fixed)
- Paid Apps Agreement activation delay blocked VOICE-05 full device verification (administrative, not technical)
- ROADMAP progress table for phases 29-32 had formatting drift (missing milestone column)

### Key Lessons
1. AVSpeech on iOS requires NLLanguageRecognizer for correct voice selection on non-English-locale devices -- device locale does not determine content language
2. SwiftUI sheet conflicts are real: fullScreenCover is the correct pattern when another sheet (voice picker) is already in use
3. Step-based progress is more meaningful than time-based for recipe narration (AVSpeech has no duration API)
4. 300ms debounce + 3-char minimum is the right balance for search UX vs API quota conservation
5. Hardware verification remains the single most effective quality gate -- every milestone confirms this

### Cost Observations
- Fastest milestone yet: 3 days, 8 plans, all iOS-only work
- AVSpeech free-tier voice narration adds $0/recipe ongoing cost vs ElevenLabs $0.01-0.03/recipe
- No new backend deployments required -- all backend endpoints were already operational from v5.0

---

## Milestone: v5.0 — Lean App Store Launch

**Shipped:** 2026-04-12
**Phases:** 5 executed (+ 2 deferred) | **Plans:** 17

### What Was Built
- Spoonacular REST-to-GraphQL backend proxy with PostgreSQL caching (6h TTL, batch pre-warm) at $0/month
- Feed UI migration from "Viral near you" to "Popular Recipes" with cursor pagination and popularity badges
- App Store compliance: PrivacyInfo.xcprivacy with 11 data types, privacy policy v2.1, Spoonacular + AdMob disclosures
- Fastlane release automation with preflight validation, metadata sync, App Store submission
- Kindred v1.0.0 (build 527) submitted to App Store — Waiting for Review

### What Worked
- Two-track execution (Feed critical path first, Voice deferred) kept scope tight and achieved the primary goal
- Decimal phase numbering (27.1) cleanly inserted compliance gap closure without disrupting phase flow
- Preflight validation lane caught config issues before expensive archive+upload cycles
- 72-hour TestFlight bake with structured checklist gave high confidence before submission
- Scraping/image-gen pipeline cleanup (-1,485 lines) reduced backend complexity significantly

### What Was Inefficient
- Phase 28 took 8 days (longest in v5.0) — fastlane signing issues, pilot bugs, and manual ASC workarounds
- Fastlane pilot bug #28630 required manual TestFlight distribution for build 509
- ROADMAP progress table formatting drifted (inconsistent milestone column for v5.0 phases)
- Phase 28 plan checkboxes in ROADMAP never updated to [x] despite having summaries

### Patterns Established
- xcconfig URL escaping: `//` must use `$()` in xcconfig files (`http:/$()/192.168.0.162:3000`)
- `app_store_export_options` as method (not constant) — gym mutates the hash internally
- Each upload lane needs its own `app_store_connect_api_key` call (lane scope doesn't share auth)
- Preflight validation lane as fail-fast gate before any build/upload operation

### Key Lessons
1. Fastlane signing/export is the most time-consuming part of release automation — budget extra time
2. Deferring non-critical scope (Voice Phases 24-25) was the right call — shipped the primary goal on time
3. AdMob compliance gap (Phase 27.1) demonstrates why milestone audits are essential before completion
4. Manual ASC workarounds (Privacy Labels, beta distribution) are unavoidable — document them in Release Process
5. `TARGETED_DEVICE_FAMILY: "1"` (iPhone-only) avoids ITMS-90474 rejection and reduces .ipa size 11%

### Cost Observations
- Model mix: ~15% opus (orchestration/milestone), ~80% sonnet (execution), ~5% haiku (quick checks)
- Notable: Phase 28 dominated session count due to signing iterations and multi-day bake period

---

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

## Milestone: v3.0 — Smart Pantry

**Shipped:** 2026-03-29
**Phases:** 6 | **Plans:** 17

### What Was Built
- Persistent digital pantry with local-first SwiftData CRUD, offline-first sync, grouped storage locations
- AI fridge photo scanning via Gemini 2.0 Flash with confidence-based ingredient checklist (Pro)
- Receipt scanning with VisionKit live OCR + Gemini parsing to auto-populate pantry (Pro)
- Client-side recipe-ingredient matching with colored match % badges and shopping list generation
- AI-estimated expiry tracking with color-coded indicators, push alerts, and consume/discard gestures
- Custom AVCaptureSession camera pipeline with blur detection, R2 upload, and Pro paywall gate

### What Worked
- SwiftData local-first pattern kept pantry responsive even offline
- Client-side ingredient matching eliminated server round-trips for match % badges
- IngredientCatalog (185 bilingual entries) provided consistent normalization
- Three-tier expiry estimation (catalog → Gemini → defaults) balanced cost and accuracy
- PantryFeature as standalone SPM package maintained modular architecture

### What Was Inefficient
- Some v3.0 tech debt deferred to v4.0 (device token registration, paywall wiring, navigation)
- Receipt scanning accuracy depends on receipt quality — edge cases not fully addressed
- 8 manual test scenarios in Phase 13 pending human execution

### Patterns Established
- SwiftData named ModelConfiguration for container isolation
- Progressive camera permission (poll-based, mirrors LocationClient)
- Base64 → Apollo multipart upload for camera photos
- Bidirectional fuzzy ingredient matching (contains check both directions)

### Key Lessons
1. Local-first with sync-later works well for single-user data (pantry, guest session)
2. AI vision (Gemini Flash) is cost-effective enough for per-scan usage (~$0.001)
3. Excluding common staples from match % produces meaningful percentages
4. Tech debt from one milestone naturally becomes requirements for the next

---

## Milestone: v4.0 — App Store Launch Prep

**Shipped:** 2026-04-03
**Phases:** 5 | **Plans:** 19

### What Was Built
- Voice cloning consent framework with GDPR per-upload consent and backend audit trail
- Privacy manifest (PrivacyInfo.xcprivacy) with Required Reason API codes and 7 data type declarations
- Backend production hardening: SignedDataVerifier, rate limiting, request tracing, narration URL resolver
- ATT consent flow with UMP SDK, pre-prompt screen, production AdMob IDs via xcconfig
- Production voice playback: GraphQL wiring replacing TestAudioGenerator with cache-first R2 CDN audio
- Complete App Store submission package: fastlane, metadata, screenshots, beta testing plan

### What Worked
- Systematic gap closure: v3.0 tech debt items (5 GraphQL TODOs, paywall wiring, navigation, SwiftData) cleanly resolved
- xcconfig-based configuration separating Debug/Release environments (ad IDs, API keys)
- SignedDataVerifier replaced base64url MVP approach — clear upgrade path from earlier ⚠️ Revisit decision
- Verification reports with human_needed status appropriately flagged device-only checks
- Phase 20 gap closure (20-04) caught AdClient wiring and pro subscriber skip before archival

### What Was Inefficient
- Phase 20 verification found gaps (AdClient wiring, pro subscriber skip) that needed gap closure plan
- Phase 22 plans were documentation-heavy (fastlane, metadata, screenshot guides) — minimal code, mostly templates
- Some ROADMAP plan checkboxes were not updated during execution (19-02, 20-01, 20-02, 20-03 show unchecked despite having summaries)

### Patterns Established
- xcconfig for environment-specific configuration (Debug test IDs vs Release production IDs)
- fatalError for unconfigured Release builds prevents shipping test credentials
- Per-upload consent pattern for legally defensible AI processing consent
- Cache-first audio loading: local cache → GraphQL fallback for narration
- Fastlane 3-lane distribution (internal, external, release)

### Key Lessons
1. Gap closure after verification is now a reliable pattern (v2.0 Phase 11, v4.0 Phases 18-04, 20-04)
2. xcconfig is the right way to manage environment-specific iOS configuration
3. Documentation phases (metadata, guides) execute fast but provide essential submission artifacts
4. ROADMAP checkbox state should be auto-updated by execution workflow to prevent drift
5. Legal compliance work (consent framework) should start early — legal review is the long pole

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.5 | ~4 | 3 | First milestone — established patterns for verification, archival, retrospective |
| v2.0 | ~12 | 8 | Gap closure pattern, device verification standard, retroactive verification |
| v3.0 | ~8 | 6 | Local-first data patterns, AI vision integration, progressive permission pattern |
| v4.0 | ~6 | 5 | Compliance-first approach, xcconfig environment separation, gap closure as standard |
| v5.0 | ~10 | 5+2 | Two-track scope management, decimal phase insertion, preflight validation, App Store submission |
| v5.1 | ~4 | 4 | iOS-only gap closure, device verification as quality gate, zero backend work |

### Cumulative Quality

| Milestone | Tests | Coverage | Tech Debt Items |
|-----------|-------|----------|-----------------|
| v1.5 | 13 (velocity scorer) | Partial (unit tests only) | 4 (in-memory queues, stale schema, tier field TODO, Instagram placeholder) |
| v2.0 | 0 (UI app) | N/A | 3 (JWS SignedDataVerifier, GraphQL mock data, test ad IDs) |
| v3.0 | 0 (feature app) | N/A | 4 (device tokens, paywall wiring, navigation, manual tests pending) |
| v4.0 | 10 (ConsentReducer TCA) | Consent state machine | 3 (legal review, in-memory queues, timezone notifications) |
| v5.0 | 0 | N/A | 6 (test mock, type mismatch, dead code, isViral query, rating config, manual submission) |
| v5.1 | 0 | N/A | 2 (VOICE-05 pending Paid Apps Agreement, iOS 17 TTSErrorDomain -4010 production monitoring) |

### Velocity Trend

| Milestone | Phases | Plans | Days | Plans/Day |
|-----------|--------|-------|------|-----------|
| v1.5 | 3 | 11 | 2 | 5.5 |
| v2.0 | 8 | 35 | 9 | 3.9 |
| v3.0 | 6 | 17 | 7 | 2.4 |
| v4.0 | 5 | 19 | 4 | 4.8 |
| v5.0 | 5 | 17 | 9 | 1.9 |
| v5.1 | 4 | 8 | 3 | 2.7 |

### Top Lessons (Verified Across Milestones)

1. Run phase verification immediately after execution (confirmed in all milestones)
2. Device verification on physical device catches bugs builds miss (v2.0, v4.0)
3. Gap closure phases are effective for catching integration issues post-audit (v2.0, v4.0)
4. ROADMAP progress tables drift — automate or update per-plan (all milestones)
5. Tech debt from one milestone cleanly becomes requirements for the next (v3.0 → v4.0)
6. xcconfig-based environment separation prevents shipping test credentials (v4.0)
7. Deferring non-critical scope to keep primary milestone goal achievable (v5.0)
8. Milestone audits catch compliance gaps that phase-level verification misses (v4.0, v5.0)
