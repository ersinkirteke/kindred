# Phase 19: Backend Production Hardening - Context

**Gathered:** 2026-03-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the backend production-ready with StoreKit 2 fraud prevention (JWS x5c chain verification), push notification delivery infrastructure, narration URL via GraphQL, and production error handling. Backend-only — no iOS client changes.

</domain>

<decisions>
## Implementation Decisions

### StoreKit JWS Validation (BILL-01)
- Wire ClerkAuthGuard on SubscriptionResolver (currently commented out with placeholder userId)
- Replace base64url decoding with `@apple/app-store-server-library` SignedDataVerifier with x5c certificate chain verification
- Support multiple product IDs via configurable allowlist (not hardcoded `com.kindred.pro.monthly`)
- Auto-detect sandbox vs production from JWS payload (use both verifiers, try sandbox if production fails)
- Apple config via environment variables: APPLE_BUNDLE_ID, APPLE_APP_ID, APPLE_ISSUER_ID
- Wire canCreateVoiceProfile query to ClerkAuthGuard (currently uses placeholder userId)

### App Store Server Notifications V2
- Single POST endpoint (e.g., `/apple/notifications`) that auto-detects sandbox vs production from notification payload
- Honor Apple's billing grace period — only revoke after EXPIRED notification, not on first billing failure
- Full transaction history: store every JWS verification attempt and notification in a separate table (for disputes, debugging, compliance)

### Narration URL via GraphQL (VOICE-03)
- Add combined `narrationUrl` query on VoiceResolver (where narrationMetadata already lives)
- Returns: `{ url: String?, speakerName: String, relationship: String, recipeName: String, durationMs: Int? }`
- When no cached audio exists: return `url: null` — client triggers REST streaming endpoint for first-time generation
- Keep REST `/narration/:recipeId/stream` endpoint for initial stream generation (GraphQL can't stream audio)
- Optional `voiceProfileId` parameter — if omitted, fall back to user's primary (first) voice profile
- New URL per generation for cache invalidation: include hash or timestamp in R2 key (e.g., `narration/{recipeId}/{voiceProfileId}-{hash}.mp3`)
- Compute audio duration at upload time from MP3 buffer, store in `NarrationAudio.durationMs`
- Cascade delete: deleting a voice profile also deletes all NarrationAudio records and R2 files for that voice

### Push Notification Triggers (PUSH-01, PUSH-02)
- Register FCM token on every app launch (upsert handles deduplication)
- Backend-only scope — iOS client FCM integration is a separate phase
- Three notification categories:
  1. **Expiry alerts** — wire existing expiry-notification.scheduler.ts to PushService
  2. **Voice ready** — send push from voice-cloning.processor.ts immediately after successful cloning
  3. **Engagement nudges** — new engagement-notification.scheduler.ts, 7-day inactivity threshold, max 3/week
- Per-category notification preferences: separate `NotificationPreferences` table with boolean columns (expiryAlerts, voiceReady, engagement)
- Simple time-based engagement: use last device token update timestamp to detect inactivity (no activity tracking needed)
- New engagement-notification.scheduler.ts (separate from expiry scheduler — different concerns, different schedules)

### Error Handling & Production Hardening
- Structured error codes in GraphQL errors extensions field (e.g., SUBSCRIPTION_EXPIRED, VOICE_NOT_READY, TOKEN_INVALID)
- Structured JSON logging with request IDs (no external monitoring service like Sentry)
- Rate limiting via @nestjs/throttler:
  - Tighter limits on narration streaming + subscription verification (~10 req/min per user)
  - Standard limits on other endpoints

### Claude's Discretion
- Exact throttle rate values and configuration
- GraphQL error code enum naming and organization
- Logging format and request ID generation approach
- Transaction history table schema design
- NotificationPreferences table defaults (all enabled by default vs opt-in)
- MP3 duration calculation library choice

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PushService` (push.service.ts): Fully built FCM service with multi-device, token cleanup, batch sending, platform-specific payloads
- `DeviceTokenResolver` (device-token.resolver.ts): GraphQL mutations for registerDevice/unregisterDevice behind ClerkAuthGuard
- `R2StorageService` (r2-storage.service.ts): S3-compatible Cloudflare R2 client with uploadImage, uploadVoiceSample, uploadNarrationAudio (immutable cache headers)
- `NarrationService` (narration.service.ts): getCachedNarrationUrl() already returns r2Url from NarrationAudio table; cacheNarrationAudio() uploads to R2
- `NarrationController` (narration.controller.ts): REST streaming with 302 redirect to CDN on cache hit
- `VoiceResolver` (voice.resolver.ts): narrationMetadata query already exists — add narrationUrl query alongside
- `expiry-notification.scheduler.ts`: Exists but needs wiring to PushService
- `voice-cloning.processor.ts`: Job processor for voice cloning — add push notification on completion

### Established Patterns
- ClerkAuthGuard + @CurrentUser() decorator for authentication (used consistently across resolvers)
- PrismaService for all database operations
- ConfigService for environment variables
- NestJS Logger per service
- Upsert pattern for idempotent operations (DeviceToken, NarrationAudio, Subscription)

### Integration Points
- SubscriptionResolver: uncomment/replace auth guards, wire to ClerkAuthGuard + CurrentUser
- SubscriptionService.decodeJWSPayload(): replace with SignedDataVerifier
- VoiceResolver: add narrationUrl query next to existing narrationMetadata
- voice-cloning.processor.ts: inject PushService, send notification on READY status
- expiry-notification.scheduler.ts: inject PushService, check NotificationPreferences before sending
- app.module.ts: register ThrottlerModule, new engagement scheduler

</code_context>

<specifics>
## Specific Ideas

- Server Notifications V2 webhook should be a single endpoint detecting env from payload, not separate sandbox/production URLs
- Engagement nudge: use device token `updatedAt` as proxy for last activity (updated on every launch)
- Narration URL cache invalidation: hash in key means old URLs naturally expire, no Cloudflare purge API needed

</specifics>

<deferred>
## Deferred Ideas

- iOS client FCM SDK integration (getting token, calling registerDevice mutation) — separate client-side phase
- Rich push notifications with images — future enhancement
- A/B testing engagement nudge content — future optimization
- Push notification analytics (open rates, conversion) — future phase

</deferred>

---

*Phase: 19-backend-production-hardening*
*Context gathered: 2026-03-30*
