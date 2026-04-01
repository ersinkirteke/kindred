import Foundation

/// Combined consent status from UMP (GDPR/CCPA) and ATT (iOS tracking)
public enum ConsentStatus: Equatable, Sendable {
    case notDetermined
    case fullyGranted      // ATT authorized + UMP obtained (or UMP not required)
    case attDenied         // ATT denied, UMP obtained or not required
    case umpDenied         // UMP denied, ATT authorized (rare — GDPR region + ATT allowed)
    case bothDenied        // Both ATT denied and UMP denied
}

/// State for consent flow progression
public enum ConsentFlowStep: Equatable {
    case idle
    case checkingUMP
    case showingUMPForm
    case showingPrePrompt
    case requestingATT
    case completed
}
