import Apollo
import ComposableArchitecture
import CoreLocation
import Dependencies
import DesignSystem
import Foundation
import KindredAPI
import NetworkClient
import AuthClient
import MonetizationFeature
import PantryFeature
import os.log
import UIKit

private let feedLogger = Logger(subsystem: "com.ersinkirteke.kindred", category: "Feed")

@Reducer
public struct FeedReducer {

    public enum FeedMode: Equatable {
        case browse
        case search
    }

    @ObservableState
    public struct State: Equatable {
        public var cardStack: [RecipeCard] = []
        public var swipeHistory: [SwipedRecipe] = []
        public var isLoading = true
        public var isRefreshing = false
        public var location: String = "New York" // Default per locked decision
        public var latitude: Double = 40.7128
        public var longitude: Double = -74.0060
        public var isOffline = false
        public var hasNewRecipes = false
        public var error: String?
        public var endCursor: String? = nil
        public var hasNextPage = true
        public var bookmarkCount = 0
        public var showLocationPicker = false
        public var activeDietaryFilters: Set<String> = []
        public var allRecipes: [RecipeCard] = [] // Unfiltered full list for client-side filtering
        public var swipedRecipeIDs: Set<String> = [] // Track swiped cards to prevent reappearance
        @Presents public var recipeDetail: RecipeDetailReducer.State?
        @Presents public var paywall: SubscriptionReducer.State?

        // Culinary DNA state
        public var culinaryDNAAffinities: [AffinityScore] = []
        public var interactionCount: Int = 0
        public var isDNAActivated: Bool = false
        public var showDNAActivationCard: Bool = false
        public var hasSeenDNAActivation: Bool = false

        // Auth state
        public var currentAuthState: AuthState = .guest

        // Location request state
        public var isRequestingLocation = false

        // Subscription and ad state
        public var subscriptionStatus: SubscriptionStatus = .unknown
        public var shouldShowAds: Bool = false

        // Search state
        public var feedMode: FeedMode = .browse
        public var searchQuery: String = ""
        public var searchResults: [RecipeCard] = []
        public var isSearching: Bool = false
        public var searchEndCursor: String? = nil
        public var searchHasNextPage: Bool = true
        public var isQuotaExhausted: Bool = false
        public var searchTotalCount: Int = 0
        public var searchError: String? = nil

        public init() {}
    }

    public enum Action: Equatable {
        case onAppear
        case recipesLoaded(Result<[RecipeCard], Error>)
        case swipeCard(String, SwipeDirection)
        case undoLastSwipe
        case loadMoreRecipes
        case moreRecipesLoaded(Result<[RecipeCard], Error>, newCursor: String?, hasMore: Bool)
        case updatePaginationCursor(endCursor: String?, hasNextPage: Bool)
        case refreshFeed
        case refreshCompleted(Result<[RecipeCard], Error>)
        case changeLocation(String)
        case connectivityChanged(Bool)
        case silentRefreshCompleted(Result<[RecipeCard], Error>)
        case acknowledgeNewRecipes
        case bookmarkCountLoaded(Int)
        case toggleLocationPicker
        case dismissLocationPicker
        case useMyLocation
        case userLocationResolved(String, Double, Double)
        case userLocationFailed
        case openRecipeDetail(String)
        case recipeDetail(PresentationAction<RecipeDetailReducer.Action>)
        case dietaryFilterChanged(Set<String>)
        case filteredRecipesLoaded(Result<[RecipeCard], Error>)

        // Culinary DNA actions
        case computeCulinaryDNA
        case culinaryDNAComputed([AffinityScore], Int, Bool)
        case dismissDNAActivationCard
        case feedReranked([RecipeCard])

        // Auth actions
        case authStateUpdated(AuthState)
        case delegate(Delegate)

        // Subscription and ad actions
        case subscriptionStatusUpdated(SubscriptionStatus)
        case adVisibilityDetermined(Bool)
        case showPaywall
        case paywall(PresentationAction<SubscriptionReducer.Action>)

        // Match percentage actions
        case computeMatchPercentages
        case matchPercentagesComputed([String: Int])

        // Search actions
        case searchQueryChanged(String)
        case executeSearch(query: String, filters: Set<String>, cursor: String?)
        case searchResultsLoaded(Result<([RecipeCard], String?, Bool, Int), Error>)
        case loadMoreSearchResults
        case clearSearch

    public enum Delegate: Equatable {
        case authGateRequested(recipeId: String, recipeName: String, imageUrl: String?, cuisineType: String?, actionType: String)
    }

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
            case (.useMyLocation, .useMyLocation):
                return true
            case let (.userLocationResolved(c1, lat1, lon1), .userLocationResolved(c2, lat2, lon2)):
                return c1 == c2 && lat1 == lat2 && lon1 == lon2
            case (.userLocationFailed, .userLocationFailed):
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
            case let (.moreRecipesLoaded(r1, c1, h1), .moreRecipesLoaded(r2, c2, h2)):
                return areResultsEqual(r1, r2) && c1 == c2 && h1 == h2
            case let (.updatePaginationCursor(c1, h1), .updatePaginationCursor(c2, h2)):
                return c1 == c2 && h1 == h2
            case let (.refreshCompleted(r1), .refreshCompleted(r2)):
                return areResultsEqual(r1, r2)
            case let (.silentRefreshCompleted(r1), .silentRefreshCompleted(r2)):
                return areResultsEqual(r1, r2)
            case let (.recipeDetail(p1), .recipeDetail(p2)):
                return p1 == p2
            case let (.dietaryFilterChanged(f1), .dietaryFilterChanged(f2)):
                return f1 == f2
            case let (.filteredRecipesLoaded(r1), .filteredRecipesLoaded(r2)):
                return areResultsEqual(r1, r2)
            case (.computeCulinaryDNA, .computeCulinaryDNA):
                return true
            case let (.culinaryDNAComputed(a1, c1, act1), .culinaryDNAComputed(a2, c2, act2)):
                return a1 == a2 && c1 == c2 && act1 == act2
            case (.dismissDNAActivationCard, .dismissDNAActivationCard):
                return true
            case let (.feedReranked(r1), .feedReranked(r2)):
                return r1 == r2
            case let (.authStateUpdated(a1), .authStateUpdated(a2)):
                return a1 == a2
            case let (.delegate(d1), .delegate(d2)):
                return d1 == d2
            case let (.subscriptionStatusUpdated(s1), .subscriptionStatusUpdated(s2)):
                return s1 == s2
            case let (.adVisibilityDetermined(b1), .adVisibilityDetermined(b2)):
                return b1 == b2
            case (.showPaywall, .showPaywall):
                return true
            case let (.paywall(p1), .paywall(p2)):
                return p1 == p2
            case let (.searchQueryChanged(q1), .searchQueryChanged(q2)):
                return q1 == q2
            case let (.executeSearch(q1, f1, c1), .executeSearch(q2, f2, c2)):
                return q1 == q2 && f1 == f2 && c1 == c2
            case let (.searchResultsLoaded(r1), .searchResultsLoaded(r2)):
                return areSearchResultsEqual(r1, r2)
            case (.loadMoreSearchResults, .loadMoreSearchResults):
                return true
            case (.clearSearch, .clearSearch):
                return true
            default:
                return false
            }
        }

        private static func areSearchResultsEqual(
            _ r1: Result<([RecipeCard], String?, Bool, Int), Error>,
            _ r2: Result<([RecipeCard], String?, Bool, Int), Error>
        ) -> Bool {
            switch (r1, r2) {
            case let (.success(c1, cur1, h1, t1), .success(c2, cur2, h2, t2)):
                return c1 == c2 && cur1 == cur2 && h1 == h2 && t1 == t2
            case let (.failure(e1), .failure(e2)):
                return e1.localizedDescription == e2.localizedDescription
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

    private enum SearchDebounceID: Hashable {
        case debounce
    }

    @Dependency(\.apolloClient) var apolloClient
    @Dependency(\.guestSessionClient) var guestSession
    @Dependency(\.networkMonitorClient) var networkMonitor
    @Dependency(\.personalizationClient) var personalization
    @Dependency(\.locationClient) var locationClient
    @Dependency(\.subscriptionClient) var subscriptionClient
    @Dependency(\.adClient) var adClient
    @Dependency(\.pantryClient) var pantryClient
    @Dependency(\.authClient) var authClient

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // Load saved dietary preferences from UserDefaults
                if let data = UserDefaults.standard.data(forKey: "dietaryPreferences"),
                   let preferences = try? JSONDecoder().decode(Set<String>.self, from: data) {
                    state.activeDietaryFilters = preferences
                }

                // Load saved city from onboarding
                if let savedCity = UserDefaults.standard.string(forKey: "selectedCity"), !savedCity.isEmpty {
                    state.location = savedCity
                }

                // Don't reload if we already have cards (prevents re-fetching on tab switch / back from detail)
                guard state.cardStack.isEmpty && state.allRecipes.isEmpty else {
                    // Recompute match percentages on tab switch (pantry may have changed)
                    return .send(.computeMatchPercentages)
                }

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

                        // Task 2: Load recipes (using PopularRecipesQuery with cursor pagination)
                        group.addTask {
                            do {
                                let query = KindredAPI.PopularRecipesQuery(first: .some(20), after: .null)
                                let result = try await apolloClient.fetch(
                                    query: query,
                                    cachePolicy: .cacheFirst
                                )

                                if let connection = result.data?.popularRecipes {
                                    let cards = connection.edges.map { RecipeCard.from(popularRecipe: $0.node) }
                                    // Translate card titles/descriptions in the user's locale
                                    // BEFORE dispatching so the feed renders in the right
                                    // language on the first frame — no English flicker.
                                    let locale = Locale.current.language.languageCode?.identifier ?? "en"
                                    let localized: [RecipeCard]
                                    if locale == "en" || cards.isEmpty {
                                        localized = cards
                                    } else {
                                        do {
                                            let translationResult = try await apolloClient.fetch(
                                                query: KindredAPI.RecipeTranslationsBatchQuery(
                                                    recipeIds: cards.map(\.id),
                                                    locale: locale
                                                ),
                                                cachePolicy: .networkFirst
                                            )
                                            var translationByRecipeId: [String: (name: String, description: String?)] = [:]
                                            for t in translationResult.data?.recipeTranslations ?? [] {
                                                translationByRecipeId[t.recipeId] = (t.name, t.description)
                                            }
                                            localized = cards.map { card in
                                                if let t = translationByRecipeId[card.id] {
                                                    return card.localized(name: t.name, description: t.description)
                                                }
                                                return card
                                            }
                                        } catch {
                                            // On failure, fall back to original cards — feed still loads
                                            localized = cards
                                        }
                                    }
                                    await send(.recipesLoaded(.success(localized)))
                                    await send(.updatePaginationCursor(
                                        endCursor: connection.pageInfo.endCursor,
                                        hasNextPage: connection.pageInfo.hasNextPage
                                    ))
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

                        // Task 4: Check subscription status
                        group.addTask {
                            let status = await subscriptionClient.currentEntitlement()
                            await send(.subscriptionStatusUpdated(status))
                        }

                        // Task 5: Check ad visibility
                        group.addTask {
                            let shouldShow = await adClient.shouldShowAds()
                            await send(.adVisibilityDetermined(shouldShow))
                        }
                    }
                }

            case let .recipesLoaded(.success(cards)):
                state.isLoading = false
                state.allRecipes = cards
                // Debug: log dietary tags to diagnose filtering
                let filterDesc = state.activeDietaryFilters.joined(separator: ", ")
                feedLogger.info("📊 Loaded \(cards.count) recipes, filters: \(filterDesc)")
                for card in cards.prefix(5) {
                    let tags = card.dietaryTags.joined(separator: ", ")
                    feedLogger.info("🏷️ '\(card.name)' tags: \(tags)")
                }
                // Apply client-side dietary filtering
                state.cardStack = applyDietaryFilter(recipes: cards, filters: state.activeDietaryFilters)
                state.error = nil

                // Load hasSeenDNAActivation from UserDefaults
                state.hasSeenDNAActivation = UserDefaults.standard.bool(forKey: "hasSeenDNAActivation")

                // Prefetch detail for top card and compute DNA
                return .merge(
                    .run { _ in
                        if let topCard = cards.first {
                            let query = KindredAPI.RecipeDetailQuery(id: topCard.id)
                            _ = try? await apolloClient.fetch(
                                query: query,
                                cachePolicy: .cacheFirst
                            )
                        }
                    },
                    .send(.computeCulinaryDNA),
                    .send(.computeMatchPercentages)
                )

            case let .recipesLoaded(.failure(error)):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none

            case let .swipeCard(recipeId, direction):
                guard let cardIndex = state.cardStack.firstIndex(where: { $0.id == recipeId }) else {
                    return .none
                }

                let card = state.cardStack.remove(at: cardIndex)
                state.swipedRecipeIDs.insert(card.id)
                let swipedRecipe = SwipedRecipe(recipe: card, direction: direction)

                // Add to history (cap at 3)
                state.swipeHistory.insert(swipedRecipe, at: 0)
                if state.swipeHistory.count > 3 {
                    state.swipeHistory.removeLast()
                }

                // CHECK AUTH STATE for bookmark swipe (right swipe)
                if direction == .right, case .guest = state.currentAuthState {
                    // Guest user attempting to bookmark - trigger auth gate via delegate
                    // Card already removed from stack for responsive UI
                    return .send(.delegate(.authGateRequested(
                        recipeId: card.id,
                        recipeName: card.name,
                        imageUrl: card.imageUrl,
                        cuisineType: card.cuisineType,
                        actionType: "bookmark"
                    )))
                }

                // Trigger pagination if running low
                let shouldPaginate = state.cardStack.count <= 3 && state.hasNextPage

                // Increment interaction count and check if we should recompute DNA
                let newInteractionCount = state.interactionCount + 1
                let shouldRecomputeDNA = newInteractionCount % 10 == 0

                return .run { [cuisineType = card.cuisineType] send in
                    // Haptic feedback
                    HapticFeedback.medium()

                    // Persist swipe action (authenticated users or skip action)
                    do {
                        if direction == .right {
                            try await guestSession.bookmarkRecipe(card.id, card.name, card.imageUrl, cuisineType)
                            let count = await guestSession.bookmarkCount()
                            await send(.bookmarkCountLoaded(count))
                        } else {
                            // Skip is NOT gated - always allowed
                            try await guestSession.skipRecipe(card.id, cuisineType)
                        }
                    } catch {
                        // Silently fail - local persistence errors shouldn't block UX
                        feedLogger.error("Failed to persist swipe: \(error.localizedDescription, privacy: .public)")
                    }

                    // Trigger pagination if needed
                    if shouldPaginate {
                        await send(.loadMoreRecipes)
                    }

                    // Recompute DNA every 10 swipes for performance
                    if shouldRecomputeDNA {
                        await send(.computeCulinaryDNA)
                    }
                }

            case .undoLastSwipe:
                guard !state.swipeHistory.isEmpty else {
                    return .none
                }

                let swipedRecipe = state.swipeHistory.removeFirst()
                state.swipedRecipeIDs.remove(swipedRecipe.recipe.id)
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
                        feedLogger.error("Failed to undo swipe: \(error.localizedDescription, privacy: .public)")
                    }
                }

            case .loadMoreRecipes:
                guard state.hasNextPage && !state.isLoading else {
                    return .none
                }
                state.isLoading = true

                return .run { [endCursor = state.endCursor] send in
                    do {
                        let query = KindredAPI.PopularRecipesQuery(
                            first: .some(20),
                            after: endCursor.map { .some($0) } ?? .null
                        )
                        let result = try await apolloClient.fetch(
                            query: query,
                            cachePolicy: .cacheFirst
                        )

                        if let connection = result.data?.popularRecipes {
                            let cards = connection.edges.map { RecipeCard.from(popularRecipe: $0.node) }
                            await send(.moreRecipesLoaded(
                                .success(cards),
                                newCursor: connection.pageInfo.endCursor,
                                hasMore: connection.pageInfo.hasNextPage
                            ))
                        } else {
                            await send(.moreRecipesLoaded(.success([]), newCursor: nil, hasMore: false))
                        }
                    } catch {
                        await send(.moreRecipesLoaded(.failure(error), newCursor: nil, hasMore: false))
                    }
                }

            case let .moreRecipesLoaded(.success(cards), newCursor, hasMore):
                state.endCursor = newCursor
                state.hasNextPage = hasMore
                state.isLoading = false
                let existingIDs = Set(state.allRecipes.map(\.id)).union(state.swipedRecipeIDs)
                let newCards = cards.filter { !existingIDs.contains($0.id) }
                state.allRecipes.append(contentsOf: newCards)
                let filtered = applyDietaryFilter(recipes: newCards, filters: state.activeDietaryFilters)
                state.cardStack.append(contentsOf: filtered)
                return .send(.computeMatchPercentages)

            case .moreRecipesLoaded(.failure, _, _):
                // Silently fail pagination - don't break UX
                state.hasNextPage = false
                state.isLoading = false
                return .none

            case .refreshFeed:
                state.isRefreshing = true
                state.error = nil
                state.hasNewRecipes = false
                state.endCursor = nil

                return .run { send in
                    do {
                        let query = KindredAPI.PopularRecipesQuery(first: .some(20), after: .null)
                        let result = try await apolloClient.fetch(
                            query: query,
                            cachePolicy: .networkOnly
                        )

                        if let connection = result.data?.popularRecipes {
                            let cards = connection.edges.map { RecipeCard.from(popularRecipe: $0.node) }
                            await send(.refreshCompleted(.success(cards)))
                            await send(.updatePaginationCursor(
                                endCursor: connection.pageInfo.endCursor,
                                hasNextPage: connection.pageInfo.hasNextPage
                            ))
                        } else {
                            await send(.refreshCompleted(.success([])))
                        }
                    } catch {
                        await send(.refreshCompleted(.failure(error)))
                    }
                }

            case let .refreshCompleted(.success(cards)):
                state.isRefreshing = false
                state.swipedRecipeIDs = []
                state.allRecipes = cards
                state.cardStack = applyDietaryFilter(recipes: cards, filters: state.activeDietaryFilters)
                state.error = nil

                // Prefetch top card and compute DNA
                return .merge(
                    .run { _ in
                        if let topCard = cards.first {
                            let query = KindredAPI.RecipeDetailQuery(id: topCard.id)
                            _ = try? await apolloClient.fetch(
                                query: query,
                                cachePolicy: .cacheFirst
                            )
                        }
                    },
                    .send(.computeCulinaryDNA),
                    .send(.computeMatchPercentages)
                )

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
                state.endCursor = nil
                state.hasNextPage = true

                return .run { send in
                    do {
                        let query = KindredAPI.PopularRecipesQuery(first: .some(20), after: .null)
                        let result = try await apolloClient.fetch(
                            query: query,
                            cachePolicy: .networkOnly
                        )

                        if let connection = result.data?.popularRecipes {
                            let cards = connection.edges.map { RecipeCard.from(popularRecipe: $0.node) }
                            await send(.recipesLoaded(.success(cards)))
                            await send(.updatePaginationCursor(
                                endCursor: connection.pageInfo.endCursor,
                                hasNextPage: connection.pageInfo.hasNextPage
                            ))
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
                    return .run { send in
                        do {
                            let query = KindredAPI.PopularRecipesQuery(first: .some(20), after: .null)
                            let result = try await apolloClient.fetch(
                                query: query,
                                cachePolicy: .networkOnly
                            )

                            if let connection = result.data?.popularRecipes {
                                let cards = connection.edges.map { RecipeCard.from(popularRecipe: $0.node) }
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

            case .useMyLocation:
                state.isRequestingLocation = true
                return .run { send in
                    do {
                        let status = await locationClient.requestAuthorization()
                        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
                            await send(.userLocationFailed)
                            return
                        }
                        let location = try await locationClient.currentLocation()
                        let cityName = try await locationClient.reverseGeocode(location)
                        await send(.userLocationResolved(
                            cityName,
                            location.coordinate.latitude,
                            location.coordinate.longitude
                        ))
                    } catch {
                        feedLogger.error("❌ useMyLocation failed: \(error.localizedDescription)")
                        await send(.userLocationFailed)
                    }
                }

            case let .userLocationResolved(cityName, latitude, longitude):
                state.isRequestingLocation = false
                state.showLocationPicker = false
                state.latitude = latitude
                state.longitude = longitude
                UserDefaults.standard.set(cityName, forKey: "selectedCity")
                UserDefaults.standard.set(cityName, forKey: "lastSelectedCity")
                return .send(.changeLocation(cityName))

            case .userLocationFailed:
                state.isRequestingLocation = false
                // Fall back to Istanbul
                let fallback = CitySearchService.popularCities[0]
                state.showLocationPicker = false
                UserDefaults.standard.set(fallback.name, forKey: "selectedCity")
                UserDefaults.standard.set(fallback.name, forKey: "lastSelectedCity")
                return .send(.changeLocation(fallback.name))

            case let .openRecipeDetail(recipeId):
                // Create RecipeDetailReducer.State with current auth + subscription state
                // so listen/bookmark auth gates work correctly from the start
                var detailState = RecipeDetailReducer.State(recipeId: recipeId)
                detailState.currentAuthState = state.currentAuthState
                detailState.subscriptionStatus = state.subscriptionStatus
                state.recipeDetail = detailState
                return .none

            case let .dietaryFilterChanged(newFilters):
                state.activeDietaryFilters = newFilters
                state.error = nil

                // Save preferences to UserDefaults
                if let encoded = try? JSONEncoder().encode(newFilters) {
                    UserDefaults.standard.set(encoded, forKey: "dietaryPreferences")
                }

                // VoiceOver announcement for filter changes
                let announcement: String
                if newFilters.isEmpty {
                    announcement = "Showing all recipes"
                } else {
                    let filterNames = newFilters.sorted().joined(separator: ", ")
                    announcement = "Showing \(filterNames) recipes"
                }
                UIAccessibility.post(notification: .announcement, argument: announcement)

                // Search mode: re-trigger server-side search with new filters
                if state.feedMode == .search && state.searchQuery.count >= 3 {
                    state.isSearching = true
                    state.searchResults = []
                    state.searchEndCursor = nil
                    state.searchHasNextPage = true
                    state.searchTotalCount = 0
                    state.searchError = nil
                    return .send(.executeSearch(query: state.searchQuery, filters: newFilters, cursor: nil))
                }

                // Browse mode: client-side filtering — no server round-trip needed
                // Exclude already-swiped cards to prevent reappearance
                let unswiped = state.allRecipes.filter { !state.swipedRecipeIDs.contains($0.id) }
                state.cardStack = applyDietaryFilter(recipes: unswiped, filters: newFilters)
                return .none

            case let .searchQueryChanged(query):
                // Skip if query hasn't changed and we already have results or are searching
                if query == state.searchQuery && (!state.searchResults.isEmpty || state.isSearching) {
                    return .none
                }
                state.searchQuery = query
                if query.isEmpty {
                    state.feedMode = .browse
                    state.searchResults = []
                    return .cancel(id: SearchDebounceID.debounce)
                }
                state.feedMode = .search
                if query.count < 3 {
                    state.searchResults = []
                    return .cancel(id: SearchDebounceID.debounce)
                }
                state.isSearching = true
                state.searchResults = []
                state.searchError = nil
                state.searchEndCursor = nil
                state.searchHasNextPage = true
                state.searchTotalCount = 0
                return .run { [filters = state.activeDietaryFilters] send in
                    try await Task.sleep(nanoseconds: 300_000_000)
                    await send(.executeSearch(query: query, filters: filters, cursor: nil))
                }
                .cancellable(id: SearchDebounceID.debounce, cancelInFlight: true)

            case let .executeSearch(query, filters, cursor):
                let (diets, intolerances) = mapChipsToSearchParams(filters)
                return .run { send in
                    do {
                        let input = KindredAPI.SearchRecipesInput(
                            after: cursor.map { .some($0) } ?? .null,
                            diets: diets.isEmpty ? .null : .some(diets),
                            first: .some(20),
                            intolerances: intolerances.isEmpty ? .null : .some(intolerances),
                            query: query.isEmpty ? .null : .some(query)
                        )
                        let result = try await apolloClient.fetch(
                            query: KindredAPI.SearchRecipesQuery(input: input),
                            cachePolicy: .networkOnly
                        )
                        if let connection = result.data?.searchRecipes {
                            let cards = connection.edges.map { RecipeCard.from(searchRecipe: $0.node) }
                                .filter { $0.imageUrl != nil && !$0.imageUrl!.isEmpty }
                            let endCursor = connection.pageInfo.endCursor
                            let hasNextPage = connection.pageInfo.hasNextPage
                            let totalCount = connection.totalCount
                            await send(.searchResultsLoaded(.success((cards, endCursor, hasNextPage, totalCount))))
                        } else if let errors = result.errors, !errors.isEmpty {
                            await send(.searchResultsLoaded(.failure(FeedError.graphQL(errors.first!.localizedDescription))))
                        } else {
                            await send(.searchResultsLoaded(.success(([], nil, false, 0))))
                        }
                    } catch {
                        feedLogger.error("Search failed: \(error.localizedDescription, privacy: .public) — \(String(describing: error), privacy: .public)")
                        await send(.searchResultsLoaded(.failure(error)))
                    }
                }

            case let .searchResultsLoaded(.success((cards, cursor, hasMore, total))):
                state.isSearching = false
                if state.searchEndCursor != nil {
                    // We had a previous cursor → this is a pagination response, append
                    state.searchResults.append(contentsOf: cards)
                } else {
                    // No previous cursor → fresh search, replace
                    state.searchResults = cards
                }
                state.searchEndCursor = cursor
                state.searchHasNextPage = hasMore
                state.searchTotalCount = total
                return .none

            case let .searchResultsLoaded(.failure(error)):
                state.isSearching = false
                let message = error.localizedDescription.lowercased()
                feedLogger.error("Search error received: \(error.localizedDescription, privacy: .public)")
                if message.contains("quota") {
                    state.isQuotaExhausted = true
                } else {
                    state.searchError = error.localizedDescription
                }
                return .none

            case .loadMoreSearchResults:
                guard state.searchHasNextPage && !state.isSearching else {
                    return .none
                }
                state.isSearching = true
                return .send(.executeSearch(
                    query: state.searchQuery,
                    filters: state.activeDietaryFilters,
                    cursor: state.searchEndCursor
                ))

            case .clearSearch:
                state.feedMode = .browse
                state.searchQuery = ""
                state.searchResults = []
                state.isSearching = false
                state.searchEndCursor = nil
                state.searchHasNextPage = true
                state.searchTotalCount = 0
                state.isQuotaExhausted = false
                state.searchError = nil
                return .cancel(id: SearchDebounceID.debounce)

            case let .filteredRecipesLoaded(.success(cards)):
                state.isLoading = false
                state.cardStack = cards
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

            case let .filteredRecipesLoaded(.failure(error)):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none

            case .computeCulinaryDNA:
                return .run { send in
                    let bookmarks = await guestSession.allBookmarks()
                    let skips = await guestSession.allSkips()
                    let affinities = await personalization.computeAffinities(bookmarks, skips)
                    let count = await personalization.interactionCount(bookmarks, skips)
                    let activated = await personalization.isActivated(bookmarks, skips)
                    await send(.culinaryDNAComputed(affinities, count, activated))
                }

            case let .culinaryDNAComputed(affinities, count, activated):
                state.culinaryDNAAffinities = affinities
                state.interactionCount = count
                state.isDNAActivated = activated

                // Show activation card only once when crossing threshold
                if activated && !state.hasSeenDNAActivation {
                    state.showDNAActivationCard = true
                }

                // Re-rank feed if DNA is activated and we have cards
                if activated && !state.cardStack.isEmpty {
                    return .run { [cardStack = state.cardStack, affinities] send in
                        let reranked = await personalization.rerankFeed(cardStack, affinities)
                        await send(.feedReranked(reranked))
                    }
                }
                return .none

            case .dismissDNAActivationCard:
                state.showDNAActivationCard = false
                state.hasSeenDNAActivation = true
                // Persist to UserDefaults
                UserDefaults.standard.set(true, forKey: "hasSeenDNAActivation")
                return .none

            case let .feedReranked(cards):
                // Exclude already-swiped cards to prevent reappearance
                state.cardStack = cards.filter { !state.swipedRecipeIDs.contains($0.id) }
                return .none

            case let .authStateUpdated(authState):
                state.currentAuthState = authState
                if state.recipeDetail != nil {
                    return .send(.recipeDetail(.presented(.authStateUpdated(authState))))
                }
                return .none

            case let .subscriptionStatusUpdated(status):
                state.subscriptionStatus = status
                // Compute shouldShowAds based on subscription status and first-launch check
                if case .free = status {
                    state.shouldShowAds = adClient.shouldShowAds()
                } else {
                    state.shouldShowAds = false
                }
                return .none

            case let .adVisibilityDetermined(shouldShow):
                // Ad visibility determined by AdClient (first-launch check)
                // Treat .unknown same as .free — only suppress ads if confirmed .pro
                if case .pro = state.subscriptionStatus {
                    state.shouldShowAds = false
                } else {
                    state.shouldShowAds = shouldShow
                }
                return .none

            case .showPaywall:
                // Guest users need to sign in first — delegate to AppReducer auth gate
                guard case .authenticated = state.currentAuthState else {
                    return .send(.delegate(.authGateRequested(
                        recipeId: "",
                        recipeName: "",
                        imageUrl: nil,
                        cuisineType: nil,
                        actionType: "subscribe"
                    )))
                }
                state.paywall = SubscriptionReducer.State()
                return .none

            case .paywall:
                return .none

            case .computeMatchPercentages:
                // Get userId - skip if guest (no pantry data)
                guard case .authenticated(let user) = state.currentAuthState else {
                    return .none
                }
                let recipes = state.cardStack
                return .run { send in
                    let pantryItems = await pantryClient.fetchAllItems(user.id)
                    // Skip if pantry is empty (user decision: hide badges when no pantry items)
                    guard !pantryItems.isEmpty else { return }

                    var matchResults: [String: Int] = [:]
                    for recipe in recipes {
                        guard !recipe.ingredientNames.isEmpty else { continue }
                        if let matchPct = IngredientMatcher.computeMatchPercentage(
                            recipeIngredientNames: recipe.ingredientNames,
                            pantryItems: pantryItems
                        ) {
                            matchResults[recipe.id] = matchPct
                        }
                    }
                    await send(.matchPercentagesComputed(matchResults))
                }

            case let .matchPercentagesComputed(results):
                // Update cardStack with match percentages
                state.cardStack = state.cardStack.map { card in
                    if let pct = results[card.id] {
                        return card.withMatchPercentage(pct)
                    }
                    return card
                }
                // Also update allRecipes for consistency after dietary filter changes
                state.allRecipes = state.allRecipes.map { card in
                    if let pct = results[card.id] {
                        return card.withMatchPercentage(pct)
                    }
                    return card
                }
                return .none

            case let .updatePaginationCursor(endCursor, hasNextPage):
                state.endCursor = endCursor
                state.hasNextPage = hasNextPage
                return .none

            case .delegate:
                // Delegate actions handled by parent reducer
                return .none

            case .recipeDetail:
                // Child navigation actions handled by composition
                return .none
            }
        }
        .ifLet(\.$recipeDetail, action: \.recipeDetail) {
            RecipeDetailReducer()
        }
        .ifLet(\.$paywall, action: \.paywall) {
            SubscriptionReducer()
        }
    }
}

// MARK: - Dietary Filtering

private let allDietaryOptions = ["Vegan", "Vegetarian", "Gluten-Free", "Dairy-Free", "Keto", "Halal", "Nut-Free", "Kosher", "Low-Carb", "Pescatarian"]

private func applyDietaryFilter(recipes: [RecipeCard], filters: Set<String>) -> [RecipeCard] {
    guard !filters.isEmpty else { return recipes }
    // If all options selected, show everything (including recipes with no tags)
    if filters.count >= allDietaryOptions.count { return recipes }
    let normalizedFilters = Set(filters.map { normalizeDietaryTag($0) })
    return recipes.filter { card in
        // Include recipes with no dietary tags (untagged)
        guard !card.dietaryTags.isEmpty else { return true }
        let normalizedTags = Set(card.dietaryTags.map { normalizeDietaryTag($0) })
        return !normalizedFilters.isDisjoint(with: normalizedTags)
    }
}

private func normalizeDietaryTag(_ tag: String) -> String {
    tag.lowercased()
        .replacingOccurrences(of: "_", with: "")
        .replacingOccurrences(of: "-", with: "")
        .replacingOccurrences(of: " ", with: "")
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

// MARK: - RecipeCard Extension for Feed Query

extension RecipeCard {
    static func from(feedNode node: KindredAPI.FeedFilteredQuery.Data.Feed.Edge.Node) -> RecipeCard {
        return RecipeCard(
            id: node.id,
            name: node.name,
            description: nil,
            prepTime: node.prepTime,
            cookTime: nil,
            calories: node.calories,
            imageUrl: node.imageUrl,
            popularityScore: nil, // FeedFilteredQuery doesn't have popularityScore
            engagementLoves: node.engagementLoves ?? 0,
            dietaryTags: [],  // Not available on RecipeCard type
            difficulty: nil,  // Not available on RecipeCard type
            cuisineType: node.cuisineType.rawValue,
            ingredientNames: []
        )
    }
}
