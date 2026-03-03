import Foundation

// MARK: - CacheEntry

public struct CacheEntry: Codable, Equatable, Sendable {
    public let voiceId: String
    public let recipeId: String
    public let fileName: String
    public let sizeBytes: Int64
    public let lastAccessTime: Date
    public let createdAt: Date

    public var cacheKey: String {
        "\(voiceId)_\(recipeId)"
    }

    public init(
        voiceId: String,
        recipeId: String,
        fileName: String,
        sizeBytes: Int64,
        lastAccessTime: Date,
        createdAt: Date
    ) {
        self.voiceId = voiceId
        self.recipeId = recipeId
        self.fileName = fileName
        self.sizeBytes = sizeBytes
        self.lastAccessTime = lastAccessTime
        self.createdAt = createdAt
    }
}
