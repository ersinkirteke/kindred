import SwiftUI
import DesignSystem

/// Animated splash screen shown on every app launch
/// Displays app logo with fade-in and pulse animation
struct SplashView: View {
    @Binding var showSplash: Bool
    @State private var logoOpacity: Double = 0
    @State private var logoScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color.kindredBackground
                .ignoresSafeArea()

            // App icon/logo - placeholder using SF Symbol
            // TODO: Replace with actual app icon asset when available
            Image(systemName: "fork.knife.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .foregroundColor(.kindredAccent)
                .opacity(logoOpacity)
                .scaleEffect(logoScale)
        }
        .onAppear {
            // Fade in with pulse animation
            withAnimation(.easeInOut(duration: 0.8)) {
                logoOpacity = 1.0
            }

            // Subtle pulse: 1.0 -> 1.05 -> 1.0
            withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
                logoScale = 1.05
            }

            withAnimation(.easeInOut(duration: 0.4).delay(1.0)) {
                logoScale = 1.0
            }

            // Dismiss after 1.5s total display time
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    logoOpacity = 0
                }

                // Transition to main content
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showSplash = false
                }
            }
        }
    }
}
