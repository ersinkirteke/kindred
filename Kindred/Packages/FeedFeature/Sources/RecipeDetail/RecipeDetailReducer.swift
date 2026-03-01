import Foundation
import ComposableArchitecture
import KindredAPI
import Apollo

// MARK: - Recipe Detail Reducer

@Reducer
public struct RecipeDetailReducer {

    // MARK: - State

    @ObservableState
    public struct State: Equatable {
        public var recipeId: String
        public var recipe: RecipeDetail?
        public var isLoading: Bool = true
        public var isBookmarked: Bool = false
        public var checkedIngredients: Set<String> = []
        public var error: String?
        public var showBookmarkNudge: Bool = false

        public init(recipeId: String) {
            self.recipeId = recipeId
        }
    }

    // MARK: - Actions

    public enum Action: Equatable {
        case onAppear
        case recipeLoaded(Result<RecipeDetail, Error>)
        case toggleBookmark
        case bookmarkStatusLoaded(Bool)
        case toggleIngredient(String)
        case listenTapped
        case dismissBookmarkNudge

        public static func == (lhs: Action, rhs: Action) -> Bool {
            switch (lhs, rhs) {
            case (.onAppear, .onAppear),
                 (.toggleBookmark, .toggleBookmark),
                 (.listenTapped, .listenTapped),
                 (.dismissBookmarkNudge, .dismissBookmarkNudge):
                return true
            case let (.recipeLoaded(lhsResult), .recipeLoaded(rhsResult)):
                switch (lhsResult, rhsResult) {
                case (.success(let lhsRecipe), .success(let rhsRecipe)):
                    return lhsRecipe == rhsRecipe
                case (.failure, .failure):
                    return true
                default:
                    return false
                }
            case let (.bookmarkStatusLoaded(lhs), .bookmarkStatusLoaded(rhs)):
                return lhs == rhs
            case let (.toggleIngredient(lhs), .toggleIngredient(rhs)):
                return lhs == rhs
            default:
                return false
            }
        }
    }

    // MARK: - Dependencies

    @Dependency(\.apolloClient) var apolloClient
    @Dependency(\.guestSessionClient) var guestSession

    // MARK: - Reducer

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // Load recipe detail from Apollo cache (should be pre-fetched from feed)
                return .run { [recipeId = state.recipeId] send in
                    do {
                        // Use returnCacheDataAndFetch policy for offline-first UX
                        let query = KindredAPI.RecipeDetailQuery(id: recipeId)
                        let result = try await apolloClient.fetch(
                            query: query,
                            cachePolicy: .returnCacheDataAndFetch
                        )

                        guard let recipeData = result.data?.recipe else {
                            await send(.recipeLoaded(.failure(RecipeDetailError.notFound)))
                            return
                        }

                        let recipe = RecipeDetail.from(graphQL: recipeData)
                        await send(.recipeLoaded(.success(recipe)))

                        // Check bookmark status
                        let isBookmarked = await guestSession.isBookmarked(recipeId)
                        await send(.bookmarkStatusLoaded(isBookmarked))
                    } catch {
                        await send(.recipeLoaded(.failure(error)))
                    }
                }

            case let .recipeLoaded(.success(recipe)):
                state.recipe = recipe
                state.isLoading = false
                state.error = nil
                return .none

            case let .recipeLoaded(.failure(error)):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none

            case let .bookmarkStatusLoaded(isBookmarked):
                state.isBookmarked = isBookmarked
                return .none

            case .toggleBookmark:
                guard let recipe = state.recipe else { return .none }

                let wasBookmarked = state.isBookmarked
                state.isBookmarked.toggle()

                return .run { send in
                    do {
                        if wasBookmarked {
                            try await guestSession.unbookmarkRecipe(recipe.id)
                        } else {
                            try await guestSession.bookmarkRecipe(
                                recipe.id,
                                recipe.name,
                                recipe.imageUrl
                            )

                            // Check bookmark count for soft nudge
                            let count = await guestSession.bookmarkCount()
                            if count >= 10 {
                                // Show gentle nudge (not blocking)
                                // User decision: soft limit, not hard block
                            }
                        }
                    } catch {
                        // Revert on error
                        await send(.bookmarkStatusLoaded(wasBookmarked))
                    }
                }

            case let .toggleIngredient(ingredientId):
                // Session-only ingredient checking (not persisted for guests)
                if state.checkedIngredients.contains(ingredientId) {
                    state.checkedIngredients.remove(ingredientId)
                } else {
                    state.checkedIngredients.insert(ingredientId)
                }
                return .none

            case .listenTapped:
                // Placeholder for Phase 7 - disabled button, no-op
                return .none

            case .dismissBookmarkNudge:
                state.showBookmarkNudge = false
                return .none
            }
        }
    }

    public init() {}
}

// MARK: - Errors

enum RecipeDetailError: Error, LocalizedError {
    case notFound

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Recipe not found"
        }
    }
}
