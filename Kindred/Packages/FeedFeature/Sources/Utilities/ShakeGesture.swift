import SwiftUI
import UIKit

// MARK: - Device Shake Notification

extension UIDevice {
    public static let deviceDidShakeNotification = Notification.Name("deviceDidShakeNotification")
}

// MARK: - UIWindow Extension for Shake Detection

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
        super.motionEnded(motion, with: event)
    }
}

// MARK: - Shake Gesture ViewModifier

private struct ShakeGestureModifier: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
                action()
            }
            // NOTE: Removed simultaneousGesture(DragGesture) that was intended as a
            // 3-finger undo gesture. It could not actually detect finger count and was
            // stealing/conflicting with the card swipe DragGesture in RecipeCardView,
            // preventing onEnded from firing on the card's gesture.
            // The shake-to-undo via motionEnded still works on device.
    }
}

// MARK: - View Extension

extension View {
    public func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(ShakeGestureModifier(action: action))
    }
}
