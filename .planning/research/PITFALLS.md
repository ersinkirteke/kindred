# Pitfalls Research

**Domain:** iOS App (SwiftUI + TCA) consuming existing NestJS GraphQL backend
**Researched:** 2026-03-01
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: TCA Over-Engineering for Simple Screens

**What goes wrong:**
Using The Composable Architecture for every screen in the app, including simple read-only views with minimal state. This creates unnecessary complexity, verbose boilerplate, and performance overhead from ViewStore wrapping and state observation.

**Why it happens:**
Developers adopt TCA enthusiastically after learning its benefits and apply it uniformly across the entire codebase without evaluating screen-by-screen complexity. The desire for architectural consistency overrides pragmatic engineering decisions.

**How to avoid:**
- Use vanilla SwiftUI with `@State`, `@Binding`, or `ObservableObject` for simple screens (recipe detail view, static content)
- Reserve TCA for screens with complex state, cross-screen dependencies, or significant side effects (feed with filtering, voice playback coordination, bookmark syncing)
- Apply TCA when you need serious testing coverage or state spans multiple screens
- Start with vanilla SwiftUI and migrate to TCA when complexity justifies it, rather than TCA-first

**Warning signs:**
- Reducers with only 2-3 actions that just set boolean flags
- ViewStore observation of entire state when only 1-2 properties are needed
- More time writing TCA boilerplate than actual feature logic
- Test files longer than implementation files for trivial features

**Phase to address:**
Phase 1 (Architecture Setup) — Establish clear guidelines for when to use TCA vs vanilla SwiftUI. Document decision criteria.

---

### Pitfall 2: ViewStore Over-Observation Causing Performance Degradation

**What goes wrong:**
Every view observes the entire application state through ViewStore, causing unnecessary view re-evaluation and redrawing whenever any state changes anywhere in the app. Long navigation stacks redraw all previous views on state changes in the leaf view. Performance degrades severely as the app grows.

**Why it happens:**
TCA's architecture passes entire state down the view hierarchy by design, which conflicts with SwiftUI's preference for minimal state observation. Developers use `WithViewStore(store) { viewStore in }` without scoping to specific state slices.

**How to avoid:**
- Always scope ViewStore to minimal required state: `WithViewStore(store, observe: \.recipeList)` instead of observing entire state
- Use `Store.scope()` to create child stores with limited state visibility
- Leverage Swift 5.9+ Observation framework for fine-grained state tracking (reduces TCA performance overhead)
- Profile with Instruments to identify unnecessary view updates
- Consider TCA 1.0+ which uses `@ObservableState` macro for better performance

**Warning signs:**
- Frame drops when typing in text fields or scrolling lists
- Instruments shows views redrawing when their displayed data hasn't changed
- Navigation animations stuttering
- CPU spikes on state mutations unrelated to visible views

**Phase to address:**
Phase 1 (Architecture Setup) and ongoing code review. Include ViewStore scoping in architectural guidelines and PR checklist.

---

### Pitfall 3: Apollo iOS Cache Orphaned Objects Causing Memory Bloat

**What goes wrong:**
Apollo's normalized cache accumulates unreachable objects (orphaned records) when re-querying data with new identifiers. Cache doubles in size over time, causing memory pressure and eventual crashes. Common when recipe IDs change or feed pagination creates duplicate cached objects.

**Why it happens:**
Apollo iOS `InMemoryNormalizedCache` does not implement auto-eviction policies. When queries fetch data with new IDs (e.g., viral recipes with updated engagement metrics), old cached objects remain in memory even though they're no longer reachable from root queries.

**How to avoid:**
- Call `apollo.clearCache()` or `store.gc()` (garbage collection) periodically to remove unreachable objects
- Implement cache eviction on low memory warnings using `NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification)`
- Use SQLite-backed cache (`SQLiteNormalizedCache`) instead of in-memory cache for large datasets — writes to disk, avoids memory pressure
- Set cache expiration policies with TTL for recipe data
- Monitor cache size in analytics/logs to detect unbounded growth

**Warning signs:**
- App memory usage grows continuously during normal use
- Memory warnings in Xcode console during testing
- App crashes with `jetsam` reports showing memory limit exceeded
- Cache size grows even when user isn't actively browsing

**Phase to address:**
Phase 2 (GraphQL Integration) — Implement cache management strategy before feed implementation. Add memory monitoring in Phase 4.

---

### Pitfall 4: Apollo Cache vs Server State Consistency Conflicts

**What goes wrong:**
Apollo's cache-first fetch policy returns stale data while server has fresher data (new viral badges, updated engagement counts, recipe edits). User sees outdated recipe information, causing confusion. Alternatively, network-first policies negate caching benefits and waste bandwidth.

**Why it happens:**
Default `cache-first` policy optimizes for performance but can serve stale data. GraphQL queries don't automatically invalidate cache when mutations occur. Multi-field updates (recipe + engagement + viral status) don't atomically update cache.

**How to avoid:**
- Use `cache-and-network` policy for feed queries — shows cached data immediately, updates with fresh data
- Implement cache updates in mutation responses: `update` function manually updates cache after bookmark/skip mutations
- Use GraphQL subscriptions for real-time updates on viral status changes (if backend supports)
- Invalidate specific cache entries on mutations: `evict()` specific recipe objects on updates
- Set `fetchPolicy: .networkOnly` for critical user actions (voice profile creation, subscription purchase)
- Tag cache entries with timestamps and implement client-side TTL checks

**Warning signs:**
- Users report seeing outdated recipe data after backgrounding/resuming app
- Viral badges don't appear until force-refresh
- Bookmarked recipes show as unbookmarked in feed
- GraphQL mutations succeed but UI doesn't reflect changes

**Phase to address:**
Phase 2 (GraphQL Integration) — Define fetch policies per query type. Phase 3 (Feed Implementation) — Implement cache update patterns for mutations.

---

### Pitfall 5: Background Audio Interruptions Not Handled Properly

**What goes wrong:**
Voice narration stops when phone call comes in, alarm fires, or user switches to another audio app. Audio doesn't resume after interruption ends. User loses playback position. Worse, audio continues playing when it shouldn't (e.g., during phone call).

**Why it happens:**
Developers don't configure `AVAudioSession` category/mode correctly or fail to observe `AVAudioSessionInterruptionNotification`. Background audio requires specific entitlements and category settings (`AVAudioSessionCategoryPlayback` with proper interruption handling).

**How to avoid:**
- Set audio session category to `.playback` with `.mixWithOthers` option if appropriate: `AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers])`
- Use `.spokenAudio` mode for voice narration (pauses for other spoken audio instead of ducking)
- Observe `AVAudioSessionInterruptionNotification` and handle `.began` / `.ended` interruption types
- Save playback position before interruption, restore after interruption ends
- Enable background audio capability in Xcode project settings
- Test with: incoming calls, alarms, Siri, control center audio switching, headphone disconnect

**Warning signs:**
- Audio stops permanently when alarm fires
- Playback doesn't pause during phone calls
- Users complain audio "disappears" randomly
- Audio plays from two apps simultaneously (no proper interruption handling)

**Phase to address:**
Phase 4 (Voice Playback) — Core requirement for audio feature. Include comprehensive interruption testing in QA plan.

---

### Pitfall 6: AVAudioPlayer vs AVPlayer Incorrect Choice for Streaming

**What goes wrong:**
Using `AVAudioPlayer` for streaming audio from ElevenLabs API, which only supports file-based or in-memory data playback. This forces downloading entire audio file before playback starts, creating 2-5 second delays and poor UX. Wastes bandwidth downloading full file for 30-second playback.

**Why it happens:**
`AVAudioPlayer` is simpler API and appears in more tutorials, but doesn't support progressive streaming. Developers don't realize `AVPlayer` is required for HTTP streaming until implementation.

**How to avoid:**
- Use `AVPlayer` with `AVPlayerItem(url: streamingURL)` for all streaming audio from ElevenLabs API
- Only use `AVAudioPlayer` for locally cached audio files (offline mode)
- Implement proper buffering indicators using `AVPlayerItem.status` and `loadedTimeRanges`
- Handle network failures gracefully with retry logic
- Test on 3G/LTE to ensure acceptable streaming performance

**Warning signs:**
- Long delay before audio starts playing (> 2 seconds)
- Audio downloads entire file before any playback begins
- Memory usage spikes when playing long narrations
- No ability to seek during streaming

**Phase to address:**
Phase 4 (Voice Playback) — Architecture decision during technical design. Specify AVPlayer in implementation plan.

---

### Pitfall 7: StoreKit 2 Receipt-Based Validation Instead of JWS Verification

**What goes wrong:**
Implementing StoreKit 2 but continuing to use legacy receipt validation (`verifyReceipt` endpoint). Receipts don't update immediately on-device after StoreKit 2 purchases, causing validation failures. Delays in subscription status updates. Using deprecated API that Apple will eventually remove.

**Why it happens:**
Developers migrate to StoreKit 2 client-side but keep existing server-side receipt validation logic. Documentation confusion between StoreKit 1 (receipt-based) and StoreKit 2 (JWS transaction-based) validation approaches.

**How to avoid:**
- Use App Store Server API with transaction ID validation instead of receipt validation
- Verify JWS (JSON Web Signature) transaction data cryptographically on your server without calling Apple's servers
- Backend should call `/inApps/v1/history/{originalTransactionId}` for subscription status
- Use `Transaction.currentEntitlements` on client to verify active subscriptions
- Implement server-side JWS verification using x509 certificate chain validation
- Never use `/verifyReceipt` endpoint with StoreKit 2

**Warning signs:**
- Successful purchases don't immediately unlock Pro features
- Server returns "receipt not found" errors after purchase
- Need to restart app for subscription to activate
- Backend still calling `/verifyReceipt` endpoint

**Phase to address:**
Phase 5 (Monetization) — Backend and iOS client both need JWS-based validation. Coordinate implementation across both platforms.

---

### Pitfall 8: StoreKit 2 Subscription State Not Monitoring Transaction.updates

**What goes wrong:**
App doesn't detect subscription renewals, expirations, or billing issues until user manually refreshes. User loses access to Pro features after renewal succeeds. Billing grace periods not communicated to user. Refunds not reflected in app state.

**Why it happens:**
Developers only check subscription status at app launch but don't monitor `Transaction.updates` async sequence for ongoing changes. Subscription changes (renewal, expiration, billing retry) occur in background while app is running.

**How to avoid:**
- Monitor `Transaction.updates` async sequence throughout app lifecycle
- Create dedicated subscription manager that listens to transaction updates:
```swift
Task {
    for await verificationResult in Transaction.updates {
        // Handle subscription changes
    }
}
```
- Check `Transaction.currentEntitlements` on app launch and state restoration
- Implement billing grace period UI to notify users of payment issues
- Handle `.revoked` transaction state (refunds)
- Test with sandbox accounts: renewal, expiration, billing retry, refund scenarios

**Warning signs:**
- Users report Pro features randomly locking after subscription renewal
- No notification when subscription expires
- Billing issues not surfaced to user
- Subscription status only updates on app restart

**Phase to address:**
Phase 5 (Monetization) — Critical for subscription management. Include Transaction.updates monitoring in StoreKit implementation.

---

### Pitfall 9: VoiceOver Accessibility Labels Missing or Generic

**What goes wrong:**
Custom UI controls (recipe cards, play/pause button, swipe gestures) have no accessibility labels or use generic labels like "Button". VoiceOver users can't understand what controls do. Swipe gestures have no accessible alternatives. Recipe cards read "Card, Card, Card" instead of recipe details.

**Why it happens:**
SwiftUI provides automatic accessibility for standard controls but custom views require explicit accessibility configuration. Developers test with eyes, not with VoiceOver, so accessibility gaps go unnoticed.

**How to avoid:**
- Set explicit `.accessibilityLabel()` on all custom controls: `.accessibilityLabel("Bookmark \(recipe.name)")`
- Use `.accessibilityHint()` for non-obvious interactions: `.accessibilityHint("Double tap to save recipe to your bookmarks")`
- Set `.accessibilityTrait(.button)` on tappable custom views
- Provide button alternatives for all swipe gestures (Listen/Watch/Skip buttons for swipe left/right)
- For complex custom controls, use `.accessibilityElement(children: .combine)` to group related elements
- Test every screen with VoiceOver enabled (Cmd+F5 in Simulator)
- Use Accessibility Inspector in Xcode to audit labels and hints

**Warning signs:**
- VoiceOver reads "Button, Button, Button" without descriptive labels
- Swipe-only interactions have no keyboard/VoiceOver alternative
- Recipe cards announce entire view tree instead of concise description
- Users complain about "impossible to navigate with VoiceOver"

**Phase to address:**
Phase 6 (Accessibility — WCAG AAA) — Comprehensive accessibility audit. Include VoiceOver testing in every PR review.

---

### Pitfall 10: Dynamic Type Support Breaks Layout with Fixed Sizes

**What goes wrong:**
UI breaks at larger accessibility text sizes (Dynamic Type). Text truncates, overlaps, or disappears. Fixed-height buttons don't accommodate larger text. Hardcoded spacing causes layout overlaps. Violates WCAG AAA requirement for text scaling.

**Why it happens:**
Developers use `.frame(height: 44)` with fixed sizes instead of letting SwiftUI calculate height based on content. Testing only at default text size, not at accessibility sizes (AX1-AX5).

**How to avoid:**
- Use `.font(.body)`, `.font(.headline)` instead of `.font(.system(size: 16))` — these scale with Dynamic Type
- Avoid fixed heights for text containers: use `.fixedSize(horizontal: false, vertical: true)` to allow vertical growth
- Use `.minimumScaleFactor()` only as last resort, prefer wrapping text to multiple lines
- Set `.lineLimit(nil)` to allow unlimited line wrapping for dynamic text
- Test at all Dynamic Type sizes in Simulator: Settings → Accessibility → Larger Text → AX1 through AX5
- Use Xcode Environment Overrides to preview all text sizes during development
- For buttons, use `.dynamicTypeSize()` modifier to cap maximum size if necessary

**Warning signs:**
- Text truncates with "..." at larger text sizes
- Buttons show only partial text at accessibility sizes
- UI elements overlap when text size increases
- Complaints from elderly users about "unreadable text"

**Phase to address:**
Phase 6 (Accessibility — WCAG AAA) — Critical for elderly users. Test all screens at AX3+ sizes before release.

---

### Pitfall 11: Touch Target Sizes Below 56dp Minimum (WCAG AAA)

**What goes wrong:**
Interactive elements (bookmark icon, skip button, filter chips) are smaller than 56dp minimum touch target. Users with motor impairments struggle to tap accurately. Violates WCAG AAA 2.5.5 requirement (44x44 minimum AA, 56x56 for AAA).

**Why it happens:**
Design prioritizes aesthetics over accessibility, creating small, elegant icons. Developers implement designs exactly without questioning touch target sizes. No accessibility testing with target size verification.

**How to avoid:**
- Set `.frame(minWidth: 56, minHeight: 56)` on all interactive elements
- Use `.contentShape(Rectangle())` to expand touch area beyond visible element
- For small icons, wrap in larger invisible touch target:
```swift
Image(systemName: "bookmark")
    .font(.system(size: 20))
    .frame(width: 56, height: 56) // Invisible touch area
    .contentShape(Rectangle())
```
- Test with Accessibility Inspector to verify touch target dimensions
- Add 8-12pt padding around visible icons to expand touch area
- Use color overlays in debug builds to visualize touch targets

**Warning signs:**
- Users report difficulty tapping small buttons
- Analytics show low tap-to-action conversion on small controls
- Accessibility audit fails on touch target size
- Frequent mis-taps on adjacent controls

**Phase to address:**
Phase 6 (Accessibility — WCAG AAA) — Include touch target audit in accessibility testing. Verify with Accessibility Inspector.

---

### Pitfall 12: Color Contrast Below 7:1 Ratio (WCAG AAA)

**What goes wrong:**
Text on terracotta accent (#E07849) fails WCAG AAA contrast requirement (7:1 for normal text, 4.5:1 for large text). Low vision users can't read text. Sunlight readability suffers. App Store accessibility review rejection risk.

**Why it happens:**
Design system prioritizes brand aesthetics (warm cream/terracotta palette) without validating contrast ratios. Developers trust design handoff without contrast verification.

**How to avoid:**
- Use contrast checker tools (WebAIM, Color Contrast Analyzer) to validate all text/background combinations
- WCAG AAA requires 7:1 for normal text (< 18pt), 4.5:1 for large text (≥ 18pt)
- For #E07849 terracotta on #FFF9F0 cream: verify contrast meets requirements, darken if needed
- Create dark mode variants with verified contrast ratios
- Use SwiftUI `.accessibilityBackground()` to provide semantic color that adapts to user preferences
- Test with Increase Contrast mode enabled in Accessibility settings
- Document contrast ratios in design system for reference

**Warning signs:**
- Text difficult to read in bright sunlight
- Users complain about "washed out" or "hard to see" text
- Accessibility audit tools flag contrast violations
- Negative app reviews mentioning readability

**Phase to address:**
Phase 6 (Accessibility — WCAG AAA) — Audit and fix before launch. Include contrast validation in design system.

---

### Pitfall 13: Offline Sync Conflicts with Last-Write-Wins Overwriting User Edits

**What goes wrong:**
User bookmarks recipe offline on Device A, unbookmarks same recipe on Device B (still offline). Both sync to backend when online — last-write-wins strategy discards one user action silently. User loses bookmark or sees unexpected state. Applies to dietary preferences, voice profiles, culinary DNA.

**Why it happens:**
Implementing naive last-write-wins conflict resolution without timestamp comparison or operational transformation. No conflict detection or user notification when conflicts occur.

**How to avoid:**
- Use operation-based sync instead of state-based: log "bookmark added" and "bookmark removed" operations with timestamps
- Implement vector clocks or Lamport timestamps to detect concurrent edits
- For conflicts, prefer additive operations (keep bookmark if conflict) over destructive ones
- Surface conflicts to user when detected: "You bookmarked this on another device, keep bookmark?"
- Use GraphQL mutations with optimistic UI updates and rollback on conflict
- Consider CRDT (Conflict-free Replicated Data Types) for complex offline state (overkill for MVP)
- Test: two devices offline, make conflicting changes, bring both online simultaneously

**Warning signs:**
- Users report lost bookmarks after syncing devices
- Dietary preferences reset unexpectedly
- Analytics show unusual spike in unbookmark actions (actually conflict overwrites)
- No conflict detection in logs despite multi-device usage

**Phase to address:**
Phase 7 (Offline Support) — Critical for multi-device sync. Implement operation-based sync and conflict detection.

---

### Pitfall 14: Cache Invalidation Strategy Missing for Offline-First

**What goes wrong:**
Cached recipe data never expires, showing outdated recipe instructions, deleted recipes, or old viral scores. No strategy for determining when cached data is "stale enough" to require refresh. Cache grows unbounded over time.

**Why it happens:**
Implementing offline caching without TTL (time-to-live) or cache invalidation strategy. "Store everything forever" approach for reliability without considering staleness.

**How to avoid:**
- Implement cache TTL based on data type:
  - Recipe content: 7 days (rare changes)
  - Viral badges/engagement: 1 hour (frequent changes)
  - Voice narration audio: 30 days (immutable once generated)
  - User bookmarks: sync immediately, cache indefinitely
- Store cache timestamp with each entry, check age on retrieval
- Implement background refresh on app launch if cache expired
- Show visual indicator when displaying cached data (offline indicator)
- Set maximum cache size limit (e.g., 500MB), evict oldest entries using LRU
- Manual refresh option for user-initiated cache invalidation
- Use ETags or GraphQL versioning to validate cache freshness

**Warning signs:**
- Users see deleted recipes in feed
- Viral badges show on recipes no longer trending
- Cache size grows to gigabytes over months
- No "last updated" timestamp shown for cached content

**Phase to address:**
Phase 7 (Offline Support) — Define cache invalidation policy before implementing offline mode. Test cache expiration edge cases.

---

### Pitfall 15: Onboarding Flow Exceeds 90-Second Target Causing Drop-Off

**What goes wrong:**
Onboarding takes 3-5 minutes with too many screens (welcome, features tour, permissions, account creation, voice upload, dietary preferences). 77% of users abandon within first 3 days. Users never experience core value proposition (voice-narrated recipes) before giving up.

**Why it happens:**
Product team wants to showcase every feature upfront. Permissions requested all at once (location, notifications, microphone) before demonstrating value. Voice profile creation required before user can browse recipes.

**How to avoid:**
- Defer voice profile creation until user tries to play first narration (progressive onboarding)
- Allow guest browsing immediately without account creation
- Show value before asking for permissions: let user browse recipes before requesting location
- Use contextual permission prompts: ask for microphone when user taps "Record Voice" button
- Limit onboarding to 3 screens maximum: welcome → explore feed as guest → conversion prompt on bookmark/voice
- Track onboarding completion time in analytics, optimize to stay under 90 seconds
- A/B test different onboarding flows to measure drop-off rates
- Use "just-in-time" onboarding: tooltips appear when features are first used

**Warning signs:**
- Analytics show > 50% drop-off during onboarding
- Users spend > 2 minutes before seeing first recipe
- App Store reviews complaining about "too much setup"
- Permission requests happen all at once at app launch

**Phase to address:**
Phase 3 (Onboarding & Auth) — Critical for retention. Test onboarding flow with real users, measure completion time.

---

### Pitfall 16: Guest-to-Account Conversion Loses User Data

**What goes wrong:**
User browses recipes as guest, bookmarks recipes, skips others (builds Culinary DNA), then creates account. All guest data (bookmarks, skips, personalization) is lost instead of migrated to authenticated account. User frustration and churn.

**Why it happens:**
Guest state stored locally in UserDefaults or Core Data without migration path to server. Account creation flow doesn't check for existing guest data or trigger migration. Guest and authenticated data stored in separate databases/tables.

**How to avoid:**
- Store guest data with device-specific identifier (UUID) in local database
- On account creation, trigger migration mutation: `convertGuestToAccount(guestId: UUID, userId: String)`
- Backend merges guest data into authenticated user account atomically
- Show migration progress UI: "Transferring your bookmarks..."
- Implement idempotent migration (safe to retry if network fails mid-migration)
- Verify migration success before clearing local guest data
- Test: guest with 10+ bookmarks → create account → verify all bookmarks preserved

**Warning signs:**
- Users complain "lost all my bookmarks after signing up"
- Analytics show low guest-to-account conversion rate
- Support tickets about missing data post-registration
- No migration logic in account creation flow

**Phase to address:**
Phase 3 (Onboarding & Auth) — Implement guest-to-account migration before launching guest mode. Critical for conversion.

---

### Pitfall 17: GraphQL Schema Type Name Conflicts with Swift Foundation Types

**What goes wrong:**
Apollo code generation creates Swift types from GraphQL schema that conflict with Foundation types (URL, Date, Data). Compilation errors or unexpected behavior when GraphQL types shadow Foundation types. Custom scalars (Date, DateTime, URL) mapped incorrectly.

**Why it happens:**
GraphQL schema defines custom scalars or types with common names (Date, URL, User) that collide with Swift standard library. Apollo codegen generates types without namespace protection.

**How to avoid:**
- Configure Apollo codegen with `schemaNamespace` to encapsulate all generated types:
```swift
schemaNamespace: "KindredAPI"  // Access as KindredAPI.Recipe instead of Recipe
```
- Use `ApolloCodegenConfiguration` to customize scalar mappings:
```swift
customScalars: [
  "DateTime": "Foundation.Date",
  "URL": "Foundation.URL"
]
```
- Use field aliases in queries when type name conflicts occur:
```graphql
query GetRecipe {
  recipe {
    recipeUrl: url  # Alias to avoid Swift URL type conflict
  }
}
```
- Review generated code for naming conflicts before integration
- Use explicit imports: `import struct Foundation.URL` when needed

**Warning signs:**
- Compilation errors: "Ambiguous use of 'URL'"
- Type inference failures in code using GraphQL responses
- Unexpected type conversions or crashes with scalar types
- Apollo codegen warnings about type name collisions

**Phase to address:**
Phase 2 (GraphQL Integration) — Configure schema namespace before first codegen run. Prevents refactoring later.

---

### Pitfall 18: GraphQL Subscription WebSocket Connection Not Managed Properly

**What goes wrong:**
WebSocket connection for GraphQL subscriptions (viral badge updates, new recipe notifications) doesn't reconnect after network interruptions. Connection leaks accumulate when switching between WiFi and cellular. App doesn't detect disconnection, misses real-time updates.

**Why it happens:**
Apollo iOS WebSocket transport doesn't automatically handle reconnection logic. Developers assume WebSocket connection is resilient like HTTP. No monitoring of connection state or network reachability changes.

**How to avoid:**
- Use `SplitNetworkTransport` with separate WebSocket and HTTP transports
- Implement connection state monitoring:
```swift
webSocketTransport.delegate = connectionMonitor
// Reconnect on disconnect
```
- Subscribe to `NWPathMonitor` for network changes, reconnect WebSocket on network transition
- Implement exponential backoff for reconnection attempts (1s, 2s, 4s, 8s, max 30s)
- Show connection status UI indicator when WebSocket disconnected
- Fall back to polling if WebSocket unavailable
- Test: switch WiFi → cellular → airplane mode → cellular to verify reconnection

**Warning signs:**
- Real-time updates stop working randomly
- WebSocket connections visible in Network profiler but not receiving messages
- Memory leaks from abandoned WebSocket connections
- Users report "need to restart app to get updates"

**Phase to address:**
Phase 2 (GraphQL Integration) — If implementing subscriptions. Otherwise defer to future phase. Test network transition scenarios.

---

### Pitfall 19: Token Refresh Race Condition Causing Logouts

**What goes wrong:**
Multiple simultaneous API requests trigger concurrent token refresh attempts when auth token expires. Two refresh requests use same refresh token, backend invalidates token (replay detection), user logged out unexpectedly. Lost session state and user frustration.

**Why it happens:**
API client doesn't serialize token refresh operations. When token expires, 5+ simultaneous GraphQL queries all trigger refresh independently. Auth0/Clerk refresh token rotation invalidates token after first use, subsequent attempts fail.

**How to avoid:**
- Use Swift Actor to serialize token refresh:
```swift
actor TokenRefresher {
    private var refreshTask: Task<String, Error>?

    func getValidToken() async throws -> String {
        if let task = refreshTask { return try await task.result.get() }
        let task = Task { try await performRefresh() }
        refreshTask = task
        defer { refreshTask = nil }
        return try await task.value
    }
}
```
- Single shared TokenRefresher instance across all API requests
- Queue pending requests while refresh in progress, resume with new token
- Store tokens securely in Keychain (never UserDefaults)
- Implement request interceptor to attach fresh token before each request
- Test: expire token → trigger 10 simultaneous requests → verify single refresh call

**Warning signs:**
- Random unexpected logouts during normal usage
- Backend logs show multiple refresh token attempts with same token
- "Invalid refresh token" errors in analytics
- Increased logout rate in analytics without user-initiated logout

**Phase to address:**
Phase 3 (Onboarding & Auth) — Critical for production stability. Implement before beta testing to avoid user churn.

---

### Pitfall 20: Navigation State Not Supporting Deep Links Properly

**What goes wrong:**
Push notification deep link (e.g., "Your recipe expires soon") doesn't navigate to correct screen. App opens to feed instead of specific recipe detail. Navigation stack doesn't build intermediate screens, leaving user unable to navigate back. Coordinator pattern not implemented, navigation logic scattered across views.

**Why it happens:**
SwiftUI navigation traditionally doesn't support pushing multiple screens in single state update. No centralized navigation coordinator to handle deep link routing. Navigation state managed locally in views instead of app-level state.

**How to avoid:**
- Use iOS 16+ `NavigationStack` with path-based navigation supporting deep links:
```swift
NavigationStack(path: $navigationPath) {
    // Root view
}
```
- Implement Coordinator pattern to centralize navigation logic (FlowStacks, SUICoordinator libraries)
- Handle deep links in app delegate/scene delegate, build navigation path array, update navigation state
- Build complete navigation stack for deep links: [.feed, .recipeDetail(id)] not just [.recipeDetail(id)]
- Store navigation state in TCA or ObservableObject for programmatic navigation
- Test deep links from: push notifications, universal links, widget taps, Siri shortcuts

**Warning signs:**
- Deep links open app but don't navigate anywhere
- No back button after deep link navigation
- Navigation inconsistent between tap-through and deep link
- Scattered `NavigationLink` calls throughout codebase without central management

**Phase to address:**
Phase 3 (Onboarding & Auth) — Establish navigation architecture before implementing features. Phase 8 (Push Notifications) — Deep link handling for notifications.

---

### Pitfall 21: Voice Recording Format Incompatible with ElevenLabs Requirements

**What goes wrong:**
User records voice sample using AVAudioRecorder, uploads to ElevenLabs, API rejects file format or quality too low for voice cloning. Recording at low bitrate (< 64kbps) or wrong format (non-MP3/WAV/M4A) causes cloning failure. File size exceeds 50MB limit.

**Why it happens:**
Default AVAudioRecorder settings use low-quality format optimized for small file size, not voice cloning quality. Developer doesn't review ElevenLabs file format requirements before implementation.

**How to avoid:**
- ElevenLabs accepts: WAV, MP3, M4A (MP4), OPUS formats
- Recommended: MP3 with 192kbps+ bitrate for best cloning quality
- Configure AVAudioRecorder settings:
```swift
let settings: [String: Any] = [
    AVFormatIDKey: kAudioFormatMPEG4AAC,
    AVSampleRateKey: 44100.0,
    AVNumberOfChannelsKey: 1,
    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
    AVEncoderBitRateKey: 192000  // 192kbps
]
```
- Enforce 30-60 second recording duration (ElevenLabs voice changer limit: 5 minutes, 50MB)
- Validate file size before upload (< 50MB)
- Convert to MP3 if needed before upload using AudioConverter
- Show recording quality indicator during capture

**Warning signs:**
- ElevenLabs API returns "unsupported format" errors
- Voice cloning quality poor (robotic, unclear)
- File uploads fail with "file too large" errors
- Backend logs show format conversion failures

**Phase to address:**
Phase 4 (Voice Playback) — Configure recording settings before implementing voice upload. Test with ElevenLabs API early.

---

### Pitfall 22: Location Permissions Requested Prematurely with Generic Rationale

**What goes wrong:**
App requests location permission on first launch without explaining why. Generic iOS permission prompt "Allow Kindred to access your location?" rejected by user. No "when in use" vs "always" distinction. 50%+ permission denial rate.

**Why it happens:**
Requesting location permission at app launch before demonstrating value. Not customizing `NSLocationWhenInUseUsageDescription` in Info.plist with compelling reason.

**How to avoid:**
- Defer location request until user browses feed and sees value proposition
- Show custom pre-permission prompt explaining benefit: "See recipes trending in your neighborhood"
- Customize Info.plist usage description:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Kindred discovers viral recipes trending within 5-10 miles of your location, bringing you the meals your neighbors are loving right now.</string>
```
- Request "When In Use" permission initially, not "Always" (better approval rate)
- Only request background location if implementing persistent tracking (avoid for MVP)
- Implement graceful degradation: default to city-level if permission denied
- Monitor location permission grant rate in analytics, optimize prompt timing/messaging

**Warning signs:**
- Analytics show < 50% location permission grant rate
- Users complain about "too many permission requests"
- Feed shows generic nationwide recipes instead of local
- App Store reviews mentioning privacy concerns

**Phase to address:**
Phase 3 (Feed Implementation) — Request location contextually when showing feed, not at app launch.

---

### Pitfall 23: App Review Rejection for Incomplete In-App Purchase Implementation

**What goes wrong:**
App submitted with StoreKit in-app purchases configured but reviewer can't complete purchase flow. Missing subscription management UI (view active subscription, cancel). External purchase links in app (website URL). Subscription terms not clearly displayed. Instant rejection.

**Why it happens:**
Developer focuses on purchase flow but neglects post-purchase management UI. App Store Review Guidelines violations not caught in pre-submission testing. No subscription management screen for users to view/cancel.

**How to avoid:**
- Implement subscription management UI showing:
  - Current subscription status (Free/Pro)
  - Renewal date and price
  - Cancel subscription option (deep link to App Store subscription management)
- Remove all external payment links (no "Subscribe on our website")
- Display subscription terms before purchase: auto-renewal, pricing, cancellation policy
- Provide restore purchases button for users reinstalling app
- Test purchases in sandbox environment with test accounts
- Configure in-app purchases in App Store Connect before submission
- Provide demo account credentials in App Review notes if login required
- Review App Store Review Guidelines 3.1 (In-App Purchase) before submission

**Warning signs:**
- Sandbox purchases failing during testing
- No subscription management UI visible in app
- External payment URLs present in app
- Missing "Restore Purchases" button

**Phase to address:**
Phase 5 (Monetization) — Complete subscription management UI before App Store submission. Pre-submission checklist.

---

### Pitfall 24: SwiftUI List Performance Degradation with Large Feed Datasets

**What goes wrong:**
Feed with 500+ recipes causes scrolling jank, frame drops, and memory pressure. List loads all recipe views immediately instead of lazy loading. Image decoding on main thread blocks scrolling. App becomes unusable as user scrolls through long feed.

**Why it happens:**
Using `List` without understanding lazy loading characteristics, or using `ForEach` inside regular `VStack` (loads all views immediately). Synchronous image loading from network on main thread. Not implementing pagination.

**How to avoid:**
- Use `List` or `LazyVStack` (not `VStack`) for large datasets — only loads visible views
- Implement pagination: load 20 recipes at a time, fetch more as user scrolls
- Use `AsyncImage` with placeholder for recipe images (async decoding)
- Consider Kingfisher/SDWebImage for image caching and background decoding
- Use `.id()` modifier sparingly on List — impacts lazy loading
- Implement view recycling by keeping recipe card views lightweight
- Profile with Instruments to identify expensive view updates
- Set `.listRowSeparator(.hidden)` if not needed to reduce rendering overhead

**Warning signs:**
- Scrolling lags or stutters with > 50 items in feed
- Memory usage spikes as user scrolls (not releasing offscreen views)
- Instruments shows main thread blocked during scrolling
- UI becomes unresponsive when loading large feed

**Phase to address:**
Phase 3 (Feed Implementation) — Implement pagination and lazy loading from start. Profile performance before moving to next phase.

---

### Pitfall 25: GDPR/ATT Compliance Missing or Incorrect Implementation

**What goes wrong:**
App tracks analytics (Firebase, Amplitude) without user consent. ATT (App Tracking Transparency) prompt shown but GDPR consent not requested. App rejected in EU App Store for privacy violations. Legal liability for GDPR non-compliance. Incorrectly assuming ATT replaces GDPR consent.

**Why it happens:**
Confusion between Apple's ATT (tracking across apps/websites) and GDPR (any personal data processing). Developers implement ATT but skip GDPR consent management platform (CMP). Analytics initialized before consent obtained.

**How to avoid:**
- ATT ≠ GDPR: both required for EU users
- Implement GDPR-compliant consent management platform (OneTrust, Usercentrics, Didomi)
- Show GDPR consent dialog before ATT prompt
- Request ATT permission using `AppTrackingTransparency.requestTrackingAuthorization()`
- Customize Info.plist `NSUserTrackingUsageDescription`:
```xml
<key>NSUserTrackingUsageDescription</key>
<string>We use your data to personalize recipe recommendations and measure app performance. Your privacy is important to us.</string>
```
- Initialize analytics only after user grants consent
- Provide privacy policy link in app and during consent flow
- Allow users to withdraw consent in app settings
- Test consent flow before analytics initialization

**Warning signs:**
- Analytics tracking starts before consent obtained
- No consent management UI in app
- App Store rejection for privacy violations
- Only ATT implemented, no GDPR consent

**Phase to address:**
Phase 3 (Onboarding & Auth) — Implement GDPR consent and ATT before any analytics/tracking. Legal review before launch.

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Skipping TCA for entire app, using only vanilla SwiftUI | Faster initial development, less boilerplate | Difficult to add complex state management later, harder testing, state scattered across views | Never for production — use TCA selectively from start |
| In-memory Apollo cache without SQLite backend | Simpler setup, no database configuration | Memory leaks, cache orphans, app crashes, no persistence across launches | MVP only, migrate to SQLite before beta |
| AVAudioPlayer instead of AVPlayer for streaming | Simpler API, less code | Forces full audio download, poor UX, high bandwidth usage | Only for local cached audio files (offline mode) |
| Last-write-wins conflict resolution | Easy to implement, no conflict UI needed | Silent data loss, user frustration, multi-device issues | Single-device use only, migrate to operation-based sync for multi-device |
| Hardcoded 44pt touch targets instead of 56pt | Smaller UI elements, more screen space | WCAG AAA violations, accessibility failures, elderly user frustration | Never acceptable — 56pt is minimum for target users |
| Guest data in UserDefaults instead of Core Data | Quick implementation, no database setup | Lost data on migration, no atomic operations, scalability issues | Prototype only, use Core Data for production |
| Network-first fetch policy everywhere | Always fresh data, simple logic | Excessive bandwidth usage, slow UX, no offline support | Only for critical user actions (purchases), use cache-and-network for feed |
| Generic permission request rationale | Faster to implement, standard iOS prompt | Low permission grant rate, user distrust, feature degradation | Never — always customize rationale for specific app value |

---

## Integration Gotchas

Common mistakes when connecting to external services.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| ElevenLabs API | Streaming entire voice narration into memory before playback | Use AVPlayer with streaming URL, progressive playback as audio arrives |
| ElevenLabs Voice Cloning | Uploading low-bitrate (< 64kbps) recordings causing poor clone quality | Record at 192kbps+ MP3/M4A, validate format before upload, 30-60s duration |
| Apollo GraphQL | Using cache-first everywhere, showing stale viral badges and engagement counts | Use cache-and-network for feed, network-only for mutations, implement cache TTL |
| Apollo Subscriptions | Not reconnecting WebSocket after network changes (WiFi → cellular) | Monitor NWPathMonitor, implement reconnection with exponential backoff |
| StoreKit 2 | Using receipt validation instead of JWS transaction verification | Verify JWS signatures, use App Store Server API with transaction IDs |
| StoreKit 2 Subscriptions | Checking entitlements only at app launch, missing renewals/expirations | Monitor Transaction.updates async sequence throughout app lifecycle |
| Clerk/Auth0 Auth | Not serializing token refresh, causing race conditions and logouts | Use Swift Actor to serialize refresh operations, queue pending requests |
| NestJS GraphQL Backend | Not handling schema type name conflicts (Date, URL) with Swift Foundation types | Configure Apollo codegen with schemaNamespace, use custom scalar mappings |
| Core Data + iCloud | Trusting automatic conflict resolution, losing user edits on multi-device sync | Implement operation-based sync with timestamps, surface conflicts to user |
| Location Services | Requesting "Always" permission upfront, causing denial | Request "When In Use" first with contextual explanation, upgrade to "Always" if needed later |

---

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| ViewStore observing entire TCA state | Frame drops, view redrawing when data unchanged, sluggish UI | Scope ViewStore to minimal state slices: `observe: \.recipeList` | > 5 screens in navigation hierarchy, frequent state updates |
| Apollo cache without garbage collection | Memory usage grows continuously, eventual crash | Call `store.gc()` on low memory warning, use SQLite cache for large datasets | > 500 cached recipes, prolonged app sessions |
| List with ForEach loading all items | Scrolling jank with > 50 items, memory spikes | Use LazyVStack or List with pagination, load 20 items at a time | > 100 feed items, complex recipe card views |
| Synchronous image decoding on main thread | Scrolling stutters, UI freezes during image load | Use AsyncImage or Kingfisher with background decoding and caching | > 20 images visible in feed, high-resolution images |
| GraphQL queries without pagination | Initial feed load takes 10+ seconds, timeout errors | Implement cursor-based pagination: `first: 20, after: cursor` | > 200 recipes in feed query |
| Loading entire audio file before playback | 3-5 second delay before audio starts, memory pressure | Use AVPlayer streaming with buffering indicators, cache for offline only | Audio files > 1MB, slow network connections |
| Network-first fetch policy on every scroll | Excessive API calls, rate limiting, high server costs | Use cache-and-network policy, implement query batching/deduplication | > 1000 DAU, frequent feed scrolling |
| Unbounded cache growth without eviction | Cache reaches gigabytes over months, slow app startup | Implement LRU eviction, max cache size (500MB), TTL-based expiration | > 1000 cached recipes, 30+ day retention |

---

## Security Mistakes

Domain-specific security issues beyond general web security.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Storing auth tokens in UserDefaults instead of Keychain | Token accessible to any process with device access, jailbreak exposure | Always use Keychain for tokens: `KeychainAccess` library or Security framework |
| Not validating JWS signatures from App Store Server API | Fake purchase receipts, unauthorized Pro access, revenue loss | Verify JWS using x509 certificate chain validation on backend |
| Exposing ElevenLabs API key in client-side code | Unlimited voice cloning costs, API abuse, account suspension | Proxy all ElevenLabs calls through NestJS backend, never expose API key |
| Accepting untrusted deep links without validation | Malicious apps triggering unauthorized actions, XSS-style attacks | Validate deep link parameters, require authentication for sensitive actions |
| Logging sensitive user data (location, voice profile IDs) | GDPR violations, privacy breaches in crash reports | Sanitize logs, use redaction: `os_log(.debug, "%{private}@", location)` |
| Not implementing certificate pinning for API requests | Man-in-the-middle attacks intercepting auth tokens, recipe data | Implement SSL pinning for production backend: `Alamofire.ServerTrustPolicy` |
| Allowing arbitrary URL schemes in deep links | Malicious redirects, phishing attacks via notification deep links | Whitelist allowed URL schemes: only `kindred://`, validate all parameters |
| Voice recordings stored unencrypted in local storage | Privacy breach if device compromised, voice cloning theft | Encrypt voice recordings using Data Protection API: `.completeUnlessOpen` |

---

## UX Pitfalls

Common user experience mistakes in this domain.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Requesting all permissions at once at launch | Permission fatigue, user denies all, missing critical features | Progressive permissions: location when viewing feed, microphone when recording voice, notifications when demonstrating value |
| No loading state during voice narration streaming | User taps play, nothing happens for 2 seconds, assumes broken | Show buffering indicator, disable play button during load, display progress |
| Error messages like "GraphQL Error: 500" | User confusion, support tickets, app appears broken | User-friendly errors: "Can't load recipes right now. Check your connection." with retry button |
| No offline indicator when showing cached data | User sees stale data, thinks app is broken when data doesn't update | Show "Offline — showing saved recipes" banner with last updated timestamp |
| Onboarding skippable but features inaccessible without completion | User skips onboarding, can't use app, confusion and churn | Allow guest browsing immediately, prompt for account/voice on first bookmark attempt |
| Swipe gestures without button alternatives | VoiceOver users can't navigate, accessibility failure | Provide Listen/Watch/Skip buttons as swipe alternatives, equal functionality |
| No confirmation for destructive actions (unbookmark, delete voice profile) | Accidental data loss, user frustration, support requests | Show confirmation dialog for destructive actions with undo option |
| Pro paywall blocking all features immediately | User never experiences value, won't pay for unknown product | Free tier with 1 voice slot, limit features after user hooked, conversion at value moment |
| Dietary preferences hidden in settings, hard to discover | Users see irrelevant recipes (meat recipes for vegans), churn | Onboarding question: "Any dietary preferences?" with easy later editing in feed filter |
| No progress indicator for long operations (voice upload, sync) | User thinks app frozen, force quits during critical operation | Show progress bar, percentage, estimated time remaining, prevent navigation during operation |

---

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Voice Playback:** Audio plays but doesn't handle interruptions (phone calls, alarms) — verify AVAudioSessionInterruptionNotification handling and session configuration
- [ ] **StoreKit Integration:** Purchases work but no subscription management UI — verify cancel/view subscription screen exists
- [ ] **Accessibility:** VoiceOver reads elements but labels are generic ("Button") — verify meaningful accessibility labels on all custom controls
- [ ] **Offline Support:** Cached data loads but no TTL/invalidation — verify cache expiration logic and staleness indicators
- [ ] **GraphQL Integration:** Queries work but mutations don't update cache — verify cache update functions in mutation responses
- [ ] **Authentication:** Login works but token refresh causes race conditions — verify serialized token refresh with Actor pattern
- [ ] **Guest Mode:** Guest browsing works but data lost on account creation — verify guest-to-account migration flow
- [ ] **Deep Linking:** App opens from notification but doesn't navigate — verify navigation stack building for deep links
- [ ] **Location:** Location permission granted but no background tracking capability — verify Info.plist has background location usage description if needed
- [ ] **Dynamic Type:** UI looks good at default size but breaks at AX3+ — verify testing at all accessibility text sizes
- [ ] **Touch Targets:** Buttons tap-able on development device but too small for WCAG AAA — verify 56x56pt minimum with Accessibility Inspector
- [ ] **Color Contrast:** Design looks beautiful but fails contrast checker — verify 7:1 ratio for all text with WebAIM tool
- [ ] **Apollo Cache:** Cache works initially but grows unbounded — verify garbage collection on low memory warnings
- [ ] **TCA Performance:** App fast with 10 items but sluggish with 100 — verify ViewStore scoping and lazy loading
- [ ] **WebSocket Subscriptions:** Real-time works on WiFi but not after network change — verify reconnection logic on network transitions

---

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| TCA over-engineering everywhere | MEDIUM | 1. Identify simple screens (< 3 state properties), 2. Migrate to vanilla SwiftUI with @StateObject, 3. Keep TCA for complex screens (feed, voice playback) |
| Apollo cache orphans causing crashes | LOW | 1. Add `apollo.clearCache()` on low memory warning, 2. Implement periodic `store.gc()`, 3. Migrate to SQLite cache if needed |
| ViewStore performance issues | LOW | 1. Add `observe:` parameter scoping ViewStore to minimal state, 2. Profile with Instruments to identify unnecessary redraws, 3. Use @ObservableState macro if TCA 1.0+ |
| StoreKit receipt validation instead of JWS | HIGH | 1. Backend: implement JWS verification, 2. iOS: send transaction ID instead of receipt, 3. Deploy backend first, 4. Update iOS client, 5. Monitor both paths during migration |
| Guest data lost on account creation | HIGH | 1. Backend: add guest migration endpoint, 2. iOS: implement migration before clearing local data, 3. Add analytics to verify migration success, 4. Communicate to affected users |
| Accessibility violations (touch targets, contrast) | MEDIUM | 1. Audit with Accessibility Inspector, 2. Increase touch targets to 56pt, 3. Adjust colors for 7:1 contrast, 4. Test with VoiceOver before resubmission |
| Token refresh race conditions | MEDIUM | 1. Wrap token refresh in Swift Actor, 2. Queue pending requests during refresh, 3. Add logging to detect concurrent refresh attempts, 4. Test with expired token |
| Deep links not navigating | MEDIUM | 1. Implement Coordinator pattern (FlowStacks library), 2. Build navigation path array from deep link, 3. Update navigation state, 4. Test all deep link scenarios |
| Offline sync conflicts losing data | HIGH | 1. Migrate to operation-based sync with timestamps, 2. Implement conflict detection, 3. Surface conflicts to user with resolution UI, 4. Add undo capability |
| Onboarding drop-off > 50% | MEDIUM | 1. Track funnel steps in analytics, 2. Identify highest drop-off step, 3. A/B test removing or simplifying that step, 4. Aim for < 90 second completion time |
| Location permission denied by 70%+ users | LOW | 1. Add pre-permission explanation screen, 2. Customize NSLocationWhenInUseUsageDescription with compelling reason, 3. Request only when showing feed, not at launch |
| App Store rejection for IAP issues | MEDIUM | 1. Add subscription management UI, 2. Remove external payment links, 3. Display terms clearly before purchase, 4. Test in sandbox, 5. Resubmit with detailed notes |
| Voice recording format incompatible | LOW | 1. Update AVAudioRecorder settings to 192kbps MP3/M4A, 2. Add format validation before upload, 3. Test with ElevenLabs API, 4. Communicate to users if re-recording needed |
| GDPR/ATT compliance missing | HIGH | 1. Integrate consent management platform (Didomi, OneTrust), 2. Show GDPR consent before ATT, 3. Initialize analytics only after consent, 4. Legal review before release |

---

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| TCA over-engineering | Phase 1 (Architecture Setup) | Documented guidelines for TCA vs vanilla SwiftUI, code review checklist |
| ViewStore performance issues | Phase 1 (Architecture Setup) | ViewStore scoping examples in docs, Instruments profiling in PR reviews |
| Apollo cache orphans | Phase 2 (GraphQL Integration) | Low memory warning handler implemented, cache size monitoring in analytics |
| Apollo cache vs server state conflicts | Phase 2 (GraphQL Integration) | Fetch policy documented per query type, cache update tests for mutations |
| Background audio interruptions | Phase 4 (Voice Playback) | Interruption handling code, tested with phone calls/alarms/Siri |
| AVAudioPlayer vs AVPlayer wrong choice | Phase 4 (Voice Playback) | Architecture decision doc specifies AVPlayer for streaming, AVAudioPlayer for cached |
| StoreKit receipt validation instead of JWS | Phase 5 (Monetization) | Backend JWS verification endpoint, iOS sends transaction IDs not receipts |
| StoreKit Transaction.updates not monitored | Phase 5 (Monetization) | Subscription manager monitors Transaction.updates, tested with sandbox renewals |
| VoiceOver labels missing/generic | Phase 6 (Accessibility — WCAG AAA) | VoiceOver testing in PR reviews, Accessibility Inspector audit before release |
| Dynamic Type breaks layout | Phase 6 (Accessibility — WCAG AAA) | All screens tested at AX1-AX5 sizes, documented in QA checklist |
| Touch targets below 56pt | Phase 6 (Accessibility — WCAG AAA) | Accessibility Inspector verification, touch target audit in design review |
| Color contrast below 7:1 | Phase 6 (Accessibility — WCAG AAA) | WebAIM contrast checker in design system, automated contrast tests |
| Offline sync conflicts | Phase 7 (Offline Support) | Operation-based sync implemented, multi-device conflict test scenarios |
| Cache invalidation strategy missing | Phase 7 (Offline Support) | TTL documented per data type, cache expiration tests, staleness indicators |
| Onboarding exceeds 90 seconds | Phase 3 (Onboarding & Auth) | Onboarding completion time analytics, user testing with target users (elderly) |
| Guest-to-account data loss | Phase 3 (Onboarding & Auth) | Migration flow tested with guest data, analytics verify migration success |
| GraphQL schema type conflicts | Phase 2 (GraphQL Integration) | Apollo codegen configuration with schemaNamespace, custom scalar mappings |
| GraphQL WebSocket not reconnecting | Phase 2 (GraphQL Integration) | Network transition tests (WiFi → cellular → airplane), connection monitoring |
| Token refresh race conditions | Phase 3 (Onboarding & Auth) | Token refresh serialization with Actor, concurrent request tests |
| Navigation deep links broken | Phase 3 (Onboarding & Auth) | Coordinator pattern implemented, deep link test suite (notifications, widgets) |
| Voice recording format incompatible | Phase 4 (Voice Playback) | AVAudioRecorder settings validated, test upload to ElevenLabs API |
| Location permissions premature | Phase 3 (Feed Implementation) | Permission request contextual (when viewing feed), custom rationale in Info.plist |
| App Store IAP rejection | Phase 5 (Monetization) | Subscription management UI, App Store Review Guidelines checklist |
| SwiftUI List performance issues | Phase 3 (Feed Implementation) | Pagination implemented, lazy loading verified, Instruments profiling |
| GDPR/ATT compliance missing | Phase 3 (Onboarding & Auth) | Consent management platform integrated, legal review completed |

---

## Sources

### TCA Architecture
- [The Composable Architecture: How Architectural Design Decisions Influence Performance - swiftyplace](https://www.swiftyplace.com/blog/the-composable-architecture-performance)
- [Modern iOS App Architecture in 2026: MVVM vs Clean Architecture vs TCA | 7Span](https://7span.com/blog/mvvm-vs-clean-architecture-vs-tca)
- [The Composable Architecture: My 3 Year Experience • Rod Schmidt](https://rodschmidt.com/posts/composable-architecture-experience/)
- [Are there any good ways to increase performance? · pointfreeco/swift-composable-architecture · Discussion #896](https://github.com/pointfreeco/swift-composable-architecture/discussions/896)
- [Improving Composable Architecture performance](https://www.pointfree.co/blog/posts/80-improving-composable-architecture-performance)
- [Dependency Injection in The Composable Architecture: An Architect's Perspective | Medium](https://medium.com/@gauravios/dependency-injection-in-the-composable-architecture-an-architects-perspective-9be5571a0f89)

### GraphQL & Apollo iOS
- [How to Implement GraphQL Caching with Apollo Client](https://oneuptime.com/blog/post/2026-01-30-graphql-client-side-caching-apollo/view)
- [Apollo Client Troubleshooting: Fixing Query, Cache, Authentication, and Performance Issues - Mindful Chase](https://www.mindfulchase.com/explore/troubleshooting-tips/frameworks-and-libraries/apollo-client-troubleshooting-fixing-query,-cache,-authentication,-and-performance-issues.html)
- [Apollo Cache is Your Friend, If You Get To Know It - Shopify](https://shopify.engineering/apollo-cache)
- [Garbage collection and cache eviction - Apollo GraphQL Docs](https://www.apollographql.com/docs/react/caching/garbage-collection)
- [Client-side caching - Apollo GraphQL Docs](https://www.apollographql.com/docs/ios/caching/introduction)
- [Codegen configuration - Apollo GraphQL Docs](https://www.apollographql.com/docs/ios/code-generation/codegen-configuration)
- [iOS Swift CodeGen scalars conflicting with Foundation types - Apollo Community](https://community.apollographql.com/t/ios-swift-codegen-scalars-conflicting-with-foundation-types/5181)
- [Subscriptions - Apollo GraphQL Docs](https://www.apollographql.com/docs/react/data/subscriptions)

### Audio & AVFoundation
- [Background audio handling with iOS AVPlayer | Mux](https://www.mux.com/blog/background-audio-handling-with-ios-avplayer)
- [How To Make Your App Support Background Audio Playback | SweetTutos](https://sweettutos.com/2020/09/08/how-to-make-your-app-support-background-audio-playback/)
- [Configuring an Audio Session](https://developer.apple.com/library/archive/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/AudioSessionBasics/AudioSessionBasics.html)
- [Managing Audio Interruption, and Route Change in iOS Application | Medium](https://medium.com/@mehsamadi/managing-audio-interruption-and-route-change-in-ios-application-8202801fd72f)

### StoreKit 2
- [How to Validate iOS and macOS In-App Purchases Using StoreKit 2 and Server-Side Swift | Medium](https://medium.com/@ronaldmannak/how-to-validate-ios-and-macos-in-app-purchases-using-storekit-2-and-server-side-swift-98626641d3ea)
- [iOS In-App Subscription Tutorial with StoreKit 2 and Swift](https://www.revenuecat.com/blog/engineering/ios-in-app-subscription-tutorial-with-storekit-2-and-swift/)
- [Receipt Validation in StoreKit 1 vs StoreKit 2 Server API](https://qonversion.io/blog/storekit1-storeki2-receipt-validation/)
- [How to validate server-side transactions with Apple's App Store Server API | Adapty](https://adapty.io/blog/validating-iap-with-app-store-server-api/)
- [StoreKit 2 API Tutorial for Apple In-App Purchases](https://adapty.io/blog/storekit-2-api-tutorial/)

### Accessibility
- [iOS Accessibility Guidelines: Best Practices for 2025 | Medium](https://medium.com/@david-auerbach/ios-accessibility-guidelines-best-practices-for-2025-6ed0d256200e)
- [Mobile App Accessibility: VoiceOver, TalkBack, and Inclusive Design | Medium](https://medium.com/@growingprot/mobile-app-accessibility-voiceover-talkback-and-inclusive-design-dc21f7eddcfc)
- [Mobile Application Accessibility Guide (2026) – WCAG 2.2, iOS & Android](https://corpowid.ai/blog/mobile-application-accessibility-practical-humancentered-guide-android-ios)
- [How to Fix Common iOS Accessibility Issues - Deque](https://www.deque.com/blog/how-to-fix-common-ios-accessibility-issues/)
- [iOS UIKit Accessibility traits | Mobile A11y](https://mobilea11y.com/blog/traits/)
- [iOS Accessibility Tutorial: Making Custom Controls Accessible | Kodeco](https://www.kodeco.com/4720178-ios-accessibility-tutorial-making-custom-controls-accessible)
- [WCAG 2.5.5: Target size (Enhanced) (Level AAA) - Silktide](https://silktide.com/accessibility-guide/the-wcag-standard/2-5/input-modalities/2-5-5-target-size-enhanced/)
- [WebAIM: Contrast and Color Accessibility - Understanding WCAG 2 Contrast and Color Requirements](https://webaim.org/articles/contrast/)
- [How to Address Common Accessibility Challenges in iOS Mobile Apps Using SwiftUI](https://www.freecodecamp.org/news/how-to-address-ios-accessibility-challenges-using-swiftui/)

### Offline & Sync
- [Offline-first mobile app background sync: conflicts, retries, UX | AppMaster](https://appmaster.io/blog/offline-first-background-sync-conflict-retries-ux)
- [Building Offline-First iOS Apps: Handling Data Synchronization and Storage](https://www.hashstudioz.com/blog/building-offline-first-ios-apps-handling-data-synchronization-and-storage/)
- [Offline First Mobile Apps Pt 1: The Blueprint | Medium](https://jeremyrempel.medium.com/offline-first-applications-pt-1-the-blueprint-9f518aa374dd)
- [Getting Started With NSPersistentCloudKitContainer](https://www.andrewcbancroft.com/blog/ios-development/data-persistence/getting-started-with-nspersistentcloudkitcontainer/)
- [Syncing a Core Data Store with CloudKit | Apple Developer Documentation](https://developer.apple.com/documentation/coredata/syncing-a-core-data-store-with-cloudkit)

### Onboarding & UX
- [Mobile Onboarding UX: 11 Best Practices for Retention (2026)](https://www.designstudiouiux.com/blog/mobile-app-onboarding-best-practices/)
- [The Ultimate Mobile App Onboarding Guide (2026) | VWO](https://vwo.com/blog/mobile-app-onboarding-guide/)
- [Onboarding UX Strategies to Reduce Drop-Off in the First Minute](https://rubyroidlabs.com/blog/2026/02/ux-onboarding-first-60-seconds/)
- [100+ User Onboarding Statistics You Need to Know in 2026](https://userguiding.com/blog/user-onboarding-statistics)

### Authentication & Security
- [Building a token refresh flow using async await in Swift](https://www.donnywals.com/building-a-token-refresh-flow-with-async-await-and-swift-concurrency/)
- [Race condition around token refreshing producing logouts · Issue #1300 · home-assistant/iOS](https://github.com/home-assistant/iOS/issues/1300)
- [Using a Refresh Token in an iOS Swift App](https://auth0.com/blog/using-a-refresh-token-in-an-ios-swift-app/)
- [Share authentication state across your apps, App Clips and Widgets (iOS) | Medium](https://medium.com/@thomsmed/share-authentication-state-across-your-apps-app-clips-and-widgets-ios-e7e7f24e5525)

### Navigation
- [Proper Navigation in SwiftUI with Coordinators | Medium](https://medium.com/@ivkuznetsov/proper-navigation-in-swiftui-with-coordinators-ee33f52ebe98)
- [Advanced SwiftUI Navigation Patterns: Production-Ready Code | Medium](https://medium.com/@chandra.welim/advanced-swiftui-navigation-patterns-production-ready-code-7886e7ae1937)
- [Navigation and Deep-Links in SwiftUI - QuickBird Studios](https://quickbirdstudios.com/blog/swiftui-navigation-deep-links/)

### Performance
- [Optimizing SwiftUI Lists: Diffable Data, Pagination, and Lazy Grids | Medium](https://medium.com/@swatimishra2824/optimizing-swiftui-lists-diffable-data-pagination-and-lazy-grids-c539210bcc9b)
- [Lazy Loading and Pagination for Large Data Sets in SwiftUI with Infinite Scrolling](https://www.svpdigitalstudio.com/blog/how-to-implement-lazy-loading-pagination-with-observation-swiftui-task-async-await)
- [Tips and Considerations for Using Lazy Containers in SwiftUI](https://fatbobman.com/en/posts/tips-and-considerations-for-using-lazy-containers-in-swiftui/)
- [Demystifying SwiftUI List Responsiveness - Best Practices for Large Datasets](https://fatbobman.com/en/posts/optimize_the_response_efficiency_of_list/)

### Privacy & Compliance
- [Mobile App Consent for iOS: A Deep Dive (2025)](https://secureprivacy.ai/blog/mobile-app-consent-ios-2025)
- [iOS Privacy Measures: GDPR, Privacy Nutrition Labels, App Tracking Transparency and Privacy Manifest Files | Medium](https://medium.com/axel-springer-tech/apple-privacy-measures-gdpr-privacy-nutrition-labels-app-tracking-transparency-and-privacy-912a7dabc85e)
- [App Tracking Transparency (ATT): Apple's User Privacy Framework](https://adapty.io/blog/app-tracking-transparency/)
- [Be Cautious App Developers: ATT ≠ GDPR - App Growth Summit](https://appgrowthsummit.com/be-cautious-app-developers-att-and-gdpr-are-not-the-same/)

### App Store Review
- [14 Common Apple App Store Rejections and How To Avoid Them - OneMobile](https://onemobile.ai/common-app-store-rejections-and-how-to-avoid-them/)
- [iOS App Store Review Guidelines 2026: Best Practices](https://crustlab.com/blog/ios-app-store-review-guidelines/)
- [Top Reasons iOS Apps Get Rejected by the App Store in 2026 (& Fixes)](https://www.eitbiz.com/blog/top-reasons-ios-apps-get-rejected-by-the-app-store-and-fixes/)
- [App Store Review Guidelines 2026: Updated Checklist](https://adapty.io/blog/how-to-pass-app-store-review/)

### ElevenLabs Integration
- [What files do you accept for voice cloning? – ElevenLabs](https://help.elevenlabs.io/hc/en-us/articles/13440435385105-What-files-do-you-accept-for-voice-cloning)
- [Voice changer (product guide) | ElevenLabs Documentation](https://elevenlabs.io/docs/eleven-creative/playground/voice-changer)
- [What is the maximum size of file I can upload for Voice Isolator? – ElevenLabs](https://help.elevenlabs.io/hc/en-us/articles/26446749564049-What-is-the-maximum-size-of-file-I-can-upload-for-Voice-Isolator)

### Location Services
- [Energy Efficiency Guide for iOS Apps: Reduce Location Accuracy and Duration](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/EnergyGuide-iOS/LocationBestPractices.html)
- [Optimizing iOS location services: maximize your app's battery life](https://rangle.io/blog/optimizing-ios-location-services)
- [Location tracking in iOS. As a developer working on an iOS… | Medium](https://medium.com/@sarathkumar_87623/location-tracking-in-ios-49bf56dd455e)

---

*Pitfalls research for: iOS App (SwiftUI + TCA) consuming existing NestJS GraphQL backend*
*Researched: 2026-03-01*
