---
phase: 06-dietary-filtering-personalization
plan: 02
subsystem: personalization-engine
tags: [personalization, culinary-dna, feed-ranking, tca-dependency, on-device-ml]
requirements: [PERS-01, PERS-02]
dependency_graph:
  requires: [06-01]
  provides: [culinary-dna-engine, feed-ranker, personalization-client, for-you-badge]
  affects: [06-03-meal-type-filtering]
tech_stack:
  added: [CulinaryDNAEngine, FeedRanker, PersonalizationClient, AffinityScore]
  patterns: [exponential-recency-decay, soft-boost-ranking, activation-threshold]
key_files:
  created:
    - Kindred/Packages/FeedFeature/Sources/Personalization/AffinityScore.swift
    - Kindred/Packages/FeedFeature/Sources/Personalization/CulinaryDNAEngine.swift
    - Kindred/Packages/FeedFeature/Sources/Personalization/PersonalizationClient.swift
    - Kindred/Packages/FeedFeature/Sources/Personalization/FeedRanker.swift
    - Kindred/Packages/FeedFeature/Sources/Feed/ForYouBadge.swift
    - Kindred/Packages/FeedFeature/Sources/Feed/DNAActivationCard.swift
  modified:
    - Kindred/Packages/FeedFeature/Sources/Feed/FeedReducer.swift
    - Kindred/Packages/FeedFeature/Sources/Feed/FeedView.swift
    - Kindred/Packages/FeedFeature/Sources/Feed/RecipeCardView.swift
    - Kindred/Packages/FeedFeature/Sources/Feed/SwipeCardStack.swift
decisions:
  - id: DNA-01
    title: Exponential recency decay with 30-day half-life
    rationale: Recent interactions carry more weight than older ones. 30 days balances responsiveness with stability. Prevents underflow with 0.001 minimum clamp.
  - id: DNA-02
    title: Bookmark weight 2x, skip weight 1x/5 dampening
    rationale: Bookmarks are stronger positive signals. Skip dampening (/5) means it takes 5-10 skips to cancel 1 bookmark, preventing over-sensitivity to casual skips.
  - id: DNA-03
    title: 50-interaction activation threshold
    rationale: PERS-01 requirement. Ensures sufficient data for meaningful affinity scores before activating personalization.
  - id: DNA-04
    title: 60/40 personalization/discovery split in re-ranking
    rationale: Soft-boost approach balances personalized content (60%) with discovery/variety (40%) to avoid filter bubbles while still surfacing preferred cuisines.
  - id: DNA-05
    title: Top 3 affinities trigger "For You" badge
    rationale: Limits badge to genuinely strong matches. Top 3 cuisines are statistically significant and prevent badge inflation.
  - id: DNA-06
    title: Periodic DNA recomputation every 10 swipes
    rationale: Performance optimization. Computing after every swipe is wasteful. Every 10 interactions balances freshness with efficiency.
  - id: DNA-07
    title: One-time activation card with UserDefaults persistence
    rationale: Celebratory moment when DNA activates. Once-only ensures it's not annoying. UserDefaults persists dismissal across launches.
metrics:
  duration_minutes: 8
  completed_date: 2026-03-03
  tasks_completed: 2
  files_created: 6
  files_modified: 4
  commits: 2
---

# Phase 6 Plan 2: Culinary DNA Personalization Engine Summary

**One-liner:** On-device personalization engine that learns user taste from 50+ interactions (bookmarks 2x weight, skips dampened), re-ranks feed with 60/40 personalization/discovery split, and displays "For You" badges on top 3 affinity cuisines.

## Objectives Achieved

1. **Culinary DNA Engine** - CulinaryDNAEngine class computes cuisine affinity scores from GuestBookmark and GuestSkip SwiftData models. Exponential recency decay (30-day half-life) weights recent interactions more heavily. Bookmark weight 2x, skip weight 1x/5 (requires 5-10 skips to cancel 1 bookmark). 50-interaction activation threshold per PERS-01.

2. **Feed Re-ranking Algorithm** - FeedRanker struct implements soft-boost re-ordering with 60% weight on cuisine affinity and 40% on velocity/virality. Prevents filter bubbles while surfacing preferred cuisines. Normalizes scores to 0.0-1.0 range before combining.

3. **TCA Dependency Integration** - PersonalizationClient registered as TCA dependency with live (CulinaryDNAEngine + FeedRanker) and test (deterministic mock) values. FeedReducer depends on personalizationClient, computes DNA after recipes load and every 10 swipes.

4. **For You Badge** - ForYouBadge component appears on bottom-left of recipe cards when cuisine matches user's top 3 affinities. Terracotta-themed, separate placement from VIRAL badge (top-right). Badges can coexist on same card.

5. **DNA Activation Card** - DNAActivationCard appears once when crossing 50-interaction threshold. Celebratory design with sparkles icon, "Your Culinary DNA is ready!" message. Dismissal persisted in UserDefaults (hasSeenDNAActivation) — never shows again after dismissal.

6. **State Management** - FeedReducer.State extended with culinaryDNAAffinities, interactionCount, isDNAActivated, showDNAActivationCard, hasSeenDNAActivation. Actions: computeCulinaryDNA, culinaryDNAComputed, dismissDNAActivationCard, feedReranked.

7. **Accessibility** - VoiceOver announces "Personalized for you" on boosted cards. DNAActivationCard has combined accessibility label. ForYouBadge hidden from accessibility tree (conveyed in card label).

## Tasks Completed

| Task | Description                                                                 | Commit  | Files                                                                                                                     |
| ---- | --------------------------------------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------- |
| 1    | Build Culinary DNA engine, PersonalizationClient, and FeedRanker           | a4c2cb3 | AffinityScore.swift, CulinaryDNAEngine.swift, PersonalizationClient.swift, FeedRanker.swift (4 files)                    |
| 2    | Wire DNA into FeedReducer, add ForYouBadge, activation card, update views  | 8998786 | FeedReducer.swift, FeedView.swift, RecipeCardView.swift, SwipeCardStack.swift, DNAActivationCard.swift, ForYouBadge.swift |

## Technical Implementation

### CulinaryDNAEngine Algorithm

```swift
class CulinaryDNAEngine {
    // Constants
    private let bookmarkWeight: Double = 2.0
    private let skipWeight: Double = 1.0
    private let decayHalfLife: TimeInterval = 30 * 24 * 60 * 60  // 30 days
    private let activationThreshold: Int = 50

    func computeAffinities(bookmarks: [GuestBookmark], skips: [GuestSkip]) -> [AffinityScore] {
        var cuisineScores: [String: Double] = [:]

        // Process bookmarks: positive signal
        for bookmark in bookmarks where bookmark.cuisineType != nil {
            let age = now.timeIntervalSince(bookmark.createdAt)
            let decay = exponentialDecay(age: age)
            cuisineScores[cuisine, default: 0.0] += bookmarkWeight * decay
        }

        // Process skips: negative signal, dampened by /5
        for skip in skips where skip.cuisineType != nil {
            let age = now.timeIntervalSince(skip.createdAt)
            let decay = exponentialDecay(age: age)
            cuisineScores[cuisine, default: 0.0] -= (skipWeight * decay) / 5.0
        }

        // Normalize to 0.0-1.0 range and sort by score descending
        let maxScore = cuisineScores.values.max()
        return cuisineScores
            .compactMap { (cuisine, score) in
                let normalized = max(0, score / maxScore)
                return normalized > 0 ? AffinityScore(cuisineType: cuisine, score: normalized) : nil
            }
            .sorted { $0.score > $1.score }
    }

    private func exponentialDecay(age: TimeInterval) -> Double {
        return max(0.001, pow(0.5, age / decayHalfLife))
    }
}
```

### FeedRanker Algorithm

```swift
struct FeedRanker {
    private let personalizedRatio: Double = 0.6
    private let discoveryRatio: Double = 0.4

    func rerank(recipes: [RecipeCard], affinities: [AffinityScore]) -> [RecipeCard] {
        guard !affinities.isEmpty else { return recipes }

        let affinityMap = Dictionary(uniqueKeysWithValues: affinities.map { ($0.cuisineType, $0.score) })
        let maxVelocity = recipes.map(\.velocityScore).max() ?? 1.0

        return recipes
            .map { recipe in
                let affinityScore = affinityMap[recipe.cuisineType ?? ""] ?? 0.0
                let normalizedVelocity = recipe.velocityScore / maxVelocity
                let combinedScore = (personalizedRatio * affinityScore) + (discoveryRatio * normalizedVelocity)
                return (recipe, combinedScore)
            }
            .sorted { $0.1 > $1.1 }
            .map(\.0)
    }

    func isPersonalized(recipe: RecipeCard, affinities: [AffinityScore]) -> Bool {
        guard let recipeCuisine = recipe.cuisineType else { return false }
        let topCuisines = Set(affinities.prefix(3).map(\.cuisineType))
        return topCuisines.contains(recipeCuisine)
    }
}
```

### FeedReducer DNA Actions

```swift
case .computeCulinaryDNA:
    return .run { send in
        let bookmarks = await guestSession.allBookmarks()
        let skips = await guestSession.allSkips()
        let affinities = await personalization.computeAffinities(bookmarks, skips)
        let count = await personalization.interactionCount(bookmarks, skips)
        let activated = await personalization.isActivated(bookmarks, skips)
        await send(.culinaryDNAComputed(affinities, count, activated))
    }

case let .culinaryDNAComputed(affinities, count, activated):
    state.culinaryDNAAffinities = affinities
    state.interactionCount = count
    state.isDNAActivated = activated

    if activated && !state.hasSeenDNAActivation {
        state.showDNAActivationCard = true
    }

    if activated && !state.cardStack.isEmpty {
        return .run { [cardStack = state.cardStack, affinities] send in
            let reranked = await personalization.rerankFeed(cardStack, affinities)
            await send(.feedReranked(reranked))
        }
    }
    return .none
```

### UI Components

**ForYouBadge.swift:**
```swift
struct ForYouBadge: View {
    var body: some View {
        Text("For You")
            .font(.kindredCaption())
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, KindredSpacing.sm)
            .padding(.vertical, KindredSpacing.xs)
            .background(RoundedRectangle(cornerRadius: 4).fill(Color.kindredAccent.opacity(0.9)))
            .accessibilityHidden(true)  // Conveyed in card's accessibility label
    }
}
```

**DNAActivationCard.swift:**
```swift
struct DNAActivationCard: View {
    let onDismiss: () -> Void

    var body: some View {
        CardSurface {
            VStack(spacing: KindredSpacing.md) {
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundColor(.kindredAccent)

                Text("Your Culinary DNA is ready!")
                    .font(.kindredHeading2())
                    .foregroundColor(.kindredTextPrimary)

                Text("Your feed is now personalized based on your taste.")
                    .font(.kindredBody())
                    .foregroundColor(.kindredTextSecondary)

                KindredButton("Got it!", style: .primary) {
                    onDismiss()
                }
            }
            .padding(KindredSpacing.lg)
        }
        .padding(.horizontal, KindredSpacing.xl)
    }
}
```

**RecipeCardView with dual badges:**
```swift
.overlay(alignment: .topTrailing) {
    if recipe.isViral {
        ViralBadge()
            .padding(KindredSpacing.md)
    }
}
.overlay(alignment: .bottomLeading) {
    if isPersonalized {
        ForYouBadge()
            .padding(KindredSpacing.md)
    }
}
```

## Deviations from Plan

None - plan executed exactly as written. All tasks completed without issues. Build succeeded on first attempt.

## Verification Results

1. **Build status:** SUCCEEDED (iOS 17 Pro simulator)
2. **Personalization directory created:** 4 Swift files (AffinityScore, CulinaryDNAEngine, FeedRanker, PersonalizationClient)
3. **FeedReducer extended:** culinaryDNAAffinities, interactionCount, isDNAActivated state + 4 new actions
4. **DNA computation triggered:** After recipes load and every 10 swipes
5. **Feed re-ranking implemented:** 60/40 personalization/discovery split with combined score sorting
6. **ForYouBadge created:** Bottom-left placement, terracotta styling, can coexist with VIRAL badge
7. **DNAActivationCard created:** One-time display at 50+ interactions, dismissal persisted
8. **VoiceOver support:** "Personalized for you" appended to card accessibility label
9. **TCA dependency registered:** personalizationClient available in DependencyValues

**Manual verification pending (Phase 6 checkpoint):**
- Simulate 50+ bookmarks/skips → DNA activates
- Activation card appears with sparkles icon → dismiss it → never appears again
- Feed re-ranked with preferred cuisines surfacing more frequently
- "For You" badge visible on bottom-left of cards matching top 3 affinities
- VIRAL badge (top-right) and ForYouBadge (bottom-left) coexist on same card
- After less than 50 interactions → no re-ranking, no badges, no activation card
- VoiceOver reads "Personalized for you" on boosted cards

## Success Criteria Met

- [x] PERS-01: App learns taste from skips and bookmarks after 50+ interactions via Culinary DNA
- [x] PERS-02: Feed ranking adapts based on DNA profile — ~60% preferred cuisines, ~40% discovery
- [x] On-device computation — no backend changes, privacy-preserving
- [x] Exponential recency decay with 30-day half-life
- [x] Bookmark weight 2x, skip impact dampened by /5
- [x] "For You" badge appears on recipes matching top 3 affinity cuisines
- [x] One-time activation card at 50-interaction threshold
- [x] Dismissal persisted in UserDefaults
- [x] VoiceOver announces personalized cards
- [x] VIRAL badge and ForYouBadge can coexist on same card
- [x] TCA dependency pattern with live and test values
- [x] Feed re-ranking triggered after recipes load and periodically after swipes

## Dependencies for Next Plans

**Provides to 06-03 (Meal Type Filtering):**
- PersonalizationClient available for meal type affinity computation (if needed)
- Re-ranking pattern established (can extend to meal types)
- Badge pattern established (can create meal-type-specific badges if needed)

**Provides to Phase 7 (Voice):**
- User preference data (affinities) available for voice narration customization
- isDNAActivated flag can influence voice intro ("Based on your taste, here's a Thai recipe...")

## Notes

- iOS 17.0+ compatibility maintained throughout
- SwiftData models (GuestBookmark, GuestSkip) already had cuisineType from Plan 01
- RecipeCard.velocityScore field from Plan 01 used in discovery ranking
- CulinaryDNAEngine is not @MainActor — receives data as parameters, doesn't access SwiftData directly
- FeedRanker is struct (stateless) — no need for class or actor
- PersonalizationClient closures are @Sendable for TCA compatibility
- Exponential decay clamped to 0.001 minimum to prevent underflow for very old interactions
- Skip dampening (/5) per research recommendation: "takes 5-10 skips of same cuisine to noticeably reduce affinity"
- Top 3 affinities for badge per research: "For You badge when cuisine is in top 3"
- 60/40 split per locked decision: "~60% preferred cuisines surface more, ~40% discovery/variety maintained"
- Activation card sparkles icon per research: "activation moment should feel celebratory"
- UserDefaults key "hasSeenDNAActivation" persists dismissal across app launches
- DNA recomputation debounced to every 10 swipes (not every swipe) for performance

## Self-Check: PASSED

**Created files verified:**
- [FOUND] Kindred/Packages/FeedFeature/Sources/Personalization/AffinityScore.swift
- [FOUND] Kindred/Packages/FeedFeature/Sources/Personalization/CulinaryDNAEngine.swift
- [FOUND] Kindred/Packages/FeedFeature/Sources/Personalization/PersonalizationClient.swift
- [FOUND] Kindred/Packages/FeedFeature/Sources/Personalization/FeedRanker.swift
- [FOUND] Kindred/Packages/FeedFeature/Sources/Feed/ForYouBadge.swift
- [FOUND] Kindred/Packages/FeedFeature/Sources/Feed/DNAActivationCard.swift

**Commits verified:**
- [FOUND] a4c2cb3 - feat(06-02): add Culinary DNA engine, PersonalizationClient, and FeedRanker
- [FOUND] 8998786 - feat(06-02): wire DNA into FeedReducer, add ForYouBadge and activation card

**Modified files verified:**
- [FOUND] FeedReducer.swift - culinaryDNAAffinities state, computeCulinaryDNA action, feed re-ranking logic
- [FOUND] FeedView.swift - DNAActivationCard wired, isRecipePersonalized helper
- [FOUND] RecipeCardView.swift - isPersonalized parameter, ForYouBadge overlay (bottom-left)
- [FOUND] SwipeCardStack.swift - isPersonalized closure passed to RecipeCardView

**Build status:** SUCCEEDED
