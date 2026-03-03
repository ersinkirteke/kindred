import Foundation

// MARK: - NarrationMetadata

public struct NarrationMetadata: Equatable, Codable, Sendable {
    public let recipeId: String
    public let voiceId: String
    public let audioURL: String
    public let duration: TimeInterval
    public let stepTimestamps: [TimeInterval]
    public let generatedAt: Date

    public init(
        recipeId: String,
        voiceId: String,
        audioURL: String,
        duration: TimeInterval,
        stepTimestamps: [TimeInterval],
        generatedAt: Date
    ) {
        self.recipeId = recipeId
        self.voiceId = voiceId
        self.audioURL = audioURL
        self.duration = duration
        self.stepTimestamps = stepTimestamps
        self.generatedAt = generatedAt
    }
}
