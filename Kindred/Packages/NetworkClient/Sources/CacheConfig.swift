import Apollo
import Foundation

/// Cache policy presets for offline-first data fetching
public enum KindredCachePolicy {
    /// Fetch from cache first, else fetch from network (offline-first UX)
    public static let offlineFirst: CachePolicy.Query.SingleResponse = .cacheFirst

    /// Network only, no cache (for real-time data)
    public static let networkOnly: CachePolicy.Query.SingleResponse = .networkOnly

    /// Network first, fall back to cache on failure
    public static let networkFirst: CachePolicy.Query.SingleResponse = .networkFirst
}
