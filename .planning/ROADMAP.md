# Roadmap: Kindred

**Project:** Kindred — Hyperlocal AI-Humanized Culinary Assistant
**Created:** 2026-02-28
**Depth:** Comprehensive (native iOS + Android, shared backend)

## Milestones

- ✅ **v1.5 Backend & AI Pipeline** — Phases 1-3 (shipped 2026-03-01)
- 📋 **Next milestone** — TBD (iOS app, pantry, personalization, accessibility, monetization, Android)

## Phases

<details>
<summary>✅ v1.5 Backend & AI Pipeline (Phases 1-3) — SHIPPED 2026-03-01</summary>

- [x] Phase 1: Foundation (5/5 plans) — Backend API, auth, scraping, image gen, push notifications
- [x] Phase 2: Feed Engine (3/3 plans) — PostGIS geospatial, velocity ranking, feed GraphQL API
- [x] Phase 3: Voice Core (3/3 plans) — ElevenLabs cloning, voice upload pipeline, narration streaming

**Total:** 3 phases, 11 plans, 20/20 requirements satisfied
**Archive:** `.planning/milestones/v1.5-ROADMAP.md`

</details>

### 📋 Next Milestone (Planned)

- [ ] **Phase 4: iOS App (Primary Features)** — Feed, recipe detail, voice player
- [ ] **Phase 5: Smart Pantry (iOS)** — Camera scan, receipt OCR, inventory management
- [ ] **Phase 6: Personalization Engine** — Culinary DNA, dietary filtering
- [ ] **Phase 7: Accessibility & Polish (iOS)** — WCAG AAA compliance, onboarding refinement
- [ ] **Phase 8: Monetization** — Free tier ads, Pro tier subscription
- [ ] **Phase 9: Android App (Core Parity)** — Feed, recipe detail, voice player
- [ ] **Phase 10: Android Pantry & Full Parity** — Complete feature set on Android

### Phase Details

#### Phase 4: iOS App (Primary Features)
**Goal:** iOS users can browse feed, view recipe details, and cook with voice narration
**Depends on:** Phase 2, Phase 3
**Plans:** TBD

#### Phase 5: Smart Pantry (iOS)
**Goal:** iOS users can scan fridge/receipts, manage digital pantry, and receive expiry alerts
**Depends on:** Phase 4
**Plans:** TBD

#### Phase 6: Personalization Engine
**Goal:** Feed adapts to user preferences through dietary settings and learned taste profile
**Depends on:** Phase 4
**Plans:** TBD

#### Phase 7: Accessibility & Polish (iOS)
**Goal:** iOS app meets WCAG AAA standards and is fully usable by 75+ year-old users
**Depends on:** Phase 4, Phase 5
**Plans:** TBD

#### Phase 8: Monetization
**Goal:** Free tier with ads and Pro subscription tier are operational with App Store billing
**Depends on:** Phase 7
**Plans:** TBD

#### Phase 9: Android App (Core Parity)
**Goal:** Android users can browse feed, view recipes, and cook with voice narration
**Depends on:** Phase 1, Phase 2, Phase 3
**Plans:** TBD

#### Phase 10: Android Pantry & Full Parity
**Goal:** Android achieves 100% feature parity with iOS including pantry and personalization
**Depends on:** Phase 9
**Plans:** TBD

---

## Progress Table

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation | v1.5 | 5/5 | Complete | 2026-02-28 |
| 2. Feed Engine | v1.5 | 3/3 | Complete | 2026-03-01 |
| 3. Voice Core | v1.5 | 3/3 | Complete | 2026-03-01 |
| 4. iOS App | TBD | 0/? | Not started | - |
| 5. Smart Pantry | TBD | 0/? | Not started | - |
| 6. Personalization | TBD | 0/? | Not started | - |
| 7. Accessibility | TBD | 0/? | Not started | - |
| 8. Monetization | TBD | 0/? | Not started | - |
| 9. Android Core | TBD | 0/? | Not started | - |
| 10. Android Full | TBD | 0/? | Not started | - |

---

## Notes

**Platform Strategy:**
- iOS ships first (Phases 4-8)
- Android begins after iOS core (shared backend ready from v1.5)
- Android Phases 9-10 run in parallel with iOS Phases 5-8
- Both platforms share: Backend API, voice generation, image generation, scraping pipeline, authentication

**Critical Dependencies:**
- ElevenLabs API for voice cloning (cost: ~$0.01-0.03/recipe)
- Gemini 3 Flash for vision (fridge scan ~85-90% accuracy, receipt ~95%+)
- Instagram/X scraping via X API + Gemini parser (abstraction layer built)
- Backend: Custom NestJS with PostgreSQL + Prisma (validated in v1.5)

---

*Roadmap created: 2026-02-28*
*v1.5 shipped: 2026-03-01*
