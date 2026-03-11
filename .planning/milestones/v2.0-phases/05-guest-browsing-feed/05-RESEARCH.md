# Phase 5: Guest Browsing & Feed - Research

**Researched:** 2026-03-01
**Domain:** SwiftUI card interactions, location services, local storage, offline-first caching
**Confidence:** HIGH

## Summary

Phase 5 implements Tinder-style swipeable recipe cards with location-based discovery, guest session persistence, and offline-first caching. The core technical domains are: (1) SwiftUI DragGesture-based card stack with custom swipe thresholds and animations, (2) CoreLocation with contextual permission prompts, (3) SwiftData/CoreData for anonymous guest storage with UUID tracking, (4) Apollo iOS SQLite cache with `returnCacheDataAndFetch` policy for offline-first UX, (5) Kingfisher image cache with memory/disk limits, (6) VoiceOver custom actions for accessible swipe alternatives.

The project already has foundation pieces in place: TCA architecture, Apollo GraphQL client with SQLite cache (configured in Phase 4), Kingfisher setup, HapticFeedback utility, and reusable design system components (CardSurface, KindredButton, SkeletonShimmer). This phase builds the core feed experience on top of that foundation.

**Primary recommendation:** Use SwiftUI DragGesture with LazyVStack for card stack (not List), implement shake detection via UIWindow.motionEnded override, leverage Apollo's existing SQLite cache with `returnCacheDataAndFetch` policy, use SwiftData for guest bookmarks/skips with anonymous UUID, and implement VoiceOver custom actions via `.accessibilityAction()` modifier for accessible swipe alternatives.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Card Interaction Model:**
- Tinder-style stacked swipe cards — one card at a time, full-width
- Swipe left to skip, swipe right to bookmark
- Listen/Watch/Skip buttons positioned below the card (not overlaid)
- Subtle slide + haptic feedback on swipe (use existing HapticFeedback utility)
- Shake to undo last swipe — keep last 3 swiped cards in memory for multi-level undo
- 3-finger swipe left (iOS standard undo gesture) as accessible alternative to shake
- Next card slightly visible behind current card (peek effect)
- End card CTA when stack is empty: "You've seen all nearby recipes! Change location to explore more"
- Pull-to-refresh available on the card stack
- Subtle card count indicator (e.g., "3 of 10") shown above the card stack
- Balanced card layout: top half is hero image, bottom half shows recipe name, description snippet, metadata

**Card Metadata & Badges:**
- VIRAL badge as prominent overlay — angled ribbon/badge pinned to corner of hero image, only when `isViral` is true
- Prep time: clock icon + total minutes (e.g., "25 min"). If both prepTime and cookTime exist, show total
- Calories shown on card
- Loves count: heart icon + abbreviated count (e.g., "2.3k loves")
- Dietary tags NOT shown on cards — detail screen only (keeps cards clean)

**Recipe Detail View:**
- Full-screen push navigation from card tap
- Hero image zoom transition (matched geometry effect) from card to detail
- Parallax scrollable content: large hero image at top, then recipe name, dietary tag pills, metadata bar, ingredients, steps
- Dietary tags as colored pills below recipe name (green for vegan, blue for keto, etc.)
- Metadata bar: prep time, calories, loves count with heart icon
- Calories only in metadata (no protein/carbs/fat breakdown)
- Checkable ingredient list — tap to mark items user has, persistent within session (not saved for guests)
- Numbered step-by-step instructions with circles and connector line (vertical timeline style), duration shown per step when available
- Sticky bottom bar with two actions: "Listen to this recipe" button (disabled/grayed — Phase 7 enables) + Bookmark button
- Engagement: loves count shown as subtle metadata on detail screen

**Location Experience:**
- Tappable pill in navigation bar showing city name with pin icon prefix
- Search-based bottom sheet when pill tapped: "Use my location" button with location pin icon at the very top, above search field
- If location permission not granted, tapping "Use my location" triggers system permission prompt
- Deferred location permission — start with default curated city, only request GPS when user taps badge and selects "Use my location"
- Default to curated city (e.g., Istanbul) when location denied
- Persist last selected city in UserDefaults across app launches
- Animated card refresh when switching cities — current cards animate out (fade/slide), new cards animate in

**Guest Session Storage:**
- Local CoreData/SwiftData for bookmarks, skipped recipes, and guest preferences
- Generate anonymous UUID on first launch — store locally, tag all interactions with it, carries over to Phase 8 account conversion
- Skipped recipes hidden until feed refresh (pull-to-refresh or location change brings them back)
- Bookmark count badge on Me tab
- Soft limit on bookmarks: after 10, show gentle nudge "Create an account to keep your recipes safe" (no hard block)

**Offline & Feed Loading:**
- Persistent top banner when offline: "You're offline — showing cached recipes"
- Queue bookmarks and sync later — user doesn't see the difference (seamless for guests since no server sync anyway)
- Cache current batch of recipes + hero images for offline use (10-20 recipes worth)
- Skeleton shimmer cards on initial feed load (use existing skeleton implementation from FeedView)
- Silent refresh on reconnect — quietly fetch new recipes, show subtle "New recipes available" indicator, user pulls to refresh to see them
- EmptyStateView (.noRecipes) for empty feed with "Change Location" button

**Accessibility:**
- Each card is single VoiceOver element: reads "Recipe name, prep time, calories"
- Custom VoiceOver actions menu on cards: "Bookmark" / "Skip" / "View details"
- Listen/Watch/Skip buttons include accessibility hints: "Skip button — or swipe left", "Bookmark button — or swipe right"
- Post VoiceOver notifications on location changes: "Now showing recipes near Istanbul"
- Post VoiceOver notifications on card transitions: "Recipe 3 of 15, [name]"
- All interactive elements maintain 56dp minimum touch targets (ACCS-01)
- Navigation depth maximum 3 levels (ACCS-04): Feed → Detail → (none beyond)

**Feed Performance:**
- 10 recipes per API batch
- Pre-load next batch when 3 cards remain in current stack
- Progressive blur-up image loading via Kingfisher — blurred low-res immediately, then sharpens
- Only top 3 cards in stack have images fully loaded — load more as user swipes
- Pre-fetch RecipeDetailQuery for current top card silently (instant detail load on tap)
- Keep last 3 swiped cards in memory for undo, release oldest beyond that

### Claude's Discretion

- Exact swipe animation curves and timing
- Card shadow and elevation styling details
- Skeleton shimmer timing and animation details
- Error state handling for API failures
- Exact search field behavior in location picker (debounce, minimum characters)
- CoreData/SwiftData schema design for guest storage
- Exact parallax scroll speed on detail screen
- Kingfisher cache configuration details
- Exact position and style of card count indicator

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope

</user_constraints>

<phase_requirements>
## Phase Requirements

This phase MUST address the following requirements from REQUIREMENTS.md:

| ID | Description | Research Support |
|----|-------------|-----------------|
| AUTH-01 | User can browse the recipe feed as a guest without creating an account | SwiftData anonymous UUID pattern, no auth gates on feed queries |
| FEED-01 | User sees viral recipes trending within 5-10 miles of their location | CoreLocation + ViralRecipesQuery with location parameter |
| FEED-02 | Each recipe card displays AI hero image, recipe name, prep time, calories, loves count, and VIRAL badge | Kingfisher progressive image loading, existing ViralRecipesQuery schema |
| FEED-03 | User can swipe left to skip and swipe right to bookmark recipe cards | DragGesture with onEnded threshold detection + TCA state management |
| FEED-04 | User can tap Listen/Watch/Skip buttons as swipe alternatives | KindredButton 56dp touch targets + VoiceOver custom actions |
| FEED-05 | User's location is shown as a city badge at the top of the feed | NavigationStack toolbar with tappable location pill |
| FEED-06 | User can manually change their location to explore other areas | Bottom sheet location picker + @AppStorage persistence |
| FEED-08 | Feed loads cached content when offline with clear offline indicator | Apollo SQLite cache + NWPathMonitor offline detection |
| ACCS-01 | All interactive elements have minimum 56dp touch targets (WCAG AAA) | KindredButton already implements 56dp minimum |
| ACCS-04 | Navigation depth is maximum 3 levels from any screen | Feed → Detail (2 levels total, within limit) |

</phase_requirements>

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17.0+ | Declarative UI framework | Native Apple framework, TCA integration, matchedGeometryEffect for hero transitions |
| TCA (swift-composable-architecture) | 1.x | State management architecture | Already integrated in Phase 4, testable side effects, dependency injection |
| Apollo iOS | 2.0.6 | GraphQL client with caching | Already configured in Phase 4 with SQLite cache, offline-first support |
| Kingfisher | 8.x | Image downloading and caching | Industry standard for iOS image caching, progressive loading, memory/disk management |
| SwiftData | iOS 17.0+ | Local persistence framework | Modern Core Data replacement, less boilerplate, type-safe, SwiftUI-first API |
| CoreLocation | iOS 17.0+ | Location services | Native framework for GPS and location permissions |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Network Framework (NWPathMonitor) | iOS 12.0+ | Network reachability monitoring | Offline detection, replaced deprecated Reachability |
| UserDefaults via @AppStorage | iOS 14.0+ | Simple key-value persistence | Store last selected city, welcome card dismissal |
| UIKit (for shake gesture) | iOS 17.0+ | Shake gesture detection via motionEnded | SwiftUI doesn't have native shake support, requires UIWindow override |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| SwiftData | Core Data directly | Core Data requires more boilerplate but has wider community support; SwiftData is simpler for this use case |
| Kingfisher | SDWebImage, Nuke | SDWebImage (UIKit-first), Nuke (pure Swift but less mature ecosystem); Kingfisher is standard for SwiftUI |
| NWPathMonitor | Third-party Reachability | Third-party Reachability libs are deprecated; NWPathMonitor is official Apple API (iOS 12+) |
| DragGesture custom | Third-party card libs | Custom DragGesture gives full control, avoids dependency on unmaintained libs |

**Installation:**

All dependencies already installed in Phase 4 except SwiftData (built-in framework, no SPM needed).

```bash
# Already installed in Phase 4:
# - Apollo iOS 2.0.6
# - ApolloSQLite
# - Kingfisher
# - TCA 1.x
# No additional installations required for Phase 5
```

## Architecture Patterns

### Recommended Project Structure

```
FeedFeature/
├── Sources/
│   ├── Feed/
│   │   ├── FeedReducer.swift          # TCA reducer with card state, swipe actions, location
│   │   ├── FeedView.swift              # Card stack UI with DragGesture
│   │   ├── RecipeCardView.swift        # Individual card component
│   │   ├── SwipeCardStack.swift        # Reusable card stack container
│   │   └── LocationPicker.swift        # Bottom sheet for location selection
│   ├── RecipeDetail/
│   │   ├── RecipeDetailReducer.swift   # Detail screen TCA reducer
│   │   ├── RecipeDetailView.swift      # Full recipe detail UI
│   │   ├── IngredientChecklistView.swift
│   │   └── StepTimelineView.swift      # Vertical timeline for steps
│   ├── GuestSession/
│   │   ├── GuestSessionManager.swift   # UUID generation, bookmark/skip storage
│   │   ├── GuestBookmark.swift         # SwiftData model
│   │   └── GuestSkip.swift             # SwiftData model
│   └── Location/
│       ├── LocationManager.swift       # CoreLocation wrapper
│       └── LocationClient.swift        # TCA dependency for location
```

### Pattern 1: Swipeable Card Stack with DragGesture

**What:** Use DragGesture with offset() and rotationEffect() to create Tinder-style card swipe with threshold detection.

**When to use:** For any swipeable card interface where discrete swipe actions trigger state changes.

**Example:**

```swift
// Based on: https://medium.com/@gary.tokman/tinder-swipe-animation-in-swiftui-tutorial-2021-b99183471e42
// and https://yyokii.medium.com/swiftui-swipeable-card-stack-c15f09224b74

struct RecipeCardView: View {
    let recipe: Recipe
    let onSwipe: (SwipeDirection) -> Void

    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0

    var body: some View {
        CardSurface {
            // Card content
        }
        .offset(x: offset.width, y: offset.height * 0.4)
        .rotationEffect(.degrees(rotation))
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                    // Multiply by 5 for sensitivity (small gestures = swipe)
                    rotation = Double(gesture.translation.width / 10)
                }
                .onEnded { gesture in
                    let threshold: CGFloat = 200
                    if abs(gesture.translation.width) > threshold {
                        // Swipe detected
                        let direction: SwipeDirection = gesture.translation.width > 0 ? .right : .left
                        withAnimation(.spring()) {
                            offset.width = gesture.translation.width > 0 ? 500 : -500
                        }
                        onSwipe(direction)
                    } else {
                        // Snap back
                        withAnimation(.spring()) {
                            offset = .zero
                            rotation = 0
                        }
                    }
                }
        )
    }
}

enum SwipeDirection {
    case left  // Skip
    case right // Bookmark
}
```

**Key insights from research:**
- Apply rotation before offset so card slides directly while rotating ([source](https://www.hackingwithswift.com/books/ios-swiftui/animating-gestures))
- Use threshold (e.g., 200pts) to determine swipe vs. snap-back ([source](https://medium.com/@gary.tokman/tinder-swipe-animation-in-swiftui-tutorial-2021-b99183471e42))
- Multiply drag amount by sensitivity factor (5-10x) for responsive feel ([source](https://designcode.io/swiftui-handbook-drag-gesture/))

### Pattern 2: Hero Image Transition with Matched Geometry Effect

**What:** Use `.matchedGeometryEffect()` (iOS 14-15) or `.matchedTransitionSource()` + `.navigationTransition()` (iOS 16+) for hero animations between feed card and detail screen.

**When to use:** When transitioning between list/grid and detail views with shared image element.

**Example (Modern iOS 16+ approach):**

```swift
// Based on: https://peterfriese.dev/blog/2024/hero-animation/
// and https://swiftui-lab.com/matchedgeometryeffect-part1/

struct FeedView: View {
    @Namespace private var heroNamespace

    var body: some View {
        NavigationStack {
            ForEach(recipes) { recipe in
                NavigationLink(value: recipe) {
                    RecipeCardView(recipe: recipe)
                        .matchedTransitionSource(id: recipe.id, in: heroNamespace)
                }
            }
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
                    .navigationTransition(.zoom(sourceID: recipe.id, in: heroNamespace))
            }
        }
    }
}
```

**Key insights:**
- iOS 16+ uses `.matchedTransitionSource()` + `.navigationTransition()` (3 lines of code) ([source](https://peterfriese.dev/blog/2024/hero-animation/))
- iOS 14-15 fallback uses `.matchedGeometryEffect()` with @Namespace ([source](https://swiftui-lab.com/matchedgeometryeffect-part1/))
- Ensure both views use same namespace and ID for matching

### Pattern 3: Location Permission with Contextual Prompt

**What:** Defer location permission request until user taps "Use my location" button, avoiding upfront permission fatigue.

**When to use:** Any feature where location is optional enhancement, not core requirement.

**Example:**

```swift
// Based on: https://www.andyibanez.com/posts/using-corelocation-with-swiftui/
// and https://sarunw.com/posts/location-button/

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var currentLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        authorizationStatus = manager.authorizationStatus
    }

    func requestLocationPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        manager.requestLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.first
    }
}

// In LocationPickerView:
Button("Use my location") {
    locationManager.requestLocationPermission() // Only request when user taps
}
```

**Key insights:**
- Set `Privacy - Location When In Use Usage Description` in Info.plist ([source](https://dwirandyh.medium.com/deep-dive-into-core-location-in-ios-a-step-by-step-guide-to-requesting-and-utilizing-user-location-fe8325462ea9))
- iOS 15+ LocationButton provides one-tap authorization without manual request ([source](https://sarunw.com/posts/location-button/))
- Use `requestWhenInUseAuthorization()`, not `requestAlwaysAuthorization()` for feed use case

### Pattern 4: Shake Gesture Detection in SwiftUI

**What:** Override `motionEnded()` in UIWindow to detect shake, post notification that SwiftUI views can observe.

**When to use:** Undo/redo actions triggered by device shake (accessibility note: also provide 3-finger swipe alternative).

**Example:**

```swift
// Based on: https://www.hackingwithswift.com/quick-start/swiftui/how-to-detect-shake-gestures
// and https://gist.github.com/ralfebert/17d4517130bec34c4b80705307e309fb

extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name(rawValue: "deviceDidShakeNotification")
}

extension UIWindow {
    override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
    }
}

// SwiftUI view modifier:
struct ShakeGesture: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
                action()
            }
    }
}

extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(ShakeGesture(action: action))
    }
}

// Usage:
FeedView()
    .onShake {
        store.send(.undoLastSwipe)
    }
```

**Key insights:**
- SwiftUI has no built-in shake detection ([source](https://www.hackingwithswift.com/quick-start/swiftui/how-to-detect-shake-gestures))
- Requires UIWindow override + NotificationCenter bridge ([source](https://medium.com/@abdelrahman_adm/shake-gesture-in-swiftui-1ce0342fbb4e))
- Also implement 3-finger swipe for accessibility (iOS standard undo gesture)

### Pattern 5: VoiceOver Custom Actions for Card Gestures

**What:** Use `.accessibilityAction()` modifier to expose swipe alternatives as VoiceOver custom actions menu.

**When to use:** Any gestural interaction that needs accessible fallback (swipes, drags, long press).

**Example:**

```swift
// Based on: https://www.createwithswift.com/accessibility-actions/
// and https://swiftwithmajid.com/2021/04/15/accessibility-actions-in-swiftui/

RecipeCardView(recipe: recipe)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(recipe.name), \(recipe.prepTime) minutes, \(recipe.calories ?? 0) calories")
    .accessibilityAction(named: "Bookmark") {
        store.send(.bookmarkRecipe(recipe.id))
    }
    .accessibilityAction(named: "Skip") {
        store.send(.skipRecipe(recipe.id))
    }
    .accessibilityAction(named: "View details") {
        store.send(.openRecipeDetail(recipe.id))
    }
```

**Key insights:**
- Combine card into single accessibility element with `.accessibilityElement(children: .combine)` ([source](https://medium.com/@federicoramos77/making-custom-ui-elements-in-swiftui-accessible-for-voiceover-3e161365b5df))
- Use `.accessibilityAction(named:)` for custom actions in VoiceOver rotor ([source](https://www.kodeco.com/books/swiftui-cookbook/v1.0/chapters/7-add-custom-accessibility-actions-to-swiftui-views))
- Post `.announcement` accessibility notifications on state changes ([source](https://swiftwithmajid.com/2021/04/15/accessibility-actions-in-swiftui/))

### Pattern 6: TCA Dependency for Side Effects (Location, Network)

**What:** Define dependencies via `@DependencyClient` macro for testable, mockable side effects in reducers.

**When to use:** Any external system interaction (location, network, analytics) in TCA reducers.

**Example:**

```swift
// Based on: https://github.com/pointfreeco/swift-composable-architecture
// and https://medium.com/@gauravios/dependency-injection-in-the-composable-architecture-an-architects-perspective-9be5571a0f89

import ComposableArchitecture

@DependencyClient
struct LocationClient {
    var requestAuthorization: @Sendable () async -> CLAuthorizationStatus
    var currentLocation: @Sendable () async throws -> CLLocation
}

extension LocationClient: DependencyKey {
    static let liveValue = LocationClient(
        requestAuthorization: {
            await LocationManager.shared.requestAuthorization()
        },
        currentLocation: {
            try await LocationManager.shared.currentLocation()
        }
    )

    static let testValue = LocationClient(
        requestAuthorization: { .authorizedWhenInUse },
        currentLocation: { CLLocation(latitude: 41.0082, longitude: 28.9784) } // Istanbul
    )
}

extension DependencyValues {
    var locationClient: LocationClient {
        get { self[LocationClient.self] }
        set { self[LocationClient.self] = newValue }
    }
}

// In reducer:
@Reducer
struct FeedReducer {
    @Dependency(\.locationClient) var locationClient

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .requestLocation:
            return .run { send in
                let location = try await locationClient.currentLocation()
                await send(.locationReceived(location))
            }
        }
    }
}
```

**Key insights:**
- `@DependencyClient` macro auto-generates test and preview values ([source](https://github.com/pointfreeco/swift-composable-architecture))
- Wrap async APIs in `.run { send in }` effect builder ([source](https://www.kodeco.com/24550178-getting-started-with-the-composable-architecture))
- Use `withDependencies` in tests to override dependencies ([source](https://www.brightec.co.uk/blog/how-to-test-with-the-composable-architecture))

### Pattern 7: Apollo Cache with Offline-First Policy

**What:** Use Apollo's `returnCacheDataAndFetch` cache policy to show cached data immediately, then update with fresh network response.

**When to use:** Offline-first UX where stale data is better than loading spinner.

**Example:**

```swift
// Based on: https://www.apollographql.com/docs/ios/caching/cache-setup
// and https://github.com/apollographql/apollo-ios-dev/blob/main/docs/source/caching/cache-setup.mdx

// Already configured in Phase 4 (04-03):
// - ApolloClient with SQLiteNormalizedCache
// - CachePolicy: .returnCacheDataAndFetch

// Usage in FeedReducer:
apollo.fetch(
    query: ViralRecipesQuery(location: state.location),
    cachePolicy: .returnCacheDataAndFetch
) { result in
    switch result {
    case .success(let graphQLResult):
        // First response: cached data (fast)
        // Second response: fresh network data (when available)
        send(.recipesLoaded(graphQLResult.data?.viralRecipes ?? []))
    case .failure(let error):
        send(.loadingFailed(error))
    }
}
```

**Key insights:**
- `returnCacheDataAndFetch` returns cache immediately, then network update ([source](https://github.com/apollographql/apollo-ios/issues/128))
- SQLite cache persists across app launches ([source](https://www.apollographql.com/docs/ios/caching/cache-setup))
- Use `cachePolicy: .fetchIgnoringCacheData` for pull-to-refresh

### Pattern 8: Pagination with LazyVStack and onAppear

**What:** Load next page when user scrolls near end of current batch using `.onAppear` on trigger item.

**When to use:** Infinite scroll or batch loading for large datasets.

**Example:**

```swift
// Based on: https://www.kodeco.com/books/swiftui-cookbook/v1.0/chapters/10-create-an-infinitely-scrolling-list-in-swiftui
// and https://medium.engineering/how-to-do-pagination-in-swiftui-04511be7fbd1

struct FeedView: View {
    @State private var recipes: [Recipe] = []
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(recipes) { recipe in
                    RecipeCardView(recipe: recipe)
                        .onAppear {
                            // Pre-load when 3 items from end
                            if recipe == recipes[max(0, recipes.count - 3)] {
                                loadMoreRecipes()
                            }
                        }
                }

                if isLoading {
                    ProgressView()
                        .onAppear {
                            loadMoreRecipes()
                        }
                }
            }
        }
        .refreshable {
            await refreshRecipes()
        }
    }

    func loadMoreRecipes() {
        guard !isLoading else { return }
        isLoading = true
        // Load next batch via TCA action
    }
}
```

**Key insights:**
- Use LazyVStack, not List, for custom card layouts ([source](https://copyprogramming.com/howto/infinite-scroll-on-ios-with-swift))
- Trigger load when 3-5 items from end for smooth UX ([source](https://medium.engineering/how-to-do-pagination-in-swiftui-04511be7fbd1))
- `.onAppear` on ProgressView ensures load even if scrolled fast ([source](https://www.kodeco.com/books/swiftui-cookbook/v1.0/chapters/10-create-an-infinitely-scrolling-list-in-swiftui))

### Pattern 9: SwiftData for Guest Session Storage

**What:** Use SwiftData `@Model` classes with anonymous UUID to track guest bookmarks and skips locally.

**When to use:** Local-only data that needs to persist across app launches but doesn't sync to server (yet).

**Example:**

```swift
// Based on: https://medium.com/devtechie/swiftdata-in-swiftui-part-1-29272b00f718
// and https://medium.com/@priya_talreja/swiftdata-in-swiftui-part-1-18919ce2612

import SwiftData

@Model
class GuestBookmark {
    @Attribute(.unique) var id: UUID
    var recipeId: String
    var guestUserId: UUID
    var createdAt: Date

    init(recipeId: String, guestUserId: UUID) {
        self.id = UUID()
        self.recipeId = recipeId
        self.guestUserId = guestUserId
        self.createdAt = Date()
    }
}

@Model
class GuestSkip {
    @Attribute(.unique) var id: UUID
    var recipeId: String
    var guestUserId: UUID
    var createdAt: Date

    init(recipeId: String, guestUserId: UUID) {
        self.id = UUID()
        self.recipeId = recipeId
        self.guestUserId = guestUserId
        self.createdAt = Date()
    }
}

// In KindredApp.swift:
@main
struct KindredApp: App {
    var body: some Scene {
        WindowGroup {
            AppView()
        }
        .modelContainer(for: [GuestBookmark.self, GuestSkip.self])
    }
}

// In FeedReducer:
@Query private var bookmarks: [GuestBookmark]

func bookmarkRecipe(recipeId: String, guestUserId: UUID, context: ModelContext) {
    let bookmark = GuestBookmark(recipeId: recipeId, guestUserId: guestUserId)
    context.insert(bookmark)
}
```

**Key insights:**
- SwiftData requires iOS 17.0+, replaces Core Data with simpler API ([source](https://medium.com/devtechie/swiftdata-in-swiftui-part-1-29272b00f718))
- Use `@Attribute(.unique)` for UUID primary keys ([source](https://www.hackingwithswift.com/forums/swiftui/uuid-in-core-data/729))
- `@Query` property wrapper auto-updates SwiftUI views on data changes ([source](https://medium.com/@jpmtech/intro-to-swiftdata-using-swiftui-d9dc5312f5e7))

### Pattern 10: AppStorage for Simple Preferences

**What:** Use `@AppStorage` property wrapper for UserDefaults-backed state that auto-updates SwiftUI views.

**When to use:** Simple user preferences (last selected location, theme, flags) that don't need complex schema.

**Example:**

```swift
// Based on: https://www.createwithswift.com/storing-information-using-user-defaults-appstorage/
// and https://www.hackingwithswift.com/quick-start/swiftui/what-is-the-appstorage-property-wrapper

struct FeedView: View {
    @AppStorage("lastSelectedCity") private var lastSelectedCity: String = "Istanbul"
    @AppStorage("hasSeenWelcomeCard") private var hasSeenWelcomeCard: Bool = false
    @AppStorage("guestUserId") private var guestUserId: String = UUID().uuidString

    var body: some View {
        // View automatically updates when @AppStorage values change
        Text("Showing recipes near \(lastSelectedCity)")
    }
}
```

**Key insights:**
- `@AppStorage` mirrors UserDefaults with SwiftUI auto-update ([source](https://www.hackingwithswift.com/quick-start/swiftui/what-is-the-appstorage-property-wrapper))
- Provide default value for first launch ([source](https://www.createwithswift.com/storing-information-using-user-defaults-appstorage/))
- Not secure storage — don't store tokens or sensitive data ([source](https://medium.com/@ramdhas/mastering-swiftui-best-practices-for-efficient-user-preference-management-with-appstorage-cf088f4ca90c))

### Pattern 11: Network Reachability with NWPathMonitor

**What:** Use Network framework's `NWPathMonitor` to observe network status changes and show offline banner.

**When to use:** Any app with offline-first caching that needs to inform users of network state.

**Example:**

```swift
// Based on: https://medium.com/@husnainali593/how-to-check-network-connection-in-swiftui-using-nwpathmonitor-8f6cd4777514
// and https://medium.com/@rwbutler/nwpathmonitor-the-new-reachability-de101a5a8835

import Network

@Observable
class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    var isConnected: Bool = true

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}

// In App:
@State private var networkMonitor = NetworkMonitor()

var body: some View {
    FeedView()
        .overlay(alignment: .top) {
            if !networkMonitor.isConnected {
                Text("You're offline — showing cached recipes")
                    .padding()
                    .background(.yellow)
            }
        }
}
```

**Key insights:**
- NWPathMonitor replaced deprecated Reachability (iOS 12+) ([source](https://medium.com/@rwbutler/nwpathmonitor-the-new-reachability-de101a5a8835))
- Observe `path.status == .satisfied` for connectivity ([source](https://www.appypievibe.ai/blog/nwpathmonitor-internet-connectivity))
- Run on background queue, update UI on main thread ([source](https://medium.com/@dkw5877/reachability-in-ios-172fc3709a37))

### Pattern 12: Kingfisher Cache Configuration

**What:** Configure Kingfisher memory and disk cache limits to prevent memory pressure on older devices.

**When to use:** Any app with heavy image loading that needs to manage cache size.

**Example:**

```swift
// Based on: https://app.studyraid.com/en/read/11573/364151/memory-cache-configuration
// and https://github.com/onevcat/Kingfisher/wiki/Cheat-Sheet

import Kingfisher

// Already configured in Phase 4 (04-03):
let cache = ImageCache.default
cache.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024  // 100MB
cache.memoryStorage.config.countLimit = 100
cache.diskStorage.config.sizeLimit = 500 * 1024 * 1024  // 500MB
cache.diskStorage.config.expiration = .days(7)

// Progressive blur-up loading:
KFImage(URL(string: recipe.imageUrl))
    .placeholder {
        Rectangle()
            .foregroundColor(.gray.opacity(0.3))
            .blur(radius: 10)
    }
    .fade(duration: 0.25)
    .resizable()
    .aspectRatio(contentMode: .fill)
```

**Key insights:**
- Set `totalCostLimit` for memory and `sizeLimit` for disk ([source](https://app.studyraid.com/en/read/11573/364151/memory-cache-configuration))
- Use `.placeholder {}` with blur for progressive loading effect ([source](https://github.com/onevcat/Kingfisher))
- Expiration policy prevents stale images ([source](https://cocoacasts.com/image-caching-in-swift-image-caching-with-kingfisher))

### Anti-Patterns to Avoid

- **Using List instead of LazyVStack for card stack:** List enforces row-based layout and doesn't work well with custom card stacks; use ScrollView + LazyVStack for full layout control
- **Requesting location permission on app launch:** Causes permission fatigue and rejections; defer until user taps "Use my location"
- **Performing expensive operations in TCA reducers:** Reducers run on main thread; move API calls, image processing to `.run { }` effects ([source](https://merowing.info/posts/the-composable-architecture-best-practices/))
- **Over-scoping ViewStore:** Don't scope entire state to ViewStore; scope only what the view needs to prevent unnecessary re-renders ([source](https://merowing.info/posts/the-composable-architecture-best-practices/))
- **Storing auth tokens in AppStorage/UserDefaults:** Not secure storage; use Keychain for sensitive data ([source](https://medium.com/@ramdhas/mastering-swiftui-best-practices-for-efficient-user-preference-management-with-appstorage-cf088f4ca90c))

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Image downloading/caching | Custom URLSession cache, in-memory dictionary | Kingfisher 8.x | Handles memory pressure, disk limits, progressive loading, cache eviction, background downloads |
| Network reachability | Custom socket monitoring, ping checks | NWPathMonitor (Network framework) | Official Apple API, handles edge cases (captive portals, VPN), battery efficient |
| GraphQL client | Raw URLSession + JSON parsing | Apollo iOS 2.0.6 (already integrated) | Type-safe queries, normalized cache, offline support, subscriptions |
| State management | Custom ObservableObject publishers | TCA 1.x (already integrated) | Testable effects, dependency injection, composable reducers |
| Local persistence for complex data | FileManager JSON serialization | SwiftData (iOS 17+) | Type-safe, SwiftUI integration, automatic relationships, undo/redo |
| Shake gesture detection | Custom accelerometer monitoring | UIWindow.motionEnded override | System-level gesture, respects accessibility settings, battery efficient |

**Key insight:** This phase leverages infrastructure from Phase 4 (Apollo, Kingfisher, TCA). Don't rebuild what's already configured. Focus on composition over custom solutions.

## Common Pitfalls

### Pitfall 1: Card Stack Performance Degradation

**What goes wrong:** Rendering all recipe cards at once causes memory spikes and jank as user swipes through feed.

**Why it happens:** SwiftUI eagerly renders all views in a regular VStack/ForEach, loading all images into memory even if off-screen.

**How to avoid:**
- Use LazyVStack instead of VStack ([source](https://copyprogramming.com/howto/infinite-scroll-on-ios-with-swift))
- Only load images for top 3 cards in stack (user decision)
- Use Kingfisher's `.onSuccess` to track loaded images and cancel pending loads for off-screen cards
- Release old swiped cards beyond last 3 (undo buffer)

**Warning signs:**
- Memory usage grows linearly with swipes
- Scrolling/swiping feels janky (dropped frames)
- Images flash/reload when swiping back

### Pitfall 2: Swipe Gesture Conflicts with ScrollView

**What goes wrong:** DragGesture on cards interferes with ScrollView scrolling, making vertical scroll feel broken.

**Why it happens:** SwiftUI gesture priority isn't explicitly set, causing gesture ambiguity.

**How to avoid:**
- Use `.gesture()` modifier on card (not `.simultaneousGesture()`)
- Set swipe threshold high enough (200pts) to distinguish from accidental drags
- Only apply horizontal offset, dampen vertical offset (multiply by 0.4) so vertical scroll still works

**Warning signs:**
- Can't scroll vertically in feed
- Cards move when trying to scroll
- Gestures feel "stuck"

### Pitfall 3: Location Permission Rejection Crashes App

**What goes wrong:** App crashes or shows empty feed when location permission is denied or restricted.

**Why it happens:** Code assumes location is always available, doesn't handle denial/restricted states.

**How to avoid:**
- Always check `CLLocationManager.authorizationStatus` before requesting location
- Default to curated city (Istanbul) when permission denied (user decision)
- Handle `.restricted`, `.denied`, `.notDetermined` states explicitly
- Persist last selected city in @AppStorage as fallback

**Warning signs:**
- App crash on first launch
- Feed shows no recipes after denying location
- Location picker doesn't work

### Pitfall 4: Apollo Cache Stale Data After Location Change

**What goes wrong:** Changing location shows cached recipes from old location, not new location.

**Why it happens:** Apollo cache keys queries by operation + variables; changing location = new query, but cache might return stale data if cache-first policy used.

**How to avoid:**
- Use `cachePolicy: .fetchIgnoringCacheData` on location change (force fresh fetch)
- Use `cachePolicy: .returnCacheDataAndFetch` for normal loads (shows cache, then updates)
- Clear specific cache entries on location change: `apollo.store.removeObject(forKey: ...)`

**Warning signs:**
- Recipes don't change when location changes
- Old location recipes mix with new location
- Pull-to-refresh doesn't fetch new data

### Pitfall 5: SwiftData Context Threading Issues

**What goes wrong:** SwiftData throws "context was not configured" or "NSInternalInconsistencyException" when inserting bookmarks.

**Why it happens:** SwiftData `ModelContext` is not thread-safe; accessing from background thread or wrong view hierarchy causes crashes.

**How to avoid:**
- Always access `@Environment(\.modelContext)` on main thread
- Don't pass `ModelContext` to async closures or background tasks
- Use `@MainActor` on bookmark/skip functions
- Inject `ModelContext` via TCA dependency, not direct access in effects

**Warning signs:**
- Crashes on bookmark/skip actions
- "Context not found" runtime errors
- Data doesn't persist after app restart

### Pitfall 6: VoiceOver Custom Actions Not Discoverable

**What goes wrong:** VoiceOver users can't find custom actions (bookmark/skip) on recipe cards.

**Why it happens:** Custom actions not properly exposed via accessibility modifiers, or accessibility label is too verbose.

**How to avoid:**
- Use `.accessibilityElement(children: .combine)` to merge card into single element
- Provide concise `.accessibilityLabel()` (recipe name, prep time, calories)
- Add `.accessibilityAction(named:)` for each action (bookmark, skip, view details)
- Post `.announcement` accessibility notifications on swipe ([source](https://swiftwithmajid.com/2021/04/15/accessibility-actions-in-swiftui/))

**Warning signs:**
- VoiceOver reads every card subview separately (image, title, metadata as separate elements)
- Custom actions don't appear in VoiceOver rotor
- No feedback when swiping cards with VoiceOver

### Pitfall 7: Shake Gesture Doesn't Work in Simulator

**What goes wrong:** Shake-to-undo doesn't trigger in iOS Simulator during testing.

**Why it happens:** Simulator's "Device > Shake Gesture" menu is flaky; custom UIWindow override might not be loaded.

**How to avoid:**
- Test shake gesture on physical device, not Simulator
- Implement 3-finger swipe left as alternative (iOS standard undo gesture) for testing and accessibility
- Add keyboard shortcut (Cmd+Z) for Simulator testing during development
- Verify UIWindow override is actually loaded (add print statement in `motionEnded`)

**Warning signs:**
- Shake menu item in Simulator does nothing
- No print/log statement when shaking Simulator
- Undo only works on physical device

### Pitfall 8: Hero Animation Breaks on iOS 14-15

**What goes wrong:** Hero image transition doesn't work, images just appear/disappear without animation.

**Why it happens:** Using iOS 16+ `.matchedTransitionSource()` API on older iOS versions.

**How to avoid:**
- Check iOS version: use `.matchedTransitionSource()` for iOS 16+, fallback to `.matchedGeometryEffect()` for iOS 14-15
- Ensure both source and destination use same `@Namespace` ID
- Verify namespace is declared in parent view, not inside NavigationLink

**Warning signs:**
- Hero animation works in iOS 16+ but not iOS 15
- Images appear with default fade, not zoom transition
- Console logs "matchedGeometryEffect: no matching geometry found"

## Code Examples

Verified patterns from official sources:

### Pull-to-Refresh with Refreshable Modifier

```swift
// Source: https://sarunw.com/posts/pull-to-refresh-in-swiftui/

struct FeedView: View {
    @State private var recipes: [Recipe] = []

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(recipes) { recipe in
                    RecipeCardView(recipe: recipe)
                }
            }
        }
        .refreshable {
            await refreshRecipes()
        }
    }

    func refreshRecipes() async {
        // TCA action to refresh feed with cachePolicy: .fetchIgnoringCacheData
        await store.send(.refreshFeed).finish()
    }
}
```

### TCA Reducer with Network Dependency

```swift
// Source: https://github.com/pointfreeco/swift-composable-architecture

@Reducer
struct FeedReducer {
    @ObservableState
    struct State: Equatable {
        var recipes: [Recipe] = []
        var isLoading = false
        var location: String = "Istanbul"
        var cardStack: [Recipe] = []
        var swipeHistory: [SwipedRecipe] = [] // Last 3 for undo
    }

    enum Action {
        case loadRecipes
        case recipesLoaded([Recipe])
        case swipeCard(RecipeID, SwipeDirection)
        case undoLastSwipe
        case changeLocation(String)
    }

    @Dependency(\.apolloClient) var apollo
    @Dependency(\.guestSession) var guestSession

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .loadRecipes:
                state.isLoading = true
                return .run { [location = state.location] send in
                    let result = try await apollo.fetch(
                        query: ViralRecipesQuery(location: location),
                        cachePolicy: .returnCacheDataAndFetch
                    )
                    await send(.recipesLoaded(result.data?.viralRecipes ?? []))
                }

            case .swipeCard(let recipeId, let direction):
                guard let recipe = state.cardStack.first(where: { $0.id == recipeId }) else {
                    return .none
                }

                // Update swipe history (keep last 3)
                state.swipeHistory.append(SwipedRecipe(recipe: recipe, direction: direction))
                if state.swipeHistory.count > 3 {
                    state.swipeHistory.removeFirst()
                }

                // Remove from stack
                state.cardStack.removeAll { $0.id == recipeId }

                // Persist action
                return .run { _ in
                    if direction == .right {
                        await guestSession.bookmarkRecipe(recipeId)
                    } else {
                        await guestSession.skipRecipe(recipeId)
                    }
                }

            case .undoLastSwipe:
                guard let lastSwipe = state.swipeHistory.popLast() else {
                    return .none
                }

                // Restore to top of stack
                state.cardStack.insert(lastSwipe.recipe, at: 0)

                return .run { _ in
                    await guestSession.undoSwipe(lastSwipe.recipe.id)
                }
            }
        }
    }
}
```

### Accessibility with Custom Actions

```swift
// Source: https://www.createwithswift.com/accessibility-actions/

struct RecipeCardView: View {
    let recipe: Recipe
    let onSwipe: (SwipeDirection) -> Void
    let onTap: () -> Void

    var body: some View {
        CardSurface {
            // Card content
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAction(named: "Bookmark") {
            HapticFeedback.medium()
            onSwipe(.right)
        }
        .accessibilityAction(named: "Skip") {
            onSwipe(.left)
        }
        .accessibilityAction(named: "View details") {
            onTap()
        }
    }

    private var accessibilityDescription: String {
        var parts: [String] = [recipe.name]
        parts.append("\(recipe.prepTime) minutes")
        if let calories = recipe.calories {
            parts.append("\(calories) calories")
        }
        if recipe.isViral {
            parts.append("Viral recipe")
        }
        return parts.joined(separator: ", ")
    }
}
```

### SwiftData Guest Bookmark Model

```swift
// Source: https://medium.com/devtechie/swiftdata-in-swiftui-part-1-29272b00f718

import SwiftData

@Model
final class GuestBookmark {
    @Attribute(.unique) var id: UUID
    var recipeId: String
    var guestUserId: UUID
    var recipeName: String
    var recipeImageUrl: String?
    var createdAt: Date

    init(
        recipeId: String,
        guestUserId: UUID,
        recipeName: String,
        recipeImageUrl: String?
    ) {
        self.id = UUID()
        self.recipeId = recipeId
        self.guestUserId = guestUserId
        self.recipeName = recipeName
        self.recipeImageUrl = recipeImageUrl
        self.createdAt = Date()
    }
}

// Usage in GuestSessionManager:
@MainActor
class GuestSessionManager {
    private let modelContext: ModelContext
    private let guestUserId: UUID

    init(modelContext: ModelContext) {
        self.modelContext = modelContext

        // Get or create guest user ID
        if let storedId = UserDefaults.standard.string(forKey: "guestUserId"),
           let uuid = UUID(uuidString: storedId) {
            self.guestUserId = uuid
        } else {
            let newId = UUID()
            UserDefaults.standard.set(newId.uuidString, forKey: "guestUserId")
            self.guestUserId = newId
        }
    }

    func bookmarkRecipe(_ recipe: Recipe) {
        let bookmark = GuestBookmark(
            recipeId: recipe.id,
            guestUserId: guestUserId,
            recipeName: recipe.name,
            recipeImageUrl: recipe.imageUrl
        )
        modelContext.insert(bookmark)
        try? modelContext.save()
    }

    func isBookmarked(_ recipeId: String) -> Bool {
        let predicate = #Predicate<GuestBookmark> { bookmark in
            bookmark.recipeId == recipeId && bookmark.guestUserId == self.guestUserId
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        return count > 0
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Reachability framework | NWPathMonitor (Network framework) | iOS 12 (2018) | Official Apple API, better edge case handling, battery efficient |
| Core Data + @FetchRequest | SwiftData + @Query | iOS 17 (2023) | Less boilerplate, type-safe, SwiftUI-first API |
| matchedGeometryEffect only | matchedTransitionSource + navigationTransition | iOS 16 (2022) | NavigationStack hero animations with 3 lines of code |
| Manual URLSession image loading | Kingfisher/SDWebImage | 2015+ | Automatic caching, memory management, progressive loading |
| Custom gesture state management | DragGesture with onChanged/onEnded | SwiftUI 1.0 (2019) | Declarative gesture handling, automatic animation |
| Third-party Reachability libs | NWPathMonitor | iOS 12 (2018) | No dependencies, official support |

**Deprecated/outdated:**
- **Reachability.swift library:** Replaced by NWPathMonitor (Network framework) — third-party lib no longer needed
- **UIViewRepresentable for shake gesture:** Still required (SwiftUI has no native shake support), but use UIWindow override pattern for cleaner implementation
- **Manual UserDefaults observation:** Use @AppStorage for automatic SwiftUI updates
- **Core Data manual fetch requests:** Use SwiftData @Query for automatic view updates

## Open Questions

1. **Exact swipe animation timing for card dismiss**
   - What we know: Use `.spring()` animation, multiply drag by 5-10x for sensitivity
   - What's unclear: Exact spring damping ratio (0.6-0.8?) and duration for "Tinder-like feel"
   - Recommendation: Start with `Animation.spring(response: 0.3, dampingFraction: 0.6)` and tune based on feel during implementation

2. **Card count indicator positioning**
   - What we know: Should show "3 of 10" above card stack
   - What's unclear: Exact position (centered? top-left?) and when to hide (always visible? fade on swipe?)
   - Recommendation: Center it 16pts above card stack, fade out during swipe gesture, fade in on release

3. **Location search debounce timing**
   - What we know: Should debounce city search to avoid excessive queries
   - What's unclear: Ideal debounce delay (300ms? 500ms?) and minimum characters
   - Recommendation: 300ms debounce (standard for search), minimum 2 characters to trigger

4. **Kingfisher blur-up transition duration**
   - What we know: Use placeholder blur, fade to sharp image
   - What's unclear: Optimal fade duration for "progressive" feel without janky appearance
   - Recommendation: 0.25s fade (Kingfisher default), matches iOS Photos app

5. **Parallax scroll speed on detail screen**
   - What we know: Hero image should parallax scroll at top of detail screen
   - What's unclear: Parallax multiplier (0.5x? 0.3x scroll speed of content?)
   - Recommendation: 0.5x parallax speed (half scroll speed) for subtle effect, common in iOS apps

## Sources

### Primary (HIGH confidence)

- [Apollo iOS Cache Setup Docs](https://www.apollographql.com/docs/ios/caching/cache-setup) - SQLite cache configuration, cache policies
- [Apple Developer: NWPathMonitor](https://developer.apple.com/documentation/network/nwpathmonitor) - Official network reachability API
- [Apple Developer: CoreLocation](https://developer.apple.com/documentation/corelocation) - Location services documentation
- [Apple Developer: SwiftData](https://developer.apple.com/documentation/swiftdata) - Modern persistence framework
- [Apple Developer: Accessibility Actions](https://developer.apple.com/documentation/swiftui/view-accessibility) - VoiceOver custom actions
- [Kingfisher GitHub](https://github.com/onevcat/Kingfisher) - Official Kingfisher documentation and examples
- [TCA GitHub](https://github.com/pointfreeco/swift-composable-architecture) - Official TCA documentation and patterns

### Secondary (MEDIUM confidence)

- [Moving views with DragGesture and offset - Hacking with Swift](https://www.hackingwithswift.com/books/ios-swiftui/moving-views-with-draggesture-and-offset) - Verified with Hacking with Swift
- [SwiftUI Swipeable Card Stack - Medium](https://yyokii.medium.com/swiftui-swipeable-card-stack-c15f09224b74) - Implementation example
- [Tinder Swipe Animation Tutorial - Medium](https://6ary.medium.com/tinder-swipe-animation-in-swiftui-tutorial-2021-b99183471e42) - Card swipe patterns
- [SwiftUI Hero Animations with NavigationTransition](https://peterfriese.dev/blog/2024/hero-animation/) - Modern hero animation approach
- [MatchedGeometryEffect Part 1 - SwiftUI Lab](https://swiftui-lab.com/matchedgeometryeffect-part1/) - Hero animation deep dive
- [Using CoreLocation with SwiftUI - Andy Ibanez](https://www.andyibanez.com/posts/using-corelocation-with-swiftui/) - Location integration patterns
- [Location Button - Sarunw](https://sarunw.com/posts/location-button/) - Modern location permission UX
- [How to detect shake gestures - Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftui/how-to-detect-shake-gestures) - Shake gesture implementation
- [Shake Gesture in SwiftUI - Medium](https://medium.com/@abdelrahman_adm/shake-gesture-in-swiftui-1ce0342fbb4e) - UIWindow override pattern
- [Accessibility actions in SwiftUI - Swift with Majid](https://swiftwithmajid.com/2021/04/15/accessibility-actions-in-swiftui/) - VoiceOver custom actions
- [Making custom UI accessible for VoiceOver - Medium](https://medium.com/@federicoramos77/making-custom-ui-elements-in-swiftui-accessible-for-voiceover-3e161365b5df) - Accessibility element patterns
- [Pull to refresh in SwiftUI - Sarunw](https://sarunw.com/posts/pull-to-refresh-in-swiftui/) - Refreshable modifier usage
- [How to enable pull to refresh - Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftui/how-to-enable-pull-to-refresh) - Pull-to-refresh examples
- [NWPathMonitor Network Monitoring - Medium](https://medium.com/@husnainali593/how-to-check-network-connection-in-swiftui-using-nwpathmonitor-8f6cd4777514) - Reachability patterns
- [NWPathMonitor: The New Reachability - Medium](https://medium.com/@rwbutler/nwpathmonitor-the-new-reachability-de101a5a8835) - NWPathMonitor overview
- [SwiftData in SwiftUI Part 1 - Medium](https://medium.com/devtechie/swiftdata-in-swiftui-part-1-29272b00f718) - SwiftData models and @Query
- [Intro to SwiftData using SwiftUI - Medium](https://medium.com/@jpmtech/intro-to-swiftdata-using-swiftui-d9dc5312f5e7) - SwiftData basics
- [What is @AppStorage - Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftui/what-is-the-appstorage-property-wrapper) - AppStorage usage
- [Storing information using UserDefaults and @AppStorage](https://www.createwithswift.com/storing-information-using-user-defaults-appstorage/) - Preference persistence
- [Infinite Scroll on iOS with Swift 2026](https://copyprogramming.com/howto/infinite-scroll-on-ios-with-swift) - Pagination patterns
- [How to do pagination in SwiftUI - Medium Engineering](https://medium.engineering/how-to-do-pagination-in-swiftui-04511be7fbd1) - LazyVStack pagination
- [Kingfisher Memory Cache Configuration - StudyRaid](https://app.studyraid.com/en/read/11573/364151/memory-cache-configuration) - Cache limits setup
- [Kingfisher Cheat Sheet](https://github.com/onevcat/Kingfisher/wiki/Cheat-Sheet) - Configuration examples
- [TCA Best Practices - Krzysztof Zabłocki](https://merowing.info/posts/the-composable-architecture-best-practices/) - Production TCA patterns
- [Dependency Injection in TCA - Medium](https://medium.com/@gauravios/dependency-injection-in-the-composable-architecture-an-architects-perspective-9be5571a0f89) - @DependencyClient usage
- [How to test with TCA - Brightec](https://www.brightec.co.uk/blog/how-to-test-with-the-composable-architecture) - Testing side effects

### Tertiary (LOW confidence - flagged for validation)

- [SwiftUI Data Persistence in 2025 - DEV Community](https://dev.to/swift_pal/swiftui-data-persistence-in-2025-swiftdata-core-data-appstorage-scenestorage-explained-with-5g2c) - General persistence overview (not official source)

## Metadata

**Confidence breakdown:**
- Standard stack: **HIGH** - All libraries already integrated in Phase 4 or built-in frameworks (SwiftUI, CoreLocation, SwiftData)
- Architecture: **HIGH** - Official docs for DragGesture, matchedGeometryEffect, NWPathMonitor; verified examples from reputable sources
- Pitfalls: **MEDIUM** - Based on community experience and documented issues, but not officially documented edge cases
- Performance patterns: **HIGH** - LazyVStack, Kingfisher cache limits, Apollo cache policies verified with official docs

**Research date:** 2026-03-01
**Valid until:** 2026-04-01 (30 days for stable frameworks; SwiftUI/TCA patterns evolve slowly)

---

*Phase 5: Guest Browsing & Feed*
*Research complete: 2026-03-01*
