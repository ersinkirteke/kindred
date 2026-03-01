# Architecture Research: iOS App Integration with NestJS GraphQL Backend

**Domain:** iOS mobile app (SwiftUI + TCA) consuming GraphQL API
**Researched:** 2026-03-01
**Confidence:** HIGH

## Executive Summary

The iOS app architecture follows **The Composable Architecture (TCA)** pattern with modular features, consuming the existing NestJS GraphQL backend via **Apollo iOS client**. The architecture emphasizes **offline-first data persistence**, **real-time voice streaming**, **accessibility-first design**, and **testability through dependency injection**. All features are built as isolated Swift Package Manager modules with clear boundaries between presentation (SwiftUI), state management (TCA Reducers), data layer (Apollo GraphQL + local cache), and platform services (AVFoundation, StoreKit 2, Firebase).

The existing backend provides 100% of business logic—recipe scraping, AI image generation, voice cloning, and narration generation. The iOS app is purely a **presentation and interaction layer** that streams data from GraphQL, caches for offline use, and provides native platform features (App Store billing, VoiceOver accessibility, background audio playback).

## System Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Presentation Layer (SwiftUI)                     │
├─────────────────────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐ │
│  │  Feed    │  │  Recipe  │  │  Voice   │  │  Profile │  │ Onboard  │ │
│  │  Feature │  │  Detail  │  │  Player  │  │  Feature │  │  Feature │ │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘ │
│       │             │             │             │             │        │
├───────┴─────────────┴─────────────┴─────────────┴─────────────┴────────┤
│                    State Management Layer (TCA Reducers)                │
├─────────────────────────────────────────────────────────────────────────┤
│  Each feature has State, Action, Reducer + Dependencies                 │
│  Unidirectional data flow: Action → Reducer → State → View              │
├─────────────────────────────────────────────────────────────────────────┤
│                         Data & Service Layer                             │
├─────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │
│  │   Apollo    │  │ AVFoundation│  │  StoreKit2  │  │   Firebase  │   │
│  │   GraphQL   │  │   Audio     │  │   Billing   │  │     FCM     │   │
│  │   Client    │  │   Streaming │  │   Service   │  │   Messaging │   │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘   │
│         │                │                │                │           │
├─────────┴────────────────┴────────────────┴────────────────┴───────────┤
│                     Local Storage & Cache Layer                         │
├─────────────────────────────────────────────────────────────────────────┤
│  ┌────────────────────┐  ┌────────────────────┐  ┌──────────────────┐  │
│  │  Apollo SQLite     │  │  SwiftData/Core    │  │  Cached Audio    │  │
│  │  GraphQL Cache     │  │  Data (User Prefs) │  │  Files (R2 URLs) │  │
│  └────────────────────┘  └────────────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
                                   ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                     External Services (Existing Backend)                 │
├─────────────────────────────────────────────────────────────────────────┤
│  NestJS 11 + GraphQL (Apollo Server 5) + Prisma 7 + PostgreSQL 15      │
│  - Recipe scraping, AI image gen, voice cloning, narration generation   │
│  - Clerk JWT auth, Cloudflare R2 CDN, Firebase FCM push notifications   │
└─────────────────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | Implementation |
|-----------|----------------|----------------|
| **Feature Modules** | Encapsulate UI, state, and business logic for a single feature (Feed, Recipe, Voice, etc.) | Swift Package Manager local packages with TCA `@Reducer` macro |
| **TCA Reducers** | Handle state mutations and side effects in response to actions | Pure functions with `Reducer` protocol, dependency injection via `@Dependency` |
| **Apollo GraphQL Client** | Fetch data from backend, manage normalized cache, handle auth headers | Apollo iOS 2.0+ with JWT interceptor for Clerk tokens |
| **SQLite Cache** | Persist GraphQL responses for offline-first data access | `ApolloSQLite` with normalized cache stored in app Documents directory |
| **SwiftData/Core Data** | Store user preferences, onboarding state, feature flags | SwiftData (iOS 17+) for simple key-value and user settings |
| **AVFoundation Audio** | Stream voice narration audio, provide playback controls, background audio | `AVPlayer` for streaming R2 URLs with `AVAudioSession` for background playback |
| **StoreKit 2** | Handle Free/Pro tier subscriptions, restore purchases, validate receipts | Native StoreKit 2 with async/await APIs, server-side validation via NestJS |
| **Firebase FCM** | Receive push notifications for recipe expiry alerts and engagement nudges | Firebase Messaging SDK with APNs integration |
| **Accessibility Layer** | VoiceOver labels, dynamic type, 56dp touch targets, WCAG AAA compliance | SwiftUI accessibility modifiers on all interactive components |

## Recommended Project Structure

```
Kindred/
├── KindredApp/                     # Main iOS app target
│   ├── KindredApp.swift            # App entry point, dependency setup
│   ├── AppReducer.swift            # Root reducer composing all features
│   ├── AppView.swift               # Root SwiftUI view with tab navigation
│   └── Info.plist                  # Capabilities: Background Audio, Push, APNs
│
├── Packages/                       # Local Swift Package Manager modules
│   ├── Features/                   # Feature modules (TCA reducers + SwiftUI)
│   │   ├── FeedFeature/            # Recipe feed with swipe cards, filters
│   │   │   ├── Sources/
│   │   │   │   ├── FeedReducer.swift       # State, Action, Reducer
│   │   │   │   ├── FeedView.swift          # SwiftUI view
│   │   │   │   └── RecipeCardView.swift    # Swipeable recipe card
│   │   │   └── Tests/
│   │   │       └── FeedReducerTests.swift  # TCA TestStore tests
│   │   │
│   │   ├── RecipeDetailFeature/    # Recipe detail with voice playback
│   │   │   ├── Sources/
│   │   │   │   ├── RecipeDetailReducer.swift
│   │   │   │   ├── RecipeDetailView.swift
│   │   │   │   └── NarrationPlayerView.swift
│   │   │   └── Tests/
│   │   │
│   │   ├── VoiceFeature/           # Voice cloning, upload, profile management
│   │   │   ├── Sources/
│   │   │   │   ├── VoiceReducer.swift
│   │   │   │   ├── VoiceProfileView.swift
│   │   │   │   └── VoiceRecorderView.swift
│   │   │   └── Tests/
│   │   │
│   │   ├── ProfileFeature/         # User profile, preferences, billing
│   │   │   ├── Sources/
│   │   │   │   ├── ProfileReducer.swift
│   │   │   │   ├── ProfileView.swift
│   │   │   │   └── SubscriptionView.swift
│   │   │   └── Tests/
│   │   │
│   │   └── OnboardingFeature/      # Under 90-second onboarding flow
│   │       ├── Sources/
│   │       │   ├── OnboardingReducer.swift
│   │       │   └── OnboardingView.swift
│   │       └── Tests/
│   │
│   ├── Services/                   # Platform services (audio, billing, push)
│   │   ├── AudioStreamingService/  # AVFoundation audio streaming
│   │   │   ├── Sources/
│   │   │   │   ├── AudioPlayerClient.swift     # TCA dependency
│   │   │   │   ├── AudioStreamManager.swift    # AVPlayer wrapper
│   │   │   │   └── AudioCacheManager.swift     # Cache R2 audio files
│   │   │   └── Tests/
│   │   │
│   │   ├── BillingService/         # StoreKit 2 subscription management
│   │   │   ├── Sources/
│   │   │   │   ├── BillingClient.swift         # TCA dependency
│   │   │   │   ├── StoreKitManager.swift       # StoreKit 2 API wrapper
│   │   │   │   └── ReceiptValidator.swift      # Server-side validation
│   │   │   └── Tests/
│   │   │
│   │   └── PushNotificationService/    # Firebase FCM integration
│   │       ├── Sources/
│   │       │   ├── PushNotificationClient.swift
│   │       │   └── FCMTokenManager.swift
│   │       └── Tests/
│   │
│   ├── DataLayer/                  # GraphQL client, cache, models
│   │   ├── GraphQLClient/          # Apollo iOS configuration
│   │   │   ├── Sources/
│   │   │   │   ├── ApolloClientProvider.swift  # Singleton with JWT auth
│   │   │   │   ├── AuthInterceptor.swift       # Clerk JWT header injection
│   │   │   │   ├── CacheConfiguration.swift    # SQLite cache setup
│   │   │   │   └── NetworkInterceptor.swift    # Offline handling
│   │   │   └── Tests/
│   │   │
│   │   ├── GraphQLOperations/      # Generated Apollo code
│   │   │   ├── Queries/
│   │   │   │   ├── GetRecipeFeed.graphql
│   │   │   │   ├── GetRecipeDetail.graphql
│   │   │   │   └── GetUserProfile.graphql
│   │   │   ├── Mutations/
│   │   │   │   ├── BookmarkRecipe.graphql
│   │   │   │   ├── SkipRecipe.graphql
│   │   │   │   └── UploadVoiceClip.graphql
│   │   │   └── Fragments/
│   │   │       ├── RecipeCard.graphql
│   │   │       └── VoiceProfile.graphql
│   │   │
│   │   └── LocalStorage/           # SwiftData models for user prefs
│   │       ├── Sources/
│   │       │   ├── UserPreferences.swift       # SwiftData @Model
│   │       │   ├── OnboardingState.swift
│   │       │   └── CachedAudioMetadata.swift
│   │       └── Tests/
│   │
│   ├── SharedUI/                   # Reusable SwiftUI components
│   │   ├── Sources/
│   │   │   ├── Components/
│   │   │   │   ├── KindredButton.swift         # 56dp accessible button
│   │   │   │   ├── KindredTextField.swift      # Accessible text input
│   │   │   │   └── LoadingView.swift
│   │   │   ├── Modifiers/
│   │   │   │   ├── AccessibilityModifiers.swift    # WCAG AAA helpers
│   │   │   │   └── CardStyle.swift
│   │   │   └── Theme/
│   │   │       ├── Colors.swift                # Warm cream/terracotta
│   │   │       ├── Typography.swift            # Dynamic type support
│   │   │       └── Spacing.swift
│   │   └── Tests/
│   │
│   └── Utilities/                  # Shared utilities
│       ├── Sources/
│       │   ├── Extensions/
│       │   │   ├── Date+Formatters.swift
│       │   │   └── URL+Validation.swift
│       │   └── Helpers/
│       │       ├── LocationManager.swift       # CoreLocation wrapper
│       │       └── NetworkMonitor.swift        # Reachability check
│       └── Tests/
│
├── schema.graphqls                 # Downloaded from NestJS backend
└── apollo-codegen-config.json      # Apollo iOS code generation config
```

### Structure Rationale

- **Feature isolation:** Each feature is a separate Swift Package with zero cross-feature dependencies. Features only depend on `DataLayer`, `Services`, and `SharedUI`.
- **Compile-time enforcement:** Swift Package Manager prevents accidental imports between features—if it compiles, architecture is intact.
- **Testability:** Each module has its own test target. TCA reducers are tested with `TestStore`, services are tested with mocked dependencies.
- **Build performance:** Incremental builds only recompile changed modules. On large projects, this can reduce iteration time from 30s to <5s.
- **Reusability:** `SharedUI` and `Utilities` are shared across all features. `DataLayer` is the single source of truth for GraphQL schemas.

## Architectural Patterns

### Pattern 1: TCA Feature Module with Dependency Injection

**What:** Each feature is a TCA reducer with explicitly declared dependencies (GraphQL client, audio player, billing service).

**When to use:** For all features requiring state management, side effects, or external service integration.

**Trade-offs:**
- **Pros:** Testable with mocked dependencies, compile-time type safety, exhaustive action handling
- **Cons:** More boilerplate than plain SwiftUI `@State`, steeper learning curve

**Example:**

```swift
// FeedFeature/Sources/FeedReducer.swift

import ComposableArchitecture
import GraphQLClient
import SharedModels

@Reducer
struct FeedReducer {
    @ObservableState
    struct State: Equatable {
        var recipes: [RecipeCard] = []
        var isLoading = false
        var currentLocation: Location?
        var filters: [DietaryFilter] = []
        var error: String?
    }

    enum Action: Equatable {
        case onAppear
        case recipesResponse(TaskResult<[RecipeCard]>)
        case swipeLeft(recipeId: String)  // Skip
        case swipeRight(recipeId: String) // Bookmark
        case updateLocation(Location)
        case applyFilters([DietaryFilter])
    }

    @Dependency(\.graphQLClient) var graphQLClient
    @Dependency(\.locationManager) var locationManager

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    await send(.recipesResponse(
                        TaskResult { try await graphQLClient.fetchRecipeFeed() }
                    ))
                }

            case let .recipesResponse(.success(recipes)):
                state.isLoading = false
                state.recipes = recipes
                return .none

            case let .recipesResponse(.failure(error)):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none

            case let .swipeRight(recipeId):
                return .run { _ in
                    try await graphQLClient.bookmarkRecipe(id: recipeId)
                }

            case let .swipeLeft(recipeId):
                return .run { _ in
                    try await graphQLClient.skipRecipe(id: recipeId)
                }

            case let .updateLocation(location):
                state.currentLocation = location
                state.isLoading = true
                return .run { send in
                    await send(.recipesResponse(
                        TaskResult { try await graphQLClient.fetchRecipeFeed(location: location) }
                    ))
                }

            case let .applyFilters(filters):
                state.filters = filters
                state.isLoading = true
                return .run { send in
                    await send(.recipesResponse(
                        TaskResult { try await graphQLClient.fetchRecipeFeed(filters: filters) }
                    ))
                }
            }
        }
    }
}

// Dependency registration
extension DependencyValues {
    var graphQLClient: GraphQLClient {
        get { self[GraphQLClientKey.self] }
        set { self[GraphQLClientKey.self] = newValue }
    }
}

private enum GraphQLClientKey: DependencyKey {
    static let liveValue = GraphQLClient.live
    static let testValue = GraphQLClient.mock
}
```

### Pattern 2: Apollo GraphQL Client with JWT Auth Interceptor

**What:** Singleton Apollo client with custom interceptor chain for Clerk JWT injection, offline handling, and cache normalization.

**When to use:** For all network requests to the NestJS GraphQL backend.

**Trade-offs:**
- **Pros:** Type-safe generated models, normalized cache reduces data duplication, offline-first with SQLite persistence
- **Cons:** Code generation step required, cache invalidation complexity

**Example:**

```swift
// DataLayer/GraphQLClient/Sources/ApolloClientProvider.swift

import Apollo
import ApolloAPI
import ApolloSQLite
import Foundation

final class ApolloClientProvider {
    static let shared = ApolloClientProvider()

    private(set) lazy var client: ApolloClient = {
        let cache = SQLiteNormalizedCache(fileURL: cacheFileURL)
        let store = ApolloStore(cache: cache)

        let authInterceptor = AuthInterceptor()
        let networkInterceptor = NetworkInterceptor(store: store)
        let interceptorProvider = InterceptorProvider(
            interceptors: [authInterceptor, networkInterceptor],
            store: store
        )

        let networkTransport = RequestChainNetworkTransport(
            interceptorProvider: interceptorProvider,
            endpointURL: URL(string: "https://api.kindred.app/graphql")!
        )

        return ApolloClient(networkTransport: networkTransport, store: store)
    }()

    private var cacheFileURL: URL {
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        return documentsPath.appendingPathComponent("kindred_graphql_cache.sqlite")
    }
}

// AuthInterceptor.swift - Inject Clerk JWT token

import Apollo
import ApolloAPI

final class AuthInterceptor: ApolloInterceptor {
    func interceptAsync<Operation: GraphQLOperation>(
        chain: RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void
    ) {
        // Get Clerk JWT token from secure storage (Keychain)
        if let token = KeychainManager.shared.getClerkJWT() {
            request.addHeader(name: "Authorization", value: "Bearer \(token)")
        }

        chain.proceedAsync(
            request: request,
            response: response,
            completion: completion
        )
    }
}

// NetworkInterceptor.swift - Handle offline mode

final class NetworkInterceptor: ApolloInterceptor {
    private let store: ApolloStore

    init(store: ApolloStore) {
        self.store = store
    }

    func interceptAsync<Operation: GraphQLOperation>(
        chain: RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void
    ) {
        // Check network reachability
        if NetworkMonitor.shared.isConnected {
            chain.proceedAsync(request: request, response: response, completion: completion)
        } else {
            // Attempt to read from cache
            store.load(query: request.operation as! any GraphQLQuery) { result in
                switch result {
                case .success(let data):
                    let graphQLResult = GraphQLResult(
                        data: data,
                        extensions: nil,
                        errors: nil,
                        source: .cache,
                        dependentKeys: nil
                    )
                    completion(.success(graphQLResult))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
}
```

### Pattern 3: Offline-First Cache Strategy with Apollo SQLite

**What:** Use Apollo's SQLite cache as the source of truth. Read from cache first, then fetch from network and update cache.

**When to use:** For recipe feed, user profile, bookmarks—any data that should be available offline.

**Trade-offs:**
- **Pros:** App works offline, faster perceived performance (cache-first), reduced network requests
- **Cons:** Stale data if cache TTL not managed, cache invalidation on mutations requires care

**Example:**

```swift
// GraphQLClient.swift

import Apollo

extension GraphQLClient {
    func fetchRecipeFeed(
        location: Location? = nil,
        filters: [DietaryFilter] = [],
        cachePolicy: CachePolicy = .returnCacheDataAndFetch
    ) async throws -> [RecipeCard] {
        let query = GetRecipeFeedQuery(
            latitude: location?.latitude,
            longitude: location?.longitude,
            dietaryFilters: filters.map { $0.rawValue }
        )

        return try await withCheckedThrowingContinuation { continuation in
            ApolloClientProvider.shared.client.fetch(
                query: query,
                cachePolicy: cachePolicy
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data {
                        let recipes = data.recipeFeed.map { RecipeCard(from: $0) }
                        continuation.resume(returning: recipes)
                    } else if let errors = graphQLResult.errors {
                        continuation.resume(throwing: GraphQLError.serverErrors(errors))
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
```

**Cache Policies:**
- `.returnCacheDataElseFetch` — Offline-first. Return cache immediately, fallback to network.
- `.returnCacheDataAndFetch` — Return cache, then fetch network and update cache in background.
- `.fetchIgnoringCacheData` — Always fetch from network (use for real-time data like live engagement metrics).

### Pattern 4: Voice Streaming with AVPlayer and Progressive Download

**What:** Stream voice narration audio from Cloudflare R2 URLs using AVPlayer, cache downloaded audio files for offline playback.

**When to use:** For recipe narration playback with play/pause/seek controls and background audio support.

**Trade-offs:**
- **Pros:** Progressive download allows playback before full download, AVPlayer handles buffering automatically, background audio with lock screen controls
- **Cons:** Streaming consumes bandwidth, cache management required to avoid excessive storage

**Example:**

```swift
// AudioStreamingService/Sources/AudioStreamManager.swift

import AVFoundation
import Combine

final class AudioStreamManager: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isBuffering = false

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?

    override init() {
        super.init()
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio)
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    func play(url: URL, speakerName: String) {
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)

        player = AVPlayer(playerItem: playerItem)

        // Observe playback status
        statusObserver = playerItem.observe(\.status) { [weak self] item, _ in
            switch item.status {
            case .readyToPlay:
                self?.isBuffering = false
                self?.duration = item.duration.seconds
                self?.player?.play()
                self?.isPlaying = true
            case .failed:
                print("Failed to load audio: \(item.error?.localizedDescription ?? "")")
                self?.isBuffering = false
            case .unknown:
                self?.isBuffering = true
            @unknown default:
                break
            }
        }

        // Observe playback time
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            self?.currentTime = time.seconds
        }

        // Configure Now Playing info for lock screen controls
        setupNowPlayingInfo(speakerName: speakerName)
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func resume() {
        player?.play()
        isPlaying = true
    }

    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
    }

    private func setupNowPlayingInfo(speakerName: String) {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = "Recipe Narration"
        nowPlayingInfo[MPMediaItemPropertyArtist] = speakerName
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        statusObserver?.invalidate()
    }
}
```

**Offline Caching Strategy:**

```swift
// AudioCacheManager.swift

import Foundation

final class AudioCacheManager {
    private let cacheDirectory: URL

    init() {
        let cachesPath = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first!
        self.cacheDirectory = cachesPath.appendingPathComponent("AudioCache", isDirectory: true)

        try? FileManager.default.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )
    }

    func cachedURL(for remoteURL: URL) -> URL? {
        let filename = remoteURL.lastPathComponent
        let localURL = cacheDirectory.appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: localURL.path) ? localURL : nil
    }

    func cacheAudio(from remoteURL: URL) async throws -> URL {
        let filename = remoteURL.lastPathComponent
        let localURL = cacheDirectory.appendingPathComponent(filename)

        // Download if not already cached
        if !FileManager.default.fileExists(atPath: localURL.path) {
            let (tempURL, _) = try await URLSession.shared.download(from: remoteURL)
            try FileManager.default.moveItem(at: tempURL, to: localURL)
        }

        return localURL
    }

    func clearCache() throws {
        try FileManager.default.removeItem(at: cacheDirectory)
        try FileManager.default.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )
    }
}
```

### Pattern 5: StoreKit 2 Subscription Management with Server Validation

**What:** Use StoreKit 2 native async/await APIs for App Store subscriptions, validate purchases server-side via NestJS backend.

**When to use:** For Free/Pro tier subscription management and entitlement checks.

**Trade-offs:**
- **Pros:** Modern async/await API, cryptographically signed transactions, automatic renewal handling
- **Cons:** Requires server-side receipt validation for security, testing requires StoreKit configuration file

**Example:**

```swift
// BillingService/Sources/StoreKitManager.swift

import StoreKit

enum SubscriptionTier: String, CaseIterable {
    case free = "com.kindred.free"
    case pro = "com.kindred.pro.monthly" // $9.99/month
}

final class StoreKitManager: ObservableObject {
    @Published var availableProducts: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var subscriptionStatus: SubscriptionTier = .free

    private var updateListenerTask: Task<Void, Error>?

    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    func loadProducts() async {
        do {
            let productIDs = SubscriptionTier.allCases.map { $0.rawValue }
            availableProducts = try await Product.products(for: productIDs)
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateSubscriptionStatus()
            await transaction.finish()
            return transaction

        case .userCancelled, .pending:
            return nil

        @unknown default:
            return nil
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        await updateSubscriptionStatus()
    }

    private func updateSubscriptionStatus() async {
        var hasPro = false

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.productID == SubscriptionTier.pro.rawValue {
                    hasPro = true
                    purchasedProductIDs.insert(transaction.productID)
                }
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }

        await MainActor.run {
            self.subscriptionStatus = hasPro ? .pro : .free
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction update failed: \(error)")
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
```

**Server-Side Validation:**

The iOS app should send the signed transaction to the NestJS backend for validation using Apple's App Store Server API. This prevents client-side receipt manipulation.

```typescript
// NestJS backend (existing): src/billing/billing.service.ts

import { verifyReceiptApple } from '@apple/app-store-server-library';

async validateTransaction(signedTransaction: string): Promise<boolean> {
  try {
    const decoded = await verifyReceiptApple(signedTransaction, {
      environment: process.env.APP_STORE_ENVIRONMENT,
      bundleId: 'com.kindred.app',
    });

    // Update user entitlements in database
    await this.prisma.user.update({
      where: { id: decoded.userId },
      data: { subscriptionTier: 'PRO' },
    });

    return true;
  } catch (error) {
    return false;
  }
}
```

### Pattern 6: WCAG AAA Accessibility Architecture

**What:** Apply accessibility modifiers to all interactive SwiftUI components for VoiceOver, Dynamic Type, and minimum touch target compliance.

**When to use:** For every view in the app—accessibility is non-negotiable.

**Trade-offs:**
- **Pros:** Inclusive design, App Store compliance, better UX for all users
- **Cons:** Requires discipline to apply consistently, increases SwiftUI view complexity slightly

**Example:**

```swift
// SharedUI/Sources/Components/KindredButton.swift

import SwiftUI

struct KindredButton: View {
    let title: String
    let icon: Image?
    let action: () -> Void
    let accessibilityLabel: String?
    let accessibilityHint: String?

    init(
        _ title: String,
        icon: Image? = nil,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.action = action
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon = icon {
                    icon
                        .font(.system(size: 20))
                }
                Text(title)
                    .font(.body)  // Respects Dynamic Type
                    .fontWeight(.semibold)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .frame(height: 56)  // WCAG AAA: 56dp minimum touch target
            .foregroundColor(.white)
            .background(Color.kindredAccent)  // #E07849
            .cornerRadius(12)
        }
        .accessibilityLabel(accessibilityLabel ?? title)
        .accessibilityHint(accessibilityHint ?? "")
        .accessibilityAddTraits(.isButton)
    }
}

// Example usage with VoiceOver context
KindredButton(
    "Listen to Recipe",
    icon: Image(systemName: "play.circle.fill"),
    accessibilityLabel: "Listen to recipe narration",
    accessibilityHint: "Double tap to hear recipe instructions in your loved one's voice"
) {
    store.send(.playNarration)
}
```

**Accessibility Modifiers:**

```swift
// SharedUI/Sources/Modifiers/AccessibilityModifiers.swift

import SwiftUI

extension View {
    /// Apply WCAG AAA minimum touch target (56x56dp)
    func accessibleTouchTarget() -> some View {
        self.frame(minWidth: 56, minHeight: 56)
    }

    /// Add semantic heading trait for navigation
    func accessibleHeading(level: Int = 1) -> some View {
        self
            .accessibilityAddTraits(.isHeader)
            .accessibilityValue("Heading level \(level)")
    }

    /// Mark image as decorative (VoiceOver ignores)
    func decorativeImage() -> some View {
        self.accessibilityHidden(true)
    }

    /// WCAG AAA contrast ratio helper (7:1 for normal text, 4.5:1 for large text)
    func accessibleContrast(background: Color, foreground: Color) -> some View {
        // TODO: Implement contrast ratio calculation
        self
    }
}
```

**VoiceOver Reading Order:**

```swift
// RecipeCardView.swift

var body: some View {
    VStack(alignment: .leading, spacing: 16) {
        // Hero image
        AsyncImage(url: recipe.heroImageURL)
            .decorativeImage()  // VoiceOver skips

        // Recipe name (read first)
        Text(recipe.name)
            .accessibleHeading(level: 2)

        HStack {
            Text("\(recipe.prepTime) min")
            Text("\(recipe.calories) cal")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Prep time \(recipe.prepTime) minutes, \(recipe.calories) calories")

        // Action buttons
        HStack {
            Button("Skip") { store.send(.skip) }
                .accessibilityHint("Swipe left to skip recipe")

            Button("Bookmark") { store.send(.bookmark) }
                .accessibilityHint("Swipe right to save recipe")
        }
    }
    .accessibilityElement(children: .contain)  // Group for logical reading
}
```

## Data Flow

### Request Flow: User Action → GraphQL Query → Cache → UI Update

```
User taps "Feed" tab
    ↓
FeedView.onAppear
    ↓
FeedReducer receives .onAppear action
    ↓
Reducer dispatches Effect: graphQLClient.fetchRecipeFeed()
    ↓
Apollo Client checks cache (returnCacheDataAndFetch policy)
    ↓
Cache hit? → Return cached data immediately → Update FeedReducer state
    ↓
Fetch from network in background (NestJS GraphQL endpoint)
    ↓
Network response → Apollo normalizes and writes to SQLite cache
    ↓
Update FeedReducer state with fresh data
    ↓
SwiftUI view re-renders with updated state
```

### Voice Playback Flow: Tap Play → Stream Audio → Cache for Offline

```
User taps "Listen" button on RecipeDetailView
    ↓
RecipeDetailReducer receives .playNarration action
    ↓
Reducer dispatches Effect: audioPlayerClient.play(url: narrationURL, speaker: voiceName)
    ↓
AudioPlayerClient checks AudioCacheManager.cachedURL(for: narrationURL)
    ↓
Cache hit? → Play from local file
Cache miss? → Stream from Cloudflare R2 URL, download in background
    ↓
AVPlayer starts playback, publishes currentTime updates
    ↓
RecipeDetailReducer observes currentTime, updates state
    ↓
SwiftUI NarrationPlayerView updates seek slider, play/pause button
    ↓
Background download completes → AudioCacheManager caches file
    ↓
Next playback uses cached file (offline support)
```

### Subscription Purchase Flow: Tap Upgrade → StoreKit → Server Validation

```
User taps "Upgrade to Pro" in ProfileView
    ↓
ProfileReducer receives .upgradeToPro action
    ↓
Reducer dispatches Effect: billingClient.purchase(product: proPlan)
    ↓
StoreKit 2 presents App Store purchase sheet
    ↓
User confirms purchase with Face ID/Touch ID
    ↓
StoreKit returns signed transaction
    ↓
BillingClient sends transaction to NestJS backend for validation
    ↓
Backend validates with Apple App Store Server API
    ↓
Backend updates user.subscriptionTier = 'PRO' in PostgreSQL
    ↓
Backend returns success → GraphQL cache invalidated
    ↓
ProfileReducer receives .purchaseSuccess action
    ↓
Update ProfileReducer state: subscriptionStatus = .pro
    ↓
SwiftUI ProfileView unlocks Pro features
```

### State Management: Unidirectional Data Flow (TCA Pattern)

```
User Action (tap, swipe, etc.)
    ↓
SwiftUI View sends Action to Store
    ↓
Store.send(.action) → Reducer receives Action
    ↓
Reducer:
  - Updates State (synchronous)
  - Returns Effects for side effects (async: GraphQL, audio, billing)
    ↓
Effects run (async/await, Combine publishers)
    ↓
Effect completes → New Action sent to Reducer (e.g., .recipesResponse(.success))
    ↓
Reducer updates State again
    ↓
SwiftUI View observes State change (@ObservedObject, @Binding)
    ↓
View re-renders with new State
```

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| **0-10k users** | Current architecture is sufficient. SQLite cache handles local storage, in-memory NestJS queues handle background jobs. Monitor GraphQL query performance and cache hit rates. |
| **10k-100k users** | **Backend:** Migrate from in-memory queues to Redis + BullMQ for reliable background processing (recipe scraping, image generation). Add PostgreSQL read replicas for query load. Enable Apollo GraphQL query batching. **iOS:** No changes needed—client-side architecture scales with backend. Monitor audio cache storage growth, implement LRU eviction policy. |
| **100k-1M users** | **Backend:** Horizontal scaling with multiple NestJS instances behind load balancer. Move AI workloads (Gemini, ElevenLabs, Imagen) to dedicated worker services. Implement CDN edge caching for recipe images and voice files. **iOS:** Implement GraphQL persisted queries to reduce payload size. Add telemetry for crash reporting (Sentry) and performance monitoring (Firebase Performance). |
| **1M+ users** | **Backend:** Consider GraphQL Federation to split monolith into domain services (Recipes, Voice, Users). Implement global CDN for R2 assets. Add Kafka for event streaming (recipe views, skips, bookmarks). **iOS:** No architectural changes—TCA + Apollo scales horizontally with backend. Focus on performance: lazy loading, view virtualization, image compression. |

### Scaling Priorities

1. **First bottleneck:** GraphQL query performance (N+1 queries). **Fix:** Enable Apollo DataLoader on backend, implement query batching, optimize PostgreSQL indexes on geospatial queries.
2. **Second bottleneck:** Audio file storage growth (cached narrations). **Fix:** Implement LRU cache eviction (e.g., delete files older than 30 days or when cache exceeds 500MB). Add telemetry to track cache hit rate and storage usage.
3. **Third bottleneck:** Real-time voice narration latency (ElevenLabs API). **Fix:** Pre-generate narrations for top 1000 trending recipes daily, cache on R2. Lazy-generate on-demand for long-tail recipes.

## Anti-Patterns

### Anti-Pattern 1: Tight Coupling Between Features

**What people do:** Import `FeedFeature` directly into `RecipeDetailFeature` to share state or logic.

**Why it's wrong:** Creates circular dependencies, breaks modular isolation, makes testing harder, prevents independent feature development.

**Do this instead:** Share state via the root `AppReducer` using TCA's `Scope` and `PullbackReducer`. Or, extract shared logic into a separate `SharedDomain` module that both features depend on.

```swift
// ❌ BAD: RecipeDetailFeature imports FeedFeature
import FeedFeature

// ✅ GOOD: Extract shared RecipeCard model to SharedModels
import SharedModels

// ✅ GOOD: Root AppReducer composes features
@Reducer
struct AppReducer {
    struct State {
        var feed = FeedReducer.State()
        var recipeDetail = RecipeDetailReducer.State()
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.feed, action: /Action.feed) {
            FeedReducer()
        }
        Scope(state: \.recipeDetail, action: /Action.recipeDetail) {
            RecipeDetailReducer()
        }
    }
}
```

### Anti-Pattern 2: Bypassing Apollo Cache with Direct HTTP Calls

**What people do:** Use `URLSession` to fetch GraphQL data instead of Apollo client, bypassing the normalized cache.

**Why it's wrong:** Loses offline-first benefits, duplicates data (same recipe fetched multiple times), no type safety from generated models.

**Do this instead:** Always use Apollo client for GraphQL queries. Configure cache policies per query (`.returnCacheDataAndFetch` for feeds, `.fetchIgnoringCacheData` for real-time data).

```swift
// ❌ BAD: Direct HTTP call bypasses cache
let data = try await URLSession.shared.data(from: graphqlEndpoint)

// ✅ GOOD: Use Apollo client with cache policy
let recipes = try await apolloClient.fetch(
    query: GetRecipeFeedQuery(),
    cachePolicy: .returnCacheDataAndFetch
)
```

### Anti-Pattern 3: Storing Sensitive Data in UserDefaults or Unencrypted Cache

**What people do:** Store Clerk JWT tokens or user credentials in `UserDefaults` or Apollo SQLite cache without encryption.

**Why it's wrong:** Security vulnerability—JWT tokens stored in plain text can be extracted from device backups or jailbroken devices.

**Do this instead:** Use iOS Keychain for sensitive data (JWT tokens, API keys). Mark Apollo cache file as excluded from backups. Consider encrypting the SQLite cache for sensitive user data.

```swift
// ❌ BAD: Store JWT in UserDefaults
UserDefaults.standard.set(jwtToken, forKey: "clerkJWT")

// ✅ GOOD: Store JWT in Keychain
KeychainManager.shared.saveClerkJWT(jwtToken)

// Keychain implementation
import Security

final class KeychainManager {
    func saveClerkJWT(_ token: String) {
        let data = token.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "clerkJWT",
            kSecValueData as String: data,
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    func getClerkJWT() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "clerkJWT",
            kSecReturnData as String: true,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
```

### Anti-Pattern 4: Blocking Main Thread with Heavy Operations

**What people do:** Run image processing, GraphQL queries, or audio file downloads on the main thread, freezing the UI.

**Why it's wrong:** Poor UX—app becomes unresponsive, violates Apple's "60fps" guideline, leads to App Store rejections.

**Do this instead:** Use Swift's async/await for all I/O operations. Run heavy CPU work (image compression, JSON parsing) on background queues.

```swift
// ❌ BAD: Block main thread with network call
let data = try Data(contentsOf: url)  // Blocks until download completes

// ✅ GOOD: Use async/await for network I/O
let data = try await URLSession.shared.data(from: url).0

// ✅ GOOD: Run heavy work on background queue
await withCheckedContinuation { continuation in
    DispatchQueue.global(qos: .userInitiated).async {
        let compressedImage = image.compress(quality: 0.7)
        continuation.resume(returning: compressedImage)
    }
}
```

### Anti-Pattern 5: Ignoring Accessibility Until the End

**What people do:** Build all features first, add accessibility modifiers as a "final polish" step before launch.

**Why it's wrong:** Accessibility often requires structural changes (view hierarchy, keyboard navigation), which are expensive to retrofit. Results in inconsistent, incomplete accessibility.

**Do this instead:** Apply accessibility modifiers from the first view. Use SwiftUI's built-in accessibility-first components (`.accessibilityLabel()`, `.accessibilityHint()`, `.accessibilityAddTraits()`). Test with VoiceOver enabled during development.

```swift
// ❌ BAD: Build UI without accessibility
Button("Play") { playAudio() }

// ✅ GOOD: Add accessibility from day one
Button("Play") { playAudio() }
    .accessibilityLabel("Play recipe narration")
    .accessibilityHint("Double tap to hear recipe instructions in your loved one's voice")
    .accessibilityAddTraits(.isButton)
    .frame(minWidth: 56, minHeight: 56)  // WCAG AAA touch target
```

### Anti-Pattern 6: Not Testing with Real Offline Scenarios

**What people do:** Test offline mode by toggling Airplane Mode briefly, assuming cached data works.

**Why it's wrong:** Misses edge cases: partial network failures, cache expiration, stale data conflicts, background refresh timing.

**Do this instead:** Use Xcode's Network Link Conditioner to simulate 3G, packet loss, and high latency. Write integration tests that mock network failures and verify cache fallback behavior.

```swift
// Integration test for offline feed loading
func testFeedLoadsFromCacheWhenOffline() async {
    let store = TestStore(initialState: FeedReducer.State()) {
        FeedReducer()
    } withDependencies: {
        $0.graphQLClient = .mock(
            networkAvailable: false,
            cachedRecipes: [mockRecipe1, mockRecipe2]
        )
    }

    await store.send(.onAppear) {
        $0.isLoading = true
    }

    await store.receive(.recipesResponse(.success([mockRecipe1, mockRecipe2]))) {
        $0.isLoading = false
        $0.recipes = [mockRecipe1, mockRecipe2]
    }
}
```

## Integration Points

### External Services (Backend Integration)

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| **NestJS GraphQL API** | Apollo iOS client with JWT auth interceptor | All queries/mutations go through Apollo. Use generated Swift types from `.graphql` files. Cache policy: `.returnCacheDataAndFetch` for feeds, `.fetchIgnoringCacheData` for real-time data. |
| **Clerk Authentication** | JWT token stored in Keychain, injected in Apollo auth interceptor | Token refresh handled by Clerk SDK. On expiry, refresh token and retry failed GraphQL requests. Guest mode: anonymous JWT issued by backend. |
| **Cloudflare R2 (Audio/Images)** | AVPlayer for audio streaming, AsyncImage for images | R2 URLs are signed by backend (short-lived tokens). Cache audio files locally for offline playback. Images cached by URLCache automatically. |
| **ElevenLabs Voice Cloning** | Backend handles all voice cloning—iOS only uploads 30-60s audio clip via GraphQL mutation | Use `multipart/form-data` upload via custom Apollo upload link. Backend returns voice profile ID. |
| **Firebase Cloud Messaging** | Firebase Messaging SDK for push notifications | APNs certificate uploaded to Firebase console. App registers device token on launch, sends to backend via GraphQL mutation. Backend sends notifications via FCM Admin SDK. |
| **App Store (StoreKit 2)** | Native StoreKit 2 for subscriptions, server-side validation via NestJS | iOS app sends signed transaction to backend. Backend validates with Apple App Store Server API, updates user entitlements in PostgreSQL. |

### Internal Boundaries (Module Communication)

| Boundary | Communication | Notes |
|----------|---------------|-------|
| **FeedFeature ↔ GraphQLClient** | TCA dependency injection (`@Dependency(\.graphQLClient)`) | FeedReducer dispatches `.fetchRecipeFeed()` effect, receives `.recipesResponse()` action with data. GraphQL client is mocked in tests. |
| **RecipeDetailFeature ↔ AudioStreamingService** | TCA dependency injection (`@Dependency(\.audioPlayerClient)`) | RecipeDetailReducer sends `.playNarration()` action, AudioPlayerClient streams from R2 URL. Publishes playback state (currentTime, isPlaying) via Combine. |
| **ProfileFeature ↔ BillingService** | TCA dependency injection (`@Dependency(\.billingClient)`) | ProfileReducer initiates purchase, BillingClient handles StoreKit flow. On success, sends transaction to backend for validation. Returns entitlement update. |
| **Features ↔ SharedUI** | Direct import (unidirectional dependency) | Features import `SharedUI` for reusable components (`KindredButton`, `LoadingView`). SharedUI never imports Features. |
| **Features ↔ DataLayer** | Direct import for GraphQL models | Features import generated Apollo models (`RecipeCard`, `VoiceProfile`). DataLayer is shared across all features. |
| **Root AppReducer ↔ Feature Reducers** | TCA `Scope` composition | AppReducer composes all feature reducers using `Scope(state:action:)`. Parent-child communication via shared state or delegate actions. |

## Testing Strategy

### Unit Testing (50% of tests)

**What to test:** TCA reducers, business logic, data transformations, utilities.

**How:** Use TCA's `TestStore` to assert state transitions and effects.

```swift
// FeedFeatureTests/FeedReducerTests.swift

import ComposableArchitecture
import XCTest
@testable import FeedFeature

final class FeedReducerTests: XCTestCase {
    func testFeedLoadsRecipesOnAppear() async {
        let mockRecipes = [RecipeCard.mock1, RecipeCard.mock2]

        let store = TestStore(initialState: FeedReducer.State()) {
            FeedReducer()
        } withDependencies: {
            $0.graphQLClient.fetchRecipeFeed = { mockRecipes }
        }

        // User opens feed
        await store.send(.onAppear) {
            $0.isLoading = true
        }

        // Receives recipes from backend
        await store.receive(.recipesResponse(.success(mockRecipes))) {
            $0.isLoading = false
            $0.recipes = mockRecipes
        }
    }

    func testSwipeRightBookmarksRecipe() async {
        let store = TestStore(
            initialState: FeedReducer.State(recipes: [RecipeCard.mock1])
        ) {
            FeedReducer()
        } withDependencies: {
            $0.graphQLClient.bookmarkRecipe = { _ in }
        }

        await store.send(.swipeRight(recipeId: "recipe-1"))

        // Verify GraphQL mutation was called
        XCTAssertTrue(store.dependencies.graphQLClient.bookmarkRecipeWasCalled)
    }
}
```

### Integration Testing (20% of tests)

**What to test:** Feature composition, data flow between modules, Apollo cache behavior, offline scenarios.

**How:** Test multiple reducers composed together, use real Apollo client with mock GraphQL server.

```swift
// Integration test: Feed → RecipeDetail navigation
func testNavigationFromFeedToRecipeDetail() async {
    let store = TestStore(initialState: AppReducer.State()) {
        AppReducer()
    } withDependencies: {
        $0.graphQLClient = .mock
    }

    // Load feed
    await store.send(.feed(.onAppear))
    await store.receive(.feed(.recipesResponse(.success([mockRecipe]))))

    // Tap recipe card
    await store.send(.feed(.selectRecipe(id: "recipe-1"))) {
        $0.recipeDetail = RecipeDetailReducer.State(recipeId: "recipe-1")
    }

    // Recipe detail loads
    await store.receive(.recipeDetail(.recipeFetched(.success(mockRecipe))))
}
```

### Snapshot Testing (10% of tests)

**What to test:** SwiftUI view rendering, accessibility layout, dark mode, dynamic type.

**How:** Use `swift-snapshot-testing` library to capture view snapshots.

```swift
import SnapshotTesting
import XCTest
@testable import SharedUI

final class KindredButtonSnapshotTests: XCTestCase {
    func testKindredButtonDefaultState() {
        let button = KindredButton("Continue") {}
        assertSnapshot(matching: button, as: .image)
    }

    func testKindredButtonDarkMode() {
        let button = KindredButton("Continue") {}
        assertSnapshot(matching: button, as: .image(traits: .init(userInterfaceStyle: .dark)))
    }

    func testKindredButtonAccessibilityXXXL() {
        let button = KindredButton("Continue") {}
        assertSnapshot(
            matching: button,
            as: .image(traits: .init(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge))
        )
    }
}
```

### UI Testing (10% of tests)

**What to test:** Critical user flows (onboarding, voice playback, subscription purchase), accessibility with VoiceOver.

**How:** Use XCTest UI testing with real app launch.

```swift
// E2E test: Onboarding flow
func testOnboardingFlowCompletesUnder90Seconds() {
    let app = XCUIApplication()
    app.launch()

    // Welcome screen
    app.buttons["Get Started"].tap()

    // Location permission
    app.buttons["Allow Location"].tap()

    // Dietary preferences
    app.buttons["Vegan"].tap()
    app.buttons["Next"].tap()

    // Voice setup (skip for now)
    app.buttons["Skip for now"].tap()

    // Verify feed loads
    XCTAssertTrue(app.otherElements["RecipeFeed"].waitForExistence(timeout: 5))
}
```

### Accessibility Testing (10% of tests)

**What to test:** VoiceOver labels, reading order, touch target sizes, color contrast.

**How:** Manual testing with VoiceOver enabled + automated checks with Accessibility Inspector.

```swift
func testRecipeCardAccessibility() {
    let recipeCard = RecipeCardView(recipe: .mock)

    // Test VoiceOver label
    XCTAssertEqual(recipeCard.accessibilityLabel, "Spicy Thai Basil Chicken")

    // Test touch target size (56x56 minimum)
    let playButton = recipeCard.descendant(matching: .button, identifier: "PlayButton")
    XCTAssertGreaterThanOrEqual(playButton.frame.width, 56)
    XCTAssertGreaterThanOrEqual(playButton.frame.height, 56)
}
```

## Build Order Considering Dependencies

### Phase 1: Foundation (Weeks 1-2)
**Why first:** Establishes core infrastructure that all features depend on.

1. **Set up Swift Package Manager modules** (`Packages/` directory structure)
2. **Configure Apollo iOS** (download schema, set up code generation, create `ApolloClientProvider`)
3. **Implement auth layer** (Clerk JWT storage in Keychain, `AuthInterceptor` for Apollo)
4. **Create SharedUI components** (`KindredButton`, `KindredTextField`, theme/colors)
5. **Set up root AppReducer** (compose features, handle navigation)

**Deliverable:** App launches with empty feed, GraphQL client authenticated, theme applied.

### Phase 2: Feed & Recipe Discovery (Weeks 3-4)
**Why second:** Core value proposition—users must see recipes to engage.

1. **FeedFeature module** (TCA reducer, swipe cards, filters)
2. **RecipeDetailFeature module** (recipe view, ingredient list, instructions)
3. **Offline-first caching** (Apollo SQLite cache, `.returnCacheDataAndFetch` policy)
4. **Location integration** (CoreLocation, display city badge)

**Deliverable:** Users can browse recipe feed, filter by dietary preferences, view recipe details offline.

### Phase 3: Voice Playback (Weeks 5-6)
**Why third:** Differentiator feature—requires audio infrastructure.

1. **AudioStreamingService module** (AVPlayer wrapper, background playback, lock screen controls)
2. **Audio caching** (download R2 audio files, LRU eviction)
3. **VoiceFeature module** (voice profile management, upload flow)
4. **Narration playback in RecipeDetailView** (play/pause/seek controls)

**Deliverable:** Users can listen to recipe narrations in cloned voices, audio plays in background.

### Phase 4: Onboarding & Personalization (Week 7)
**Why fourth:** Requires feed and voice features to be functional for meaningful onboarding.

1. **OnboardingFeature module** (welcome, location permission, dietary prefs, voice setup)
2. **Guest mode support** (anonymous JWT, bookmark/skip without account)
3. **Culinary DNA personalization** (send skips/bookmarks to backend, filter feed)

**Deliverable:** New users complete onboarding in <90s, see personalized feed.

### Phase 5: Monetization (Week 8)
**Why fifth:** Billing requires backend validation infrastructure.

1. **BillingService module** (StoreKit 2 setup, subscription management)
2. **ProfileFeature module** (user settings, subscription status, upgrade flow)
3. **Server-side receipt validation** (NestJS endpoint to validate transactions)
4. **Entitlement checks** (limit voice slots for Free tier)

**Deliverable:** Users can upgrade to Pro, subscription persists across app restarts.

### Phase 6: Accessibility & Polish (Weeks 9-10)
**Why last:** Requires all features to be complete for comprehensive accessibility audit.

1. **Accessibility audit** (VoiceOver labels, touch targets, color contrast)
2. **Dynamic Type support** (test XXXL text sizes)
3. **Push notifications** (Firebase FCM integration, recipe expiry alerts)
4. **Error handling & loading states** (graceful offline mode, retry logic)
5. **Performance optimization** (lazy loading, image compression, cache tuning)

**Deliverable:** App meets WCAG AAA standards, fully functional offline, production-ready.

### Dependency Graph

```
Phase 1: Foundation
    ↓ (Apollo client, auth, theme)
Phase 2: Feed & Recipe Discovery
    ↓ (GraphQL models, cache)
Phase 3: Voice Playback
    ↓ (Audio infrastructure)
Phase 4: Onboarding & Personalization
    ↓ (Complete feature set)
Phase 5: Monetization
    ↓ (All features ready for entitlement checks)
Phase 6: Accessibility & Polish
```

## Sources

### High Confidence (Official Documentation, Current)

**TCA (The Composable Architecture):**
- [GitHub - pointfreeco/swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture)
- [Getting Started With The Composable Architecture | Kodeco](https://www.kodeco.com/24550178-getting-started-with-the-composable-architecture)
- [Dependency management in The Composable Architecture](https://medium.com/evangelist-apps/dependency-management-in-the-composable-architecture-using-reducerprotocol-c7346d07716a)

**Apollo iOS GraphQL:**
- [Introduction to Apollo iOS - Apollo GraphQL Docs](https://www.apollographql.com/docs/ios)
- [Cache setup - Apollo GraphQL Docs](https://www.apollographql.com/docs/ios/caching/cache-setup)
- [Test mocks - Apollo GraphQL Docs](https://www.apollographql.com/docs/ios/testing/test-mocks)
- [Announcing Apollo iOS 2.0 - Apollo GraphQL Blog](https://www.apollographql.com/blog/announcing-apollo-ios-2-0)

**iOS Modular Architecture:**
- [Modularizing iOS Applications with SwiftUI and Swift Package Manager - Nimble](https://nimblehq.co/blog/modern-approach-modularize-ios-swiftui-spm)
- [Microapps architecture in Swift. Feature modules. | Swift with Majid](https://swiftwithmajid.com/2022/01/19/microapps-architecture-in-swift-feature-modules/)

**Offline-First Architecture:**
- [Designing Offline-First iOS Architecture with Swift Concurrency & Core Data Sync | Medium](https://medium.com/@er.rajatlakhina/designing-offline-first-architecture-with-swift-concurrency-and-core-data-sync-46ad5008c7b5)
- [Architecting Offline-First iOS Apps with Idle-Aware Background Sync - DEV Community](https://dev.to/vijaya_saimunduru_c9579b/architecting-offline-first-ios-apps-with-idle-aware-background-sync-1dhh)

**Audio Streaming:**
- [Streaming Audio With AVAudioEngine - Haris Ali](https://www.syedharisali.com/articles/streaming-audio-with-avaudioengine/)
- [Background audio handling with iOS AVPlayer | Mux](https://www.mux.com/blog/background-audio-handling-with-ios-avplayer)

**StoreKit 2:**
- [iOS In-App Subscription Tutorial with StoreKit 2 and Swift - RevenueCat](https://www.revenuecat.com/blog/engineering/ios-in-app-subscription-tutorial-with-storekit-2-and-swift/)
- [Mastering StoreKit 2 in SwiftUI: A Complete Guide (2025) | Medium](https://medium.com/@dhruvinbhalodiya752/mastering-storekit-2-in-swiftui-a-complete-guide-to-in-app-purchases-2025-ef9241fced46)

**Accessibility (WCAG AAA):**
- [GitHub - cvs-health/ios-swiftui-accessibility-techniques](https://github.com/cvs-health/ios-swiftui-accessibility-techniques)
- [iOS Accessibility Properties: How They Relate to WCAG - 24 Accessibility](https://www.24a11y.com/2018/ios-accessibility-properties/)

**Firebase Cloud Messaging:**
- [Get started with Firebase Cloud Messaging in Apple platform apps](https://firebase.google.com/docs/cloud-messaging/ios/get-started)
- [FCM Architectural Overview | Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging/fcm-architecture)

**Local Storage (SwiftData/Core Data):**
- [Designing Efficient Local-First Architectures with SwiftData | Medium](https://medium.com/@gauravharkhani01/designing-efficient-local-first-architectures-with-swiftdata-cc74048526f2)
- [Core Data vs SwiftData: Which Should You Use in 2025?](https://distantjob.com/blog/core-data-vs-swiftdata/)

**Testing:**
- [How to test with The Composable Architecture | Brightec](https://www.brightec.co.uk/blog/how-to-test-with-the-composable-architecture)
- [Testing in TCA: Best Practices for iOS Developers | Medium](https://evilhonda303.medium.com/testing-in-tca-best-practices-part-1-exhaustive-testing-critique-679f1c8e97e6)

### Medium Confidence (Community Best Practices, 2025-2026)

- [Modern iOS App Architecture in 2026: MVVM vs Clean Architecture vs TCA | 7Span](https://7span.com/blog/mvvm-vs-clean-architecture-vs-tca)
- [Graphql/apollo-ios with TCA - Swift Forums](https://forums.swift.org/t/graphql-apollo-ios-with-tca/62339)
- [Building a Scalable GraphQL Client in Swift with Apollo | Medium](https://medium.com/@salladedeepya/building-a-scalable-graphql-client-in-swift-with-apollo-from-one-api-to-many-17dc20eec692)

---

*Architecture research for: iOS App Integration with NestJS GraphQL Backend*
*Researched: 2026-03-01*
*Confidence: HIGH (based on official Apple, Apollo, and TCA documentation + current community best practices)*
