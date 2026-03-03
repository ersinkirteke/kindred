# Requirements: Kindred

**Defined:** 2026-03-01
**Core Value:** Hearing a loved one's voice guide you through a trending local recipe — that emotional moment is what makes Kindred irreplaceable.

## v2.0 Requirements

Requirements for iOS App milestone. Each maps to roadmap phases.

### Authentication & Onboarding

- [x] **AUTH-01**: User can browse the recipe feed as a guest without creating an account
- [ ] **AUTH-02**: User can sign in with Google OAuth (one-tap)
- [ ] **AUTH-03**: User can sign in with Apple Sign In (one-tap)
- [ ] **AUTH-04**: Guest user is prompted to create account when saving, bookmarking, or using voice features
- [ ] **AUTH-05**: Guest session state (browsed recipes, preferences) persists through account conversion
- [ ] **AUTH-06**: User completes onboarding flow in under 90 seconds (dietary prefs, location, optional voice upload)

### Feed & Discovery

- [x] **FEED-01**: User sees viral recipes trending within 5-10 miles of their location
- [x] **FEED-02**: Each recipe card displays AI hero image, recipe name, prep time, calories, loves count, and VIRAL badge
- [x] **FEED-03**: User can swipe left to skip and swipe right to bookmark recipe cards
- [x] **FEED-04**: User can tap Listen/Watch/Skip buttons as swipe alternatives
- [x] **FEED-05**: User's location is shown as a city badge at the top of the feed
- [x] **FEED-06**: User can manually change their location to explore other areas
- [x] **FEED-07**: User can filter recipes by dietary preference (vegan, keto, halal, allergies)
- [x] **FEED-08**: Feed loads cached content when offline with clear offline indicator

### Voice Experience

- [x] **VOICE-01**: User can listen to any recipe's instructions narrated in their cloned voice
- [x] **VOICE-02**: Voice narration streams in real-time with play/pause/seek controls and 64dp play button
- [x] **VOICE-03**: Voice narration displays the speaker's name prominently during playback
- [ ] **VOICE-04**: Voice playback continues in background with lock screen controls
- [x] **VOICE-05**: Voice profiles are cached locally for offline narration playback
- [x] **VOICE-06**: User can upload a 30-60 second voice clip to create a voice profile
- [ ] **VOICE-07**: Free tier users get 1 voice slot; Pro users get unlimited voice slots

### Personalization

- [x] **PERS-01**: App learns user taste from implicit feedback (skips and bookmarks) via Culinary DNA
- [x] **PERS-02**: Feed ranking adapts based on user's Culinary DNA profile over time
- [x] **PERS-03**: User can set dietary preferences during onboarding or in settings (vegan, keto, halal, allergies)

### Accessibility

- [x] **ACCS-01**: All interactive elements have minimum 56dp touch targets (WCAG AAA)
- [x] **ACCS-02**: All body text is minimum 18sp with Dynamic Type support
- [x] **ACCS-03**: Full VoiceOver support with meaningful labels on all custom controls and gestures
- [x] **ACCS-04**: Navigation depth is maximum 3 levels from any screen
- [ ] **ACCS-05**: Color contrast meets WCAG AAA 7:1 ratio

### Monetization

- [ ] **MONET-01**: Free tier displays ads (AdMob) in non-intrusive placements
- [ ] **MONET-02**: Pro tier ($9.99/mo) removes ads and unlocks unlimited voice slots
- [ ] **MONET-03**: User can subscribe to Pro via App Store billing (StoreKit 2)
- [ ] **MONET-04**: Subscription status syncs between app and backend via JWS verification

## Future Requirements

Deferred to future milestones. Tracked but not in current roadmap.

### Pantry & Ingredients (v2.1)

- **PANT-01**: User can scan fridge photo to identify ingredients (Gemini 3 Flash)
- **PANT-02**: User can scan supermarket receipt to populate digital pantry
- **PANT-03**: User receives push notification alerts for food expiry

### Android (v2.x)

- **ANDR-01**: Android full feature parity with iOS

### Social & Integrations (v3.0)

- **SOCL-01**: User can share recipes externally
- **SOCL-02**: User can follow other users
- **INTG-01**: Instacart/UberEats "Order Ingredients" integration

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| AI cooking video generation (Veo) | $4.50-9/user/month cost, 30-120s latency, cooking safety |
| In-app recipe creation | Content moderation, quality control, liability |
| Real-time chat / community | High complexity, not core to emotional utility |
| Map view for recipe discovery | Cognitive overload, location privacy concerns |
| In-app voice recording | iOS permissions complexity, audio quality issues |
| Auto-play voice narration | Startles users, accessibility conflict with screen readers |
| Mandatory onboarding tutorial | Kills D7 retention, high drop-off |
| Complex filtering UI | Cognitive overload for 65% of users who prefer defaults |
| Web app | Mobile-first, native only for v2.0 |
| Cross-platform framework | Native iOS + Android for best UX and accessibility |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUTH-01 | Phase 5 | Complete |
| AUTH-02 | Phase 8 | Pending |
| AUTH-03 | Phase 8 | Pending |
| AUTH-04 | Phase 8 | Pending |
| AUTH-05 | Phase 8 | Pending |
| AUTH-06 | Phase 8 | Pending |
| FEED-01 | Phase 5 | Complete |
| FEED-02 | Phase 5 | Complete |
| FEED-03 | Phase 5 | Complete |
| FEED-04 | Phase 5 | Complete |
| FEED-05 | Phase 5 | Complete |
| FEED-06 | Phase 5 | Complete |
| FEED-07 | Phase 6 | Complete |
| FEED-08 | Phase 5 | Complete |
| VOICE-01 | Phase 7 | Complete |
| VOICE-02 | Phase 7 | Complete |
| VOICE-03 | Phase 7 | Complete |
| VOICE-04 | Phase 7 | Pending |
| VOICE-05 | Phase 7 | Complete |
| VOICE-06 | Phase 7 | Complete |
| VOICE-07 | Phase 9 | Pending |
| PERS-01 | Phase 6 | Complete |
| PERS-02 | Phase 6 | Complete |
| PERS-03 | Phase 6 | Complete |
| ACCS-01 | Phase 5 | Pending (baked in) |
| ACCS-02 | Phase 7 | Pending (baked in) |
| ACCS-03 | Phase 7 | Pending (baked in) |
| ACCS-04 | Phase 5 | Pending (baked in) |
| ACCS-05 | Phase 10 | Pending |
| MONET-01 | Phase 9 | Pending |
| MONET-02 | Phase 9 | Pending |
| MONET-03 | Phase 9 | Pending |
| MONET-04 | Phase 9 | Pending |

**Coverage:**
- v2.0 requirements: 33 total
- Mapped to phases: 33
- Unmapped: 0
- Infrastructure phase (Phase 4): 0 requirements (foundation only)
- Requirements distributed: Phase 5 (8), Phase 6 (4), Phase 7 (6), Phase 8 (5), Phase 9 (5), Phase 10 (1), Accessibility baked in (4)

**Notes:**
- ACCS-01, ACCS-02, ACCS-03, ACCS-04 are integrated into phases 5 and 7 (not deferred to Phase 10)
- Phase 4 is infrastructure only (no functional requirements)
- Phase 10 focuses on ACCS-05 (color contrast) audit and final polish

---
*Requirements defined: 2026-03-01*
*Last updated: 2026-03-01 after v2.0 roadmap creation*
