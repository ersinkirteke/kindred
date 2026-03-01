import SwiftUI

// MARK: - EmptyStateView
// Friendly empty state display for no-content scenarios

public struct EmptyStateView: View {

    // MARK: - Properties

    private let title: String
    private let message: String
    private let icon: String

    // MARK: - Initialization

    public init(
        title: String,
        message: String,
        icon: String = "tray"
    ) {
        self.title = title
        self.message = message
        self.icon = icon
    }

    // MARK: - Body

    public var body: some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            ContentUnavailableView {
                Label(title, systemImage: icon)
                    .font(.kindredHeading1())
                    .foregroundColor(.kindredTextPrimary)
            } description: {
                Text(message)
                    .font(.kindredBody())
                    .foregroundColor(.kindredTextSecondary)
                    .multilineTextAlignment(.center)
            }
        } else {
            // Fallback for iOS 16 (though our app targets iOS 17+)
            VStack(spacing: KindredSpacing.lg) {
                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundColor(.kindredAccentDecorative)

                Text(title)
                    .font(.kindredHeading1())
                    .foregroundColor(.kindredTextPrimary)

                Text(message)
                    .font(.kindredBody())
                    .foregroundColor(.kindredTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(KindredSpacing.xl)
        }
    }
}

// MARK: - Convenience Initializers

public extension EmptyStateView {

    /// No recipes found
    static var noRecipes: EmptyStateView {
        EmptyStateView(
            title: "No Recipes Found",
            message: "Try changing your location or check back later for new recipes.",
            icon: "fork.knife"
        )
    }

    /// No search results
    static var noSearchResults: EmptyStateView {
        EmptyStateView(
            title: "No Results",
            message: "We couldn't find any recipes matching your search.",
            icon: "magnifyingglass"
        )
    }

    /// No favorites
    static var noFavorites: EmptyStateView {
        EmptyStateView(
            title: "No Favorites Yet",
            message: "Tap the heart on recipes you love to save them here.",
            icon: "heart"
        )
    }

    /// No history
    static var noHistory: EmptyStateView {
        EmptyStateView(
            title: "No History",
            message: "Recipes you've listened to or watched will appear here.",
            icon: "clock"
        )
    }
}

// MARK: - Preview Providers
// SwiftUI previews are available in Xcode only

#if DEBUG
struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EmptyStateView.noRecipes
                .previewDisplayName("No Recipes")

            EmptyStateView.noSearchResults
                .previewDisplayName("No Search Results")

            EmptyStateView.noFavorites
                .previewDisplayName("No Favorites")

            EmptyStateView.noHistory
                .previewDisplayName("No History")

            EmptyStateView(
                title: "Coming Soon",
                message: "We're working on bringing you even more amazing recipes.",
                icon: "sparkles"
            )
            .previewDisplayName("Custom Empty State")
        }
        .background(Color.kindredBackground)
    }
}
#endif
