# Phase 11: Auth Gap Closure - Research

**Researched:** 2026-03-08
**Domain:** TCA presentation state management, SwiftUI fullScreenCover composition, Apollo iOS GraphQL mutations, SwiftData-to-backend migration patterns
**Confidence:** HIGH

## Summary

Phase 11 closes two v2.0 milestone gaps: (1) wire OnboardingReducer as `@Presents` in AppReducer so the carousel appears after first sign-in, and (2) verify guest session state (bookmarks, skips, dietary prefs, city) persists through account conversion with no data loss. The architecture is already 90% complete from Phase 8 — OnboardingReducer exists with all 4 steps (sign-in, dietary, location, voice teaser), GuestMigrationClient has the migration logic skeleton, and AppReducer has migration triggers. This phase is integration work, not greenfield development.

The technical challenge is twofold: (1) coordinate two fullScreenCover presentations (auth gate dismisses first, onboarding presents second) without jarring transitions, and (2) implement the real GraphQL `migrateGuestData` mutation to replace the TODO placeholder while handling offline/retry edge cases gracefully. The onboarding carousel must appear ONLY after first sign-in (not on first launch), pre-fill dietary prefs and city from guest data if available, and resume from the last completed step if dismissed mid-flow.

**Primary recommendation:** Use `@Presents var onboarding: OnboardingReducer.State?` in AppReducer following the exact pattern used for `authGate`. Trigger onboarding from `authStateChanged` when user transitions to `.authenticated` AND `hasCompletedOnboarding` is false. Remove sign-in step from OnboardingReducer (user is already authenticated) and update `totalSteps` to 3. Create `MigrateGuestData.graphql` mutation file matching the pattern in `NetworkClient/Sources/GraphQL/`, run Apollo codegen, and replace the TODO in `GuestMigrationClient.migrateGuestData()` with a real Apollo mutation call. Handle offline retries via existing `connectivityChanged` action in AppReducer.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Onboarding Trigger:**
- Onboarding carousel appears **only after first sign-in**, not on first launch
- Any sign-in path triggers it (auth gate popup OR profile tab sign-in)
- Sign-in step is removed from the carousel — user already authenticated
- Carousel is 3 steps: Dietary Prefs → Location → Voice Teaser (update totalSteps to 3)
- Step indicator shows 3 dots

**Onboarding Presentation:**
- Use `.fullScreenCover` with `@Presents` in AppReducer (same pattern as auth gate)
- Dismissable with reminder: user can swipe down/tap X, carousel reappears on next launch until completed
- Resume from last completed step (persist current step to UserDefaults)
- Feed updates only after onboarding completes, not per-step
- Pre-fill dietary prefs and city from guest data if user set them before sign-in

**Onboarding Step Content:**
- First step shows personalized greeting: "Welcome, [firstName]! Let's personalize your feed"
- Use firstName from Clerk user profile
- Fallback to generic "Welcome! Let's personalize your feed" if name unavailable (Apple Sign In can hide name)
- All steps remain skippable (per AUTH-06 90-second requirement)
- Voice teaser "Try Voice Now" completes onboarding, then opens voice upload sheet separately

**Auth State Transitions:**
- Single trigger point: `authStateChanged` in AppReducer — when `.authenticated` AND `hasCompletedOnboarding` is false → present onboarding
- Auth gate dismisses first, brief moment of main app visible, then onboarding fullScreenCover presents
- Profile tab sign-in follows the same flow
- `hasCompletedOnboarding` moves to TCA state in AppReducer, persisted to UserDefaults via effect
- OnboardingReducer sends `.delegate(.completed(prefs, city))` action — AppReducer forwards to feed

**Migration Scope:**
- ALL guest data migrates: bookmarks (SwiftData), skips (SwiftData), dietary preferences (UserDefaults), city (UserDefaults)
- Local data stays intact during conversion + sent to backend via GraphQL mutation (belt and suspenders)
- On backend failure: keep local, retry later — no data loss risk
- After confirmed backend sync: clean up local SwiftData guest records — Apollo cache takes over for bookmarks
- After migration, bookmarks sourced from Apollo cache (server-synced), not SwiftData

**Migration Backend:**
- Backend `migrateGuestData` mutation already exists in schema
- Takes: guestUserId, bookmarks array, skips array, dietaryPreferences array, city string
- Single atomic call — all data in one mutation, all-or-nothing
- Idempotent — backend uses guestUserId as dedup key, safe to retry
- Response returns counts (migratedBookmarks, migratedSkips, etc.)
- Verify returned counts match local counts before cleaning up SwiftData
- Claude should check codebase for existing .graphql operations directory and follow same pattern for codegen

**Post-Conversion UX:**
- Silent background migration — no loading indicator, user goes straight to onboarding carousel
- No confirmation message after conversion — data just appears where expected
- Silent failure if migration fails after all retries — local data stays, retry on next launch
- After successful migration, populate Apollo cache from response so bookmarks appear immediately in profile

**Offline Edge Cases:**
- If migration fails due to network: retry automatically when connectivity returns (use existing `connectivityChanged` action)
- Onboarding presents independently of migration — doesn't wait for migration to complete
- If onboarding prefs conflict with migrating guest prefs: onboarding prefs win (most recent intent)
- `pendingMigration` flag persists in UserDefaults across app restarts — retry on next launch if needed

**Testing:**
- Manual QA: browse as guest, bookmark recipes, sign in, verify bookmarks appear in profile
- TCA unit tests for migration reducer logic with mock GuestMigrationClient
- Edge case tests: empty guest data, partial data (bookmarks but no prefs), offline during migration, duplicate migration calls

### Claude's Discretion
- Exact animation timing for auth gate dismiss → onboarding present transition
- UserDefaults key names for onboarding step persistence
- Retry timing/backoff strategy for connectivity-based migration retry
- Apollo cache population strategy from migration response
- GraphQL operation file placement (Claude to check existing pattern)

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| AUTH-05 | Guest session state (browsed recipes, preferences) persists through account conversion | Apollo iOS mutation API, existing GuestMigrationClient skeleton, SwiftData → GraphQL mapping patterns |
| AUTH-06 | User completes onboarding flow in under 90 seconds (dietary prefs, location, optional voice upload) | TCA `@Presents` pattern, SwiftUI fullScreenCover with `item:`, UserDefaults-based step persistence |

</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| TCA (Composable Architecture) | 1.x | State management for onboarding + migration | Already integrated, all features use TCA — onboarding uses `@Presents` same as auth gate |
| Apollo iOS | 2.0.6 | GraphQL mutations for guest data migration | Already integrated, provides `apolloClient.perform(mutation:)` API with cache updates |
| SwiftUI | iOS 17+ | fullScreenCover presentation | Native presentation API, pairs with TCA's `@Presents` via `.sheet(item:)` / `.fullScreenCover(item:)` |
| SwiftData | iOS 17+ | Guest session storage (GuestBookmark, GuestSkip) | Already used for guest data, source for migration payload |
| UserDefaults | iOS 17+ | Onboarding step + completion persistence | Standard persistence for lightweight app state, `hasCompletedOnboarding` flag |
| Clerk iOS SDK | 1.x | User profile access (firstName) | Already integrated, provides `ClerkUser.firstName` for personalized onboarding greeting |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| @AppStorage | iOS 17+ | SwiftUI property wrapper for UserDefaults | Alternative to manual UserDefaults calls, auto-invalidates views — NOT used in TCA reducers (use effects instead) |
| CoreLocation | iOS 17+ | Location client (already exists) | OnboardingReducer already uses `LocationClient` from FeedFeature for GPS + city picker |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Apollo mutations | REST endpoint for migration | Apollo already integrated, mutations update local cache automatically (bookmarks appear immediately), REST requires manual cache sync |
| fullScreenCover | sheet presentation for onboarding | fullScreenCover matches auth gate pattern, feels more immersive for first-time setup vs. sheet which feels optional |
| UserDefaults for step persistence | TCA state only | UserDefaults survives app restart — if user dismisses onboarding mid-flow and force-quits app, they resume from same step |

**Installation:**
```bash
# Already installed in Phase 4 + Phase 8
# No additional dependencies needed
```

## Architecture Patterns

### Recommended Project Structure
```
Kindred/Packages/
├── AuthFeature/
│   └── Sources/
│       ├── Onboarding/
│       │   ├── OnboardingReducer.swift     # MODIFY: Remove sign-in step, add delegate action
│       │   ├── OnboardingView.swift        # MODIFY: Update totalSteps to 3
│       │   ├── DietaryPrefsStepView.swift  # MODIFY: Add personalized greeting with firstName
│       │   ├── LocationStepView.swift      # (no changes needed)
│       │   └── VoiceTeaserStepView.swift   # (no changes needed)
│       └── Migration/
│           └── GuestMigrationClient.swift  # MODIFY: Replace TODO with real Apollo mutation
├── NetworkClient/
│   └── Sources/
│       └── GraphQL/
│           ├── FeedQueries.graphql         # Existing
│           ├── RecipeQueries.graphql       # Existing
│           └── MigrateGuestData.graphql    # NEW: Migration mutation operation
└── (generated by Apollo codegen)
    └── KindredAPI/
        └── Operations/
            └── Mutations/
                └── MigrateGuestDataMutation.graphql.swift  # Auto-generated

Kindred/Sources/App/
├── AppReducer.swift                        # MODIFY: Add @Presents var onboarding, trigger on authStateChanged
├── RootView.swift                          # MODIFY: Add .fullScreenCover for onboarding
└── KindredApp.swift                        # (no changes needed)
```

### Pattern 1: TCA @Presents for Onboarding
**What:** Use `@Presents var onboarding: OnboardingReducer.State?` in AppReducer to manage onboarding lifecycle. Setting state to non-nil presents onboarding, setting to nil dismisses.

**When to use:** Any child reducer that needs full-screen or sheet presentation. Already used for `authGate` in AppReducer and `paywall` in FeedReducer.

**Example:**
```swift
// Source: AppReducer.swift (existing pattern for authGate)
@Reducer
struct AppReducer {
    @ObservableState
    struct State: Equatable {
        // Existing
        @Presents var authGate: SignInGateReducer.State?

        // NEW for Phase 11
        @Presents var onboarding: OnboardingReducer.State?
        var hasCompletedOnboarding: Bool = false
    }

    enum Action {
        case authGate(PresentationAction<SignInGateReducer.Action>)
        case onboarding(PresentationAction<OnboardingReducer.Action>)  // NEW
        case authStateChanged(AuthClient.AuthState)
        case persistOnboardingCompletion  // NEW: Save to UserDefaults
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .authStateChanged(let authState):
                state.currentAuthState = authState

                // NEW: Trigger onboarding after first sign-in
                if case .authenticated = authState, !state.hasCompletedOnboarding {
                    state.authGate = nil  // Dismiss auth gate first
                    state.onboarding = OnboardingReducer.State()  // Present onboarding
                }

                // ... existing migration logic

            case .onboarding(.presented(.delegate(.completed(let prefs, let city)))):
                state.hasCompletedOnboarding = true
                state.onboarding = nil  // Dismiss onboarding

                // Forward dietary prefs and city to feed
                return .concatenate(
                    .send(.feed(.dietaryFilterChanged(prefs))),
                    city.map { .send(.feed(.changeLocation($0))) } ?? .none,
                    .send(.persistOnboardingCompletion)
                )

            case .persistOnboardingCompletion:
                return .run { _ in
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                }

            // ... rest of reducer
            }
        }
        .ifLet(\.$authGate, action: \.authGate) {
            SignInGateReducer()
        }
        .ifLet(\.$onboarding, action: \.onboarding) {  // NEW
            OnboardingReducer()
        }
    }
}
```

**Key points:**
- `@Presents` property wrapper manages optional child state
- `.ifLet` scopes child reducer to handle child actions
- `PresentationAction` wraps child actions with `.presented()` and `.dismiss()`
- Setting state to non-nil triggers presentation, nil dismisses

### Pattern 2: SwiftUI fullScreenCover with @Presents
**What:** Bind `@Presents` state to `.fullScreenCover(item:)` modifier for reactive presentation.

**When to use:** Any full-screen modal that needs to cover the entire app (onboarding, auth gate). Use `.sheet(item:)` for partial-height sheets.

**Example:**
```swift
// Source: RootView.swift (existing pattern for authGate)
struct RootView: View {
    @Bindable var store: StoreOf<AppReducer>

    var body: some View {
        TabView { /* ... */ }
            // Existing auth gate
            .fullScreenCover(item: $store.scope(state: \.authGate, action: \.authGate)) { gateStore in
                SignInGateView(store: gateStore)
            }
            // NEW: Onboarding cover (same pattern)
            .fullScreenCover(item: $store.scope(state: \.onboarding, action: \.onboarding)) { onboardingStore in
                OnboardingView(store: onboardingStore)
            }
    }
}
```

**Key points:**
- `$store.scope(state:action:)` creates a binding to child state
- `.fullScreenCover(item:)` presents when item is non-nil, dismisses when nil
- Multiple fullScreenCovers can be stacked — only the last non-nil one shows
- SwiftUI handles dismiss animations automatically when item becomes nil

### Pattern 3: Apollo iOS Mutation with Cache Update
**What:** Use `apolloClient.perform(mutation:)` to execute GraphQL mutations. Apollo automatically updates local cache based on mutation response.

**When to use:** Any create/update/delete operation that needs to sync with backend AND update local cache (e.g., bookmarking, migration).

**Example:**
```swift
// Source: Apollo iOS documentation + existing FeedReducer fetch pattern
import Apollo
import KindredAPI  // Generated by codegen

@DependencyClient
public struct GuestMigrationClient: Sendable {
    public var migrateGuestData: @Sendable () async throws -> MigrationResult
}

extension GuestMigrationClient: DependencyKey {
    public static let liveValue: GuestMigrationClient = {
        @Dependency(\.apolloClient) var apolloClient
        @Dependency(\.guestSessionClient) var guestSessionClient

        return GuestMigrationClient(
            migrateGuestData: {
                // 1. Read guest data
                let guestUserId = UserDefaults.standard.string(forKey: "guestUserId") ?? ""
                let bookmarks = await guestSessionClient.allBookmarks()
                let skips = await guestSessionClient.allSkips()

                var dietaryPreferences: [String] = []
                if let data = UserDefaults.standard.data(forKey: "dietaryPreferences"),
                   let prefs = try? JSONDecoder().decode(Set<String>.self, from: data) {
                    dietaryPreferences = Array(prefs)
                }

                let city = UserDefaults.standard.string(forKey: "selectedCity")

                // 2. Execute mutation
                let mutation = MigrateGuestDataMutation(
                    guestUserId: guestUserId,
                    bookmarks: bookmarks.map { $0.recipeId },
                    skips: skips.map { $0.recipeId },
                    dietaryPreferences: dietaryPreferences,
                    city: city
                )

                let result = try await apolloClient.perform(mutation: mutation)

                // 3. Verify counts match
                guard let data = result.data else {
                    throw MigrationError.noData
                }

                guard data.migrateGuestData.migratedBookmarks == bookmarks.count,
                      data.migrateGuestData.migratedSkips == skips.count else {
                    throw MigrationError.countMismatch
                }

                // 4. Clean up local SwiftData
                for bookmark in bookmarks {
                    try await guestSessionClient.unbookmarkRecipe(bookmark.recipeId)
                }
                for skip in skips {
                    try await guestSessionClient.undoSkip(skip.recipeId)
                }

                // 5. Mark migration complete
                UserDefaults.standard.set(true, forKey: "guestMigrated")

                return MigrationResult(
                    migratedBookmarks: data.migrateGuestData.migratedBookmarks,
                    migratedSkips: data.migrateGuestData.migratedSkips
                )
            }
        )
    }()
}
```

**Key points:**
- `apolloClient.perform(mutation:)` returns `GraphQLResult<MutationData>`
- Mutation response automatically updates Apollo cache (bookmarks appear in `myBookmarks` query)
- Error handling: mutation can throw `ApolloError` (network) or custom errors (count mismatch)
- Idempotent mutations (using guestUserId as dedup key) are safe to retry

### Pattern 4: TCA Delegate Actions for Parent-Child Communication
**What:** Child reducer sends `.delegate()` actions to notify parent of significant events. Parent handles delegate actions and coordinates across features.

**When to use:** When child reducer needs to trigger actions in sibling reducers or parent state (e.g., onboarding completion updates feed filters).

**Example:**
```swift
// Source: FeedReducer.swift (existing delegate pattern)
@Reducer
public struct OnboardingReducer {
    public enum Action: Equatable {
        case nextStep
        case completeOnboarding
        case delegate(Delegate)  // NEW
    }

    public enum Delegate: Equatable {
        case completed(dietaryPrefs: Set<String>, city: String?)
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .completeOnboarding:
                // Send delegate action with final selections
                return .send(.delegate(.completed(
                    dietaryPrefs: state.selectedDietaryPrefs,
                    city: state.selectedCity
                )))
            }
        }
    }
}

// Parent reducer (AppReducer) handles delegate
case .onboarding(.presented(.delegate(.completed(let prefs, let city)))):
    state.hasCompletedOnboarding = true
    state.onboarding = nil

    return .concatenate(
        .send(.feed(.dietaryFilterChanged(prefs))),
        city.map { .send(.feed(.changeLocation($0))) } ?? .none
    )
```

**Key points:**
- Delegate actions flow from child to parent via `.presented(.delegate(...))`
- Parent can coordinate across multiple children (e.g., forward to feed + profile)
- Delegate pattern keeps child reducers decoupled from parent structure

### Anti-Patterns to Avoid
- **Using @AppStorage in reducers:** @AppStorage only works in SwiftUI views. Reducers must use `.run` effects with `UserDefaults.standard` to avoid runtime crashes.
- **Multiple fullScreenCovers on the same view:** SwiftUI only presents the last non-nil fullScreenCover. Stack them in order of priority (auth gate first, onboarding second).
- **Awaiting mutation completion before presenting onboarding:** Migration should be fire-and-forget with background retries. Don't block onboarding on migration success.
- **Deleting local SwiftData before backend confirms sync:** Keep local data until backend returns success + counts match. Only then delete.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| GraphQL codegen for mutation types | Manual Swift structs matching mutation schema | Apollo iOS Code Generation Engine | Codegen auto-generates type-safe mutation structs from `.graphql` files. Manual structs drift from schema, break on backend changes. |
| Retry logic with exponential backoff | Custom timer-based retry mechanism | Existing `connectivityChanged` + `migrationRetryCount` in AppReducer | AppReducer already has exponential backoff (Phase 8). Adding custom retry duplicates logic and creates race conditions. |
| Step persistence across app restarts | Custom binary file encoding | UserDefaults with JSON | UserDefaults is atomic, thread-safe, and debuggable. Binary files require manual locking and are harder to debug. |
| Apollo cache update after mutation | Manual cache write calls | Mutation response with `__typename` fields | Apollo automatically updates cache if mutation response includes `id` and `__typename`. Manual writes are error-prone and can desync cache. |

**Key insight:** Apollo iOS is a batteries-included GraphQL client. Using its codegen, cache management, and error handling saves 100+ lines of boilerplate and avoids subtle bugs (cache desyncs, type mismatches, retry races).

## Common Pitfalls

### Pitfall 1: @Presents State Collision (Two fullScreenCovers)
**What goes wrong:** Auth gate dismisses, sets `authGate = nil`, but onboarding doesn't present because SwiftUI evaluates both fullScreenCover bindings at once and sees `onboarding = nil` still.

**Why it happens:** SwiftUI batches state changes within a single render pass. If you set `authGate = nil` and `onboarding = OnboardingReducer.State()` in the same reducer action, SwiftUI may present onboarding before auth gate finishes dismissing, causing jarring transition.

**How to avoid:** Use `.concatenate` to sequence the dismissal and presentation:
```swift
case .authStateChanged(.authenticated):
    state.currentAuthState = .authenticated

    guard !state.hasCompletedOnboarding else { return .none }

    // Sequence: dismiss auth gate, then present onboarding
    return .concatenate(
        .run { send in
            try await clock.sleep(for: .milliseconds(100))  // Brief pause for auth gate animation
            await send(.presentOnboarding)
        }
    )

case .presentOnboarding:
    state.authGate = nil
    state.onboarding = OnboardingReducer.State()
    return .none
```

**Warning signs:** Onboarding appears instantly with no auth gate dismiss animation, or auth gate lingers on screen while onboarding tries to present behind it.

### Pitfall 2: Mutation Without __typename in Response
**What goes wrong:** Apollo mutation succeeds, but bookmarks don't appear in profile. `myBookmarks` query still returns empty array.

**Why it happens:** Apollo cache updates require `__typename` and `id` fields in mutation response. If backend mutation returns `{ migratedBookmarks: 5 }` without the actual bookmark objects and their types, Apollo can't update the cache.

**How to avoid:** Mutation response must include the migrated objects with `__typename`:
```graphql
mutation MigrateGuestData($guestUserId: String!, $bookmarks: [String!]!, ...) {
  migrateGuestData(input: {
    guestUserId: $guestUserId
    bookmarks: $bookmarks
    ...
  }) {
    migratedBookmarks
    migratedSkips
    bookmarks {      # Return full objects for cache update
      id
      __typename
      recipeId
      recipeName
      imageUrl
      createdAt
    }
  }
}
```

**Warning signs:** Mutation succeeds (no errors), but profile shows empty bookmarks. Logging `apolloClient.cache.extract()` shows empty `Bookmark` entries.

### Pitfall 3: OnboardingReducer Sends Delegate Before State is Persisted
**What goes wrong:** User completes onboarding, app crashes, onboarding reappears on next launch even though user already completed it.

**Why it happens:** OnboardingReducer sends `.delegate(.completed)` immediately, parent reducer sets `hasCompletedOnboarding = true` in state, but UserDefaults persistence is async. If app crashes before effect completes, the flag is lost.

**How to avoid:** Wait for persistence to complete before dismissing onboarding:
```swift
case .onboarding(.presented(.delegate(.completed(let prefs, let city)))):
    state.hasCompletedOnboarding = true  // Update state

    return .concatenate(
        .run { _ in
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        },
        .send(.dismissOnboarding),  // Dismiss AFTER persistence
        .send(.feed(.dietaryFilterChanged(prefs))),
        city.map { .send(.feed(.changeLocation($0))) } ?? .none
    )

case .dismissOnboarding:
    state.onboarding = nil
    return .none
```

**Warning signs:** User reports "I already set up onboarding but it keeps showing up again." Check Xcode logs for rapid app terminations.

### Pitfall 4: Migration Retry Loop with No Max Attempts
**What goes wrong:** User is offline, migration fails, retries forever, drains battery and logs.

**Why it happens:** Migration is triggered on `authStateChanged` and retries on `connectivityChanged`, but there's no max retry limit or cooldown between attempts.

**How to avoid:** Use existing `migrationRetryCount` in AppReducer (added in Phase 8) to cap retries:
```swift
case .migrationFailed:
    state.isMigrating = false
    state.migrationRetryCount += 1

    // Max 3 retries, then give up until next app launch
    guard state.migrationRetryCount < 3 else {
        Logger.migration.warning("Migration failed after 3 retries, will retry on next launch")
        return .none
    }

    // Exponential backoff: 1s, 2s, 4s
    let delay = Duration.seconds(Int(pow(2.0, Double(state.migrationRetryCount - 1))))

    return .run { send in
        try await clock.sleep(for: delay)
        await send(.retryMigration)
    }
```

**Warning signs:** Console logs show hundreds of "Migration failed" messages. Battery drains faster than normal when offline.

## Code Examples

Verified patterns from official sources and existing codebase:

### TCA @Presents with fullScreenCover
```swift
// Source: AppReducer.swift + RootView.swift (existing authGate pattern)

// AppReducer.swift
@Reducer
struct AppReducer {
    @ObservableState
    struct State: Equatable {
        @Presents var onboarding: OnboardingReducer.State?
    }

    enum Action {
        case onboarding(PresentationAction<OnboardingReducer.Action>)
        case showOnboarding
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .showOnboarding:
                state.onboarding = OnboardingReducer.State()
                return .none

            case .onboarding(.presented(.delegate(.completed))):
                state.onboarding = nil  // Dismiss
                return .none
            }
        }
        .ifLet(\.$onboarding, action: \.onboarding) {
            OnboardingReducer()
        }
    }
}

// RootView.swift
struct RootView: View {
    @Bindable var store: StoreOf<AppReducer>

    var body: some View {
        TabView { /* ... */ }
            .fullScreenCover(item: $store.scope(state: \.onboarding, action: \.onboarding)) { onboardingStore in
                OnboardingView(store: onboardingStore)
            }
    }
}
```

### Apollo iOS Mutation
```swift
// Source: Apollo iOS 2.0 documentation
import Apollo
import KindredAPI  // Generated types

@Dependency(\.apolloClient) var apolloClient

let mutation = MigrateGuestDataMutation(
    guestUserId: "guest-123",
    bookmarks: ["recipe-1", "recipe-2"],
    skips: ["recipe-3"],
    dietaryPreferences: ["vegan", "gluten-free"],
    city: "Vilnius"
)

let result = try await apolloClient.perform(mutation: mutation)

if let data = result.data {
    print("Migrated \(data.migrateGuestData.migratedBookmarks) bookmarks")
}
```

### UserDefaults Persistence Effect
```swift
// Source: TCA documentation + OnboardingReducer.swift (existing pattern)
case .persistOnboardingCompletion:
    return .run { _ in
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
```

### GraphQL Mutation File
```graphql
# Source: NetworkClient/Sources/GraphQL/FeedQueries.graphql (existing pattern)
# File: NetworkClient/Sources/GraphQL/MigrateGuestData.graphql

mutation MigrateGuestData(
  $guestUserId: String!
  $bookmarks: [String!]!
  $skips: [String!]!
  $dietaryPreferences: [String!]!
  $city: String
) {
  migrateGuestData(input: {
    guestUserId: $guestUserId
    bookmarks: $bookmarks
    skips: $skips
    dietaryPreferences: $dietaryPreferences
    city: $city
  }) {
    migratedBookmarks
    migratedSkips
    bookmarks {
      id
      __typename
      recipeId
      recipeName
      imageUrl
      createdAt
    }
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual UserDefaults observation | @AppStorage property wrapper | iOS 14+ | Only works in SwiftUI views, NOT in TCA reducers. Use `.run` effects with UserDefaults.standard instead. |
| `.sheet(isPresented:)` binding | `.sheet(item:)` with optional state | iOS 15+ | Item-based sheets automatically bind to optional state, cleaner than manual Bool binding. |
| Apollo custom cache writes | Automatic cache updates via mutation response | Apollo iOS 2.0 | Include full objects with __typename in mutation response, Apollo updates cache automatically. |
| Separate .graphql files per mutation | Single file with multiple operations | Apollo iOS 2.0 | Both patterns work, but single file per operation is easier to maintain and aligns with codegen expectations. |

**Deprecated/outdated:**
- **Old codegen setup:** `apollo-ios-cli` replaced `apollo-tooling`. If codebase has `apollo-codegen` scripts, update to `apollo-ios-cli generate`.
- **Manual Clerk session observation:** Phase 8 used `ClerkAuthClient.observeAuthState()` stream — already implemented, no changes needed.

## Open Questions

1. **Backend mutation schema verification**
   - What we know: CONTEXT.md states "backend `migrateGuestData` mutation already exists in schema"
   - What's unclear: Exact mutation signature (input type fields, response type fields)
   - Recommendation: Check `backend/schema.gql` for mutation definition. If missing, coordinate with backend team to add it. Mutation MUST return migrated object arrays with `__typename` for cache update.

2. **Apollo cache population strategy**
   - What we know: After migration, bookmarks should appear immediately in profile (from Apollo cache, not SwiftData)
   - What's unclear: Does mutation response include full bookmark objects, or do we need a separate `myBookmarks` query after migration?
   - Recommendation: Mutation response should include bookmark objects with `__typename`. If backend doesn't support this, fall back to manual cache write or refetch `myBookmarks` query after migration.

3. **Onboarding step persistence key naming**
   - What we know: Resume from last completed step across app restarts
   - What's unclear: UserDefaults key name pattern (e.g., "onboardingCurrentStep" vs "lastCompletedOnboardingStep")
   - Recommendation: Use "onboardingCurrentStep" for consistency with existing keys ("hasCompletedOnboarding", "selectedCity", "dietaryPreferences").

## Sources

### Primary (HIGH confidence)
- TCA Documentation - `@Presents` and `.ifLet` patterns (official docs)
- Apollo iOS 2.0.6 Documentation - `perform(mutation:)` API and cache updates (official docs)
- Existing codebase - AppReducer.swift `authGate` pattern (line 27, 98), FeedReducer.swift delegate pattern (line 92-102), GuestMigrationClient.swift skeleton (AuthFeature/Sources/Migration/)
- Kindred backend schema.gql - GraphQL schema reference (backend/schema.gql)
- Phase 8 RESEARCH.md - Auth gate and onboarding architecture decisions (already implemented)

### Secondary (MEDIUM confidence)
- SwiftUI fullScreenCover documentation - Item-based presentation binding (Apple official docs)
- UserDefaults thread safety - Atomic reads/writes guaranteed by Foundation (Apple official docs)

### Tertiary (LOW confidence)
- None — all findings verified against official docs or existing codebase

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All libraries already integrated, patterns proven in Phase 8
- Architecture: HIGH - TCA `@Presents` pattern already used for authGate and paywall, exact same approach for onboarding
- Pitfalls: HIGH - Based on existing codebase patterns (auth gate dismiss timing) and Apollo iOS documentation (cache update requirements)

**Research date:** 2026-03-08
**Valid until:** 2026-04-08 (30 days - stable stack, no fast-moving dependencies)
