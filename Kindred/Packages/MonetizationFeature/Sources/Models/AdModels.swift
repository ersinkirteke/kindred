import Foundation

/// Ad unit IDs from xcconfig build settings (Debug: test IDs, Release: production)
public struct AdUnitIDs {
    /// Feed native ad unit ID — reads from ADMOB_FEED_NATIVE_ID in xcconfig
    public static let feedNative: String = {
        guard let id = Bundle.main.object(forInfoDictionaryKey: "ADMOB_FEED_NATIVE_ID") as? String,
              !id.isEmpty,
              !id.contains("REPLACE") else {
            #if DEBUG
            // Fallback to test ID in debug if Info.plist injection fails
            return "ca-app-pub-3940256099942544/3986624511"
            #else
            fatalError("ADMOB_FEED_NATIVE_ID not configured. Update Config/Release.xcconfig with production ad unit IDs from https://apps.admob.com/")
            #endif
        }
        return id
    }()

    /// Recipe detail banner ad unit ID — reads from ADMOB_DETAIL_BANNER_ID in xcconfig
    public static let detailBanner: String = {
        guard let id = Bundle.main.object(forInfoDictionaryKey: "ADMOB_DETAIL_BANNER_ID") as? String,
              !id.isEmpty,
              !id.contains("REPLACE") else {
            #if DEBUG
            return "ca-app-pub-3940256099942544/2435281174"
            #else
            fatalError("ADMOB_DETAIL_BANNER_ID not configured. Update Config/Release.xcconfig with production ad unit IDs from https://apps.admob.com/")
            #endif
        }
        return id
    }()
}

/// Represents the loading state of an ad
public enum AdLoadState: Equatable, Sendable {
    case idle
    case loading
    case loaded
    case failed(String)
}
