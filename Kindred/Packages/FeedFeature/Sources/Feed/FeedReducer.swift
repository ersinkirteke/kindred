import Apollo
import ComposableArchitecture
import Dependencies
import DesignSystem
import Foundation
import KindredAPI
import NetworkClient

@Reducer
public struct FeedReducer {
    @ObservableState
    public struct State: Equatable {
        public var cardStack: [RecipeCard] = []
        public var swipeHistory: [SwipedRecipe] = []
        public var isLoading = true
        public var isRefreshing = false
        public var location: String = "Istanbul" // Default per locked decision
        public var isOffline = false
        public var hasNewRecipes = false
        public var error: String?
        public var currentPage: Int = 0
        public var hasMorePages = true
        public var bookmarkCount = 0
        public var showLocationPicker = false
        @Presents public var recipeDetail: RecipeDetailReducer.State?

        public init() {}
    }

    public enum Action: Equatable {
        case onAppear
        case recipesLoaded(Result<[RecipeCard], Error>)
        case swipeCard(String, SwipeDirection)
        case undoLastSwipe
        case loadMoreRecipes
        case moreRecipesLoaded(Result<[RecipeCard], Error>)
        case refreshFeed
        case refreshCompleted(Result<[RecipeCard], Error>)
        case changeLocation(String)
        case connectivityChanged(Bool)
        case silentRefreshCompleted(Result<[RecipeCard], Error>)
        case acknowledgeNewRecipes
        case bookmarkCountLoaded(Int)
        case toggleLocationPicker
        case dismissLocationPicker
        case openRecipeDetail(String)
        case recipeDetail(PresentationAction<RecipeDetailReducer.Action>)

        public static func == (lhs: Action, rhs: Action) -> Bool {
            switch (lhs, rhs) {
            case (.onAppear, .onAppear):
                return true
            case (.undoLastSwipe, .undoLastSwipe):
                return true
            case (.loadMoreRecipes, .loadMoreRecipes):
                return true
            case (.refreshFeed, .refreshFeed):
                return true
            case (.acknowledgeNewRecipes, .acknowledgeNewRecipes):
                return true
            case (.toggleLocationPicker, .toggleLocationPicker):
                return true
            case (.dismissLocationPicker, .dismissLocationPicker):
                return true
            case let (.swipeCard(id1, dir1), .swipeCard(id2, dir2)):
                return id1 == id2 && dir1 == dir2
            case let (.changeLocation(loc1), .changeLocation(loc2)):
                return loc1 == loc2
            case let (.connectivityChanged(c1), .connectivityChanged(c2)):
                return c1 == c2
            case let (.bookmarkCountLoaded(c1), .bookmarkCountLoaded(c2)):
                return c1 == c2
            case let (.openRecipeDetail(id1), .openRecipeDetail(id2)):
                return id1 == id2
            case let (.recipesLoaded(r1), .recipesLoaded(r2)):
                return areResultsEqual(r1, r2)
            case let (.moreRecipesLoaded(r1), .moreRecipesLoaded(r2)):
                return areResultsEqual(r1, r2)
            case let (.refreshCompleted(r1), .refreshCompleted(r2)):
                return areResultsEqual(r1, r2)
            case let (.silentRefreshCompleted(r1), .silentRefreshCompleted(r2)):
                return areResultsEqual(r1, r2)
            case let (.recipeDetail(p1), .recipeDetail(p2)):
                return p1 == p2
            default:
                return false
            }
        }

        private static func areResultsEqual(_ r1: Result<[RecipeCard], Error>, _ r2: Result<[RecipeCard], Error>) -> Bool {
            switch (r1, r2) {
            case let (.success(cards1), .success(cards2)):
                return cards1 == cards2
            case let (.failure(e1), .failure(e2)):
                return e1.localizedDescription == e2.localizedDescription
            default:
                return false
            }
        }
    }

    public init() {}

    @Dependency(\.apolloClient) var apolloClient
    @Dependency(\.guestSessionClient) var guestSession
    @Dependency(\.networkMonitorClient) var networkMonitor

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.error = nil

                return .run { [location = state.location] send in
                    // Start network monitoring
                    await withTaskGroup(of: Void.self) { group in
                        // Task 1: Connectivity stream
                        group.addTask {
                            for await isConnected in await networkMonitor.connectivityStream() {
                                await send(.connectivityChanged(isConnected))
                            }
                        }

                        // Task 2: Load recipes
                        group.addTask {
                            do {
                                let query = KindredAPI.ViralRecipesQuery(location: location)
                                let result = try await apolloClient.fetch(
                                    query: query,
                                    cachePolicy: .cacheFirst
                                )

                                if let recipes = result.data?.viralRecipes {
                                    let cards = recipes.map { RecipeCard.from(graphQL: $0) }
                                    await send(.recipesLoaded(.success(cards)))
                                } else if let errors = result.errors, !errors.isEmpty {
                                    await send(.recipesLoaded(.failure(FeedError.graphQL(errors.first!.localizedDescription))))
                                } else {
                                    await send(.recipesLoaded(.success([])))
                                }
                            } catch {
                                await send(.recipesLoaded(.failure(error)))
                            }
                        }

                        // Task 3: Load bookmark count
                        group.addTask {
                            let count = await guestSession.bookmarkCount()
                            await send(.bookmarkCountLoaded(count))
                        }
                    }
                }

            case let .recipesLoaded(.success(cards)):
                state.isLoading = false
                state.cardStack = cards
                state.hasMorePages = cards.count >= 10
                state.currentPage = 1
                state.error = nil

                // Prefetch detail for top card
                if let topCard = cards.first {
                    return .run { _ in
                        let query = KindredAPI.RecipeDetailQuery(id: topCard.id)
                        _ = try? await apolloClient.fetch(
                            query: query,
                            cachePolicy: .cacheFirst
                        )
                    }
                }
                return .none

            case let .recipesLoaded(.failure(error)):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none

            case let .swipeCard(recipeId, direction):
                guard let cardIndex = state.cardStack.firstIndex(where: { $0.id == recipeId }) else {
                    return .none
                }

                let card = state.cardStack.remove(at: cardIndex)
                let swipedRecipe = SwipedRecipe(recipe: card, direction: direction)

                // Add to history (cap at 3)
                state.swipeHistory.insert(swipedRecipe, at: 0)
                if state.swipeHistory.count > 3 {
                    state.swipeHistory.removeLast()
                }

                // Trigger pagination if running low
                let shouldPaginate = state.cardStack.count <= 3 && state.hasMorePages

                return .run { [location = state.location, page = state.currentPage] send in
                    // Haptic feedback
                    HapticFeedback.medium()

                    // Persist swipe action
                    do {
                        if direction == .right {
                            try await guestSession.bookmarkRecipe(card.id, card.name, card.imageUrl)
                            let count = await guestSession.bookmarkCount()
                            await send(.bookmarkCountLoaded(count))
                        } else {
                            try await guestSession.skipRecipe(card.id)
                        }
                    } catch {
                        // Silently fail - local persistence errors shouldn't block UX
                        print("Failed to persist swipe: \(error)")
                    }

                    // Trigger pagination if needed
                    if shouldPaginate {
                        await send(.loadMoreRecipes)
                    }
                }

            case .undoLastSwipe:
                guard !state.swipeHistory.isEmpty else {
                    return .none
                }

                let swipedRecipe = state.swipeHistory.removeFirst()
                state.cardStack.insert(swipedRecipe.recipe, at: 0)

                return .run { send in
                    // Haptic feedback
                    HapticFeedback.light()

                    // Undo persistence
                    do {
                        if swipedRecipe.direction == .right {
                            try await guestSession.unbookmarkRecipe(swipedRecipe.recipe.id)
                            let count = await guestSession.bookmarkCount()
                            await send(.bookmarkCountLoaded(count))
                        } else {
                            try await guestSession.undoSkip(swipedRecipe.recipe.id)
                        }
                    } catch {
                        print("Failed to undo swipe: \(error)")
                    }
                }

            case .loadMoreRecipes:
                guard state.hasMorePages && !state.isLoading else {
                    return .none
                }

                return .run { [location = state.location, page = state.currentPage] send in
                    do {
                        let query = KindredAPI.RecipesQuery(
                            location: .some(location),
                            limit: .some(10),
                            offset: .some(Int32(page * 10))
                        )
                        let result = try await apolloClient.fetch(
                            query: query,
                            cachePolicy: .cacheFirst
                        )

                        if let recipes = result.data?.recipes {
                            let cards = recipes.map { RecipeCard.from(recipesQuery: $0) }
                            await send(.moreRecipesLoaded(.success(cards)))
                        } else {
                            await send(.moreRecipesLoaded(.success([])))
                        }
                    } catch {
                        await send(.moreRecipesLoaded(.failure(error)))
                    }
                }

            case let .moreRecipesLoaded(.success(cards)):
                state.cardStack.append(contentsOf: cards)
                state.hasMorePages = cards.count >= 10
                state.currentPage += 1
                return .none

            case .moreRecipesLoaded(.failure):
                // Silently fail pagination - don't break UX
                state.hasMorePages = false
                return .none

            case .refreshFeed:
                state.isRefreshing = true
                state.error = nil
                state.hasNewRecipes = false

                return .run { [location = state.location] send in
                    do {
                        let query = KindredAPI.ViralRecipesQuery(location: location)
                        let result = try await apolloClient.fetch(
                            query: query,
                            cachePolicy: .networkOnly
                        )

                        if let recipes = result.data?.viralRecipes {
                            let cards = recipes.map { RecipeCard.from(graphQL: $0) }
                            await send(.refreshCompleted(.success(cards)))
                        } else {
                            await send(.refreshCompleted(.success([])))
                        }
                    } catch {
                        await send(.refreshCompleted(.failure(error)))
                    }
                }

            case let .refreshCompleted(.success(cards)):
                state.isRefreshing = false
                state.cardStack = cards
                state.hasMorePages = cards.count >= 10
                state.currentPage = 1
                state.error = nil

                // Prefetch top card
                if let topCard = cards.first {
                    return .run { _ in
                        let query = KindredAPI.RecipeDetailQuery(id: topCard.id)
                        _ = try? await apolloClient.fetch(
                            query: query,
                            cachePolicy: .cacheFirst
                        )
                    }
                }
                return .none

            case let .refreshCompleted(.failure(error)):
                state.isRefreshing = false
                state.error = error.localizedDescription
                return .none

            case let .changeLocation(newLocation):
                state.location = newLocation
                state.cardStack = []
                state.swipeHistory = []
                state.isLoading = true
                state.error = nil
                state.currentPage = 0
                state.hasMorePages = true

                return .run { send in
                    do {
                        let query = KindredAPI.ViralRecipesQuery(location: newLocation)
                        let result = try await apolloClient.fetch(
                            query: query,
                            cachePolicy: .networkOnly
                        )

                        if let recipes = result.data?.viralRecipes {
                            let cards = recipes.map { RecipeCard.from(graphQL: $0) }
                            await send(.recipesLoaded(.success(cards)))
                        } else {
                            await send(.recipesLoaded(.success([])))
                        }
                    } catch {
                        await send(.recipesLoaded(.failure(error)))
                    }
                }

            case let .connectivityChanged(isConnected):
                let wasOffline = state.isOffline
                state.isOffline = !isConnected

                // If we just came back online, do a silent refresh
                if wasOffline && isConnected {
                    return .run { [location = state.location] send in
                        do {
                            let query = KindredAPI.ViralRecipesQuery(location: location)
                            let result = try await apolloClient.fetch(
                                query: query,
                                cachePolicy: .networkOnly
                            )

                            if let recipes = result.data?.viralRecipes {
                                let cards = recipes.map { RecipeCard.from(graphQL: $0) }
                                await send(.silentRefreshCompleted(.success(cards)))
                            }
                        } catch {
                            // Silently fail - we're just opportunistically refreshing
                        }
                    }
                }
                return .none

            case let .silentRefreshCompleted(.success(cards)):
                // Don't replace current stack - just indicate new recipes available
                if !cards.isEmpty {
                    state.hasNewRecipes = true
                }
                return .none

            case .silentRefreshCompleted(.failure):
                return .none

            case .acknowledgeNewRecipes:
                state.hasNewRecipes = false
                return .send(.refreshFeed)

            case let .bookmarkCountLoaded(count):
                state.bookmarkCount = count
                return .none

            case .toggleLocationPicker:
                state.showLocationPicker.toggle()
                return .none

            case .dismissLocationPicker:
                state.showLocationPicker = false
                return .none

            case let .openRecipeDetail(recipeId):
                // Create RecipeDetailReducer.State and present it
                state.recipeDetail = RecipeDetailReducer.State(recipeId: recipeId)
                return .none

            case .recipeDetail:
                // Child navigation actions handled by composition
                return .none
            }
        }
        .ifLet(\.$recipeDetail, action: \.recipeDetail) {
            RecipeDetailReducer()
        }
    }
}

// MARK: - Errors

private enum FeedError: LocalizedError {
    case graphQL(String)

    var errorDescription: String? {
        switch self {
        case .graphQL(let message):
            return message
        }
    }
}

// MARK: - RecipeCard Extension for Recipes Query

extension RecipeCard {
    static func from(recipesQuery recipe: KindredAPI.RecipesQuery.Data.Recipe) -> RecipeCard {
        return RecipeCard(
            id: recipe.id,
            name: recipe.name,
            description: recipe.description,
            prepTime: recipe.prepTime,
            cookTime: recipe.cookTime,
            calories: recipe.calories,
            imageUrl: recipe.imageUrl,
            isViral: recipe.isViral ?? false,
            engagementLoves: recipe.engagementLoves ?? 0,
            dietaryTags: recipe.dietaryTags ?? [],
            difficulty: recipe.difficulty.rawValue
        )
    }
}
