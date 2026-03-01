# Roadmap: Kindred

**Project:** Kindred — Hyperlocal AI-Humanized Culinary Assistant
**Created:** 2026-02-28
**Depth:** Comprehensive (native iOS + Android, shared backend)

## Project Summary

Kindred is a mobile app that discovers viral recipes trending in your neighborhood and presents them with AI-generated imagery, narrated in the cloned voice of someone you love. Core differentiator: hearing a loved one's voice guide you through cooking creates an irreplaceable emotional connection.

**Platform Strategy:** iOS first (SwiftUI + TCA), Android fast-follow 4-6 weeks (Compose + MVVM/Clean/Hilt), 100% shared backend/API/AI pipeline.

**v1 Scope:** 46 requirements across 9 categories. AI video (Veo) explicitly OUT of v1 due to cost/latency concerns.

---

## Phases

- [x] **Phase 1: Foundation** - Backend API, auth, infrastructure
- [ ] **Phase 2: Feed Engine** - Hyperlocal viral recipe discovery
- [ ] **Phase 3: Voice Core** - ElevenLabs cloning + narration playback
- [ ] **Phase 4: iOS App (Primary Features)** - Feed, recipe detail, voice player
- [ ] **Phase 5: Smart Pantry (iOS)** - Camera scan, receipt OCR, inventory management
- [ ] **Phase 6: Personalization Engine** - Culinary DNA, dietary filtering
- [ ] **Phase 7: Accessibility & Polish (iOS)** - WCAG AAA compliance, onboarding refinement
- [ ] **Phase 8: Monetization** - Free tier ads, Pro tier subscription
- [ ] **Phase 9: Android App (Core Parity)** - Feed, recipe detail, voice player
- [ ] **Phase 10: Android Pantry & Full Parity** - Complete feature set on Android

---

## Phase Details

### Phase 1: Foundation
**Goal:** Backend API serving both platforms with authentication, database, and core infrastructure operational

**Depends on:** Nothing (first phase)

**Requirements:** INFR-01, INFR-02, INFR-03, INFR-04, INFR-06, AUTH-05

**Success Criteria** (what must be TRUE):
1. API endpoints respond to authenticated requests from iOS and Android test clients
2. Recipe scraping pipeline discovers trending content from Instagram/X by location
3. AI image generation pipeline creates hero images for scraped recipes
4. App continues to function with cached content when scraping sources are unavailable
5. Push notification infrastructure sends test notifications to registered devices

**Plans:** 5 plans

Plans:
- [x] 01-01-PLAN.md — NestJS scaffold, Prisma schema, Docker, GraphQL API
- [x] 01-02-PLAN.md — Clerk authentication, session persistence, webhook user sync
- [x] 01-03-PLAN.md — Recipe scraping pipeline (X API + Gemini parser) with fallback strategy
- [x] 01-04-PLAN.md — AI hero image generation (Imagen 4 Fast) + Cloudflare R2 storage
- [x] 01-05-PLAN.md — Push notifications (FCM/APNs) + GitHub Actions CI/CD

---

### Phase 2: Feed Engine
**Goal:** Users can discover viral recipes trending within their neighborhood

**Depends on:** Phase 1

**Requirements:** FEED-01, FEED-02, FEED-03, FEED-06, FEED-07, FEED-08, FEED-09

**Success Criteria** (what must be TRUE):
1. User sees recipes trending within 5-10 miles of their current location
2. Each recipe card displays AI hero image, name, prep time, calories, and local engagement count
3. Recipes with high local velocity display a "VIRAL" badge
4. User can filter feed by cuisine type, meal type, and dietary tags
5. User's current city/neighborhood is visible at top of feed
6. User can manually change location to explore other areas
7. Feed displays cached recipes with offline indicator when network unavailable

**Plans:** 3 plans

Plans:
- [ ] 02-01-PLAN.md — PostGIS geospatial support, CuisineType/MealType enums, Mapbox geocoding service
- [ ] 02-02-PLAN.md — Velocity scorer, AI cuisine/meal tagging, scraping pipeline geocoding integration
- [ ] 02-03-PLAN.md — Feed GraphQL API with geo-radius queries, cursor pagination, filters, offline cache headers

---

### Phase 3: Voice Core
**Goal:** Users can clone a loved one's voice and hear recipes narrated in that voice

**Depends on:** Phase 1

**Requirements:** VOICE-01, VOICE-02, VOICE-03, VOICE-04, VOICE-05, VOICE-06, VOICE-07

**Success Criteria** (what must be TRUE):
1. User uploads 30-60 second voice sample and receives confirmation of successful clone
2. User can play recipe instructions narrated in their cloned voice with <5 second latency
3. Voice narration streams with play/pause/seek controls and 64dp play button
4. Speaker's name displays prominently during playback
5. Free tier users can store 1 voice; Pro users can store unlimited voices
6. User can re-record voice sample if quality is unsatisfactory

**Plans:** 3 plans

Plans:
- [ ] 03-01-PLAN.md — VoiceProfile schema, ElevenLabs API client, R2 voice storage
- [ ] 03-02-PLAN.md — Voice upload pipeline, background cloning, tier enforcement, voice management
- [ ] 03-03-PLAN.md — Narration service (Gemini rewrite + ElevenLabs streaming TTS)

---

### Phase 4: iOS App (Primary Features)
**Goal:** iOS users can browse feed, view recipe details, and cook with voice narration

**Depends on:** Phase 2, Phase 3

**Requirements:** AUTH-01, AUTH-02, AUTH-03, AUTH-04, FEED-04, FEED-05, ONBR-01, ONBR-02, ONBR-03, ONBR-04

**Success Criteria** (what must be TRUE):
1. Guest users browse recipe feed without creating account
2. Users sign in via Google OAuth or Apple Sign In with one tap
3. Guest users are prompted to create account when bookmarking or using voice features
4. Users can swipe left to skip or swipe right to bookmark recipe cards
5. Users can tap Listen, Watch (placeholder), or Skip buttons as swipe alternatives
6. Onboarding flow completes in under 90 seconds (location → dietary prefs → skill → voice upload)
7. Each onboarding step is completable in single screen with large clear options
8. Users can skip voice upload and still use app without narration

**Plans:** TBD

---

### Phase 5: Smart Pantry (iOS)
**Goal:** iOS users can scan fridge/receipts, manage digital pantry, and receive expiry alerts

**Depends on:** Phase 4

**Requirements:** PNTR-01, PNTR-02, PNTR-03, PNTR-04, PNTR-05, PNTR-06, PNTR-07

**Success Criteria** (what must be TRUE):
1. User takes photo of fridge and app identifies visible ingredients with ~85-90% accuracy
2. User scans supermarket receipt and app extracts purchased items into pantry
3. Digital pantry displays all ingredients with estimated expiry dates
4. User can manually add, edit, or remove pantry items
5. App sends push notification 2 days before food items expire
6. App suggests recipes using ingredients nearing expiry with specific call-to-action
7. Fridge scan results show confidence levels and allow user corrections

**Plans:** TBD

---

### Phase 6: Personalization Engine
**Goal:** Feed adapts to user preferences through dietary settings and learned taste profile

**Depends on:** Phase 4

**Requirements:** PRSN-01, PRSN-02, PRSN-03, PRSN-04, PRSN-05, PRSN-06, PRSN-07

**Success Criteria** (what must be TRUE):
1. User sets dietary preferences during onboarding (vegan, keto, halal, allergies, etc.)
2. User sets cooking skill level (beginner, intermediate, advanced)
3. Feed automatically excludes recipes conflicting with dietary preferences
4. Feed prioritizes recipes matching user's skill level
5. After 10+ skip/bookmark interactions, feed visibly adapts (e.g., stops showing disliked ingredients)
6. User can view and edit learned taste profile from settings
7. Taste profile displays cuisine preference percentages and ingredient dislikes

**Plans:** TBD

---

### Phase 7: Accessibility & Polish (iOS)
**Goal:** iOS app meets WCAG AAA standards and is fully usable by 75+ year-old users

**Depends on:** Phase 4, Phase 5

**Requirements:** ACCS-01, ACCS-02, ACCS-03, ACCS-04, ACCS-05, ACCS-06, ACCS-07, ACCS-08

**Success Criteria** (what must be TRUE):
1. All touch targets meet 56dp minimum (primary actions 64dp)
2. All body text is minimum 18sp with no smaller interactive text
3. VoiceOver announces all content with semantic grouping (recipe cards, steps, etc.)
4. App supports Dynamic Type scaling up to 200% without layout breaking
5. User reaches cooking mode with voice narration in maximum 2 taps from feed
6. All icon buttons have visible text labels (no icon-only interactions)
7. High contrast mode meets WCAG AAA 7:1 ratio for all text
8. All swipe gestures have explicit button alternatives visible on screen

**Plans:** TBD

---

### Phase 8: Monetization
**Goal:** Free tier with ads and Pro subscription tier are operational with App Store billing

**Depends on:** Phase 7

**Requirements:** MNTZ-01, MNTZ-02, MNTZ-03, MNTZ-04, MNTZ-05

**Success Criteria** (what must be TRUE):
1. Free tier provides full feed, AI images, 1 voice slot, 3 fridge scans/week, basic pantry
2. Pro tier ($9.99/month) unlocks unlimited voices, unlimited scans, expiry alerts, ad-free
3. Pro subscription processes through App Store billing without manual payment entry
4. User can upgrade or downgrade between tiers from profile settings
5. Paywall appears naturally when hitting free tier limits (not on first launch)
6. Trial period (if offered) converts to paid subscription automatically

**Plans:** TBD

---

### Phase 9: Android App (Core Parity)
**Goal:** Android users can browse feed, view recipes, and cook with voice narration

**Depends on:** Phase 1, Phase 2, Phase 3

**Requirements:** AUTH-01, AUTH-02, AUTH-03, AUTH-04, FEED-01, FEED-02, FEED-03, FEED-04, FEED-05, FEED-06, FEED-07, FEED-08, FEED-09, VOICE-01, VOICE-02, VOICE-03, VOICE-04, VOICE-05, VOICE-06, VOICE-07, ONBR-01, ONBR-02, ONBR-03, ONBR-04

**Success Criteria** (what must be TRUE):
1. Android users browse hyperlocal feed with same UX as iOS (card stack, swipe, buttons)
2. Android users sign in via Google OAuth or Apple Sign In (if available on device)
3. Android users clone voices and hear narration with feature parity to iOS
4. Android onboarding completes in under 90 seconds matching iOS flow
5. Android app respects TalkBack with full semantic descriptions
6. Android app supports text scaling up to 200% without breaking layouts
7. All touch targets meet 56dp minimum on Android
8. Android app uses warm terracotta palette matching iOS design system

**Plans:** TBD

---

### Phase 10: Android Pantry & Full Parity
**Goal:** Android achieves 100% feature parity with iOS including pantry and personalization

**Depends on:** Phase 9

**Requirements:** PNTR-01, PNTR-02, PNTR-03, PNTR-04, PNTR-05, PNTR-06, PNTR-07, PRSN-01, PRSN-02, PRSN-03, PRSN-04, PRSN-05, PRSN-06, PRSN-07, ACCS-01, ACCS-02, ACCS-03, ACCS-04, ACCS-05, ACCS-06, ACCS-07, ACCS-08, MNTZ-01, MNTZ-02, MNTZ-03, MNTZ-04, MNTZ-05

**Success Criteria** (what must be TRUE):
1. Android users scan fridge photos and receipts with accuracy parity to iOS
2. Android users manage digital pantry with expiry alerts via FCM
3. Android users receive personalized feed based on dietary preferences and Culinary DNA
4. Android app meets WCAG AAA accessibility standards
5. Android users can subscribe to Pro tier via Google Play billing
6. Feature matrix shows 100% parity between iOS and Android (same requirements mapped)
7. Performance on budget Android devices (2GB RAM) matches iOS on older iPhones

**Plans:** TBD

---

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 2/5 | In Progress | - |
| 2. Feed Engine | 0/? | Not started | - |
| 3. Voice Core | 0/? | Not started | - |
| 4. iOS App (Primary Features) | 0/? | Not started | - |
| 5. Smart Pantry (iOS) | 0/? | Not started | - |
| 6. Personalization Engine | 0/? | Not started | - |
| 7. Accessibility & Polish (iOS) | 0/? | Not started | - |
| 8. Monetization | 0/? | Not started | - |
| 9. Android App (Core Parity) | 0/? | Not started | - |
| 10. Android Pantry & Full Parity | 0/? | Not started | - |

---

## Notes

**Platform Strategy:**
- iOS ships first (Phases 1-8)
- Android begins after Phase 3 completes (shared backend ready)
- Android Phases 9-10 run in parallel with iOS Phases 5-8
- Both platforms share: Backend API, voice generation, image generation, scraping pipeline, authentication

**Out of v1 Scope:**
- AI video generation (Veo) - deferred to v2 due to $4.50-9/user/month cost and 30-120s latency
- Social features (sharing, following) - deferred to v1.5
- Instacart/UberEats integration - deferred to v2
- Web app - mobile-first, native only

**Critical Dependencies:**
- ElevenLabs API for voice cloning (cost: ~$0.01-0.03/recipe)
- Gemini 3 Flash for vision (fridge scan ~85-90% accuracy, receipt ~95%+)
- Instagram/X scraping via Apify/Browse AI (build abstraction layer - scraping is fragile)
- Backend: Custom NestJS with PostgreSQL + Prisma (decided in Phase 1 planning)

---

*Roadmap created: 2026-02-28*
*Phase 1 planned: 2026-02-28*
