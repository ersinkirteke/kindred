import Foundation

/// On-device personalization engine that computes cuisine affinity scores
/// from user interactions (bookmarks and skips) with exponential recency decay.
public class CulinaryDNAEngine {

    // MARK: - Constants

    /// Bookmark weight: bookmarks are 2x stronger positive signals than skips
    private let bookmarkWeight: Double = 2.0

    /// Skip weight: skips have negative influence, dampened by /5 to require 5-10 skips to cancel 1 bookmark
    private let skipWeight: Double = 1.0

    /// Exponential decay half-life: 30 days
    private let decayHalfLife: TimeInterval = 30 * 24 * 60 * 60

    /// Activation threshold: DNA activates after 50+ interactions (PERS-01)
    private let activationThreshold: Int = 50

    // MARK: - Public API

    public init() {}

    /// Computes normalized affinity scores for each cuisine type based on user interactions.
    /// - Parameters:
    ///   - bookmarks: User's bookmark history
    ///   - skips: User's skip history
    /// - Returns: Array of AffinityScore sorted by score descending, normalized to 0.0-1.0 range
    public func computeAffinities(
        bookmarks: [GuestBookmark],
        skips: [GuestSkip]
    ) -> [AffinityScore] {
        var cuisineScores: [String: Double] = [:]
        let now = Date()

        // Process bookmarks: positive signal
        for bookmark in bookmarks {
            guard let cuisine = bookmark.cuisineType, !cuisine.isEmpty else { continue }
            let age = now.timeIntervalSince(bookmark.createdAt)
            let decay = exponentialDecay(age: age)
            cuisineScores[cuisine, default: 0.0] += bookmarkWeight * decay
        }

        // Process skips: negative signal, dampened by /5
        for skip in skips {
            guard let cuisine = skip.cuisineType, !cuisine.isEmpty else { continue }
            let age = now.timeIntervalSince(skip.createdAt)
            let decay = exponentialDecay(age: age)
            cuisineScores[cuisine, default: 0.0] -= (skipWeight * decay) / 5.0
        }

        // Find max positive score for normalization
        guard let maxScore = cuisineScores.values.max(), maxScore > 0 else {
            return []
        }

        // Normalize scores to 0.0-1.0 range and create AffinityScore objects
        let affinities = cuisineScores.compactMap { (cuisine, score) -> AffinityScore? in
            let normalizedScore = max(0, score / maxScore)
            guard normalizedScore > 0 else { return nil }
            return AffinityScore(cuisineType: cuisine, score: normalizedScore)
        }

        // Sort by score descending
        return affinities.sorted { $0.score > $1.score }
    }

    /// Computes total interaction count (bookmarks + skips)
    public func interactionCount(
        bookmarks: [GuestBookmark],
        skips: [GuestSkip]
    ) -> Int {
        return bookmarks.count + skips.count
    }

    /// Checks if DNA is activated (50+ interactions)
    public func isActivated(
        bookmarks: [GuestBookmark],
        skips: [GuestSkip]
    ) -> Bool {
        return interactionCount(bookmarks: bookmarks, skips: skips) >= activationThreshold
    }

    // MARK: - Private Helpers

    /// Exponential decay function with 30-day half-life.
    /// Recent interactions carry more weight than older ones.
    /// - Parameter age: Time interval since interaction in seconds
    /// - Returns: Decay multiplier (clamped to 0.001 minimum to prevent underflow)
    private func exponentialDecay(age: TimeInterval) -> Double {
        return max(0.001, pow(0.5, age / decayHalfLife))
    }
}
