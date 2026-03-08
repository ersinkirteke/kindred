import UIKit

// MARK: - HapticFeedback
// Haptic feedback utility for tactile user feedback
// Per accessibility decision: Haptics always fire regardless of Reduce Motion
// (haptics are tactile, not visual motion)

public enum HapticFeedback {

    /// Light impact — tab selection, minor actions
    /// Use for: Tab bar taps, minor UI interactions
    public static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Medium impact — bookmark, voice play start
    /// Use for: Swipe bookmark, voice playback start, important actions
    public static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Heavy impact — playback start/stop, significant state changes
    /// Use for: Playback start/stop, major UI transitions
    public static func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    /// Success notification — save complete, action confirmed
    /// Use for: Successful save, recipe bookmarked, action completed
    public static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Error notification — failed actions, error states
    /// Use for: Error states, failed actions
    public static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    /// Warning notification — offline attempts, reaching limits
    /// Use for: Offline action attempts, rate limits, warnings
    public static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    /// Selection — subtle feedback for picker/toggle changes
    /// Use for: Voice picker changes, settings toggles, filter toggles
    public static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
