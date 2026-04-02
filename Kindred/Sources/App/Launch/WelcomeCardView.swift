import SwiftUI
import DesignSystem

/// First-launch welcome card overlay
/// Shows dismissible card with Kindred value proposition
/// Dismissed permanently after first tap via UserDefaults
struct WelcomeCardView: View {
    let onDismiss: () -> Void
    @State private var cardScale: CGFloat = 0.9
    @State private var cardOpacity: Double = 0

    var body: some View {
        ZStack {
            // Semi-transparent background overlay
            Button {
                dismissCard()
            } label: {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
            }
            .accessibilityLabel("Dismiss welcome card")

            // Welcome card
            CardSurface {
                VStack(alignment: .leading, spacing: KindredSpacing.lg) {
                    // Headline
                    Text("Kindred discovers viral recipes near you. Swipe to explore.")
                        .font(.kindredHeading2())
                        .foregroundStyle(.kindredTextPrimary)
                        .multilineTextAlignment(.leading)

                    // Dismiss button
                    KindredButton("Let's Go", style: .primary) {
                        dismissCard()
                    }
                }
            }
            .frame(maxWidth: 320)
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
        }
        .onAppear {
            // Card appears with scale-in animation
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                cardScale = 1.0
                cardOpacity = 1.0
            }
        }
    }

    private func dismissCard() {
        withAnimation(.easeOut(duration: 0.2)) {
            cardScale = 0.9
            cardOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}
