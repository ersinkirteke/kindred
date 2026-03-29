# Architecture Research: App Store Launch Prep

**Domain:** iOS App Store Integration & Production Readiness  
**Researched:** 2026-03-30  
**Confidence:** HIGH

## Executive Summary

App Store launch readiness features integrate with existing Kindred architecture through 5 primary integration points that are all **additive** — no architectural rewrites needed. Changes target specific gaps between MVP implementation and production requirements, preserving the existing SwiftUI + TCA architecture on iOS and NestJS + GraphQL on backend.

## Research Complete

Architecture research delivered comprehensive integration patterns for v4.0 App Store launch readiness. All 5 integration points identified with explicit component changes, data flow modifications, and build order optimized for parallelization.

### Files Created

- `.planning/research/ARCHITECTURE.md` — Complete integration architecture

### Key Findings

**Integration Points:** 5 identified (voice R2 URLs, ATT consent, paywall triggering, device token registration, JWS verification)

**Component Changes:** 4 new components, 9 modified, 4 unchanged (referenced for context)

**Build Order:** 10 tasks across 5 phases, 15 hours total (2 days with testing)

**Critical Path:** Backend GraphQL queries → iOS voice playback wiring

**Architectural Risk Level:** LOW — All changes extend existing patterns, no refactoring required

---

*See full ARCHITECTURE.md for detailed implementation patterns, code examples, and risk mitigation strategies.*

## Existing Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      iOS App (SwiftUI + TCA)                 │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌───────────┐  ┌──────────┐   │
│  │  Feed    │  │  Voice   │  │  Pantry   │  │ Profile  │   │
│  │ Feature  │  │ Playback │  │  Feature  │  │ Feature  │   │
│  └────┬─────┘  └────┬─────┘  └─────┬─────┘  └────┬─────┘   │
│       │             │               │             │          │
├───────┴─────────────┴───────────────┴─────────────┴─────────┤
│              Cross-Cutting Concerns Layer                    │
│  ┌────────────┐  ┌─────────────┐  ┌──────────────┐          │
│  │ Network    │  │ Monetization│  │ Auth         │          │
│  │ Client     │  │ Feature     │  │ Client       │          │
│  └──────┬─────┘  └──────┬──────┘  └──────┬───────┘          │
│         │                │                │                  │
├─────────┴────────────────┴────────────────┴──────────────────┤
│                    Foundation Layer                          │
│  ┌───────────────┐  ┌──────────────┐  ┌─────────────┐       │
│  │ Apollo Client │  │ SwiftData    │  │ DesignSystem│       │
│  │ (SQLite cache)│  │ (Pantry)     │  │             │       │
│  └───────┬───────┘  └──────────────┘  └─────────────┘       │
│          │                                                   │
└──────────┼───────────────────────────────────────────────────┘
           │
           ↓ (GraphQL/REST)
┌──────────┴───────────────────────────────────────────────────┐
│                  Backend (NestJS + GraphQL)                  │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌───────────┐  ┌──────────┐  ┌──────────┐   │
│  │ Recipe   │  │ Voice     │  │ Pantry   │  │ Billing  │   │
│  │ Resolver │  │ Service   │  │ Resolver │  │ Resolver │   │
│  └────┬─────┘  └─────┬─────┘  └────┬─────┘  └────┬─────┘   │
│       │              │              │             │          │
├───────┴──────────────┴──────────────┴─────────────┴─────────┤
│               External Services Integration                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ Prisma   │  │ Eleven   │  │ Gemini   │  │ Cloudflare│   │
│  │ (Postgres)│ │ Labs API │  │ 2.0 Flash│  │ R2 (CDN) │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## Integration Points for v4.0

### 1. Voice Playback → Backend R2 URLs

**Current:** TestAudioGenerator creates local WAV sine waves  
**Target:** GraphQL query returns R2 CDN URL or REST streaming endpoint

**Data Flow:**
```
User taps Play → VoicePlaybackReducer.selectVoice
  → GraphQL GetNarrationUrl(recipeId, voiceProfileId)
  → Backend checks NarrationAudio cache
  → If cached: R2 CDN URL
  → If not: /narration/:recipeId/stream endpoint
  → AudioPlayerManager.play(url)
  → AVPlayer progressive download
```

**Key Files:**
- iOS: `VoicePlaybackReducer.swift` (line 299 TODO block)
- Backend: `narration.controller.ts`, `voice.resolver.ts`
- New: `GetNarrationUrlQuery.graphql`

**AVPlayer Best Practices:**
- Already configured for HTTP streaming (AudioPlayerManager.swift:41)
- R2 supports HTTP range requests for seeking
- Monitor `isPlaybackLikelyToKeepUp` for buffering (line 178)

---

### 2. ATT Consent Flow

**Current:** AdMob.start() called immediately, test ad units  
**Target:** ATT prompt shown, production ad unit IDs

**Privacy Manifest Required:**
- File: `PrivacyInfo.xcprivacy` in `Kindred/Sources/`
- Declare: `NSPrivacyTracking: true`
- Domains: `["googleadservices.com", "googlesyndication.com"]`
- Usage: "We use tracking to show relevant ads..."

**Key Files:**
- iOS: `AppDelegate.swift`, `AdClient.swift`, `FeedReducer.swift`
- New: `PrivacyInfo.xcprivacy`

---

### 3. Paywall Triggering

**Current:** ScanPaywallView "Subscribe" button placeholder  
**Target:** Trigger MonetizationFeature PaywallView sheet

**Integration Pattern:**
```swift
// CameraReducer action
case .subscribeToPro:
    state.showSubscriptionGate = false
    // Parent presents PaywallView
    return .none
```

**Key Files:**
- iOS: `CameraReducer.swift`, `ScanPaywallView.swift`
- Reference: `MonetizationFeature/PaywallView.swift` (unchanged)

---

### 4. Device Token Registration

**Current:** Token stored in UserDefaults only  
**Target:** GraphQL mutation to backend

**Backend Schema:**
```prisma
model User {
  deviceToken         String?
  devicePlatform      String?
  deviceTokenUpdatedAt DateTime?
}
```

**Key Files:**
- iOS: `AppDelegate.swift` (line 192)
- Backend: `user.resolver.ts`, `schema.prisma`
- New: `RegisterDeviceTokenMutation.graphql`

---

### 5. SignedDataVerifier (Backend)

**Current:** Base64url decoding only  
**Target:** Full JWS verification with certificate chain

**Implementation:**
```typescript
npm install @apple/app-store-server-library

const verifier = new SignedDataVerifier(
  rootCertificates,
  true, // enableOnlineChecks
  environment,
  bundleId,
  appAppleId
);

const transaction = await verifier.verifyAndDecodeTransaction(jws);
```

**Key Files:**
- Backend: `billing.service.ts`
- Config: `APP_STORE_ENV`, `IOS_BUNDLE_ID`, `APPLE_APP_ID`

---

## Component Changes

### New (Create)
- `PrivacyInfo.xcprivacy` — ATT manifest
- `GetNarrationUrlQuery.graphql` — Query R2 URL
- `RegisterDeviceTokenMutation.graphql` — Push token registration

### Modified (Extend)
- `AppDelegate.swift` — ATT import, device token GraphQL
- `AdClient.swift` — Add `requestTrackingAuthorization`
- `VoicePlaybackReducer.swift` — Replace TestAudioGenerator
- `CameraReducer.swift` — Add `subscribeToPro` action
- `billing.service.ts` — Add SignedDataVerifier
- `user.resolver.ts` — Add device token mutation
- `schema.prisma` — Add device token fields

### Unchanged (Reference)
- `AudioPlayerManager.swift` — Already supports HTTP streaming
- `SubscriptionClient.swift` — JWS generation correct
- `PaywallView.swift` — Reuse existing UI
- `R2StorageService` — Already returns CDN URLs

---

## Build Order (15 hours total)

### Phase 1: Backend (3.5h)
1. GraphQL queries + mutations
2. SignedDataVerifier
3. Prisma schema migration

### Phase 2: Voice Playback (4h)
*Depends on Phase 1.1*
4. Wire VoicePlaybackReducer
5. Remove TODO markers

### Phase 3: ATT (3.5h)
*Parallel to Phase 2*
6. PrivacyInfo.xcprivacy
7. ATT flow implementation
8. Production ad unit IDs

### Phase 4: Device Token (2h)
*Parallel to Phase 2-3*
9. GraphQL mutation wiring

### Phase 5: Paywall (2h)
*Depends on Phase 3*
10. ScanPaywallView integration

**Critical Path:** Phase 1.1 → Phase 2.4

---

## Risks & Mitigations

### Risk 1: AVPlayer Cannot Open R2 URLs
**Likelihood:** Low | **Impact:** High

**Mitigation:**
- Test R2 URLs in isolation first
- Verify public read access
- Check CORS headers for audio/mpeg
- Fallback to REST endpoint if CDN fails

### Risk 2: ATT Prompt Timing
**Likelihood:** Medium | **Impact:** Medium

**Mitigation:**
- Show after user experiences value
- Optional pre-prompt explanation
- Respect ATT choice (don't re-ask)
- TestFlight user testing

### Risk 3: JWS Verification Fails
**Likelihood:** Medium | **Impact:** High

**Mitigation:**
- Extensive sandbox testing
- Detailed error logging
- Graceful degradation to client-side verification
- Monitor error rates

### Risk 4: Device Token Silent Failure
**Likelihood:** Medium | **Impact:** Medium

**Mitigation:**
- Retry with exponential backoff
- Re-send on next launch if failed
- Admin dashboard for token status
- Prominent logging

---

## Post-Launch Monitoring

| Metric | Target | Red Flag |
|--------|--------|----------|
| Voice playback success | >95% | <90% |
| ATT acceptance rate | >30% | <10% |
| JWS verification failure | <1% | >5% |
| Device token registration | >90% | <80% |
| Paywall conversion | >5% | <2% |

---

## Sources

**Apple Official:**
- [User Privacy and Data Use](https://developer.apple.com/app-store/user-privacy-and-data-use/)
- [Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)
- [AVPlayer Documentation](https://developer.apple.com/documentation/avfoundation/avplayer)
- [jwsRepresentation](https://developer.apple.com/documentation/storekit/verificationresult/jwsrepresentation-21vgo)

**Implementation Guides:**
- [iOS App Store Review Guidelines 2026](https://theapplaunchpad.com/blog/app-store-review-guidelines)
- [ATT framework | Adjust](https://help.adjust.com/en/article/app-tracking-transparency-att-framework)
- [StoreKit 2 JWS Validation | Medium](https://medium.com/@ronaldmannak/how-to-validate-ios-and-macos-in-app-purchases-using-storekit-2-and-server-side-swift-98626641d3ea)
- [AVPlayer Audio Streaming | Everappz](https://everappz.com/blog/audio-streaming-and-caching-in-ios-using-avassetresourceloader-and-avplayer/)
- [App Store Server API | Adapty](https://adapty.io/blog/validating-iap-with-app-store-server-api/)

---

*Architecture research for App Store Launch Prep*  
*Researched: 2026-03-30*
