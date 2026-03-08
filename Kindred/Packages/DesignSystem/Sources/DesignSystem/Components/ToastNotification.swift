import SwiftUI

// MARK: - ToastNotification
// Brief, non-blocking toast notification for offline action attempts
// Auto-dismisses after specified duration (default 3 seconds)

public struct ToastNotification: View {

    // MARK: - Properties

    let message: String
    let duration: TimeInterval
    @Binding var isShowing: Bool
    @State private var offset: CGFloat = 100

    // MARK: - Initializer

    public init(message: String, duration: TimeInterval = 3, isShowing: Binding<Bool>) {
        self.message = message
        self.duration = duration
        self._isShowing = isShowing
    }

    // MARK: - Body

    public var body: some View {
        if isShowing {
            Text(message)
                .font(.kindredCaption())
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.kindredTextPrimary.opacity(0.9))
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .offset(y: offset)
                .accessibilityLabel(message)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    // Slide up animation
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        offset = 0
                    }

                    // Auto-dismiss after duration
                    Task {
                        try? await Task.sleep(for: .seconds(duration))
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            offset = 100
                        }
                        // Wait for animation to complete before hiding
                        try? await Task.sleep(for: .seconds(0.5))
                        isShowing = false
                    }
                }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ToastNotification_Previews: PreviewProvider {
    @State static var showToast = true

    static var previews: some View {
        VStack {
            Spacer()

            Button("Show Toast") {
                showToast = true
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.kindredBackground)
        .overlay(alignment: .bottom) {
            ToastNotification(
                message: "This requires internet connection",
                isShowing: .constant(true)
            )
        }
    }
}
#endif
