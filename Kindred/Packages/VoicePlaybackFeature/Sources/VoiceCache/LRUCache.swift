import Foundation

// MARK: - VoiceCache

public class VoiceCache {
    public static let shared = VoiceCache()

    private let maxCacheSizeBytes: Int64 = 500 * 1024 * 1024 // 500MB
    private let cacheDirectory: URL
    private let metadataKey = "voiceCache_metadata"

    private init() {
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = cachesDir.appendingPathComponent("VoiceNarrations", isDirectory: true)

        // Create cache directory if it doesn't exist
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Public Methods

    public func cacheAudio(voiceId: String, recipeId: String, data: Data) async throws -> URL {
        let fileName = "\(voiceId)_\(recipeId).m4a"
        let fileURL = cacheDirectory.appendingPathComponent(fileName)

        // Write audio data to file
        try data.write(to: fileURL)

        // Get file size
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let sizeBytes = attributes[.size] as? Int64 ?? 0

        // Create cache entry
        let entry = CacheEntry(
            voiceId: voiceId,
            recipeId: recipeId,
            fileName: fileName,
            sizeBytes: sizeBytes,
            lastAccessTime: Date(),
            createdAt: Date()
        )

        // Save metadata
        var entries = loadMetadata()

        // Remove existing entry if present (update scenario)
        entries.removeAll { $0.cacheKey == entry.cacheKey }

        entries.append(entry)
        saveMetadata(entries)

        // Evict if needed
        try await evictIfNeeded()

        return fileURL
    }

    public func getCachedAudio(voiceId: String, recipeId: String) async -> URL? {
        let fileName = "\(voiceId)_\(recipeId).m4a"
        let fileURL = cacheDirectory.appendingPathComponent(fileName)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        // Update last access time (LRU touch)
        var entries = loadMetadata()
        if let index = entries.firstIndex(where: { $0.cacheKey == "\(voiceId)_\(recipeId)" }) {
            var entry = entries[index]
            entry = CacheEntry(
                voiceId: entry.voiceId,
                recipeId: entry.recipeId,
                fileName: entry.fileName,
                sizeBytes: entry.sizeBytes,
                lastAccessTime: Date(),
                createdAt: entry.createdAt
            )
            entries[index] = entry
            saveMetadata(entries)
        }

        return fileURL
    }

    public func isCached(voiceId: String, recipeId: String) -> Bool {
        let fileName = "\(voiceId)_\(recipeId).m4a"
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    public func getTotalCacheSize() -> Int64 {
        let entries = loadMetadata()
        return entries.reduce(0) { $0 + $1.sizeBytes }
    }

    public func clearAll() throws {
        // Remove all files in cache directory
        try FileManager.default.removeItem(at: cacheDirectory)

        // Recreate empty directory
        try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // Clear metadata
        UserDefaults.standard.removeObject(forKey: metadataKey)
    }

    // MARK: - Private Methods

    private func evictIfNeeded() async throws {
        var entries = loadMetadata()
        var totalSize = getTotalCacheSize()

        guard totalSize > maxCacheSizeBytes else { return }

        // Sort by last access time ascending (oldest first)
        entries.sort { $0.lastAccessTime < $1.lastAccessTime }

        // Remove oldest entries until we're under the limit
        while totalSize > maxCacheSizeBytes && !entries.isEmpty {
            let oldestEntry = entries.removeFirst()
            let fileURL = cacheDirectory.appendingPathComponent(oldestEntry.fileName)

            // Delete file
            try? FileManager.default.removeItem(at: fileURL)

            // Update total size
            totalSize -= oldestEntry.sizeBytes
        }

        // Save updated metadata
        saveMetadata(entries)
    }

    private func loadMetadata() -> [CacheEntry] {
        guard let data = UserDefaults.standard.data(forKey: metadataKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([CacheEntry].self, from: data)
        } catch {
            return []
        }
    }

    private func saveMetadata(_ entries: [CacheEntry]) {
        do {
            let data = try JSONEncoder().encode(entries)
            UserDefaults.standard.set(data, forKey: metadataKey)
        } catch {
            // Failed to save metadata
        }
    }
}
