---
phase: 08-authentication-onboarding
plan: 03
subsystem: Authentication & User Flow
tags: [auth-gate, guest-migration, tca, integration]
dependency_graph:
  requires:
    - SignInGateReducer (08-01)
    - SignInClient (08-01)
    - GuestSessionClient (05-01)
    - AuthState (08-01)
  provides:
    - GuestMigrationClient
    - AppReducer with auth state management
    - Auth-gated bookmark and voice actions
  affects:
    - FeedReducer (auth state propagation)
    - RecipeDetailReducer (auth state propagation)
    - RootView (auth gate presentation)
    - KindredApp (onboarding flag)
tech_stack:
  added:
    - GuestMigrationClient TCA dependency
  patterns:
    - TCA delegate actions for parent-child communication
    - Presentation composition with @Presents
    - Auth gate cooldown with UserDefaults persistence
    - Exponential backoff retry logic
key_files:
  created:
    - Kindred/Packages/AuthFeature/Sources/Migration/GuestMigrationClient.swift
  modified:
    - Kindred/Sources/App/AppReducer.swift
    - Kindred/Packages/FeedFeature/Sources/Feed/FeedReducer.swift
    - Kindred/Packages/FeedFeature/Sources/RecipeDetail/RecipeDetailReducer.swift
    - Kindred/Sources/App/RootView.swift
    - Kindred/Sources/App/KindredApp.swift
    - Kindred/Package.swift
    - Kindred/Packages/FeedFeature/Package.swift
    - Kindred/Packages/AuthFeature/Package.swift
decisions:
  - decision: "Guest bookmark swipe triggers auth gate - card removed from stack before gate shown for responsive UI"
    rationale: "User sees immediate visual feedback, gate doesn't interrupt swipe animation"
  - decision: "Skip swipes remain ungated for guests per product requirements"
    rationale: "Allows full feed browsing without auth pressure"
  - decision: "5-minute cooldown persists to UserDefaults, not in-memory"
    rationale: "Cooldown survives app restart to prevent gate fatigue"
  - decision: "Migration retries 3 times with exponential backoff (2s, 4s, 8s)"
    rationale: "Handles transient network errors without blocking UX"
  - decision: "Guest UUID kept after migration for analytics continuity"
    rationale: "Preserves user journey tracking across guest-to-auth transition"
  - decision: "Deferred onboarding integration until Plan 08-02 is complete"
    rationale: "OnboardingView components don't exist yet, flag structure prepared"
metrics:
  duration_minutes: 35
  tasks_completed: 2
  files_created: 1
  files_modified: 8
  commits: 0
  completed_at: "2026-03-04T00:05:37Z"
---

# Phase 08 Plan 03: Auth Gate Integration Summary

**One-liner:** Auth gate with deferred action execution, guest data migration with retry logic, and auth state propagation through TCA delegate pattern

## Status: BLOCKED - Build Configuration Issue

**Implementation Complete:** All tasks implemented per specification
**Verification Status:** ❌ Cannot verify due to Xcode module resolution issue
**Blockers:** AuthFeature module not recognized by Xcode build system

## What Was Built

### Task 1: GuestMigrationClient and AppReducer Auth Integration

**GuestMigrationClient** (`AuthFeature/Sources/Migration/GuestMigrationClient.swift`):
- TCA @DependencyClient for migrating guest data to authenticated backend
- `migrateGuestData()`: Uploads bookmarks, skips, dietary prefs; cleans local storage
- `hasPendingMigration()`: Checks for unmigrated local data
- Placeholder GraphQL mutation (logs data until backend endpoint ready)
- Keeps guestUserId for analytics, marks migrated with boolean flag

**AppReducer Enhancements** (`Sources/App/AppReducer.swift`):
- **Auth state management:** `currentAuthState: AuthState` tracks guest vs authenticated
- **Auth gate presentation:** `@Presents var authGate: SignInGateReducer.State?`
- **Deferred action execution:** `pendingGatedAction: GatedAction?` stores bookmark/listen action
- **Migration orchestration:** `startMigration`, `migrationSucceeded`, `migrationFailed` actions
- **Cooldown logic:** 5-minute gate suppression via UserDefaults("lastGateDismissedAt")
- **Exponential backoff:** Retry migration up to 3 times with 2s, 4s, 8s delays
- **Child action forwarding:** Executes pending action after sign-in success

**GatedAction enum:**
```swift
enum GatedAction: Equatable {
    case bookmark(recipeId: String, recipeName: String, imageUrl: String?, cuisineType: String?)
    case toggleBookmark(recipeId: String)
    case listenToRecipe(recipeId: String, recipeName: String, artworkURL: String?, steps: [String])
}
```

### Task 2: Feed/RecipeDetail Auth Gating and UI Integration

**FeedReducer** (`FeedFeature/Sources/Feed/FeedReducer.swift`):
- Added `currentAuthState: AuthState` to state
- New `delegate(Delegate)` action for parent communication
- **Bookmark gating:** Swipe-right for guests emits `.delegate(.authGateRequested(...))` instead of saving
- **Skip ungated:** Swipe-left works for all users without auth check
- Card removed from stack BEFORE gate shown for responsive UI

**RecipeDetailReducer** (`FeedFeature/Sources/RecipeDetail/RecipeDetailReducer.swift`):
- Added `currentAuthState: AuthState` to state
- **Bookmark toggle gating:** `.toggleBookmark` checks auth, emits delegate for guests
- **Listen gating:** `.listenTapped` checks auth, emits delegate for guests
- Authenticated users proceed with existing bookmark/listen logic

**RootView** (`Sources/App/RootView.swift`):
- Added `.fullScreenCover` for auth gate presentation
- Swipe-down dismissal enabled (no `.interactiveDismissDisabled()`)
- `.onAppear` triggers `.observeAuth` action for auth state monitoring

**KindredApp** (`Sources/App/KindredApp.swift`):
- Flag renamed: `hasSeenWelcome` → `hasCompletedOnboarding`
- TODO comments added for onboarding integration when Plan 08-02 completes
- WelcomeCardView remains as temporary placeholder

**Package Dependency Updates:**
- Main Package.swift: Added AuthFeature dependency
- FeedFeature Package.swift: Added AuthClient dependency
- AuthFeature Package.swift: Added `path: "Sources"` to target

## Deviations from Plan

### Deviation 1: Onboarding Integration Deferred
**Type:** Rule 4 - Architectural/Dependency Issue
**Trigger:** Task 2 requires OnboardingView integration, but Plan 08-02 (onboarding carousel) hasn't been executed
**Impact:** Flag structure prepared (`hasCompletedOnboarding`), but actual OnboardingView replacement deferred

**What was done:**
- Updated flag name from `hasSeenWelcome` to `hasCompletedOnboarding`
- Added TODO comments for future onboarding integration
- Kept WelcomeCardView as temporary placeholder

**Next steps:** Complete Plan 08-02, then replace WelcomeCardView with OnboardingView

### Deviation 2: Build Configuration Blocker
**Type:** Rule 3 - Blocking Technical Issue
**Trigger:** Xcode build system cannot resolve AuthFeature module despite correct Package.swift configuration
**Impact:** Implementation complete but unverified - no compilation check, no tests run

**What was attempted (3 fix attempts):**
1. Updated Package.swift dependencies for main app and FeedFeature
2. Added explicit `path: "Sources"` to AuthFeature target
3. Clean build with package resolution
4. Attempted build with .swiftpm workspace

**Root cause hypothesis:**
Project uses mixed structure (Xcode .xcodeproj + SPM packages). AuthFeature may need explicit addition to Xcode project target dependencies, not just Package.swift.

**Error:**
```
error: Unable to find module dependency: 'AuthFeature'
```

**Recommendation for user:**
Open Kindred.xcodeproj in Xcode GUI and manually add AuthFeature as a framework dependency to the Kindred target in project settings.

## Implementation Details

### Auth Gate Flow

1. **Guest taps bookmark/listen** → RecipeDetailReducer or FeedReducer checks `currentAuthState`
2. **Guest detected** → Emit `.delegate(.authGateRequested(...))` to parent
3. **AppReducer receives delegate** → Check cooldown (5 min via UserDefaults)
4. **Cooldown inactive** → Store `pendingGatedAction`, present `authGate`
5. **User signs in** → SignInGateReducer emits `.signInSucceeded(user)`
6. **AppReducer handles success** → Update auth state, dismiss gate, execute pending action, start migration
7. **Migration** → Upload data to backend (placeholder), clean local storage, retry on failure (3x with backoff)

### Cooldown Mechanism

```swift
// Check
if let lastDismissedAt = UserDefaults.standard.object(forKey: "lastGateDismissedAt") as? Date {
    let fiveMinutesAgo = Date().addingTimeInterval(-5 * 60)
    if lastDismissedAt > fiveMinutesAgo {
        return .none // Suppress gate
    }
}

// Record
UserDefaults.standard.set(Date(), forKey: "lastGateDismissedAt")
```

### Migration Retry Logic

```swift
case .migrationFailed:
    state.migrationRetryCount += 1
    if state.migrationRetryCount <= 3 {
        let delay = pow(2.0, Double(state.migrationRetryCount)) // 2s, 4s, 8s
        return .run { send in
            try await clock.sleep(for: .seconds(delay))
            await send(.retryMigration)
        }
    }
```

## What Works (Theoretically)

Based on implementation (pending build fix):

- ✅ Guest bookmark swipe triggers full-screen auth gate
- ✅ Guest listen tap triggers auth gate
- ✅ Skip swipe works without auth gate
- ✅ Deferred action auto-executes after sign-in
- ✅ 5-minute cooldown persists across restarts
- ✅ Migration runs silently after sign-in
- ✅ Migration retries 3x with exponential backoff
- ✅ Auth state flows to child reducers
- ✅ No visual indicators on gated buttons (discovery-on-tap)

## What's Missing

1. **Build verification** - Module resolution issue prevents compilation
2. **Onboarding integration** - Waiting for Plan 08-02
3. **Backend migration endpoint** - GraphQL mutation placeholder logs data
4. **Tests** - Cannot run due to build blocker

## Verification Steps (When Build Fixed)

1. Build app successfully
2. As guest: swipe right on recipe card → auth gate appears
3. Dismiss gate → cooldown active for 5 minutes
4. As guest: tap Listen button → auth gate appears
5. Sign in via gate → action auto-completes, data migrates
6. Check UserDefaults: `guestMigrated` flag set to true
7. Verify local bookmarks/skips deleted after migration
8. Test migration retry: force network error, observe 3 retries with backoff

## Files Modified

### Created (1)
- `Kindred/Packages/AuthFeature/Sources/Migration/GuestMigrationClient.swift` (92 lines)

### Modified (8)
- `Kindred/Sources/App/AppReducer.swift` - Added 150+ lines for auth state, migration, delegate handling
- `Kindred/Packages/FeedFeature/Sources/Feed/FeedReducer.swift` - Added auth state, delegate actions, bookmark gating
- `Kindred/Packages/FeedFeature/Sources/RecipeDetail/RecipeDetailReducer.swift` - Added auth state, bookmark/listen gating
- `Kindred/Sources/App/RootView.swift` - Added auth gate fullScreenCover + onAppear
- `Kindred/Sources/App/KindredApp.swift` - Updated onboarding flag name
- `Kindred/Package.swift` - Added AuthFeature dependency
- `Kindred/Packages/FeedFeature/Package.swift` - Added AuthClient dependency
- `Kindred/Packages/AuthFeature/Package.swift` - Added path parameter to target

## Next Steps

### Immediate (User Action Required)
1. Fix AuthFeature module resolution in Xcode project
2. Verify build succeeds
3. Run manual verification tests

### Short-term (Complete Plan 08-02)
1. Execute Plan 08-02 (Onboarding carousel)
2. Replace WelcomeCardView with OnboardingView in KindredApp
3. Remove TODO comments

### Future (Backend)
1. Implement `MigrateGuestData` GraphQL mutation in NestJS backend
2. Replace placeholder logging with actual Apollo mutation call
3. Add error handling for backend migration failures

## Lessons Learned

1. **Mixed project structures are fragile** - SPM + .xcodeproj requires careful dependency management
2. **Plan dependencies matter** - Plan 08-03 references onboarding from unexecuted Plan 08-02
3. **Delegate pattern scales well** - Clean parent-child communication without tight coupling
4. **Responsive UI before async actions** - Removing card before showing gate feels instant
5. **Exponential backoff is essential** - Network errors shouldn't block migration forever

## Self-Check: FAILED

**Reason:** Build blocker prevents verification

### Expected files:
- ✅ GuestMigrationClient.swift exists at expected path
- ✅ AppReducer.swift modified with auth state
- ✅ FeedReducer.swift modified with gating logic
- ✅ RecipeDetailReducer.swift modified with gating logic
- ✅ RootView.swift modified with fullScreenCover
- ✅ Package.swift files updated with dependencies

### Expected commits:
- ❌ No commits made due to build failure (per execution protocol: don't commit broken code)

### Build status:
- ❌ Cannot compile due to module resolution issue
- ❌ Cannot run tests
- ❌ Cannot verify runtime behavior

**Recommendation:** User must resolve Xcode project configuration before proceeding with Phase 08.
