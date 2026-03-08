---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: iOS App
current_phase: 10
status: completed
last_updated: "2026-03-08T09:53:26.039Z"
progress:
  total_phases: 7
  completed_phases: 6
  total_plans: 33
  completed_plans: 31
---

# Project State: Kindred

**Last Updated:** 2026-03-03
**Current Phase:** 10
**Status:** Phase 9 complete, Phase 10 next

---

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-01)

**Core value:** Hearing a loved one's voice guide you through a trending local recipe — that emotional moment is what makes Kindred irreplaceable.
**Current focus:** Phase 10 — Accessibility & Polish (v2.0 iOS App milestone)

---

## Current Position

Phase: 9 of 10 — COMPLETE (Monetization & Voice Tiers)
Plan: 5 of 5 — All plans complete
Status: Phase 9 verified on device — ads, subscription, voice slots, paywall all working
Last activity: 2026-03-08 — Completed 09-05: Device verification passed all 18 checks, 6 bugs fixed

Progress: [████████████████████████████████████████] 100% (Phase 9 complete, Phase 10 next)

---

## Performance Metrics

**Velocity:**
- Total plans completed: 11 (from v1.5 Backend & AI Pipeline)
- Average duration: ~45 min per plan
- Total execution time: ~8.25 hours (v1.5 milestone)

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1. Foundation (v1.5) | 5 | ~4h | ~48 min |
| 2. Feed Engine (v1.5) | 3 | ~2.5h | ~50 min |
| 3. Voice Core (v1.5) | 3 | ~1.75h | ~35 min |
| 4. Foundation & Architecture (v2.0) | 4 | ~52 min | ~13 min |
| 5. Guest Browsing & Feed (v2.0) | 4 | ~1039 min | ~260 min |
| 6. Dietary Filtering & Personalization (v2.0) | 3 | ~686 min | ~229 min |
| 7. Voice Playback & Streaming (v2.0) | 4 | ~13 min | ~3.3 min |

**Recent Trend:**
- v1.5 milestone: Delivered in 2 days (21 feat commits, 6,066 LOC TypeScript)
- Trend: Stable velocity, comprehensive depth setting working well

*Updated after v2.0 roadmap creation*

---
| Phase 04 P04 | 15 | 3 tasks | 7 files |
| Phase 05-guest-browsing-feed P01 | 338 | 2 tasks | 10 files |
| Phase 05-guest-browsing-feed P02 | 313 | 2 tasks | 7 files |
| Phase 05-guest-browsing-feed P03 | 228 | 2 tasks | 6 files |
| Phase 05-guest-browsing-feed P04 | 160 | 3 tasks | 7 files |
| Phase 05 P04 | 160 | 3 tasks | 7 files |
| Phase 06-dietary-filtering-personalization P01 | 670 | 2 tasks | 11 files |
| Phase 06 P02 | 8 | 2 tasks | 10 files |
| Phase 06 P03 | 8 | 2 tasks | 5 files |
| Phase 07 P01 | 3 | 2 tasks | 10 files |
| Phase 07-voice-playback-streaming P02 | 4 | 2 tasks | 4 files |
| Phase 07-voice-playback-streaming P03 | 3 | 2 tasks | 11 files |
| Phase 07-voice-playback-streaming P05 | 4 | 2 tasks | 2 files |
| Phase 07-voice-playback-streaming P06 | 2 | 2 tasks | 1 files |
| Phase 08-authentication-onboarding P01 | 4 | 2 tasks | 4 files |
| Phase 08-authentication-onboarding P02 | 7 | 2 tasks | 7 files |
| Phase 09 P04 | 7 | 3 tasks | 12 files |
| Phase 09 P03 | 5 | 2 tasks | 9 files |
| Phase 09 P02 | 6 | 2 tasks | 5 files |
| Phase 09 P01 | 6 | 3 tasks | 7 files |
| Phase 09-monetization-voice-tiers P04 | 7 | 3 tasks | 12 files |
| Phase 10 P01 | 8 | 3 tasks | 5 files |
| Phase 10 P02 | 16 | 2 tasks | 5 files |
| Phase 10 P04 | 10 | 2 tasks | 8 files |
| Phase 10 P03 | 10 | 2 tasks | 12 files |
| Phase 10 P05 | 10 | 2 tasks | 17 files |

## Accumulated Context

### Key Decisions Made

See PROJECT.md Key Decisions table for full list.

Recent decisions affecting v2.0 iOS work:
- Native iOS + Android (not cross-platform) for best UX and accessibility
- iOS first, Android fast-follow (v2.x milestone after v2.0 ships)
- SwiftUI + TCA architecture for iOS (iOS 17.0+ minimum per Clerk SDK)
- Apollo iOS 2.0.6 for GraphQL with SQLite offline-first cache
- Accessibility integrated throughout phases (ACCS-01-04), not just final audit
- Guest browsing first (Phase 5), onboarding deferred (Phase 8) for low-friction entry
- Swift Package Manager structure (instead of .xcodeproj) for modular architecture with local packages
- KindredAPI namespace prevents Foundation type conflicts - all GraphQL types use explicit namespace (04-03)
- SQLite cache with returnCacheDataAndFetch for offline-first UX (04-03)
- Guest mode allowed - GraphQL requests proceed without JWT for public feed browsing (04-03)
- Kingfisher cache limits: 100MB memory, 500MB disk to prevent memory pressure on older devices (04-03)
- Launch flow: splash → conditional welcome card → main content with @AppStorage persistence (04-04)
- HapticFeedback utility respects UIAccessibility.isReduceMotionEnabled, no in-app toggle (04-04)
- SwiftData for guest session storage with separate GuestBookmark and GuestSkip models (05-01)
- Deferred location permission - only requested when user taps "Use my location" (05-01)
- Guest UUID in UserDefaults carries over to account creation in Phase 8 (05-01)
- MapKit MKLocalSearch for city discovery - no API keys, respects privacy, works offline (05-04)
- "Use my location" at top of picker above search for prominent visibility (05-04)
- @AppStorage for last selected city persistence across app launches (05-04)
- @Namespace matched geometry for hero animation on card-to-detail navigation (05-04)
- Me tab bookmark badge only shows when bookmarkCount > 0 for clean UI (05-04)
- Reuse .onAppear for filter changes instead of duplicating fetch logic (06-01)
- Dual-access dietary preferences (Feed + Me tab) via shared @AppStorage key (06-01)
- Exponential recency decay with 30-day half-life weights recent interactions more heavily (06-02)
- 60/40 personalization/discovery split balances preferred cuisines with variety to avoid filter bubbles (06-02)
- FeedFeature dependency added to ProfileFeature for PersonalizationClient types (one-way dependency) (06-03)
- Progress indicator creates gamification loop showing "Learning... (X/50 interactions)" to encourage engagement (06-03)
- Affinity bars limited to top 5 cuisines for clean UI (06-03)
- Reset button in Me tab uses same @AppStorage key as feed X chip for unified preference management (06-03)
- AVPlayer (not AVAudioPlayer) for streaming capability with HTTP progressive download (07-01)
- Actor-based AudioPlayerManager for thread-safe async/await AVPlayer access (07-01)
- Rate changes require play() call first, then set rate (AVPlayer API requirement) (07-01)
- .cachesDirectory (not .documentDirectory) for audio files per iOS best practices (07-01)
- Binary search O(log n) for timestamp-to-step mapping in StepSyncEngine (07-01)
- 500MB cache limit with LRU eviction matches Kingfisher image cache strategy (07-01)
- TCA reducer with 20+ actions for comprehensive playback control (07-02)
- Mini-player uses 44x44 tap target, expanded player uses 64dp play button (07-02)
- Last-used voice per recipe auto-starts, picker shown only on first listen (07-02)
- Voice picker orders own voice first, then alphabetically (07-02)
- Auto-cache on .playing status avoids duplicate downloads (07-02)
- Mid-playback voice switch shows spinner on play button (07-02)
- Wait for AVPlayerItem.readyToPlay before AVPlayer.play() to fix "Cannot Open" errors (07-05)
- Cache-first strategy enabled — getCachedAudio called before streaming, no destructive clearCache (07-05)
- Stream observations independently cancellable (timeObserver, statusObserver, durationObserver) (07-05)
- Verified end-to-end audio playback on device with working controls, background audio, and cache operations (07-06)
- SignInClient uses TCA @DependencyClient pattern wrapping Clerk SDK with proper error mapping (08-01)
- SignInGateReducer is pure presentation reducer - cooldown and deferred action logic belong in parent reducer (08-01)
- SignInGateView uses Apple SignInWithAppleButton on top, custom Google button below, with swipe-down dismissal enabled (08-01)
- Dietary preferences use SAME UserDefaults key as Phase 6 (dietaryPreferences) for consistency (08-02)
- OnboardingView uses TabView PageTabViewStyle for horizontal paging carousel with dots indicator (08-02)
- FeedFeature dependency added to AuthFeature for LocationClient access in onboarding (08-02)
- GoogleMobileAds SDK 11.0.0+ integrated into MonetizationFeature with test ad unit IDs (09-02)
- AdClient TCA @DependencyClient checks UserDefaults 'kindredFirstLaunchComplete' flag for first-launch ad suppression (09-02)
- AdCardView matches RecipeCardView styling (16:9 media, 340x400 dimensions, CardSurface background, 16pt corners) (09-02)
- BannerAdView uses adaptive sizing and collapses to zero height when no ad loaded (09-02)
- SwipeCardStack tracks swipe count internally rather than modifying cardStack array for ad interleaving (09-03)
- Banner ad hides when voice narration is ACTIVE (playing/loading/buffering), shows when idle/paused/error (09-03)
- Voice slot limit (1 profile) enforced at UI layer in VoicePickerView with isAtVoiceLimit computed property (09-03)
- Free tier allows 1 voice profile creation, Pro tier unlimited (09-03)
- Transaction.updates listener runs throughout app lifecycle with Task-based cancellation in applicationWillTerminate (09-04)
- Base64url JWS decoding for MVP, production will use @apple/app-store-server-library SignedDataVerifier (09-04)
- Voice slot enforcement only on uploadVoice endpoint, replaceVoice excluded (doesn't consume new slot) (09-04)
- PRO pill badge shown next to Profile heading for Pro users (capsule shape, .kindredAccent background) (09-04)

### Pending Todos

None yet.

### Blockers/Concerns

**Phase 4 (Foundation) readiness:**
- ✅ Apollo iOS schema configuration uses KindredAPI namespace (resolved in 04-03)
- TCA usage guidelines should be established upfront (avoid over-engineering simple screens)
- ViewStore scoping pattern must be documented to prevent performance degradation

**Phase 5 (Feed) readiness:**
- Location permission flow needs contextual prompt strategy (not at app launch)
- Swipe card implementation needs accessibility fallback buttons (56dp Listen/Watch/Skip)
- ✅ Apollo cache policy (returnCacheDataAndFetch) configured with SQLite cache (resolved in 04-03)

**Phase 7 (Voice) readiness:**
- ✅ Audio cache eviction policy (LRU, 500MB max) implemented in VoiceCache (resolved in 07-01)
- AVAudioSession configuration (.playback, .spokenAudio) with interruption handling critical
- Background audio lock screen controls need MPNowPlayingInfoCenter implementation

**Phase 9 (Monetization) readiness:**
- StoreKit 2 JWS verification requires backend coordination (NestJS endpoint)
- Transaction.updates monitoring must run throughout app lifecycle
- Subscription management UI needs restore purchases flow

---
- Phase 08 Plan 03: AuthFeature module not recognized by Xcode build system. Implementation complete but unverified. Requires manual Xcode project configuration.

## Session Continuity

Last session: 2026-03-08
Stopped at: Phase 9 complete — all 5 plans executed and verified on device
Resume file: .planning/phases/09-monetization-voice-tiers/09-05-SUMMARY.md
Next action: Plan and execute Phase 10 (Accessibility & Polish)

---

*State updated: 2026-03-06 after completing Phase 8 (Authentication & Onboarding) — Phase 9 next*
