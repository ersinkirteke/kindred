import SwiftUI

// MARK: - CardSurface
// Container view for recipe cards and content blocks with themed background

public struct CardSurface<Content: View>: View {

    // MARK: - Properties

    private let content: Content
    private let hasShadow: Bool

    // MARK: - Initialization

    public init(
        hasShadow: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.hasShadow = hasShadow
        self.content = content()
    }

    // MARK: - Body

    public var body: some View {
        content
            .padding(KindredSpacing.md)
            .background(Color.kindredCardSurface)
            .cornerRadius(16)
            .shadow(
                color: hasShadow ? Color.black.opacity(0.1) : .clear,
                radius: hasShadow ? 8 : 0,
                x: 0,
                y: hasShadow ? 2 : 0
            )
    }
}

// MARK: - Preview Providers
// SwiftUI previews are available in Xcode only

#if DEBUG
struct CardSurface_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack(spacing: KindredSpacing.lg) {
                CardSurface {
                    VStack(alignment: .leading, spacing: KindredSpacing.sm) {
                        Text("Recipe Title")
                            .font(.kindredHeading2())
                            .foregroundColor(.kindredTextPrimary)

                        Text("A delicious recipe description that spans multiple lines to show how content looks inside a card surface.")
                            .font(.kindredBody())
                            .foregroundColor(.kindredTextSecondary)
                    }
                }

                CardSurface(hasShadow: false) {
                    Text("Card without shadow")
                        .font(.kindredBody())
                        .foregroundColor(.kindredTextPrimary)
                }
            }
            .padding()
            .previewDisplayName("Light Mode")

            VStack(spacing: KindredSpacing.lg) {
                CardSurface {
                    VStack(alignment: .leading, spacing: KindredSpacing.sm) {
                        Text("Recipe Title")
                            .font(.kindredHeading2())
                            .foregroundColor(.kindredTextPrimary)

                        Text("A delicious recipe description in dark mode with warm brown background.")
                            .font(.kindredBody())
                            .foregroundColor(.kindredTextSecondary)
                    }
                }
            }
            .padding()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
        .background(Color.kindredBackground)
    }
}
#endif
