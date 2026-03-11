# Roadmap: Kindred

## Milestones

- ✅ **v1.5 Backend & AI Pipeline** — Phases 1-3 (shipped 2026-03-01)
- ✅ **v2.0 iOS App** — Phases 4-11 (shipped 2026-03-11)
- 🚧 **v3.0 Smart Pantry** — Phases 12-17 (in progress)

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

### 🚧 v3.0 Smart Pantry (In Progress)

**Milestone Goal:** Add ingredient intelligence — fridge scanning, receipt scanning, persistent pantry, expiry tracking, and recipe-ingredient matching to transform Kindred from recipe discovery into a complete cooking companion.

- [ ] **Phase 12: Pantry Infrastructure** - Backend GraphQL schema, ingredient normalization, PantryFeature SPM package foundation
- [ ] **Phase 13: Manual Pantry Management** - Local-first CRUD with SwiftData, offline-first sync, storage categorization
- [ ] **Phase 14: Camera Capture** - Progressive permission request, photo capture, R2 upload, memory-safe processing
- [ ] **Phase 15: AI Scanning** - Fridge photo recognition (Pro), receipt OCR (Pro), Gemini analysis, Pro paywall
- [ ] **Phase 16: Recipe Matching** - Match % badge on feed cards, shopping list generation, ingredient normalization
- [ ] **Phase 17: Expiry Tracking** - AI expiry estimation, push notifications, visual indicators, consumption tracking

## Phase Details

### Phase 12: Pantry Infrastructure
**Goal**: Build backend and iOS foundation for pantry features with ingredient normalization and data models
**Depends on**: Phase 11
**Requirements**: INFRA-01, INFRA-02, INFRA-03
**Success Criteria** (what must be TRUE):
  1. Backend GraphQL schema supports pantry CRUD operations (queries, mutations, subscriptions)
  2. Ingredient normalization maps user input to canonical forms (handles "eggs" vs "large eggs")
  3. PantryFeature SPM package exists following TCA architecture patterns (reducers, clients, models)
  4. PantryItem SwiftData model persists locally with validation and migrations
**Plans**: TBD

Plans:
- [ ] 12-01: TBD

### Phase 13: Manual Pantry Management
**Goal**: Users can manually add, edit, delete, and view their pantry inventory with offline-first persistence
**Depends on**: Phase 12
**Requirements**: PANTRY-01, PANTRY-02, PANTRY-03, PANTRY-04, PANTRY-05, PANTRY-06, PANTRY-07
**Success Criteria** (what must be TRUE):
  1. User can add a pantry item with name, quantity, unit, and storage location (fridge/freezer/pantry)
  2. User can edit existing pantry items (all fields including category)
  3. User can delete pantry items with swipe-to-delete gesture
  4. User sees pantry list grouped by storage location with item counts
  5. Pantry data persists locally via SwiftData and syncs to backend when online
  6. Pantry works offline with changes queued and synced when connectivity returns
**Plans**: TBD

Plans:
- [ ] 13-01: TBD

### Phase 14: Camera Capture
**Goal**: Users can capture photos from camera with progressive permission request and memory-safe processing
**Depends on**: Phase 13
**Requirements**: INFRA-04, SCAN-06
**Success Criteria** (what must be TRUE):
  1. Camera permission requested with progressive disclosure (not at launch, with explanation)
  2. User can capture photos using UIImagePickerController with live preview
  3. Captured photos upload to Cloudflare R2 with streaming (no memory buffering)
  4. Photo processing handles batch uploads without memory explosion (autoreleasepool, sequential)
  5. Pro paywall appears for free-tier users when accessing camera scanning features
**Plans**: TBD

Plans:
- [ ] 14-01: TBD

### Phase 15: AI Scanning
**Goal**: Pro users can scan fridge photos or supermarket receipts to auto-populate their pantry inventory
**Depends on**: Phase 14
**Requirements**: SCAN-01, SCAN-02, SCAN-03, SCAN-04, SCAN-05
**Success Criteria** (what must be TRUE):
  1. Pro user can photograph their fridge and get identified ingredients via Gemini 2.0 Flash
  2. Fridge scan results show editable ingredient list with confidence indicators (>70% auto-accept)
  3. After fridge scan, user sees matching recipes based on identified ingredients
  4. Pro user can scan supermarket receipt using VisionKit live OCR preview
  5. Receipt scan extracts item names and quantities, adding them to pantry with expiry estimates
  6. Scanning features gracefully handle AI failures (low confidence, OCR misreads) with manual correction
**Plans**: TBD

Plans:
- [ ] 15-01: TBD

### Phase 16: Recipe Matching
**Goal**: Recipe feed cards display ingredient match percentage based on pantry contents with shopping list generation
**Depends on**: Phase 13 (needs populated pantry)
**Requirements**: MATCH-01, MATCH-02, MATCH-03, MATCH-04
**Success Criteria** (what must be TRUE):
  1. Recipe cards display match % badge showing pantry ingredient overlap (green >70%, yellow >50%, hidden <50%)
  2. Match badge uses color coding that's accessible (WCAG AAA contrast)
  3. User can tap recipe to generate shopping list of missing ingredients
  4. Ingredient matching uses normalized names and fuzzy matching (handles variants like "eggs" vs "large eggs")
  5. Match % recalculates automatically when pantry contents change
**Plans**: TBD

Plans:
- [ ] 16-01: TBD

### Phase 17: Expiry Tracking
**Goal**: Users receive push notifications before pantry items expire with AI-estimated expiry dates and visual indicators
**Depends on**: Phase 13 (needs pantry items)
**Requirements**: EXPIRY-01, EXPIRY-02, EXPIRY-03, EXPIRY-04, EXPIRY-05
**Success Criteria** (what must be TRUE):
  1. Each pantry item has an AI-estimated expiry date based on item type (conservative estimates)
  2. User receives push notifications 1-2 days before items expire (batched, not spam)
  3. Pantry view shows expiry status with visual indicators (green fresh, yellow expiring soon, red expired)
  4. AI estimates include disclaimers ("Estimated expiry—verify packaging"), user can manually override dates
  5. User can mark expired items as consumed or discarded with one tap
  6. Notification permission requested progressively (after first pantry add, not at launch)
**Plans**: TBD

Plans:
- [ ] 17-01: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 12 → 13 → 14 → 15 → 16 → 17

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation | v1.5 | 5/5 | Complete | 2026-02-28 |
| 2. Feed Engine | v1.5 | 3/3 | Complete | 2026-03-01 |
| 3. Voice Core | v1.5 | 3/3 | Complete | 2026-03-01 |
| 4. Foundation & Architecture | v2.0 | 4/4 | Complete | 2026-03-01 |
| 5. Guest Browsing & Feed | v2.0 | 4/4 | Complete | 2026-03-02 |
| 6. Dietary Filtering & Personalization | v2.0 | 3/3 | Complete | 2026-03-03 |
| 7. Voice Playback & Streaming | v2.0 | 6/6 | Complete | 2026-03-03 |
| 8. Authentication & Onboarding | v2.0 | 4/4 | Complete | 2026-03-06 |
| 9. Monetization & Voice Tiers | v2.0 | 5/5 | Complete | 2026-03-08 |
| 10. Accessibility & Polish | v2.0 | 7/7 | Complete | 2026-03-08 |
| 11. Auth Gap Closure | v2.0 | 2/2 | Complete | 2026-03-09 |
| 12. Pantry Infrastructure | v3.0 | 0/? | Not started | - |
| 13. Manual Pantry Management | v3.0 | 0/? | Not started | - |
| 14. Camera Capture | v3.0 | 0/? | Not started | - |
| 15. AI Scanning | v3.0 | 0/? | Not started | - |
| 16. Recipe Matching | v3.0 | 0/? | Not started | - |
| 17. Expiry Tracking | v3.0 | 0/? | Not started | - |

---

*Roadmap created: 2026-02-28*
*v1.5 shipped: 2026-03-01*
*v2.0 shipped: 2026-03-11*
*v3.0 started: 2026-03-11*
