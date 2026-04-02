import UIKit
import ClerkKit
import AuthFeature
import FeedFeature
import Kingfisher
import VoicePlaybackFeature
import StoreKit
import GoogleMobileAds
import MetricKit
import BackgroundTasks
import OSLog
import UserNotifications
import Security

/// AppDelegate for Firebase and Kingfisher cache configuration
class AppDelegate: NSObject, UIApplicationDelegate, MXMetricManagerSubscriber {
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

        // Configure Clerk SDK for authentication (key from xcconfig → Info.plist)
        guard let clerkKey = Bundle.main.object(forInfoDictionaryKey: "ClerkPublishableKey") as? String,
              !clerkKey.isEmpty,
              !clerkKey.hasPrefix("REPLACE_WITH") else {
            fatalError("Missing ClerkPublishableKey in Info.plist — check xcconfig files")
        }
        Clerk.configure(publishableKey: clerkKey)
        ClerkConfigurationState.isConfigured = true

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

        // Initialize AdMob SDK — consent status configured before loading ads
        #if DEBUG
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [GADSimulatorID]
        #endif
        GADMobileAds.sharedInstance().start(completionHandler: nil)

        // Mark first launch complete when app enters background (ads suppressed during first session)
        if !UserDefaults.standard.bool(forKey: "kindredFirstLaunchComplete") {
            NotificationCenter.default.addObserver(
                forName: UIApplication.didEnterBackgroundNotification,
                object: nil,
                queue: .main
            ) { _ in
                UserDefaults.standard.set(true, forKey: "kindredFirstLaunchComplete")
            }
        }

        // Register MetricKit subscriber for production performance monitoring
        MXMetricManager.shared.add(self)

        // Register BGAppRefreshTask for periodic recipe feed refresh
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.ersinkirteke.kindred.recipe-refresh",
            using: nil
        ) { task in
            self.handleRecipeRefresh(task: task as! BGAppRefreshTask)
        }

        Logger.appLifecycle.info("App did finish launching")

        // TODO: Firebase configuration will be added when analytics is needed
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Cancel StoreKit transaction observer task
        transactionObserverTask?.cancel()

        // Remove MetricKit subscriber
        MXMetricManager.shared.remove(self)

        Logger.appLifecycle.info("App will terminate")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Schedule background recipe refresh
        scheduleRecipeRefresh()
        Logger.appLifecycle.info("App entered background")
    }

    // MARK: - MetricKit

    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            // Log launch time metrics
            if let launchMetrics = payload.applicationLaunchMetrics {
                let timeToFirstDraw = launchMetrics.histogrammedTimeToFirstDraw
                let bucketCount = timeToFirstDraw.totalBucketCount
                Logger.performance.info("Launch time histogram buckets: \(bucketCount)")

                // Check if launch time is concerning (> 1s in upper buckets)
                if bucketCount > 10 {
                    Logger.performance.warning("Launch time has many histogram buckets, indicating slow launches")
                }
            }

            // Log hang metrics
            if let hangMetrics = payload.applicationResponsivenessMetrics {
                let hangTime = hangMetrics.histogrammedApplicationHangTime
                let hangCount = hangTime.totalBucketCount
                Logger.performance.info("Hang histogram buckets: \(hangCount)")
            }

            // Log exit metrics
            if let exitMetrics = payload.applicationExitMetrics {
                let backgroundExits = exitMetrics.backgroundExitData.cumulativeAbnormalExitCount
                let foregroundExits = exitMetrics.foregroundExitData.cumulativeAbnormalExitCount
                Logger.performance.info("Abnormal exits - background: \(backgroundExits), foreground: \(foregroundExits)")
            }
        }
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            // Log crash and hang diagnostics
            if let crashDiagnostic = payload.crashDiagnostics?.first {
                Logger.performance.error("Crash diagnostic received: \(crashDiagnostic.callStackTree.jsonRepresentation())")
            }

            if let hangDiagnostic = payload.hangDiagnostics?.first {
                Logger.performance.error("Hang diagnostic received: \(hangDiagnostic.callStackTree.jsonRepresentation())")
            }
        }
    }

    // MARK: - Background Refresh

    private func handleRecipeRefresh(task: BGAppRefreshTask) {
        Logger.background.info("Recipe refresh task started")

        // Schedule next refresh
        scheduleRecipeRefresh()

        // Set expiration handler
        task.expirationHandler = {
            Logger.background.warning("Recipe refresh task expired")
        }

        // Perform background fetch (placeholder - actual implementation depends on Apollo client availability)
        Task {
            do {
                // TODO: Fetch latest recipes via Apollo client
                // await apolloClient.fetch(query: GetRecipesQuery())
                Logger.background.info("Recipe refresh completed successfully")
                task.setTaskCompleted(success: true)
            } catch {
                Logger.background.error("Recipe refresh failed: \(error.localizedDescription)")
                task.setTaskCompleted(success: false)
            }
        }
    }

    private func scheduleRecipeRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.ersinkirteke.kindred.recipe-refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes

        do {
            try BGTaskScheduler.shared.submit(request)
            Logger.background.info("Recipe refresh scheduled for 15 minutes from now")
        } catch {
            Logger.background.error("Failed to schedule recipe refresh: \(error.localizedDescription)")
        }
    }

    // MARK: - Remote Notifications

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        Logger.appLifecycle.info("Registered for remote notifications with token: \(tokenString.prefix(10))...")

        // Store token in Keychain (not UserDefaults) for when backend integration is ready
        // TODO: Wire to GraphQL registerDeviceToken mutation when Firebase is configured
        Self.storeAPNSToken(tokenString)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Logger.appLifecycle.error("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // MARK: - Keychain

    private static let apnsTokenKeychainAccount = "com.ersinkirteke.kindred.apnsDeviceToken"

    private static func storeAPNSToken(_ token: String) {
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: apnsTokenKeychainAccount,
        ]
        // Delete any existing item first
        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        if status != errSecSuccess {
            Logger.appLifecycle.error("Failed to store APNS token in Keychain: \(status)")
        }
    }
}

// MARK: - Logger Extensions

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!

    static let appLifecycle = Logger(subsystem: subsystem, category: "app-lifecycle")
    static let performance = Logger(subsystem: subsystem, category: "performance")
    static let background = Logger(subsystem: subsystem, category: "background")
}
