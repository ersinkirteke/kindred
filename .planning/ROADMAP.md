# Roadmap: Kindred

**Project:** Kindred — Hyperlocal AI-Humanized Culinary Assistant
**Created:** 2026-02-28
**Depth:** Comprehensive (native iOS + Android, shared backend)

## Milestones

- ✅ **v1.5 Backend & AI Pipeline** — Phases 1-3 (shipped 2026-03-01)
- 🚧 **v2.0 iOS App** — Phases 4-10 (in progress)
- 📋 **v2.1 Pantry & Android** — TBD

## Phases

<details>
<summary>✅ v1.5 Backend & AI Pipeline (Phases 1-3) — SHIPPED 2026-03-01</summary>

- [x] Phase 1: Foundation (5/5 plans) — Backend API, auth, scraping, image gen, push notifications
- [x] Phase 2: Feed Engine (3/3 plans) — PostGIS geospatial, velocity ranking, feed GraphQL API
- [x] Phase 3: Voice Core (3/3 plans) — ElevenLabs cloning, voice upload pipeline, narration streaming

**Total:** 3 phases, 11 plans, 20/20 requirements satisfied
**Archive:** `.planning/milestones/v1.5-ROADMAP.md`

</details>

### 🚧 v2.0 iOS App (In Progress)

**Milestone Goal:** Put Kindred in users' hands — the full iOS experience with feed, voice playback, personalization, accessibility, and monetization.

- [ ] **Phase 4: Foundation & Architecture** - SwiftUI + TCA structure, Apollo iOS GraphQL client, theme system
- [ ] **Phase 5: Guest Browsing & Feed** - Guest mode, swipe cards, recipe discovery, location-based feed
- [ ] **Phase 6: Dietary Filtering & Personalization** - Dietary preferences, Culinary DNA learning from implicit feedback
- [ ] **Phase 7: Voice Playback & Streaming** - Voice narration streaming, background audio, offline caching
- [ ] **Phase 8: Authentication & Onboarding** - Google/Apple OAuth, guest-to-account conversion, sub-90s onboarding
- [ ] **Phase 9: Monetization & Voice Tiers** - Free tier with ads, Pro subscription, StoreKit 2, voice slot enforcement
- [ ] **Phase 10: Accessibility & Polish** - WCAG AAA audit, VoiceOver polish, Dynamic Type testing, production readiness

## Phase Details

### Phase 4: Foundation & Architecture
**Goal**: Establish iOS app architecture and core infrastructure for all features
**Depends on**: Phase 3 (backend voice cloning complete)
**Requirements**: None (infrastructure only)
**Success Criteria** (what must be TRUE):
  1. App launches with SwiftUI + TCA project structure and modular Swift Package Manager setup
  2. Apollo iOS GraphQL client successfully authenticates with backend using Clerk JWT tokens
  3. Shared UI theme (cream/terracotta palette, typography, 56dp button components) is applied app-wide
  4. Navigation structure (2-tab bottom nav: Feed, Me) is functional
**Plans**: 4 plans

Plans:
- [x] 04-01-PLAN.md — Xcode project + SPM modules + TCA root navigation (✓ 2026-03-01, 12 min)
- [x] 04-02-PLAN.md — Design system (colors, typography, reusable components) (✓ 2026-03-01, 13 min)
- [ ] 04-03-PLAN.md — Apollo GraphQL client + Clerk auth + Kingfisher config
- [ ] 04-04-PLAN.md — App shell (splash, welcome card, themed tabs, visual verification)

### Phase 5: Guest Browsing & Feed
**Goal**: Users can browse viral recipes and explore the feed without creating an account
**Depends on**: Phase 4
**Requirements**: AUTH-01, FEED-01, FEED-02, FEED-03, FEED-04, FEED-05, FEED-06, FEED-08, ACCS-01, ACCS-04
**Success Criteria** (what must be TRUE):
  1. Guest user sees viral recipes trending within 5-10 miles of their location with AI hero images, prep time, calories, VIRAL badges
  2. User can swipe left to skip and swipe right to bookmark recipe cards OR use Listen/Watch/Skip buttons (56dp touch targets)
  3. User can view recipe details (ingredients, instructions) in maximum 2 taps from feed
  4. User's location displays as city badge at top of feed and can be manually changed to explore other areas
  5. Feed loads cached content when offline with clear offline indicator
**Plans**: 4 plans

Plans:
- [ ] 05-01-PLAN.md — Guest session infrastructure, location/network TCA dependencies, domain types
- [ ] 05-02-PLAN.md — Swipe card stack, FeedReducer, RecipeCardView, action buttons, accessibility
- [ ] 05-03-PLAN.md — Recipe detail view with parallax hero, ingredients checklist, step timeline
- [ ] 05-04-PLAN.md — Location picker, feed-to-detail navigation, Me tab badge, visual verification

### Phase 6: Dietary Filtering & Personalization
**Goal**: Feed adapts to user dietary preferences and learns taste from implicit feedback
**Depends on**: Phase 5
**Requirements**: FEED-07, PERS-01, PERS-02, PERS-03
**Success Criteria** (what must be TRUE):
  1. User can filter recipes by dietary preference (vegan, keto, halal, allergies) with filters persisting across sessions
  2. App learns user taste from skips and bookmarks via Culinary DNA (after 50+ interactions)
  3. Feed ranking adapts over time based on Culinary DNA profile (similar cuisines surface more, disliked patterns surface less)
**Plans**: TBD

Plans:
- [ ] 06-01: TBD
- [ ] 06-02: TBD

### Phase 7: Voice Playback & Streaming
**Goal**: Users listen to recipe narrations in cloned voices with full audio playback controls
**Depends on**: Phase 5
**Requirements**: VOICE-01, VOICE-02, VOICE-03, VOICE-04, VOICE-05, VOICE-06, ACCS-02, ACCS-03
**Success Criteria** (what must be TRUE):
  1. User can listen to any recipe's instructions narrated in their cloned voice with streaming playback from Cloudflare R2
  2. Voice narration displays play/pause/seek controls (64dp play button, 18sp+ text labels) with speaker name prominently shown
  3. Voice playback continues in background with lock screen controls (play/pause, seek, Now Playing info)
  4. Voice profiles cache locally for offline narration playback (downloaded audio files persist)
  5. VoiceOver users can navigate audio controls with meaningful labels and hints
**Plans**: TBD

Plans:
- [ ] 07-01: TBD
- [ ] 07-02: TBD
- [ ] 07-03: TBD

### Phase 8: Authentication & Onboarding
**Goal**: Users complete onboarding in under 90 seconds and seamlessly convert from guest to account
**Depends on**: Phase 5, Phase 7
**Requirements**: AUTH-02, AUTH-03, AUTH-04, AUTH-05, AUTH-06
**Success Criteria** (what must be TRUE):
  1. User can sign in with Google OAuth or Apple Sign In via one-tap authentication
  2. Guest user is prompted to create account when saving, bookmarking, or using voice features with frictionless conversion
  3. Guest session state (browsed recipes, dietary preferences, bookmarks) persists through account conversion (no data loss)
  4. New user completes onboarding flow in under 90 seconds (welcome → dietary prefs → location → optional voice upload → start)
**Plans**: TBD

Plans:
- [ ] 08-01: TBD
- [ ] 08-02: TBD

### Phase 9: Monetization & Voice Tiers
**Goal**: Free and Pro tiers operational with App Store billing and voice slot enforcement
**Depends on**: Phase 8
**Requirements**: MONET-01, MONET-02, MONET-03, MONET-04, VOICE-07
**Success Criteria** (what must be TRUE):
  1. Free tier displays AdMob ads in non-intrusive placements (between recipe cards, not during voice playback)
  2. User can subscribe to Pro ($9.99/mo) via StoreKit 2 App Store billing with subscription status syncing to backend
  3. Pro tier removes all ads and unlocks unlimited voice slots (Free tier has 1 voice slot)
  4. Subscription status persists across app restarts and device changes via JWS verification
**Plans**: TBD

Plans:
- [ ] 09-01: TBD
- [ ] 09-02: TBD

### Phase 10: Accessibility & Polish
**Goal**: App meets WCAG AAA standards and is production-ready for App Store submission
**Depends on**: Phase 4, Phase 5, Phase 6, Phase 7, Phase 8, Phase 9
**Requirements**: ACCS-05
**Success Criteria** (what must be TRUE):
  1. All screens pass WCAG AAA color contrast audit (7:1 ratio for body text, 4.5:1 for large text)
  2. VoiceOver navigation works correctly on all screens with meaningful labels and reading order
  3. All text scales correctly with Dynamic Type at accessibility sizes (AX1-AX5) without layout breaking
  4. App handles offline mode gracefully with cached content and clear indicators across all features
  5. App passes App Store review requirements (privacy labels, ATT consent, metadata complete)
**Plans**: TBD

Plans:
- [ ] 10-01: TBD
- [ ] 10-02: TBD

---

## Progress Table

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation | v1.5 | 5/5 | Complete | 2026-02-28 |
| 2. Feed Engine | v1.5 | 3/3 | Complete | 2026-03-01 |
| 3. Voice Core | v1.5 | 3/3 | Complete | 2026-03-01 |
| 4. Foundation & Architecture | v2.0 | 0/4 | Planned | - |
| 5. Guest Browsing & Feed | 1/4 | In Progress|  | - |
| 6. Dietary Filtering & Personalization | v2.0 | 0/? | Not started | - |
| 7. Voice Playback & Streaming | v2.0 | 0/? | Not started | - |
| 8. Authentication & Onboarding | v2.0 | 0/? | Not started | - |
| 9. Monetization & Voice Tiers | v2.0 | 0/? | Not started | - |
| 10. Accessibility & Polish | v2.0 | 0/? | Not started | - |

---

## Notes

**v2.0 iOS App Strategy:**
- Phase 4-10 deliver complete iOS experience (7 phases, 33 requirements)
- Accessibility integrated throughout (ACCS-01-04 in Phases 5, 7) + final audit (Phase 10)
- Guest browsing enables immediate value delivery (no forced signup)
- Onboarding deferred until Phase 8 (users experience product before converting)
- Monetization comes after core features proven (Phase 9)
- Backend/API/AI pipeline 100% ready from v1.5 (GraphQL, voice cloning, feed engine)

**Platform Strategy:**
- iOS ships first (v2.0 milestone: Phases 4-10)
- Android fast-follow in v2.x milestone (4-6 weeks after iOS)
- Backend is 100% shared between platforms (validated in v1.5)

**Critical Dependencies:**
- SwiftUI + TCA 1.x architecture (iOS 17.0+ minimum per Clerk SDK requirement)
- Apollo iOS 2.0.6 for GraphQL (SQLite cache, offline-first)
- AVFoundation for voice streaming (AVPlayer, background audio session)
- StoreKit 2 for subscriptions (JWS validation, Transaction.updates monitoring)
- ElevenLabs voice cloning from v1.5 backend (~$0.01-0.03/recipe)

---

*Roadmap created: 2026-02-28*
*v1.5 shipped: 2026-03-01*
*v2.0 iOS App roadmap: 2026-03-01*
