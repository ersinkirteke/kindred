import Dependencies
import UserNotifications
import UIKit

public struct NotificationClient {
    public var requestAuthorization: @Sendable () async -> UNAuthorizationStatus
    public var authorizationStatus: @Sendable () async -> UNAuthorizationStatus
    public var registerForRemoteNotifications: @Sendable () async -> Void
}

extension NotificationClient: DependencyKey {
    public static var liveValue: NotificationClient {
        NotificationClient(
            requestAuthorization: {
                let center = UNUserNotificationCenter.current()
                let currentSettings = await center.notificationSettings()
                let currentStatus = currentSettings.authorizationStatus

                // If already determined, return immediately
                guard currentStatus == .notDetermined else {
                    return currentStatus
                }

                // Request permission with alert, sound, badge
                do {
                    let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                    return granted ? .authorized : .denied
                } catch {
                    return .denied
                }
            },
            authorizationStatus: {
                let center = UNUserNotificationCenter.current()
                let settings = await center.notificationSettings()
                return settings.authorizationStatus
            },
            registerForRemoteNotifications: {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        )
    }

    public static var testValue: NotificationClient {
        NotificationClient(
            requestAuthorization: { .authorized },
            authorizationStatus: { .authorized },
            registerForRemoteNotifications: {}
        )
    }
}

extension DependencyValues {
    public var notificationClient: NotificationClient {
        get { self[NotificationClient.self] }
        set { self[NotificationClient.self] = newValue }
    }
}
