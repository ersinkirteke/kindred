import ComposableArchitecture
import Foundation

/// TCA dependency for Culinary DNA personalization engine.
/// Provides affinity computation, feed re-ranking, and badge determination.
public struct PersonalizationClient {
    public var computeAffinities: @Sendable ([GuestBookmark], [GuestSkip]) async -> [AffinityScore]
    public var interactionCount: @Sendable ([GuestBookmark], [GuestSkip]) async -> Int
    public var isActivated: @Sendable ([GuestBookmark], [GuestSkip]) async -> Bool
    public var rerankFeed: @Sendable ([RecipeCard], [AffinityScore]) async -> [RecipeCard]
    public var isPersonalized: @Sendable (RecipeCard, [AffinityScore]) async -> Bool

    public init(
        computeAffinities: @escaping @Sendable ([GuestBookmark], [GuestSkip]) async -> [AffinityScore],
        interactionCount: @escaping @Sendable ([GuestBookmark], [GuestSkip]) async -> Int,
        isActivated: @escaping @Sendable ([GuestBookmark], [GuestSkip]) async -> Bool,
        rerankFeed: @escaping @Sendable ([RecipeCard], [AffinityScore]) async -> [RecipeCard],
        isPersonalized: @escaping @Sendable (RecipeCard, [AffinityScore]) async -> Bool
    ) {
        self.computeAffinities = computeAffinities
        self.interactionCount = interactionCount
        self.isActivated = isActivated
        self.rerankFeed = rerankFeed
        self.isPersonalized = isPersonalized
    }
}

extension PersonalizationClient: DependencyKey {
    public static let liveValue: PersonalizationClient = {
        let engine = CulinaryDNAEngine()
        let ranker = FeedRanker()

        return PersonalizationClient(
            computeAffinities: { bookmarks, skips in
                engine.computeAffinities(bookmarks: bookmarks, skips: skips)
            },
            interactionCount: { bookmarks, skips in
                engine.interactionCount(bookmarks: bookmarks, skips: skips)
            },
            isActivated: { bookmarks, skips in
                engine.isActivated(bookmarks: bookmarks, skips: skips)
            },
            rerankFeed: { recipes, affinities in
                ranker.rerank(recipes: recipes, affinities: affinities)
            },
            isPersonalized: { recipe, affinities in
                ranker.isPersonalized(recipe: recipe, affinities: affinities)
            }
        )
    }()

    public static let testValue: PersonalizationClient = PersonalizationClient(
        computeAffinities: { _, _ in
            // Mock affinities: Italian (0.9), Mexican (0.7), Thai (0.5)
            [
                AffinityScore(cuisineType: "ITALIAN", score: 0.9),
                AffinityScore(cuisineType: "MEXICAN", score: 0.7),
                AffinityScore(cuisineType: "THAI", score: 0.5)
            ]
        },
        interactionCount: { _, _ in
            50  // At activation threshold
        },
        isActivated: { _, _ in
            true
        },
        rerankFeed: { recipes, _ in
            recipes  // No-op in tests
        },
        isPersonalized: { _, _ in
            false
        }
    )
}

extension DependencyValues {
    public var personalizationClient: PersonalizationClient {
        get { self[PersonalizationClient.self] }
        set { self[PersonalizationClient.self] = newValue }
    }
}
