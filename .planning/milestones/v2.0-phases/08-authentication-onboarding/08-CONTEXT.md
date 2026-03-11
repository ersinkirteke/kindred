# Phase 8: Authentication & Onboarding - Context

**Gathered:** 2026-03-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Users complete onboarding in under 90 seconds and seamlessly convert from guest to account. Implements Google OAuth and Apple Sign In via Clerk SDK (already integrated). Guest users are gated from bookmarking and voice features until signed in. Guest session data (bookmarks, skips, dietary preferences) migrates silently to the authenticated account on conversion.

</domain>

<decisions>
## Implementation Decisions

### Sign-in Presentation
- Full-screen gate view (not sheet, not inline)
- Apple Sign In + Google OAuth buttons stacked vertically (Apple on top, Google below)
- App branding + tagline above buttons (e.g., "Save recipes, hear them narrated, make them yours")
- "Continue as guest" skip link always visible below buttons
- Swipe-down gesture + skip button both dismiss the gate
- After successful sign-in: instant transition back to where user was (no celebration/animation)
- Sign-in errors: inline red text below buttons with retry message
- Generic sign-in message — no contextual hint about what triggered the gate

### Guest Conversion Triggers
- Gated actions: bookmarking a recipe + all voice features (listen + upload)
- Non-gated actions: browsing feed, viewing recipe details, skipping recipes, setting session dietary prefs
- Gating behavior: block the action entirely until signed in (no local save for gated actions)
- After sign-in via gate: auto-complete the original action (e.g., bookmark saves automatically)
- Cooldown: 5 minutes after dismissing the gate before showing it again
- No visual indicators on gated buttons (no lock icons) — user discovers gate on tap
- Same generic sign-in screen regardless of which action triggered it

### Onboarding Sequence
- Triggers on first app launch (replaces current WelcomeCardView)
- Horizontal paging carousel with dots indicator
- Step order: Sign-in → Dietary preferences → Location → Voice teaser → Start
- All steps are skippable (including sign-in — "Continue as guest")
- Dietary preferences: chip/tag grid (multi-select) — Vegetarian, Vegan, Gluten-free, Keto, Halal, etc.
- Location: iOS "When In Use" location permission request. If denied, offer manual city entry fallback
- Voice step: teaser card explaining voice narration feature + "Set up later" / "Try it now" CTA (not the full upload flow)

### Data Migration
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

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ClerkAuthClient` (AuthClient package): Already wraps Clerk SDK with `getToken()`, `isAuthenticated`, `currentUser`. Needs UI layer added on top
- `AuthState` enum: `.guest`, `.authenticated(ClerkUser)`, `.loading` — ready for state-driven view switching
- `AuthInterceptor`: Already injects JWT Bearer tokens into GraphQL requests. Guest = no header (backend allows unauthenticated)
- `GuestSessionClient`: Full SwiftData-based guest session with bookmarks, skips, guest UUID
- `GuestBookmark` / `GuestSkip` SwiftData models: Have all fields needed for backend migration
- `CardSurface`: Reusable card component for onboarding carousel cards
- `KindredButton`: Primary/secondary button styles for sign-in buttons
- `EmptyStateView` / `ErrorStateView`: For error states in sign-in flow
- `SplashView`: Animated splash screen — onboarding would follow this
- `WelcomeCardView`: Current first-launch overlay — will be replaced by onboarding carousel
- `HapticFeedback`: For tactile feedback on sign-in success / step transitions

### Established Patterns
- TCA (ComposableArchitecture): All features use Reducer + Store pattern. Auth/Onboarding should follow same architecture
- Dependencies system: `@Dependency` for clients — AuthClient already registered as dependency
- SwiftData + ModelContainer: Used for guest session. App-level container in KindredApp
- `@AppStorage("hasSeenWelcome")`: Current first-launch flag — can be extended for onboarding completion tracking

### Integration Points
- `KindredApp.swift`: Entry point. Currently shows Splash → RootView → WelcomeCard. Onboarding replaces WelcomeCard flow
- `AppReducer.swift`: Root reducer. Needs auth state and onboarding state added
- `RootView.swift`: Tab-based layout. Auth gate needs to intercept before tab actions
- `FeedReducer` / `RecipeDetailReducer`: Bookmark and voice actions originate here — need auth gate check before executing
- `VoicePlaybackReducer`: Voice playback actions originate here — need auth gate check
- `NetworkClient/ApolloClientFactory`: Token provider already connected via AuthInterceptor

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 08-authentication-onboarding*
*Context gathered: 2026-03-03*
