---
gsd_state_version: 1.0
milestone: v1.5
milestone_name: milestone
status: Active
last_updated: "2026-04-03T08:24:42.706Z"
progress:
  total_phases: 18
  completed_phases: 17
  total_plans: 68
  completed_plans: 67
---

# Project State: Kindred

**Last Updated:** 2026-04-03
**Status:** Active

---

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-30)

**Core value:** Hearing a loved one's voice guide you through a trending local recipe — that emotional moment is what makes Kindred irreplaceable.
**Current focus:** Phase 21 - Voice Playback & Monetization Integration

---

## Current Position

Milestone: v4.0 App Store Launch Prep
Phase: 21 of 22 (Voice Playback & Monetization Integration)
Plan: 3 of 4 in current phase
Status: Active
Last activity: 2026-04-03 — Completed plan 21-03 (Recipe carousel navigation + pantry ingredient badges)

Progress: [████████████████░░░░] 96% (66/68 plans complete across all milestones)

---

## Performance Metrics

**Velocity:**
- Total plans completed: 66 (v1.5: 11, v2.0: 35, v3.0: 17, v4.0: 13)
- Total execution time: 18 days + 49h 0m across 3 milestones
- v4.0: 13 plans completed (Phase 18 complete, Phase 19 complete, Phase 20 complete, Phase 21: 3 of 4 plans)

**By Milestone:**

| Milestone | Phases | Plans | Duration |
|-----------|--------|-------|----------|
| v1.5 Backend & AI | 3 | 11 | 2 days |
| v2.0 iOS App | 8 | 35 | 9 days |
| v3.0 Smart Pantry | 6 | 17 | 7 days |
| v4.0 Launch Prep | 5 | 10/TBD | 48h 40m |

**Recent Trend:** Phase 19 complete (4 of 4 plans), Phase 20 complete (3 of 3 plans), Phase 21 in progress (1 of 4 plans)

---

| Phase | Plan | Duration (s) | Tasks | Files |
|-------|------|--------------|-------|-------|
| Phase 18 | P01 | 5 | 2 | 7 |
| Phase 18 | P02 | 130 | 1 | 1 |
| Phase 18 | P03 | 383 | 2 | 11 |
| Phase 18 | P04 | 66 | 1 | 2 |
| Phase 19 | P01 | 136 | 3 | 5 |
| Phase 19 P04 | 223 | 2 tasks | 6 files |
| Phase 19 P03 | 215 | 2 tasks | 6 files |
| Phase 19 P02 | 317 | 2 tasks | 8 files |
| Phase 20 | P01 | 203 | 2 | 9 |
| Phase 20 | P02 | 170 | 2 | 9 |
| Phase 20 P02 | 170 | 2 tasks | 9 files |
| Phase 20 P03 | 175137 | 2 tasks | 4 files |
| Phase 21 P01 | 420 | 2 tasks | 5 files |
| Phase 21 P02 | 575 | 2 tasks | 3 files |
| Phase 21 P03 | 703 | 2 tasks | 3 files |
| Phase 21 P04 | 402 | 1 tasks | 1 files |
| Phase 21 P01 | 754 | 2 tasks | 11 files |

## Accumulated Context

### Decisions

See PROJECT.md Key Decisions table for full list (28 decisions tracked).

Recent decisions affecting v4.0 work:

- [Phase 21-03]: Bidirectional fuzzy ingredient matching (chicken matches chicken breast) using contains check in both directions
- [Phase 21-03]: All pantry items included in matching regardless of expiry date (no expiry filter)
- [Phase 20]: Synchronous adClient.configurePersonalization (non-async closure, no .run effect needed)
- [Phase 20]: Pro subscriber consent skip via `case .pro` pattern match on subscriptionStatus
- **NSPrivacyTracking false** (Phase 18-02): No IDFA usage, no cross-app tracking in v4.0 — ATT prompt not needed
- **Required Reason API codes** (Phase 18-02): UserDefaults CA92.1 for app config, FileTimestamp C617.1 for pantry dates
- **7 data types declared** (Phase 18-02): AudioData (ElevenLabs), CoarseLocation (Mapbox), EmailAddress (Clerk), UserID (Clerk), ProductInteraction (Firebase), CrashData (Firebase), PurchaseHistory (StoreKit)
- **SwiftData persistence pattern** (v3.0): Named ModelConfiguration with PantryStore/GuestStore separation — completed in Phase 21-04 (DATA-01 complete)
- **Test AdMob IDs** (v2.0): Used test unit IDs throughout development — must replace with production IDs (BILL-03 in Phase 20)
- **Base64url JWS verification RESOLVED** (Phase 19-02): Replaced with SignedDataVerifier x5c certificate chain validation (BILL-01 complete)
- **Device token storage** (v3.0 partial): Tokens registered locally but not sent to backend — blocks push delivery (PUSH-01, PUSH-02 in Phase 19)
- [Phase 18]: Per-upload consent (not once-per-user) for GDPR Article 7 compliance and Tennessee ELVIS Act requirements
- [Phase 18]: interactiveDismissDisabled on consent modal to prevent accidental dismissal via swipe gesture
- [Phase 18]: consentAppVersion as nullable field to support existing records without breaking changes
- [Phase 18]: VoiceProfileInfo as local struct in ProfileReducer to avoid package dependencies
- [Phase 18]: GraphQL via URLSession directly (no new network client) for voice profile queries
- [Phase 18]: SFSafariViewController for privacy policy (App Store preferred over WKWebView)
- [Phase 18]: Use CFBundleShortVersionString (not CFBundleVersion) for consent audit trail versioning
- [Phase 19-01]: Named ThrottlerModule contexts ('default' 100 req/min, 'expensive' 10 req/min) for differential rate limiting
- [Phase 19-01]: Request ID generation with crypto.randomUUID() (Node.js built-in, zero dependencies)
- [Phase 19-01]: TransactionHistory without foreign key to User to support webhook events before user creation
- [Phase 19-02]: SignedDataVerifier x5c certificate chain validation (production first, sandbox fallback) prevents subscription fraud
- [Phase 19-02]: Product ID allowlist validation via APPLE_ALLOWED_PRODUCT_IDS to prevent unauthorized product redemptions
- [Phase 19-02]: DID_FAIL_TO_RENEW does NOT revoke access (honors Apple's grace period for failed billing)
- [Phase 19-02]: Webhook returns success even on error to prevent Apple retry storms (errors logged for investigation)
- [Phase 19]: MD5 hash for cache invalidation (8-char hash provides collision-resistant cache keys)
- [Phase 19]: get-mp3-duration for audio duration computation (lightweight library without ffmpeg dependency)
- [Phase 19]: Engagement nudge rate limit: Max 3 per user per week (7-day rolling window) to prevent notification fatigue
- [Phase 19]: Default all notification preferences to enabled (opt-out model for utility notifications)
- [Phase 19]: Cascade delete narration audio before marking profile DELETED (ensures cleanup completes)
- [Phase 19]: Inactivity detection via DeviceToken.updatedAt (no additional analytics infrastructure needed)
- [Phase 20]: UMP failure does not block ATT flow — graceful degradation for user consent
- [Phase 20]: Firebase Analytics disabled on ATT denial to respect user privacy choice
- [Phase 20]: Pre-prompt shown once per device matching iOS ATT dialog behavior
- [Phase 20]: xcconfig-based ad unit ID configuration separates Debug test IDs from Release production IDs
- [Phase 20]: fatalError for unconfigured Release builds prevents shipping test ads to production
- [Phase 20]: ConsentStatus drives ad personalization (fullyGranted = personalized, denied = non-personalized)
- [Phase 20]: Debug menu accessible via long-press on version label (debug-only)
- [Phase 20]: 10 comprehensive TCA test scenarios for consent state machine coverage
- [Phase 21]: Named ModelConfiguration for GuestStore and PantryStore ensures clean SwiftData container separation
- [Phase 21-01]: Removed TestAudioGenerator entirely for production-only R2 CDN audio
- [Phase 21-01]: Default 'Kindred Voice' prepended client-side for free-tier users

### Pending Todos

None - DATA-01 SwiftData persistence fix completed in Phase 21-04

### Blockers/Concerns

**Critical path for Phase 18:**
- Voice cloning consent copy requires legal counsel review for multi-state compliance (Tennessee ELVIS Act, California AB 1836, Federal AI Voice Act)
- Budget: $20-50K for AI/media legal counsel
- Timeline: 2-4 weeks for review (can run parallel to technical work in Phase 19-21)

**Known gaps from v3.0 (resolved in v4.0):**
- Voice playback uses TestAudioGenerator — resolved by Phase 19 + Phase 21
- 5 GraphQL voice profile TODO markers — resolved by Phase 21
- ScanPaywallView subscribe button not wired — resolved by Phase 21
- Recipe suggestion card tap navigation missing — resolved by Phase 21

---

## Session Continuity

Last session: 2026-04-03
Stopped at: Completed 21-04-PLAN.md (SwiftData container separation for GuestStore)
Resume file: None
Next action: Continue Phase 21 - Execute plans 21-01, 21-02, 21-03

---

*State initialized: 2026-03-30 — v4.0 App Store Launch Prep milestone*
