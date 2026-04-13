# Requirements: Kindred

**Defined:** 2026-04-12
**Core Value:** Hearing a loved one's voice guide you through a trending local recipe — that emotional moment is what makes Kindred irreplaceable.

## v5.1 Requirements

Requirements for v5.1 Gap Closure. Each maps to roadmap phases.

### Voice Narration

- [ ] **VOICE-01**: Free-tier user can listen to recipe instructions narrated via on-device AVSpeechSynthesizer
- [ ] **VOICE-02**: AVSpeechSynthesizer narration plays step-by-step with current step highlighting
- [ ] **VOICE-03**: Free-tier narration gracefully handles iOS 17 silent failure with automatic retry/fallback
- [ ] **VOICE-04**: Voice tier routing selects AVSpeech for free users and ElevenLabs for Pro users automatically
- [ ] **VOICE-05**: Audio session handoff between AVSpeech and AVPlayer works cleanly without corruption

### Search & Filtering

- [ ] **SEARCH-01**: User can search recipes by keyword via search bar in feed
- [ ] **SEARCH-02**: Search results display with same card layout as popular recipes feed
- [ ] **SEARCH-03**: Search includes debounce (300ms+) to respect Spoonacular quota (150 req/day)
- [ ] **FILTER-01**: Dietary filter chips pass parameters through GraphQL to Spoonacular API
- [ ] **FILTER-02**: Diet vs intolerance tags are correctly classified for Spoonacular API mapping

### Source Attribution

- [x] **ATTR-01**: Recipe detail view displays clickable source URL linking to original recipe

## Future Requirements

Deferred to future release. Tracked but not in current roadmap.

### Voice Enhancements

- **VOICE-06**: Personal Voice integration (iOS 17+) for users who have set up Personal Voice
- **VOICE-07**: Voice speed control (0.5x, 1x, 1.5x, 2x) for AVSpeech narration
- **VOICE-08**: Localized voice selection (Turkish TTS voice for Turkish recipes)

### Search Enhancements

- **SEARCH-04**: Search history with recent queries
- **SEARCH-05**: Search suggestions/autocomplete from Spoonacular

## Out of Scope

| Feature | Reason |
|---------|--------|
| ElevenLabs for free tier | Cost prohibitive at scale (~$0.01-0.03/recipe); AVSpeech is $0 |
| Multi-diet Spoonacular queries | API accepts single diet param; would require client-side intersection |
| Voice narration download for offline | AVSpeech works offline natively; ElevenLabs cache already exists |
| Android search/filter | iOS-only milestone; Android is separate fast-follow |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| ATTR-01 | Phase 29 | Complete |
| VOICE-01 | Phase 30 | Pending |
| VOICE-02 | Phase 30 | Pending |
| VOICE-03 | Phase 30 | Pending |
| VOICE-04 | Phase 30 | Pending |
| VOICE-05 | Phase 30 | Pending |
| SEARCH-01 | Phase 31 | Pending |
| SEARCH-02 | Phase 31 | Pending |
| SEARCH-03 | Phase 31 | Pending |
| FILTER-01 | Phase 31 | Pending |
| FILTER-02 | Phase 31 | Pending |

**Coverage:**
- v5.1 requirements: 11 total
- Mapped to phases: 11
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-12*
*Last updated: 2026-04-12 — traceability mapped after roadmap creation (phases 29-32)*
