import Foundation

/// Represents a user's affinity score for a specific cuisine type.
/// Scores range from 0.0 (no affinity) to 1.0 (maximum affinity).
public struct AffinityScore: Equatable, Identifiable {
    public let cuisineType: String
    public let score: Double

    public var id: String { cuisineType }

    public init(cuisineType: String, score: Double) {
        self.cuisineType = cuisineType
        self.score = score
    }
}
