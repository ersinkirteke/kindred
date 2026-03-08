import DesignSystem
import SwiftUI
import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    fileprivate static let feed = Logger(subsystem: subsystem, category: "feed")
}

/// One-time celebratory card that appears when Culinary DNA activates (50+ interactions)
struct DNAActivationCard: View {
    let onDismiss: () -> Void

    var body: some View {
        CardSurface {
            VStack(spacing: KindredSpacing.md) {
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundColor(.kindredAccent)

                Text("Your Culinary DNA is ready!")
                    .font(.kindredHeading2())
                    .foregroundColor(.kindredTextPrimary)
                    .multilineTextAlignment(.center)

                Text("Your feed is now personalized based on your taste.")
                    .font(.kindredBody())
                    .foregroundColor(.kindredTextSecondary)
                    .multilineTextAlignment(.center)

                KindredButton("Got it!", style: .primary) {
                    onDismiss()
                }
            }
            .padding(KindredSpacing.lg)
        }
        .padding(.horizontal, KindredSpacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your Culinary DNA is ready! Your feed is now personalized based on your taste.")
        .accessibilityAddTraits(.isStaticText)
    }
}

#Preview {
    DNAActivationCard {
        Logger.feed.debug("Dismissed")
    }
}
