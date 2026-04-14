import ComposableArchitecture
import SwiftUI

struct SearchResultsView: View {
    let store: StoreOf<FeedReducer>
    let heroNamespace: Namespace.ID

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
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
                        .padding()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}
