import Foundation

/// Ad unit IDs for AdMob integration
public struct AdUnitIDs {
    /// Google's test native ad unit ID for feed cards
    /// Replace with production ad unit ID from AdMob console before App Store submission
    public static let feedNative = "ca-app-pub-3940256099942544/3986624511"

    /// Google's test banner ad unit ID for recipe detail
    /// Replace with production ad unit ID from AdMob console before App Store submission
    public static let detailBanner = "ca-app-pub-3940256099942544/2435281174"
}

/// Represents the loading state of an ad
public enum AdLoadState: Equatable, Sendable {
    case idle
    case loading
    case loaded
    case failed(String)
}
