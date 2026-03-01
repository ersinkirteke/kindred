import UIKit

// MARK: - HapticFeedback
// Haptic feedback utility that respects iOS accessibility settings
// Per locked decision: Checks isReduceMotionEnabled before triggering

public enum HapticFeedback {

    /// Light impact — tab selection, minor actions
    /// Use for: Tab bar taps, minor UI interactions
    public static func light() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Medium impact — bookmark, voice play start
    /// Use for: Swipe bookmark, voice playback start, important actions
    public static func medium() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Success notification — save complete, action confirmed
    /// Use for: Successful save, recipe bookmarked, action completed
    public static func success() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Selection — subtle feedback for picker/toggle changes
    /// Use for: Voice picker changes, settings toggles
    public static func selection() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
