# Phase 19: Backend Production Hardening - Research

**Researched:** 2026-03-30
**Domain:** Backend production infrastructure (StoreKit 2 fraud prevention, push notifications, GraphQL narration URLs, error handling)
**Confidence:** HIGH

## Summary

Phase 19 hardens the Kindred backend for production launch with four critical components: (1) StoreKit 2 JWS validation using Apple's official library with x5c certificate chain verification to prevent subscription fraud, (2) push notification infrastructure wiring expiry alerts, voice-ready notifications, and engagement nudges to the existing PushService, (3) GraphQL narration URL query returning cached R2 CDN URLs with cache invalidation via hash-based keys, and (4) production error handling with structured error codes, JSON logging with request IDs, and rate limiting via @nestjs/throttler.

The codebase already has 80% of the infrastructure built: PushService (full FCM implementation), DeviceTokenResolver (GraphQL mutations), R2StorageService (CDN uploads), NarrationService (cache lookup), expiry-notification.scheduler (cron job), and voice-cloning.processor (async queue). This phase primarily **wires existing components together** and **replaces placeholder code** (base64url JWS decoding, commented-out ClerkAuthGuard, hardcoded product IDs) with production-grade implementations.

**Primary recommendation:** Install @apple/app-store-server-library, wire ClerkAuthGuard on SubscriptionResolver, add narrationUrl GraphQL query to VoiceResolver, create engagement-notification.scheduler.ts (clone expiry pattern), wire PushService to voice-cloning.processor, add NotificationPreferences table, configure ThrottlerModule with named contexts for tighter narration/subscription limits.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### StoreKit JWS Validation (BILL-01)
- Wire ClerkAuthGuard on SubscriptionResolver (currently commented out with placeholder userId)
- Replace base64url decoding with `@apple/app-store-server-library` SignedDataVerifier with x5c certificate chain verification
- Support multiple product IDs via configurable allowlist (not hardcoded `com.kindred.pro.monthly`)
- Auto-detect sandbox vs production from JWS payload (use both verifiers, try sandbox if production fails)
- Apple config via environment variables: APPLE_BUNDLE_ID, APPLE_APP_ID, APPLE_ISSUER_ID
- Wire canCreateVoiceProfile query to ClerkAuthGuard (currently uses placeholder userId)

#### App Store Server Notifications V2
- Single POST endpoint (e.g., `/apple/notifications`) that auto-detects sandbox vs production from notification payload
- Honor Apple's billing grace period — only revoke after EXPIRED notification, not on first billing failure
- Full transaction history: store every JWS verification attempt and notification in a separate table (for disputes, debugging, compliance)

#### Narration URL via GraphQL (VOICE-03)
- Add combined `narrationUrl` query on VoiceResolver (where narrationMetadata already lives)
- Returns: `{ url: String?, speakerName: String, relationship: String, recipeName: String, durationMs: Int? }`
- When no cached audio exists: return `url: null` — client triggers REST streaming endpoint for first-time generation
- Keep REST `/narration/:recipeId/stream` endpoint for initial stream generation (GraphQL can't stream audio)
- Optional `voiceProfileId` parameter — if omitted, fall back to user's primary (first) voice profile
- New URL per generation for cache invalidation: include hash or timestamp in R2 key (e.g., `narration/{recipeId}/{voiceProfileId}-{hash}.mp3`)
- Compute audio duration at upload time from MP3 buffer, store in `NarrationAudio.durationMs`
- Cascade delete: deleting a voice profile also deletes all NarrationAudio records and R2 files for that voice

#### Push Notification Triggers (PUSH-01, PUSH-02)
- Register FCM token on every app launch (upsert handles deduplication)
- Backend-only scope — iOS client FCM integration is a separate phase
- Three notification categories:
  1. **Expiry alerts** — wire existing expiry-notification.scheduler.ts to PushService
  2. **Voice ready** — send push from voice-cloning.processor.ts immediately after successful cloning
  3. **Engagement nudges** — new engagement-notification.scheduler.ts, 7-day inactivity threshold, max 3/week
- Per-category notification preferences: separate `NotificationPreferences` table with boolean columns (expiryAlerts, voiceReady, engagement)
- Simple time-based engagement: use last device token update timestamp to detect inactivity (no activity tracking needed)
- New engagement-notification.scheduler.ts (separate from expiry scheduler — different concerns, different schedules)

#### Error Handling & Production Hardening
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

### Deferred Ideas (OUT OF SCOPE)
- iOS client FCM SDK integration (getting token, calling registerDevice mutation) — separate client-side phase
- Rich push notifications with images — future enhancement
- A/B testing engagement nudge content — future optimization
- Push notification analytics (open rates, conversion) — future phase
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| BILL-01 | Backend validates StoreKit 2 JWS transactions using SignedDataVerifier with x5c chain | Apple official library with x5c chain verification, environment auto-detection, error handling patterns |
| PUSH-01 | Device FCM token registered with backend via GraphQL mutation on app launch | Existing DeviceTokenResolver with ClerkAuthGuard, PushService.registerDeviceToken upsert pattern |
| PUSH-02 | Backend stores FCM token per user and uses it for push notification delivery | Existing PushService with multi-device, batch sending, automatic token cleanup, scheduler patterns |
| VOICE-03 | Narration URL returned via GraphQL query with NarrationAudio cache lookup | Existing NarrationService.getCachedNarrationUrl, R2StorageService, GraphQL resolver patterns |
</phase_requirements>

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| @apple/app-store-server-library | Latest (1.x) | StoreKit 2 JWS verification with x5c chain | Official Apple library, handles certificate chain validation, OCSP checks, sandbox/production environments |
| @nestjs/throttler | ^6.5.0 | Rate limiting for GraphQL/REST endpoints | Official NestJS package, supports multiple named contexts, GraphQL-aware, per-resolver decorators |
| @nestjs/schedule | ^6.1.1 | Cron jobs for notifications | Already installed, used in existing expiry-notification.scheduler.ts |
| firebase-admin | ^13.7.0 | FCM push notifications | Already installed, used in existing PushService |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| get-mp3-duration | 1.0.0 | Calculate MP3 audio duration | When caching narration audio to populate NarrationAudio.durationMs field |
| @nestjs/config | ^4.0.3 | Environment variable management | Already installed, use for Apple credentials (APPLE_BUNDLE_ID, APPLE_APP_ID, etc.) |
| winston | ^3.19.0 | Structured JSON logging | Already installed via nest-winston, add request ID to log context |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| @apple/app-store-server-library | Custom JWS verification with jsonwebtoken + node-forge | Apple library handles OCSP checks, certificate chain validation, environment detection — custom solution error-prone and insecure |
| get-mp3-duration | music-metadata or fluent-ffmpeg | music-metadata is heavier (parses full metadata), ffmpeg requires binary dependency — get-mp3-duration is lightweight and sufficient |
| @nestjs/throttler | rate-limiter-flexible or express-rate-limit | @nestjs/throttler integrates natively with NestJS guards, supports GraphQL context, and allows per-resolver decorators |

**Installation:**
```bash
cd backend
npm install @apple/app-store-server-library get-mp3-duration
# All other dependencies already installed
```

## Architecture Patterns

### Recommended Project Structure
```
backend/src/
├── subscription/
│   ├── subscription.service.ts      # Replace base64url with SignedDataVerifier
│   ├── subscription.resolver.ts     # Wire ClerkAuthGuard, @CurrentUser
│   ├── subscription.controller.ts   # NEW: Apple Server Notifications V2 webhook
│   ├── transaction-history.entity.ts # NEW: Prisma model for audit trail
│   └── dto/
│       └── apple-notification.dto.ts # NEW: V2 notification payload types
├── push/
│   ├── push.service.ts              # Existing, no changes needed
│   ├── device-token.resolver.ts     # Existing, already wired
│   └── notification-preferences.entity.ts # NEW: Prisma model
├── voice/
│   ├── voice.resolver.ts            # Add narrationUrl query
│   ├── narration.service.ts         # Add durationMs calculation to cacheNarrationAudio
│   └── voice-cloning.processor.ts   # Inject PushService, send notification
├── pantry/
│   ├── expiry-notification.scheduler.ts  # Wire PushService (already injected)
│   └── engagement-notification.scheduler.ts # NEW: Clone expiry pattern
├── common/
│   ├── errors/
│   │   └── graphql-error-codes.enum.ts # NEW: Structured error codes
│   └── interceptors/
│       └── request-id.interceptor.ts # NEW: Generate request IDs
└── app.module.ts                    # Configure ThrottlerModule with named contexts
```

### Pattern 1: StoreKit 2 JWS Verification with Environment Auto-Detection

**What:** Verify JWS signatures using SignedDataVerifier, automatically trying sandbox if production fails

**When to use:** On every subscription verification mutation, to prevent fraud and validate Apple-signed receipts

**Example:**
```typescript
// Source: @apple/app-store-server-library official documentation
import { SignedDataVerifier, Environment, VerificationException } from '@apple/app-store-server-library';

export class SubscriptionService {
  private productionVerifier: SignedDataVerifier;
  private sandboxVerifier: SignedDataVerifier;

  constructor(private config: ConfigService) {
    const appleRootCAs = [/* Download from Apple PKI */];
    const bundleId = this.config.get('APPLE_BUNDLE_ID');
    const appAppleId = this.config.get('APPLE_APP_ID');

    this.productionVerifier = new SignedDataVerifier(
      appleRootCAs,
      true, // enableOnlineChecks
      Environment.PRODUCTION,
      bundleId,
      appAppleId
    );

    this.sandboxVerifier = new SignedDataVerifier(
      appleRootCAs,
      true,
      Environment.SANDBOX,
      bundleId
      // Note: appAppleId NOT required for sandbox
    );
  }

  async verifyJWS(jwsRepresentation: string): Promise<TransactionPayload> {
    try {
      // Try production first
      return await this.productionVerifier.verifyAndDecodeSignedTransaction(jwsRepresentation);
    } catch (error) {
      if (error instanceof VerificationException) {
        // Try sandbox as fallback
        return await this.sandboxVerifier.verifyAndDecodeSignedTransaction(jwsRepresentation);
      }
      throw error;
    }
  }
}
```

### Pattern 2: GraphQL Rate Limiting with Named Contexts

**What:** Apply different rate limits to expensive operations (narration, subscription) vs standard queries

**When to use:** Protect backend from abuse on high-cost operations (ElevenLabs API calls, StoreKit verification)

**Example:**
```typescript
// Source: @nestjs/throttler GitHub README
// app.module.ts
ThrottlerModule.forRoot([
  { name: 'default', ttl: 60000, limit: 100 },      // 100 req/min for most endpoints
  { name: 'expensive', ttl: 60000, limit: 10 },     // 10 req/min for narration/subscription
])

// subscription.resolver.ts
@Mutation(() => Boolean)
@UseGuards(ClerkAuthGuard)
@Throttle({ expensive: { limit: 10, ttl: 60000 } })
async verifySubscription(
  @Args('jwsRepresentation') jwsRepresentation: string,
  @CurrentUser() user: CurrentUserContext,
): Promise<boolean> {
  return this.subscriptionService.verifyAndSyncSubscription(user.clerkId, jwsRepresentation);
}
```

### Pattern 3: Notification Preferences Check Before Sending

**What:** Query NotificationPreferences table before sending push to respect user opt-outs

**When to use:** In all three notification schedulers (expiry, voice-ready, engagement)

**Example:**
```typescript
// expiry-notification.scheduler.ts
async sendExpiryNotification(userId: string, items: any[]) {
  // Check if user enabled expiry alerts
  const prefs = await this.prisma.notificationPreferences.findUnique({
    where: { userId }
  });

  if (!prefs?.expiryAlerts) {
    this.logger.debug(`User ${userId} disabled expiry alerts, skipping`);
    return;
  }

  const notification = this.buildNotificationMessage(items);
  await this.pushService.sendToUser(userId, notification);
}
```

### Pattern 4: Narration Cache Invalidation via Hash-Based Keys

**What:** Include content hash in R2 key to automatically invalidate old narrations when recipe changes

**When to use:** When uploading narration audio to R2, to ensure clients always get latest version

**Example:**
```typescript
// narration.service.ts
import crypto from 'crypto';

async cacheNarrationAudio(
  recipeId: string,
  voiceProfileId: string,
  audioBuffer: Buffer,
): Promise<void> {
  // Generate hash from audio content for cache busting
  const hash = crypto.createHash('md5').update(audioBuffer).digest('hex').substring(0, 8);
  const key = `narration/${recipeId}/${voiceProfileId}-${hash}.mp3`;

  // Calculate duration from MP3 buffer
  const durationMs = await this.getAudioDuration(audioBuffer);

  const r2Url = await this.r2Storage.uploadNarrationAudio(recipeId, voiceProfileId, audioBuffer, key);

  await this.prisma.narrationAudio.upsert({
    where: { recipeId_voiceProfileId: { recipeId, voiceProfileId } },
    update: { r2Url, sizeBytes: audioBuffer.length, durationMs },
    create: { recipeId, voiceProfileId, r2Url, sizeBytes: audioBuffer.length, durationMs },
  });
}

private async getAudioDuration(audioBuffer: Buffer): Promise<number> {
  const getMp3Duration = require('get-mp3-duration');
  return getMp3Duration(audioBuffer); // Returns duration in milliseconds
}
```

### Pattern 5: App Store Server Notifications V2 Environment Detection

**What:** Parse `environment` field from decoded signedPayload to distinguish sandbox vs production

**When to use:** In Apple webhook controller to route notifications correctly

**Example:**
```typescript
// subscription.controller.ts
@Post('apple/notifications')
async handleAppleNotification(@Body() body: any): Promise<void> {
  const { signedPayload } = body;

  // Decode and verify notification (auto-detects environment)
  let verifiedPayload;
  try {
    verifiedPayload = await this.productionVerifier.verifyAndDecodeNotification(signedPayload);
  } catch {
    verifiedPayload = await this.sandboxVerifier.verifyAndDecodeNotification(signedPayload);
  }

  const { environment, notificationType, data } = verifiedPayload;
  this.logger.log(`Notification from ${environment}: ${notificationType}`);

  // Store in transaction history
  await this.prisma.transactionHistory.create({
    data: {
      environment,
      notificationType,
      payload: JSON.stringify(verifiedPayload),
      receivedAt: new Date(),
    }
  });

  // Handle specific notification types
  if (notificationType === 'EXPIRED') {
    // Only revoke after grace period expires
    await this.subscriptionService.revokeSubscription(data.transactionId);
  }
}
```

### Anti-Patterns to Avoid

- **Hardcoded product IDs:** Use configurable allowlist from environment variable (APPLE_ALLOWED_PRODUCT_IDS), not `if (payload.productId === 'com.kindred.pro.monthly')`
- **Ignoring grace period:** Never revoke subscription on first billing failure — wait for EXPIRED notification (Apple handles 60-day recovery window)
- **Manual JWS verification:** Don't use jsonwebtoken + manual x5c parsing — Apple's library handles OCSP checks and edge cases
- **Separate sandbox/production webhooks:** Single endpoint auto-detects environment from payload.environment field
- **Synchronous notification sending:** Use background schedulers with batching, not inline in mutation resolvers

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JWS signature verification | Custom JWT + x509 certificate validation | @apple/app-store-server-library SignedDataVerifier | Handles x5c chain extraction, OCSP revocation checks, certificate date validation with tolerance, environment detection — edge cases are non-obvious |
| Request ID generation | Custom UUID appending to logs | NestJS interceptor with AsyncLocalStorage | Automatic context propagation across async operations, no manual threading of requestId through service calls |
| GraphQL error codes | Ad-hoc string error messages | Structured enum in extensions field | Clients can programmatically handle errors (e.g., show subscription paywall on SUBSCRIPTION_EXPIRED) |
| MP3 duration calculation | ffmpeg shell exec or manual frame parsing | get-mp3-duration library | Synchronous, no binary dependencies, handles VBR/CBR MP3s correctly |
| Rate limiting | Redis + Lua scripts or in-memory counters | @nestjs/throttler | Integrates with NestJS guards, GraphQL context extraction, per-resolver decorators, TTL/limit configuration |

**Key insight:** Apple's ecosystem has non-obvious edge cases (OCSP responder URLs, certificate OID validation, grace period semantics) — official library encapsulates production battle-testing.

## Common Pitfalls

### Pitfall 1: Missing appAppleId for Production Environment

**What goes wrong:** SignedDataVerifier throws VerificationException when initialized for PRODUCTION without appAppleId

**Why it happens:** Sandbox environment doesn't require appAppleId, but production does (documented in library)

**How to avoid:** Always provide APPLE_APP_ID environment variable, validate on app startup:
```typescript
if (environment === Environment.PRODUCTION && !appAppleId) {
  throw new Error('APPLE_APP_ID required for production environment');
}
```

**Warning signs:** VerificationException with "missing appAppleId" on first production JWS verification

### Pitfall 2: Revoking Subscription on DID_FAIL_TO_RENEW Notification

**What goes wrong:** User loses access during billing grace period, Apple successfully retries payment, but backend already revoked access

**Why it happens:** Confusing "failed to renew" with "subscription expired" — Apple continues retrying for 60 days

**How to avoid:** Only revoke on EXPIRED notification (grace period ended), ignore DID_FAIL_TO_RENEW:
```typescript
if (notificationType === 'EXPIRED') {
  await this.subscriptionService.revokeSubscription(transactionId);
} else if (notificationType === 'DID_FAIL_TO_RENEW') {
  this.logger.warn(`Billing retry for ${transactionId}, grace period active`);
}
```

**Warning signs:** Users reporting "lost access but payment went through later"

### Pitfall 3: Not Storing Transaction History

**What goes wrong:** Unable to resolve disputes, debug billing issues, or comply with audit requirements

**Why it happens:** Treating verification as a boolean check instead of compliance requirement

**How to avoid:** Store every JWS verification attempt and webhook notification:
```typescript
await this.prisma.transactionHistory.create({
  data: {
    userId,
    transactionId: payload.transactionId,
    jwsPayload: jwsRepresentation,
    verificationResult: 'SUCCESS',
    environment: payload.environment,
    timestamp: new Date(),
  }
});
```

**Warning signs:** Support tickets asking "when did my subscription renew?" with no audit trail

### Pitfall 4: Hardcoded APPLE_ROOT_CA Certificates

**What goes wrong:** Verification fails when Apple rotates root certificates (happens every few years)

**Why it happens:** Copying certificate strings into code instead of loading from external source

**How to avoid:** Download from Apple PKI (https://www.apple.com/certificateauthority/), store in config/certs/ directory, load at runtime:
```typescript
const appleRootCAs = [
  fs.readFileSync('config/certs/AppleRootCA-G2.cer', 'utf8'),
  fs.readFileSync('config/certs/AppleRootCA-G3.cer', 'utf8'),
];
```

**Warning signs:** All JWS verifications suddenly failing with INVALID_CERTIFICATE after Apple cert rotation

### Pitfall 5: Forgetting to Add durationMs to NarrationAudio

**What goes wrong:** Client receives narration URL but can't display progress bar duration ("0:00 / ???")

**Why it happens:** Caching audio URL without computing metadata

**How to avoid:** Calculate duration synchronously during cacheNarrationAudio:
```typescript
const getMp3Duration = require('get-mp3-duration');
const durationMs = getMp3Duration(audioBuffer);

await this.prisma.narrationAudio.upsert({
  where: { recipeId_voiceProfileId: { recipeId, voiceProfileId } },
  update: { r2Url, sizeBytes: audioBuffer.length, durationMs },
  create: { recipeId, voiceProfileId, r2Url, sizeBytes: audioBuffer.length, durationMs },
});
```

**Warning signs:** UI shows "0:00" duration for all narrations

### Pitfall 6: Not Checking NotificationPreferences Before Sending Push

**What goes wrong:** Users receive notifications they opted out of, leading to App Store rejection under guideline 4.5.4

**Why it happens:** Assuming all users want all notification types

**How to avoid:** Query preferences table before every push:
```typescript
const prefs = await this.prisma.notificationPreferences.findUnique({ where: { userId } });
if (!prefs?.voiceReady) return; // User disabled voice-ready notifications
```

**Warning signs:** User complaints about unwanted notifications, App Store review rejection

### Pitfall 7: Applying Global Rate Limit to All GraphQL Operations

**What goes wrong:** Expensive operations (narration streaming) get same limit as cheap queries (recipe list), enabling abuse

**Why it happens:** Not using named throttler contexts

**How to avoid:** Configure multiple contexts, apply @Throttle decorator per-resolver:
```typescript
ThrottlerModule.forRoot([
  { name: 'default', ttl: 60000, limit: 100 },
  { name: 'expensive', ttl: 60000, limit: 10 },
]);

@Throttle({ expensive: { limit: 10, ttl: 60000 } })
async streamNarration(...) { }
```

**Warning signs:** ElevenLabs API bills skyrocketing from abuse

## Code Examples

Verified patterns from official sources:

### StoreKit 2 JWS Verification with Transaction History
```typescript
// Source: @apple/app-store-server-library official docs
import { SignedDataVerifier, Environment } from '@apple/app-store-server-library';

export class SubscriptionService {
  async verifyAndSyncSubscription(userId: string, jwsRepresentation: string): Promise<boolean> {
    try {
      // Verify with production verifier first
      const payload = await this.productionVerifier.verifyAndDecodeSignedTransaction(jwsRepresentation);

      // Store transaction history for audit trail
      await this.prisma.transactionHistory.create({
        data: {
          userId,
          transactionId: payload.transactionId,
          originalTransactionId: payload.originalTransactionId,
          jwsPayload: jwsRepresentation,
          environment: 'PRODUCTION',
          productId: payload.productId,
          expiresDate: new Date(payload.expiresDate),
          verificationResult: 'SUCCESS',
          timestamp: new Date(),
        }
      });

      // Validate product ID against allowlist
      const allowedProducts = this.config.get('APPLE_ALLOWED_PRODUCT_IDS').split(',');
      if (!allowedProducts.includes(payload.productId)) {
        throw new Error(`Product ID ${payload.productId} not in allowlist`);
      }

      // Check expiration
      const isValid = payload.expiresDate > Date.now();

      // Upsert subscription record
      await this.prisma.subscription.upsert({
        where: { userId },
        create: {
          userId,
          productId: payload.productId,
          transactionId: payload.transactionId,
          originalTransactionId: payload.originalTransactionId,
          expiresDate: new Date(payload.expiresDate),
          isActive: isValid,
          jwsPayload: jwsRepresentation,
        },
        update: {
          transactionId: payload.transactionId,
          expiresDate: new Date(payload.expiresDate),
          isActive: isValid,
          jwsPayload: jwsRepresentation,
          updatedAt: new Date(),
        },
      });

      return isValid;
    } catch (error) {
      // Try sandbox verifier as fallback
      try {
        const payload = await this.sandboxVerifier.verifyAndDecodeSignedTransaction(jwsRepresentation);

        await this.prisma.transactionHistory.create({
          data: {
            userId,
            transactionId: payload.transactionId,
            jwsPayload: jwsRepresentation,
            environment: 'SANDBOX',
            verificationResult: 'SUCCESS',
            timestamp: new Date(),
          }
        });

        // Same upsert logic for sandbox
        // ... (omitted for brevity)
        return true;
      } catch (sandboxError) {
        // Both verifiers failed, store failure
        await this.prisma.transactionHistory.create({
          data: {
            userId,
            jwsPayload: jwsRepresentation,
            verificationResult: 'FAILURE',
            errorMessage: sandboxError.message,
            timestamp: new Date(),
          }
        });
        return false;
      }
    }
  }
}
```

### GraphQL Narration URL Query with Cache Lookup and Duration
```typescript
// voice.resolver.ts
@Query(() => NarrationUrlDto)
@UseGuards(ClerkAuthGuard)
async narrationUrl(
  @Args('recipeId') recipeId: string,
  @Args('voiceProfileId', { nullable: true }) voiceProfileId?: string,
  @CurrentUser() user: CurrentUserContext,
): Promise<NarrationUrlDto> {
  // Find database user from Clerk ID
  const dbUser = await this.prisma.user.findUnique({
    where: { clerkId: user.clerkId }
  });

  // If no voiceProfileId provided, use user's primary (first) voice profile
  let profileId = voiceProfileId;
  if (!profileId) {
    const primaryProfile = await this.prisma.voiceProfile.findFirst({
      where: { userId: dbUser.id, status: 'READY' },
      orderBy: { createdAt: 'asc' },
    });

    if (!primaryProfile) {
      throw new Error('No voice profiles found');
    }
    profileId = primaryProfile.id;
  }

  // Load voice profile for metadata
  const profile = await this.voiceService.getVoiceProfile(profileId, user.clerkId);

  // Load recipe
  const recipe = await this.prisma.recipe.findUnique({
    where: { id: recipeId },
    select: { id: true, name: true },
  });

  if (!recipe) {
    throw new Error('Recipe not found');
  }

  // Check for cached narration audio
  const cached = await this.prisma.narrationAudio.findUnique({
    where: { recipeId_voiceProfileId: { recipeId, voiceProfileId: profileId } },
  });

  return {
    url: cached?.r2Url ?? null,
    speakerName: profile.speakerName,
    relationship: profile.relationship,
    recipeName: recipe.name,
    durationMs: cached?.durationMs ?? null,
  };
}
```

### Engagement Notification Scheduler with Inactivity Detection
```typescript
// pantry/engagement-notification.scheduler.ts
import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { PrismaService } from '../prisma/prisma.service';
import { PushService } from '../push/push.service';

@Injectable()
export class EngagementNotificationScheduler {
  private readonly logger = new Logger(EngagementNotificationScheduler.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly pushService: PushService,
  ) {}

  @Cron('0 10 * * *', { name: 'engagement-nudge', timeZone: 'UTC' })
  async handleEngagementNudge() {
    this.logger.log('Starting engagement nudge job (10:00 AM UTC)');

    try {
      // Find users inactive for 7+ days (based on last device token update)
      const sevenDaysAgo = new Date();
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

      const inactiveUsers = await this.prisma.deviceToken.groupBy({
        by: ['userId'],
        where: {
          updatedAt: { lt: sevenDaysAgo },
        },
        _max: { updatedAt: true },
      });

      this.logger.log(`Found ${inactiveUsers.length} inactive users (7+ days)`);

      // Check notification preferences and send rate (max 3/week)
      for (const { userId, _max } of inactiveUsers) {
        const prefs = await this.prisma.notificationPreferences.findUnique({
          where: { userId }
        });

        if (!prefs?.engagement) {
          this.logger.debug(`User ${userId} disabled engagement notifications`);
          continue;
        }

        // Check weekly rate limit (count notifications sent in last 7 days)
        const weekAgo = new Date();
        weekAgo.setDate(weekAgo.getDate() - 7);

        const sentCount = await this.prisma.notificationLog.count({
          where: {
            userId,
            type: 'ENGAGEMENT',
            sentAt: { gte: weekAgo },
          }
        });

        if (sentCount >= 3) {
          this.logger.debug(`User ${userId} already received 3 engagement notifications this week`);
          continue;
        }

        // Send engagement nudge
        await this.sendEngagementNudge(userId);
      }

      this.logger.log('Engagement nudge job complete');
    } catch (error) {
      this.logger.error(`Engagement nudge job failed: ${error.message}`, error.stack);
    }
  }

  private async sendEngagementNudge(userId: string) {
    try {
      await this.pushService.sendToUser(userId, {
        title: 'Missing you in the kitchen!',
        body: 'Check out the latest trending recipes in your area',
        data: { type: 'ENGAGEMENT' },
      });

      // Log notification for rate limiting
      await this.prisma.notificationLog.create({
        data: {
          userId,
          type: 'ENGAGEMENT',
          sentAt: new Date(),
        }
      });

      this.logger.debug(`Sent engagement nudge to user ${userId}`);
    } catch (error) {
      this.logger.error(`Failed to send engagement nudge to ${userId}: ${error.message}`);
    }
  }
}
```

### Structured GraphQL Error Codes
```typescript
// common/errors/graphql-error-codes.enum.ts
export enum GraphQLErrorCode {
  SUBSCRIPTION_EXPIRED = 'SUBSCRIPTION_EXPIRED',
  SUBSCRIPTION_INVALID = 'SUBSCRIPTION_INVALID',
  VOICE_NOT_READY = 'VOICE_NOT_READY',
  VOICE_QUOTA_EXCEEDED = 'VOICE_QUOTA_EXCEEDED',
  TOKEN_INVALID = 'TOKEN_INVALID',
  NARRATION_NOT_CACHED = 'NARRATION_NOT_CACHED',
  RATE_LIMIT_EXCEEDED = 'RATE_LIMIT_EXCEEDED',
}

// Usage in resolver:
throw new GraphQLError('Subscription expired', {
  extensions: {
    code: GraphQLErrorCode.SUBSCRIPTION_EXPIRED,
    expiresDate: subscription.expiresDate.toISOString(),
  }
});
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual JWT verification with jsonwebtoken | @apple/app-store-server-library SignedDataVerifier | WWDC 2023 (library released) | Handles x5c chain, OCSP checks, environment detection automatically |
| Base64url decode of JWS payload | SignedDataVerifier with certificate validation | Now (this phase) | Prevents fraud by validating Apple signatures |
| Separate sandbox/production webhook URLs | Single endpoint with environment auto-detection | App Store Server Notifications V2 (2021) | Simpler webhook configuration in App Store Connect |
| Global rate limiting (e.g., 100 req/min) | Named throttler contexts with per-resolver limits | @nestjs/throttler v5+ (2023) | Protects expensive operations without blocking cheap queries |
| Revoking subscription on first billing failure | Honor grace period, revoke only on EXPIRED | StoreKit 2 grace period (2021) | Prevents user churn during temporary billing issues |

**Deprecated/outdated:**
- **App Store Server Notifications V1**: Deprecated, might be removed anytime — use V2 (signedPayload structure)
- **RevenueCat SDK**: Not needed — @apple/app-store-server-library sufficient for v4.0 launch
- **Manual OCSP certificate revocation checks**: SignedDataVerifier handles when enableOnlineChecks=true

## Open Questions

1. **Should NotificationPreferences default all categories to enabled or opt-in?**
   - What we know: iOS requires explicit notification permissions, but doesn't cover per-category preferences
   - What's unclear: User expectation for first-time behavior (get all notifications vs explicitly enable)
   - Recommendation: Default all to `true` (all enabled) — users already opted in via iOS permissions, per-category is refinement

2. **What's the exact weekly limit for engagement nudges (3 vs 2)?**
   - What we know: CONTEXT.md says "max 3/week", industry standard is 2-3
   - What's unclear: User tolerance threshold
   - Recommendation: Start with 3, add metrics in NotificationLog to detect opt-out patterns

3. **Should transaction history table include failed verification attempts?**
   - What we know: CONTEXT.md says "store every JWS verification attempt"
   - What's unclear: Whether "every" includes failures or just successes
   - Recommendation: Store all (successes + failures) — critical for debugging fraud attempts and false positives

## Validation Architecture

> Skipped — workflow.nyquist_validation is false in .planning/config.json

## Sources

### Primary (HIGH confidence)
- [@apple/app-store-server-library official documentation](https://apple.github.io/app-store-server-library-node/) - Installation, SignedDataVerifier usage, environment handling
- [Apple app-store-server-library-node GitHub (jws_verification.ts)](https://github.com/apple/app-store-server-library-node/blob/main/jws_verification.ts) - x5c chain extraction, certificate validation logic, error types
- [@nestjs/throttler GitHub README](https://github.com/nestjs/throttler) - Named contexts, @Throttle decorator, GraphQL integration
- Existing codebase (backend/src) - PushService, DeviceTokenResolver, NarrationService, R2StorageService, expiry-notification.scheduler.ts

### Secondary (MEDIUM confidence)
- [How to handle App store server notification (Medium)](https://medium.com/zen8labs/how-to-handle-app-store-server-notification-1fdd4eaf58c9) - App Store Server Notifications V2 environment field detection
- [Enable billing grace period for auto-renewable subscriptions (Apple Developer)](https://developer.apple.com/help/app-store-connect/manage-subscriptions/enable-billing-grace-period-for-auto-renewable-subscriptions/) - Grace period behavior, EXPIRED notification semantics
- [How to Handle Apple Billing Grace Period in an iOS App (Adapty)](https://adapty.io/blog/how-to-handle-apple-billing-grace-period/) - 60-day recovery window, DID_FAIL_TO_RENEW vs EXPIRED distinction
- [Rate Limiting in NestJS: A Complete Guide (Medium)](https://syedalihamzaofficial.medium.com/rate-limiting-in-nestjs-a-complete-guide-with-examples-49fb5c340bb8) - NestJS throttler best practices
- [get-mp3-duration npm package](https://www.npmjs.com/package/get-mp3-duration) - MP3 duration calculation (v1.0.0, published 8 years ago)

### Tertiary (LOW confidence)
- [App Store Server Notifications V2 validation gist](https://gist.github.com/behe/25ddd9e873f36657776f69e6d4ea8ade) - Community implementation example (not official)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Official Apple library, existing NestJS packages already installed and in use
- Architecture: HIGH - Patterns verified from official docs and existing codebase (PushService, schedulers, R2Storage)
- Pitfalls: MEDIUM-HIGH - Grace period behavior verified from Apple docs, transaction history best practice from community experience

**Research date:** 2026-03-30
**Valid until:** 2026-06-30 (90 days for stable APIs — Apple library and NestJS throttler are mature)
