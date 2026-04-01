import ComposableArchitecture
import Foundation
import AppTrackingTransparency
import OSLog

private let logger = Logger(subsystem: "com.ersinkirteke.kindred", category: "consent")

@Reducer
public struct ConsentReducer {
    @ObservableState
    public struct State: Equatable {
        public var consentStatus: ConsentStatus = .notDetermined
        public var isShowingPrePrompt: Bool = false
        public var flowStep: ConsentFlowStep = .idle
        public var lastError: String?

        public init() {}
    }

    public enum Action: Equatable {
        // Launch check
        case checkConsentOnLaunch
        case attStatusChecked(isAlreadyDetermined: Bool, isAuthorized: Bool)

        // UMP flow
        case umpConsentCheckCompleted(formAvailable: Bool)
        case umpConsentCheckFailed(String)
        case umpFormPresented
        case umpFormCompleted
        case umpFormFailed(String)

        // Pre-prompt flow
        case showPrePromptIfNeeded
        case prePromptContinueTapped

        // ATT flow
        case attAuthorizationReceived(isAuthorized: Bool)

        // Final resolution
        case consentFlowCompleted(ConsentStatus)

        // Analytics events
        case logAnalyticsEvent(String)
    }

    @Dependency(\.consentClient) var consentClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .checkConsentOnLaunch:
                let attStatus = consentClient.checkATTStatus()
                logger.info("Checking consent on launch, ATT status: \(attStatus.rawValue)")

                switch attStatus {
                case .authorized:
                    state.consentStatus = .fullyGranted
                    state.flowStep = .completed
                    return .send(.consentFlowCompleted(.fullyGranted))

                case .denied, .restricted:
                    state.consentStatus = .attDenied
                    state.flowStep = .completed
                    return .send(.consentFlowCompleted(.attDenied))

                case .notDetermined:
                    // Start UMP check
                    state.flowStep = .checkingUMP
                    return .run { send in
                        do {
                            let formAvailable = try await consentClient.requestUMPConsentUpdate()
                            await send(.umpConsentCheckCompleted(formAvailable: formAvailable))
                        } catch {
                            logger.error("UMP consent check failed: \(error.localizedDescription)")
                            await send(.umpConsentCheckFailed(error.localizedDescription))
                        }
                    }

                @unknown default:
                    logger.warning("Unknown ATT status: \(attStatus.rawValue)")
                    return .none
                }

            case .attStatusChecked(let isAlreadyDetermined, let isAuthorized):
                // Deprecated - handled in .checkConsentOnLaunch
                return .none

            case .umpConsentCheckCompleted(let formAvailable):
                if formAvailable {
                    logger.info("UMP form available, presenting")
                    state.flowStep = .showingUMPForm
                    return .run { send in
                        do {
                            try await consentClient.presentUMPForm()
                            await send(.umpFormCompleted)
                        } catch {
                            logger.error("UMP form presentation failed: \(error.localizedDescription)")
                            await send(.umpFormFailed(error.localizedDescription))
                        }
                    }
                } else {
                    logger.info("UMP form not available, proceeding to pre-prompt")
                    return .send(.showPrePromptIfNeeded)
                }

            case .umpConsentCheckFailed(let error):
                logger.warning("UMP consent check failed, continuing to ATT: \(error)")
                state.lastError = error
                // Per plan: UMP failure does NOT block ATT flow
                return .send(.showPrePromptIfNeeded)

            case .umpFormPresented:
                // Deprecated - handled in .umpConsentCheckCompleted
                return .none

            case .umpFormCompleted:
                logger.info("UMP form completed, proceeding to pre-prompt")
                return .send(.showPrePromptIfNeeded)

            case .umpFormFailed(let error):
                logger.warning("UMP form failed, continuing to ATT: \(error)")
                state.lastError = error
                // Per plan: Continue to ATT regardless
                return .send(.showPrePromptIfNeeded)

            case .showPrePromptIfNeeded:
                let hasSeenPrePrompt = consentClient.hasSeenPrePrompt()

                if hasSeenPrePrompt {
                    logger.info("Pre-prompt already seen, proceeding directly to ATT")
                    return .send(.prePromptContinueTapped)
                } else {
                    logger.info("Showing ATT pre-prompt")
                    state.isShowingPrePrompt = true
                    state.flowStep = .showingPrePrompt
                    return .send(.logAnalyticsEvent("consent_att_shown"))
                }

            case .prePromptContinueTapped:
                logger.info("Pre-prompt Continue tapped, requesting ATT authorization")
                state.isShowingPrePrompt = false
                state.flowStep = .requestingATT

                return .run { send in
                    // Mark pre-prompt as seen
                    await consentClient.markPrePromptSeen()

                    // Request ATT authorization
                    let status = await consentClient.requestATTAuthorization()
                    let isAuthorized = status == .authorized
                    await send(.attAuthorizationReceived(isAuthorized: isAuthorized))
                }

            case .attAuthorizationReceived(let isAuthorized):
                logger.info("ATT authorization received: \(isAuthorized ? "authorized" : "denied")")

                // Combine UMP + ATT status
                let umpStatus = consentClient.getUMPConsentStatus()
                let umpObtained = umpStatus == 3 // 3 = obtained per UMP SDK
                let umpNotRequired = umpStatus == 2 // 2 = not required

                let finalStatus: ConsentStatus
                if isAuthorized {
                    if umpObtained || umpNotRequired {
                        finalStatus = .fullyGranted
                    } else {
                        finalStatus = .umpDenied
                    }
                } else {
                    if umpObtained || umpNotRequired {
                        finalStatus = .attDenied
                    } else {
                        finalStatus = .bothDenied
                    }
                }

                logger.info("Final consent status: \(String(describing: finalStatus))")

                // Send analytics event
                let analyticsEvent = isAuthorized ? "consent_att_authorized" : "consent_att_denied"

                return .merge(
                    .send(.consentFlowCompleted(finalStatus)),
                    .send(.logAnalyticsEvent(analyticsEvent))
                )

            case .consentFlowCompleted(let status):
                state.consentStatus = status
                state.flowStep = .completed

                // Enable/disable Firebase Analytics based on consent
                let shouldEnableAnalytics: Bool
                switch status {
                case .attDenied, .bothDenied:
                    shouldEnableAnalytics = false
                default:
                    shouldEnableAnalytics = true
                }

                return .run { _ in
                    await consentClient.setFirebaseAnalyticsEnabled(shouldEnableAnalytics)
                }

            case .logAnalyticsEvent(let event):
                logger.info("Analytics event: \(event)")
                // Firebase event logging will be added when Firebase is properly configured
                return .none
            }
        }
    }
}
