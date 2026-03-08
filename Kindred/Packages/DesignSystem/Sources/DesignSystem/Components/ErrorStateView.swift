import SwiftUI
import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    static let designSystem = Logger(subsystem: subsystem, category: "design-system")
}

// MARK: - ErrorStateView
// Warm, friendly error display for failed states

public struct ErrorStateView: View {

    // MARK: - Properties

    private let title: String
    private let message: String
    private let icon: String
    private let retryAction: (() -> Void)?

    // MARK: - Initialization

    public init(
        title: String,
        message: String,
        icon: String = "exclamationmark.triangle",
        retryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.retryAction = retryAction
    }

    // MARK: - Body

    public var body: some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            ContentUnavailableView {
                Label(title, systemImage: icon)
                    .font(.kindredHeading1())
                    .foregroundColor(.kindredTextPrimary)
            } description: {
                VStack(spacing: KindredSpacing.md) {
                    Text(message)
                        .font(.kindredBody())
                        .foregroundColor(.kindredTextSecondary)
                        .multilineTextAlignment(.center)

                    if let retryAction = retryAction {
                        KindredButton("Try Again", style: .primary) {
                            retryAction()
                        }
                        .padding(.top, KindredSpacing.sm)
                    }
                }
            }
        } else {
            // Fallback for iOS 16 (though our app targets iOS 17+)
            VStack(spacing: KindredSpacing.lg) {
                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundColor(.kindredAccent)

                Text(title)
                    .font(.kindredHeading1())
                    .foregroundColor(.kindredTextPrimary)

                Text(message)
                    .font(.kindredBody())
                    .foregroundColor(.kindredTextSecondary)
                    .multilineTextAlignment(.center)

                if let retryAction = retryAction {
                    KindredButton("Try Again", style: .primary) {
                        retryAction()
                    }
                    .padding(.top, KindredSpacing.sm)
                }
            }
            .padding(KindredSpacing.xl)
        }
    }
}

// MARK: - Convenience Initializers

public extension ErrorStateView {

    /// Network error state
    static func networkError(retryAction: @escaping () -> Void) -> ErrorStateView {
        ErrorStateView(
            title: "Connection Issue",
            message: "Hmm, we can't find recipes right now. Check your connection and try again.",
            icon: "wifi.slash",
            retryAction: retryAction
        )
    }

    /// Generic error state
    static func genericError(retryAction: @escaping () -> Void) -> ErrorStateView {
        ErrorStateView(
            title: "Something Went Wrong",
            message: "We couldn't load that right now. Give it another try?",
            icon: "exclamationmark.triangle",
            retryAction: retryAction
        )
    }

    /// Location permission error
    static func locationError(openSettings: @escaping () -> Void) -> ErrorStateView {
        ErrorStateView(
            title: "Location Needed",
            message: "We need your location to find recipes nearby. You can enable this in Settings.",
            icon: "location.slash",
            retryAction: openSettings
        )
    }
}

// MARK: - Preview Providers
// SwiftUI previews are available in Xcode only

#if DEBUG
struct ErrorStateView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ErrorStateView.networkError {
                Logger.designSystem.debug("Retry tapped")
            }
            .previewDisplayName("Network Error")

            ErrorStateView.genericError {
                Logger.designSystem.debug("Retry tapped")
            }
            .previewDisplayName("Generic Error")

            ErrorStateView.locationError {
                Logger.designSystem.debug("Open settings tapped")
            }
            .previewDisplayName("Location Error")

            ErrorStateView(
                title: "Recipe Not Found",
                message: "This recipe has been removed or is no longer available.",
                icon: "fork.knife",
                retryAction: nil
            )
            .previewDisplayName("Custom Error")
        }
        .background(Color.kindredBackground)
    }
}
#endif
