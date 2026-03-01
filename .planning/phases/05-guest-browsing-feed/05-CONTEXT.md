# Phase 5: Guest Browsing & Feed - Context

**Gathered:** 2026-03-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Users can browse viral recipes and explore the feed without creating an account. Includes Tinder-style swipeable recipe cards with location-based discovery, recipe detail view, guest session persistence, and offline caching. Authentication, dietary filtering, and voice playback are separate phases.

</domain>

<decisions>
## Implementation Decisions

### Card Interaction Model
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

### Card Metadata & Badges
- VIRAL badge as prominent overlay — angled ribbon/badge pinned to corner of hero image, only when `isViral` is true
- Prep time: clock icon + total minutes (e.g., "25 min"). If both prepTime and cookTime exist, show total
- Calories shown on card
- Loves count: heart icon + abbreviated count (e.g., "2.3k loves")
- Dietary tags NOT shown on cards — detail screen only (keeps cards clean)

### Recipe Detail View
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

### Location Experience
- Tappable pill in navigation bar showing city name with pin icon prefix
- Search-based bottom sheet when pill tapped: "Use my location" button with location pin icon at the very top, above search field
- If location permission not granted, tapping "Use my location" triggers system permission prompt
- Deferred location permission — start with default curated city, only request GPS when user taps badge and selects "Use my location"
- Default to curated city (e.g., Istanbul) when location denied
- Persist last selected city in UserDefaults across app launches
- Animated card refresh when switching cities — current cards animate out (fade/slide), new cards animate in

### Guest Session Storage
- Local CoreData/SwiftData for bookmarks, skipped recipes, and guest preferences
- Generate anonymous UUID on first launch — store locally, tag all interactions with it, carries over to Phase 8 account conversion
- Skipped recipes hidden until feed refresh (pull-to-refresh or location change brings them back)
- Bookmark count badge on Me tab
- Soft limit on bookmarks: after 10, show gentle nudge "Create an account to keep your recipes safe" (no hard block)

### Offline & Feed Loading
- Persistent top banner when offline: "You're offline — showing cached recipes"
- Queue bookmarks and sync later — user doesn't see the difference (seamless for guests since no server sync anyway)
- Cache current batch of recipes + hero images for offline use (10-20 recipes worth)
- Skeleton shimmer cards on initial feed load (use existing skeleton implementation from FeedView)
- Silent refresh on reconnect — quietly fetch new recipes, show subtle "New recipes available" indicator, user pulls to refresh to see them
- EmptyStateView (.noRecipes) for empty feed with "Change Location" button

### Accessibility
- Each card is single VoiceOver element: reads "Recipe name, prep time, calories"
- Custom VoiceOver actions menu on cards: "Bookmark" / "Skip" / "View details"
- Listen/Watch/Skip buttons include accessibility hints: "Skip button — or swipe left", "Bookmark button — or swipe right"
- Post VoiceOver notifications on location changes: "Now showing recipes near Istanbul"
- Post VoiceOver notifications on card transitions: "Recipe 3 of 15, [name]"
- All interactive elements maintain 56dp minimum touch targets (ACCS-01)
- Navigation depth maximum 3 levels (ACCS-04): Feed → Detail → (none beyond)

### Feed Performance
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

</decisions>

<specifics>
## Specific Ideas

- Cards should feel like Tinder's card stack — the satisfying swipe-and-dismiss interaction
- Hero image zoom transition inspired by iOS Photos app — image expands from card into detail
- The end-of-stack card should be friendly, not a dead end — encourage exploring other cities
- The Listen button in the bottom bar should be visible but clearly disabled (grayed out) to preview the voice experience coming in Phase 7
- Bookmark nudge after 10 saves should feel gentle, like a friend suggesting, not a paywall

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `CardSurface`: Container with shadow/rounded corners/themed background — base for recipe cards
- `KindredButton`: 56dp WCAG AAA touch target, primary/secondary/text styles — use for Listen/Watch/Skip buttons
- `EmptyStateView`: ContentUnavailableView with .noRecipes preset — use for empty feed
- `SkeletonShimmer`: Shimmer animation modifier + .redacted — use for loading states
- `ErrorStateView`: Error display component
- `HapticFeedback`: Haptic utility — use for swipe feedback
- Colors: cream/terracotta palette with WCAG AAA contrast ratios
- Typography: .kindredHeading1/2, .kindredBody, .kindredBodyBold, .kindredCaption

### Established Patterns
- TCA (The Composable Architecture) for state management: Reducer + ObservableState
- Apollo iOS GraphQL with generated query types and SQLite cache
- SwiftUI + NavigationStack navigation
- SPM modular packages: FeedFeature, ProfileFeature, DesignSystem, NetworkClient, KindredAPI, AuthClient
- Kingfisher for image loading/caching

### Integration Points
- `FeedReducer`: Placeholder TCA reducer — needs full implementation with recipe loading, swiping, bookmarking
- `FeedView`: Placeholder view with skeleton cards — needs swipe card stack implementation
- `AppReducer`: Feed tab already wired via Scope(state: \.feedState, action: \.feed)
- `ViralRecipesQuery`: Location-based query returning recipe data (name, prepTime, calories, imageUrl, isViral, engagementLoves, etc.)
- `RecipeDetailQuery`: Full recipe with ingredients and steps — for detail screen
- `NetworkClient`: Apollo client with offline-first cache policy

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 05-guest-browsing-feed*
*Context gathered: 2026-03-01*
