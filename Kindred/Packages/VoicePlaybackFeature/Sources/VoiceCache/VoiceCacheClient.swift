import Dependencies
import Foundation

// MARK: - NarrationCacheMetadata

public struct NarrationCacheMetadata: Codable, Sendable {
    public let duration: TimeInterval
    public let stepTimestamps: [TimeInterval]
    public let generatedAt: Date

    public init(duration: TimeInterval, stepTimestamps: [TimeInterval], generatedAt: Date) {
        self.duration = duration
        self.stepTimestamps = stepTimestamps
        self.generatedAt = generatedAt
    }
}

// MARK: - VoiceCacheClient

public struct VoiceCacheClient {
    public var cacheAudio: @Sendable (String, String, Data) async throws -> URL
    public var getCachedAudio: @Sendable (String, String) async -> URL?
    public var isCached: @Sendable (String, String) -> Bool
    public var totalCacheSize: @Sendable () -> Int64
    public var clearCache: @Sendable () async throws -> Void
    public var cacheMetadata: @Sendable (String, String, NarrationCacheMetadata) async throws -> Void
    public var getCachedMetadata: @Sendable (String, String) async -> NarrationCacheMetadata?
}

// MARK: - DependencyKey

extension VoiceCacheClient: DependencyKey {
    public static var liveValue: VoiceCacheClient {
        let fileManager = FileManager.default
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("VoiceNarrations", isDirectory: true)

        // Ensure cache directory exists
        try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)

        func metadataURL(voiceId: String, recipeId: String) -> URL {
            cacheDir.appendingPathComponent("\(voiceId)_\(recipeId)_metadata.json")
        }

        func audioURL(voiceId: String, recipeId: String) -> URL {
            // ElevenLabs returns MP3 (audio/mpeg). Previous builds saved as .m4a,
            // which AVPlayer couldn't decode from the local cache — the HTTP play
            // succeeded but every cached replay errored. Old .m4a orphans in the
            // cache dir are simply ignored by fileExists since the extension no
            // longer matches; they get evicted by the system's cache management.
            cacheDir.appendingPathComponent("\(voiceId)_\(recipeId).mp3")
        }

        return VoiceCacheClient(
            cacheAudio: { voiceId, recipeId, data in
                let url = audioURL(voiceId: voiceId, recipeId: recipeId)
                try data.write(to: url)
                return url
            },
            getCachedAudio: { voiceId, recipeId in
                let url = audioURL(voiceId: voiceId, recipeId: recipeId)
                return fileManager.fileExists(atPath: url.path) ? url : nil
            },
            isCached: { voiceId, recipeId in
                fileManager.fileExists(atPath: audioURL(voiceId: voiceId, recipeId: recipeId).path)
            },
            totalCacheSize: {
                guard let enumerator = fileManager.enumerator(at: cacheDir, includingPropertiesForKeys: [.fileSizeKey]) else {
                    return 0
                }
                var totalSize: Int64 = 0
                for case let fileURL as URL in enumerator {
                    guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                          let fileSize = resourceValues.fileSize else {
                        continue
                    }
                    totalSize += Int64(fileSize)
                }
                return totalSize
            },
            clearCache: {
                try? fileManager.removeItem(at: cacheDir)
                try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
            },
            cacheMetadata: { voiceId, recipeId, metadata in
                let url = metadataURL(voiceId: voiceId, recipeId: recipeId)
                let data = try JSONEncoder().encode(metadata)
                try data.write(to: url)
            },
            getCachedMetadata: { voiceId, recipeId in
                let url = metadataURL(voiceId: voiceId, recipeId: recipeId)
                guard fileManager.fileExists(atPath: url.path),
                      let data = try? Data(contentsOf: url) else {
                    return nil
                }
                return try? JSONDecoder().decode(NarrationCacheMetadata.self, from: data)
            }
        )
    }

    public static var testValue: VoiceCacheClient {
        VoiceCacheClient(
            cacheAudio: { _, _, _ in URL(fileURLWithPath: "/tmp/test.m4a") },
            getCachedAudio: { _, _ in nil },
            isCached: { _, _ in false },
            totalCacheSize: { 0 },
            clearCache: { },
            cacheMetadata: { _, _, _ in },
            getCachedMetadata: { _, _ in nil }
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
