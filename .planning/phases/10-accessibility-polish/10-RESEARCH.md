# Phase 10: Accessibility & Polish - Research

**Researched:** 2026-03-08
**Domain:** iOS accessibility (WCAG AAA), localization, app performance, App Store submission
**Confidence:** HIGH

## Summary

Phase 10 focuses on achieving WCAG AAA accessibility standards, implementing bilingual localization (English + Turkish), optimizing app performance with MetricKit monitoring, ensuring robust offline resilience, and completing App Store submission requirements. This is a polish and audit phase that builds on all features implemented in Phases 4-9, not introducing new functionality but ensuring production-readiness.

The research reveals that SwiftUI provides strong native accessibility support through `@ScaledMetric` for Dynamic Type scaling, `@Environment(\.accessibilityReduceMotion)` for motion sensitivity, and comprehensive VoiceOver modifiers. iOS 17+ String Catalogs (.xcstrings) streamline localization with automatic string extraction and support for plurals. MetricKit offers production performance monitoring without third-party dependencies. The existing codebase already has excellent accessibility patterns (RecipeCardView's VoiceOver implementation) and design system components that can be extended.

**Primary recommendation:** Build on existing accessibility patterns (RecipeCardView's combined VoiceOver element with custom actions), wrap all typography with `@ScaledMetric` for AX1-AX5 support, use SwiftUI String Catalogs for bilingual localization with AI-generated Turkish translations, integrate MetricKit for launch time monitoring, and create consistent offline states across all features using the established FeedReducer connectivity pattern.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Dynamic Type Strategy:**
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

**Color Contrast:**
- Trust existing Asset Catalog values (already declare WCAG AAA 7:1 ratios) + manual contrast audit of all color pairings
- No programmatic contrast validation tests — manual audit sufficient

**VoiceOver Navigation:**
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

**Offline Resilience:**
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

**App Store Submission:**
- Firebase Analytics only — no ATT consent needed unless ad network requires it
- Privacy nutrition labels: minimal data (location/city, dietary preferences, bookmarks). Analytics not linked to identity
- Create all metadata: App Store description, keywords, screenshots (manual). Category: Food & Drink (primary only)
- Age rating: 4+ (Everyone)
- Sign in with Apple: already implemented via Clerk
- Subscription management + Terms of Service links in Profile settings section
- No in-app promotion of accessibility features — they just work silently
- English + Turkish bilingual support for initial launch

**Localization Architecture:**
- One app-level String Catalog (.xcstrings) in the main app target — all strings extracted here
- Use `String(localized:)` initializer for all user-facing strings. Xcode auto-extracts into String Catalog
- AI-generated Turkish translations (Claude generates, user reviews and corrects)
- Follow iOS system language — no in-app language switcher
- Recipe content: backend provides Turkish content. App displays whatever language backend returns
- Verify Turkish layout overflow (Turkish words ~30% longer than English on average)
- LTR only for now — no RTL consideration since English and Turkish are both LTR

**Performance & Launch:**
- Cold launch target: under 1 second to first meaningful content
- Launch screen: static LaunchScreen.storyboard with app logo on warm cream background
- Kingfisher: use default cache settings (no custom limits)
- MetricKit integration for production performance monitoring (launch time, hangs, disk writes)
- Firebase Crashlytics for crash reporting (richer than MetricKit alone)
- Prefetch top 3 card details (up from current 1) for smoother swipe-through experience
- Optimize binary size: strip debug symbols from release, upload dSYM to Crashlytics separately
- Minimum iOS: keep 17.0 (Clerk SDK requirement)
- Background app refresh: register BGAppRefreshTask to periodically fetch new recipes

**Error Handling Polish:**
- All error states use ErrorStateView consistently across every screen
- All empty states use EmptyStateView consistently (icon + message + optional action)
- Migrate all print() statements to os.log Logger with proper categories
- User-friendly error messages only — never show raw error text to users
- Auto-retry once silently, then show ErrorStateView with manual retry button if still fails
- Firebase Crashlytics for crash reports
- No global error boundary — trust SwiftUI, Crashlytics catches actual crashes

**Haptics & Motion:**
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

### Deferred Ideas (OUT OF SCOPE)

- AI-generated image descriptions for recipe photos — future enhancement, requires backend support
- In-app language switcher — future if user demand exists
- RTL layout support — only needed when Arabic/Hebrew languages added
- Download-for-offline voice narration — separate feature, significant scope
- Programmatic contrast ratio validation tests — can add in maintenance phase
- In-app accessibility settings section — not needed, iOS handles this
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| ACCS-05 | Color contrast meets WCAG AAA 7:1 ratio | Manual audit process documented; existing Asset Catalog claims verified via WebAIM Contrast Checker tool |
</phase_requirements>

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | Declarative UI framework | Apple's modern UI framework with built-in accessibility support via property wrappers and environment values |
| `@ScaledMetric` | iOS 14+ | Dynamic Type scaling for custom values | SwiftUI property wrapper that automatically scales numeric values (CGFloat, Double) based on Dynamic Type settings; essential for AX1-AX5 support |
| `@Environment(\.accessibilityReduceMotion)` | iOS 14+ | Detect Reduce Motion setting | SwiftUI environment property that returns Boolean indicating if user has enabled Reduce Motion; integrates with accessibility settings |
| String Catalog (.xcstrings) | iOS 17+ | App localization | Apple's modern localization system that auto-extracts strings during build, replaces .strings/.stringsdict files, single-file format |
| MetricKit (MXMetricManager) | iOS 13+ | Production performance monitoring | Apple's first-party framework for collecting real-world app launch time, hangs, crashes, and resource usage from user devices; no third-party dependency |
| os.log Logger | iOS 14+ | Structured logging | Apple's unified logging system with subsystems/categories; replaces print() with performance-optimized async logging that respects privacy |
| Firebase Crashlytics | 11.0.0+ | Crash reporting | Industry-standard crash reporting with symbolicated stack traces; already integrated in project for analytics |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Apollo iOS | 2.0.6 | GraphQL client with SQLite cache | Already integrated; supports offline-first with `cacheFirst` policy for recipe detail data persistence |
| Kingfisher | 8.0.0+ | Image loading and caching | Already integrated; `ImagePrefetcher` API for prefetching top 3 card details before swipe |
| UIAccessibility | iOS 13+ | Accessibility APIs | Use `UIAccessibility.post(notification: .announcement, argument: String)` for dynamic VoiceOver announcements on connectivity changes |
| BackgroundTasks (BGAppRefreshTask) | iOS 13+ | Background fetch | Schedule periodic recipe feed refreshes; system allocates ~30 seconds execution time, aligns with app usage patterns |

### Installation

All dependencies already in project via Swift Package Manager (project.yml). No new packages required.

## Architecture Patterns

### Recommended Project Structure

Already established in Kindred project:

```
Kindred/
├── Sources/
│   ├── App/
│   │   ├── AppDelegate.swift        # Audio session, MetricKit subscriber
│   │   ├── AppReducer.swift         # App-level connectivity state
│   │   └── Info.plist               # Privacy strings, BGTaskScheduler IDs
│   └── Resources/
│       ├── Assets.xcassets/         # Color assets with WCAG AAA values
│       ├── Localizable.xcstrings    # String Catalog (to be created)
│       └── LaunchScreen.storyboard  # Static launch screen
├── Packages/
│   ├── DesignSystem/
│   │   ├── Typography.swift         # Typography system (needs @ScaledMetric wrapping)
│   │   ├── Colors.swift             # Semantic colors (audit WCAG AAA)
│   │   └── Components/
│   │       ├── ErrorStateView.swift
│   │       ├── EmptyStateView.swift
│   │       ├── OfflineBanner.swift  # (to be created)
│   │       └── ToastNotification.swift # (to be created)
│   └── {Feature}Feature/
│       └── Sources/
│           └── Utilities/
│               └── Logger+{Feature}.swift # Feature-specific logger extensions
```

### Pattern 1: @ScaledMetric for Dynamic Type

**What:** Wrap all fixed-size numeric values (fonts, spacing, icons) with `@ScaledMetric` property wrapper to scale proportionally with Dynamic Type settings.

**When to use:** Anytime you have a fixed CGFloat/Double that should grow at accessibility sizes (AX1-AX5).

**Example:**

```swift
// Source: https://www.avanderlee.com/swiftui/scaledmetric-dynamic-type-support/
// https://sarunw.com/posts/swiftui-scaledmetric/

// Before: Fixed 18pt body text
static func kindredBody() -> Font {
    .system(size: 18, weight: .light, design: .default)
}

// After: Scales with Dynamic Type
public extension Font {
    static func kindredBody() -> Font {
        // Use @ScaledMetric in view that uses this font
        .system(size: scaledBodySize, weight: .light, design: .default)
    }
}

// In view:
struct RecipeDetailView: View {
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18

    var body: some View {
        Text(recipe.description)
            .font(.system(size: bodySize, weight: .light))
    }
}

// For icons and spacing:
struct MetadataIcon: View {
    @ScaledMetric(relativeTo: .caption) private var iconSize: CGFloat = 14

    var body: some View {
        Image(systemName: "clock")
            .font(.system(size: iconSize))
    }
}
```

**relativeTo parameter options:**
- `.largeTitle` → 34pt base (kindredLargeTitle)
- `.title` → 28pt base (kindredHeading1)
- `.title2` → 22pt base (kindredHeading2)
- `.headline` → 18pt base (kindredHeading3, kindredBody)
- `.caption` → 14pt base (kindredCaption)
- `.caption2` → 12pt base (kindredSmall, but bump to 14pt minimum)

### Pattern 2: Reduce Motion with @Environment

**What:** Detect user's Reduce Motion setting and swap animations for static/simple transitions.

**When to use:** Any view with animations (springs, hero transitions, shimmer effects).

**Example:**

```swift
// Source: https://www.hackingwithswift.com/quick-start/swiftui/how-to-detect-the-reduce-motion-accessibility-setting
// https://www.createwithswift.com/ensure-visual-accessibility-supporting-reduced-motion-preferences-in-swiftui/

struct RecipeCardView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        cardContent
            .transition(
                reduceMotion
                    ? .opacity  // Fade only
                    : .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    )
            )
            .animation(
                reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.6),
                value: offset
            )
    }
}

// Hero transition:
if #available(iOS 18.0, *) {
    heroImageView
        .matchedTransitionSource(id: recipe.id, in: heroNamespace) {
            if reduceMotion {
                .crossfade  // Simple fade instead of zoom
            } else {
                .zoom
            }
        }
}

// Shimmer loading:
struct SkeletonShimmer: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        if reduceMotion {
            // Static gray placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.kindredDivider)
        } else {
            // Animated shimmer
            shimmering(
                active: true,
                duration: 1.5,
                bounce: false
            )
        }
    }
}
```

**Important:** Haptics are NOT affected by Reduce Motion (they're tactile, not visual). Per user constraint: "Keep haptics always, even when Reduce Motion is on."

### Pattern 3: String Catalog Localization

**What:** Use `String(localized:)` initializer for all user-facing strings. Xcode automatically extracts strings into Localizable.xcstrings during build.

**When to use:** Every Text(), Label(), Button(), accessibility string in the app.

**Example:**

```swift
// Source: https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog
// https://medium.com/@hyleedevelop/ios-localization-tutorial-in-swiftui-using-string-catalog-9307953d8082

// Before: Hardcoded English strings
Text("Listen")
Button("Bookmark") { ... }
.accessibilityLabel("Skip this recipe")

// After: Localized strings
Text(String(localized: "Listen"))
Button(String(localized: "Bookmark")) { ... }
.accessibilityLabel(String(localized: "accessibility.recipe_card.skip"))

// With interpolation:
Text(String(localized: "recipe.time_minutes \(minutes)"))

// Plurals (handled automatically by String Catalog):
String(localized: "bookmarks.count \(count)")
// In .xcstrings:
// "bookmarks.count" → Plural rule:
//   zero: "No bookmarks"
//   one: "1 bookmark"
//   other: "%lld bookmarks"

// In Localizable.xcstrings (Xcode auto-generates):
{
  "sourceLanguage": "en",
  "strings": {
    "Listen": {
      "localizations": {
        "en": { "stringUnit": { "value": "Listen" } },
        "tr": { "stringUnit": { "value": "Dinle" } }
      }
    }
  },
  "version": "1.0"
}
```

**String Catalog best practices:**
1. Use descriptive keys for accessibility strings: `accessibility.{view}.{action}` (e.g., `accessibility.recipe_card.skip`)
2. Use interpolation for dynamic values: `\(variableName)` in string
3. Let Xcode extract during build — no manual .xcstrings editing during development
4. Review .xcstrings file after first build to add Turkish translations
5. Use Comments field in String Catalog to provide context for translators

### Pattern 4: VoiceOver Combined Element with Custom Actions

**What:** Combine multi-element cards into single VoiceOver element with custom swipe actions for better navigation flow.

**When to use:** Cards with multiple interactive areas (Recipe card, Profile sections, Ad cards).

**Example (already implemented in RecipeCardView):**

```swift
// Source: Existing RecipeCardView.swift
// https://www.avanderlee.com/swiftui/voiceover-navigation-improvement-tips/

VStack {
    heroImage
    recipeName
    metadata
}
.accessibilityElement(children: .combine)
.accessibilityLabel(accessibilityLabelText)  // "Pasta Carbonara, 30 minutes, 450 calories, Viral recipe"
.accessibilityAction(named: "Bookmark") {
    onSwipe(.right)
}
.accessibilityAction(named: "Skip") {
    onSwipe(.left)
}
.accessibilityAction(named: "View details") {
    onTap()
}

private var accessibilityLabelText: String {
    var label = recipe.name
    if let time = recipe.totalTime {
        label += ", \(time) minutes"
    }
    if let calories = recipe.calories {
        label += ", \(calories) calories"
    }
    if recipe.isViral {
        label += ", Viral recipe"
    }
    if isPersonalized {
        label += ", Personalized for you"
    }
    return label
}
```

**Pattern applies to:**
- MiniPlayerView: combine play button + recipe name + voice name into single element with "Play", "Pause", "Expand", "Dismiss" actions
- Tab bar items: dynamic badge in accessibility value ("Bookmarks, 5 saved recipes")
- DietaryChip: combine icon + label, action named "Toggle {dietary preference}"

### Pattern 5: VoiceOver Announcements for State Changes

**What:** Use `UIAccessibility.post(notification:argument:)` to announce dynamic state changes (offline/online, playback state).

**When to use:** Non-visual state changes that VoiceOver users need to know about immediately.

**Example:**

```swift
// Source: Existing FeedView VoiceOver announcement pattern
// https://developer.apple.com/documentation/uikit/uiaccessibility

// In AppReducer connectivity change:
case .connectivityChanged(let isOffline):
    state.isOffline = isOffline

    // Announce to VoiceOver
    let message = isOffline
        ? String(localized: "accessibility.offline_announcement")  // "You're offline"
        : String(localized: "accessibility.online_announcement")   // "Back online"

    UIAccessibility.post(
        notification: .announcement,
        argument: message
    )
    return .none

// In VoicePlaybackReducer playback state:
case .playbackStateChanged(let state):
    switch state {
    case .playing:
        if let recipe = currentPlayback?.recipe, let voice = currentPlayback?.voice {
            UIAccessibility.post(
                notification: .announcement,
                argument: String(localized: "accessibility.now_playing \(recipe.name) \(voice.name)")
            )
        }
    case .paused:
        UIAccessibility.post(
            notification: .announcement,
            argument: String(localized: "accessibility.paused")
        )
    default:
        break
    }
```

### Pattern 6: os.log Logger with Subsystems and Categories

**What:** Replace all `print()` statements with structured `Logger` instances organized by subsystem (bundle ID) and category (feature area).

**When to use:** All logging in the app.

**Example:**

```swift
// Source: https://www.avanderlee.com/debugging/oslog-unified-logging/
// https://swiftwithmajid.com/2022/04/06/logging-in-swift/

import OSLog

// In each feature package (e.g., FeedFeature/Sources/Utilities/Logger+Feed.swift):
extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!

    // Feature-specific categories
    static let feed = Logger(subsystem: subsystem, category: "feed")
    static let personalization = Logger(subsystem: subsystem, category: "personalization")
    static let location = Logger(subsystem: subsystem, category: "location")
}

// Usage in FeedReducer:
import OSLog

case .fetchRecipes:
    Logger.feed.info("Fetching recipes for location: \(state.selectedCity?.name ?? "unknown")")
    // ...

case .recipeFetchFailed(let error):
    Logger.feed.error("Recipe fetch failed: \(error.localizedDescription, privacy: .public)")
    // ...

// In VoicePlaybackReducer:
extension Logger {
    static let voicePlayback = Logger(subsystem: subsystem, category: "voice-playback")
    static let audioCache = Logger(subsystem: subsystem, category: "audio-cache")
}

Logger.voicePlayback.debug("Starting playback for recipe: \(recipe.id, privacy: .private)")
Logger.audioCache.notice("Cache hit for audio URL: \(url, privacy: .private)")

// Log levels (in order of severity):
// .debug   → Development only, not persisted
// .info    → Informational, not persisted by default
// .notice  → Informational, persisted to disk
// .warning → Warning, persisted to disk
// .error   → Error, persisted to disk
// .fault   → Critical error, persisted to disk
```

**Subsystem and category naming conventions:**
- **Subsystem:** Use `Bundle.main.bundleIdentifier` (e.g., `com.ersinkirteke.kindred`)
- **Categories:** Lowercase kebab-case by feature area:
  - `feed` — FeedReducer, RecipeCardView
  - `personalization` — PersonalizationClient, CulinaryDNA
  - `location` — LocationClient, LocationPicker
  - `voice-playback` — VoicePlaybackReducer, AudioPlayerManager
  - `voice-upload` — VoiceUploadReducer
  - `auth` — AuthReducer, SignInClient
  - `profile` — ProfileReducer
  - `monetization` — SubscriptionClient, AdClient
  - `network` — NetworkClient, Apollo cache
  - `app-lifecycle` — AppDelegate, AppReducer

**Privacy annotations:**
- `.private` (default) — Hides value in logs ("Cache hit for audio URL: <private>")
- `.public` — Shows value in logs (use for non-sensitive data like error codes)

### Pattern 7: MetricKit Performance Monitoring

**What:** Subscribe to `MXMetricManager` in AppDelegate to receive daily aggregated metrics (launch time, hangs, crashes) from production users.

**When to use:** Production monitoring only (MetricKit only works in TestFlight/App Store builds, not Debug).

**Example:**

```swift
// Source: https://www.avanderlee.com/swift/metrickit-launch-time/
// https://swiftwithmajid.com/2025/12/09/monitoring-app-performance-with-metrickit/

import MetricKit

// In AppDelegate.swift:
class AppDelegate: NSObject, UIApplicationDelegate, MXMetricManagerSubscriber {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Subscribe to MetricKit
        MXMetricManager.shared.add(self)
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        MXMetricManager.shared.remove(self)
    }

    // MARK: - MXMetricManagerSubscriber

    // Called at most once per day with metrics from previous 24 hours
    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            // Launch metrics
            if let launchMetrics = payload.applicationLaunchMetrics {
                let launchTime = launchMetrics.histogrammedTimeToFirstDraw.averageValue
                Logger.performance.notice("Average launch time: \(launchTime.converted(to: .seconds).value)s")

                // Send to analytics or crash reporting
                Analytics.logEvent("metric_launch_time", parameters: [
                    "average_seconds": launchTime.converted(to: .seconds).value
                ])
            }

            // Hang metrics
            if let hangMetrics = payload.applicationHangTimeMetrics {
                let hangCount = hangMetrics.cumulativeHangTime.histogramNumBuckets
                Logger.performance.warning("Hang count: \(hangCount)")
            }

            // Exit metrics (crashes, watchdog kills, OOMs)
            if let exitMetrics = payload.applicationExitMetrics {
                let backgroundExits = exitMetrics.backgroundExitData
                Logger.performance.error("Background exits: \(backgroundExits)")
            }
        }
    }

    // Called when diagnostics are available (crashes)
    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            if let crashDiagnostic = payload.crashDiagnostics?.first {
                // Already sent to Crashlytics, just log
                Logger.performance.fault("Crash detected: \(crashDiagnostic.callStackTree)")
            }
        }
    }
}

// Add Logger category for performance:
extension Logger {
    static let performance = Logger(subsystem: subsystem, category: "performance")
}
```

**MetricKit key points:**
- Metrics delivered **at most once per day**, containing data from previous 24 hours
- First payload arrives **24 hours after first app launch**
- Only works in **TestFlight and App Store builds** (not Debug, not Simulator)
- Metrics are aggregated across all users, not per-user
- Combine with Crashlytics for richer crash reporting (MetricKit provides aggregated data, Crashlytics provides individual crash reports with full symbolication)

### Pattern 8: BGAppRefreshTask Background Fetch

**What:** Register background task to periodically fetch new recipes when app is not running, so fresh content is ready when user opens app.

**When to use:** Social media feeds, news apps, recipe apps where fresh content is valuable.

**Example:**

```swift
// Source: https://uynguyen.github.io/2020/09/26/Best-practice-iOS-background-processing-Background-App-Refresh-Task/
// https://developer.apple.com/documentation/backgroundtasks/choosing-background-strategies-for-your-app

// 1. Register task identifier in Info.plist:
// <key>BGTaskSchedulerPermittedIdentifiers</key>
// <array>
//     <string>com.ersinkirteke.kindred.recipe-refresh</string>
// </array>

// 2. Register handler in AppDelegate:
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Register background task handler
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.ersinkirteke.kindred.recipe-refresh",
            using: nil
        ) { task in
            self.handleRecipeRefresh(task: task as! BGAppRefreshTask)
        }

        return true
    }

    // 3. Schedule task (call when app enters background):
    func applicationDidEnterBackground(_ application: UIApplication) {
        scheduleRecipeRefresh()
    }

    private func scheduleRecipeRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.ersinkirteke.kindred.recipe-refresh")

        // System allows minimum 15 minutes, but actual scheduling depends on:
        // - User's app usage patterns (frequently used apps get more regular scheduling)
        // - Battery level
        // - Network conditions
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)  // 15 minutes

        do {
            try BGTaskScheduler.shared.submit(request)
            Logger.background.info("Recipe refresh task scheduled")
        } catch {
            Logger.background.error("Failed to schedule background task: \(error)")
        }
    }

    // 4. Handle background fetch (max 30 seconds):
    private func handleRecipeRefresh(task: BGAppRefreshTask) {
        // Schedule next refresh
        scheduleRecipeRefresh()

        // Perform fetch with timeout
        Task {
            do {
                // Fetch new recipes (use existing FeedReducer logic)
                try await fetchLatestRecipes()
                Logger.background.notice("Background recipe refresh succeeded")
                task.setTaskCompleted(success: true)
            } catch {
                Logger.background.error("Background recipe refresh failed: \(error)")
                task.setTaskCompleted(success: false)
            }
        }

        // Set expiration handler (called if task runs too long)
        task.expirationHandler = {
            Logger.background.warning("Background task expired")
            task.setTaskCompleted(success: false)
        }
    }
}

// Testing in Simulator (background tasks don't run automatically):
// e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.ersinkirteke.kindred.recipe-refresh"]
```

**BGAppRefreshTask constraints:**
- System allocates **~30 seconds** execution time per launch
- Minimum interval: **15 minutes**, but system may delay to 45 min - 2 hours based on usage patterns
- **Force-quit kills all background tasks** — if user swipes app away, tasks stop until app reopened
- Scheduling is **best-effort** — system decides when to run based on battery, network, app usage
- Use for **quick operations** like fetching JSON feed, not heavy processing

### Anti-Patterns to Avoid

- **Fixed font sizes without @ScaledMetric:** Never use `.font(.system(size: 18))` directly in views. Always wrap size with `@ScaledMetric` or use semantic Font styles (`.body`, `.headline`) that scale automatically.
- **Hardcoded strings:** Never use `Text("Listen")` or `Button("Bookmark")`. Always use `String(localized:)` even for English-only MVP (enables future localization without refactor).
- **print() debugging:** Never use `print()` in production code. Use `Logger` with proper categories and privacy annotations.
- **Animations without Reduce Motion check:** Never assume all users want animations. Always check `@Environment(\.accessibilityReduceMotion)` and provide static/simple fallback.
- **Separate VoiceOver elements for composite cards:** Don't make each card element (image, title, metadata) a separate VoiceOver focus target. Combine into single element with `.accessibilityElement(children: .combine)` and custom actions.
- **Ignoring offline state:** Never fetch-only without checking `isOffline` state. Show offline banner + cached content, disable network-dependent actions.
- **Sensitive data in logs:** Never log user tokens, passwords, personal data without `.privacy: .private` annotation.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Color contrast validation | Custom contrast ratio calculator, programmatic tests | Manual audit with WebAIM Contrast Checker + Asset Catalog documentation | User constraint: "No programmatic contrast validation tests — manual audit sufficient." Tool: https://webaim.org/resources/contrastchecker/ |
| Localization extraction | Custom string parser, .strings file generator | Xcode String Catalog (.xcstrings) with automatic extraction | Xcode 15+ auto-extracts `String(localized:)` during build, handles plurals/variables, single-file format, backward compatible |
| Performance monitoring | Custom launch time tracker, analytics events | MetricKit (MXMetricManager) | Apple's first-party framework; collects real-world metrics from production users; aggregates launch time, hangs, crashes; no third-party dependency |
| Crash reporting | Custom crash handler, stack trace parser | Firebase Crashlytics (already integrated) | Industry-standard; symbolicated stack traces; integrates with dSYM upload; richer than MetricKit alone |
| Background fetch scheduling | Custom timer, app lifecycle hooks | BGAppRefreshTask (BackgroundTasks framework) | System-managed scheduling based on battery, network, usage patterns; 30-second execution window; respects user force-quit |
| Offline cache management | Custom SQLite wrapper, cache expiration logic | Apollo iOS cache (already integrated) + Kingfisher (already integrated) | Apollo provides normalized SQLite cache with `cacheFirst` policy; Kingfisher provides image cache with prefetching API; both handle cache eviction |
| Dynamic Type scaling calculator | Custom font size multiplier, accessibility size mapping | @ScaledMetric property wrapper | SwiftUI built-in; automatically scales numeric values based on Dynamic Type setting; supports `relativeTo` parameter for semantic scaling |
| VoiceOver announcement queue | Custom announcement manager, TTS wrapper | UIAccessibility.post(notification: .announcement, argument: String) | UIKit API; queues announcements; respects VoiceOver running state; no custom TTS needed |

**Key insight:** Apple provides comprehensive accessibility, localization, and performance tooling that outperforms custom solutions. String Catalogs eliminate localization boilerplate, MetricKit provides production insights without third-party SDKs, and `@ScaledMetric` handles Dynamic Type scaling complexity. The ecosystem maturity means "boring" choices (use Apple's tools) are the correct choices for this phase.

## Common Pitfalls

### Pitfall 1: @ScaledMetric Without relativeTo Context

**What goes wrong:** Using `@ScaledMetric` without `relativeTo` parameter causes text to scale uniformly across all sizes, breaking visual hierarchy at accessibility sizes.

**Why it happens:** `@ScaledMetric` defaults to `.body` scaling if `relativeTo` is omitted, making headings and captions scale identically.

**How to avoid:**
1. Always specify `relativeTo` parameter matching semantic text role
2. Use `.largeTitle` for 34pt, `.title` for 28pt, `.title2` for 22pt, `.headline` for 18pt, `.caption` for 14pt
3. Preview at AX5 size (Settings → Accessibility → Display & Text Size → Larger Text → drag to max) to verify hierarchy

**Warning signs:**
- Headings and body text appear same size at AX5
- Buttons disappear off-screen at AX sizes
- Card layouts break with overlapping text

**Example fix:**

```swift
// Wrong: All scale uniformly
@ScaledMetric private var largeTitle: CGFloat = 34
@ScaledMetric private var body: CGFloat = 18
@ScaledMetric private var caption: CGFloat = 14

// Right: Preserve hierarchy
@ScaledMetric(relativeTo: .largeTitle) private var largeTitle: CGFloat = 34
@ScaledMetric(relativeTo: .body) private var body: CGFloat = 18
@ScaledMetric(relativeTo: .caption) private var caption: CGFloat = 14
```

### Pitfall 2: Turkish Localization Layout Overflow

**What goes wrong:** Turkish translations are ~30% longer than English, causing text truncation, button overflow, and broken layouts.

**Why it happens:** Turkish is agglutinative (adds suffixes to words), creating longer strings. Example: "Listen" → "Dinle" (OK), but "Bookmarks" → "Yer İşaretleri" (83% longer).

**How to avoid:**
1. Test all screens with Turkish language selected (Settings → General → Language & Region → Preferred Languages → Add Turkish)
2. Use flexible layouts: `HStack` with `spacing`, avoid fixed widths
3. Enable line wrapping: `.lineLimit(nil)` or `.lineLimit(2)` for labels
4. Use `@Environment(\.dynamicTypeSize)` to detect AX sizes and switch to vertical layouts
5. Add longer placeholder text during development to simulate Turkish length

**Warning signs:**
- Text truncated with "..." at default size
- Buttons pushed off-screen
- Labels overlap with icons
- Tab bar labels truncated

**Example fix:**

```swift
// Wrong: Fixed width, truncates
HStack(spacing: 8) {
    Text(String(localized: "Bookmarks"))
        .frame(width: 100)  // "Yer İşaretleri" truncates
}

// Right: Flexible width
HStack(spacing: 8) {
    Text(String(localized: "Bookmarks"))
        .lineLimit(1)
        .minimumScaleFactor(0.8)  // Shrinks if needed
}

// Better: Vertical stack at AX sizes
@Environment(\.dynamicTypeSize) var dynamicTypeSize

var body: some View {
    if dynamicTypeSize.isAccessibilitySize {
        VStack(alignment: .leading, spacing: 8) {  // Vertical at AX
            icon
            Text(String(localized: "Bookmarks"))
        }
    } else {
        HStack(spacing: 8) {  // Horizontal at default
            icon
            Text(String(localized: "Bookmarks"))
        }
    }
}
```

### Pitfall 3: Forgetting VoiceOver Announcements for State Changes

**What goes wrong:** Non-visual state changes (offline/online, playback start/pause, filter applied) go unnoticed by VoiceOver users.

**Why it happens:** VoiceOver only announces visible UI changes (buttons appearing, labels updating). State changes that don't affect visible UI need manual announcements.

**How to avoid:**
1. Use `UIAccessibility.post(notification: .announcement, argument: String)` for all critical state changes
2. Announce connectivity changes: "You're offline", "Back online"
3. Announce playback state: "Now playing: [Recipe] by [Voice]", "Paused"
4. Announce filter changes: "Showing vegan recipes"
5. Keep announcements brief (2-5 words)

**Warning signs:**
- VoiceOver silent when offline banner appears
- No audio feedback when playback starts
- Filter changes don't announce

**Example fix:**

```swift
// Wrong: Silent state change
case .connectivityChanged(let isOffline):
    state.isOffline = isOffline
    return .none

// Right: Announce to VoiceOver
case .connectivityChanged(let isOffline):
    state.isOffline = isOffline

    let message = isOffline
        ? String(localized: "accessibility.offline")
        : String(localized: "accessibility.online")

    UIAccessibility.post(
        notification: .announcement,
        argument: message
    )
    return .none
```

### Pitfall 4: Xcode String Catalog Not Auto-Extracting

**What goes wrong:** New `String(localized:)` strings don't appear in Localizable.xcstrings after build.

**Why it happens:** Xcode only extracts strings during **full build** (Cmd+B), not during incremental builds or SwiftUI previews.

**How to avoid:**
1. After adding new localized strings, do **Clean Build Folder** (Cmd+Shift+K), then **Build** (Cmd+B)
2. Check Localizable.xcstrings file in Project Navigator to verify extraction
3. If still missing, manually add string key in .xcstrings editor (Xcode will then track it)
4. Use build-time warnings for missing translations (Xcode 15+)

**Warning signs:**
- New strings not in .xcstrings after build
- String appears as literal English text instead of using catalog value
- Xcode shows "Missing localization" warning in console

**Example fix:**

1. Clean: Cmd+Shift+K
2. Build: Cmd+B
3. Open Localizable.xcstrings in Xcode
4. Verify new strings appear with English value
5. Add Turkish translation in .xcstrings editor

### Pitfall 5: MetricKit Metrics Never Arriving

**What goes wrong:** `didReceive(_ payloads: [MXMetricPayload])` never called, no launch time data.

**Why it happens:** MetricKit only works in **TestFlight/App Store builds**, not Debug builds or Simulator. Metrics arrive **24 hours after first app launch**, not immediately.

**How to avoid:**
1. Test MetricKit only via TestFlight (not Xcode Debug builds)
2. Wait 24 hours after TestFlight install for first payload
3. Check Console.app for MetricKit logs (subsystem: `com.apple.metrickit`)
4. Verify `MXMetricManagerSubscriber` conformance in AppDelegate
5. Add `.add(self)` in `didFinishLaunchingWithOptions`, `.remove(self)` in `applicationWillTerminate`

**Warning signs:**
- No metrics after 24 hours in TestFlight
- `didReceive` never called
- Console.app shows no MetricKit logs

**Example fix:**

```swift
// Add logging to verify subscription:
func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
) -> Bool {
    MXMetricManager.shared.add(self)
    Logger.performance.info("MetricKit subscriber registered")
    return true
}

func didReceive(_ payloads: [MXMetricPayload]) {
    Logger.performance.notice("Received \(payloads.count) metric payloads")
    // Process payloads...
}
```

### Pitfall 6: BGAppRefreshTask Never Running

**What goes wrong:** Background recipe refresh never executes, even in TestFlight.

**Why it happens:** System scheduling is **best-effort** and depends on battery, network, app usage patterns. Force-quitting app **kills all background tasks** until app reopened.

**How to avoid:**
1. Register task identifier in Info.plist `BGTaskSchedulerPermittedIdentifiers`
2. Register handler **before** app finishes launching
3. Schedule task in `applicationDidEnterBackground`
4. Test in Simulator with: `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"your-task-id"]`
5. Don't rely on background tasks for critical features (they're opportunistic)
6. Educate users: don't force-quit app if they want fresh content

**Warning signs:**
- Task never runs in TestFlight
- Console shows "No registered handler for task identifier"
- Background fetch toggle disabled in Settings → App → Background App Refresh

**Example fix:**

1. Info.plist:
```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.ersinkirteke.kindred.recipe-refresh</string>
</array>
```

2. AppDelegate:
```swift
func application(...) -> Bool {
    BGTaskScheduler.shared.register(
        forTaskWithIdentifier: "com.ersinkirteke.kindred.recipe-refresh",
        using: nil
    ) { task in
        self.handleRecipeRefresh(task: task as! BGAppRefreshTask)
    }
    Logger.background.info("Background task registered")
    return true
}
```

### Pitfall 7: Reduce Motion Breaks Core Functionality

**What goes wrong:** Disabling animations with `reduceMotion ? nil : .spring()` breaks swipe-to-dismiss, card transitions, hero animations entirely.

**Why it happens:** Setting `.animation(nil)` removes ALL animations, including transition animations needed for view insertion/removal.

**How to avoid:**
1. Don't remove animations entirely — replace with simpler animations (opacity, linear timing)
2. Use `.transition(.opacity)` instead of `.transition(.move)` under Reduce Motion
3. Keep hero transitions but swap `.zoom` for `.crossfade`
4. Use `withOptionalAnimation()` wrapper that checks Reduce Motion internally

**Warning signs:**
- Cards disappear instantly without transition
- Hero transitions snap instead of animate
- Swipe gestures don't provide visual feedback

**Example fix:**

```swift
// Wrong: No animation at all
.transition(reduceMotion ? .identity : .asymmetric(...))
.animation(reduceMotion ? nil : .spring(...))

// Right: Simple animation instead of complex
.transition(reduceMotion ? .opacity : .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading)))
.animation(reduceMotion ? .linear(duration: 0.2) : .spring(response: 0.3, dampingFraction: 0.6), value: offset)

// Hero transition:
.matchedTransitionSource(id: recipe.id, in: heroNamespace) {
    if reduceMotion {
        .crossfade  // Still animates, just simpler
    } else {
        .zoom
    }
}
```

## Code Examples

Verified patterns from official sources and existing codebase:

### Dynamic Type with @ScaledMetric

```swift
// Source: https://www.avanderlee.com/swiftui/scaledmetric-dynamic-type-support/
// Packages/DesignSystem/Sources/DesignSystem/Typography.swift

// Update existing typography system to support @ScaledMetric:

public extension Font {
    // Base sizes remain fixed for reference
    static func kindredLargeTitle() -> Font {
        .system(size: 34, weight: .medium, design: .default)
    }

    static func kindredBody() -> Font {
        .system(size: 18, weight: .light, design: .default)
    }

    static func kindredCaption() -> Font {
        .system(size: 14, weight: .light, design: .default)
    }

    // NEW: Scaled variants for use in views
    static func kindredLargeTitleScaled(size: CGFloat = 34) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    static func kindredBodyScaled(size: CGFloat = 18) -> Font {
        .system(size: size, weight: .light, design: .default)
    }

    static func kindredCaptionScaled(size: CGFloat = 14) -> Font {
        .system(size: size, weight: .light, design: .default)
    }
}

// Usage in view:
struct RecipeDetailView: View {
    @ScaledMetric(relativeTo: .largeTitle) private var largeTitleSize: CGFloat = 34
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18
    @ScaledMetric(relativeTo: .caption) private var captionSize: CGFloat = 14

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(recipe.name)
                .font(.kindredLargeTitleScaled(size: largeTitleSize))

            Text(recipe.description)
                .font(.kindredBodyScaled(size: bodySize))

            Text("\(recipe.totalTime) min")
                .font(.kindredCaptionScaled(size: captionSize))
        }
    }
}
```

### Localization with String Catalog

```swift
// Source: https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog
// https://medium.com/@hyleedevelop/ios-localization-tutorial-in-swiftui-using-string-catalog-9307953d8082

// 1. Create Localizable.xcstrings in Kindred/Sources/Resources/:
// File → New → File → String Catalog → Name: "Localizable"
// Set Languages: English (base), Turkish

// 2. Replace all hardcoded strings with String(localized:):

// Before:
Button("Listen") { ... }
Text("Skip")
.accessibilityLabel("Skip this recipe")

// After:
Button(String(localized: "button.listen")) { ... }
Text(String(localized: "button.skip"))
.accessibilityLabel(String(localized: "accessibility.recipe_card.skip"))

// With interpolation:
Text(String(localized: "recipe.time_minutes \(totalTime)"))
.accessibilityLabel(String(localized: "accessibility.now_playing \(recipe.name) \(voice.name)"))

// Plurals (String Catalog auto-handles):
Text(String(localized: "bookmarks.count \(count)"))

// 3. Build project (Cmd+B) — Xcode extracts strings into Localizable.xcstrings

// 4. Open Localizable.xcstrings in Xcode, add Turkish translations:
// {
//   "sourceLanguage": "en",
//   "strings": {
//     "button.listen": {
//       "extractionState": "extracted_with_value",
//       "localizations": {
//         "en": { "stringUnit": { "value": "Listen" } },
//         "tr": { "stringUnit": { "value": "Dinle" } }
//       }
//     },
//     "button.skip": {
//       "localizations": {
//         "en": { "stringUnit": { "value": "Skip" } },
//         "tr": { "stringUnit": { "value": "Geç" } }
//       }
//     },
//     "recipe.time_minutes %lld": {
//       "localizations": {
//         "en": { "stringUnit": { "value": "%lld minutes" } },
//         "tr": { "stringUnit": { "value": "%lld dakika" } }
//       }
//     },
//     "bookmarks.count %lld": {
//       "localizations": {
//         "en": {
//           "variations": {
//             "plural": {
//               "zero": { "stringUnit": { "value": "No bookmarks" } },
//               "one": { "stringUnit": { "value": "1 bookmark" } },
//               "other": { "stringUnit": { "value": "%lld bookmarks" } }
//             }
//           }
//         },
//         "tr": {
//           "variations": {
//             "plural": {
//               "zero": { "stringUnit": { "value": "Yer işareti yok" } },
//               "one": { "stringUnit": { "value": "1 yer işareti" } },
//               "other": { "stringUnit": { "value": "%lld yer işareti" } }
//             }
//           }
//         }
//       }
//     }
//   },
//   "version": "1.0"
// }

// 5. Test Turkish: Settings → General → Language & Region → Preferred Languages → Add Turkish
```

### VoiceOver Announcements

```swift
// Source: Existing FeedView.swift VoiceOver pattern
// UIKit UIAccessibility API

import UIKit

// In AppReducer (connectivity changes):
case .connectivityChanged(let isOffline):
    state.isOffline = isOffline

    let message = isOffline
        ? String(localized: "accessibility.offline")  // "You're offline"
        : String(localized: "accessibility.online")   // "Back online"

    UIAccessibility.post(
        notification: .announcement,
        argument: message
    )
    return .none

// In VoicePlaybackReducer (playback state):
case .playbackStateChanged(let newState):
    state.playbackState = newState

    switch newState {
    case .playing:
        if let recipe = state.currentRecipe, let voice = state.currentVoice {
            UIAccessibility.post(
                notification: .announcement,
                argument: String(localized: "accessibility.now_playing \(recipe.name) \(voice.name)")
                // "Now playing: Pasta Carbonara by Mom"
            )
        }

    case .paused:
        UIAccessibility.post(
            notification: .announcement,
            argument: String(localized: "accessibility.paused")
            // "Paused"
        )

    default:
        break
    }

    return .none

// In FeedReducer (filter changes):
case .dietaryFilterToggled(let filter):
    state.selectedFilters.toggle(filter)

    let announcement = state.selectedFilters.isEmpty
        ? String(localized: "accessibility.showing_all_recipes")
        : String(localized: "accessibility.showing_filtered_recipes \(filter.rawValue)")

    UIAccessibility.post(
        notification: .announcement,
        argument: announcement
    )

    return .send(.fetchRecipes)
```

### Reduce Motion Fallbacks

```swift
// Source: https://www.hackingwithswift.com/quick-start/swiftui/how-to-detect-the-reduce-motion-accessibility-setting
// Packages/FeedFeature/Sources/Feed/RecipeCardView.swift

struct RecipeCardView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        cardContent
            .offset(offset)
            .rotationEffect(.degrees(rotation))
            .transition(
                reduceMotion
                    ? .opacity  // Simple fade
                    : .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    )
            )
            .animation(
                reduceMotion
                    ? .linear(duration: 0.2)  // Simple linear
                    : .spring(response: 0.3, dampingFraction: 0.6),  // Bouncy spring
                value: offset
            )
    }
}

// In RecipeDetailView (hero transition):
struct RecipeDetailView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let heroNamespace: Namespace.ID

    var body: some View {
        ScrollView {
            if #available(iOS 18.0, *) {
                heroImage
                    .matchedTransitionSource(id: recipe.id, in: heroNamespace) {
                        if reduceMotion {
                            .crossfade  // Simple crossfade
                        } else {
                            .zoom  // Fancy zoom
                        }
                    }
            } else {
                heroImage
            }
        }
    }
}

// In SkeletonShimmer (loading animation):
struct SkeletonShimmer: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        if reduceMotion {
            // Static gray placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.kindredDivider)
        } else {
            // Animated shimmer (existing implementation)
            shimmering(
                active: true,
                duration: 1.5,
                bounce: false
            )
        }
    }
}
```

### Offline State Management

```swift
// Source: Existing FeedReducer connectivity pattern
// Packages/FeedFeature/Sources/Feed/FeedReducer.swift

// 1. App-level connectivity state (AppReducer.swift):
@Reducer
struct AppReducer {
    struct State: Equatable {
        var isOffline: Bool = false
        // ... other state
    }

    enum Action {
        case connectivityChanged(Bool)
        // ... other actions
    }

    @Dependency(\.networkMonitorClient) var networkMonitor

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    for await isOffline in networkMonitor.startMonitoring() {
                        await send(.connectivityChanged(isOffline))
                    }
                }

            case .connectivityChanged(let isOffline):
                state.isOffline = isOffline

                // Announce to VoiceOver
                let message = isOffline
                    ? String(localized: "accessibility.offline")
                    : String(localized: "accessibility.online")
                UIAccessibility.post(notification: .announcement, argument: message)

                // Auto-refresh when back online
                if !isOffline {
                    return .send(.refreshAllFeatures)
                }
                return .none

            default:
                return .none
            }
        }
    }
}

// 2. Shared offline banner component (DesignSystem/Components/OfflineBanner.swift):
public struct OfflineBanner: View {
    public init() {}

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
            Text(String(localized: "banner.offline"))
                .font(.kindredCaption())
        }
        .foregroundColor(.white)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(Color.orange)
    }
}

// 3. Feature observes app-level state (FeedView.swift):
struct FeedView: View {
    let store: StoreOf<FeedReducer>
    @ObservedObject var viewStore: ViewStoreOf<FeedReducer>

    var body: some View {
        VStack(spacing: 0) {
            // Show offline banner when disconnected
            if viewStore.isOffline {
                OfflineBanner()
            }

            // Main content
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewStore.recipes.isEmpty && viewStore.isOffline {
            // No cached recipes
            EmptyStateView(
                icon: "wifi.slash",
                title: String(localized: "empty.offline_title"),
                message: String(localized: "empty.offline_message")
            )
        } else {
            // Show cached recipes
            recipeCards
        }
    }
}

// 4. Disable network actions when offline (VoicePlaybackView.swift):
Button {
    viewStore.send(.playButtonTapped)
} label: {
    Image(systemName: "play.circle.fill")
}
.disabled(viewStore.isOffline)
.overlay {
    if viewStore.isOffline {
        // Toast notification
        ToastNotification(
            message: String(localized: "toast.voice_requires_internet"),
            duration: 3
        )
    }
}
```

### os.log Logger Implementation

```swift
// Source: https://www.avanderlee.com/debugging/oslog-unified-logging/
// https://swiftwithmajid.com/2022/04/06/logging-in-swift/

// 1. Create Logger extensions for each feature (FeedFeature/Sources/Utilities/Logger+Feed.swift):
import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!

    // Feed feature categories
    static let feed = Logger(subsystem: subsystem, category: "feed")
    static let personalization = Logger(subsystem: subsystem, category: "personalization")
    static let location = Logger(subsystem: subsystem, category: "location")
}

// 2. Create Logger extensions for other features:

// VoicePlaybackFeature/Sources/Utilities/Logger+VoicePlayback.swift
extension Logger {
    static let voicePlayback = Logger(subsystem: subsystem, category: "voice-playback")
    static let audioCache = Logger(subsystem: subsystem, category: "audio-cache")
}

// AuthFeature/Sources/Utilities/Logger+Auth.swift
extension Logger {
    static let auth = Logger(subsystem: subsystem, category: "auth")
    static let onboarding = Logger(subsystem: subsystem, category: "onboarding")
}

// MonetizationFeature/Sources/Utilities/Logger+Monetization.swift
extension Logger {
    static let subscription = Logger(subsystem: subsystem, category: "subscription")
    static let ads = Logger(subsystem: subsystem, category: "ads")
}

// App-level (Sources/App/Utilities/Logger+App.swift):
extension Logger {
    static let appLifecycle = Logger(subsystem: subsystem, category: "app-lifecycle")
    static let performance = Logger(subsystem: subsystem, category: "performance")
    static let background = Logger(subsystem: subsystem, category: "background")
}

// 3. Replace all print() statements:

// Before:
print("Fetching recipes for location: \(city)")
print("ERROR: Recipe fetch failed: \(error)")

// After:
Logger.feed.info("Fetching recipes for location: \(city, privacy: .public)")
Logger.feed.error("Recipe fetch failed: \(error.localizedDescription, privacy: .public)")

// Privacy annotations:
Logger.voicePlayback.debug("Starting playback for recipe: \(recipe.id, privacy: .private)")
// Console: "Starting playback for recipe: <private>"

Logger.audioCache.notice("Cache hit for URL: \(url.absoluteString, privacy: .private)")
// Console: "Cache hit for URL: <private>"

// Public data (error codes, state names):
Logger.feed.warning("Feed state changed: \(state, privacy: .public)")
// Console: "Feed state changed: loading"

// 4. Log level guidelines:
// .debug   → Verbose development logs (not persisted)
// .info    → Informational (not persisted by default)
// .notice  → Important info (persisted to disk)
// .warning → Warning (persisted to disk)
// .error   → Error (persisted to disk)
// .fault   → Critical error (persisted to disk)
```

### MetricKit Integration

```swift
// Source: https://www.avanderlee.com/swift/metrickit-launch-time/
// https://swiftwithmajid.com/2025/12/09/monitoring-app-performance-with-metrickit/
// Kindred/Sources/App/AppDelegate.swift

import MetricKit
import OSLog

class AppDelegate: NSObject, UIApplicationDelegate, MXMetricManagerSubscriber {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Subscribe to MetricKit
        MXMetricManager.shared.add(self)
        Logger.performance.info("MetricKit subscriber registered")

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        MXMetricManager.shared.remove(self)
    }

    // MARK: - MXMetricManagerSubscriber

    // Called at most once per 24 hours with aggregated metrics
    func didReceive(_ payloads: [MXMetricPayload]) {
        Logger.performance.notice("Received \(payloads.count) metric payloads")

        for payload in payloads {
            // Launch time metrics
            if let launchMetrics = payload.applicationLaunchMetrics {
                let avgLaunchTime = launchMetrics.histogrammedTimeToFirstDraw.averageValue
                let launchSeconds = avgLaunchTime.converted(to: .seconds).value

                Logger.performance.notice("Average launch time: \(launchSeconds)s")

                // Log to Firebase Analytics (optional)
                Analytics.logEvent("metric_launch_time", parameters: [
                    "average_seconds": launchSeconds,
                    "sample_count": launchMetrics.histogrammedTimeToFirstDraw.histogramNumBuckets
                ])

                // Warn if launch time exceeds target (1 second)
                if launchSeconds > 1.0 {
                    Logger.performance.warning("Launch time exceeds 1s target: \(launchSeconds)s")
                }
            }

            // Hang metrics (UI freezes)
            if let hangMetrics = payload.applicationHangTimeMetrics {
                let hangCount = hangMetrics.cumulativeHangTime.histogramNumBuckets
                let totalHangTime = hangMetrics.cumulativeHangTime.totalValue.converted(to: .seconds).value

                Logger.performance.warning("Hangs detected: \(hangCount) events, \(totalHangTime)s total")

                Analytics.logEvent("metric_hangs", parameters: [
                    "count": hangCount,
                    "total_seconds": totalHangTime
                ])
            }

            // Exit metrics (crashes, OOMs, watchdog kills)
            if let exitMetrics = payload.applicationExitMetrics {
                // Background exits
                if let bgExits = exitMetrics.backgroundExitData {
                    Logger.performance.error("Background exits: normal=\(bgExits.cumulativeNormalAppExitCount), abnormal=\(bgExits.cumulativeAbnormalExitCount)")
                }

                // Foreground exits
                if let fgExits = exitMetrics.foregroundExitData {
                    Logger.performance.error("Foreground exits: normal=\(fgExits.cumulativeNormalAppExitCount), abnormal=\(fgExits.cumulativeAbnormalExitCount)")
                }
            }

            // Disk write metrics (check for excessive writes)
            if let diskWriteMetrics = payload.diskWriteExceptionMetrics {
                let writeCount = diskWriteMetrics.cumulativeLogicalWrites.totalValue.converted(to: .megabytes).value
                Logger.performance.notice("Disk writes: \(writeCount) MB")
            }
        }
    }

    // Diagnostic payloads (crashes, hangs, CPU exceptions)
    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        Logger.performance.notice("Received \(payloads.count) diagnostic payloads")

        for payload in payloads {
            // Crash diagnostics (also sent to Crashlytics)
            if let crashDiagnostics = payload.crashDiagnostics {
                for crash in crashDiagnostics {
                    Logger.performance.fault("Crash detected: \(crash.exceptionType?.rawValue ?? "unknown"), \(crash.exceptionCode ?? 0)")
                    // Full stack trace in crash.callStackTree (JSON)
                }
            }

            // Hang diagnostics
            if let hangDiagnostics = payload.hangDiagnostics {
                for hang in hangDiagnostics {
                    Logger.performance.warning("Hang detected: \(hang.hangDuration.converted(to: .seconds).value)s")
                }
            }
        }
    }
}
```

### BGAppRefreshTask Background Fetch

```swift
// Source: https://uynguyen.github.io/2020/09/26/Best-practice-iOS-background-processing-Background-App-Refresh-Task/
// https://developer.apple.com/documentation/backgroundtasks/choosing-background-strategies-for-your-app

// 1. Add to Info.plist (Kindred/Sources/Info.plist):
// <key>BGTaskSchedulerPermittedIdentifiers</key>
// <array>
//     <string>com.ersinkirteke.kindred.recipe-refresh</string>
// </array>

// 2. AppDelegate.swift:
import BackgroundTasks
import OSLog

class AppDelegate: NSObject, UIApplicationDelegate {

    private let refreshTaskIdentifier = "com.ersinkirteke.kindred.recipe-refresh"

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Register background task handler EARLY
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: refreshTaskIdentifier,
            using: nil
        ) { task in
            self.handleRecipeRefresh(task: task as! BGAppRefreshTask)
        }

        Logger.background.info("Background task registered: \(refreshTaskIdentifier)")

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        scheduleRecipeRefresh()
    }

    // Schedule background refresh
    private func scheduleRecipeRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: refreshTaskIdentifier)

        // Earliest begin date (system may delay further)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)  // 15 minutes minimum

        do {
            try BGTaskScheduler.shared.submit(request)
            Logger.background.info("Background refresh scheduled (earliest: 15 min)")
        } catch {
            Logger.background.error("Failed to schedule background task: \(error)")
        }
    }

    // Handle background fetch (max 30 seconds execution)
    private func handleRecipeRefresh(task: BGAppRefreshTask) {
        Logger.background.notice("Background refresh started")

        // Schedule next refresh
        scheduleRecipeRefresh()

        // Set expiration handler (called if task runs too long)
        task.expirationHandler = {
            Logger.background.warning("Background task expired before completion")
            task.setTaskCompleted(success: false)
        }

        // Perform fetch
        Task {
            do {
                // Fetch latest recipes (reuse FeedReducer logic)
                try await fetchLatestRecipes()

                Logger.background.notice("Background refresh succeeded")
                task.setTaskCompleted(success: true)
            } catch {
                Logger.background.error("Background refresh failed: \(error)")
                task.setTaskCompleted(success: false)
            }
        }
    }

    // Fetch recipes (delegate to existing FeedReducer/NetworkClient)
    private func fetchLatestRecipes() async throws {
        // Use existing GraphQL client
        // Example: await apolloClient.fetch(query: GetFeedQuery())
        // This should update Apollo cache, ready for app launch
    }
}

// 3. Testing in Simulator (background tasks don't run automatically):
// Open Console.app → Debugger Console
// Run: e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.ersinkirteke.kindred.recipe-refresh"]
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| .strings + .stringsdict files | String Catalog (.xcstrings) single file | iOS 17 (2023) | Auto-extraction during build, no manual .strings editing, plurals/variables in one file, backward compatible |
| Custom font size calculations for Dynamic Type | @ScaledMetric property wrapper | iOS 14 (2020) | Automatic scaling based on user's Dynamic Type setting, supports relativeTo parameter for semantic scaling |
| UIAccessibility.isReduceMotionEnabled (UIKit) | @Environment(\.accessibilityReduceMotion) (SwiftUI) | iOS 14 (2020) | SwiftUI environment property, reactive updates when setting changes |
| OSLog (global function) | Logger (structured logging) | iOS 14 (2020) | Type-safe API, subsystems/categories for filtering, privacy annotations, async performance |
| TestFlight analytics + third-party crash tools | MetricKit (MXMetricManager) | iOS 13 (2019) | First-party production metrics (launch time, hangs, crashes) aggregated across users, no third-party SDK |
| UIBackgroundFetchResult (7-minute intervals) | BGAppRefreshTask (flexible scheduling) | iOS 13 (2019) | System-managed scheduling based on usage patterns, 30-second execution window, battery-aware |
| .storyboard launch screens with static images | LaunchScreen.storyboard + Asset Catalog | iOS 13+ (still current) | Static rendering (no animations), SwiftUI-friendly, supports light/dark mode via Asset Catalog |
| Manual crash symbol upload (dSYM) | Automatic dSYM upload via Xcode build phase | Xcode 14+ (2022) | Firebase Crashlytics script auto-uploads dSYM during build, no manual App Store Connect download |
| Bitcode-based dSYM retrieval from App Store Connect | Local dSYM files only (Bitcode deprecated) | Xcode 14 (2022) | Simpler: dSYM files generated locally during build, no waiting for App Store Connect processing |

**Deprecated/outdated:**

- **Bitcode:** Deprecated in Xcode 14 (2022). No longer need to download dSYM from App Store Connect; all dSYM files generated locally during build.
- **UIBackgroundFetchResult:** Replaced by BackgroundTasks framework (BGAppRefreshTask) in iOS 13. Old API still works but offers less flexibility.
- **.strings files:** Not deprecated, but String Catalogs (.xcstrings) are now recommended for iOS 17+. Xcode converts .xcstrings to .strings during build for backward compatibility.
- **print() debugging:** Not deprecated, but os.log Logger is strongly recommended for production apps (performance, privacy, filtering).
- **Localizable.strings manual editing:** Xcode now auto-extracts `String(localized:)` strings into String Catalog during build. Manual .strings editing is legacy workflow.

## Open Questions

1. **Turkish translation validation process**
   - What we know: AI (Claude) will generate Turkish translations, user will review and correct
   - What's unclear: Specific workflow for iterating on translations after initial generation (in-app preview? TestFlight feedback?)
   - Recommendation: Generate initial translations in one batch after all English strings finalized (post-Wave 0), test in-app with Turkish language selected, iterate corrections in .xcstrings editor

2. **MetricKit payload delivery timing**
   - What we know: Metrics delivered at most once per 24 hours, first payload arrives 24 hours after first app launch
   - What's unclear: Will TestFlight builds generate enough user-days for meaningful data before App Store submission?
   - Recommendation: Integrate MetricKit now, but don't rely on it for pre-launch validation. Use Xcode Instruments (Time Profiler, System Trace) for launch time optimization during development.

3. **Exact BGAppRefreshTask scheduling interval for optimal freshness vs battery impact**
   - What we know: System allows minimum 15 minutes, but actual scheduling depends on app usage patterns, battery, network
   - What's unclear: What interval balances "fresh recipes on app open" with "not draining battery"?
   - Recommendation: Start with `earliestBeginDate = 15 * 60` (15 minutes). Monitor real-world scheduling in TestFlight logs. System will delay to 45 min - 2 hours if user doesn't open app frequently, which is acceptable (background fetch is opportunistic, not guaranteed).

4. **Manual WCAG AAA contrast audit tooling**
   - What we know: Manual audit using WebAIM Contrast Checker (https://webaim.org/resources/contrastchecker/), existing Asset Catalog declares WCAG AAA values
   - What's unclear: Best workflow for auditing all color pairings (text on backgrounds, button states, badges on images)?
   - Recommendation: Create spreadsheet with all color pairings (kindredTextPrimary on kindredBackground, kindredAccent on white, etc.), verify each pair in WebAIM tool, document ratios in .planning/phases/10-accessibility-polish/contrast-audit.md

5. **App Store screenshot generation strategy**
   - What we know: Requires 6.9" iPhone 16 Pro Max size (1320 x 2868 pixels), minimum 1 screenshot, maximum 10
   - What's unclear: Manual screenshots from device, or automated screenshot generation tool (Fastlane Snapshot)?
   - Recommendation: Manual screenshots for MVP (10 screens: Feed, Recipe Detail, Voice Playback, Profile, Bookmarks, Onboarding, Voice Upload, Paywall, Dietary Filters, Location Picker). Use iPhone 16 Pro Max simulator, save to Files app, upload to App Store Connect. Automated tools can be added post-launch for localization.

## Sources

### PRIMARY (HIGH confidence)

**Official Apple Documentation:**
- [Specifying your app's launch screen | Apple Developer](https://developer.apple.com/documentation/xcode/specifying-your-apps-launch-screen) - LaunchScreen.storyboard setup
- [Localizing and varying text with a string catalog | Apple Developer](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog) - String Catalog (.xcstrings) official guide
- [Accessibility modifiers | Apple Developer](https://developer.apple.com/documentation/swiftui/view-accessibility) - SwiftUI accessibility API reference
- [MetricKit | Apple Developer](https://developer.apple.com/documentation/MetricKit) - MetricKit framework documentation
- [MXAppLaunchMetric | Apple Developer](https://developer.apple.com/documentation/metrickit/mxapplaunchmetric?language=objc) - App launch time metrics
- [Choosing Background Strategies for Your App | Apple Developer](https://developer.apple.com/documentation/backgroundtasks/choosing-background-strategies-for-your-app) - BGAppRefreshTask guide
- [Using background tasks to update your app | Apple Developer](https://developer.apple.com/documentation/uikit/using-background-tasks-to-update-your-app) - Background tasks tutorial

**WCAG Standards:**
- [Understanding Success Criterion 1.4.6: Contrast (Enhanced) | WCAG 2.1](https://www.w3.org/WAI/WCAG21/Understanding/contrast-enhanced.html) - WCAG AAA 7:1 ratio definition
- [WebAIM: Contrast Checker](https://webaim.org/resources/contrastchecker/) - Manual contrast validation tool
- [WebAIM: Contrast and Color Accessibility](https://webaim.org/articles/contrast/) - WCAG 2 contrast requirements

**App Store Requirements:**
- [App Privacy Details - App Store - Apple Developer](https://developer.apple.com/app-store/app-privacy-details/) - Privacy Nutrition Labels
- [Submitting - App Store - Apple Developer](https://developer.apple.com/app-store/submitting/) - App Store submission requirements
- [Screenshot specifications - App Store Connect](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/) - 2026 screenshot sizes
- [Upload app previews and screenshots - App Store Connect](https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots/) - Screenshot upload guide

### SECONDARY (MEDIUM confidence)

**@ScaledMetric and Dynamic Type:**
- [How to use @ScaledMetric in SwiftUI for Dynamic Type support | SwiftLee](https://www.avanderlee.com/swiftui/scaledmetric-dynamic-type-support/) - @ScaledMetric tutorial with examples
- [How to scale margin and padding with @ScaledMetric Property Wrapper | Sarunw](https://sarunw.com/posts/swiftui-scaledmetric/) - @ScaledMetric for spacing
- [Supporting Dynamic Type and Larger Text in your app | Create with Swift](https://www.createwithswift.com/supporting-dynamic-type-and-larger-text-in-your-app-to-enhance-accessibility/) - Dynamic Type best practices
- [Get Started with Dynamic Type - WWDC24 | Yaacoub](https://yaacoub.github.io/articles/swift-tip/get-started-with-dynamic-type-wwdc24/) - WWDC 2024 summary

**String Catalogs:**
- [iOS Localization with Xcode String Catalogs: The Complete Guide | Atomic Robot](https://atomicrobot.com/blog/lost-in-translation-understanding-ios-localization/) - String Catalog migration guide
- [iOS Localization Tutorial in SwiftUI using String Catalog | Medium](https://medium.com/@hyleedevelop/ios-localization-tutorial-in-swiftui-using-string-catalog-9307953d8082) - SwiftUI String Catalog walkthrough
- [How to migrate from Localizable.strings to String Catalogs | Tanaschita](https://tanaschita.com/20231106-migration-to-string-catalogs/) - Migration process
- [How to use String Catalogs for localization in Swift | Tanaschita](https://tanaschita.com/20230626-string-catalogs/) - String Catalog basics

**VoiceOver:**
- [iOS 26 Accessibility Guide: SwiftUI VoiceOver & More | Medium](https://ravi6997.medium.com/swiftui-accessibility-apis-whats-new-in-ios-26-d5d7f24ba2a7) - iOS 26 accessibility updates
- [VoiceOver navigation improvement tips for SwiftUI apps | SwiftLee](https://www.avanderlee.com/swiftui/voiceover-navigation-improvement-tips/) - VoiceOver best practices
- [Beginners guide to supporting VoiceOver in SwiftUI | Tanaschita](https://tanaschita.com/ios-accessibility-voiceover-swiftui-guide/) - VoiceOver tutorial
- [Accessibility in SwiftUI Apps: Best Practices | Medium](https://commitstudiogs.medium.com/accessibility-in-swiftui-apps-best-practices-a15450ebf554) - Accessibility patterns

**Reduce Motion:**
- [How to detect the Reduce Motion accessibility setting | Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftui/how-to-detect-the-reduce-motion-accessibility-setting) - @Environment(\.accessibilityReduceMotion)
- [Ensure Visual Accessibility: Supporting reduced motion preferences in SwiftUI | Create with Swift](https://www.createwithswift.com/ensure-visual-accessibility-supporting-reduced-motion-preferences-in-swiftui/) - Reduce Motion implementation
- [Supporting Reduced Motion accessibility setting in SwiftUI | Tanaschita](https://tanaschita.com/ios-accessibility-reduced-motion/) - Reduce Motion guide

**os.log Logger:**
- [OSLog and Unified logging as recommended by Apple | SwiftLee](https://www.avanderlee.com/debugging/oslog-unified-logging/) - Logger tutorial with subsystems/categories
- [Logging in Swift | Swift with Majid](https://swiftwithmajid.com/2022/04/06/logging-in-swift/) - Logger API guide
- [Modern logging with the OSLog framework in Swift | Donny Wals](https://www.donnywals.com/modern-logging-with-the-oslog-framework-in-swift/) - OSLog vs Logger comparison
- [Swift Logging Techniques: A Complete Guide to iOS Logging | Bugfender](https://bugfender.com/blog/swift-logging/) - Comprehensive logging guide

**MetricKit:**
- [Using MetricKit to monitor user data like launch times | SwiftLee](https://www.avanderlee.com/swift/metrickit-launch-time/) - MetricKit launch time tutorial
- [Monitoring app performance with MetricKit | Swift with Majid](https://swiftwithmajid.com/2025/12/09/monitoring-app-performance-with-metrickit/) - MetricKit implementation (2025)
- [A Practical Guide to Apple's MetricKit | Medium](https://medium.com/@rajanTheSilentCompiler/a-practical-guide-to-apples-metrickit-stop-guessing-start-measuring-your-ios-app-s-health-5639db388e9c) - MetricKit practical examples (Feb 2026)
- [Monitoring for iOS with MetricKit: Getting Started | Kodeco](https://www.kodeco.com/20952676-monitoring-for-ios-with-metrickit-getting-started) - MetricKit tutorial

**BGAppRefreshTask:**
- [Best practice: iOS background processing - Background App Refresh Task | Uy Nguyen](https://uynguyen.github.io/2020/09/26/Best-practice-iOS-background-processing-Background-App-Refresh-Task/) - BGAppRefreshTask best practices
- [Mastering Background Tasks in iOS | Medium](https://medium.com/@dhruvmanavadaria/mastering-background-tasks-in-ios-bgtaskscheduler-silent-push-and-background-fetch-with-6b5c502d7448) - BGTaskScheduler guide
- [iOS Background Tasks | OneUptime](https://oneuptime.com/blog/post/2026-02-02-ios-background-tasks/view) - 2026 background tasks overview

**Firebase Crashlytics:**
- [Get readable crash reports in the Crashlytics dashboard | Firebase](https://firebase.google.com/docs/crashlytics/ios/get-deobfuscated-reports) - dSYM upload guide
- [Simplify the Process of Uploading iOS dSYM Files to Crashlytics with Fastlane | Firebase Blog](https://firebase.blog/posts/2021/09/uploading-dsym-files-to-crashlytics-with-fastlane/) - Automated dSYM upload
- [Firebase Crashlytics dSYM uploading | Codemagic Docs](https://docs.codemagic.io/knowledge-firebase/firebase-crashlytics-dsym-uploading/) - Crashlytics dSYM setup

**Apollo iOS Cache:**
- [Cache setup | Apollo GraphQL Docs](https://www.apollographql.com/docs/ios/caching/cache-setup) - Apollo iOS cache configuration
- [CachePolicy | Apollo GraphQL Docs](https://www.apollographql.com/docs/ios/api/Apollo/enums/CachePolicy) - cacheFirst policy documentation
- [Client-side caching | Apollo GraphQL Docs](https://www.apollographql.com/docs/ios/caching/introduction) - Apollo iOS caching overview

**Kingfisher Prefetching:**
- [Kingfisher GitHub](https://github.com/onevcat/Kingfisher) - Official Kingfisher repository
- [Cheat Sheet | Kingfisher Wiki](https://github.com/onevcat/Kingfisher/wiki/Cheat-Sheet) - Kingfisher API quick reference
- [ImagePrefetcher.swift | Kingfisher](https://github.com/onevcat/Kingfisher/blob/master/Sources/Networking/ImagePrefetcher.swift) - ImagePrefetcher source code

**Turkish Localization:**
- [How to Manage Text Expansion in Translation & Localization [2026] | Pairaphrase](https://www.pairaphrase.com/blog/text-expansion-in-translation) - Text expansion percentages by language
- [Design that speaks every language: UI tips for localization | SimpleLocalize](https://simplelocalize.io/blog/posts/ui-localization-best-practices/) - Localization UI best practices

**App Store Metadata:**
- [App Store Screenshot Guidelines in 2026 | The App Launchpad](https://theapplaunchpad.com/blog/app-store-screenshot-guidelines-in-2026) - 2026 screenshot requirements
- [The Complete Guide to App Store Screenshots in 2026 | FrameHero](https://www.framehero.dev/blog/app-store-screenshots-guide) - Screenshot best practices

### TERTIARY (LOW confidence)

None. All findings verified with official Apple documentation or authoritative secondary sources (SwiftLee, Swift with Majid, Kodeco, Firebase official docs).

## Metadata

**Confidence breakdown:**
- **Standard stack:** HIGH — All libraries are Apple first-party (SwiftUI, String Catalogs, MetricKit, os.log Logger) or already integrated in project (Apollo iOS, Kingfisher, Firebase Crashlytics). Version numbers verified from project.yml and official docs.
- **Architecture patterns:** HIGH — @ScaledMetric, @Environment(\.accessibilityReduceMotion), String(localized:), UIAccessibility.post, Logger subsystems/categories, MetricKit MXMetricManagerSubscriber, BGAppRefreshTask all documented in official Apple sources with code examples. Existing VoiceOver patterns verified from RecipeCardView.swift.
- **Localization:** HIGH — String Catalog (.xcstrings) is iOS 17+ official approach, Xcode 15+ auto-extraction verified in official docs. Turkish text expansion (30% longer) verified from localization industry sources.
- **Performance:** HIGH — MetricKit, os.log Logger, BGAppRefreshTask all Apple first-party frameworks with official documentation. Launch time target (under 1 second) is industry standard for consumer apps.
- **Offline resilience:** HIGH — Apollo iOS cacheFirst policy verified from official Apollo docs. Kingfisher prefetching API verified from official GitHub repo. Connectivity pattern already implemented in FeedReducer.swift.
- **WCAG AAA:** HIGH — 7:1 contrast ratio for normal text, 4.5:1 for large text defined in WCAG 2.1 official spec. Manual audit with WebAIM Contrast Checker is standard industry practice.
- **Common pitfalls:** MEDIUM — Based on community patterns (SwiftLee, Medium articles) and cross-referenced with official docs. Turkish layout overflow percentage (30%) is from translation industry sources, not Turkish-specific iOS data.

**Research date:** 2026-03-08
**Valid until:** 2026-04-08 (30 days — stable domain, Apple APIs change slowly)
