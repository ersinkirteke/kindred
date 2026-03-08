# Phase 10: Accessibility & Polish - Context

**Gathered:** 2026-03-08
**Status:** Ready for planning

<domain>
## Phase Boundary

App meets WCAG AAA standards, handles offline gracefully, and is production-ready for App Store submission. Includes full bilingual localization (English + Turkish), performance polish, and consistent error handling across all screens. No new features — this phase audits, polishes, and prepares everything built in Phases 4-9.

</domain>

<decisions>
## Implementation Decisions

### Dynamic Type Strategy
- Keep Kindred's custom type scale (34/28/22/18/14pt) but wrap with `@ScaledMetric` so sizes scale proportionally at accessibility sizes
- 14pt minimum for all text — no text in the app below 14pt even at default Dynamic Type (bump `kindredSmall` from 12pt to 14pt)
- Support full AX1-AX5 range — no `.dynamicTypeSize()` cap at the app root
- Icons scale with text via `@ScaledMetric` (clock, flame, heart metadata icons)
- RecipeCardView: remove fixed 400pt height, card grows to fit content. Card becomes scrollable if content overflows at AX sizes
- Single card mode at AX1+: hide peeking cards behind the top card. Only top card visible, VoiceOver-friendly
- Action buttons (Skip/Listen/Bookmark): grow with `@ScaledMetric` proportionally at AX sizes
- ExpandedPlayerView controls: stack vertically at AX sizes (detect with `@Environment(\.dynamicTypeSize)`)
- DietaryChipBar: wrap to multiple rows at AX sizes (vertical flow layout instead of horizontal scroll)
- PaywallView: stack subscription tiers vertically at AX sizes
- Onboarding steps: add scroll-for-more indicators (gradient fade or arrow) when content overflows at AX sizes

### Color Contrast
- Trust existing Asset Catalog values (already declare WCAG AAA 7:1 ratios) + manual contrast audit of all color pairings
- No programmatic contrast validation tests — manual audit sufficient

### VoiceOver Navigation
- Custom `.accessibilityAction(named:)` is enough for swipe card interactions — no rotor needed
- Announce all playback state changes: "Now playing: [Recipe] by [Voice]", "Paused", "Track N of M"
- Recipe detail reading order: top-down natural (name → image → metadata → ingredients → steps → voice player)
- Recipe images: use recipe name as alt text ("Photo of Pasta Carbonara")
- Full onboarding step descriptions: each step has `.accessibilityHint` explaining purpose
- No in-app accessibility settings section — respect iOS system settings automatically
- Reduce Motion: card swipes become fade-out/fade-in, hero transitions become crossfade, springs become linear
- MiniPlayerView: single combined VoiceOver element with custom actions (play/pause, expand, dismiss)
- Badges (Viral, ForYou): included in combined card accessibility label, not separate elements
- Location pill: convert from `.onTapGesture` to proper `Button` for VoiceOver and keyboard semantics
- Tab bar: labels + dynamic badge count in accessibility value ("Bookmarks, 5 saved recipes")
- VoiceOver announces connectivity changes ("You're offline", "Back online")

### Offline Resilience
- Recipe detail works offline via Apollo's SQLite cache (cacheFirst policy). If not cached: "Available when online" placeholder
- Voice narration: disable Listen button when offline with message "Voice narration requires internet"
- Consistent orange offline banner at top of every screen (Feed, Detail, Profile, Bookmarks) — shared component
- Auto-refresh all screens when connectivity returns (Feed refreshes silently, Detail reloads if stale, Profile syncs)
- Pre-cache bookmarked recipes: when bookmarked, prefetch detail data + hero image via Kingfisher for guaranteed offline viewing
- Paywall: show cached subscription status only when offline. Disable purchase buttons with "Go online to manage subscription"
- No cache info shown — offline works silently without displaying cache stats
- App-level shared connectivity state in AppReducer that all child features observe (single source of truth)
- Toast notification for offline action attempts: "This requires internet connection" — brief, non-blocking, 3-second dismiss
- VoiceOver announces connectivity changes via UIAccessibility.post

### App Store Submission
- Firebase Analytics only — no ATT consent needed unless ad network requires it
- Privacy nutrition labels: minimal data (location/city, dietary preferences, bookmarks). Analytics not linked to identity
- Create all metadata: App Store description, keywords, screenshots (manual). Category: Food & Drink (primary only)
- Age rating: 4+ (Everyone)
- Sign in with Apple: already implemented via Clerk
- Subscription management + Terms of Service links in Profile settings section
- No in-app promotion of accessibility features — they just work silently
- English + Turkish bilingual support for initial launch

### Localization Architecture
- One app-level String Catalog (.xcstrings) in the main app target — all strings extracted here
- Use `String(localized:)` initializer for all user-facing strings. Xcode auto-extracts into String Catalog
- AI-generated Turkish translations (Claude generates, user reviews and corrects)
- Follow iOS system language — no in-app language switcher
- Recipe content: backend provides Turkish content. App displays whatever language backend returns
- Verify Turkish layout overflow (Turkish words ~30% longer than English on average)
- LTR only for now — no RTL consideration since English and Turkish are both LTR

### Performance & Launch
- Cold launch target: under 1 second to first meaningful content
- Launch screen: static LaunchScreen.storyboard with app logo on warm cream background
- Kingfisher: use default cache settings (no custom limits)
- MetricKit integration for production performance monitoring (launch time, hangs, disk writes)
- Firebase Crashlytics for crash reporting (richer than MetricKit alone)
- Prefetch top 3 card details (up from current 1) for smoother swipe-through experience
- Optimize binary size: strip debug symbols from release, upload dSYM to Crashlytics separately
- Minimum iOS: keep 17.0 (Clerk SDK requirement)
- Background app refresh: register BGAppRefreshTask to periodically fetch new recipes

### Error Handling Polish
- All error states use ErrorStateView consistently across every screen
- All empty states use EmptyStateView consistently (icon + message + optional action)
- Migrate all print() statements to os.log Logger with proper categories
- User-friendly error messages only — never show raw error text to users
- Auto-retry once silently, then show ErrorStateView with manual retry button if still fails
- Firebase Crashlytics for crash reports
- No global error boundary — trust SwiftUI, Crashlytics catches actual crashes

### Haptics & Motion
- Expand haptics to: bookmark success, error states, playback start/stop, filter toggle, onboarding step completion
- Keep haptics always, even when Reduce Motion is on (haptics are tactile, not visual)
- Hero transition under Reduce Motion: crossfade instead of .zoom
- Shimmer loading under Reduce Motion: static gray placeholder (no animation)

### Claude's Discretion
- Exact `@ScaledMetric` relativeTo parameters for each typography level
- Specific scroll-for-more indicator design (gradient vs arrow)
- Toast notification component implementation details
- Logger category naming conventions
- Exact BGAppRefreshTask scheduling interval
- MetricKit payload handling and reporting flow

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `DesignSystem/Typography.swift`: Custom font scale (34/28/22/18/14/12pt) — needs @ScaledMetric wrapping
- `DesignSystem/Colors.swift`: Semantic colors with WCAG AAA claims — needs manual audit verification
- `DesignSystem/Components/ErrorStateView.swift`: Error state component — use consistently everywhere
- `DesignSystem/Components/EmptyStateView.swift`: Empty state component — standardize across all screens
- `DesignSystem/Components/KindredButton.swift`: Already has 56dp touch targets — add @ScaledMetric
- `DesignSystem/Components/SkeletonShimmer.swift`: Shimmer animation — add Reduce Motion static fallback
- `DesignSystem/Components/CardSurface.swift`: Card wrapper — reuse for consistent card styling
- `DesignSystem/Utilities/HapticFeedback.swift`: Haptic utility — expand with new feedback types

### Established Patterns
- TCA (The Composable Architecture) for all state management
- Apollo iOS with cacheFirst for offline-capable data fetching
- Kingfisher for image loading and caching
- `@Dependency` injection for all external services
- VoiceOver: `.accessibilityElement(children: .combine)` + `.accessibilityLabel` + `.accessibilityAction(named:)` pattern in RecipeCardView
- `UIAccessibility.post(notification: .announcement)` for dynamic VoiceOver announcements in FeedView
- `networkMonitorClient` for connectivity monitoring (currently only in FeedReducer)

### Integration Points
- `AppReducer` / `AppDelegate.swift`: App-level connectivity state needs to live here
- `FeedReducer.swift`: Already has isOffline, connectivityChanged, networkMonitor — model for other features
- All view files: Need String(localized:) extraction for hardcoded strings
- `project.yml`: Build settings for release optimization, LaunchScreen configuration
- `Sources/Info.plist`: Privacy usage descriptions, ATT if needed

</code_context>

<specifics>
## Specific Ideas

- RecipeCardView already has excellent VoiceOver support (combined element, named actions, descriptive labels) — use as the model for all other views
- FeedView's VoiceOver announcements for location change and card transitions — extend this pattern to playback state changes
- The offline banner in FeedView is a good starting point — extract to shared component in DesignSystem

</specifics>

<deferred>
## Deferred Ideas

- AI-generated image descriptions for recipe photos — future enhancement, requires backend support
- In-app language switcher — future if user demand exists
- RTL layout support — only needed when Arabic/Hebrew languages added
- Download-for-offline voice narration — separate feature, significant scope
- Programmatic contrast ratio validation tests — can add in maintenance phase
- In-app accessibility settings section — not needed, iOS handles this

</deferred>

---

*Phase: 10-accessibility-polish*
*Context gathered: 2026-03-08*
