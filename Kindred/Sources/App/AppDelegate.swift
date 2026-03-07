import UIKit
import ClerkKit
import FeedFeature
import Kingfisher
import VoicePlaybackFeature
import StoreKit
import GoogleMobileAds

/// AppDelegate for Firebase and Kingfisher cache configuration
class AppDelegate: NSObject, UIApplicationDelegate {
    private var transactionObserverTask: Task<Void, Never>?
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Configure Kingfisher cache limits to prevent memory pressure on older devices
        let cache = ImageCache.default
        cache.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024 // 100MB memory
        cache.memoryStorage.config.countLimit = 50 // 50 images in memory
        cache.diskStorage.config.sizeLimit = 500 * 1024 * 1024 // 500MB disk

        // Clerk SDK configured lazily — no-op here until real key is set

        // Configure AVAudioSession for background voice playback
        AudioSessionConfigurator.configure()

        // Warm up LocationManager on main thread to avoid Swift Concurrency deadlocks
        LocationManager.warmUp()

        // Start StoreKit 2 Transaction.updates listener for cross-device subscription sync
        transactionObserverTask = Task {
            for await verification in Transaction.updates {
                guard case .verified(let transaction) = verification else { continue }
                // Finish transaction (Apple requirement)
                await transaction.finish()
                // Note: Subscription status is checked lazily by SubscriptionClient.currentEntitlement
                // No need to push updates — reducers check on appear
            }
        }

        // Initialize AdMob SDK
        GADMobileAds.sharedInstance().start(completionHandler: nil)

        // Mark first launch complete (ads suppressed until second session)
        if !UserDefaults.standard.bool(forKey: "kindredFirstLaunchComplete") {
            UserDefaults.standard.set(true, forKey: "kindredFirstLaunchComplete")
        }

        // TODO: Firebase configuration will be added when analytics is needed
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Cancel StoreKit transaction observer task
        transactionObserverTask?.cancel()
    }
}
