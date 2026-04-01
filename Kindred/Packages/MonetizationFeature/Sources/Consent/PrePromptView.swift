import SwiftUI
import DesignSystem
import OSLog

private let logger = Logger(subsystem: "com.ersinkirteke.kindred", category: "consent")

public struct PrePromptView: View {
    let onContinue: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = 60
    @ScaledMetric(relativeTo: .title) private var headingSize: CGFloat = 24
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 16

    public init(onContinue: @escaping () -> Void) {
        self.onContinue = onContinue
    }

    public var body: some View {
        VStack(spacing: KindredSpacing.xl) {
            Spacer()

            // Icon
            Image(systemName: "heart.text.square")
                .font(.system(size: iconSize))
                .foregroundStyle(.kindredAccent)
                .padding(.bottom, KindredSpacing.md)

            // Heading
            Text("Hey! Let's personalize your experience")
                .font(.kindredHeading2Scaled)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .padding(.horizontal, KindredSpacing.xl)

            // Body
            Text("We'd like to show you ads that match your tastes — think kitchen tools and ingredients you'll actually use. Tap Continue to help us personalize your ads.")
                .font(.kindredBodyScaled)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, KindredSpacing.xl)

            Spacer()

            // Continue Button
            Button(action: {
                logger.info("ATT pre-prompt Continue tapped")
                onContinue()
            }) {
                Text("Continue")
                    .font(.kindredBodyScaled.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, KindredSpacing.md)
                    .background(Color.kindredAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, KindredSpacing.xl)
            .padding(.bottom, KindredSpacing.xl)
        }
        .background(Color.kindredBackground)
        .interactiveDismissDisabled()
    }
}

#Preview {
    PrePromptView {
        print("Continue tapped in preview")
    }
}
