# Phase 21: Voice Playback & Monetization Integration - Context

**Gathered:** 2026-04-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire production voice narration from R2 CDN URLs, connect paywall to MonetizationFeature purchase flow, enable cross-module navigation from recipe suggestion carousel to recipe detail, add pantry ingredient badges to recipe detail, and commit SwiftData named ModelConfiguration separation. Replace all mock data and TODO markers with real backend integration.

</domain>

<decisions>
## Implementation Decisions

### Voice Playback Wiring
- Fetch narration audio **on-demand when user taps play** (not preloaded)
- When narration is unavailable for a recipe, show **"Narration not available" message** — no on-demand generation
- Voice profiles fetched via **GraphQL query on voice picker open** (not cached on launch)
- **Remove TestAudioGenerator entirely** — no debug flag, clean deletion
- Network/backend errors during fetch: **inline error with retry button** in player area
- Voice picker shows **only completed voice profiles** (no in-progress clones)
- Cache policy: **cache-first, no revalidation** — if cached audio exists, use it immediately
- **Auto-cache audio after first play** — downloaded audio saved to VoiceCache for offline/instant replay
- **Backend provides step timestamps** in narration response — app does not estimate from duration
- Free-tier users get **1 default "Kindred Voice"** (generic, no persona name) — Pro unlocks custom/cloned voices
- Keep **existing mini-player scope** — don't change visibility, just wire real audio

### Voice Playback Error States
- Mid-playback buffering: **spinner on play/pause button**, auto-resumes when buffer fills
- Stream failure mid-playback: **pause at current position + "Connection lost — Tap to retry"** inline
- Offline with no cache: **immediate "Narration requires internet connection" message** — no fetch attempt
- Cached narrations playable offline with **full step-sync** (timestamps stored in cache)
- No narration available: **show disabled/greyed play button** — tapping shows "unavailable" message
- **Pre-check narration availability on recipe detail load** — button state correct immediately
- Pre-check via **hasNarration boolean field added to RecipeDetail GraphQL query** — no extra request
- Cached audio for deleted voices **still plays** — no cache invalidation on voice deletion

### Paywall Purchase Flow (ScanPaywallView)
- Subscribe tap: **dismiss paywall, then show StoreKit purchase sheet**
- After successful purchase: **auto-unlock, return to scanning** — no celebration screen
- Purchase failure/cancel: **stay on paywall with error banner** — user can retry
- Wire **both subscribe AND restore** buttons to MonetizationFeature
- Scope: **ScanPaywallView only** — no other paywall entry points in this phase
- **Show real subscription price** from StoreKit on the button (e.g., "$4.99/month")
- **Loading spinner on subscribe button** until price loads from StoreKit
- If price can't load: **disable subscribe button with "Unable to load pricing" message**
- Restore flow: **full-screen loading overlay** with "Restoring purchases..." text
- No active subscription found after restore: **"No active subscription found. Subscribe to unlock Pro features."** — stay on paywall

### Cross-Module Navigation
- Carousel recipe tap: **delegate action (.openRecipe(id)) up to AppReducer** — PantryReducer emits, AppReducer handles
- Navigation: **switch to Feed tab + push recipe detail** onto Feed navigation stack
- **Dismiss carousel on recipe tap** — clean transition
- Error fetching recipe: **show error on recipe detail screen** with retry — navigate there regardless
- **Pass pantry match data** when navigating — recipe detail shows which ingredients user has
- Ingredient badges: **checkmark icon + green tint** on matching ingredients in recipe detail
- Badge source: **full pantry inventory** (all user's pantry items, not just current scan)
- Badges show **always** — from feed browsing AND from scan navigation
- All pantry items treated **equally regardless of expiry** status
- Ingredient matching: **fuzzy/partial matching** ("chicken" matches "chicken breast")

### Pantry-to-Recipe Data Flow
- FeedFeature accesses pantry data via **shared PantryClient dependency** (direct cross-package dependency)
- Matching computed **on recipe detail load** (not pre-computed for all feed recipes)
- Pantry data **cached in memory for session** — not fetched fresh each time
- Cache **refreshes on pantry tab visit** — adding items in pantry updates badges on next recipe view

### GraphQL Schema Alignment
- iOS VoiceProfile model maps **1:1 to backend GraphQL type** — mirror schema directly
- narrationUrl: **separate dedicated query** (narrationUrl(recipeId, voiceId)) — already built in Phase 19-04
- voiceProfiles: **standalone query** — new, not part of user profile query
- Voice profiles query returns: **id, name, avatarURL, sampleAudioURL, isOwnVoice, createdAt**
- Backend status: narrationUrl query exists (Phase 19-04), **voiceProfiles query needs work** on backend

### Monetization State Sync
- After purchase: **immediate local unlock** via StoreKit entitlement — no backend round-trip
- Voice tier gating: **local StoreKit check** via SubscriptionClient.currentEntitlement()
- Subscription expiry: **lock on next app launch** — don't interrupt current session
- Default "Kindred Voice": **works for guest users** without sign-in
- Guest taps Pro voice: **show auth gate first**, then subscription paywall after sign-in
- Pro voices **visible to free/guest users with lock icon** — tapping shows upgrade path

### SwiftData Commit Scope
- Only **PantryStore + GuestStore** need named ModelConfigurations — no other models
- **Needs verification first** before commit — test that data separation works correctly
- **Fresh installs only** — no migration needed (pre-App Store)

### Claude's Discretion
- Exact error message copy/localization
- VoiceCache storage format for step timestamps
- Fuzzy matching algorithm for ingredient names (contains, Levenshtein, etc.)
- Apollo codegen setup for new GraphQL queries
- Exact green tint color value for pantry badges

</decisions>

<specifics>
## Specific Ideas

- Default voice is named "Kindred Voice" — generic branding, no character persona
- Narration availability pre-checked as hasNarration boolean on RecipeDetail query — disabled play button state known immediately
- Pantry badges use the same visual language everywhere (feed-originating and scan-originating recipe details)
- ScanPaywallView shows actual price with loading state, not a generic "Subscribe" label

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `VoicePlaybackReducer` (VoicePlaybackFeature): Has full player UI/state machine, 5 TODO markers to replace with real GraphQL calls
- `AudioPlayerManager` (VoicePlaybackFeature): AVPlayer wrapper, TestAudioGenerator to remove
- `VoiceCache`: Existing cache client for audio files — extend to store step timestamps
- `ScanPaywallView` (PantryFeature): Complete UI with onSubscribe/onRestore closures, just needs wiring
- `RecipeSuggestionCarousel` (PantryFeature): Complete UI with onRecipeTapped closure, needs navigation wiring
- `SubscriptionClient`: Already used for entitlement checks across the app
- `PantryClient` / `PantryStore`: Full CRUD for pantry items with SwiftData, available as shared dependency
- `RecipeDetailQuery` (KindredAPI): Existing GraphQL query — needs hasNarration field addition
- `AppReducer`: Handles cross-feature coordination — already manages feed↔voice playback delegation

### Established Patterns
- TCA delegate actions for cross-feature communication (PantryReducer → AppReducer → FeedFeature)
- Apollo GraphQL for all backend queries with generated types
- SubscriptionClient.currentEntitlement() for local tier checks
- ModelConfiguration named stores for SwiftData separation (PantryStore, GuestStore)

### Integration Points
- `AppReducer` handles PantryReducer delegate actions → switch tab + push recipe detail
- `VoicePlaybackReducer` `.selectVoice` and `.narrationReady` actions — replace mock data with GraphQL
- `PantryReducer` scanPaywall presentation — wire onSubscribe/onRestore to MonetizationFeature actions
- `RecipeDetailReducer` — add pantry ingredient matching on load
- Backend: narrationUrl query (Phase 19-04), voiceProfiles query (needs work)

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 21-voice-playback-monetization-integration*
*Context gathered: 2026-04-03*
