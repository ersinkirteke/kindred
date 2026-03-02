import Foundation

/// Soft-boost re-ranking algorithm for feed personalization.
/// Balances personalized content (60%) with discovery/variety (40%).
public struct FeedRanker {

    // MARK: - Constants

    /// Personalized ratio: 60% weight on cuisine affinity
    private let personalizedRatio: Double = 0.6

    /// Discovery ratio: 40% weight on velocity/virality
    private let discoveryRatio: Double = 0.4

    // MARK: - Public API

    public init() {}

    /// Re-ranks recipes using combined personalization and discovery scores.
    /// - Parameters:
    ///   - recipes: Original recipe feed
    ///   - affinities: User's cuisine affinity scores
    /// - Returns: Re-ranked recipes sorted by combined score descending
    public func rerank(
        recipes: [RecipeCard],
        affinities: [AffinityScore]
    ) -> [RecipeCard] {
        guard !affinities.isEmpty else { return recipes }

        // Build affinity lookup map
        let affinityMap = Dictionary(uniqueKeysWithValues: affinities.map { ($0.cuisineType, $0.score) })

        // Find max velocity for normalization
        let maxVelocity = recipes.map(\.velocityScore).max() ?? 1.0
        let velocityNormalizer = maxVelocity > 0 ? maxVelocity : 1.0

        // Compute combined scores and sort
        let rankedRecipes = recipes.map { recipe -> (recipe: RecipeCard, score: Double) in
            let affinityScore = recipe.cuisineType.flatMap { affinityMap[$0] } ?? 0.0
            let normalizedVelocity = recipe.velocityScore / velocityNormalizer
            let combinedScore = (personalizedRatio * affinityScore) + (discoveryRatio * normalizedVelocity)
            return (recipe, combinedScore)
        }
        .sorted { $0.score > $1.score }
        .map(\.recipe)

        return rankedRecipes
    }

    /// Determines if a recipe should show the "For You" badge.
    /// Badge appears when recipe's cuisine is in user's top 3 affinities.
    /// - Parameters:
    ///   - recipe: Recipe to check
    ///   - affinities: User's cuisine affinity scores
    /// - Returns: True if recipe matches top 3 cuisines
    public func isPersonalized(
        recipe: RecipeCard,
        affinities: [AffinityScore]
    ) -> Bool {
        guard let recipeCuisine = recipe.cuisineType else { return false }
        let topCuisines = Set(affinities.prefix(3).map(\.cuisineType))
        return topCuisines.contains(recipeCuisine)
    }
}
