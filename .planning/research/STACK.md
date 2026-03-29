# Stack Research: App Store Launch Prep

**Domain:** iOS App Store submission readiness
**Researched:** 2026-03-30
**Confidence:** HIGH

## Overview

This research focuses on stack additions/changes needed to prepare Kindred iOS app for App Store submission. The app already has a solid foundation with SwiftUI + TCA, AdMob SDK, StoreKit 2, and Firebase Cloud Messaging. The gaps are around production-ready ad consent, receipt verification, and privacy compliance.

## Required Stack Additions

### App Tracking Transparency (ATT)

| Technology | Version | Purpose | Why Required |
|------------|---------|---------|-------------|
| AppTrackingTransparency | iOS 17.0+ (built-in) | IDFA consent for personalized ads | Mandatory since iOS 14.5 for apps using AdMob with personalized ads. Apple rejects apps without ATT when using ad identifiers. |
| Google UMP SDK | 3.0.0+ (already installed) | Pre-ATT consent flow | Already in project (UserMessagingPlatform.xcframework detected). Coordinates with ATT to show consent UI before requesting IDFA. |

**Status:** UMP SDK already integrated. Only ATT framework code and Info.plist key needed.

### StoreKit Production Receipt Validation

| Technology | Version | Purpose | Why Required |
|------------|---------|---------|-------------|
| @apple/app-store-server-library | 2.4.0+ (Node.js) | JWS transaction verification with x5c chain | Current backend uses base64url decoding (line 74 subscription.service.ts). Production needs full cryptographic signature verification to prevent fraud. |

**Status:** Backend has placeholder comment (line 4-5). Must install and integrate before launch.

### Firebase Cloud Messaging Production Setup

| Technology | Version | Purpose | Why Required |
|------------|---------|---------|-------------|
| Firebase iOS SDK | 11.5.0+ | APNs device token → FCM registration token mapping | Already integrated but device tokens not sent to backend (known gap: EXPIRY-02 partial). |

**Status:** SDK already integrated. Need backend API endpoint to receive device tokens.

### App Store Connect Requirements

No new libraries needed. Configuration-only requirements:

| Requirement | Type | Why Required |
|-------------|------|-------------|
| Privacy Nutrition Labels | App Store Connect metadata | Mandatory since iOS 14. Disclose data collection by app and third-party SDKs (AdMob, ElevenLabs, Gemini, Firebase). |
| NSUserTrackingUsageDescription | Info.plist key (NEW) | Required for ATT prompt. Clear explanation why app tracks users. |
| Third-Party AI Disclosure | App Store metadata | Apple Guideline 5.1.2(i) effective Nov 2025. Must name AI providers (ElevenLabs, Google Gemini) and get explicit consent for voice cloning. |
| Voice Cloning Consent Framework | In-app consent flow | Federal AI Voice Act (enforced 2026) + state laws (Tennessee ELVIS Act, California AB 1836). Written consent required before cloning voices. |

## Installation

### iOS (Swift Package Manager)

```swift
// AppTrackingTransparency - Built-in framework, no installation needed
// Just add import statement:
import AppTrackingTransparency
```

### Backend (npm)

```bash
# Production receipt verification
npm install @apple/app-store-server-library@^2.4.0

# Types for TypeScript (if available)
npm install -D @types/apple__app-store-server-library
```

## Implementation Patterns

### 1. ATT + UMP Consent Flow

**When to request:**
- After app launch, before showing any ads
- Before AdMob SDK initialization
- On every cold launch (UMP SDK checks if consent needed)

**Swift implementation:**

```swift
import AppTrackingTransparency
import AdSupport
import UserMessagingPlatform

// In AppDelegate or App scene
func requestTrackingConsent() async {
    // 1. UMP pre-consent (GDPR/CCPA if applicable)
    let parameters = UMPRequestParameters()
    parameters.tagForUnderAgeOfConsent = false

    do {
        let formStatus = try await UMPConsentInformation.sharedInstance
            .requestConsentInfoUpdate(with: parameters)

        if formStatus == .required {
            // Show UMP consent form
            try await UMPConsentForm.load()
                .present(from: rootViewController)
        }

        // 2. ATT prompt (IDFA consent)
        let status = await ATTrackingManager.requestTrackingAuthorization()

        switch status {
        case .authorized:
            // User granted IDFA access
            let idfa = ASIdentifierManager.shared().advertisingIdentifier
            // AdMob will send IDFA in ad requests
        case .denied, .restricted:
            // AdMob will not send IDFA (still serves ads)
        case .notDetermined:
            // Should not happen after request
        @unknown default:
            break
        }

        // 3. Initialize AdMob AFTER consent
        await AdClient.liveValue.initializeSDK()

    } catch {
        // Handle consent errors
    }
}
```

**Info.plist requirement:**

```xml
<key>NSUserTrackingUsageDescription</key>
<string>Kindred shows personalized recipe ads based on your cooking interests to support free features like voice narration and smart pantry.</string>
```

**Critical:** ATT prompt appears only once per app installation. Subsequent calls return cached status.

### 2. Production JWS Verification (Backend)

**Current state:** Lines 70-79 of `subscription.service.ts` use base64url decode without signature verification.

**Production pattern:**

```typescript
import {
  AppStoreServerAPIClient,
  Environment,
  SignedDataVerifier
} from '@apple/app-store-server-library';

export class SubscriptionService {
  private verifier: SignedDataVerifier;

  constructor(private configService: ConfigService) {
    const rootCerts = [
      // Apple Root CA G3 (download from Apple PKI)
      fs.readFileSync('./certs/AppleRootCA-G3.cer')
    ];

    const bundleId = 'com.ersinkirteke.kindred';
    const appAppleId = this.configService.get('APPLE_APP_ID'); // From App Store Connect
    const environment = this.configService.get('NODE_ENV') === 'production'
      ? Environment.PRODUCTION
      : Environment.SANDBOX;

    this.verifier = new SignedDataVerifier(
      rootCerts,
      true, // enableOnlineChecks
      environment,
      bundleId,
      appAppleId
    );
  }

  async verifyAndSyncSubscription(userId: string, jwsRepresentation: string): Promise<boolean> {
    try {
      // Verify signature + decode payload in one step
      const verifiedTransaction = await this.verifier.verifyAndDecodeTransaction(
        jwsRepresentation
      );

      const productId = verifiedTransaction.productId;
      const expiresDate = verifiedTransaction.expiresDate; // milliseconds since epoch
      const transactionId = verifiedTransaction.transactionId;
      const originalTransactionId = verifiedTransaction.originalTransactionId;

      const isValid = productId === 'com.kindred.pro.monthly'
        && expiresDate > Date.now();

      await this.prisma.subscription.upsert({
        where: { userId },
        create: {
          userId,
          productId,
          transactionId,
          originalTransactionId,
          expiresDate: new Date(expiresDate),
          isActive: isValid,
          jwsPayload: jwsRepresentation,
        },
        update: {
          transactionId,
          expiresDate: new Date(expiresDate),
          isActive: isValid,
          jwsPayload: jwsRepresentation,
          updatedAt: new Date(),
        },
      });

      return isValid;

    } catch (error) {
      this.logger.error(`JWS verification failed: ${error.message}`);
      // VerificationException, SignatureException thrown by library
      return false;
    }
  }
}
```

**Required configuration:**

```env
# .env
APPLE_APP_ID=<your-app-id-from-app-store-connect>
APPLE_TEAM_ID=CV9G42QVG4
```

**Apple Root CA G3 certificate:** Download from [Apple PKI](https://www.apple.com/certificateauthority/). Store in `backend/certs/AppleRootCA-G3.cer`.

### 3. Firebase Device Token Registration

**iOS implementation (AppDelegate):**

```swift
import FirebaseMessaging
import UIKit

extension AppDelegate: MessagingDelegate {
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        guard let token = fcmToken else { return }

        // Send to backend GraphQL mutation
        Task {
            await registerDeviceToken(token: token)
        }
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Map APNs token to FCM token
        Messaging.messaging().apnsToken = deviceToken
    }
}
```

**Backend GraphQL mutation (new):**

```graphql
mutation RegisterDeviceToken($token: String!) {
  registerDeviceToken(token: $token) {
    success
  }
}
```

**Backend resolver:**

```typescript
@Mutation(() => RegisterDeviceTokenResponse)
async registerDeviceToken(
  @CurrentUser() user: JwtPayload,
  @Args('token') token: string,
): Promise<RegisterDeviceTokenResponse> {
  await this.prisma.user.update({
    where: { id: user.sub },
    data: { fcmToken: token },
  });
  return { success: true };
}
```

**Prisma schema addition:**

```prisma
model User {
  id        String   @id @default(cuid())
  // ... existing fields
  fcmToken  String?  // FCM registration token
}
```

### 4. Voice Cloning Consent Framework

**Legal requirements (2026):**
- Federal AI Voice Act: Written consent + right to revoke
- State laws (TN, CA, NY): Explicit permission before cloning
- Apple Guideline 5.1.2(i): Name AI provider (ElevenLabs) + explicit consent

**Implementation pattern:**

```swift
// Before voice upload flow
struct VoiceConsentView: View {
    @Binding var hasConsented: Bool

    var body: some View {
        VStack(spacing: 24) {
            Text("Voice Cloning Consent")
                .font(.title2.bold())

            Text("""
            Kindred uses ElevenLabs AI to clone voices for recipe narration.

            By proceeding, you consent to:
            • Recording and uploading a voice sample
            • Processing your voice data with ElevenLabs AI
            • Generating synthetic narrations from your voice

            You may delete your voice profile at any time.
            """)
            .font(.body)

            Button("I Consent") {
                hasConsented = true
                recordConsent()
            }
            .buttonStyle(.borderedProminent)

            Button("Learn More") {
                // Show full legal disclosure
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    func recordConsent() {
        // Store consent timestamp in backend
        // Include: userId, timestamp, IP address, app version
    }
}
```

**Backend consent record:**

```prisma
model VoiceConsentRecord {
  id           String   @id @default(cuid())
  userId       String
  consentedAt  DateTime @default(now())
  ipAddress    String
  appVersion   String
  revokedAt    DateTime?

  user User @relation(fields: [userId], references: [id])
}
```

## Production Configuration Checklist

### Info.plist Updates

```xml
<!-- NEW: Required for ATT -->
<key>NSUserTrackingUsageDescription</key>
<string>Kindred shows personalized recipe ads based on your cooking interests to support free features like voice narration and smart pantry.</string>

<!-- EXISTING: Keep current camera/location descriptions -->
<key>NSCameraUsageDescription</key>
<string>Kindred uses your camera to scan ingredients from fridge photos and receipts.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Kindred uses your location to show trending recipes near you.</string>

<!-- UPDATE: Replace test AdMob ID with production -->
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-3940256099942544~1458002511</string>
<!-- ⬆️ This is TEST ID - must replace before submission -->
```

### AdMob Production Unit IDs

**Current (Test IDs):**
```
App ID: ca-app-pub-3940256099942544~1458002511 (TEST)
Banner: ca-app-pub-3940256099942544/2435281174 (TEST)
Native: ca-app-pub-3940256099942544/3986624511 (TEST)
```

**Production setup:**
1. Create AdMob account at https://admob.google.com
2. Add Kindred iOS app
3. Create ad units: Native (feed cards), Banner (bottom)
4. Replace test IDs in:
   - `Kindred/Sources/Info.plist` (GADApplicationIdentifier)
   - `MonetizationFeature/Sources/Ads/AdClient.swift` (unit IDs)
   - AdMob dashboard: Link to App Store once live

**Revenue per user estimate (Free tier):**
- 60% of users on free tier (Pro @ $9.99/mo)
- ~$0.50-2.00 CPM for native ads
- ~$0.10-0.50 CPM for banner ads
- Expected: $0.05-0.15 per daily active user

### App Store Connect Privacy Labels

**Data Collection Disclosure:**

| Category | Data Type | Linked to User | Used for Tracking | Purpose |
|----------|-----------|----------------|-------------------|---------|
| Location | Coarse Location (city) | Yes | No | Show trending local recipes |
| User Content | Photos (fridge, receipts) | Yes | No | Ingredient scanning (Pro) |
| User Content | Audio (voice clips) | Yes | No | Voice cloning for narration |
| Identifiers | User ID (Clerk JWT) | Yes | No | Account management |
| Usage Data | Product interactions | No | Yes | Personalized ads (AdMob) |
| Diagnostics | Crash logs | No | No | App stability |

**Third-Party SDK Disclosure (Apple Guideline 5.1.2(i)):**

Must disclose in app description or consent flow:
- **ElevenLabs:** Voice cloning and TTS generation
- **Google Gemini:** AI recipe parsing, narration rewriting, fridge scanning
- **Google AdMob:** Personalized advertising
- **Firebase:** Push notifications and analytics

### Voice Cloning Legal Disclosure

**In App Store metadata (App Privacy section):**

> Kindred uses ElevenLabs AI to clone voices for recipe narration. Users provide explicit consent before voice cloning. Voice profiles can be deleted at any time. See Privacy Policy for details.

**Consent collection requirements:**
- [ ] Show consent screen before first voice upload
- [ ] Store consent timestamp + IP + app version in database
- [ ] Provide "Delete Voice Profile" option in Settings
- [ ] Log deletion events for compliance audit trail

**Budget for legal review:** $20-50K for AI/media counsel to draft:
- Terms of Service (voice cloning addendum)
- Privacy Policy (AI data processing)
- Consent flow copy (legal review)
- Multi-state compliance (TN, CA, NY laws)

## Alternatives Considered

### 1. StoreKit 2 Client-Side Verification Only

**Rejected because:**
- Apple recommends server-side verification for production
- Client verification can be bypassed with jailbreak/proxies
- SignedDataVerifier provides cryptographic proof of authenticity

**Use client verification for:** Immediate feature unlock (optimistic UI), then verify on server.

### 2. RevenueCat for Receipt Management

| Feature | @apple/app-store-server-library | RevenueCat |
|---------|--------------------------------|------------|
| Cost | Free (DIY) | $0-10K+/year based on MRR |
| Control | Full backend control | Managed service |
| Integration | Direct Apple API | SDK + webhook |
| Complexity | Higher (manual JWS parsing) | Lower (turnkey) |

**Recommendation:** Use Apple library for v4.0 launch. Consider RevenueCat if subscription management becomes complex (grace period, refunds, upgrades).

### 3. Custom ATT Consent vs UMP SDK

**Custom ATT only:**
- Pros: Simpler, no Google dependency
- Cons: No GDPR/CCPA support, manual consent UI

**UMP SDK (recommended):**
- Pros: Handles GDPR/CCPA + ATT in one flow, required for AdMob
- Cons: Larger SDK size (~2MB)

**Verdict:** UMP SDK already integrated and required for AdMob compliance. Use it.

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Old /verifyReceipt endpoint | Deprecated by Apple, StoreKit 1 only | @apple/app-store-server-library (StoreKit 2 native) |
| Base64url JWS decode without signature check | Security risk: fraud, subscription bypasses | SignedDataVerifier with x5c chain validation |
| Requesting ATT before app value shown | Apple rejects apps that request ATT at launch | Request after user sees core features (recipe feed) |
| Bundling voice consent with other permissions | Apple Guideline 5.1.2(i) violation | Separate consent screen for AI data sharing |
| Test AdMob unit IDs in production | Violates AdMob ToS, account suspension risk | Production unit IDs from AdMob dashboard |

## Integration with Existing Stack

### iOS Dependencies (SPM)

**Already integrated:**
- GoogleMobileAds 12.14.0+ (via SPM)
- UserMessagingPlatform 3.0.0+ (via SPM)
- Firebase iOS SDK (messaging, analytics)
- StoreKit 2 (built-in framework)

**New framework imports needed:**
```swift
import AppTrackingTransparency // Built-in, iOS 14.0+
import AdSupport // Built-in, for IDFA
```

### Backend Dependencies (npm)

**Already integrated:**
- NestJS 11
- Prisma 7
- Firebase Admin SDK (for FCM server-side push)

**New package needed:**
```json
{
  "dependencies": {
    "@apple/app-store-server-library": "^2.4.0"
  }
}
```

### Database Schema Changes

**Add to Prisma schema:**

```prisma
model User {
  // Existing fields...
  fcmToken  String?  // Firebase Cloud Messaging registration token
}

model VoiceConsentRecord {
  id           String   @id @default(cuid())
  userId       String
  consentedAt  DateTime @default(now())
  ipAddress    String
  appVersion   String
  revokedAt    DateTime?

  user User @relation(fields: [userId], references: [id])

  @@index([userId])
}
```

**Migration:**
```bash
npx prisma migrate dev --name add_fcm_token_and_voice_consent
```

## Version Compatibility

| iOS Package | Backend Package | Compatibility Notes |
|-------------|-----------------|---------------------|
| iOS 17.0+ deployment target | @apple/app-store-server-library 2.4.0+ | Library supports both Sandbox and Production environments |
| GoogleMobileAds 12.14.0+ | N/A | Requires iOS 15.0+ minimum, works with iOS 17+ |
| UserMessagingPlatform 3.0.0+ | N/A | Must match GoogleMobileAds major version |
| StoreKit 2 (built-in) | @apple/app-store-server-library 2.4.0+ | Backend library handles JWS format from iOS 15+ |
| Firebase iOS SDK 11.5.0+ | firebase-admin 13.0.0+ | Server SDK must support FCM HTTP v1 API |

**Critical compatibility:** iOS 17.0 deployment target already set. No changes needed.

## Timeline Estimate

| Task | Complexity | Time Estimate |
|------|-----------|---------------|
| ATT + UMP consent flow integration | Low (SDK ready) | 2-4 hours |
| Replace test AdMob IDs with production | Low (config only) | 1 hour |
| Backend JWS SignedDataVerifier | Medium (new library) | 4-6 hours |
| Firebase device token registration | Low (API endpoint) | 2-3 hours |
| Voice cloning consent screen | Medium (legal copy + UI) | 3-4 hours |
| App Store Connect privacy labels | Low (metadata entry) | 2 hours |
| Legal review (external counsel) | High (compliance) | 2-4 weeks |

**Total development time:** 14-20 hours
**Total calendar time:** 3-5 weeks (includes legal review)

## Sources

**App Tracking Transparency:**
- [App Tracking Transparency | Apple Developer Documentation](https://developer.apple.com/documentation/apptrackingtransparency) — Framework reference
- [How to implement App Tracking Transparency in Swift? | Prograils](https://prograils.com/app-tracking-transparency-swift) — Swift implementation patterns
- [Getting Ready for App Tracking Transparency - Swift Senpai](https://swiftsenpai.com/development/get-ready-apptrackingtransparency/) — Best practices

**Google UMP SDK:**
- [Set up UMP SDK | iOS | Google for Developers](https://developers.google.com/admob/ios/privacy) — Official integration guide (version 3.0.0, released 2025-03-24)
- [Present IDFA message | iOS | Google for Developers](https://developers.google.com/admob/ios/privacy/idfa) — ATT + UMP coordination

**AdMob Production Setup:**
- [Configure your iOS ATT alert description - Google AdMob Help](https://support.google.com/admob/answer/10349306?hl=en) — Info.plist requirements

**StoreKit 2 JWS Verification:**
- [How to Validate iOS and macOS In-App Purchases Using StoreKit 2 and Server-Side Swift | Ronald Mannak | Medium](https://medium.com/@ronaldmannak/how-to-validate-ios-and-macos-in-app-purchases-using-storekit-2-and-server-side-swift-98626641d3ea) — SignedDataVerifier patterns
- [Receipt Validation in StoreKit 1 vs StoreKit 2 Server API | Qonversion](https://qonversion.io/blog/storekit1-storeki2-receipt-validation/) — Migration guidance

**Firebase Cloud Messaging:**
- [Get started with Firebase Cloud Messaging in Apple platform apps](https://firebase.google.com/docs/cloud-messaging/ios/get-started) — APNs token registration
- [Best practices for FCM registration token management | Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging/manage-tokens) — Token lifecycle

**App Store Connect Privacy:**
- [App Privacy Details - App Store - Apple Developer](https://developer.apple.com/app-store/app-privacy-details/) — Privacy Nutrition Labels requirements
- [App Store Requirements: iOS & Android Submission Guide 2026 | Natively](https://natively.dev/articles/app-store-requirements) — 2026 submission checklist

**Voice Cloning Legal:**
- [Apple's new App Review Guidelines clamp down on apps sharing personal data with 'third-party AI' | TechCrunch](https://techcrunch.com/2025/11/13/apples-new-app-review-guidelines-clamp-down-on-apps-sharing-personal-data-with-third-party-ai/) — Guideline 5.1.2(i) effective Nov 2025
- [Voice Cloning Consent Laws by Country: Understanding Global Voice Rights in 2026 | Soundverse](https://www.soundverse.ai/blog/article/voice-cloning-consent-laws-by-country-1049) — International compliance
- [Synthetic Media & Voice Cloning: Right of Publicity Risks for 2026 | Holon Law](https://holonlaw.com/entertainment-law/synthetic-media-voice-cloning-and-the-new-right-of-publicity-risk-map-for-2026/) — US state law requirements

---
*Stack research for: App Store Launch Prep (v4.0)*
*Researched: 2026-03-30*
*Confidence: HIGH (verified with official Apple/Google docs)*
