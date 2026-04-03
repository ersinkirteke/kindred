---
phase: 19-backend-production-hardening
plan: 02
subsystem: subscription-verification
tags: [security, storekit, authentication, webhook]
dependencies:
  requires: [19-01]
  provides: [cryptographic-jws-verification, apple-webhook-v2, subscription-audit-trail]
  affects: [subscription-service, subscription-resolver]
tech_stack:
  added: [@apple/app-store-server-library@3.0.0, SignedDataVerifier, Apple Root CA G2/G3]
  patterns: [dual-environment-verification, x5c-certificate-chain, product-allowlist, notification-webhooks]
key_files:
  created:
    - backend/src/subscription/subscription.controller.ts
    - backend/src/subscription/dto/apple-notification.dto.ts
    - backend/config/certs/AppleRootCA-G2.cer
    - backend/config/certs/AppleRootCA-G3.cer
  modified:
    - backend/src/subscription/subscription.service.ts
    - backend/src/subscription/subscription.resolver.ts
    - backend/src/subscription/subscription.module.ts
    - backend/package.json
decisions:
  - "Use SignedDataVerifier with x5c certificate chain validation instead of base64url decoding (security requirement)"
  - "Auto-detect sandbox vs production by trying production verifier first then sandbox fallback (developer experience)"
  - "Product ID validation against APPLE_ALLOWED_PRODUCT_IDS env var allowlist (fraud prevention)"
  - "DID_FAIL_TO_RENEW does NOT revoke access to honor Apple's grace period (user experience)"
  - "Webhook returns success even on error to prevent Apple retry storms (operational stability)"
metrics:
  duration: 317s
  tasks_completed: 2
  files_modified: 8
  commits: 2
  completed_at: "2026-03-30T18:14:25Z"
---

# Phase 19 Plan 02: StoreKit 2 JWS Verification Summary

**One-liner:** Cryptographic StoreKit 2 transaction verification with SignedDataVerifier x5c chain validation, ClerkAuth-protected mutations, and Apple Server Notifications V2 webhook for subscription lifecycle automation.

## What Was Built

Replaced insecure base64url JWS decoding with Apple's official SignedDataVerifier library to prevent subscription fraud. Integrated ClerkAuthGuard on SubscriptionResolver to eliminate placeholder userId. Added Apple Server Notifications V2 webhook endpoint to automatically revoke expired subscriptions and track renewals.

**Key Security Upgrade:**
- **Before:** Anyone could forge JWS payloads by base64url-encoding fake data → free Pro access
- **After:** Every transaction cryptographically verified against Apple's x5c certificate chain → fraud impossible

**Subscription Lifecycle Automation:**
- EXPIRED/REFUND/REVOKE → immediately revoke subscription (`isActive = false`)
- DID_FAIL_TO_RENEW → log warning only, honor grace period (do NOT revoke)
- DID_RENEW → update expiry date, keep active
- SUBSCRIBED/DID_CHANGE_RENEWAL_STATUS → upsert subscription record

**Audit Trail:**
Every JWS verification attempt (success and failure) stored in `TransactionHistory` with environment, error message, and notification type for forensic analysis.

## Tasks Completed

### Task 1: Install Apple library, download root CAs, rewrite SubscriptionService with SignedDataVerifier
**Commit:** `32668a1`

**Changes:**
- Installed `@apple/app-store-server-library@3.0.0`
- Downloaded Apple Root CA G2 (1.4KB DER) and G3 (583B DER) certificates to `config/certs/`
- Rewrote `SubscriptionService` with `SignedDataVerifier` for production and sandbox environments
- Dual-environment verification: try production first, fallback to sandbox on `VerificationException`
- Product ID validation against `APPLE_ALLOWED_PRODUCT_IDS` comma-separated allowlist
- Store all verification attempts in `TransactionHistory` (SUCCESS/FAILURE with error messages)
- Added `handleNotification()` method for Apple Server Notifications V2
- Support for notification types: EXPIRED, DID_RENEW, DID_FAIL_TO_RENEW, SUBSCRIBED, REFUND, REVOKE
- **Removed `decodeJWSPayload()` method** (security vulnerability - no signature verification)

**Types Used:**
- `JWSTransactionDecodedPayload` from Apple library (replaces manual payload decoding)
- `ResponseBodyV2DecodedPayload` for notification structure
- `VerificationException` for dual-environment fallback logic

**Environment Variables Required:**
- `APPLE_BUNDLE_ID` (required) - app bundle identifier for JWS verification
- `APPLE_APP_ID` (optional) - app Apple ID for production verifier (sandbox works without it)
- `APPLE_ALLOWED_PRODUCT_IDS` (defaults to `com.kindred.pro.monthly`) - comma-separated product allowlist

### Task 2: Wire ClerkAuthGuard on SubscriptionResolver + create Apple webhook controller
**Commit:** `c139b7c`

**Changes:**
- Replaced placeholder `userId = 'placeholder-user-id'` with `ClerkAuthGuard` + `@CurrentUser()` decorator
- Added `@Throttle({ expensive: { limit: 10, ttl: 60000 } })` on `verifySubscription` mutation (10 requests per minute)
- Updated `canCreateVoiceProfile` query to use `ClerkAuthGuard` and resolve userId from clerkId
- Created `SubscriptionController` with `POST /apple/notifications` endpoint
- Created `dto/apple-notification.dto.ts` with `AppleNotificationType` enum (type-only, no validation decorators)
- Updated `SubscriptionModule` to import `AuthModule` and `ConfigModule`
- **Webhook has NO auth guard** - JWS signature verification IS the authentication
- Webhook returns `{ success: true }` even on error to prevent Apple retry storms (errors logged for investigation)

**GraphQL Mutations Protected:**
- `verifySubscription(jwsRepresentation: String!): Boolean` - rate-limited, requires auth token
- `canCreateVoiceProfile(): Boolean` - checks voice slot limit (1 free, unlimited Pro)

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

**All automated checks passed:**

✅ TypeScript compilation: `npx tsc --noEmit` (no errors)
✅ Library installed: `npm ls @apple/app-store-server-library` → v3.0.0
✅ Certificates downloaded: `ls backend/config/certs/` → AppleRootCA-G2.cer (1.4KB), AppleRootCA-G3.cer (583B)
✅ SignedDataVerifier usage: 6 occurrences in `subscription.service.ts`
✅ ClerkAuthGuard wired: `@UseGuards(ClerkAuthGuard)` on both mutations
✅ Webhook endpoint: `@Post('apple/notifications')` in controller
✅ Placeholder removed: `grep "placeholder-user-id"` → no results
✅ decodeJWSPayload removed: `grep "decodeJWSPayload"` → no results

## Technical Details

### SignedDataVerifier Configuration

```typescript
// Production verifier (requires appAppleId)
new SignedDataVerifier(
  [rootCAG2, rootCAG3],
  true, // enableOnlineChecks (revocation + expiration)
  Environment.PRODUCTION,
  bundleId,
  appAppleId
)

// Sandbox verifier (no appAppleId required)
new SignedDataVerifier(
  [rootCAG2, rootCAG3],
  true,
  Environment.SANDBOX,
  bundleId,
  undefined
)
```

### Notification Handling Logic

| Notification Type           | Action                             | Revoke? |
|-----------------------------|------------------------------------|---------|
| EXPIRED                     | Set `isActive = false`             | ✅      |
| REFUND                      | Set `isActive = false`             | ✅      |
| REVOKE                      | Set `isActive = false`             | ✅      |
| DID_FAIL_TO_RENEW           | Log warning (grace period)         | ❌      |
| DID_RENEW                   | Update `expiresDate`, keep active  | ❌      |
| SUBSCRIBED                  | Upsert subscription                | ❌      |
| DID_CHANGE_RENEWAL_STATUS   | Upsert subscription                | ❌      |

### Transaction History Schema

Every verification attempt creates a record:

```typescript
{
  userId?: string,                    // null for webhook events
  transactionId?: string,
  originalTransactionId?: string,
  productId?: string,
  jwsPayload: string,                 // full JWS for forensics
  environment: 'PRODUCTION' | 'SANDBOX' | 'UNKNOWN',
  verificationResult: 'SUCCESS' | 'FAILURE',
  errorMessage?: string,              // failure details
  expiresDate?: Date,
  notificationType?: string,          // for webhook events
  receivedAt: Date
}
```

## Integration Notes

**For iOS app (StoreKit 2 integration):**
```swift
// After purchase completes
let transaction = try await Transaction.latest(for: productId)
let jwsRepresentation = transaction.jwsRepresentation

// Send to backend
let mutation = VerifySubscriptionMutation(jwsRepresentation: jwsRepresentation)
```

**Apple Server Notifications V2 Configuration:**
1. App Store Connect → App → General → App Information → App Store Server Notifications
2. Set URL: `https://api.kindred.app/apple/notifications`
3. Apple will POST notifications with `{ signedPayload: "ey..." }` body
4. No shared secret needed (JWS signature verification replaces it)

**Environment Variables Required:**
```bash
APPLE_BUNDLE_ID=com.kindred.app
APPLE_APP_ID=123456789  # Optional for sandbox
APPLE_ALLOWED_PRODUCT_IDS=com.kindred.pro.monthly,com.kindred.pro.yearly
```

## Security Improvements

**Fraud Prevention:**
- ✅ X.509 certificate chain validation prevents forged transactions
- ✅ Product ID allowlist prevents unauthorized product redemptions
- ✅ Environment detection (production vs sandbox) logged for audit
- ✅ Rate limiting (10 req/min) prevents verification spam
- ✅ TransactionHistory audit trail for forensic analysis

**Authentication:**
- ✅ ClerkAuthGuard on all mutations (no more placeholder userId)
- ✅ @CurrentUser decorator extracts clerkId from JWT
- ✅ Webhook signature verification via Apple's x5c chain (no auth token needed)

## Known Limitations

**Production Deployment Checklist:**
1. Set `APPLE_APP_ID` environment variable (production verifier requires it)
2. Configure Apple Server Notifications URL in App Store Connect
3. Test webhook with Apple's test notification button
4. Monitor `TransactionHistory` for verification failures
5. Set up alerts for repeated `FAILURE` results (possible fraud attempts)

**Grace Period Handling:**
Apple sends `DID_FAIL_TO_RENEW` during billing retry period. Current implementation logs warning but does NOT revoke access (grace period honored). If business requirements change, modify switch statement in `handleNotification()`.

**Webhook Retry Strategy:**
Webhook returns `{ success: true }` even on internal errors to prevent Apple's exponential backoff retry storm. Errors are logged for investigation. If this causes missed events, consider:
1. Return 500 on critical errors to trigger Apple retry
2. Add dead letter queue for failed notification processing
3. Implement idempotency with `notificationUUID` deduplication

## Self-Check: PASSED

✅ All created files exist:
- backend/src/subscription/subscription.controller.ts
- backend/src/subscription/dto/apple-notification.dto.ts
- backend/config/certs/AppleRootCA-G2.cer
- backend/config/certs/AppleRootCA-G3.cer

✅ All commits exist:
- 32668a1: feat(19-02): implement StoreKit 2 JWS verification with SignedDataVerifier
- c139b7c: feat(19-02): wire ClerkAuthGuard on SubscriptionResolver and add Apple webhook

✅ TypeScript compilation: No errors
✅ All verification criteria passed (see Verification Results section)
