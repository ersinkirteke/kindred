import ComposableArchitecture
import XCTest
@testable import MonetizationFeature
import AppTrackingTransparency

@MainActor
final class ConsentReducerTests: XCTestCase {

    // MARK: - Test 1: Happy path — full consent flow granted

    func testFullConsentFlowGranted() async {
        let store = TestStore(initialState: ConsentReducer.State()) {
            ConsentReducer()
        } withDependencies: {
            $0.consentClient = ConsentClient(
                checkATTStatus: { .notDetermined },
                requestATTAuthorization: { .authorized },
                requestUMPConsentUpdate: { false }, // No UMP form needed
                presentUMPForm: {},
                getUMPConsentStatus: { 3 }, // obtained
                hasSeenPrePrompt: { false },
                markPrePromptSeen: {},
                setFirebaseAnalyticsEnabled: { _ in }
            )
        }

        // Start consent flow
        await store.send(.checkConsentOnLaunch) {
            $0.flowStep = .checkingUMP
        }

        // UMP check completes without form
        await store.receive(.umpConsentCheckCompleted(formAvailable: false))

        // Pre-prompt should be shown
        await store.receive(.showPrePromptIfNeeded) {
            $0.isShowingPrePrompt = true
            $0.flowStep = .showingPrePrompt
        }

        // Analytics event for showing pre-prompt
        await store.receive(.logAnalyticsEvent("consent_att_shown"))

        // User taps Continue on pre-prompt
        await store.send(.prePromptContinueTapped) {
            $0.isShowingPrePrompt = false
            $0.flowStep = .requestingATT
        }

        // ATT authorization received
        await store.receive(.attAuthorizationReceived(isAuthorized: true))

        // Flow completes with fully granted status
        await store.receive(.consentFlowCompleted(.fullyGranted)) {
            $0.consentStatus = .fullyGranted
            $0.flowStep = .completed
        }

        // Analytics event for ATT authorized
        await store.receive(.logAnalyticsEvent("consent_att_authorized"))
    }

    // MARK: - Test 2: ATT already determined — skip flow

    func testATTAlreadyAuthorized() async {
        let store = TestStore(initialState: ConsentReducer.State()) {
            ConsentReducer()
        } withDependencies: {
            $0.consentClient = ConsentClient(
                checkATTStatus: { .authorized },
                requestATTAuthorization: { .authorized },
                requestUMPConsentUpdate: { false },
                presentUMPForm: {},
                getUMPConsentStatus: { 3 },
                hasSeenPrePrompt: { false },
                markPrePromptSeen: {},
                setFirebaseAnalyticsEnabled: { _ in }
            )
        }

        // Start consent flow with ATT already authorized
        await store.send(.checkConsentOnLaunch) {
            $0.consentStatus = .fullyGranted
            $0.flowStep = .completed
        }

        // Flow completes immediately
        await store.receive(.consentFlowCompleted(.fullyGranted))
    }

    func testATTAlreadyDenied() async {
        let store = TestStore(initialState: ConsentReducer.State()) {
            ConsentReducer()
        } withDependencies: {
            $0.consentClient = ConsentClient(
                checkATTStatus: { .denied },
                requestATTAuthorization: { .denied },
                requestUMPConsentUpdate: { false },
                presentUMPForm: {},
                getUMPConsentStatus: { 3 },
                hasSeenPrePrompt: { false },
                markPrePromptSeen: {},
                setFirebaseAnalyticsEnabled: { _ in }
            )
        }

        // Start consent flow with ATT already denied
        await store.send(.checkConsentOnLaunch) {
            $0.consentStatus = .attDenied
            $0.flowStep = .completed
        }

        // Flow completes immediately with attDenied status
        await store.receive(.consentFlowCompleted(.attDenied))
    }

    // MARK: - Test 3: ATT denied — non-personalized ads

    func testATTDenied() async {
        var analyticsEnabled: Bool?

        let store = TestStore(initialState: ConsentReducer.State()) {
            ConsentReducer()
        } withDependencies: {
            $0.consentClient = ConsentClient(
                checkATTStatus: { .notDetermined },
                requestATTAuthorization: { .denied },
                requestUMPConsentUpdate: { false },
                presentUMPForm: {},
                getUMPConsentStatus: { 3 }, // obtained
                hasSeenPrePrompt: { false },
                markPrePromptSeen: {},
                setFirebaseAnalyticsEnabled: { enabled in
                    analyticsEnabled = enabled
                }
            )
        }

        // Start consent flow
        await store.send(.checkConsentOnLaunch) {
            $0.flowStep = .checkingUMP
        }

        await store.receive(.umpConsentCheckCompleted(formAvailable: false))
        await store.receive(.showPrePromptIfNeeded) {
            $0.isShowingPrePrompt = true
            $0.flowStep = .showingPrePrompt
        }
        await store.receive(.logAnalyticsEvent("consent_att_shown"))

        await store.send(.prePromptContinueTapped) {
            $0.isShowingPrePrompt = false
            $0.flowStep = .requestingATT
        }

        // ATT denied
        await store.receive(.attAuthorizationReceived(isAuthorized: false))

        // Flow completes with attDenied status
        await store.receive(.consentFlowCompleted(.attDenied)) {
            $0.consentStatus = .attDenied
            $0.flowStep = .completed
        }

        // Analytics event for ATT denied
        await store.receive(.logAnalyticsEvent("consent_att_denied"))

        // Verify Firebase Analytics is disabled
        XCTAssertEqual(analyticsEnabled, false, "Firebase Analytics should be disabled when ATT is denied")
    }

    // MARK: - Test 4: UMP failure — graceful fallback

    func testUMPFailureContinuesToATT() async {
        let store = TestStore(initialState: ConsentReducer.State()) {
            ConsentReducer()
        } withDependencies: {
            $0.consentClient = ConsentClient(
                checkATTStatus: { .notDetermined },
                requestATTAuthorization: { .authorized },
                requestUMPConsentUpdate: {
                    throw NSError(domain: "UMP", code: -1, userInfo: [NSLocalizedDescriptionKey: "UMP failed"])
                },
                presentUMPForm: {},
                getUMPConsentStatus: { 3 },
                hasSeenPrePrompt: { false },
                markPrePromptSeen: {},
                setFirebaseAnalyticsEnabled: { _ in }
            )
        }

        // Start consent flow
        await store.send(.checkConsentOnLaunch) {
            $0.flowStep = .checkingUMP
        }

        // UMP fails
        await store.receive(.umpConsentCheckFailed("UMP failed")) {
            $0.lastError = "UMP failed"
        }

        // Flow continues to pre-prompt despite UMP failure
        await store.receive(.showPrePromptIfNeeded) {
            $0.isShowingPrePrompt = true
            $0.flowStep = .showingPrePrompt
        }
        await store.receive(.logAnalyticsEvent("consent_att_shown"))

        await store.send(.prePromptContinueTapped) {
            $0.isShowingPrePrompt = false
            $0.flowStep = .requestingATT
        }

        await store.receive(.attAuthorizationReceived(isAuthorized: true))
        await store.receive(.consentFlowCompleted(.fullyGranted)) {
            $0.consentStatus = .fullyGranted
            $0.flowStep = .completed
        }
        await store.receive(.logAnalyticsEvent("consent_att_authorized"))
    }

    // MARK: - Test 5: Pre-prompt already seen — skip to ATT

    func testPrePromptAlreadySeen() async {
        let store = TestStore(initialState: ConsentReducer.State()) {
            ConsentReducer()
        } withDependencies: {
            $0.consentClient = ConsentClient(
                checkATTStatus: { .notDetermined },
                requestATTAuthorization: { .authorized },
                requestUMPConsentUpdate: { false },
                presentUMPForm: {},
                getUMPConsentStatus: { 3 },
                hasSeenPrePrompt: { true }, // Already seen
                markPrePromptSeen: {},
                setFirebaseAnalyticsEnabled: { _ in }
            )
        }

        // Start consent flow
        await store.send(.checkConsentOnLaunch) {
            $0.flowStep = .checkingUMP
        }

        await store.receive(.umpConsentCheckCompleted(formAvailable: false))

        // Pre-prompt check skips showing
        await store.receive(.showPrePromptIfNeeded)

        // Directly proceeds to ATT
        await store.receive(.prePromptContinueTapped) {
            $0.flowStep = .requestingATT
        }

        await store.receive(.attAuthorizationReceived(isAuthorized: true))
        await store.receive(.consentFlowCompleted(.fullyGranted)) {
            $0.consentStatus = .fullyGranted
            $0.flowStep = .completed
        }
        await store.receive(.logAnalyticsEvent("consent_att_authorized"))

        // Verify pre-prompt was never shown
        XCTAssertFalse(store.state.isShowingPrePrompt)
    }

    // MARK: - Test 6: UMP form available and presented

    func testUMPFormPresented() async {
        let store = TestStore(initialState: ConsentReducer.State()) {
            ConsentReducer()
        } withDependencies: {
            $0.consentClient = ConsentClient(
                checkATTStatus: { .notDetermined },
                requestATTAuthorization: { .authorized },
                requestUMPConsentUpdate: { true }, // Form available
                presentUMPForm: {}, // No-op for test
                getUMPConsentStatus: { 3 },
                hasSeenPrePrompt: { false },
                markPrePromptSeen: {},
                setFirebaseAnalyticsEnabled: { _ in }
            )
        }

        // Start consent flow
        await store.send(.checkConsentOnLaunch) {
            $0.flowStep = .checkingUMP
        }

        // UMP form is available
        await store.receive(.umpConsentCheckCompleted(formAvailable: true)) {
            $0.flowStep = .showingUMPForm
        }

        // UMP form completes
        await store.receive(.umpFormCompleted)

        // Continues to pre-prompt after UMP form
        await store.receive(.showPrePromptIfNeeded) {
            $0.isShowingPrePrompt = true
            $0.flowStep = .showingPrePrompt
        }
        await store.receive(.logAnalyticsEvent("consent_att_shown"))

        await store.send(.prePromptContinueTapped) {
            $0.isShowingPrePrompt = false
            $0.flowStep = .requestingATT
        }

        await store.receive(.attAuthorizationReceived(isAuthorized: true))
        await store.receive(.consentFlowCompleted(.fullyGranted)) {
            $0.consentStatus = .fullyGranted
            $0.flowStep = .completed
        }
        await store.receive(.logAnalyticsEvent("consent_att_authorized"))
    }

    // MARK: - Test 7: UMP form failure — graceful fallback

    func testUMPFormFailureContinuesToATT() async {
        let store = TestStore(initialState: ConsentReducer.State()) {
            ConsentReducer()
        } withDependencies: {
            $0.consentClient = ConsentClient(
                checkATTStatus: { .notDetermined },
                requestATTAuthorization: { .authorized },
                requestUMPConsentUpdate: { true }, // Form available
                presentUMPForm: {
                    throw NSError(domain: "UMP", code: -1, userInfo: [NSLocalizedDescriptionKey: "Form presentation failed"])
                },
                getUMPConsentStatus: { 3 },
                hasSeenPrePrompt: { false },
                markPrePromptSeen: {},
                setFirebaseAnalyticsEnabled: { _ in }
            )
        }

        // Start consent flow
        await store.send(.checkConsentOnLaunch) {
            $0.flowStep = .checkingUMP
        }

        // UMP form is available
        await store.receive(.umpConsentCheckCompleted(formAvailable: true)) {
            $0.flowStep = .showingUMPForm
        }

        // UMP form presentation fails
        await store.receive(.umpFormFailed("Form presentation failed")) {
            $0.lastError = "Form presentation failed"
        }

        // Flow continues to pre-prompt despite form failure
        await store.receive(.showPrePromptIfNeeded) {
            $0.isShowingPrePrompt = true
            $0.flowStep = .showingPrePrompt
        }
        await store.receive(.logAnalyticsEvent("consent_att_shown"))

        await store.send(.prePromptContinueTapped) {
            $0.isShowingPrePrompt = false
            $0.flowStep = .requestingATT
        }

        await store.receive(.attAuthorizationReceived(isAuthorized: true))
        await store.receive(.consentFlowCompleted(.fullyGranted)) {
            $0.consentStatus = .fullyGranted
            $0.flowStep = .completed
        }
        await store.receive(.logAnalyticsEvent("consent_att_authorized"))
    }

    // MARK: - Test 8: Both denied status

    func testBothATTAndUMPDenied() async {
        let store = TestStore(initialState: ConsentReducer.State()) {
            ConsentReducer()
        } withDependencies: {
            $0.consentClient = ConsentClient(
                checkATTStatus: { .notDetermined },
                requestATTAuthorization: { .denied },
                requestUMPConsentUpdate: { false },
                presentUMPForm: {},
                getUMPConsentStatus: { 0 }, // unknown/denied
                hasSeenPrePrompt: { false },
                markPrePromptSeen: {},
                setFirebaseAnalyticsEnabled: { _ in }
            )
        }

        // Start consent flow
        await store.send(.checkConsentOnLaunch) {
            $0.flowStep = .checkingUMP
        }

        await store.receive(.umpConsentCheckCompleted(formAvailable: false))
        await store.receive(.showPrePromptIfNeeded) {
            $0.isShowingPrePrompt = true
            $0.flowStep = .showingPrePrompt
        }
        await store.receive(.logAnalyticsEvent("consent_att_shown"))

        await store.send(.prePromptContinueTapped) {
            $0.isShowingPrePrompt = false
            $0.flowStep = .requestingATT
        }

        // ATT denied + UMP not obtained = both denied
        await store.receive(.attAuthorizationReceived(isAuthorized: false))
        await store.receive(.consentFlowCompleted(.bothDenied)) {
            $0.consentStatus = .bothDenied
            $0.flowStep = .completed
        }
        await store.receive(.logAnalyticsEvent("consent_att_denied"))
    }
}
