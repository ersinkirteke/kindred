import ComposableArchitecture
import Foundation
import GoogleMobileAds

/// TCA dependency client for AdMob SDK initialization and ad suppression logic
@DependencyClient
public struct AdClient: Sendable {
    /// Initializes the Google Mobile Ads SDK
    /// Should be called once at app launch
    public var initializeSDK: @Sendable () async -> Void

    /// Determines whether ads should be shown to the user
    /// Returns false on the very first app launch (before AppDelegate sets the flag)
    /// Returns true on all subsequent launches
    ///
    /// NOTE: The "kindredFirstLaunchComplete" flag is set by AppDelegate in Plan 04 Task 2
    /// at the end of didFinishLaunchingWithOptions. This means:
    /// - First launch: flag doesn't exist → shouldShowAds returns false
    /// - Subsequent launches: flag exists → shouldShowAds returns true
    public var shouldShowAds: @Sendable () -> Bool

    /// Checks if this is the very first app launch ever
    /// Returns true if the "kindredFirstLaunchComplete" flag does not exist
    public var isFirstLaunchEver: @Sendable () -> Bool
}

// MARK: - Dependency Key

extension AdClient: DependencyKey {
    public static let liveValue = AdClient(
        initializeSDK: {
            await withCheckedContinuation { continuation in
                GADMobileAds.sharedInstance().start { status in
                    continuation.resume()
                }
            }
        },
        shouldShowAds: {
            // Check if first launch flag exists
            // If it doesn't exist, this is the first launch → no ads
            // If it exists, show ads
            UserDefaults.standard.object(forKey: "kindredFirstLaunchComplete") != nil
        },
        isFirstLaunchEver: {
            UserDefaults.standard.object(forKey: "kindredFirstLaunchComplete") == nil
        }
    )

    public static let testValue = AdClient(
        initializeSDK: {},
        shouldShowAds: { false },
        isFirstLaunchEver: { true }
    )
}

// MARK: - Dependency Values Extension

extension DependencyValues {
    public var adClient: AdClient {
        get { self[AdClient.self] }
        set { self[AdClient.self] = newValue }
    }
}
