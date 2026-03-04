import Foundation
import ComposableArchitecture
import KindredAPI
import Apollo
import AuthClient
import VoicePlaybackFeature

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
        public var currentAuthState: AuthState = .guest
        public var playbackStatus: PlaybackStatus = .idle

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
        case authStateUpdated(AuthState)
        case playbackStatusUpdated(PlaybackStatus)
        case delegate(Delegate)

    public enum Delegate: Equatable {
        case authGateRequested(actionType: String)
        case pausePlayback
    }

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
            case let (.authStateUpdated(lhs), .authStateUpdated(rhs)):
                return lhs == rhs
            case let (.playbackStatusUpdated(lhs), .playbackStatusUpdated(rhs)):
                return lhs == rhs
            case let (.delegate(lhs), .delegate(rhs)):
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
                            cachePolicy: .cacheFirst
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

                // CHECK AUTH STATE - gate bookmark for guests
                if case .guest = state.currentAuthState {
                    return .send(.delegate(.authGateRequested(actionType: "bookmark")))
                }

                // Authenticated user - proceed with bookmark toggle
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
                                recipe.imageUrl,
                                nil // cuisineType not available in detail view
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
                // If already playing this recipe, pause it
                if case .playing = state.playbackStatus {
                    return .send(.delegate(.pausePlayback))
                }

                // CHECK AUTH STATE - gate listen for guests
                if case .guest = state.currentAuthState {
                    return .send(.delegate(.authGateRequested(actionType: "listen")))
                }

                // Authenticated user - action handled by parent AppReducer
                return .none

            case .dismissBookmarkNudge:
                state.showBookmarkNudge = false
                return .none

            case let .authStateUpdated(authState):
                state.currentAuthState = authState
                return .none

            case let .playbackStatusUpdated(status):
                state.playbackStatus = status
                return .none

            case .delegate:
                // Delegate actions handled by parent reducer
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
