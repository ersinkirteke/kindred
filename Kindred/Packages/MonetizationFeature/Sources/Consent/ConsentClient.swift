import Foundation
import AppTrackingTransparency
import UserMessagingPlatform
import Dependencies
import DependenciesMacros
import OSLog

private let logger = Logger(subsystem: "com.ersinkirteke.kindred", category: "consent")

@DependencyClient
public struct ConsentClient: Sendable {
    /// Returns current ATT authorization status
    public var checkATTStatus: @Sendable () -> ATTrackingManager.AuthorizationStatus = { .notDetermined }

    /// Requests ATT authorization and returns the result
    public var requestATTAuthorization: @Sendable () async -> ATTrackingManager.AuthorizationStatus = { .notDetermined }

    /// Requests UMP consent info update, returns true if consent form is available
    public var requestUMPConsentUpdate: @Sendable () async throws -> Bool = { false }

    /// Presents the UMP consent form
    public var presentUMPForm: @Sendable () async throws -> Void = {}

    /// Returns UMP consent status raw value (0 = unknown, 1 = required, 2 = not required, 3 = obtained)
    public var getUMPConsentStatus: @Sendable () -> Int = { 0 }

    /// Checks if user has seen the ATT pre-prompt
    public var hasSeenPrePrompt: @Sendable () -> Bool = { false }

    /// Marks the ATT pre-prompt as seen
    public var markPrePromptSeen: @Sendable () -> Void = {}

    /// Enables or disables Firebase Analytics collection (injected by app layer)
    public var setFirebaseAnalyticsEnabled: @Sendable (Bool) -> Void = { _ in }
}

// MARK: - Dependency Registration

extension ConsentClient: DependencyKey {
    public static let liveValue: ConsentClient = {
        @Sendable func _checkATTStatus() -> ATTrackingManager.AuthorizationStatus {
            ATTrackingManager.trackingAuthorizationStatus
        }

        @Sendable func _requestATTAuthorization() async -> ATTrackingManager.AuthorizationStatus {
            do {
                let status = await ATTrackingManager.requestTrackingAuthorization()
                logger.info("ATT authorization requested, status: \(status.rawValue)")
                return status
            } catch {
                logger.error("ATT authorization failed: \(error.localizedDescription)")
                // Per plan: treat error as denied, no retry
                return .denied
            }
        }

        @Sendable func _requestUMPConsentUpdate() async throws -> Bool {
            logger.info("Requesting UMP consent info update")
            let parameters = UMPRequestParameters()
            parameters.tagForUnderAgeOfConsent = false

            try await UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters)

            let formAvailable = UMPConsentInformation.sharedInstance.formStatus == .available
            logger.info("UMP consent info updated, form available: \(formAvailable)")
            return formAvailable
        }

        @Sendable func _presentUMPForm() async throws {
            logger.info("Loading UMP consent form")
            let form = try await UMPConsentForm.load()

            logger.info("Presenting UMP consent form")
            try await form.present(from: nil) // Uses key window
            logger.info("UMP consent form dismissed")
        }

        @Sendable func _getUMPConsentStatus() -> Int {
            UMPConsentInformation.sharedInstance.consentStatus.rawValue
        }

        @Sendable func _hasSeenPrePrompt() -> Bool {
            UserDefaults.standard.bool(forKey: "hasSeenATTPrePrompt")
        }

        @Sendable func _markPrePromptSeen() {
            UserDefaults.standard.set(true, forKey: "hasSeenATTPrePrompt")
            logger.info("ATT pre-prompt marked as seen")
        }

        return ConsentClient(
            checkATTStatus: _checkATTStatus,
            requestATTAuthorization: _requestATTAuthorization,
            requestUMPConsentUpdate: _requestUMPConsentUpdate,
            presentUMPForm: _presentUMPForm,
            getUMPConsentStatus: _getUMPConsentStatus,
            hasSeenPrePrompt: _hasSeenPrePrompt,
            markPrePromptSeen: _markPrePromptSeen,
            setFirebaseAnalyticsEnabled: { _ in } // Overridden in app layer
        )
    }()

    public static let testValue = ConsentClient()

    // Named test presets
    public static var allGranted: ConsentClient {
        var client = ConsentClient()
        client.checkATTStatus = { .authorized }
        client.getUMPConsentStatus = { 3 } // obtained
        return client
    }

    public static var attDenied: ConsentClient {
        var client = ConsentClient()
        client.checkATTStatus = { .denied }
        client.getUMPConsentStatus = { 3 } // obtained
        return client
    }
}

extension DependencyValues {
    public var consentClient: ConsentClient {
        get { self[ConsentClient.self] }
        set { self[ConsentClient.self] = newValue }
    }
}
