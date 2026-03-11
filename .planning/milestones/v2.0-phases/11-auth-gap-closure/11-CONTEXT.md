# Phase 11: Auth Gap Closure - Context

**Gathered:** 2026-03-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire OnboardingReducer as `@Presents` in AppReducer so onboarding carousel triggers for new users after their first sign-in. Verify that guest session state (bookmarks, skips, dietary preferences, city) persists through account conversion with no data loss. This phase closes gaps from the v2.0 milestone audit.

</domain>

<decisions>
## Implementation Decisions

### Onboarding Trigger
- Onboarding carousel appears **only after first sign-in**, not on first launch
- Any sign-in path triggers it (auth gate popup OR profile tab sign-in)
- Sign-in step is removed from the carousel — user already authenticated
- Carousel is 3 steps: Dietary Prefs → Location → Voice Teaser (update totalSteps to 3)
- Step indicator shows 3 dots

### Onboarding Presentation
- Use `.fullScreenCover` with `@Presents` in AppReducer (same pattern as auth gate)
- Dismissable with reminder: user can swipe down/tap X, carousel reappears on next launch until completed
- Resume from last completed step (persist current step to UserDefaults)
- Feed updates only after onboarding completes, not per-step
- Pre-fill dietary prefs and city from guest data if user set them before sign-in

### Onboarding Step Content
- First step shows personalized greeting: "Welcome, [firstName]! Let's personalize your feed"
- Use firstName from Clerk user profile
- Fallback to generic "Welcome! Let's personalize your feed" if name unavailable (Apple Sign In can hide name)
- All steps remain skippable (per AUTH-06 90-second requirement)
- Voice teaser "Try Voice Now" completes onboarding, then opens voice upload sheet separately

### Auth State Transitions
- Single trigger point: `authStateChanged` in AppReducer — when `.authenticated` AND `hasCompletedOnboarding` is false → present onboarding
- Auth gate dismisses first, brief moment of main app visible, then onboarding fullScreenCover presents
- Profile tab sign-in follows the same flow
- `hasCompletedOnboarding` moves to TCA state in AppReducer, persisted to UserDefaults via effect
- OnboardingReducer sends `.delegate(.completed(prefs, city))` action — AppReducer forwards to feed

### Migration Scope
- ALL guest data migrates: bookmarks (SwiftData), skips (SwiftData), dietary preferences (UserDefaults), city (UserDefaults)
- Local data stays intact during conversion + sent to backend via GraphQL mutation (belt and suspenders)
- On backend failure: keep local, retry later — no data loss risk
- After confirmed backend sync: clean up local SwiftData guest records — Apollo cache takes over for bookmarks
- After migration, bookmarks sourced from Apollo cache (server-synced), not SwiftData

### Migration Backend
- Backend `migrateGuestData` mutation already exists in schema
- Takes: guestUserId, bookmarks array, skips array, dietaryPreferences array, city string
- Single atomic call — all data in one mutation, all-or-nothing
- Idempotent — backend uses guestUserId as dedup key, safe to retry
- Response returns counts (migratedBookmarks, migratedSkips, etc.)
- Verify returned counts match local counts before cleaning up SwiftData
- Claude should check codebase for existing .graphql operations directory and follow same pattern for codegen

### Post-Conversion UX
- Silent background migration — no loading indicator, user goes straight to onboarding carousel
- No confirmation message after conversion — data just appears where expected
- Silent failure if migration fails after all retries — local data stays, retry on next launch
- After successful migration, populate Apollo cache from response so bookmarks appear immediately in profile

### Offline Edge Cases
- If migration fails due to network: retry automatically when connectivity returns (use existing `connectivityChanged` action)
- Onboarding presents independently of migration — doesn't wait for migration to complete
- If onboarding prefs conflict with migrating guest prefs: onboarding prefs win (most recent intent)
- `pendingMigration` flag persists in UserDefaults across app restarts — retry on next launch if needed

### Testing
- Manual QA: browse as guest, bookmark recipes, sign in, verify bookmarks appear in profile
- TCA unit tests for migration reducer logic with mock GuestMigrationClient
- Edge case tests: empty guest data, partial data (bookmarks but no prefs), offline during migration, duplicate migration calls

### Claude's Discretion
- Exact animation timing for auth gate dismiss → onboarding present transition
- UserDefaults key names for onboarding step persistence
- Retry timing/backoff strategy for connectivity-based migration retry
- Apollo cache population strategy from migration response
- GraphQL operation file placement (Claude to check existing pattern)

</decisions>

<specifics>
## Specific Ideas

- Auth gate → onboarding transition should feel smooth, not jarring — brief pause is OK
- "Welcome, [name]!" personalization makes the post-sign-in experience feel intentional, not like a second hurdle
- Migration must be bulletproof — user should never lose their bookmarks during conversion

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `SignInGateReducer` + `.fullScreenCover`: Already uses `@Presents` pattern in AppReducer — onboarding should follow the same pattern
- `GuestMigrationClient`: Exists with `migrateGuestData()` and `hasPendingMigration()` — needs real GraphQL call instead of TODO placeholder
- `GuestSessionClient`: Full SwiftData CRUD for bookmarks/skips — source of migration data
- `OnboardingReducer`: Complete reducer with all steps — needs sign-in step removal and `@Presents` wiring
- `OnboardingView` + step views: UI exists and works — minimal changes needed

### Established Patterns
- `@Presents` + `.ifLet` + `.fullScreenCover`: Used for auth gate (AppReducer line 27, 382)
- Auth state observation: `observeAuth` → `authStateChanged` in AppReducer — reliable trigger point
- Migration with retry: `startMigration` → `migrationFailed` → exponential backoff retry (up to 3) already implemented
- Connectivity monitoring: `startConnectivityMonitor` → `connectivityChanged` already in AppReducer
- Dietary prefs saved to UserDefaults key "dietaryPreferences" (shared between onboarding and feed)
- City saved to UserDefaults key "selectedCity"

### Integration Points
- `KindredApp.swift`: Remove standalone onboarding store and ZStack overlay
- `AppReducer.swift`: Add `@Presents var onboarding: OnboardingReducer.State?`, trigger from `authStateChanged`
- `RootView.swift`: Add `.fullScreenCover` for onboarding (alongside existing auth gate cover)
- `OnboardingReducer.swift`: Remove sign-in step, add delegate action, update totalSteps to 3
- `GuestMigrationClient.swift`: Replace TODO with real Apollo GraphQL mutation call
- Apollo codegen: Add `MigrateGuestData.graphql` operation file

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 11-auth-gap-closure*
*Context gathered: 2026-03-08*
