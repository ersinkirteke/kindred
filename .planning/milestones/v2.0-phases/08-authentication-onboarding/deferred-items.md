# Deferred Items - Phase 08

## Plan 08-03: Auth Gate Integration

### Build Configuration Issue - AuthFeature Module Not Found

**Status:** BLOCKING - Requires user intervention

**Issue:**
Xcode build system cannot resolve the AuthFeature module, despite:
- Package.swift correctly configured with AuthFeature dependency
- Source files existing in correct locations (`Packages/AuthFeature/Sources/`)
- All dependencies properly declared

**Error:**
```
error: Unable to find module dependency: 'AuthFeature'
```

**Root Cause:**
Likely an Xcode project configuration issue where the .xcodeproj file isn't properly linked to the local SPM package. The project uses a mixed structure (Xcode project + SPM packages), and AuthFeature may need to be explicitly added to the Xcode project's target dependencies.

**Attempted Fixes:**
1. Added AuthFeature to main Package.swift dependencies ✓
2. Added `path: "Sources"` to AuthFeature Package.swift target ✓
3. Clean build with package resolution ✓
4. Attempted build with .swiftpm workspace (in progress)

**Recommendation:**
User should open Kindred.xcodeproj in Xcode and manually add AuthFeature as a framework dependency to the Kindred target, or verify that the local package is properly linked in the project navigator.

### Onboarding Integration Incomplete

**Status:** DEFERRED - Depends on Plan 08-02

**Issue:**
Task 2 requires integrating OnboardingView into KindredApp, but Plan 08-02 (Onboarding carousel) hasn't been executed yet.

**Current State:**
- Flag name updated from `hasSeenWelcome` to `hasCompletedOnboarding`
- WelcomeCardView still in use as temporary placeholder
- TODO comments added for future onboarding integration

**Next Steps:**
Execute Plan 08-02 first, then complete onboarding integration in this plan.

### Files Modified But Not Verified

Due to the build blocker, the following files were modified but couldn't be verified through compilation:

1. `Kindred/Packages/AuthFeature/Sources/Migration/GuestMigrationClient.swift` (created)
2. `Kindred/Sources/App/AppReducer.swift` (major modifications)
3. `Kindred/Packages/FeedFeature/Sources/Feed/FeedReducer.swift` (auth gating added)
4. `Kindred/Packages/FeedFeature/Sources/RecipeDetail/RecipeDetailReducer.swift` (auth gating added)
5. `Kindred/Sources/App/RootView.swift` (auth gate fullScreenCover added)
6. `Kindred/Sources/App/KindredApp.swift` (flag update)
7. Various Package.swift files (dependency additions)

All files follow the plan specifications and should compile once the module resolution issue is fixed.
