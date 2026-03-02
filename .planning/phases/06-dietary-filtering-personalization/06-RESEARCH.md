# Phase 6: Dietary Filtering & Personalization - Research

**Researched:** 2026-03-03
**Domain:** Dietary filtering UI, on-device personalization, implicit feedback learning, preference persistence
**Confidence:** MEDIUM

## Summary

Phase 6 implements dietary preference filtering with persistent chip-based UI and introduces Culinary DNA — an on-device personalization system that learns user taste from implicit feedback (skips and bookmarks). The core technical domains are: (1) SwiftUI chip bar with multi-select dietary filters (vegan, keto, halal, etc.) that persist across sessions via UserDefaults/AppStorage, (2) backend GraphQL filtering with AND logic already implemented via `FeedFiltersInput.dietaryTags`, (3) on-device affinity calculation using weighted implicit signals (bookmark = 2x skip weight) with recency decay, (4) feed ranking adaptation using soft-boost strategy (~60% personalized, ~40% discovery), (5) Me tab visualization with affinity bars and progress tracking toward 50-interaction threshold.

The backend already supports dietary filtering with AND logic (`FeedFiltersInput.dietaryTags: [String]`), so iOS implementation focuses on chip UI, preference storage, and local Culinary DNA computation. No Core ML model needed — simple weighted affinity calculation on SwiftData bookmark/skip history is sufficient for MVP personalization.

**Primary recommendation:** Use horizontal chip bar with @AppStorage for filter persistence, extend FeedReducer to send `dietaryTags` parameter to existing GraphQL `feed` query, compute Culinary DNA affinity scores locally from GuestBookmark/GuestSkip counts with exponential recency decay, soft-boost feed ranking by re-ordering recipes (not re-fetching), and visualize top 3-5 cuisine affinities as horizontal progress bars in Me tab with "For You" badges on boosted cards.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Filter Interaction:**
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

**Preference Storage:**
- Dietary preferences stored in UserDefaults (Set<String> of active dietary tags)
- Active filters = saved preferences (same thing, single concept)
- Auto-save on chip tap — no apply/confirm button needed
- Auto-apply saved preferences on app launch (feed starts pre-filtered if prefs exist)
- Dual access: chip bar in feed AND "Dietary Preferences" section in Me tab
- Me tab shows same chip style as feed (consistent, tappable)
- "Reset Dietary Preferences" button in Me tab only (X chip in feed only clears active session, not saved defaults)
- No first-launch onboarding prompt for dietary preferences — users discover via chips
- Storage designed to be migration-friendly for Phase 8 auth (UserDefaults keys readable for backend sync)

**Culinary DNA Learning:**
- Signals: skips (left swipe) and bookmarks (right swipe) only — no detail view time or completion tracking
- Tracked attributes: cuisine type affinity + dietary tag patterns
- On-device computation — process GuestBookmark/GuestSkip SwiftData history locally, no backend changes
- Activation threshold: 50+ interactions (per PERS-01 requirement)
- Ranking influence: soft boost — ~60% preferred cuisines, ~40% discovery/variety
- Bookmark weight = 2x skip weight (bookmarks are stronger positive signals)
- Weighted decay for skips: takes 5-10 skips of same cuisine to noticeably reduce affinity
- Recency-weighted: recent interactions carry more weight than older ones (taste evolves)

**Feed Adaptation UX:**
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

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope

</user_constraints>

<phase_requirements>
## Phase Requirements

This phase MUST address the following requirements from REQUIREMENTS.md:

| ID | Description | Research Support |
|----|-------------|-----------------|
| FEED-07 | User can filter recipes by dietary preference (vegan, keto, halal, allergies) | Chip bar UI + @AppStorage persistence + FeedFiltersInput GraphQL parameter |
| PERS-01 | App learns user taste from implicit feedback (skips and bookmarks) via Culinary DNA | On-device weighted affinity calculation from SwiftData GuestBookmark/GuestSkip counts |
| PERS-02 | Feed ranking adapts based on user's Culinary DNA profile over time | Soft-boost re-ranking algorithm (~60% personalized, ~40% discovery) |
| PERS-03 | User can set dietary preferences during onboarding or in settings (vegan, keto, halal, allergies) | Chip bar in feed + Me tab "Dietary Preferences" section with @AppStorage |

</phase_requirements>

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17.0+ | Declarative UI framework | Native framework, chip bar ScrollView, @AppStorage integration |
| @AppStorage | iOS 14.0+ | UserDefaults-backed preferences | Auto-saves dietary filters, auto-updates UI, migration-friendly |
| TCA (swift-composable-architecture) | 1.x | State management architecture | Already integrated in Phase 5, manage filter state and DNA state |
| SwiftData | iOS 17.0+ | Local persistence framework | GuestBookmark/GuestSkip models already in place from Phase 5 |
| Apollo iOS | 2.0.6 | GraphQL client | FeedFiltersInput already supported by backend `feed` query |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Foundation | iOS 17.0+ | Date calculations, sorting, Set operations | Recency weighting, affinity score calculation |
| Combine | iOS 13.0+ | @Published property wrappers | Observe changes to dietary preferences for UI updates (optional — @AppStorage auto-updates) |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| @AppStorage | Manual UserDefaults | @AppStorage auto-updates UI; manual UserDefaults requires ObservableObject boilerplate |
| On-device calculation | Core ML MLRecommender | Core ML is overkill for simple weighted affinity; requires training data, model updates |
| Exponential decay | Linear decay | Exponential decay better models taste evolution; linear is simpler but less realistic |
| Soft-boost re-ranking | Re-fetch with backend personalization | On-device re-ranking is instant, privacy-preserving; backend requires auth, server logic |

**Installation:**

All dependencies already installed in Phase 4-5. No new SPM packages required.

```bash
# All dependencies already available:
# - SwiftUI (built-in)
# - @AppStorage (built-in)
# - TCA 1.x (Phase 4)
# - SwiftData (Phase 5)
# - Apollo iOS 2.0.6 (Phase 4)
# No new installations needed
```

## Architecture Patterns

### Recommended Project Structure

```
FeedFeature/
├── Sources/
│   ├── Feed/
│   │   ├── FeedReducer.swift              # Extend with dietaryFilters, culinaryDNA state
│   │   ├── FeedView.swift                  # Add chip bar above card stack
│   │   ├── DietaryChipBar.swift            # Horizontal chip selector
│   │   ├── ForYouBadge.swift               # "For You" badge component (pattern from ViralBadge)
│   │   └── DNAActivationCard.swift         # One-time activation card
│   ├── Personalization/
│   │   ├── CulinaryDNAEngine.swift         # Affinity calculation logic
│   │   ├── AffinityScore.swift             # Data model for cuisine affinity
│   │   ├── PersonalizationClient.swift     # TCA dependency for DNA engine
│   │   └── FeedRanker.swift                # Soft-boost re-ranking algorithm
│   ├── Profile/
│   │   ├── ProfileReducer.swift            # Extend with DNA state
│   │   ├── ProfileView.swift               # Add "Dietary Preferences" + "Culinary DNA" sections
│   │   ├── DietaryPreferencesSection.swift # Chip bar + reset button
│   │   └── CulinaryDNASection.swift        # Affinity bars + progress indicator
│   └── GuestSession/
│       └── GuestSessionClient.swift        # Extend with DNA query methods
```

### Pattern 1: Multi-Select Chip Bar with @AppStorage

**What:** Horizontal ScrollView with selectable chips that auto-save to UserDefaults via @AppStorage and trigger re-fetch on toggle.

**When to use:** Any multi-select filter UI where selections persist across app launches.

**Example:**

```swift
// Based on: https://medium.com/@ramdhas/mastering-swiftui-best-practices-for-efficient-user-preference-management-with-appstorage-cf088f4ca90c
// and https://www.hackingwithswift.com/books/ios-swiftui/storing-user-settings-with-userdefaults

struct DietaryChipBar: View {
    @AppStorage("dietaryPreferences") private var dietaryPreferencesData: Data = Data()

    private var dietaryPreferences: Set<String> {
        get {
            (try? JSONDecoder().decode(Set<String>.self, from: dietaryPreferencesData)) ?? []
        }
        set {
            dietaryPreferencesData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    let allDietaryTags = ["Vegan", "Vegetarian", "Gluten-free", "Dairy-free", "Keto", "Halal", "Nut-free"]
    let onFilterChanged: (Set<String>) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(allDietaryTags, id: \.self) { tag in
                    DietaryChip(
                        title: tag,
                        isSelected: dietaryPreferences.contains(tag),
                        onTap: { toggleFilter(tag) }
                    )
                }

                if !dietaryPreferences.isEmpty {
                    ClearAllChip(onTap: clearAllFilters)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func toggleFilter(_ tag: String) {
        var updated = dietaryPreferences
        if updated.contains(tag) {
            updated.remove(tag)
        } else {
            updated.insert(tag)
        }
        dietaryPreferences = updated
        onFilterChanged(updated)
    }

    private func clearAllFilters() {
        dietaryPreferences = []
        onFilterChanged([])
    }
}

struct DietaryChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Text(title)
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Colors.terracotta : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Colors.terracotta, lineWidth: 1.5)
            )
            .foregroundColor(isSelected ? .white : Colors.terracotta)
            .onTapGesture(perform: onTap)
    }
}
```

**Key insights:**
- @AppStorage doesn't natively support Set<String>, encode/decode as Data ([source](https://www.hackingwithswift.com/books/ios-swiftui/storing-user-settings-with-userdefaults))
- OnTap callback triggers TCA action to re-fetch feed with filters ([source](https://medium.com/@ramdhas/mastering-swiftui-best-practices-for-efficient-user-preference-management-with-appstorage-cf088f4ca90c))
- Migration-friendly: keys like "dietaryPreferences" can be read by backend after Phase 8 auth ([source](https://www.vadimbulavin.com/advanced-guide-to-userdefaults-in-swift/))

### Pattern 2: Backend Filtering with FeedFiltersInput

**What:** Extend Apollo GraphQL query to pass `dietaryTags` parameter using existing backend `FeedFiltersInput` schema.

**When to use:** When filtering recipes server-side to avoid fetching irrelevant data.

**Example:**

```swift
// Backend already supports FeedFiltersInput with dietaryTags: [String]
// iOS sends active dietary preferences as array

@Reducer
struct FeedReducer {
    @ObservableState
    struct State {
        var activeDietaryFilters: Set<String> = []
        // ... existing state
    }

    enum Action {
        case dietaryFilterChanged(Set<String>)
        // ... existing actions
    }

    @Dependency(\.apolloClient) var apollo

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case let .dietaryFilterChanged(filters):
            state.activeDietaryFilters = filters
            state.isLoading = true

            return .run { [location = state.location, filters] send in
                let filterInput = filters.isEmpty ? nil : KindredAPI.FeedFiltersInput(
                    cuisineTypes: nil,
                    mealTypes: nil,
                    dietaryTags: Array(filters)
                )

                let result = try await apollo.fetch(
                    query: KindredAPI.FeedQuery(
                        latitude: location.latitude,
                        longitude: location.longitude,
                        first: 20,
                        after: nil,
                        filters: filterInput,
                        lastFetchedAt: nil
                    ),
                    cachePolicy: .fetchIgnoringCacheData // Force fresh fetch on filter change
                )

                await send(.recipesLoaded(.success(result.data?.feed.edges.map(\.node) ?? [])))
            } catch: { error, send in
                await send(.recipesLoaded(.failure(error)))
            }
        }
    }
}
```

**Key insights:**
- Backend FeedFiltersInput already exists with AND logic for dietaryTags ([source](https://github.com/apollographql/apollo-ios))
- Use `.fetchIgnoringCacheData` on filter change to avoid stale cached results (similar to location change pattern from Phase 5)
- Empty filters = nil parameter (no filtering applied)

### Pattern 3: On-Device Affinity Calculation with Exponential Recency Decay

**What:** Calculate cuisine affinity scores from SwiftData bookmark/skip counts, weighted by action type and recency.

**When to use:** Privacy-preserving personalization without sending user behavior to server.

**Example:**

```swift
// Based on: https://thesis.eur.nl/pub/63345/FinalThesis_HannaHurenkamp.pdf (recency weighting)
// and https://customers.ai/recency-weighted-scoring (exponential decay)

struct AffinityScore: Equatable {
    let cuisineType: String
    let score: Double // 0.0 to 1.0
}

@MainActor
class CulinaryDNAEngine {
    private let bookmarkWeight: Double = 2.0  // Bookmarks are 2x stronger than skips
    private let skipWeight: Double = 1.0
    private let decayHalfLife: TimeInterval = 30 * 24 * 60 * 60  // 30 days in seconds

    func computeAffinities(
        bookmarks: [GuestBookmark],
        skips: [GuestSkip]
    ) -> [AffinityScore] {
        var cuisineScores: [String: Double] = [:]
        let now = Date()

        // Process bookmarks (positive signal, 2x weight)
        for bookmark in bookmarks {
            guard let cuisineType = bookmark.cuisineType else { continue }
            let recencyWeight = exponentialDecay(age: now.timeIntervalSince(bookmark.createdAt))
            cuisineScores[cuisineType, default: 0] += bookmarkWeight * recencyWeight
        }

        // Process skips (negative signal, 1x weight, requires 5-10 to noticeably reduce)
        for skip in skips {
            guard let cuisineType = skip.cuisineType else { continue }
            let recencyWeight = exponentialDecay(age: now.timeIntervalSince(skip.createdAt))
            // Negative weight, but divided by 5 so it takes 5 skips to cancel 1 bookmark
            cuisineScores[cuisineType, default: 0] -= (skipWeight * recencyWeight) / 5.0
        }

        // Normalize scores to 0-1 range
        let maxScore = cuisineScores.values.max() ?? 1.0
        let normalized = cuisineScores.map { cuisine, score in
            AffinityScore(
                cuisineType: cuisine,
                score: max(0, score / maxScore)  // Clamp to non-negative
            )
        }

        // Return top cuisines sorted by score
        return normalized.sorted { $0.score > $1.score }
    }

    /// Exponential decay: weight = 0.5^(age / halfLife)
    /// Recent interactions have weight ~1.0, old interactions decay toward 0
    private func exponentialDecay(age: TimeInterval) -> Double {
        return pow(0.5, age / decayHalfLife)
    }

    func interactionCount(bookmarks: [GuestBookmark], skips: [GuestSkip]) -> Int {
        return bookmarks.count + skips.count
    }
}
```

**Key insights:**
- Exponential decay better models taste evolution than linear ([source](https://thesis.eur.nl/pub/63345/FinalThesis_HannaHurenkamp.pdf))
- Bookmark weight 2x skip weight matches user decision ([source](https://customers.ai/recency-weighted-scoring))
- Divide skip weight by 5 so it takes ~5-10 skips to noticeably reduce affinity (user decision)
- 30-day half-life means interactions from 1 month ago have ~50% weight

### Pattern 4: Soft-Boost Feed Ranking (60/40 Split)

**What:** Re-order fetched recipes to surface preferred cuisines while maintaining discovery, without re-fetching from backend.

**When to use:** When personalization should enhance but not dominate feed (avoid filter bubbles).

**Example:**

```swift
// Based on: exploration/exploitation tradeoff in recommender systems
// and https://builtin.com/data-science/recommender-systems

struct FeedRanker {
    let personalizedRatio: Double = 0.6  // 60% personalized
    let discoveryRatio: Double = 0.4     // 40% discovery/variety

    func rerank(
        recipes: [RecipeCard],
        affinities: [AffinityScore]
    ) -> [RecipeCard] {
        guard !affinities.isEmpty else { return recipes }

        let affinityMap = Dictionary(uniqueKeysWithValues: affinities.map { ($0.cuisineType, $0.score) })

        // Score each recipe based on cuisine affinity
        let scoredRecipes = recipes.map { recipe -> (recipe: RecipeCard, score: Double) in
            let affinityScore = affinityMap[recipe.cuisineType] ?? 0.0
            // Mix affinity with original velocity score (60/40 split)
            let combinedScore = (personalizedRatio * affinityScore) + (discoveryRatio * recipe.velocityScore)
            return (recipe, combinedScore)
        }

        // Sort by combined score (descending)
        return scoredRecipes
            .sorted { $0.score > $1.score }
            .map(\.recipe)
    }
}
```

**Key insights:**
- 60/40 split balances personalization with discovery (user decision) ([source](https://builtin.com/data-science/recommender-systems))
- Re-ranking happens on-device, instant, privacy-preserving
- Original velocity score preserved in mix prevents filter bubble
- No backend changes needed — pure client-side re-ordering

### Pattern 5: TCA Dependency for Personalization Engine

**What:** Define PersonalizationClient as TCA dependency to inject DNA engine for testability.

**When to use:** Any stateful logic that needs access to SwiftData and should be testable.

**Example:**

```swift
import ComposableArchitecture
import SwiftData

@DependencyClient
struct PersonalizationClient {
    var computeAffinities: @Sendable ([GuestBookmark], [GuestSkip]) async -> [AffinityScore]
    var interactionCount: @Sendable ([GuestBookmark], [GuestSkip]) async -> Int
    var rerankFeed: @Sendable ([RecipeCard], [AffinityScore]) async -> [RecipeCard]
}

extension PersonalizationClient: DependencyKey {
    static let liveValue = PersonalizationClient(
        computeAffinities: { bookmarks, skips in
            await CulinaryDNAEngine().computeAffinities(bookmarks: bookmarks, skips: skips)
        },
        interactionCount: { bookmarks, skips in
            await CulinaryDNAEngine().interactionCount(bookmarks: bookmarks, skips: skips)
        },
        rerankFeed: { recipes, affinities in
            await FeedRanker().rerank(recipes: recipes, affinities: affinities)
        }
    )

    static let testValue = PersonalizationClient(
        computeAffinities: { _, _ in
            [
                AffinityScore(cuisineType: "ITALIAN", score: 0.9),
                AffinityScore(cuisineType: "MEXICAN", score: 0.7)
            ]
        },
        interactionCount: { bookmarks, skips in 50 },
        rerankFeed: { recipes, _ in recipes }  // No-op in tests
    )
}

extension DependencyValues {
    var personalizationClient: PersonalizationClient {
        get { self[PersonalizationClient.self] }
        set { self[PersonalizationClient.self] = newValue }
    }
}
```

**Key insights:**
- @DependencyClient auto-generates test stubs ([source](https://github.com/pointfreeco/swift-composable-architecture))
- Async functions support SwiftData ModelContext access on main thread
- Test value provides deterministic affinities for UI testing

### Pattern 6: Progress Indicator with Conditional Rendering

**What:** Show progress toward 50-interaction threshold in Me tab, replace with affinity bars after activation.

**When to use:** Gamification to encourage user engagement with clear milestone.

**Example:**

```swift
struct CulinaryDNASection: View {
    let interactionCount: Int
    let affinities: [AffinityScore]
    let threshold: Int = 50

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Culinary DNA")
                .font(.headline)

            if interactionCount < threshold {
                // Show progress before activation
                ProgressView(value: Double(interactionCount), total: Double(threshold))
                    .tint(Colors.terracotta)

                Text("Learning... (\(interactionCount)/\(threshold) interactions)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                // Show affinity bars after activation
                ForEach(affinities.prefix(5), id: \.cuisineType) { affinity in
                    AffinityBar(
                        cuisineType: affinity.cuisineType,
                        score: affinity.score
                    )
                }
            }
        }
        .padding()
        .background(Colors.cream)
        .cornerRadius(12)
    }
}

struct AffinityBar: View {
    let cuisineType: String
    let score: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(cuisineType.capitalized)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(score * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))

                    // Filled bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Colors.terracotta)
                        .frame(width: geometry.size.width * score)
                }
            }
            .frame(height: 8)
        }
    }
}
```

**Key insights:**
- Conditional rendering based on threshold creates clear activation moment
- ProgressView with tint matches brand colors
- Top 5 affinities prevent UI clutter (user decision: "top 3-5 cuisines")

### Anti-Patterns to Avoid

- **Using Core ML for simple affinity calculation:** Overkill for weighted sum over 7 dietary tags + ~40 cuisine types; adds complexity, training overhead, model updates
- **Server-side personalization without auth:** Can't track guest users server-side without UUID sync; on-device is simpler for MVP
- **Hard filter instead of soft boost:** Filtering out low-affinity cuisines creates filter bubble, reduces discovery
- **Linear decay for recency:** Doesn't model taste evolution as well as exponential; old interactions linger too long
- **Storing raw bookmark/skip arrays in @AppStorage:** Exceeds 512KB limit; use SwiftData queries on-demand instead ([source](https://www.avanderlee.com/swift/user-defaults-preferences/))
- **Equal weight for skips and bookmarks:** Bookmarks are stronger positive signals; equal weighting under-values user intent ([source](https://builtin.com/data-science/recommender-systems))

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Recommendation ML model | Custom Core ML training pipeline | Simple weighted affinity calculation | 50 interactions too few for ML; weighted sum is interpretable, debuggable, instant |
| UserDefaults wrapper | Custom Codable persistence layer | @AppStorage property wrapper | @AppStorage auto-updates UI, less boilerplate, SwiftUI-native |
| Recency decay formula | Custom time-based weighting | Exponential decay (0.5^(age/halfLife)) | Well-studied in recommender systems, models taste evolution, adjustable via halfLife parameter |
| Feed re-ranking algorithm | Custom sorting heuristics | 60/40 personalization/discovery split | Proven exploration/exploitation tradeoff, prevents filter bubble while personalizing |
| Complex chip selection state management | Manual @State + callbacks | @AppStorage with Set<String> encoding | Persists across launches, auto-saves, migration-friendly for Phase 8 |

**Key insight:** This phase requires minimal custom logic — @AppStorage handles persistence, SwiftData provides raw data, simple weighted math computes affinity, re-sorting is one-liner. Don't over-engineer with ML frameworks or custom state management.

## Common Pitfalls

### Pitfall 1: @AppStorage Set<String> Encoding Issues

**What goes wrong:** @AppStorage doesn't natively support Set<String>, causing runtime crashes when trying to save dietary preferences.

**Why it happens:** @AppStorage only supports property list types (String, Int, Bool, Data, etc.), not collections.

**How to avoid:**
- Encode Set<String> as Data using JSONEncoder/JSONDecoder ([source](https://www.hackingwithswift.com/books/ios-swiftui/storing-user-settings-with-userdefaults))
- Alternative: store as comma-separated String and parse on read
- Provide default empty Set if decoding fails

**Warning signs:**
- App crashes on chip tap with "not a property list type" error
- Dietary preferences don't persist after app restart
- SwiftUI preview crashes when accessing @AppStorage

### Pitfall 2: Affinity Calculation Performance on Large History

**What goes wrong:** Computing affinity scores on every feed load becomes slow as bookmark/skip count grows (1000+ interactions).

**Why it happens:** Iterating over all SwiftData records without pagination, performing exponential decay on each, every time feed loads.

**How to avoid:**
- Cache affinity scores in UserDefaults, recompute only on new bookmark/skip
- Limit history window to last 6 months (truncate older records from calculation)
- Use @Query with limit and date predicate to fetch recent interactions only
- Debounce affinity recomputation (e.g., every 10th interaction, not every swipe)

**Warning signs:**
- Feed loads slowly after activation (2+ seconds)
- Affinity calculation blocks main thread
- Memory usage spikes during DNA computation

### Pitfall 3: Empty Filter Results with No Fallback

**What goes wrong:** User selects multiple dietary filters (e.g., Vegan + Keto + Halal), gets zero results, sees blank screen with no guidance.

**Why it happens:** AND logic is too restrictive; local recipes don't match all selected tags.

**How to avoid:**
- Show EmptyStateView with "No [filters] recipes nearby. Try removing a filter?" (user decision)
- Provide "Clear Filters" button in empty state
- Alternative: backend filter relaxation (already implemented in `getFeedWithFilterRelaxation`)
- Consider showing count of active filters in chip bar ("Showing 0 recipes with 3 filters")

**Warning signs:**
- Users report "app broken" after selecting multiple filters
- Analytics show high filter abandonment rate
- Empty state shown frequently

### Pitfall 4: DNA Activation Card Shown Multiple Times

**What goes wrong:** One-time activation card re-appears every session or after dismissal.

**Why it happens:** Dismissal state not persisted, or threshold check logic triggers on every feed load.

**How to avoid:**
- Store "hasSeenDNAActivation" in @AppStorage, check before showing card
- Only show card once when interactionCount crosses 50 threshold (not on every load >= 50)
- Use TCA state to track threshold crossing event, not just count comparison

**Warning signs:**
- Activation card appears every app launch
- Card re-appears after user dismisses it
- Analytics show activation event fired multiple times per user

### Pitfall 5: "For You" Badge on All Recipes When DNA Active

**What goes wrong:** Every recipe shows "For You" badge after activation, defeating its purpose as personalization signal.

**Why it happens:** Logic shows badge whenever DNA is active, not when recipe is actually boosted by affinity.

**How to avoid:**
- Only show "For You" badge on recipes with affinity score > threshold (e.g., 0.5)
- Badge appears when recipe's cuisine matches top 3-5 affinities
- Use re-ranked position change as signal (e.g., recipe moved up 5+ positions after re-ranking)

**Warning signs:**
- All recipes have "For You" badge after activation
- Badge becomes meaningless visual clutter
- Users confused about what "For You" means

### Pitfall 6: GuestBookmark/GuestSkip Missing cuisineType Field

**What goes wrong:** Affinity calculation fails because GuestBookmark/GuestSkip models don't store cuisineType, only recipeId.

**Why it happens:** Phase 5 models store minimal data; cuisineType must be denormalized or looked up.

**How to avoid:**
- Add `cuisineType: String` field to GuestBookmark and GuestSkip models
- Store cuisineType on bookmark/skip to avoid recipe lookup (denormalization)
- Alternative: query RecipeCard by recipeId from Apollo cache, but this is slower and cache may evict

**Warning signs:**
- DNA computation returns empty affinities
- cuisineType is nil when iterating bookmarks/skips
- Affinity bars never populate in Me tab

### Pitfall 7: Dietary Filters Not Cleared on Location Change

**What goes wrong:** User changes location from Istanbul to Tokyo, but vegan filter from Istanbul remains active, showing no Japanese vegan recipes.

**Why it happens:** Dietary filters are persistent preferences, don't auto-clear on location change.

**How to avoid:**
- This is CORRECT behavior per user decision: "Auto-apply saved preferences on app launch"
- If user wants different filters per location, they manually adjust chips
- Consider showing subtle hint: "No vegan recipes in Tokyo. Try removing filters or changing location."
- Don't auto-clear filters — let user decide

**Warning signs:**
- User confusion when switching locations
- Empty results after location change
- Support requests about "recipes not loading"

### Pitfall 8: Recency Decay Calculation Overflow for Very Old Dates

**What goes wrong:** Exponential decay calculation (`pow(0.5, age / halfLife)`) returns NaN or crashes for bookmarks from years ago.

**Why it happens:** Large `age` values cause floating-point overflow in pow() function.

**How to avoid:**
- Clamp minimum weight to 0.001 (effectively ignore interactions older than ~1 year)
- Filter out interactions older than max window (e.g., 6 months) before calculation
- Use `max(0.001, pow(0.5, age / halfLife))` to prevent underflow

**Warning signs:**
- Affinity scores are NaN
- DNA computation crashes with floating-point exception
- Affinity bars show as empty despite hundreds of bookmarks

## Code Examples

Verified patterns from research and existing codebase:

### Dietary Chip Toggle with @AppStorage

```swift
// Based on: https://medium.com/@ramdhas/mastering-swiftui-best-practices-for-efficient-user-preference-management-with-appstorage-cf088f4ca90c

struct DietaryChipBar: View {
    @AppStorage("dietaryPreferences") private var dietaryPreferencesData: Data = Data()
    let onFilterChanged: (Set<String>) -> Void

    private var dietaryPreferences: Set<String> {
        get {
            (try? JSONDecoder().decode(Set<String>.self, from: dietaryPreferencesData)) ?? []
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                dietaryPreferencesData = encoded
            }
        }
    }

    let allTags = ["Vegan", "Vegetarian", "Gluten-free", "Dairy-free", "Keto", "Halal", "Nut-free"]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(allTags, id: \.self) { tag in
                    DietaryChip(
                        title: tag,
                        isSelected: dietaryPreferences.contains(tag)
                    ) {
                        toggleFilter(tag)
                    }
                }

                if !dietaryPreferences.isEmpty {
                    Button {
                        clearAllFilters()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 44)
    }

    private func toggleFilter(_ tag: String) {
        var updated = dietaryPreferences
        if updated.contains(tag) {
            updated.remove(tag)
        } else {
            updated.insert(tag)
        }
        dietaryPreferences = updated
        onFilterChanged(updated)
    }

    private func clearAllFilters() {
        dietaryPreferences = []
        onFilterChanged([])
    }
}
```

### Culinary DNA Affinity Calculation

```swift
// Based on: exponential decay pattern from https://thesis.eur.nl/pub/63345/FinalThesis_HannaHurenkamp.pdf

@MainActor
class CulinaryDNAEngine {
    private let bookmarkWeight: Double = 2.0
    private let skipWeight: Double = 1.0
    private let decayHalfLife: TimeInterval = 30 * 24 * 60 * 60  // 30 days

    func computeAffinities(
        bookmarks: [GuestBookmark],
        skips: [GuestSkip]
    ) -> [AffinityScore] {
        var cuisineScores: [String: Double] = [:]
        let now = Date()

        // Process bookmarks (positive signal, 2x weight)
        for bookmark in bookmarks {
            guard let cuisine = bookmark.cuisineType else { continue }
            let recencyWeight = exponentialDecay(age: now.timeIntervalSince(bookmark.createdAt))
            cuisineScores[cuisine, default: 0] += bookmarkWeight * recencyWeight
        }

        // Process skips (negative signal, 1x weight, divided by 5)
        for skip in skips {
            guard let cuisine = skip.cuisineType else { continue }
            let recencyWeight = exponentialDecay(age: now.timeIntervalSince(skip.createdAt))
            cuisineScores[cuisine, default: 0] -= (skipWeight * recencyWeight) / 5.0
        }

        // Normalize to 0-1 range
        let maxScore = cuisineScores.values.max() ?? 1.0
        guard maxScore > 0 else { return [] }

        return cuisineScores.map { cuisine, score in
            AffinityScore(
                cuisineType: cuisine,
                score: max(0, score / maxScore)
            )
        }
        .sorted { $0.score > $1.score }
    }

    private func exponentialDecay(age: TimeInterval) -> Double {
        // Clamp to prevent underflow for very old interactions
        return max(0.001, pow(0.5, age / decayHalfLife))
    }
}
```

### FeedReducer Extension for Dietary Filters

```swift
@Reducer
struct FeedReducer {
    @ObservableState
    struct State {
        var activeDietaryFilters: Set<String> = []
        var culinaryDNAAffinities: [AffinityScore] = []
        var interactionCount: Int = 0
        var hasSeenDNAActivation: Bool = false
        // ... existing state
    }

    enum Action {
        case dietaryFilterChanged(Set<String>)
        case computeCulinaryDNA
        case culinaryDNAComputed([AffinityScore], Int)
        case dismissDNAActivationCard
        // ... existing actions
    }

    @Dependency(\.personalizationClient) var personalization
    @Dependency(\.apolloClient) var apollo

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case let .dietaryFilterChanged(filters):
            state.activeDietaryFilters = filters
            state.isLoading = true

            return .run { [location = state.location] send in
                let filterInput = filters.isEmpty ? nil : KindredAPI.FeedFiltersInput(
                    cuisineTypes: nil,
                    mealTypes: nil,
                    dietaryTags: Array(filters)
                )

                let result = try await apollo.fetch(
                    query: KindredAPI.FeedQuery(
                        latitude: location.latitude,
                        longitude: location.longitude,
                        first: 20,
                        filters: filterInput
                    ),
                    cachePolicy: .fetchIgnoringCacheData
                )

                await send(.recipesLoaded(.success(result.data?.feed.edges.map(\.node) ?? [])))
            }

        case .computeCulinaryDNA:
            return .run { send in
                // Fetch bookmarks and skips from SwiftData
                let bookmarks = try await guestSessionClient.fetchBookmarks()
                let skips = try await guestSessionClient.fetchSkips()

                // Compute affinities
                let affinities = await personalization.computeAffinities(bookmarks, skips)
                let count = await personalization.interactionCount(bookmarks, skips)

                await send(.culinaryDNAComputed(affinities, count))
            }

        case let .culinaryDNAComputed(affinities, count):
            state.culinaryDNAAffinities = affinities
            state.interactionCount = count

            // Re-rank feed if DNA is active (50+ interactions)
            if count >= 50, !state.cardStack.isEmpty {
                return .run { [cardStack = state.cardStack, affinities] send in
                    let reranked = await personalization.rerankFeed(cardStack, affinities)
                    await send(.feedReranked(reranked))
                }
            }

            return .none

        case .dismissDNAActivationCard:
            state.hasSeenDNAActivation = true
            return .none
        }
    }
}
```

### "For You" Badge Component

```swift
// Pattern from existing ViralBadge component

struct ForYouBadge: View {
    var body: some View {
        Text("For You")
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Colors.terracotta.opacity(0.9))
            )
            .foregroundColor(.white)
    }
}

// Usage on RecipeCardView:
ZStack(alignment: .bottomLeading) {
    // Card content

    if recipe.isPersonalized {
        ForYouBadge()
            .padding(12)
    }
}
```

### Me Tab Dietary Preferences Section

```swift
struct DietaryPreferencesSection: View {
    @AppStorage("dietaryPreferences") private var dietaryPreferencesData: Data = Data()
    let onPreferencesChanged: (Set<String>) -> Void

    private var dietaryPreferences: Set<String> {
        get {
            (try? JSONDecoder().decode(Set<String>.self, from: dietaryPreferencesData)) ?? []
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                dietaryPreferencesData = encoded
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dietary Preferences")
                .font(.headline)

            // Same chip bar as feed
            DietaryChipBar(onFilterChanged: onPreferencesChanged)

            if !dietaryPreferences.isEmpty {
                Button("Reset Dietary Preferences") {
                    dietaryPreferences = []
                    onPreferencesChanged([])
                }
                .font(.subheadline)
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Colors.cream)
        .cornerRadius(12)
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual UserDefaults observation | @AppStorage property wrapper | iOS 14 (2020) | Auto-updates UI on value change, less boilerplate |
| Core ML MLRecommender | Simple weighted affinity calculation | N/A (depends on use case) | ML is overkill for <1000 interactions; weighted sum is interpretable |
| Linear recency decay | Exponential decay (0.5^(age/halfLife)) | N/A (recommender systems research) | Better models taste evolution, adjustable via halfLife |
| Hard filtering (exclude low affinity) | Soft boost (60/40 personalization/discovery) | N/A (exploration/exploitation tradeoff) | Prevents filter bubble while personalizing |
| Server-side personalization | On-device computation | iOS privacy push (2020+) | Privacy-preserving, instant, works offline |

**Deprecated/outdated:**
- **Manual UserDefaults .observe():** Use @AppStorage for automatic SwiftUI updates
- **Core Data UserDefaults syncing:** Use @AppStorage with Codable types, simpler
- **Hard-coded dietary tag lists:** Store centrally, fetch from backend if tags expand (future-proofing)

## Open Questions

1. **Exact dietary tag list standardization**
   - What we know: 7 tags (Vegan, Vegetarian, Gluten-free, Dairy-free, Keto, Halal, Nut-free) per user decision
   - What's unclear: Are these exact strings backend expects? Case-sensitive?
   - Recommendation: Verify with backend schema, use enum or constants file for consistency

2. **GuestBookmark/GuestSkip cuisineType storage**
   - What we know: Models exist from Phase 5, need cuisineType for affinity calculation
   - What's unclear: Do models already have cuisineType field, or must it be added?
   - Recommendation: Inspect Phase 5 models, add field if missing, migrate existing data

3. **DNA activation card dismissal persistence**
   - What we know: One-time card shown when crossing 50 interactions
   - What's unclear: Store dismissal in @AppStorage or TCA state? Reset on logout?
   - Recommendation: @AppStorage("hasSeenDNAActivation") persists across launches, reset in Phase 8 logout

4. **Empty filter result UX**
   - What we know: Show EmptyStateView with "Try removing a filter?" message
   - What's unclear: Should backend automatically relax filters (getFeedWithFilterRelaxation)?
   - Recommendation: Backend already implements relaxation — use it on empty results, show "Showing similar recipes" badge

5. **"For You" badge threshold**
   - What we know: Show badge on recipes boosted by DNA
   - What's unclear: What affinity score qualifies as "boosted"? Top 3 cuisines? Score > 0.5?
   - Recommendation: Show badge when recipe's cuisine is in top 3 affinities (simple, interpretable)

## Sources

### Primary (HIGH confidence)

- [Apple Developer: UserDefaults](https://developer.apple.com/documentation/foundation/userdefaults) - Official UserDefaults API
- [Apple Developer: @AppStorage](https://developer.apple.com/documentation/swiftui/appstorage) - SwiftUI property wrapper documentation
- [Apollo iOS GraphQL Client](https://www.apollographql.com/docs/ios/) - GraphQL query with filters
- [Mastering SwiftUI: @AppStorage Best Practices](https://medium.com/@ramdhas/mastering-swiftui-best-practices-for-efficient-user-preference-management-with-appstorage-cf088f4ca90c)
- [Storing User Settings with UserDefaults - Hacking with Swift](https://www.hackingwithswift.com/books/ios-swiftui/storing-user-settings-with-userdefaults)

### Secondary (MEDIUM confidence)

- [Simplifying Food Discovery for Users with Dietary Restrictions](https://www.michaelc.design/doordash-dietary-preferences) - DoorDash dietary filtering UX case study
- [Improving UX in Food Delivery Apps](http://www.nicolletta.com/2025/02/06/improving-user-experience-in-food-delivery-apps-recommendations-for-clarity-customization-and-engagement/) - Food app filtering best practices
- [Recency Adapted Next Basket Recommendation](https://thesis.eur.nl/pub/63345/FinalThesis_HannaHurenkamp.pdf) - Recency weighting in recommendations
- [Recency-Weighted Scoring Explained](https://customers.ai/recency-weighted-scoring) - Exponential decay pattern
- [Recommender Systems: In-Depth Guide](https://builtin.com/data-science/recommender-systems) - Exploration/exploitation tradeoff
- [Training Recommendation Models in Create ML - WWDC19](https://developer.apple.com/videos/play/wwdc2019/427/) - Apple's recommendation framework
- [MLRecommender - Apple Developer](https://developer.apple.com/documentation/createml/mlrecommender) - Create ML recommendation model
- [Building a Recommendation App With Create ML](https://www.kodeco.com/34652639-building-a-recommendation-app-with-create-ml-in-swiftui) - SwiftUI recommendation patterns
- [The Advanced Guide to UserDefaults in Swift](https://www.vadimbulavin.com/advanced-guide-to-userdefaults-in-swift/) - Migration-friendly UserDefaults architecture
- [User Defaults in Swift - SwiftLee](https://www.avanderlee.com/swift/user-defaults-preferences/) - Best practices and limitations
- [Apple Music Algorithm Guide 2026](https://beatstorapon.com/blog/the-apple-music-algorithm-in-2026-a-comprehensive-guide-for-artists-labels-and-data-scientists/) - Recency bias and affinity weighting
- [iOS Privacy Changes Affecting Tracking: 2026 Guide](https://www.cometly.com/post/ios-privacy-changes-affecting-tracking) - On-device ML for privacy
- [Meet privacy-preserving ad attribution - WWDC21](https://developer.apple.com/videos/play/wwdc2021/10033/) - On-device machine learning patterns

### Tertiary (LOW confidence - flagged for validation)

- [Apple Core AI: iOS 27 Signals New Framework](https://applemagazine.com/apple-core-ai/) - Potential Core ML replacement (2026 speculation, not confirmed by Apple)
- [GitHub - CollaborativeFiltering](https://github.com/ryanashcraft/CollaborativeFiltering) - Third-party library (not needed for this phase)

## Metadata

**Confidence breakdown:**
- Standard stack: **HIGH** - All libraries already integrated (@AppStorage, SwiftData, TCA, Apollo)
- Architecture: **MEDIUM** - Chip bar pattern well-documented; affinity calculation based on research papers but not iOS-specific
- Pitfalls: **MEDIUM** - Based on UserDefaults best practices and common SwiftData issues; DNA-specific pitfalls are hypothetical
- Personalization patterns: **MEDIUM** - Exponential decay and soft-boost well-studied in recommender systems, but not verified for cuisine affinity specifically

**Research date:** 2026-03-03
**Valid until:** 2026-04-02 (30 days for stable frameworks; SwiftUI/@AppStorage patterns evolve slowly)

---

*Phase 6: Dietary Filtering & Personalization*
*Research complete: 2026-03-03*
