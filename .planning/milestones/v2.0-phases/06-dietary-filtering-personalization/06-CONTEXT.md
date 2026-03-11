# Phase 6: Dietary Filtering & Personalization - Context

**Gathered:** 2026-03-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Feed adapts to user dietary preferences and learns taste from implicit feedback. Users can filter recipes by dietary tags (vegan, keto, halal, allergies) with filters persisting across sessions. After 50+ interactions, Culinary DNA builds a taste profile from skips/bookmarks and soft-boosts preferred cuisines in feed ranking. Creating accounts, authentication, and server-side profile sync are separate phases.

</domain>

<decisions>
## Implementation Decisions

### Filter Interaction
- Horizontal scrollable chip bar below the city badge, above the swipe card stack
- Chip bar is sticky — stays pinned while user swipes cards
- All 7 dietary tags as chips: Vegan, Vegetarian, Gluten-free, Dairy-free, Keto, Halal, Nut-free
- All chips styled equally — no visual distinction between allergy and diet-choice filters
- Active chip: filled terracotta background with white text. Inactive: outlined with terracotta border
- Multiple filters combine with AND logic (must match ALL selected tags) — matches existing backend filter logic
- Server-side filtering: toggling a chip re-fetches from backend with dietaryTags filter parameter
- X/clear-all chip appears at the end of the bar when any filter is active — one tap resets all active filters
- After filter applied, show subtle text below chips: "Showing X [filter] recipes"
- Empty filter results: show EmptyStateView with "No [filters] recipes nearby. Try removing a filter?" + clear button

### Preference Storage
- Dietary preferences stored in UserDefaults (Set<String> of active dietary tags)
- Active filters = saved preferences (same thing, single concept)
- Auto-save on chip tap — no apply/confirm button needed
- Auto-apply saved preferences on app launch (feed starts pre-filtered if prefs exist)
- Dual access: chip bar in feed AND "Dietary Preferences" section in Me tab
- Me tab shows same chip style as feed (consistent, tappable)
- "Reset Dietary Preferences" button in Me tab only (X chip in feed only clears active session, not saved defaults)
- No first-launch onboarding prompt for dietary preferences — users discover via chips
- Storage designed to be migration-friendly for Phase 8 auth (UserDefaults keys readable for backend sync)

### Culinary DNA Learning
- Signals: skips (left swipe) and bookmarks (right swipe) only — no detail view time or completion tracking
- Tracked attributes: cuisine type affinity + dietary tag patterns
- On-device computation — process GuestBookmark/GuestSkip SwiftData history locally, no backend changes
- Activation threshold: 50+ interactions (per PERS-01 requirement)
- Ranking influence: soft boost — ~60% preferred cuisines, ~40% discovery/variety
- Bookmark weight = 2x skip weight (bookmarks are stronger positive signals)
- Weighted decay for skips: takes 5-10 skips of same cuisine to noticeably reduce affinity
- Recency-weighted: recent interactions carry more weight than older ones (taste evolves)

### Feed Adaptation UX
- "For You" badge on every recipe boosted by Culinary DNA (not just first few per session)
- "For You" badge coexists with VIRAL badge — separate placement (e.g., bottom-left vs top-right)
- Me tab: "Your Culinary DNA" section with horizontal affinity bars (top 3-5 cuisines with percentages)
- Before threshold: progress indicator in Me tab — "Culinary DNA: Learning... (23/50 interactions)"
- On activation: one-time special card in feed — "Your Culinary DNA is ready! Your feed is now personalized." (dismissible)
- After activation: Me tab shows cuisine affinity bars instead of progress indicator

### Claude's Discretion
- Exact spacing/padding for chip bar layout
- Loading skeleton during filter re-fetch
- Exact recency decay algorithm (exponential vs linear)
- "For You" badge visual design (color, size, placement details)
- Culinary DNA affinity bar styling and animation
- Activation card illustration/design
- Error handling for failed filter fetches

</decisions>

<specifics>
## Specific Ideas

- Filter chip bar should feel like food delivery apps (DoorDash/UberEats style horizontal chips)
- "For You" badge similar to the existing VIRAL badge pattern — small, non-intrusive, informational
- Culinary DNA progress in Me tab creates a light gamification loop encouraging engagement
- Activation moment should feel celebratory — the feed "knows you" now

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `RecipeCard.dietaryTags: [String]` — dietary info already flows from backend GraphQL
- `GuestSessionClient` — SwiftData persistence for bookmarks/skips with timestamps (raw DNA data)
- `GuestBookmark` / `GuestSkip` SwiftData models — include `createdAt` timestamps for recency weighting
- `ViralBadge` component — pattern for "For You" badge implementation
- `EmptyStateView` — reusable for empty filter results
- `CardSurface` — for the DNA activation card in feed
- `KindredButton` — for clear filter actions
- Design system: `Colors` (terracotta/cream palette), `Typography`, `Spacing`

### Established Patterns
- TCA architecture: FeedReducer handles state/actions — extend with filter state and DNA state
- SwiftData for local persistence (GuestSessionClient pattern)
- Apollo GraphQL with cache-first fetching — extend queries with filter parameters
- SPM modular packages — FeedFeature package contains all feed-related code
- `@Dependency` injection for testability (GuestSessionClient, NetworkClient)

### Integration Points
- `FeedReducer.State` — add `activeDietaryFilters: Set<String>` and Culinary DNA state
- `ViralRecipesQuery` / `RecipesQuery` — add `filters` parameter to pass dietaryTags
- Backend `FeedFiltersInput.dietaryTags` — already supports AND filtering, just needs iOS to send it
- `ProfileReducer` (Me tab) — add dietary preferences section and Culinary DNA visualization
- `RecipeCardView` — add "For You" badge alongside existing VIRAL badge
- `FeedView` — add chip bar between city badge and card stack
- `NetworkClient/GraphQL/FeedQueries.graphql` — update queries with filter input

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 06-dietary-filtering-personalization*
*Context gathered: 2026-03-03*
