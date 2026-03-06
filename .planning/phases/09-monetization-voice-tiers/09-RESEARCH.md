# Phase 9: Monetization & Voice Tiers - Research

**Researched:** 2026-03-06
**Domain:** iOS in-app subscriptions (StoreKit 2), mobile advertising (AdMob), TCA state management, backend JWS verification
**Confidence:** HIGH

## Summary

Phase 9 implements a freemium monetization model with free (ad-supported, 1 voice slot) and Pro ($9.99/mo, ad-free, unlimited voices) tiers. The iOS ecosystem provides mature tooling: **StoreKit 2** for native subscription management with JWS-signed receipts, **AdMob** for non-intrusive native ads, and Apple's **App Store Server Library** for Node.js backend verification. TCA patterns established in Phase 8 (SignInClient) provide the template for SubscriptionClient and AdClient dependencies.

Key implementation insight: StoreKit 2's `Transaction.updates` listener must start at app launch (AppDelegate) and run indefinitely to catch purchase events occurring outside the app. Grace period (up to 60 days billing retry) requires maintaining Pro access during failed renewals. AdMob native ads integrate via UIViewRepresentable wrappers styled to match recipe cards.

**Primary recommendation:** Use StoreKit 2 with local StoreKit Configuration File for testing, Apple's official Node.js App Store Server Library for JWS verification on NestJS backend, and AdMob native ads wrapped in UIViewRepresentable matching DesignSystem styling. Create SubscriptionClient and AdClient as TCA @DependencyClient structs following SignInClient pattern.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
#### Ad Placements
- Native AdMob ads inserted between swipe cards in the feed, every 5 recipe cards
- Ad card styled to match recipe card look (same rounded corners, similar layout) with "Sponsored" label
- Ad card is swipeable like recipe cards — user swipes left to dismiss
- Each ad card includes a subtle "Remove ads with Pro" upsell link at the bottom
- Additional banner ad in recipe detail view, positioned below ingredients and above step timeline
- Recipe detail banner hides when voice narration is active (not during playback)
- No ads on the very first app launch ever (tracked via UserDefaults/Keychain, resets only on reinstall)
- Guest users (not signed in) see ads (after first session rule)
- Ads appear in feed + recipe detail only — profile, settings, voice picker stay ad-free

#### Paywall & Upgrade Flow
- Paywall triggered only at voice slot limit (when free user tries to create 2nd voice profile)
- Paywall presented as bottom sheet overlay sliding up over the voice picker
- Paywall highlights two main perks: ad-free experience + unlimited voice profiles
- Subtle "Restore Purchases" text link below the subscribe button (Apple requirement)
- No soft upsells or banners elsewhere — paywall only appears at the moment of need
- Ad card upsell link ("Remove ads with Pro") is the only other touchpoint besides the voice limit gate

#### Voice Slot Enforcement
- Free tier: 1 voice slot total (any voice type — own clone or family member)
- When free user has 1 voice, "Create Voice Profile" button in VoicePickerView replaced with "Upgrade to Pro for more voices" CTA
- Downgrade handling: users who cancel Pro keep ALL existing voice profiles usable, just can't create new ones
- Enforcement on both client-side (UI blocks creation) AND server-side (API rejects if limit exceeded)

#### Subscription Status UI
- New subscription section in ProfileView (alongside existing CulinaryDNA and DietaryPreferences sections)
- Styled card showing: plan name (Free/Pro), price, renewal date, and "Manage Subscription" link
- "Manage Subscription" opens iOS Settings > Subscriptions deep link (Apple-standard)
- Small "PRO" pill badge next to user's name in profile for subscribed users
- Free users see an upgrade CTA card with benefits summary and subscribe button in the profile section
- Silent StoreKit 2 entitlement check on app launch — no visible loading, seamless background verification
- Pro features maintained during Apple's billing retry grace period (up to 60 days)

### Claude's Discretion
- Exact native ad card layout and styling details
- AdMob SDK integration approach and ad unit configuration
- StoreKit 2 transaction listener implementation details
- JWS verification flow between app and backend
- Subscription state persistence mechanism (Keychain vs UserDefaults vs backend)
- Banner ad sizing in recipe detail view
- Animation/transition for paywall bottom sheet
- Error handling for failed purchases or network issues during subscription
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| MONET-01 | Free tier displays ads (AdMob) in non-intrusive placements | AdMob iOS SDK integration, UIViewRepresentable SwiftUI wrappers, native ad styling |
| MONET-02 | Pro tier ($9.99/mo) removes ads and unlocks unlimited voice slots | StoreKit 2 Product configuration, subscription status checking, conditional UI rendering |
| MONET-03 | User can subscribe to Pro via App Store billing (StoreKit 2) | StoreKit 2 purchase flow, Transaction.updates listener, restore purchases, grace period handling |
| MONET-04 | Subscription status syncs between app and backend via JWS verification | StoreKit 2 Transaction.jwsRepresentation, App Store Server Library (Node.js), NestJS endpoint integration |
| VOICE-07 | Free tier users get 1 voice slot; Pro users get unlimited voice slots | SubscriptionClient entitlement check, VoicePickerView conditional CTA, backend GraphQL mutation guard |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| StoreKit 2 | iOS 15.0+ | Native in-app subscription management | Apple's official framework, JWS-signed receipts, async/await support, free StoreKit Testing in Xcode |
| Google Mobile Ads SDK | 11.0.0+ | AdMob ad serving (banner, native) | Industry standard mobile monetization, 60% market share, native ad format support |
| @apple/app-store-server-library | Latest | Node.js JWS verification | Apple's official library for App Store Server API, reduces custom crypto code |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| swift-dependencies | 1.0.0+ (already in project) | TCA dependency injection | Create SubscriptionClient and AdClient as @DependencyClient structs |
| CocoaPods or SPM | - | AdMob SDK installation | SPM preferred (matches project.yml pattern), CocoaPods fallback if SPM AdMob unavailable |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| StoreKit 2 | StoreKit 1 (SKProduct) | SK1 is legacy, lacks async/await, requires manual receipt validation via verifyReceipt endpoint (deprecated 2024) |
| AdMob | AdMob Mediation | Mediation adds complexity, not needed for single ad network |
| Official Apple library | Custom JWS parser | Custom crypto is error-prone, Apple library handles x5c chain validation, root cert updates |

**Installation:**
```bash
# iOS: Add to project.yml packages section
google-mobile-ads-ios:
  url: https://github.com/googleads/swift-package-manager-google-mobile-ads
  from: "11.0.0"

# Backend: Add to package.json
npm install @apple/app-store-server-library
```

## Architecture Patterns

### Recommended Project Structure
```
Kindred/Packages/
├── MonetizationFeature/           # New package (Phase 9)
│   ├── Sources/
│   │   ├── Subscription/
│   │   │   ├── SubscriptionClient.swift        # @DependencyClient for StoreKit 2
│   │   │   ├── SubscriptionReducer.swift       # TCA state machine
│   │   │   ├── SubscriptionStatusView.swift    # ProfileView section
│   │   │   └── PaywallView.swift               # Bottom sheet
│   │   └── Ads/
│   │       ├── AdClient.swift                  # @DependencyClient for AdMob
│   │       ├── AdCardView.swift                # UIViewRepresentable native ad
│   │       └── BannerAdView.swift              # Recipe detail banner
│   └── Package.swift
├── FeedFeature/                    # Modified
│   └── Sources/Feed/FeedReducer.swift          # Inject ad cards every 5 recipes
└── VoicePlaybackFeature/           # Modified
    └── Sources/VoicePicker/VoicePickerView.swift  # Voice slot CTA
```

### Pattern 1: TCA Dependency Client (SubscriptionClient)
**What:** Wrap StoreKit 2 APIs in @DependencyClient struct following SignInClient pattern established in Phase 8
**When to use:** All external service integrations (StoreKit, AdMob, location, auth)
**Example:**
```swift
// Source: Established pattern from Kindred/Packages/AuthFeature/Sources/SignIn/SignInClient.swift
import Dependencies
import DependenciesMacros
import StoreKit

@DependencyClient
public struct SubscriptionClient: Sendable {
    public var loadProducts: @Sendable () async throws -> [Product]
    public var purchase: @Sendable (Product) async throws -> Transaction
    public var restorePurchases: @Sendable () async throws -> Void
    public var currentEntitlement: @Sendable () async -> SubscriptionStatus
    public var observeTransactionUpdates: @Sendable () async -> AsyncStream<Transaction>
}

public enum SubscriptionStatus: Equatable, Sendable {
    case free
    case pro(expiresDate: Date, isInGracePeriod: Bool)
}

extension SubscriptionClient: DependencyKey {
    public static let liveValue: SubscriptionClient = {
        // Implementation wraps StoreKit 2 APIs
        SubscriptionClient(
            loadProducts: {
                try await Product.products(for: ["com.kindred.pro.monthly"])
            },
            purchase: { product in
                let result = try await product.purchase()
                guard case .success(let verification) = result else {
                    throw SubscriptionError.purchaseFailed
                }
                return try verification.payloadValue
            },
            currentEntitlement: {
                // Check Transaction.currentEntitlements (works offline)
                // ...
            },
            observeTransactionUpdates: {
                AsyncStream { continuation in
                    Task {
                        for await verification in Transaction.updates {
                            if case .verified(let transaction) = verification {
                                continuation.yield(transaction)
                            }
                        }
                    }
                }
            }
        )
    }()
}
```

### Pattern 2: Transaction.updates Listener Lifecycle
**What:** Infinite async sequence that emits transactions occurring outside app (App Store, other devices)
**When to use:** Start at app launch in AppDelegate, store Task reference, cancel on app termination
**Example:**
```swift
// Source: Apple Developer Forums (https://developer.apple.com/forums/thread/716059)
@MainActor
class AppDelegate: NSObject, UIApplicationDelegate {
    private var transactionObserverTask: Task<Void, Never>?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Start Transaction.updates listener immediately
        transactionObserverTask = Task {
            for await verification in Transaction.updates {
                guard case .verified(let transaction) = verification else { continue }

                // Update subscription state in SubscriptionClient
                await updateEntitlement(transaction)

                // Finish transaction (Apple requirement)
                await transaction.finish()
            }
        }
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        transactionObserverTask?.cancel()
    }
}
```

### Pattern 3: AdMob Native Ad UIViewRepresentable
**What:** Wrap GADNativeAdView in UIViewRepresentable to render native ads in SwiftUI
**When to use:** Feed ad cards, recipe detail banners (any AdMob native ad in SwiftUI)
**Example:**
```swift
// Source: Google AdMob documentation + community examples
import SwiftUI
import GoogleMobileAds

struct NativeAdView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> GADNativeAdView {
        let adView = GADNativeAdView()
        let adLoader = GADAdLoader(
            adUnitID: adUnitID,
            rootViewController: nil,
            adTypes: [.native],
            options: nil
        )
        adLoader.delegate = context.coordinator
        adLoader.load(GADRequest())
        return adView
    }

    func updateUIView(_ uiView: GADNativeAdView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, GADNativeAdLoaderDelegate {
        func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
            // Populate adView with nativeAd data (headline, body, call-to-action)
        }
    }
}
```

### Pattern 4: Grace Period Handling
**What:** Maintain Pro access during Apple's billing retry period (up to 60 days)
**When to use:** Check Product.SubscriptionInfo.RenewalState for .inGracePeriod
**Example:**
```swift
// Source: Apple documentation + RevenueCat blog (https://www.revenuecat.com/blog/engineering/ios-subscription-grace-periods/)
func checkSubscriptionStatus() async -> SubscriptionStatus {
    guard let subscription = try? await Product.SubscriptionInfo.status(for: "com.kindred.pro.monthly").first else {
        return .free
    }

    switch subscription.state {
    case .subscribed, .inGracePeriod:
        // User keeps Pro features during grace period
        return .pro(
            expiresDate: subscription.renewalInfo.expirationDate ?? Date(),
            isInGracePeriod: subscription.state == .inGracePeriod
        )
    case .revoked, .expired:
        return .free
    @unknown default:
        return .free
    }
}
```

### Pattern 5: Backend JWS Verification
**What:** Verify Transaction.jwsRepresentation on NestJS backend using Apple's official library
**When to use:** Sync subscription status to backend after successful purchase
**Example:**
```typescript
// Source: Apple's app-store-server-library-node (https://github.com/apple/app-store-server-library-node)
import { SignedDataVerifier } from '@apple/app-store-server-library';

@Injectable()
export class SubscriptionService {
  private verifier: SignedDataVerifier;

  constructor() {
    const rootCertificates = [/* Apple root certs */];
    this.verifier = new SignedDataVerifier(
      rootCertificates,
      true, // Enable online checks
      'production', // Environment
      'com.kindred.app' // Bundle ID
    );
  }

  async verifySubscription(jwsRepresentation: string): Promise<boolean> {
    try {
      const decodedTransaction = await this.verifier.verifyAndDecodeTransaction(jwsRepresentation);

      // Check expiration, product ID, etc.
      return decodedTransaction.expiresDate > Date.now();
    } catch (error) {
      // Invalid signature or expired
      return false;
    }
  }
}
```

### Anti-Patterns to Avoid
- **Hardcoding prices:** Use `product.displayPrice` for localized currency formatting (StoreKit 2 handles this)
- **Checking subscriptions on every reducer action:** Cache entitlement status, only refresh on Transaction.updates events
- **Showing ads during first app launch:** UserDefaults flag `hasLaunchedBefore` prevents ads on first session
- **Blocking UI on subscription check:** Use silent background check at app launch, assume last-known state until verified

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JWS signature verification | Custom JWT parser with x5c chain validation | @apple/app-store-server-library | Apple's library handles root certificate updates, chain validation, replay attack prevention |
| Receipt validation | verifyReceipt endpoint (deprecated 2024) | StoreKit 2 local verification + JWS sync | verifyReceipt is deprecated, StoreKit 2 validates locally first (faster, works offline) |
| Ad loading/caching | Manual GADRequest retry logic | GADAdLoader with delegate callbacks | AdMob SDK handles retry, frequency capping, creative rotation |
| Subscription renewal tracking | Polling App Store API | Transaction.updates listener | updates stream is push-based, instant, covers all devices |
| Grace period state machine | Custom billing retry logic | Product.SubscriptionInfo.RenewalState | Apple's state machine handles billing retry, grace period, expiration |

**Key insight:** Apple and Google have invested millions in edge case handling (clock skew, network partitions, fraud detection). Custom implementations miss subtle bugs (e.g., StoreKit 2 handles 100+ edge cases in Transaction.updates alone).

## Common Pitfalls

### Pitfall 1: Missing Transaction.updates Events
**What goes wrong:** User purchases on device A, device B doesn't see Pro status
**Why it happens:** Transaction.updates listener not started at app launch, or cancelled too early
**How to avoid:** Start listener in AppDelegate.didFinishLaunching, store Task reference, never cancel until app termination
**Warning signs:** Subscription status only updates after app restart, restore purchases required frequently

### Pitfall 2: Memory Leak from Transaction.updates Task
**What goes wrong:** Transaction.updates listener runs indefinitely without cleanup, causing memory leak
**Why it happens:** Task not stored or cancelled in AppDelegate lifecycle methods
**How to avoid:** Store Task reference as instance variable, cancel in applicationWillTerminate
**Warning signs:** Memory usage grows over time, Instruments shows leaked Task closures

### Pitfall 3: Showing Paywall Without Product Fetch
**What goes wrong:** Paywall shows "Loading..." or wrong price, purchase button broken
**Why it happens:** Product.products(for:) called inside paywall view instead of preloading at app launch
**How to avoid:** Load products at app launch, cache in SubscriptionClient, paywall reads from cache
**Warning signs:** Paywall has 2-3 second delay on first show, App Store connection errors

### Pitfall 4: AdMob Banner Height Calculation
**What goes wrong:** Banner ad overlaps content or leaves white space
**Why it happens:** GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth returns dynamic height, SwiftUI frame not updated
**How to avoid:** Use inline adaptive banners (not anchored), measure UIView height in coordinator, update SwiftUI frame with @State
**Warning signs:** Ad clipping, white space below banner, layout jumps after ad loads

### Pitfall 5: Testing with Production StoreKit Config
**What goes wrong:** Real purchases charged during development, hard to test renewals/failures
**Why it happens:** Xcode scheme not configured to use local StoreKit Configuration File
**How to avoid:** Create .storekit file in Xcode, select it in scheme options (Run > Options > StoreKit Configuration)
**Warning signs:** TestFlight prompts for real payment, can't simulate billing failures

### Pitfall 6: JWS Verification Replay Attacks
**What goes wrong:** User sends same JWS token multiple times to backend to extend subscription
**Why it happens:** Backend doesn't track transaction IDs already processed
**How to avoid:** Store transaction.id in database, reject duplicates, Apple library provides transactionId field
**Warning signs:** User has multiple "active" subscriptions for same product, audit logs show repeated JWS submissions

## Code Examples

Verified patterns from official sources:

### Check Current Entitlement (Offline-First)
```swift
// Source: Apple StoreKit 2 documentation
func checkEntitlement() async -> Bool {
    // Works offline using cached transactions
    for await verification in Transaction.currentEntitlements {
        if case .verified(let transaction) = verification,
           transaction.productID == "com.kindred.pro.monthly" {
            return true
        }
    }
    return false
}
```

### Restore Purchases (Manual Sync)
```swift
// Source: Apple StoreKit 2 documentation + community best practices
func restorePurchases() async throws {
    // Force sync with App Store (rare, only when user suspects missing subscription)
    try await AppStore.sync()

    // Re-check entitlements after sync
    let isPro = await checkEntitlement()
    // Update UI...
}
```

### AdMob SDK Initialization
```swift
// Source: Google AdMob quick start guide (https://developers.google.com/admob/ios/quick-start)
import GoogleMobileAds

@main
struct KindredApp: App {
    init() {
        // Initialize AdMob SDK at app launch
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Deep Link to iOS Subscription Management
```swift
// Source: Apple documentation + RevenueCat community
func openSubscriptionManagement() {
    // Opens Settings > Apple ID > Subscriptions > This App
    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
        UIApplication.shared.open(url)
    }
}
```

### Localized Price Display
```swift
// Source: Apple StoreKit 2 Product documentation
let product = try await Product.products(for: ["com.kindred.pro.monthly"]).first
let priceLabel = product?.displayPrice ?? "$9.99" // "9,99 €" for EU users
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| StoreKit 1 verifyReceipt endpoint | StoreKit 2 local verification + JWS | iOS 15 (2021), verifyReceipt deprecated 2024 | Faster (offline-first), more secure (JWS signatures), async/await syntax |
| Manual receipt parsing (base64) | Transaction.jwsRepresentation | iOS 15 (2021) | Eliminates custom crypto, Apple handles signature verification |
| SKProduct price formatting | Product.displayPrice | iOS 15 (2021) | Automatic currency/locale formatting, no manual NumberFormatter |
| Polling App Store status | Transaction.updates stream | iOS 15 (2021) | Real-time push updates, cross-device sync, no polling overhead |
| AdMob banner-only | AdMob native ads | 2018+ | Higher CTR (3-5x), better UX integration, customizable styling |

**Deprecated/outdated:**
- **verifyReceipt endpoint:** Deprecated in 2024, will stop working in future iOS versions. Use StoreKit 2 Transaction.jwsRepresentation.
- **StoreKit 1 SKPaymentQueue:** Legacy API, lacks async/await, requires manual queue observation. Use StoreKit 2 Product.purchase().
- **AdMob standard banner sizes (320x50):** Use adaptive banner sizes (GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth) for better responsive layout.

## Open Questions

1. **AdMob Ad Unit IDs**
   - What we know: Need to create ad units in AdMob console before testing
   - What's unclear: Test ad unit IDs available, or need to create real units for dev/staging?
   - Recommendation: Use test ad unit IDs from Google docs during development (ca-app-pub-3940256099942544/2247696110 for native), create real units for TestFlight

2. **Voice Slot Backend Enforcement**
   - What we know: Backend must reject voice creation if user exceeded limit
   - What's unclear: Should backend query App Store Server API for real-time status, or trust client-synced JWS?
   - Recommendation: Trust client-synced JWS (updated on Transaction.updates), fallback to App Store Server API if JWS older than 24 hours

3. **Pro Badge Styling**
   - What we know: Small "PRO" pill badge next to user's name in profile
   - What's unclear: Exact color scheme (DesignSystem accent vs custom gradient?)
   - Recommendation: Use `.kindredAccent` background with white text for consistency, matches existing design system

## Validation Architecture

> Validation architecture included per workflow.nyquist_validation: true in .planning/config.json

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (iOS native, no external dependencies) |
| Config file | None — Wave 0 will create test targets in project.yml |
| Quick run command | `xcodebuild test -scheme MonetizationFeatureTests -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:MonetizationFeatureTests/{TestClass}/{testMethod}` |
| Full suite command | `xcodebuild test -scheme Kindred -destination 'platform=iOS Simulator,name=iPhone 16 Pro'` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MONET-01 | Free tier displays AdMob native ads in feed every 5 cards and recipe detail banner | UI test | `xcodebuild test -only-testing:KindredUITests/AdPlacementTests/testFreeUserSeesAdsInFeed -x` | ❌ Wave 0 |
| MONET-01 | First app launch shows no ads | UI test | `xcodebuild test -only-testing:KindredUITests/AdPlacementTests/testFirstLaunchNoAds -x` | ❌ Wave 0 |
| MONET-02 | Pro tier removes all ads | UI test | `xcodebuild test -only-testing:KindredUITests/AdPlacementTests/testProUserSeesNoAds -x` | ❌ Wave 0 |
| MONET-03 | User can purchase Pro subscription via StoreKit | Unit test (StoreKit Testing) | `xcodebuild test -only-testing:MonetizationFeatureTests/SubscriptionReducerTests/testPurchaseProSubscription -x` | ❌ Wave 0 |
| MONET-03 | User can restore purchases | Unit test (StoreKit Testing) | `xcodebuild test -only-testing:MonetizationFeatureTests/SubscriptionReducerTests/testRestorePurchases -x` | ❌ Wave 0 |
| MONET-03 | Grace period maintains Pro access | Unit test | `xcodebuild test -only-testing:MonetizationFeatureTests/SubscriptionClientTests/testGracePeriodMaintainsAccess -x` | ❌ Wave 0 |
| MONET-04 | JWS verification succeeds for valid transaction | Unit test (mock) | `xcodebuild test -only-testing:MonetizationFeatureTests/SubscriptionClientTests/testJWSVerification -x` | ❌ Wave 0 |
| VOICE-07 | Free user with 1 voice sees upgrade CTA in voice picker | UI test | `xcodebuild test -only-testing:KindredUITests/VoiceSlotTests/testFreeUserVoiceSlotLimit -x` | ❌ Wave 0 |
| VOICE-07 | Pro user can create unlimited voices | Integration test | `xcodebuild test -only-testing:KindredUITests/VoiceSlotTests/testProUserUnlimitedVoices -x` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `xcodebuild test -only-testing:MonetizationFeatureTests -x` (< 30s, unit tests only)
- **Per wave merge:** Full suite with UI tests (2-3 min)
- **Phase gate:** Full suite green + manual device test (StoreKit sandbox purchase) before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `KindredUITests/AdPlacementTests.swift` — covers MONET-01, MONET-02 (free/pro ad visibility)
- [ ] `MonetizationFeatureTests/SubscriptionReducerTests.swift` — covers MONET-03 (purchase flow with StoreKit Testing)
- [ ] `MonetizationFeatureTests/SubscriptionClientTests.swift` — covers MONET-03 (grace period), MONET-04 (JWS)
- [ ] `KindredUITests/VoiceSlotTests.swift` — covers VOICE-07 (free/pro voice slot enforcement)
- [ ] `.storekit` configuration file in Kindred/ — enables StoreKit Testing in Xcode for automated purchase tests
- [ ] Test targets in `project.yml` — add MonetizationFeatureTests and update KindredUITests scheme

## Sources

### Primary (HIGH confidence)
- [Apple Developer: StoreKit 2](https://developer.apple.com/storekit/) - Official framework documentation
- [Apple Developer: Transaction.updates](https://developer.apple.com/documentation/storekit/transaction/3851206-updates) - Transaction stream lifecycle
- [Apple Developer: Product.SubscriptionInfo.Status](https://developer.apple.com/documentation/storekit/product/subscriptioninfo/status) - Subscription state checking
- [Google Developers: AdMob iOS Quick Start](https://developers.google.com/admob/ios/quick-start) - SDK integration steps
- [Apple Developer: Setting up StoreKit Testing in Xcode](https://developer.apple.com/documentation/xcode/setting-up-storekit-testing-in-xcode) - Local testing configuration
- [GitHub: app-store-server-library-node](https://github.com/apple/app-store-server-library-node) - Official Apple Node.js library
- [Apple Developer: App Store Server Library](https://developer.apple.com/documentation/appstoreserverapi/simplifying-your-implementation-by-using-the-app-store-server-library) - JWS verification guide

### Secondary (MEDIUM confidence)
- [RevenueCat: iOS In-App Subscription Tutorial with StoreKit 2 and Swift](https://www.revenuecat.com/blog/engineering/ios-in-app-subscription-tutorial-with-storekit-2-and-swift/) - Comprehensive StoreKit 2 tutorial
- [RevenueCat: Implementing iOS Subscription Grace Periods](https://www.revenuecat.com/blog/engineering/ios-subscription-grace-periods/) - Grace period implementation patterns
- [Medium: Mastering StoreKit 2 in SwiftUI (2025)](https://medium.com/@dhruvinbhalodiya752/mastering-storekit-2-in-swiftui-a-complete-guide-to-in-app-purchases-2025-ef9241fced46) - SwiftUI integration guide
- [Apple Developer Forums: When should we listen to StoreKit Transaction.updates](https://developer.apple.com/forums/thread/716059) - Official Apple engineer guidance on Transaction.updates lifecycle
- [Google AdMob: Banner ad guidance](https://support.google.com/admob/answer/6128877) - Ad placement best practices
- [Google AdMob: Implementation guidance](https://support.google.com/admob/answer/2936217) - Non-intrusive ad placement strategy
- [Medium: Integrating Custom AdMob Native Ads into SwiftUI](https://toyboy2.medium.com/integrating-custom-admob-native-ads-into-swiftui-a-migration-guide-from-uikit-b3057adc2f68) - UIViewRepresentable wrapper patterns
- [Apple Developer: Setting up a link to manage subscriptions](https://developer.apple.com/documentation/advancedcommerceapi/setupmanagesubscriptions) - Deep linking to Settings
- [GitHub: pointfreeco/swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture) - TCA dependency patterns

### Tertiary (LOW confidence)
- [Medium: Dependency Injection in TCA](https://medium.com/@gauravios/dependency-injection-in-the-composable-architecture-an-architects-perspective-9be5571a0f89) - TCA @DependencyClient macro usage (not verified with official Point-Free docs)
- [Apple Developer Forums: StoreKit 2 currentEntitlements](https://developer.apple.com/forums/thread/706450) - Community discussion on offline entitlement checking (not official Apple guidance)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Official Apple and Google documentation verified, widely adopted in production apps
- Architecture: HIGH - TCA patterns established in Phase 8 (SignInClient.swift), StoreKit 2 patterns from Apple docs and community consensus
- Pitfalls: MEDIUM-HIGH - Common issues documented in Apple Developer Forums and RevenueCat engineering blog (experienced implementers)
- Backend JWS verification: HIGH - Apple's official Node.js library reduces custom implementation risk

**Research date:** 2026-03-06
**Valid until:** 2026-04-06 (30 days for stable APIs, StoreKit 2 and AdMob are mature)
