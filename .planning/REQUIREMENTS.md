# Requirements: Kindred

**Defined:** 2026-02-28
**Core Value:** Hearing a loved one's voice guide you through a trending local recipe — that emotional moment is what makes Kindred irreplaceable.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Authentication

- [ ] **AUTH-01**: User can browse the recipe feed as a guest without creating an account
- [ ] **AUTH-02**: User can sign up / sign in via Google OAuth (one-tap)
- [ ] **AUTH-03**: User can sign up / sign in via Apple Sign In
- [ ] **AUTH-04**: Guest user is prompted to create account when attempting to save, bookmark, or use voice features
- [x] **AUTH-05**: User session persists across app restarts

### Hyperlocal Feed

- [x] **FEED-01**: User sees viral recipes trending within a 5-10 mile radius of their location
- [ ] **FEED-02**: Each recipe card displays AI-generated hero image, recipe name, prep time, calories, and "loves this week" count
- [ ] **FEED-03**: Trending recipes display a "VIRAL" badge based on local engagement metrics
- [ ] **FEED-04**: User can swipe left to skip a recipe or swipe right to bookmark it
- [ ] **FEED-05**: User can tap Listen, Watch (placeholder for v2 video), or Skip buttons as alternative to swiping
- [ ] **FEED-06**: User can filter recipes by category (cuisine type, meal type, dietary tags)
- [x] **FEED-07**: User's location is shown at the top of the feed (city badge)
- [x] **FEED-08**: User can manually change their location to explore other areas
- [ ] **FEED-09**: Feed loads cached content when offline with clear offline indicator

### Voice Narrator

- [ ] **VOICE-01**: User can upload a 30-60 second voice clip of a loved one during onboarding or from profile
- [ ] **VOICE-02**: App clones the uploaded voice using ElevenLabs API and stores the voice profile
- [ ] **VOICE-03**: User can listen to any recipe's instructions narrated in their cloned voice
- [ ] **VOICE-04**: Voice narration streams in real-time with play/pause/seek controls (64dp play button)
- [ ] **VOICE-05**: Voice narration displays the speaker's name prominently during playback
- [ ] **VOICE-06**: Free tier users get 1 voice slot; Pro users get unlimited voice slots
- [ ] **VOICE-07**: User can re-record or replace their voice clip to improve quality

### Smart Pantry

- [ ] **PNTR-01**: User can take a photo of their fridge and AI identifies visible ingredients (Gemini 3 Flash)
- [ ] **PNTR-02**: User can scan a supermarket receipt and AI extracts purchased items into their digital pantry
- [ ] **PNTR-03**: Digital pantry displays all tracked ingredients with estimated expiry dates
- [ ] **PNTR-04**: User can manually add, edit, or remove items from their pantry
- [ ] **PNTR-05**: App sends push notification when food items are approaching expiry (2 days before)
- [ ] **PNTR-06**: App suggests recipes that use ingredients nearing expiry ("Save your heavy cream with Mom's Creamy Tuscan Chicken")
- [ ] **PNTR-07**: Fridge scan results show confidence level and let user correct misidentified items

### Personalization

- [ ] **PRSN-01**: User sets dietary preferences during onboarding (allergies, diet type: vegan, keto, halal, gluten-free, etc.)
- [ ] **PRSN-02**: User sets cooking skill level during onboarding (beginner, intermediate, advanced)
- [ ] **PRSN-03**: Feed automatically filters out recipes conflicting with dietary preferences
- [ ] **PRSN-04**: Feed prioritizes recipes matching user's skill level
- [ ] **PRSN-05**: App tracks skip/bookmark behavior to build "Culinary DNA" taste profile
- [ ] **PRSN-06**: After 10+ interactions, feed adapts to learned preferences (e.g., stops showing cilantro recipes if user consistently skips them)
- [ ] **PRSN-07**: User can view and edit their taste profile from settings

### Monetization

- [ ] **MNTZ-01**: Free tier provides full feed access, AI images, 1 voice slot, fridge scan (limited to 3/week), and basic pantry
- [ ] **MNTZ-02**: Pro tier ($9.99/month) unlocks unlimited voice slots, unlimited scans, expiry alerts, ad-free experience
- [ ] **MNTZ-03**: Pro subscription managed via App Store (iOS) and Google Play (Android) billing
- [ ] **MNTZ-04**: User can upgrade/downgrade between tiers from profile settings
- [ ] **MNTZ-05**: Paywall is soft — user encounters it naturally when hitting free tier limits, not on first launch

### Accessibility

- [ ] **ACCS-01**: All touch targets are minimum 56dp (primary actions 64dp)
- [ ] **ACCS-02**: Body text is minimum 18sp, never smaller
- [ ] **ACCS-03**: Full VoiceOver (iOS) and TalkBack (Android) support with semantic grouping
- [ ] **ACCS-04**: Dynamic Type (iOS) and text scaling up to 200% (Android) supported
- [ ] **ACCS-05**: Maximum 2 taps from feed to start cooking with voice narration
- [ ] **ACCS-06**: No icon-only buttons — all icons have visible text labels
- [ ] **ACCS-07**: High contrast mode meeting WCAG AAA standards
- [ ] **ACCS-08**: Swipe gestures always have explicit button alternatives

### Onboarding

- [ ] **ONBR-01**: Onboarding flow: location permission → dietary preferences → skill level → voice upload (skippable)
- [ ] **ONBR-02**: Each onboarding step is completable in a single screen with large, clear options
- [ ] **ONBR-03**: User can skip voice upload and use app without voice narration
- [ ] **ONBR-04**: Onboarding is completable in under 90 seconds

### Backend & Infrastructure

- [x] **INFR-01**: Backend API serves both iOS and Android with shared data models
- [x] **INFR-02**: Recipe scraping pipeline discovers trending recipes from Instagram/X by location
- [x] **INFR-03**: AI image generation pipeline creates hero images for each scraped recipe
- [x] **INFR-04**: App functions with degraded experience when scraping sources are unavailable (cached/curated fallback)
- [ ] **INFR-05**: Voice profiles and audio cached locally for offline narration of previously played recipes
- [x] **INFR-06**: Push notification infrastructure for expiry alerts and engagement nudges

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### AI Video

- **VIDO-01**: User can watch AI-generated 15-second cooking overview video for any recipe
- **VIDO-02**: User can tap a confusing step to see a 5-second AI-generated technique clip
- **VIDO-03**: Pre-generated video library for top 500 recipes

### Social

- **SOCL-01**: User can share a recipe card with voice preview to social media
- **SOCL-02**: User can see which recipes friends are cooking
- **SOCL-03**: Shared recipe link deep-links into the app

### Partnerships

- **PART-01**: "Order Ingredients" button integration with Instacart/UberEats
- **PART-02**: Affiliate commission tracking (3-5% per order)
- **PART-03**: Local grocery store coupon integration in free tier

## Out of Scope

| Feature | Reason |
|---------|--------|
| AI cooking video (Veo) | $4.50-9/user/month cost, 30-120s latency, cooking safety risk with AI-generated techniques |
| Cross-platform framework | Native iOS + Android chosen for best UX and accessibility |
| Web app | Mobile-first strategy, native only |
| Real-time chat/community | High complexity, not core to emotional utility value |
| Meal planning/calendar | Feature creep — Kindred is discovery-first, not planning-first |
| Grocery delivery integration | Requires partnership deals, defer to v2 |
| User-generated recipe uploads | Content moderation complexity, keep feed curated from social trends |
| Email/password authentication | Social login + guest mode is simpler and faster for elderly users |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUTH-01 | Phase 4, Phase 9 | Pending |
| AUTH-02 | Phase 4, Phase 9 | Pending |
| AUTH-03 | Phase 4, Phase 9 | Pending |
| AUTH-04 | Phase 4, Phase 9 | Pending |
| AUTH-05 | Phase 1 | Complete |
| FEED-01 | Phase 2, Phase 9 | Complete |
| FEED-02 | Phase 2, Phase 9 | Pending |
| FEED-03 | Phase 2, Phase 9 | Pending |
| FEED-04 | Phase 4, Phase 9 | Pending |
| FEED-05 | Phase 4, Phase 9 | Pending |
| FEED-06 | Phase 2, Phase 9 | Pending |
| FEED-07 | Phase 2, Phase 9 | Complete |
| FEED-08 | Phase 2, Phase 9 | Complete |
| FEED-09 | Phase 2, Phase 9 | Pending |
| VOICE-01 | Phase 3, Phase 9 | Pending |
| VOICE-02 | Phase 3, Phase 9 | Pending |
| VOICE-03 | Phase 3, Phase 9 | Pending |
| VOICE-04 | Phase 3, Phase 9 | Pending |
| VOICE-05 | Phase 3, Phase 9 | Pending |
| VOICE-06 | Phase 3, Phase 9 | Pending |
| VOICE-07 | Phase 3, Phase 9 | Pending |
| PNTR-01 | Phase 5, Phase 10 | Pending |
| PNTR-02 | Phase 5, Phase 10 | Pending |
| PNTR-03 | Phase 5, Phase 10 | Pending |
| PNTR-04 | Phase 5, Phase 10 | Pending |
| PNTR-05 | Phase 5, Phase 10 | Pending |
| PNTR-06 | Phase 5, Phase 10 | Pending |
| PNTR-07 | Phase 5, Phase 10 | Pending |
| PRSN-01 | Phase 6, Phase 10 | Pending |
| PRSN-02 | Phase 6, Phase 10 | Pending |
| PRSN-03 | Phase 6, Phase 10 | Pending |
| PRSN-04 | Phase 6, Phase 10 | Pending |
| PRSN-05 | Phase 6, Phase 10 | Pending |
| PRSN-06 | Phase 6, Phase 10 | Pending |
| PRSN-07 | Phase 6, Phase 10 | Pending |
| MNTZ-01 | Phase 8, Phase 10 | Pending |
| MNTZ-02 | Phase 8, Phase 10 | Pending |
| MNTZ-03 | Phase 8, Phase 10 | Pending |
| MNTZ-04 | Phase 8, Phase 10 | Pending |
| MNTZ-05 | Phase 8, Phase 10 | Pending |
| ACCS-01 | Phase 7, Phase 10 | Pending |
| ACCS-02 | Phase 7, Phase 10 | Pending |
| ACCS-03 | Phase 7, Phase 10 | Pending |
| ACCS-04 | Phase 7, Phase 10 | Pending |
| ACCS-05 | Phase 7, Phase 10 | Pending |
| ACCS-06 | Phase 7, Phase 10 | Pending |
| ACCS-07 | Phase 7, Phase 10 | Pending |
| ACCS-08 | Phase 7, Phase 10 | Pending |
| ONBR-01 | Phase 4, Phase 9 | Pending |
| ONBR-02 | Phase 4, Phase 9 | Pending |
| ONBR-03 | Phase 4, Phase 9 | Pending |
| ONBR-04 | Phase 4, Phase 9 | Pending |
| INFR-01 | Phase 1 | Complete |
| INFR-02 | Phase 1 | Complete |
| INFR-03 | Phase 1 | Complete |
| INFR-04 | Phase 1 | Complete |
| INFR-05 | Backend (shared) | Pending |
| INFR-06 | Phase 1 | Complete |

**Coverage:**
- v1 requirements: 46 total
- Mapped to phases: 46
- Unmapped: 0 ✓

**Note:** Some requirements appear in multiple phases because they must be implemented on both iOS (Phases 4-8) and Android (Phases 9-10). Backend requirements (Phase 1-3) are shared across both platforms.

---
*Requirements defined: 2026-02-28*
*Last updated: 2026-02-28 after roadmap creation*
