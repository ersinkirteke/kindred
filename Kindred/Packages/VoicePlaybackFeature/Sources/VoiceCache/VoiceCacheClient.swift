import Dependencies
import Foundation

// MARK: - VoiceCacheClient

public struct VoiceCacheClient {
    public var cacheAudio: @Sendable (String, String, Data) async throws -> URL
    public var getCachedAudio: @Sendable (String, String) async -> URL?
    public var isCached: @Sendable (String, String) -> Bool
    public var totalCacheSize: @Sendable () -> Int64
    public var clearCache: @Sendable () async throws -> Void
}

// MARK: - DependencyKey

extension VoiceCacheClient: DependencyKey {
    public static var liveValue: VoiceCacheClient {
        let cache = VoiceCache.shared

        return VoiceCacheClient(
            cacheAudio: { voiceId, recipeId, data in
                try await cache.cacheAudio(voiceId: voiceId, recipeId: recipeId, data: data)
            },
            getCachedAudio: { voiceId, recipeId in
                await cache.getCachedAudio(voiceId: voiceId, recipeId: recipeId)
            },
            isCached: { voiceId, recipeId in
                cache.isCached(voiceId: voiceId, recipeId: recipeId)
            },
            totalCacheSize: {
                cache.getTotalCacheSize()
            },
            clearCache: {
                try await cache.clearAll()
            }
        )
    }

    public static var testValue: VoiceCacheClient {
        VoiceCacheClient(
            cacheAudio: { _, _, _ in URL(fileURLWithPath: "/tmp/test.m4a") },
            getCachedAudio: { _, _ in nil },
            isCached: { _, _ in false },
            totalCacheSize: { 0 },
            clearCache: { }
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {
    public var voiceCacheClient: VoiceCacheClient {
        get { self[VoiceCacheClient.self] }
        set { self[VoiceCacheClient.self] = newValue }
    }
}
