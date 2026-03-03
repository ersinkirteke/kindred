# Phase 8: Authentication & Onboarding - Research

**Researched:** 2026-03-03
**Domain:** iOS authentication with Clerk SDK, SwiftUI onboarding flows, guest-to-authenticated user migration
**Confidence:** HIGH

## Summary

Phase 8 implements one-tap authentication (Google OAuth + Apple Sign In via Clerk), a skippable onboarding carousel, and seamless guest-to-authenticated data migration. The Clerk iOS SDK is already integrated in Phase 4 with `ClerkAuthClient` wrapping token retrieval and session state. This phase adds the UI layer (sign-in gate, onboarding flow) and backend migration logic.

Key technical challenges: (1) guest data migration requires GraphQL mutations to upload SwiftData bookmarks/skips and link the guest UUID to the authenticated account, (2) onboarding flow must replace the existing `WelcomeCardView` while maintaining TCA patterns, and (3) auth gate must intercept gated actions (bookmarking, voice features) without visual indicators on buttons.

**Primary recommendation:** Use Clerk's native `signInWithApple()` and OAuth methods for authentication, TabView with PageTabViewStyle for onboarding carousel, and batch GraphQL mutations for guest data migration. Track onboarding completion and gate cooldown via @AppStorage. Implement auth gate as TCA middleware to intercept actions before execution.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Sign-in Presentation:**
- Full-screen gate view (not sheet, not inline)
- Apple Sign In + Google OAuth buttons stacked vertically (Apple on top, Google below)
- App branding + tagline above buttons (e.g., "Save recipes, hear them narrated, make them yours")
- "Continue as guest" skip link always visible below buttons
- Swipe-down gesture + skip button both dismiss the gate
- After successful sign-in: instant transition back to where user was (no celebration/animation)
- Sign-in errors: inline red text below buttons with retry message
- Generic sign-in message — no contextual hint about what triggered the gate

**Guest Conversion Triggers:**
- Gated actions: bookmarking a recipe + all voice features (listen + upload)
- Non-gated actions: browsing feed, viewing recipe details, skipping recipes, setting session dietary prefs
- Gating behavior: block the action entirely until signed in (no local save for gated actions)
- After sign-in via gate: auto-complete the original action (e.g., bookmark saves automatically)
- Cooldown: 5 minutes after dismissing the gate before showing it again
- No visual indicators on gated buttons (no lock icons) — user discovers gate on tap
- Same generic sign-in screen regardless of which action triggered it

**Onboarding Sequence:**
- Triggers on first app launch (replaces current WelcomeCardView)
- Horizontal paging carousel with dots indicator
- Step order: Sign-in → Dietary preferences → Location → Voice teaser → Start
- All steps are skippable (including sign-in — "Continue as guest")
- Dietary preferences: chip/tag grid (multi-select) — Vegetarian, Vegan, Gluten-free, Keto, Halal, etc.
- Location: iOS "When In Use" location permission request. If denied, offer manual city entry fallback
- Voice step: teaser card explaining voice narration feature + "Set up later" / "Try it now" CTA (not the full upload flow)

**Data Migration:**
- Silent background sync after guest converts to account
- Upload all local SwiftData (GuestBookmark, GuestSkip) + dietary preferences to backend
- Delete local SwiftData records after successful migration (backend becomes source of truth)
- On migration failure: retry silently in background. Data stays local until sync succeeds. No user-facing error
- Link guest UUID (from UserDefaults "guestUserId") to the new authenticated account on backend for analytics continuity

### Claude's Discretion
- Exact sign-in screen layout spacing and typography
- Loading states during sign-in flow
- Carousel animation and transition timing
- Specific dietary preference chip list items
- Location fallback city picker implementation
- Voice teaser card design and copy
- Migration retry strategy (exponential backoff, max retries, etc.)
- How to handle edge case: user signs in during onboarding vs. signs in later via gated action

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| AUTH-02 | User can sign in with Google OAuth (one-tap) | Clerk iOS SDK provides `.signIn(strategy: .oauth(provider: .google))` for one-tap Google OAuth flow |
| AUTH-03 | User can sign in with Apple Sign In (one-tap) | Clerk iOS SDK provides `signInWithApple()` method that handles native Apple Sign In flow |
| AUTH-04 | Guest user is prompted to create account when saving, bookmarking, or using voice features | Auth gate implemented as TCA middleware intercepting bookmarking and voice actions, presenting full-screen gate |
| AUTH-05 | Guest session state (browsed recipes, preferences) persists through account conversion | GraphQL mutations upload GuestBookmark/GuestSkip SwiftData + dietary preferences to backend, then delete local records |
| AUTH-06 | User completes onboarding flow in under 90 seconds (dietary prefs, location, optional voice upload) | TabView with PageTabViewStyle for carousel, all steps skippable, tracked via @AppStorage("hasCompletedOnboarding") |

</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Clerk iOS SDK | 1.x (installed) | Authentication provider | Already integrated in Phase 4, provides native OAuth + Apple Sign In with SwiftUI components |
| ClerkKit | Part of Clerk SDK | Core auth API (sign-in, session) | Handles token management, session state, keychain storage |
| AuthenticationServices | iOS 17+ built-in | Apple Sign In framework | Apple's native framework for Sign in with Apple, required for SignInWithAppleButton |
| SwiftUI TabView | iOS 17+ built-in | Onboarding carousel | Native SwiftUI component for horizontal paging, supports PageTabViewStyle for dots indicator |
| @AppStorage | iOS 17+ built-in | Onboarding completion tracking | SwiftUI property wrapper for UserDefaults, auto-invalidates views on value change |
| CoreLocation | iOS 17+ built-in | Location permission request | Standard iOS framework for location services, CLLocationManager for "When In Use" permission |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| TCA (Composable Architecture) | 1.x (installed) | State management for auth flows | All features use TCA — auth gate and onboarding follow same pattern |
| Apollo iOS | 2.0.6 (installed) | GraphQL mutations for data migration | Upload guest bookmarks/skips to backend via GraphQL |
| SwiftData | iOS 17+ built-in | Guest session storage | Already used for GuestBookmark/GuestSkip — migration reads from SwiftData then deletes |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Clerk SDK | Firebase Auth | Clerk already integrated, no advantage to switching. Firebase requires separate configuration for OAuth providers |
| TabView PageTabViewStyle | Custom gesture-based carousel | TabView is native, accessible, and handles pagination dots automatically. Custom solution adds complexity with no benefit |
| @AppStorage | Custom UserDefaults wrapper | @AppStorage auto-invalidates SwiftUI views, cleaner than manual observation |

**Installation:**
```bash
# Already installed in Phase 4
# No additional dependencies needed
```

## Architecture Patterns

### Recommended Project Structure
```
Kindred/Packages/
├── AuthClient/                  # Existing (Phase 4)
│   └── Sources/
│       └── AuthModels.swift     # AuthState enum, ClerkUser model
├── AuthFeature/                 # NEW in Phase 8
│   └── Sources/
│       ├── SignIn/
│       │   ├── SignInGateReducer.swift       # TCA reducer for auth gate
│       │   ├── SignInGateView.swift          # Full-screen sign-in UI
│       │   └── SignInClient.swift            # Dependency wrapping Clerk auth methods
│       ├── Onboarding/
│       │   ├── OnboardingReducer.swift       # TCA reducer for onboarding flow
│       │   ├── OnboardingView.swift          # Main carousel container
│       │   ├── WelcomeStepView.swift         # Sign-in step
│       │   ├── DietaryPrefsStepView.swift    # Dietary preferences step
│       │   ├── LocationStepView.swift        # Location permission step
│       │   └── VoiceTeaserStepView.swift     # Voice feature teaser step
│       └── Migration/
│           ├── GuestMigrationClient.swift    # Dependency for data migration
│           └── GuestMigrationReducer.swift   # TCA reducer for migration logic
└── FeedFeature/                 # Existing
    └── Sources/
        └── GuestSession/        # Existing SwiftData models

Kindred/Sources/App/
├── KindredApp.swift             # Modify: Replace WelcomeCardView with onboarding check
├── AppReducer.swift             # Modify: Add auth gate state and onboarding state
└── RootView.swift               # Modify: Present auth gate and onboarding flow
```

### Pattern 1: Auth Gate as TCA Middleware
**What:** Auth gate intercepts gated actions (bookmarking, voice playback) in the reducer before execution, presenting a full-screen sign-in view when user is in `.guest` state.

**When to use:** Any action that requires authentication (bookmarking, voice features). Non-gated actions (browsing, skipping, viewing details) bypass the gate.

**Example:**
```swift
// Source: TCA navigation patterns + user requirements
import ComposableArchitecture

@Reducer
struct FeedReducer {
  @ObservableState
  struct State: Equatable {
    var authGate: SignInGateReducer.State?
    var currentAuthState: AuthState = .guest
    // ... existing feed state
  }

  enum Action {
    case bookmarkTapped(recipeId: String)
    case authGate(PresentationAction<SignInGateReducer.Action>)
    case authStateChanged(AuthState)
    case performBookmark(recipeId: String)  // Deferred action after sign-in
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .bookmarkTapped(let recipeId):
        // Gate check: If guest, show auth gate
        if state.currentAuthState == .guest {
          state.authGate = SignInGateReducer.State(
            deferredAction: .performBookmark(recipeId: recipeId)
          )
          return .none
        }
        // If authenticated, proceed directly
        return .run { send in
          await send(.performBookmark(recipeId: recipeId))
        }

      case .authGate(.presented(.signInSucceeded)):
        // Auth gate dismissed, execute deferred action
        if let deferredAction = state.authGate?.deferredAction {
          state.authGate = nil
          return .send(deferredAction)
        }
        return .none

      case .authGate(.presented(.dismissed)):
        // User dismissed without signing in
        state.authGate = nil
        return .none

      case .performBookmark(let recipeId):
        // Actually execute bookmark (authenticated)
        return .run { send in
          try await guestSessionClient.bookmarkRecipe(recipeId, ...)
        }

      // ... other actions
      }
    }
    .ifLet(\.$authGate, action: \.authGate) {
      SignInGateReducer()
    }
  }
}

// View presentation
struct FeedView: View {
  let store: StoreOf<FeedReducer>

  var body: some View {
    // ... feed content
    .fullScreenCover(item: $store.scope(state: \.authGate, action: \.authGate)) { gateStore in
      SignInGateView(store: gateStore)
    }
  }
}
```

### Pattern 2: Onboarding Carousel with TabView
**What:** Horizontal paging carousel using TabView with PageTabViewStyle, tracking current step with @State, showing dots indicator at bottom.

**When to use:** Multi-step onboarding flow with skippable steps. Replaces existing WelcomeCardView.

**Example:**
```swift
// Source: SwiftUI onboarding patterns
import SwiftUI

struct OnboardingView: View {
  @State private var currentStep = 0
  @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
  let onComplete: () -> Void

  private let totalSteps = 4  // Sign-in, Dietary, Location, Voice

  var body: some View {
    TabView(selection: $currentStep) {
      WelcomeStepView(onNext: nextStep, onSkip: completeOnboarding)
        .tag(0)

      DietaryPrefsStepView(onNext: nextStep, onSkip: nextStep)
        .tag(1)

      LocationStepView(onNext: nextStep, onSkip: nextStep)
        .tag(2)

      VoiceTeaserStepView(onFinish: completeOnboarding)
        .tag(3)
    }
    .tabViewStyle(.page(indexDisplayMode: .always))
    .indexViewStyle(.page(backgroundDisplayMode: .always))
  }

  private func nextStep() {
    withAnimation {
      currentStep += 1
    }
  }

  private func completeOnboarding() {
    hasCompletedOnboarding = true
    onComplete()
  }
}
```

### Pattern 3: Guest Data Migration with Retry
**What:** After successful sign-in, read all SwiftData GuestBookmark/GuestSkip records, batch upload via GraphQL mutations, delete local records on success, retry silently on failure.

**When to use:** Guest-to-authenticated conversion (triggered by auth gate sign-in success or onboarding sign-in).

**Example:**
```swift
// Source: Migration patterns + GraphQL batch operations
import Dependencies
import Apollo

@Reducer
struct GuestMigrationReducer {
  @Dependency(\.guestSessionClient) var guestSessionClient
  @Dependency(\.apolloClient) var apolloClient

  @ObservableState
  struct State: Equatable {
    var isRunning = false
    var retryCount = 0
  }

  enum Action {
    case startMigration
    case migrationSucceeded
    case migrationFailed(Error)
    case retryMigration
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .startMigration:
        state.isRunning = true
        return .run { send in
          do {
            // 1. Fetch local guest data
            let guestUserId = await guestSessionClient.getGuestUserId()
            let bookmarks = await guestSessionClient.allBookmarks()
            let skips = await guestSessionClient.allSkips()
            let dietaryPrefs = UserDefaults.standard.stringArray(forKey: "dietaryPreferences") ?? []

            // 2. Upload to backend via GraphQL
            let mutation = MigrateGuestDataMutation(
              guestUserId: guestUserId,
              bookmarks: bookmarks.map { BookmarkInput(recipeId: $0.recipeId, cuisineType: $0.cuisineType) },
              skips: skips.map { SkipInput(recipeId: $0.recipeId, cuisineType: $0.cuisineType) },
              dietaryPreferences: dietaryPrefs
            )

            _ = try await apolloClient.perform(mutation: mutation)

            // 3. Delete local data (backend is now source of truth)
            for bookmark in bookmarks {
              try await guestSessionClient.unbookmarkRecipe(bookmark.recipeId)
            }
            for skip in skips {
              try await guestSessionClient.undoSkip(skip.recipeId)
            }

            await send(.migrationSucceeded)
          } catch {
            await send(.migrationFailed(error))
          }
        }

      case .migrationSucceeded:
        state.isRunning = false
        state.retryCount = 0
        return .none

      case .migrationFailed:
        state.isRunning = false
        state.retryCount += 1

        // Retry with exponential backoff (max 3 retries)
        if state.retryCount <= 3 {
          let delay = Double(1 << state.retryCount)  // 2s, 4s, 8s
          return .run { send in
            try await Task.sleep(for: .seconds(delay))
            await send(.retryMigration)
          }
        }

        // Max retries exceeded — data stays local until next app launch
        return .none

      case .retryMigration:
        return .send(.startMigration)
      }
    }
  }
}
```

### Pattern 4: Location Permission with Fallback
**What:** Request "When In Use" location permission via CLLocationManager. If denied, show manual city picker using existing MapKit search (from Phase 5).

**When to use:** Onboarding location step.

**Example:**
```swift
// Source: CoreLocation best practices + Phase 5 city picker
import SwiftUI
import CoreLocation

struct LocationStepView: View {
  @StateObject private var locationManager = LocationManager()
  @State private var showCityPicker = false
  let onNext: () -> Void
  let onSkip: () -> Void

  var body: some View {
    VStack(spacing: 24) {
      Text("Find recipes near you")
        .font(.kindredHeading2())

      Button("Use my location") {
        locationManager.requestPermission()
      }
      .buttonStyle(.primary)

      Button("Enter city manually") {
        showCityPicker = true
      }
      .buttonStyle(.secondary)

      Button("Skip") {
        onSkip()
      }
      .buttonStyle(.text)
    }
    .onChange(of: locationManager.authorizationStatus) { _, status in
      if status == .authorizedWhenInUse {
        onNext()
      }
    }
    .sheet(isPresented: $showCityPicker) {
      // Reuse existing CityPickerView from Phase 5
      CityPickerView { selectedCity in
        showCityPicker = false
        onNext()
      }
    }
  }
}

@MainActor
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
  @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
  private let manager = CLLocationManager()

  override init() {
    super.init()
    manager.delegate = self
  }

  func requestPermission() {
    manager.requestWhenInUseAuthorization()
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    authorizationStatus = manager.authorizationStatus
  }
}
```

### Anti-Patterns to Avoid
- **Showing auth gate as sheet/modal:** Requirement specifies full-screen gate. Use `.fullScreenCover()`, not `.sheet()`.
- **Visual lock indicators on gated buttons:** Requirement specifies no visual indicators. User discovers gate on tap, not before.
- **Blocking sign-in until onboarding completes:** All onboarding steps must be skippable, including sign-in step. User can complete onboarding as guest.
- **Multiple sign-in screens:** Same generic sign-in screen regardless of trigger (bookmark vs voice). No contextual messages.
- **Synchronous migration blocking UI:** Migration runs silently in background with retry. No user-facing loading state or error.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Apple Sign In authentication | Custom ASAuthorizationController flow | Clerk's `signInWithApple()` | Clerk handles authorization flow, credential validation, token exchange, and session management. Edge cases: name data only sent once, email hiding, device vs simulator differences |
| OAuth provider configuration | Manual OAuth URL building and token exchange | Clerk Dashboard OAuth configuration + `.oauth(provider:)` | Clerk manages OAuth redirect URIs, state parameters, PKCE flow, token refresh. Avoids OAuth security vulnerabilities |
| Webhook signature verification | Custom HMAC validation | Svix library (already used in backend) | Svix handles timestamp validation, replay attack prevention, signature verification. Backend already uses this for Clerk webhooks |
| Onboarding completion tracking | Custom persistence layer | @AppStorage property wrapper | SwiftUI auto-invalidates views on UserDefaults change. No need for manual observation or Combine publishers |
| Carousel pagination | Custom gesture recognizers + animation | TabView with PageTabViewStyle | Native component handles swipe gestures, dots indicator, accessibility (VoiceOver announces page changes), and RTL support |

**Key insight:** Authentication and OAuth are deceptively complex domains with subtle security edge cases (CSRF, token refresh, replay attacks). Clerk abstracts these details with battle-tested implementations. Custom solutions introduce security risks and maintenance burden.

## Common Pitfalls

### Pitfall 1: Apple Sign In Name Data Loss
**What goes wrong:** Apple only provides `fullName` during initial authorization. Subsequent sign-ins don't resend name data. Deleting the Clerk user doesn't reset Apple's authorization, so re-testing requires deleting the app from iOS Settings > Apple ID > Password & Security > Apps Using Apple ID.

**Why it happens:** Apple privacy design — name is optional and only sent once to minimize data sharing.

**How to avoid:** Store name data on first receipt in backend database. Treat name as optional field in all UI. Never assume name will be present on sign-in.

**Warning signs:** User profile shows "Unknown" or blank name after initial sign-in. Backend logs show name field as null on webhook.

### Pitfall 2: Auth Gate Cooldown Not Persisted
**What goes wrong:** Cooldown timer resets on app restart, allowing user to see gate again immediately after dismissing.

**Why it happens:** Cooldown stored in @State or reducer state, not persisted to UserDefaults or disk.

**How to avoid:** Store `lastGateDismissedAt: Date?` in UserDefaults. Check `Date().timeIntervalSince(lastGateDismissedAt) < 300` (5 minutes) before showing gate.

**Warning signs:** Gate appears immediately after force-quitting and relaunching app, even though user just dismissed it.

### Pitfall 3: Migration Deletes Data Before Upload Completes
**What goes wrong:** SwiftData records deleted before GraphQL mutation confirms success, resulting in data loss on network failure.

**Why it happens:** Delete operation runs before awaiting mutation response, or error handling doesn't rollback local delete.

**How to avoid:** Delete local records only after successful mutation response. If mutation fails, retry in background and keep data local until success.

**Warning signs:** User reports missing bookmarks after sign-in. Backend logs show failed mutation but client logs show deleted SwiftData.

### Pitfall 4: Onboarding Replaces WelcomeCardView Without Removing Old Code
**What goes wrong:** Both `WelcomeCardView` and new onboarding flow appear on first launch, causing visual glitch or duplicate overlays.

**Why it happens:** `hasSeenWelcome` flag checked before onboarding flag, showing welcome card first, then onboarding.

**How to avoid:** Replace `hasSeenWelcome` with `hasCompletedOnboarding` flag. Single source of truth for first-launch flow.

**Warning signs:** Two overlays appear simultaneously on first launch. User taps through welcome card, then sees onboarding carousel.

### Pitfall 5: Gated Action Continues After Gate Dismissal Without Sign-In
**What goes wrong:** User taps bookmark → gate appears → user dismisses gate without signing in → bookmark saves locally (violates requirement).

**Why it happens:** Reducer sends bookmark action regardless of auth gate result.

**How to avoid:** Store deferred action in auth gate state. Only execute deferred action if sign-in succeeds. If gate dismissed, discard deferred action.

**Warning signs:** Guest user has bookmarks saved locally despite not signing in.

### Pitfall 6: Location Permission Never Requested on Denial
**What goes wrong:** User denies location permission → no fallback offered → stuck on location step with "Allow" button that does nothing.

**Why it happens:** CLLocationManager doesn't re-prompt after denial. Need to detect `.denied` status and show manual city picker.

**How to avoid:** Observe `authorizationStatus` changes. On `.denied`, show manual city picker automatically or offer "Enter city manually" button.

**Warning signs:** User taps "Use my location" → nothing happens → stuck on location step.

## Code Examples

Verified patterns from official sources:

### Clerk Sign In with Apple
```swift
// Source: https://clerk.com/docs/ios/guides/configure/auth-strategies/sign-in-with-apple
import ClerkKit

@MainActor
func handleAppleSignIn() async throws {
  do {
    try await Clerk.shared.auth.signInWithApple()
    // Sign-in succeeded — Clerk session is now active
  } catch {
    // Handle error (user cancelled, network failure, etc.)
    throw error
  }
}
```

### Clerk Google OAuth Sign In
```swift
// Source: https://clerk.com/docs/ios/getting-started/quickstart
import ClerkKit

@MainActor
func handleGoogleSignIn() async throws {
  do {
    try await Clerk.shared.auth.signIn(
      strategy: .oauth(provider: .google)
    )
    // Sign-in succeeded — Clerk session is now active
  } catch {
    throw error
  }
}
```

### Full-Screen Modal Presentation in SwiftUI
```swift
// Source: Apple SwiftUI documentation
import SwiftUI

struct ContentView: View {
  @State private var showAuthGate = false

  var body: some View {
    Button("Sign In") {
      showAuthGate = true
    }
    .fullScreenCover(isPresented: $showAuthGate) {
      SignInGateView(onDismiss: { showAuthGate = false })
        .interactiveDismissDisabled(false)  // Allow swipe-down dismissal
    }
  }
}
```

### TabView with Page Style for Carousel
```swift
// Source: https://www.hackingwithswift.com/quick-start/swiftui/how-to-create-scrolling-pages-of-content-using-tabviewstyle
import SwiftUI

struct OnboardingCarousel: View {
  @State private var currentPage = 0

  var body: some View {
    TabView(selection: $currentPage) {
      Text("Page 1").tag(0)
      Text("Page 2").tag(1)
      Text("Page 3").tag(2)
    }
    .tabViewStyle(.page(indexDisplayMode: .always))
    .indexViewStyle(.page(backgroundDisplayMode: .always))
  }
}
```

### Location Permission Request with Observer
```swift
// Source: https://developer.apple.com/documentation/corelocation/requesting-authorization-to-use-location-services
import CoreLocation

@MainActor
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
  @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
  private let manager = CLLocationManager()

  override init() {
    super.init()
    manager.delegate = self
    authorizationStatus = manager.authorizationStatus
  }

  func requestPermission() {
    manager.requestWhenInUseAuthorization()
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    authorizationStatus = manager.authorizationStatus
  }
}

// Info.plist required key:
// NSLocationWhenInUseUsageDescription: "Find viral recipes near your location"
```

### GraphQL Batch Mutation for Migration
```swift
// Source: Apollo iOS mutations documentation
import Apollo

func migrateGuestData(
  guestUserId: String,
  bookmarks: [BookmarkInput],
  skips: [SkipInput],
  dietaryPrefs: [String]
) async throws {
  let mutation = MigrateGuestDataMutation(
    guestUserId: guestUserId,
    bookmarks: bookmarks,
    skips: skips,
    dietaryPreferences: dietaryPrefs
  )

  let result = try await apolloClient.perform(mutation: mutation)

  guard let data = result.data else {
    throw MigrationError.noData
  }

  // Migration successful — backend now has all guest data
  // Safe to delete local SwiftData records
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Firebase Auth | Clerk | 2024-2025 | Clerk provides better SwiftUI integration, simpler OAuth setup, and built-in webhook support for backend sync |
| Manual OAuth flow with ASWebAuthenticationSession | Clerk SDK native methods | 2024-2025 | Clerk handles OAuth redirect URIs, PKCE, token refresh automatically. Reduces security risks |
| UIPageViewController for onboarding | TabView with PageTabViewStyle | iOS 14+ (2020) | SwiftUI native, no UIKit bridging, automatic accessibility support |
| Manual UserDefaults observation | @AppStorage property wrapper | iOS 14+ (2020) | SwiftUI auto-invalidates views on change, no need for Combine publishers |
| Global location permission requests | Contextual "When In Use" requests | iOS 13+ (2019) | Apple HIG best practice — request permission when user engages with location feature, not at launch |

**Deprecated/outdated:**
- **SignInWithAppleButton** from AuthenticationServices: Still valid, but Clerk's `signInWithApple()` abstracts credential handling. For custom UI, use Clerk's method instead of raw ASAuthorizationController.
- **PageTabViewStyle**: Renamed to `.page` in iOS 17+. Use `.tabViewStyle(.page(indexDisplayMode: .always))` instead of `PageTabViewStyle()`.

## Open Questions

1. **GraphQL mutation for guest data migration**
   - What we know: Backend has Clerk webhook handler for user.created. Prisma schema has User and Bookmark models.
   - What's unclear: Does a dedicated `migrateGuestData` mutation exist, or do we need to create it? Should migration happen via single mutation or separate mutations per entity (bookmarks, skips, dietary prefs)?
   - Recommendation: Create `migrateGuestData` mutation accepting arrays of bookmarks/skips + dietary prefs. Single transaction ensures atomicity. Mutation should also accept guestUserId to link analytics data.

2. **Auth gate cooldown persistence across app restarts**
   - What we know: Cooldown is 5 minutes after dismissal.
   - What's unclear: Should cooldown persist across app restarts, or reset on fresh launch? Current requirement says "5 minutes after dismissing the gate before showing it again" without specifying persistence.
   - Recommendation: Persist cooldown to UserDefaults (`lastGateDismissedAt: Date?`) to prevent immediate re-prompt after force-quit. User intent to dismiss should persist across sessions.

3. **Onboarding skip behavior during sign-in step**
   - What we know: All steps are skippable, including sign-in.
   - What's unclear: If user skips sign-in during onboarding, do they see dietary prefs/location steps (which might feel pointless as guest), or skip straight to end?
   - Recommendation: Show all steps regardless of sign-in status. Dietary prefs work for guest mode (already implemented via @AppStorage in Phase 6). Location already works for guest. Voice teaser educates user about premium feature, even if unavailable as guest.

4. **Voice upload during onboarding vs. later**
   - What we know: Voice step is teaser with "Set up later" / "Try it now" CTA, not full upload flow.
   - What's unclear: Does "Try it now" launch the existing voice upload flow (from Phase 7), or is it a simplified inline upload?
   - Recommendation: Launch existing voice upload flow in a modal. Onboarding completes after dismissal, preventing nested onboarding → voice upload → onboarding. Onboarding completion flag set before launching voice upload.

## Validation Architecture

> Phase 8 validation strategy

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest + TCA TestStore (inherited from Phase 4) |
| Config file | Kindred.xcodeproj test target |
| Quick run command | `xcodebuild test -scheme Kindred -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:KindredTests/AuthFeatureTests` |
| Full suite command | `xcodebuild test -scheme Kindred -destination 'platform=iOS Simulator,name=iPhone 16 Pro'` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AUTH-02 | Google OAuth sign-in completes successfully | Unit (TCA TestStore) | `xcodebuild test -only-testing:KindredTests/SignInClientTests/testGoogleOAuthSignIn` | ❌ Wave 0 |
| AUTH-03 | Apple Sign In completes successfully | Unit (TCA TestStore) | `xcodebuild test -only-testing:KindredTests/SignInClientTests/testAppleSignIn` | ❌ Wave 0 |
| AUTH-04 | Auth gate appears when guest taps bookmark | Unit (TCA TestStore) | `xcodebuild test -only-testing:KindredTests/FeedReducerTests/testBookmarkGateTrigger` | ❌ Wave 0 |
| AUTH-04 | Auth gate respects 5-minute cooldown | Unit (TCA TestStore) | `xcodebuild test -only-testing:KindredTests/SignInGateReducerTests/testCooldownPersistence` | ❌ Wave 0 |
| AUTH-05 | Guest bookmarks migrate to backend on sign-in | Integration (mock GraphQL) | `xcodebuild test -only-testing:KindredTests/GuestMigrationReducerTests/testBookmarkMigration` | ❌ Wave 0 |
| AUTH-05 | Migration retries on failure | Unit (TCA TestStore) | `xcodebuild test -only-testing:KindredTests/GuestMigrationReducerTests/testMigrationRetry` | ❌ Wave 0 |
| AUTH-06 | Onboarding carousel advances through all steps | Unit (TCA TestStore) | `xcodebuild test -only-testing:KindredTests/OnboardingReducerTests/testCarouselNavigation` | ❌ Wave 0 |
| AUTH-06 | Onboarding completion flag persists to UserDefaults | Unit | `xcodebuild test -only-testing:KindredTests/OnboardingReducerTests/testCompletionPersistence` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `xcodebuild test -only-testing:KindredTests/AuthFeatureTests` (auth-specific tests only)
- **Per wave merge:** Full test suite (`xcodebuild test -scheme Kindred`)
- **Phase gate:** Full suite green + manual device testing (Clerk OAuth requires device, not simulator)

### Wave 0 Gaps
- [ ] `KindredTests/AuthFeatureTests/SignInClientTests.swift` — covers AUTH-02, AUTH-03 (OAuth + Apple Sign In)
- [ ] `KindredTests/AuthFeatureTests/SignInGateReducerTests.swift` — covers AUTH-04 (gate triggering, cooldown)
- [ ] `KindredTests/AuthFeatureTests/GuestMigrationReducerTests.swift` — covers AUTH-05 (migration success, retry)
- [ ] `KindredTests/AuthFeatureTests/OnboardingReducerTests.swift` — covers AUTH-06 (carousel, completion tracking)
- [ ] Mock GraphQL client for migration tests (Apollo mocking)

## Sources

### Primary (HIGH confidence)
- [Clerk iOS SDK Quickstart](https://clerk.com/docs/ios/getting-started/quickstart) - Installation, configuration, SwiftUI environment setup
- [Clerk Sign in with Apple Guide](https://clerk.com/docs/ios/guides/configure/auth-strategies/sign-in-with-apple) - Native Apple Sign In implementation, gotchas
- [Apple Developer: Requesting Authorization for Location Services](https://developer.apple.com/documentation/corelocation/requesting-authorization-to-use-location-services) - CLLocationManager patterns
- [Apple Developer: fullScreenCover Modifier](https://developer.apple.com/documentation/swiftui/view/fullscreencover(ispresented:ondismiss:content:)) - Full-screen modal presentation
- [Apple Developer: TabView](https://developer.apple.com/documentation/swiftui/tabview) - Carousel implementation
- [Clerk Webhooks Documentation](https://clerk.com/docs/webhooks/sync-data) - Backend user.created webhook handling

### Secondary (MEDIUM confidence)
- [Hacking with Swift: TabView Page Style](https://www.hackingwithswift.com/quick-start/swiftui/how-to-create-scrolling-pages-of-content-using-tabviewstyle) - Onboarding carousel pattern
- [SwiftUI Onboarding Flow (Dev.to)](https://dev.to/thevediwho/onboarding-flow-in-ios-18-30daysofswift-kee) - @AppStorage completion tracking pattern
- [Medium: SwiftUI Sign in with Apple in ONE Line](https://medium.com/@itsuki.enjoy/swiftui-sign-in-with-apple-in-one-line-589db4e1a059) - Apple Sign In integration
- [Apollo iOS Mutations Documentation](https://www.apollographql.com/docs/ios/fetching/mutations) - GraphQL mutation patterns
- [TCA GitHub Discussion: Modal Navigation](https://github.com/pointfreeco/swift-composable-architecture/discussions/2048) - TCA sheet/fullScreenCover patterns

### Tertiary (LOW confidence)
- [Medium: Setting Up Clerk with NestJS](https://medium.com/@aozora-med/setting-up-clerk-authentication-with-nestjs-and-next-js-3cdcb54a6780) - Backend webhook integration examples
- [Dev.to: Sync Clerk Users to Database](https://dev.to/devlawrence/sync-clerk-users-to-your-database-using-webhooks-a-step-by-step-guide-263i) - Guest-to-authenticated migration strategy inspiration

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Clerk SDK already integrated, Apple frameworks are native, patterns verified in official docs
- Architecture: HIGH - TCA patterns established in Phase 4-7, onboarding carousel is standard SwiftUI, migration follows Apollo best practices
- Pitfalls: MEDIUM - Apple Sign In name data loss and cooldown persistence are documented edge cases, others derived from requirement analysis

**Research date:** 2026-03-03
**Valid until:** 2026-04-03 (30 days for stable domain — authentication patterns change slowly)
