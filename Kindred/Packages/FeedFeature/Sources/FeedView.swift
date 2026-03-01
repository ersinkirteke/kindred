import ComposableArchitecture
import DesignSystem
import SwiftUI

public struct FeedView: View {
    let store: StoreOf<FeedReducer>

    public init(store: StoreOf<FeedReducer>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.kindredBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: KindredSpacing.lg) {
                        if store.isLoading {
                            // Skeleton loading cards
                            ForEach(0..<3, id: \.self) { _ in
                                skeletonCard
                            }
                        } else {
                            EmptyStateView(
                                title: "Ready to Explore",
                                message: "Tap to discover viral recipes near you",
                                icon: "fork.knife"
                            )
                        }
                    }
                    .padding(.horizontal, KindredSpacing.md)
                    .padding(.vertical, KindredSpacing.lg)
                }
            }
            .navigationTitle(store.location)
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            store.send(.onAppear)
        }
    }

    private var skeletonCard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: KindredSpacing.sm) {
                // Image area placeholder (16:9 ratio)
                Rectangle()
                    .fill(Color.kindredDivider)
                    .aspectRatio(16/9, contentMode: .fit)
                    .cornerRadius(8)

                // Title line
                Text("Recipe Title Placeholder Text")
                    .font(.kindredHeading2())
                    .foregroundColor(.kindredTextPrimary)

                // Subtitle line
                Text("Recipe description that shows placeholder content")
                    .font(.kindredBody())
                    .foregroundColor(.kindredTextSecondary)

                // Metadata row
                HStack {
                    Text("30 min")
                        .font(.kindredCaption())
                    Text("•")
                        .font(.kindredCaption())
                    Text("Medium")
                        .font(.kindredCaption())
                }
                .foregroundColor(.kindredTextSecondary)
            }
        }
        .redacted(reason: .placeholder)
        .shimmer()
    }
}
