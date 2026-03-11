# Phase 7: Voice Playback & Streaming - Context

**Gathered:** 2026-03-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Users listen to recipe instructions narrated in cloned voices with full audio playback controls. Includes streaming from Cloudflare R2, playback UI with play/pause/seek, background playback with lock screen controls, offline caching, and VoiceOver accessibility. Voice cloning/profile creation is Phase 5/6 — this phase consumes existing voice profiles.

</domain>

<decisions>
## Implementation Decisions

### Player UI & Placement
- Bottom mini-player bar (Spotify/Podcasts-style) that persists globally across all screens
- Mini-player shows: play/pause button, thin progress bar, recipe name — tap anywhere to expand
- Expanded view is a bottom sheet (half-screen, ~60% of screen)
- 64dp play button in expanded view only; mini-player uses standard ~44dp tap target
- Visual style matches existing DesignSystem: CardSurface, kindredAccent for controls, same typography (18sp+ labels)
- Speaker name and avatar displayed prominently at top of expanded bottom sheet
- Seek bar shows elapsed time (left) and remaining time (right)
- 15-second skip back and 30-second skip forward buttons in expanded player
- Current step text displayed in expanded bottom sheet alongside controls

### Narration & Step Sync
- One continuous audio file per recipe (not per-step segments)
- Narration includes brief intro (recipe name, total time) then step-by-step instructions — no ingredient readout
- StepTimelineView highlights the current step being narrated (accent border/background), auto-scrolls into view
- Playback speed control: 0.5x, 0.75x, 1x, 1.25x, 1.5x, 2x
- When narration finishes: auto-stop, mini-player fades/dismisses after brief pause

### Voice Profile Selection
- Pre-playback inline card list showing available voice profiles
- Each voice card has a small play button for 3-5 second voice sample preview
- Voice list ordered: user's own voice first, then family members alphabetically
- App remembers last-used voice per recipe — auto-starts with that voice on subsequent listens, shows picker only on first listen
- User can switch voices mid-playback via voice button in expanded player
- Mid-playback voice switch: pause current audio, show spinner on play button, generate/fetch new voice audio, resume from same position
- If no cloned voice profiles exist: show message prompting user to create a voice profile, with navigation to voice cloning flow

### Offline Caching & Downloads
- Auto-cache on first listen — streamed audio automatically saved locally, no explicit download step
- LRU eviction with configurable size cap (e.g., 500MB) — oldest/least recently used audio removed when full
- Cache stores audio per voice per recipe (multiple voices cached for same recipe if listened)
- Subtle icon indicator on Listen button showing cached/available offline status
- Offline + uncached: show friendly error message with guidance ("Listen while connected to save for later")
- Cache management section in app settings: shows total cache size, "Clear Cache" button
- Buffering/loading state: SkeletonShimmer on player controls while initial streaming loads (consistent with app patterns)

### Claude's Discretion
- Mini-player animation/transition details (slide up, fade, etc.)
- Bottom sheet drag-to-dismiss gesture behavior
- Exact step highlighting visual treatment (accent border color, background opacity)
- Step boundary detection approach for highlighting (timestamp markers in audio metadata)
- Audio format choice (MP3, AAC, etc.) and streaming chunk sizes
- Cache size default value
- Lock screen Now Playing artwork and metadata formatting
- AVAudioSession category and routing configuration

</decisions>

<specifics>
## Specific Ideas

- RecipeDetailView already has a disabled "Listen" button in the bottom bar with `.listenTapped` action as no-op — enable and wire this up as the entry point
- Mini-player should feel like Spotify's persistent bottom bar — always accessible, never blocking content
- Voice picker cards should feel personal — name + avatar, not technical/clinical
- Speed control should be a simple cycle button (tap to cycle through speeds) rather than a slider

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `CardSurface`: Container with themed background, shadow, corner radius — use for voice picker cards and player surfaces
- `SkeletonShimmer`: Loading shimmer component — use for buffering state in player
- `EmptyStateView`: Empty state pattern — use for "no voice profiles" prompt
- `KindredButton`: Styled button component — use for player action buttons
- `HapticFeedback`: Haptic patterns — use for play/pause, voice selection interactions
- Typography system: `kindredBody()` (18sp light), `kindredBodyBold()` (18sp medium), `kindredHeading3()` (18sp medium) — meet WCAG AAA requirements

### Established Patterns
- TCA (The Composable Architecture) for state management — new audio player reducer(s) will follow this pattern
- Package-per-feature architecture — voice playback should be its own `VoicePlaybackFeature` package
- `@Dependency` injection for clients — AudioClient, VoiceCacheClient will follow this pattern
- Apollo GraphQL for API data — voice profile data likely fetched via GraphQL
- `accessibilityLabel` and `accessibilityElement(children:)` used throughout — VoiceOver patterns established

### Integration Points
- `RecipeDetailReducer.listenTapped` — existing action to wire up as playback trigger
- `RecipeDetailView` bottom bar — existing Listen button location to transform
- `AppReducer` — mini-player state needs to live at app root level for global persistence
- `RootView` — mini-player overlay needs to be added here for cross-screen visibility
- `StepTimelineView` — needs enhancement to accept and display current step highlighting

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 07-voice-playback-streaming*
*Context gathered: 2026-03-03*
