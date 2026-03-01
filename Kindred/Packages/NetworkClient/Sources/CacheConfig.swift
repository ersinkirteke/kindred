import Apollo
import Foundation

/// Cache policy configuration for offline-first data fetching
public enum CachePolicy {
    /// Fetch from cache first, then update from network (offline-first UX)
    public static let offlineFirst: Apollo.CachePolicy = .returnCacheDataAndFetch

    /// Network only, no cache (for real-time data)
    public static let networkOnly: Apollo.CachePolicy = .fetchIgnoringCacheData

    /// Cache only (for truly offline scenarios)
    public static let cacheOnly: Apollo.CachePolicy = .returnCacheDataDontFetch
}
