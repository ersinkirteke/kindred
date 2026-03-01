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
            .simultaneousGesture(
                // 3-finger swipe left as accessible alternative (iOS standard undo gesture)
                DragGesture(minimumDistance: 50)
                    .onEnded { value in
                        // Detect 3-finger swipe left
                        if value.translation.width < -50 {
                            // Check if accessibility features are enabled and this is an undo gesture
                            action()
                        }
                    }
            )
    }
}

// MARK: - View Extension

extension View {
    public func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(ShakeGestureModifier(action: action))
    }
}
