import UIKit
import ClerkKit
import Kingfisher
import VoicePlaybackFeature

/// AppDelegate for Firebase and Kingfisher cache configuration
class AppDelegate: NSObject, UIApplicationDelegate {
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

        // DEBUG: Reset onboarding and auth gate state for testing (remove before release)
        #if DEBUG
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        UserDefaults.standard.removeObject(forKey: "lastGateDismissedAt")
        #endif

        // Configure AVAudioSession for background voice playback
        AudioSessionConfigurator.configure()

        // TODO: Firebase configuration will be added when analytics is needed
        return true
    }
}
