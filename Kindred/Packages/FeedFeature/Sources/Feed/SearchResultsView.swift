import ComposableArchitecture
import DesignSystem
import SwiftUI

struct SearchResultsView: View {
    let store: StoreOf<FeedReducer>
    let heroNamespace: Namespace.ID

    var body: some View {
        ScrollView {
            VStack(spacing: KindredSpacing.md) {
                ForEach(store.searchResults) { recipe in
                    SearchResultCardView(
                        recipe: recipe,
                        heroNamespace: heroNamespace,
                        onTap: { id in store.send(.openRecipeDetail(id)) }
                    )
                    .onAppear {
                        // Auto-load more when within 3 cards of bottom
                        if recipe == store.searchResults.suffix(3).first {
                            store.send(.loadMoreSearchResults)
                        }
                    }
                }

                // Bottom loading spinner for pagination
                if store.isSearching && !store.searchResults.isEmpty {
                    ProgressView()
                        .padding(KindredSpacing.lg)
                }

                // End of results
                if !store.searchHasNextPage && !store.searchResults.isEmpty && !store.isSearching {
                    Text(String(localized: "search.end_of_results", bundle: .main))
                        .font(.kindredCaption())
                        .foregroundStyle(.kindredTextSecondary)
                        .padding(.vertical, KindredSpacing.sm)
                }
            }
            .padding(.horizontal, KindredSpacing.md)
            .padding(.bottom, KindredSpacing.md)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollBounceBehavior(.basedOnSize)
        .background(Color.kindredBackground)
    }
}
