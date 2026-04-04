# Requirements: Kindred

**Defined:** 2026-04-04
**Core Value:** Hearing a loved one's voice guide you through a trending local recipe — that emotional moment is what makes Kindred irreplaceable.

## v5.0 Requirements

Requirements for Lean App Store Launch. Replace expensive backend services with free alternatives and ship to App Store.

### Recipe — Spoonacular Integration

- [x] **RECIPE-01**: User can search recipes by keyword via Spoonacular API
- [x] **RECIPE-02**: User can filter recipes by cuisine, diet type, and intolerances
- [x] **RECIPE-03**: Recipe cards display images from Spoonacular CDN
- [ ] **RECIPE-04**: Recipe cards show popularity score instead of viral badge
- [ ] **RECIPE-05**: Feed displays "Popular Recipes" heading (replaces "Viral near you")
- [x] **RECIPE-06**: Recipe detail shows Spoonacular source attribution with link
- [ ] **RECIPE-07**: User sees ingredient match % on recipe cards based on pantry via Spoonacular findByIngredients

### Cache — Backend Caching & Quota

- [x] **CACHE-01**: Backend caches Spoonacular responses in PostgreSQL with 6-hour TTL
- [x] **CACHE-02**: Backend tracks daily Spoonacular API quota usage (150 req/day)
- [x] **CACHE-03**: App shows graceful "daily limit reached" state when quota exhausted
- [x] **CACHE-04**: Backend pre-warms 100 popular recipes via scheduled batch job

### Voice — Free-Tier Narration

- [ ] **VOICE-01**: Free/guest users hear recipe narration via Apple AVSpeechSynthesizer (on-device, zero cost)
- [ ] **VOICE-02**: AVSpeech narration plays in background with lock screen controls
- [ ] **VOICE-03**: Pro users continue hearing recipes via ElevenLabs cloned voices (existing flow unchanged)
- [ ] **VOICE-04**: App suggests enhanced iOS voice downloads for better free-tier TTS quality
- [ ] **VOICE-05**: Narration uses SSML markup for pauses between steps and emphasis on measurements

### Store — App Store Submission

- [ ] **STORE-01**: Fastlane release lane automates binary upload, metadata sync, and submission
- [ ] **STORE-02**: Privacy Labels and privacy policy updated with Spoonacular as third-party data processor
- [ ] **STORE-03**: App Store screenshots refreshed to reflect "popular recipes" feed
- [ ] **STORE-04**: TestFlight internal beta test completed before App Store submission

## Future Requirements

Deferred to future milestone. Tracked but not in current roadmap.

### Recipe Enhancements

- **RECIPE-08**: User can browse Spoonacular meal plans (weekly/daily)
- **RECIPE-09**: User can save custom recipes to Spoonacular

### Voice Enhancements

- **VOICE-06**: Multi-voice narration (different voices for ingredients vs. steps)
- **VOICE-07**: Pre-cached offline voice synthesis for saved recipes
- **VOICE-08**: Personal Voice integration (iOS 17+ — narrate in user's own voice at zero cost)

### Platform

- **PLAT-01**: Android full feature parity with iOS
- **PLAT-02**: App Store Server API integration for refund and subscription lifecycle events
- **PLAT-03**: Staged ATT rollout with A/B testing for opt-in rate optimization

## Out of Scope

| Feature | Reason |
|---------|--------|
| Instagram scraping | Requires partner program approval ($500-1K+/mo), not lean |
| X API scraping | $200/mo — replaced by free Spoonacular API |
| Imagen 4 AI image generation | $50-200/mo — replaced by Spoonacular CDN images |
| ElevenLabs for free tier | $99/mo — replaced by AVSpeechSynthesizer |
| Real-time viral detection | Requires X API — replaced by Spoonacular popularity |
| Location-based trending | Spoonacular free tier has no geolocation support |
| Custom recipe uploads to Spoonacular | Per-recipe charges, not cost-effective for lean launch |
| Redis/BullMQ queue upgrade | Not needed at pre-launch scale |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| RECIPE-01 | Phase 23 | Complete |
| RECIPE-02 | Phase 23 | Complete |
| RECIPE-03 | Phase 23 | Complete |
| RECIPE-06 | Phase 23 | Complete |
| CACHE-01 | Phase 23 | Complete |
| CACHE-02 | Phase 23 | Complete |
| CACHE-03 | Phase 23 | Complete |
| CACHE-04 | Phase 23 | Complete |
| VOICE-01 | Phase 24 | Pending |
| VOICE-02 | Phase 24 | Pending |
| VOICE-04 | Phase 24 | Pending |
| VOICE-05 | Phase 24 | Pending |
| VOICE-03 | Phase 25 | Pending |
| RECIPE-04 | Phase 26 | Pending |
| RECIPE-05 | Phase 26 | Pending |
| RECIPE-07 | Phase 26 | Pending |
| STORE-02 | Phase 27 | Pending |
| STORE-03 | Phase 27 | Pending |
| STORE-01 | Phase 28 | Pending |
| STORE-04 | Phase 28 | Pending |

**Coverage:**
- v5.0 requirements: 18 total
- Mapped to phases: 18
- Unmapped: 0 ✓

**Coverage by Phase:**
- Phase 23: 8 requirements (RECIPE-01,02,03,06 + CACHE-01,02,03,04)
- Phase 24: 4 requirements (VOICE-01,02,04,05)
- Phase 25: 1 requirement (VOICE-03)
- Phase 26: 3 requirements (RECIPE-04,05,07)
- Phase 27: 2 requirements (STORE-02,03)
- Phase 28: 2 requirements (STORE-01,04)

---
*Requirements defined: 2026-04-04*
*Last updated: 2026-04-04 after roadmap creation — 100% coverage achieved*
