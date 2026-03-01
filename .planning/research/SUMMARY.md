# Project Research Summary

**Project:** Kindred iOS App (SwiftUI + TCA)
**Domain:** Native iOS food discovery and voice-guided cooking app
**Researched:** 2026-03-01
**Confidence:** HIGH

## Executive Summary

Kindred is a native iOS app for discovering viral recipes with voice narration cloned from loved ones. The backend (NestJS + GraphQL) is complete and validated—the iOS app is purely a presentation layer that streams data, caches for offline use, and provides native platform features. The recommended approach uses SwiftUI with The Composable Architecture (TCA) selectively, Apollo iOS for GraphQL, AVPlayer for voice streaming, and StoreKit 2 for freemium monetization.

The architecture emphasizes offline-first functionality (Apollo SQLite cache, local audio files), accessibility-first design (WCAG AAA compliance: 56dp touch targets, VoiceOver support, 7:1 contrast ratio), and modular Swift Package Manager structure to prevent tight coupling. The core value proposition—voice-narrated recipes from loved ones—requires careful AVFoundation audio handling (interruptions, background playback) and proper voice recording format (192kbps MP3/M4A for ElevenLabs).

Key risks center on performance (TCA ViewStore over-observation, Apollo cache orphans, SwiftUI List scrolling), accessibility compliance (touch targets, Dynamic Type, VoiceOver labels), and StoreKit 2 implementation complexity (JWS verification, subscription state monitoring). These risks are mitigated through selective TCA usage, cache garbage collection, lazy loading, and comprehensive accessibility testing from day one. The roadmap should prioritize foundation (GraphQL + auth) → feed (core discovery) → voice playback (differentiator) → onboarding (retention) → monetization (revenue) → accessibility audit (compliance).

## Key Findings

### Recommended Stack

The stack is already decided: SwiftUI + TCA for architecture, with iOS 17.0+ minimum due to Clerk SDK requirements. The focus is on adding targeted libraries for GraphQL communication, image caching, and platform services while maximizing use of native iOS frameworks (AVFoundation, Core Location, StoreKit 2).

**Core technologies:**
- **SwiftUI + TCA 1.x**: Modern UI with selective state management—use TCA for complex features (feed, voice playback), vanilla SwiftUI for simple screens to avoid over-engineering
- **Apollo iOS 2.0.6**: GraphQL client with native async/await, SQLite cache for offline-first, JWT auth interceptor for Clerk tokens
- **AVFoundation (native)**: Voice streaming via AVPlayer, background audio support, lock screen controls—no third-party audio library needed
- **StoreKit 2 (native)**: Freemium subscriptions with async/await APIs, JWS transaction verification (not legacy receipt validation)
- **Kingfisher 8.0+**: Image loading and caching (superior to native AsyncImage), pure Swift with SwiftUI support
- **Firebase FCM 12.10.0**: Push notifications (already validated in backend v1.5), APNs integration
- **Core Location + Core Data (native)**: Location services and offline storage—no external dependencies

**Critical version constraint:** iOS 17.0+ minimum (driven by Clerk iOS SDK requirement)

### Expected Features

Users expect a Tinder-style swipe feed with dietary filtering, social OAuth, and offline functionality. Differentiators are cloned voice narration, hyperlocal viral ranking (5-10 mile radius), and accessibility-first design ("Build for Grandpa George"). The MVP should launch with guest browsing (low friction) and defer video playback, social sharing, and in-app recipe creation to v2+.

**Must have (table stakes):**
- Swipe cards with button alternatives (Listen/Watch/Skip for accessibility)
- Voice playback controls (play/pause/seek, 64dp touch targets per PROJECT.md)
- Social OAuth (Google/Apple—Sign in with Apple required by App Store if other OAuth exists)
- Bookmark/save recipes (100% of recipe apps have this)
- Dietary preference filtering (60% of users expect this)
- Offline voice caching (unique for voice-guided apps, core utility)
- VoiceOver support (WCAG AAA target)
- Freemium paywall (95% of iOS apps use freemium model)

**Should have (competitive):**
- Cloned voice narration (CORE VALUE—emotional connection, unique in food app space)
- Hyperlocal viral feed (recipes trending within 5-10 miles, solves "what's viral near me?")
- Culinary DNA personalization (learns from skips/bookmarks, no rating prompts)
- Guest-to-account conversion (frictionless onboarding, convert when motivated)
- WCAG AAA compliance (56dp touch targets, 18sp+ text, max 3 nav levels—most apps stop at AA)

**Defer (v2+):**
- Culinary DNA personalization (trigger after 50+ skips/bookmarks collected)
- Recipe search (trigger when users request specific recipes)
- Social sharing (not core to emotional utility per PROJECT.md)
- Video playback (Veo deferred: $4.50-9/user/month, 30-120s latency, safety concerns per PROJECT.md)
- In-app voice recording (defer to file upload for MVP, avoid permissions complexity)

### Architecture Approach

Use modular Swift Package Manager structure with feature isolation (FeedFeature, RecipeDetailFeature, VoiceFeature, ProfileFeature, OnboardingFeature). Each feature is a TCA reducer with dependency injection for services (GraphQLClient, AudioPlayerClient, BillingClient). Apollo iOS handles all backend communication with JWT auth interceptor, offline-first cache policy (returnCacheDataAndFetch), and SQLite persistence.

**Major components:**
1. **Feature Modules (TCA reducers)**: Encapsulate UI, state, and business logic for single features—zero cross-feature dependencies, compile-time enforcement via Swift Package Manager
2. **Apollo GraphQL Client**: Singleton with JWT interceptor, SQLite normalized cache, offline handling—all queries/mutations go through Apollo for type safety
3. **AudioStreamingService**: AVPlayer wrapper for voice streaming from Cloudflare R2 URLs, background audio session management, local file caching for offline
4. **BillingService**: StoreKit 2 subscription management with server-side JWS validation, Transaction.updates monitoring for renewals/expirations
5. **SharedUI**: Reusable SwiftUI components with accessibility-first design (KindredButton with 56dp touch targets, KindredTextField, theme/colors)
6. **DataLayer**: Generated Apollo models from backend GraphQL schema, shared across all features—single source of truth

**Key patterns:**
- Offline-first cache strategy: read from Apollo SQLite cache first, fetch network in background, show staleness indicators
- Unidirectional data flow (TCA): Action → Reducer → State → View, effects for async operations (GraphQL, audio, billing)
- Dependency injection: @Dependency property wrapper for testability, mock implementations for unit tests
- Accessibility from day one: Apply accessibility modifiers in first view implementation, test with VoiceOver during development

### Critical Pitfalls

Research identified 25 pitfalls across TCA architecture, Apollo GraphQL, audio streaming, StoreKit 2, and accessibility. The top 5 that could derail the project:

1. **ViewStore Over-Observation Causing Performance Degradation**: Every view observing entire TCA state causes unnecessary re-renders, scrolling jank, frame drops as app grows—AVOID by scoping ViewStore to minimal state slices (`observe: \.recipeList`), use @ObservableState macro in TCA 1.0+
2. **Apollo iOS Cache Orphaned Objects Causing Memory Bloat**: InMemoryNormalizedCache accumulates unreachable objects (orphaned records), cache doubles in size over time causing crashes—AVOID by using SQLiteNormalizedCache instead, call `store.gc()` on low memory warnings, monitor cache size in analytics
3. **Background Audio Interruptions Not Handled Properly**: Voice narration stops on phone calls/alarms but doesn't resume, audio continues playing during calls—AVOID by configuring AVAudioSession category (.playback, mode: .spokenAudio), observe AVAudioSessionInterruptionNotification, save/restore playback position
4. **StoreKit 2 Subscription State Not Monitoring Transaction.updates**: App doesn't detect renewals/expirations/billing issues until user restarts, users lose Pro access after renewal—AVOID by monitoring Transaction.updates async sequence throughout app lifecycle, handle billing grace periods
5. **Onboarding Flow Exceeds 90-Second Target Causing Drop-Off**: Long tutorials (3-5 min) with too many screens kills retention, users never reach core value—AVOID by deferring voice profile creation until first recipe play, allow guest browsing immediately, limit to 3 screens max (welcome → dietary prefs → start)

**Additional critical risks:**
- Touch targets below 56dp (WCAG AAA violation, elderly user frustration)—verify with Accessibility Inspector
- Dynamic Type breaks layout at AX3+ sizes—test all screens at accessibility text sizes
- Guest-to-account conversion loses user data (bookmarks, preferences)—implement migration flow before clearing local data
- Token refresh race conditions causing unexpected logouts—serialize refresh with Swift Actor pattern
- AVAudioPlayer vs AVPlayer wrong choice (forces full download before playback)—use AVPlayer for streaming, AVAudioPlayer only for cached files

## Implications for Roadmap

Based on research, suggested 6-phase structure optimized for dependency order, pitfall avoidance, and incremental value delivery:

### Phase 1: Foundation (Weeks 1-2)
**Rationale:** Core infrastructure that all features depend on—establishing this first prevents architectural refactoring later
**Delivers:** App launches with authenticated GraphQL client, theme applied, navigation structure
**Stack used:** Apollo iOS 2.0.6 (GraphQL client + SQLite cache), Clerk iOS SDK (JWT auth), SwiftUI NavigationStack
**Pitfalls addressed:**
- Set TCA usage guidelines upfront (avoid over-engineering simple screens)
- Configure Apollo schema namespace to prevent Foundation type conflicts
- Implement ViewStore scoping pattern in architectural docs
**Critical tasks:**
- Set up Swift Package Manager modular structure
- Configure Apollo codegen with schemaNamespace, custom scalar mappings
- Implement JWT auth interceptor for Clerk tokens (store in Keychain, not UserDefaults)
- Create SharedUI theme (colors, typography, KindredButton with 56dp touch targets)

### Phase 2: Feed & Recipe Discovery (Weeks 3-4)
**Rationale:** Core value proposition—users must see recipes to engage. Feed is the primary interaction surface.
**Delivers:** Users browse viral recipes, filter by dietary preferences, view recipe details offline
**Features:** Swipe cards, Listen/Watch/Skip buttons, dietary filtering, location badge, bookmark/skip
**Architecture:** FeedFeature module (TCA reducer), RecipeDetailFeature module, Apollo SQLite cache
**Pitfalls addressed:**
- Implement pagination + lazy loading to avoid List performance issues (> 50 items)
- Set Apollo cache policy (returnCacheDataAndFetch for feed, cache TTL for viral badges)
- Request location permission contextually (when viewing feed, not at app launch)
**Critical tasks:**
- FeedFeature TCA reducer with GraphQL client dependency
- Swipe card UI with DragGesture (custom, not library—2-3 hour implementation)
- RecipeDetailView with ingredient list, instructions, prep time
- Location integration (Core Location, display city badge, manual location change)

### Phase 3: Voice Playback (Weeks 5-6)
**Rationale:** Differentiator feature requiring audio infrastructure—must work flawlessly for product to succeed
**Delivers:** Users listen to recipe narrations in cloned voices, audio plays in background, caches for offline
**Stack used:** AVFoundation (AVPlayer for streaming, AVAudioSession for background), AudioStreamingService module
**Pitfalls addressed:**
- Use AVPlayer (not AVAudioPlayer) for streaming R2 URLs—progressive download, not full file
- Configure AVAudioSession (.playback, .spokenAudio) with interruption handling (phone calls, alarms)
- Validate voice recording format (192kbps MP3/M4A) for ElevenLabs compatibility
- Implement audio cache manager with LRU eviction (max 500MB storage)
**Critical tasks:**
- AudioStreamManager with AVPlayer, play/pause/seek controls, time observation
- Background audio support (lock screen controls, MPNowPlayingInfoCenter)
- Audio caching strategy (download to Documents directory, cache key: recipeId + voiceProfileId)
- VoiceFeature module for profile management (upload flow deferred to settings)

### Phase 4: Onboarding & Auth (Week 7)
**Rationale:** Requires feed and voice features to be functional for meaningful onboarding—retention is critical
**Delivers:** New users complete onboarding < 90 seconds, see personalized feed, convert from guest to account
**Features:** Welcome screen, dietary prefs, guest browsing, Google/Apple OAuth, guest-to-account migration
**Pitfalls addressed:**
- Defer voice upload to first recipe play (avoid onboarding bloat)
- Allow guest browsing immediately (no forced signup)
- Implement guest-to-account migration flow (preserve bookmarks/skips)
- Show custom pre-permission prompts before iOS permission requests
- Serialize token refresh to avoid race conditions and unexpected logouts
**Critical tasks:**
- OnboardingFeature module (3 screens max: welcome → dietary prefs → start)
- Guest mode support (anonymous JWT from backend, UserDefaults for guest state)
- Guest-to-account conversion (migration mutation, verify success before clearing local data)
- Sign in with Apple + Google OAuth (Clerk iOS SDK integration)

### Phase 5: Monetization (Week 8)
**Rationale:** Revenue generation requires stable product—billing implementation is complex and needs backend coordination
**Delivers:** Users upgrade to Pro ($9.99/mo), subscription persists across restarts, entitlement checks work
**Stack used:** StoreKit 2 (native), BillingService module, backend JWS validation
**Pitfalls addressed:**
- Use JWS transaction verification (not legacy receipt validation—StoreKit 2 requirement)
- Monitor Transaction.updates async sequence for renewals/expirations
- Implement subscription management UI (view status, cancel, restore purchases)
- Remove all external payment links (App Store Review rejection risk)
**Critical tasks:**
- BillingService with StoreKit 2 subscription management
- ProfileFeature module (user settings, subscription status, upgrade flow)
- Server-side JWS validation (NestJS endpoint validates with App Store Server API)
- Entitlement checks (Free tier: 1 voice slot, Pro: unlimited)
- Paywall triggers (upload 2nd voice, bookmark 10+ recipes)

### Phase 6: Accessibility & Polish (Weeks 9-10)
**Rationale:** Requires all features complete for comprehensive audit—WCAG AAA compliance is non-negotiable for target users
**Delivers:** App meets WCAG AAA standards, fully functional offline, production-ready for App Store submission
**Pitfalls addressed:**
- VoiceOver labels missing/generic (test with VoiceOver enabled, Accessibility Inspector audit)
- Dynamic Type breaks layout (test at AX1-AX5 sizes, all screens)
- Touch targets below 56dp (Accessibility Inspector verification)
- Color contrast below 7:1 ratio (WebAIM contrast checker, adjust terracotta if needed)
- GDPR/ATT compliance (consent management before analytics, both required for EU users)
**Critical tasks:**
- Accessibility audit with VoiceOver (labels, hints, reading order)
- Dynamic Type testing (XXXL text sizes, layout adjustments)
- Touch target verification (56x56pt minimum for all interactive elements)
- Color contrast validation (7:1 for body text, 4.5:1 for large text)
- Push notifications (Firebase FCM integration)
- Error handling & loading states (graceful offline mode, retry logic)
- Performance optimization (lazy loading verified, cache tuning, image compression)

### Phase Ordering Rationale

- **Foundation first**: Apollo client, auth, and theme are dependencies for all subsequent phases. TCA guidelines prevent over-engineering debt.
- **Feed before voice**: Users must browse recipes before playing narrations. Feed validates GraphQL integration and cache strategy before adding audio complexity.
- **Voice before onboarding**: Onboarding should showcase voice playback as differentiator. Need working audio infrastructure to demo value proposition.
- **Onboarding before monetization**: Users must experience product value before paywall. Guest-to-account conversion funnel drives Pro upgrades.
- **Monetization before accessibility audit**: Billing implementation is complex and needs iteration. Accessibility audit requires stable feature set.
- **Accessibility last**: Comprehensive audit needs all features complete. Testing with VoiceOver, Dynamic Type, and Accessibility Inspector is time-intensive.

**Dependency chain:**
```
Phase 1 (Foundation)
    ↓ Apollo client, auth, theme
Phase 2 (Feed & Recipe Discovery)
    ↓ GraphQL models, cache, location
Phase 3 (Voice Playback)
    ↓ Audio infrastructure
Phase 4 (Onboarding & Auth)
    ↓ Complete feature set, conversion funnel
Phase 5 (Monetization)
    ↓ Revenue generation, entitlement checks
Phase 6 (Accessibility & Polish)
    ↓ WCAG AAA compliance, production-ready
```

### Research Flags

**Phases likely needing deeper research during planning:**
- **Phase 3 (Voice Playback)**: ElevenLabs API integration details, audio streaming optimization for cellular networks, cache eviction policy tuning
- **Phase 5 (Monetization)**: StoreKit 2 server-side JWS validation implementation, App Store Server API integration, subscription group configuration

**Phases with standard patterns (skip research-phase):**
- **Phase 1 (Foundation)**: Apollo iOS setup well-documented, TCA patterns established, Clerk integration validated in backend v1.5
- **Phase 2 (Feed & Recipe Discovery)**: SwiftUI List optimization and pagination are well-documented patterns, DragGesture for swipe cards has multiple tutorials
- **Phase 4 (Onboarding & Auth)**: OAuth flows and guest-to-account migration are standard patterns with clear implementation paths
- **Phase 6 (Accessibility & Polish)**: WCAG guidelines and SwiftUI accessibility modifiers extensively documented, established testing methodology

**Backend dependencies already validated (v1.5):**
- GraphQL API (Apollo Server 5) with recipe feed, bookmarks, dietary filters
- Clerk JWT authentication
- ElevenLabs voice cloning pipeline
- Firebase FCM push notifications
- Cloudflare R2 CDN for audio/images

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Apollo iOS 2.0.6 released Feb 2026 (current), TCA 1.x mature, Clerk iOS SDK v1.0 stable (Feb 2026), StoreKit 2 native to iOS 17+ |
| Features | MEDIUM | Table stakes validated via competitor analysis (SideChef, Tasty, Yummly), user engagement benchmarks from 2026 data, some features novel (voice cloning) with less reference data |
| Architecture | HIGH | TCA + Apollo iOS integration patterns well-documented, modular Swift Package Manager structure proven in production apps, offline-first with SQLite cache is established pattern |
| Pitfalls | HIGH | 25 pitfalls identified from official Apple docs, Apollo GraphQL docs, TCA community discussions, StoreKit 2 migration guides, accessibility guidelines—all cross-referenced with multiple sources |

**Overall confidence:** HIGH

### Gaps to Address

**Performance benchmarks for large datasets:**
- Research identified scrolling performance issues with > 50 items but didn't quantify exact thresholds
- **Mitigation:** Profile with Instruments during Phase 2 (Feed Implementation), implement pagination early, measure scrolling frame rate in analytics

**Voice streaming latency on cellular networks:**
- AVPlayer streaming latency varies by connection quality (3G/LTE/5G)
- **Mitigation:** Test on real devices with Network Link Conditioner during Phase 3, implement adaptive bitrate streaming if needed, show buffering indicators

**Apollo cache TTL tuning:**
- Optimal cache expiration times for recipe data vs viral badges unknown
- **Mitigation:** Start with conservative TTLs (recipes: 7 days, viral badges: 1 hour), monitor cache hit rates in analytics, adjust based on real usage patterns

**StoreKit 2 sandbox testing limitations:**
- Research notes sandbox purchases behave differently than production (faster renewals, no billing retry)
- **Mitigation:** Test all subscription scenarios in sandbox during Phase 5, run TestFlight beta with real subscriptions before production launch

**WCAG AAA compliance verification:**
- Accessibility research provides guidelines but doesn't cover every edge case (complex custom controls)
- **Mitigation:** Hire accessibility consultant for audit during Phase 6, test with actual elderly users (target demographic), iterate based on feedback

**Culinary DNA personalization algorithm:**
- Collaborative filtering approach outlined but not validated for cold start (< 50 interactions)
- **Mitigation:** Defer to Phase 7 (post-MVP), use content-based filtering for cold start (cuisine type, dietary prefs), gather 50+ interactions before activating collaborative filtering

## Sources

### Primary (HIGH confidence)
All research files cite official documentation and recent releases:
- **STACK.md**: Apollo iOS 2.0.6 (Feb 2026), Clerk iOS SDK v1.0 (Feb 2026), Google Mobile Ads 13.1.0 (Feb 2026), Firebase iOS SDK 12.10.0, StoreKit 2 official Apple docs, TCA GitHub repository
- **FEATURES.md**: Recipe app statistics (2025), mobile app engagement benchmarks (2026), WCAG 2.1 accessibility standards, iOS onboarding best practices (2026)
- **ARCHITECTURE.md**: TCA documentation (official), Apollo iOS docs (cache setup, testing), SwiftUI accessibility techniques (CVS Health open-source), StoreKit 2 implementation guides (RevenueCat 2025)
- **PITFALLS.md**: TCA performance discussions (GitHub issues), Apollo cache management (official docs), StoreKit 2 migration guides (receipt → JWS), accessibility violations (WebAIM, 24 Accessibility)

### Secondary (MEDIUM confidence)
Community best practices and 2025-2026 technical blog posts:
- Modern iOS architecture comparisons (MVVM vs TCA)
- Offline-first architecture patterns (SwiftData, Core Data sync)
- Mobile app onboarding statistics and A/B test results
- Freemium monetization benchmarks and conversion rate data

### Tertiary (LOW confidence, needs validation)
- Culinary DNA personalization algorithm (collaborative filtering for implicit feedback—academic paper)
- Voice streaming latency estimates (ElevenLabs Flash v2.5 = ~75ms—needs real-world testing)
- Cache eviction thresholds (500MB max, 30-day TTL—requires tuning)

---
*Research completed: 2026-03-01*
*Ready for roadmap: yes*
