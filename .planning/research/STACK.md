# Stack Research: iOS App Additions

**Domain:** Native iOS App (SwiftUI + TCA)
**Researched:** 2026-03-01
**Confidence:** HIGH

## Executive Summary

For the Kindred iOS app, the core framework decisions (SwiftUI + TCA) are already made. This research identifies specific libraries needed for GraphQL client communication, voice streaming playback, offline caching, App Store billing, accessibility, and supporting features. The focus is on mature, actively maintained libraries with native SwiftUI support and minimal overlap with TCA's built-in capabilities.

**Key Recommendation:** Leverage iOS 17+ native capabilities wherever possible (URLSession async/await, Core Location, AVFoundation) and add targeted libraries only where native frameworks fall short (GraphQL client, image caching, swipe cards).

## Core Technologies (Already Decided)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| SwiftUI | iOS 17.0+ | Declarative UI framework | Apple's modern UI framework with native async/await, observable state, and NavigationStack |
| TCA (The Composable Architecture) | Latest (1.x) | State management & architecture | Provides @ObservableState, @Dependency, @Shared macros; handles side effects, testability, and composability out-of-box |
| iOS | 17.0+ minimum | Target platform | Clerk iOS SDK v1 requires iOS 17+; aligns with modern SwiftUI features and async/await |

## GraphQL Client

| Library | Version | Purpose | Why Recommended |
|---------|---------|---------|-----------------|
| **Apollo iOS** | **2.0.6** | GraphQL client with code generation | Industry-leading Swift GraphQL client; native async/await support; strongly-typed query/mutation results; built-in caching; actively maintained (released Feb 6, 2026) |

**Why Apollo iOS:**
- Code-first type safety: Generates operation-specific Swift types from your GraphQL schema
- Built for Swift concurrency: Apollo iOS 2.0 rebuilt from ground up for modern async/await patterns
- Native SwiftUI integration: Works seamlessly with @ObservableObject and TCA's @Dependency
- Caching built-in: InMemoryNormalizedCache and SQLiteNormalizedCache for offline support
- Active maintenance: Version 2.0.6 released Feb 2026, fully supports iOS 17+

**Installation:**
```swift
// Swift Package Manager
dependencies: [
    .package(url: "https://github.com/apollographql/apollo-ios.git", from: "2.0.6")
]
```

**Minimum Requirements:** iOS 15+, but recommend iOS 17+ for full async/await support

## Voice Streaming & Playback

| Library | Version | Purpose | Why Recommended |
|---------|---------|---------|-----------------|
| **AVFoundation** | Native (iOS 17) | Audio streaming & playback | Apple's native framework; AVPlayer handles streaming from network URLs; no third-party dependency needed |
| **ElevenLabsKit** (optional) | Latest | Swift SDK for ElevenLabs streaming | Provides Swift-native PCM stream handling for ElevenLabs TTS; alternative to custom REST client |

**Why AVFoundation (Native):**
- Native iOS framework optimized for audio streaming
- AVPlayer supports streaming from network URLs out-of-box
- Background audio playback and media controls (lock screen integration)
- Configurable audio session for playback category
- No external dependencies, maximum compatibility

**ElevenLabs Integration:**
- Backend already uses custom REST client for ElevenLabs (validated in v1.5)
- For iOS: Stream MP3 URL from backend → play via AVPlayer
- Alternative: Use ElevenLabsKit Swift SDK for direct client-side streaming (adds dependency but simplifies integration)
- Latency: ElevenLabs Flash v2.5 = ~75ms, streaming typically responds <500ms

**Recommendation:** Start with AVPlayer streaming MP3 URLs from your NestJS backend. Only add ElevenLabsKit if client-side streaming proves necessary.

## Image Loading & Caching

| Library | Version | Purpose | Why Recommended |
|---------|---------|---------|-----------------|
| **Kingfisher** | **8.0+** | Async image downloading & caching | Pure Swift, native SwiftUI support via KFImage, lightweight, actively maintained, excellent performance |

**Why Kingfisher:**
- Native SwiftUI support: KFImage component integrates seamlessly with SwiftUI views
- Pure Swift: Written in Swift, better type safety and interop than Objective-C alternatives
- Multi-layer caching: Memory + disk cache with configurable TTL
- Modern async/await: Supports Swift concurrency patterns
- Lightweight: Smaller footprint than SDWebImage
- Active maintenance: Version 8.0 released with full SwiftUI support

**Installation:**
```swift
// Swift Package Manager
dependencies: [
    .package(url: "https://github.com/onevcat/Kingfisher.git", from: "8.0.0")
]
```

**Minimum Requirements:** iOS 13.0+ for UIKit, iOS 14.0+ for SwiftUI (your app targets iOS 17+)

**Usage Pattern:**
```swift
import Kingfisher

KFImage(URL(string: recipe.heroImageUrl))
    .placeholder { ProgressView() }
    .retry(maxCount: 3)
    .cacheOriginalImage()
    .resizable()
    .aspectRatio(contentMode: .fill)
```

## Swipe Card UI

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **Custom SwiftUI DragGesture** | Native | Swipe gestures for card stack | **Recommended**: Full control, no dependencies, TCA-friendly |
| **SwipeCardsKit** (alternative) | Latest | Tinder-like swipe cards | If you need pre-built card stack with depth effects |

**Why Custom Implementation:**
- SwiftUI's DragGesture provides all primitives needed
- Full control over swipe thresholds, animations, and TCA state integration
- No external dependency = smaller binary, fewer breaking changes
- TCA makes state management trivial: track card index, swipe direction in reducer

**If Using Library:**
- SwipeCardsKit: Lightweight, customizable, automatic depth effect for top 4 cards
- Supports LeftRight, FourDirections, EightDirections predefined modes
- Easy integration with SwiftUI environment values

**Recommendation:** Build custom swipe with DragGesture unless you need complex depth animations. Estimated implementation: 2-3 hours for basic swipe left/right with rotation.

## Offline Data Caching

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **Apollo iOS Cache** | Built-in | GraphQL response caching | SQLiteNormalizedCache for persistent offline GraphQL data; automatic query result caching |
| **Core Data** (optional) | Native (iOS 17) | Voice profile caching | Native iOS persistence; use for large binary data (voice clips); integrates with SwiftUI @FetchRequest |
| **UserDefaults** | Native | Simple key-value storage | Lightweight persistence for user preferences, feed state, last location |

**Why This Combination:**
- **Apollo Cache:** Already included with Apollo iOS; handles GraphQL offline caching automatically
- **Core Data:** Best for structured data + binary blobs (voice clips); native SwiftUI integration
- **UserDefaults:** Zero-setup persistence for small data (user preferences, feed position)

**Voice Caching Strategy:**
- Cache voice narration MP3 files in Documents directory
- Store file paths + metadata in Core Data
- Cache key: recipeId + voiceProfileId + narrationScriptHash
- Estimated size: ~500KB-1MB per 2-minute recipe narration
- Expiration: 30 days or LRU eviction when storage >100MB

**Apollo Cache Setup:**
```swift
import Apollo
import ApolloSQLite

let sqliteCache = try! SQLiteNormalizedCache(fileURL: cacheFileURL)
let store = ApolloStore(cache: sqliteCache)
let client = ApolloClient(networkTransport: transport, store: store)
```

## App Store Billing (StoreKit 2)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **StoreKit 2** | Native (iOS 17) | In-app subscriptions & purchases | Apple's modern subscription API; async/await native; serverless validation; 2x faster than StoreKit 1 |

**Why StoreKit 2:**
- **Native async/await:** Built for Swift concurrency (iOS 15+)
- **SwiftUI components:** SubscriptionOfferView for merchandising auto-renewable subscriptions (iOS 18.4+)
- **Serverless validation:** On-device transaction validation via App Store Server API
- **Transaction tracking:** appTransactionID provides globally unique user identifier
- **Performance:** 2x faster than StoreKit 1; off-main-thread transactions

**Clerk + StoreKit Integration:**
- Clerk handles authentication (Google/Apple OAuth)
- StoreKit 2 handles subscription state (Free vs Pro tier)
- Sync subscription status to backend GraphQL mutation: `updateUserSubscription(tier: SubscriptionTier!)`
- Backend validates receipt via App Store Server API (JWS verification)

**Key APIs:**
- `Product.SubscriptionInfo`: Query subscription products
- `Transaction.currentEntitlements`: Check active subscriptions
- `Transaction.updates`: Listen for subscription changes
- `SubscriptionOfferView`: SwiftUI view for subscription UI (iOS 18.4+)

**Installation:** No package needed — StoreKit 2 is native to iOS 15+.

**Minimum Requirements:** iOS 15.0+, SwiftUI support in iOS 17+

## Authentication

| Library | Version | Purpose | Why Recommended |
|---------|---------|---------|-----------------|
| **Clerk iOS SDK** | **1.0+** | Authentication (Google/Apple OAuth) | Official Clerk SDK; SwiftUI-first design; prebuilt UI components; unified auth API; released Feb 2026 |

**Why Clerk iOS SDK v1:**
- **Just released (Feb 2026):** v1.0 stable with improved DX and simplified API
- **SwiftUI-native:** Built with SwiftUI in mind; split into ClerkKit (core) + ClerkKitUI (prebuilt views)
- **Unified auth API:** All auth methods under `.auth` namespace
- **Prebuilt components:** SignInView, SignUpView, UserProfileView — no custom forms needed
- **Easy configuration:** `Clerk.configure(...)` at launch, inject via `@Environment(Clerk.self)`
- **Supports backend integration:** Works with your existing Clerk + NestJS GraphQL backend (JWT validation)

**Installation:**
```swift
// Swift Package Manager only (no CocoaPods)
dependencies: [
    .package(url: "https://github.com/clerk/clerk-ios", from: "1.0.0")
]

// Import both
import ClerkKit       // Core auth APIs
import ClerkKitUI     // Prebuilt SwiftUI views
```

**Minimum Requirements:** iOS 17.0+, Xcode 16+, Swift 5.10+

**Backend Integration:**
- iOS app sends Clerk JWT in GraphQL Authorization header
- NestJS backend validates JWT via Clerk webhook/API
- Existing backend auth already configured (validated in v1.5)

## Push Notifications

| Library | Version | Purpose | Why Recommended |
|---------|---------|---------|-----------------|
| **Firebase Cloud Messaging (FCM)** | **12.10.0** | Push notification delivery | Already validated in backend (v1.5); handles iOS APNs routing; SwiftUI compatible |

**Why FCM:**
- **Backend integration:** NestJS backend already uses Firebase Admin SDK (validated in v1.5)
- **APNs routing:** FCM handles APNs token management and message delivery to iOS
- **SwiftUI integration:** Use UIApplicationDelegateAdaptor to register APNs token with FCM
- **Cross-platform:** Same FCM setup works for future Android app

**Installation:**
```swift
// Swift Package Manager or CocoaPods
dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "12.10.0")
]

// Import
import FirebaseMessaging
```

**Minimum Requirements:** iOS 13.0+, Xcode 16.2+

**SwiftUI Integration Pattern:**
```swift
@main
struct KindredApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate {
    func application(_ application: UIApplication,
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}
```

## Location Services

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **Core Location** | Native (iOS 17) | User location & geocoding | Apple's native framework; handles GPS, Wi-Fi, cellular triangulation; SwiftUI integration via CLLocationManager |
| **MapKit** (optional) | Native (iOS 17) | Map display | Only if showing map UI; not required for location-only features |

**Why Core Location (Native):**
- Native iOS framework optimized for location services
- Handles all location sources: GPS, Wi-Fi, Bluetooth, cellular
- Privacy-first: System permissions, location accuracy controls
- No external dependencies

**SwiftUI Integration:**
- Create `LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate`
- Inject via `@StateObject` or TCA `@Dependency`
- Request `whenInUseAuthorization` for feed location
- Send location to backend GraphQL query: `feed(latitude: Float!, longitude: Float!, radius: Float!)`

**Location Strategy:**
- **On app launch:** Request location permission, get current location
- **Feed query:** Pass lat/lng to GraphQL `feed` query (backend filters with PostGIS ST_DWithin)
- **Manual location change:** Let user search city → geocode via backend Mapbox API (already cached)
- **Background location:** Not needed for v2.0 (feed is foreground-only)

**Installation:** No package needed — Core Location is native to iOS.

## Ad SDK (Free Tier)

| Library | Version | Purpose | Why Recommended |
|---------|---------|---------|-----------------|
| **Google Mobile Ads SDK (AdMob)** | **13.1.0** | Banner/interstitial ads for free tier | Industry-standard iOS ad platform; native SwiftUI integration via UIViewRepresentable; highest eCPM |

**Why AdMob:**
- **Industry standard:** Highest fill rates and eCPMs for iOS
- **SwiftUI compatible:** Wrap GADBannerView in UIViewRepresentable for SwiftUI views
- **Easy integration:** SPM or CocoaPods, simple Info.plist configuration
- **Active maintenance:** Version 13.1.0 released Feb 24, 2026

**Installation:**
```swift
// Swift Package Manager or CocoaPods
dependencies: [
    .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", from: "13.1.0")
]

// Import
import GoogleMobileAds
```

**Minimum Requirements:** iOS 13.0+, Xcode 16.0+

**Key Changes in v13:**
- Removed dependency on GoogleAppMeasurement (use Firebase Analytics separately)
- Many deprecated APIs removed (check migration guide)
- String-only `neighboringContentURLStrings` enforcement

**SwiftUI Integration:**
```swift
struct BannerView: UIViewRepresentable {
    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = "ca-app-pub-xxxxx"
        banner.rootViewController = UIApplication.shared.keyWindow?.rootViewController
        banner.load(GADRequest())
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}
```

## Accessibility

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **SwiftUI Accessibility APIs** | Native (iOS 17) | VoiceOver, Dynamic Type, WCAG AAA | Native accessibility modifiers; no library needed; Apple's WCAG-compliant primitives |

**Why Native SwiftUI:**
- **Built-in modifiers:** `.accessibilityLabel()`, `.accessibilityHint()`, `.accessibilityAction()`, `.accessibilityValue()`
- **VoiceOver support:** SwiftUI views are accessible by default; customize with modifiers
- **Dynamic Type:** Automatic font scaling with `.font(.body)`, `.font(.title)`, etc.
- **Touch targets:** SwiftUI respects minimum 44pt (56dp Android) touch targets automatically
- **Trait support:** `.accessibilityAddTraits(.isButton)` for semantic roles

**WCAG AAA Requirements:**
- **Touch targets:** 56dp minimum (SwiftUI buttons already meet this)
- **Text size:** 18sp minimum body text (use `.font(.body)` with Dynamic Type)
- **Contrast:** 7:1 for normal text, 4.5:1 for large text (validate with Xcode Accessibility Inspector)
- **Navigation depth:** Max 3 levels (enforce with tab bar + modal sheets)

**Resources:**
- CVS Health iOS SwiftUI Accessibility Techniques (open-source examples)
- Apple WWDC23: "SwiftUI Accessibility: Beyond the basics"
- Orange Digital Accessibility Guidelines for iOS

**No library needed** — SwiftUI provides all accessibility primitives natively.

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| **Alamofire** | URLSession + async/await is native and sufficient for GraphQL via Apollo | URLSession (native) + Apollo iOS |
| **RealmSwift** | Adds 10MB+ to binary; Apollo cache + Core Data cover all persistence needs | Apollo SQLite cache + Core Data |
| **SwiftLint** (optional) | Not critical for v2.0; focus on feature delivery | Add in v2.1+ for code quality |
| **Lottie** (animations) | Adds complexity; SwiftUI animations sufficient for card swipes and transitions | SwiftUI native animations |
| **Custom navigation libraries** | SwiftUI NavigationStack (iOS 16+) + TCA handle all navigation needs | SwiftUI NavigationStack + TCA |
| **PromiseKit/Combine** | Swift async/await is the modern standard; TCA uses async/await | Swift async/await + TCA Effects |

## What TCA Already Provides (Don't Re-Add)

TCA includes these capabilities — no additional libraries needed:

| Feature | TCA Provides | Don't Add |
|---------|--------------|-----------|
| **State management** | @ObservableState, @Shared macros | Redux libraries, MobX-style state |
| **Dependency injection** | @Dependency property wrapper | Swinject, Resolver |
| **Side effects** | Effect type with async/await support | RxSwift, ReactiveSwift, Combine publishers |
| **Navigation** | NavigationStack integration, @PresentationState | Coordinator pattern libraries |
| **Testing** | TestStore for reducer testing | Additional mocking frameworks |
| **Persistence** | @Shared supports UserDefaults, file storage | Custom persistence wrappers |

## What SwiftUI Already Provides (Don't Re-Add)

| Feature | SwiftUI Provides | Don't Add |
|---------|------------------|-----------|
| **Networking** | URLSession + async/await | Alamofire (Apollo handles GraphQL) |
| **Image caching** | Built-in AsyncImage (but limited) | Use Kingfisher for advanced caching |
| **Animations** | Native animation modifiers | Lottie (unless specific animation assets) |
| **Forms** | Form, TextField, Toggle, Picker | Third-party form builders |
| **Gestures** | DragGesture, TapGesture, LongPressGesture | Custom gesture libraries |
| **Accessibility** | Full VoiceOver, Dynamic Type support | Third-party accessibility libraries |

## Installation Summary

```bash
# Add to Xcode project via Swift Package Manager

# GraphQL Client
https://github.com/apollographql/apollo-ios.git (2.0.6+)

# Image Loading & Caching
https://github.com/onevcat/Kingfisher.git (8.0+)

# Authentication
https://github.com/clerk/clerk-ios (1.0+)

# Push Notifications
https://github.com/firebase/firebase-ios-sdk (12.10.0+)

# Ad SDK
https://github.com/googleads/swift-package-manager-google-mobile-ads.git (13.1.0+)

# Native Frameworks (No Installation)
- AVFoundation (voice playback)
- Core Location (location services)
- StoreKit 2 (subscriptions)
- Core Data (offline persistence)
- SwiftUI Accessibility APIs
```

## Version Compatibility Matrix

| Library | Version | iOS Min | Xcode Min | Notes |
|---------|---------|---------|-----------|-------|
| Apollo iOS | 2.0.6 | 15.0 | 15.0 | Recommend iOS 17+ for full async/await |
| Kingfisher | 8.0+ | 13.0 (UIKit), 14.0 (SwiftUI) | 15.0 | SwiftUI support requires iOS 14+ |
| Clerk iOS SDK | 1.0+ | **17.0** | **16.0** | **Drives minimum iOS version** |
| Firebase iOS SDK | 12.10.0 | 13.0 | 16.2 | FCM + Analytics modules |
| Google Mobile Ads | 13.1.0 | 13.0 | 16.0 | Breaking changes in v13 (check migration guide) |

**Minimum iOS Version for Kindred v2.0:** **iOS 17.0** (driven by Clerk iOS SDK requirement)

## Backend Integration Points

| iOS Component | Backend Integration | Notes |
|---------------|-------------------|-------|
| **Apollo iOS** | NestJS GraphQL API (Apollo Server 5) | Code generation from backend schema; JWT auth in headers |
| **Clerk iOS** | Clerk JWT validation in NestJS | Backend validates JWT via Clerk API; already configured in v1.5 |
| **Firebase FCM** | Firebase Admin SDK in NestJS | Backend sends push notifications; iOS receives via APNs |
| **StoreKit 2** | App Store Server API (JWS validation) | iOS sends receipt → backend validates → updates subscription tier |
| **Core Location** | GraphQL query with lat/lng | `feed(latitude: Float!, longitude: Float!, radius: Float!)` |
| **Voice Playback** | ElevenLabs MP3 URLs from backend | Backend generates narration → stores in R2 → returns URL → iOS streams via AVPlayer |

## Sources

**High Confidence (Official Documentation + Recent Releases):**
- [Apollo iOS 2.0.6 Release](https://github.com/apollographql/apollo-ios) — GraphQL client, Feb 6, 2026
- [Kingfisher 8.0 Documentation](https://github.com/onevcat/Kingfisher) — Image caching, SwiftUI support
- [Clerk iOS SDK v1 Changelog](https://clerk.com/changelog/2026-02-10-ios-android-sdk-v1) — Auth SDK, Feb 10, 2026
- [Google Mobile Ads SDK 13.1.0 Release Notes](https://developers.google.com/admob/ios/rel-notes) — AdMob SDK, Feb 24, 2026
- [Firebase iOS SDK 12.10.0](https://firebase.google.com/support/release-notes/ios) — FCM for iOS
- [StoreKit 2 Documentation](https://developer.apple.com/storekit/) — Apple official docs
- [TCA GitHub Repository](https://github.com/pointfreeco/swift-composable-architecture) — Architecture framework

**Medium Confidence (Community Best Practices):**
- [SwiftUI Accessibility Techniques (CVS Health)](https://github.com/cvs-health/ios-swiftui-accessibility-techniques) — WCAG compliance examples
- [Modern iOS Architecture Comparison](https://7span.com/blog/mvvm-vs-clean-architecture-vs-tca) — TCA vs alternatives
- [AVFoundation Streaming Guide](https://developer.apple.com/documentation/avfoundation) — Apple official docs

---
*Stack research for: Kindred iOS App (v2.0)*
*Researched: 2026-03-01*
*Confidence: HIGH*
