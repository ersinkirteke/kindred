import SwiftUI
import OSLog

// MARK: - KindredButton
// Primary CTA button with 56dp minimum touch target (WCAG AAA compliance)

public struct KindredButton: View {

    // MARK: - Properties

    private let title: String
    private let style: ButtonStyle
    private let isLoading: Bool
    private let isDisabled: Bool
    private let action: () -> Void

    // MARK: - Initialization

    public init(
        _ title: String,
        style: ButtonStyle = .primary,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    // MARK: - Body

    public var body: some View {
        Button(action: action) {
            HStack(spacing: KindredSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                } else {
                    Text(title)
                        .font(.kindredBodyBold())
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minWidth: 56, minHeight: 56) // WCAG AAA 56dp minimum touch target
            .padding(.horizontal, KindredSpacing.md)
            .background(style.backgroundColor)
            .foregroundColor(style.foregroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style.borderColor, lineWidth: style.borderWidth)
            )
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}

// MARK: - Button Styles

public extension KindredButton {

    enum ButtonStyle {
        case primary
        case secondary
        case text

        var backgroundColor: Color {
            switch self {
            case .primary:
                return .kindredAccent
            case .secondary:
                return .clear
            case .text:
                return .clear
            }
        }

        var foregroundColor: Color {
            switch self {
            case .primary:
                return .white
            case .secondary:
                return .kindredAccent
            case .text:
                return .kindredAccent
            }
        }

        var borderColor: Color {
            switch self {
            case .primary:
                return .clear
            case .secondary:
                return .kindredAccent
            case .text:
                return .clear
            }
        }

        var borderWidth: CGFloat {
            switch self {
            case .primary:
                return 0
            case .secondary:
                return 2
            case .text:
                return 0
            }
        }
    }
}

// MARK: - Preview Providers
// SwiftUI previews are available in Xcode only

#if DEBUG
struct KindredButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack(spacing: KindredSpacing.md) {
                KindredButton("Listen", style: .primary) {
                    Logger.designSystem.debug("Primary tapped")
                }

                KindredButton("Listen", style: .primary, isLoading: true) {
                    Logger.designSystem.debug("Loading")
                }

                KindredButton("Listen", style: .primary, isDisabled: true) {
                    Logger.designSystem.debug("Disabled")
                }
            }
            .padding()
            .previewDisplayName("Primary Button")

            VStack(spacing: KindredSpacing.md) {
                KindredButton("Skip", style: .secondary) {
                    Logger.designSystem.debug("Secondary tapped")
                }

                KindredButton("Skip", style: .secondary, isDisabled: true) {
                    Logger.designSystem.debug("Disabled")
                }
            }
            .padding()
            .previewDisplayName("Secondary Button")

            VStack(spacing: KindredSpacing.md) {
                KindredButton("Learn More", style: .text) {
                    Logger.designSystem.debug("Text tapped")
                }
            }
            .padding()
            .previewDisplayName("Text Button")
        }
        .background(Color.kindredBackground)
    }
}
#endif
