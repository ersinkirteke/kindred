import Foundation
import ComposableArchitecture
import KindredAPI
import Apollo
import AuthClient
import VoicePlaybackFeature
import MonetizationFeature
import PantryFeature

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
        public var isMiniPlayerVisible: Bool = false
        public var subscriptionStatus: SubscriptionStatus = .unknown
        public var shouldShowAds: Bool = false
        public var currentStepIndex: Int? = nil
        public var isAVSpeechActive: Bool = false

        // Ingredient match state
        public var ingredientMatchStatuses: [String: IngredientMatchStatus] = [:]
        public var matchedCount: Int = 0
        public var eligibleCount: Int = 0
        public var matchPercentage: Int? = nil
        @Presents public var shoppingList: ShoppingListReducer.State?

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
        case pauseTapped
        case resumeTapped
        case dismissBookmarkNudge
        case authStateUpdated(AuthState)
        case playbackStatusUpdated(PlaybackStatus)
        case miniPlayerVisibilityChanged(Bool)
        case subscriptionStatusUpdated(SubscriptionStatus)
        case adVisibilityDetermined(Bool)
        case computeIngredientMatch
        case ingredientMatchComputed([String: IngredientMatchStatus], Int, Int, Int)
        case showShoppingList
        case shoppingList(PresentationAction<ShoppingListReducer.Action>)
        case currentStepIndexUpdated(Int?)
        case isAVSpeechActiveUpdated(Bool)
        case jumpToStep(Int)
        case recipeTranslationApplied(
            name: String,
            description: String?,
            ingredients: [RecipeIngredient],
            steps: [RecipeStep]
        )
        case delegate(Delegate)

    public enum Delegate: Equatable {
        case authGateRequested(actionType: String)
        case pausePlayback
        case resumePlayback
        case jumpToStep(Int)
    }

        public static func == (lhs: Action, rhs: Action) -> Bool {
            switch (lhs, rhs) {
            case (.onAppear, .onAppear),
                 (.toggleBookmark, .toggleBookmark),
                 (.listenTapped, .listenTapped),
                 (.pauseTapped, .pauseTapped),
                 (.resumeTapped, .resumeTapped),
                 (.dismissBookmarkNudge, .dismissBookmarkNudge),
                 (.computeIngredientMatch, .computeIngredientMatch),
                 (.showShoppingList, .showShoppingList):
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
            case let (.miniPlayerVisibilityChanged(lhs), .miniPlayerVisibilityChanged(rhs)):
                return lhs == rhs
            case let (.subscriptionStatusUpdated(lhs), .subscriptionStatusUpdated(rhs)):
                return lhs == rhs
            case let (.adVisibilityDetermined(lhs), .adVisibilityDetermined(rhs)):
                return lhs == rhs
            case let (.ingredientMatchComputed(lhsStatuses, lhsMatched, lhsEligible, lhsPct),
                      .ingredientMatchComputed(rhsStatuses, rhsMatched, rhsEligible, rhsPct)):
                return lhsStatuses == rhsStatuses && lhsMatched == rhsMatched && lhsEligible == rhsEligible && lhsPct == rhsPct
            case let (.shoppingList(lhs), .shoppingList(rhs)):
                return lhs == rhs
            case let (.currentStepIndexUpdated(lhs), .currentStepIndexUpdated(rhs)):
                return lhs == rhs
            case let (.isAVSpeechActiveUpdated(lhs), .isAVSpeechActiveUpdated(rhs)):
                return lhs == rhs
            case let (.jumpToStep(lhs), .jumpToStep(rhs)):
                return lhs == rhs
            case let (.recipeTranslationApplied(lName, lDesc, lIng, lSteps),
                      .recipeTranslationApplied(rName, rDesc, rIng, rSteps)):
                return lName == rName && lDesc == rDesc && lIng == rIng && lSteps == rSteps
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
    @Dependency(\.subscriptionClient) var subscriptionClient
    @Dependency(\.adClient) var adClient
    @Dependency(\.pantryClient) var pantryClient

    // MARK: - Reducer

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // Load recipe detail from Apollo cache (should be pre-fetched from feed)
                return .run { [recipeId = state.recipeId] send in
                    await withTaskGroup(of: Void.self) { group in
                        // Task 1: Load recipe
                        group.addTask {
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

                        // Task 2: Check subscription status
                        group.addTask {
                            let status = await subscriptionClient.currentEntitlement()
                            await send(.subscriptionStatusUpdated(status))
                        }

                        // Task 3: Check ad visibility
                        group.addTask {
                            let shouldShow = await adClient.shouldShowAds()
                            await send(.adVisibilityDetermined(shouldShow))
                        }

                        // Task 4: Localize recipe text if the device isn't already English.
                        // Backend returns null for 'en' so we skip the call entirely there.
                        let locale = Locale.current.language.languageCode?.identifier ?? "en"
                        if locale != "en" {
                            group.addTask {
                                do {
                                    let result = try await apolloClient.fetch(
                                        query: KindredAPI.RecipeTranslationQuery(
                                            recipeId: recipeId,
                                            locale: locale
                                        ),
                                        cachePolicy: .networkFirst
                                    )
                                    guard let translation = result.data?.recipeTranslation else { return }
                                    let ingredients = translation.ingredients.enumerated().map { idx, i in
                                        RecipeIngredient(
                                            name: i.name,
                                            quantity: i.quantity.isEmpty ? nil : i.quantity,
                                            unit: i.unit.isEmpty ? nil : i.unit,
                                            orderIndex: idx
                                        )
                                    }
                                    let steps = translation.steps.map { s in
                                        RecipeStep(orderIndex: s.orderIndex, text: s.text)
                                    }
                                    await send(.recipeTranslationApplied(
                                        name: translation.name,
                                        description: translation.description,
                                        ingredients: ingredients,
                                        steps: steps
                                    ))
                                } catch {
                                    // Translation is best-effort; swallow errors and keep original text
                                }
                            }
                        }
                    }
                }

            case let .recipeLoaded(.success(recipe)):
                state.recipe = recipe
                state.isLoading = false
                state.error = nil
                return .send(.computeIngredientMatch)

            case let .recipeLoaded(.failure(error)):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none

            case let .recipeTranslationApplied(name, description, ingredients, steps):
                // Merge translated strings into the loaded recipe, preserving everything
                // else (times, calories, tags, etc.). If recipe hasn't arrived yet the
                // effect no-ops and the translation would naturally be re-fetched on
                // next onAppear (it'll come out of Apollo cache next time).
                guard let recipe = state.recipe else { return .none }
                state.recipe = RecipeDetail(
                    id: recipe.id,
                    name: name,
                    description: description ?? recipe.description,
                    prepTime: recipe.prepTime,
                    cookTime: recipe.cookTime,
                    servings: recipe.servings,
                    calories: recipe.calories,
                    imageUrl: recipe.imageUrl,
                    popularityScore: recipe.popularityScore,
                    engagementLoves: recipe.engagementLoves,
                    dietaryTags: recipe.dietaryTags,
                    difficulty: recipe.difficulty,
                    sourceUrl: recipe.sourceUrl,
                    sourceName: recipe.sourceName,
                    ingredients: ingredients,
                    steps: steps
                )
                return .send(.computeIngredientMatch)

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
                // Only fires for NEW playback (idle state) — view sends
                // .pauseTapped/.resumeTapped for active playback instead
                if case .guest = state.currentAuthState {
                    return .send(.delegate(.authGateRequested(actionType: "listen")))
                }
                // AppReducer handles startPlayback
                return .none

            case .pauseTapped:
                return .send(.delegate(.pausePlayback))

            case .resumeTapped:
                return .send(.delegate(.resumePlayback))

            case .dismissBookmarkNudge:
                state.showBookmarkNudge = false
                return .none

            case let .authStateUpdated(authState):
                state.currentAuthState = authState
                return .none

            case let .playbackStatusUpdated(status):
                state.playbackStatus = status
                return .none

            case let .miniPlayerVisibilityChanged(visible):
                state.isMiniPlayerVisible = visible
                return .none

            case let .subscriptionStatusUpdated(status):
                state.subscriptionStatus = status
                // Only suppress ads if confirmed .pro — treat .unknown same as .free
                if case .pro = status {
                    state.shouldShowAds = false
                } else {
                    state.shouldShowAds = adClient.shouldShowAds()
                }
                return .none

            case let .adVisibilityDetermined(shouldShow):
                // Only suppress ads if confirmed .pro — treat .unknown same as .free
                if case .pro = state.subscriptionStatus {
                    state.shouldShowAds = false
                } else {
                    state.shouldShowAds = shouldShow
                }
                return .none

            case .computeIngredientMatch:
                guard let recipe = state.recipe else { return .none }

                // Only compute matches for authenticated users
                guard case .authenticated(let user) = state.currentAuthState else {
                    return .none
                }

                let ingredients = recipe.ingredients
                return .run { send in
                    let pantryItems = await pantryClient.fetchAllItems(user.id)
                    let validPantry = pantryItems.filter { !$0.isDeleted }
                    let pantryNormalized = validPantry.map { IngredientMatcher.normalize($0.normalizedName ?? $0.name) }

                    var statuses: [String: IngredientMatchStatus] = [:]
                    var matched = 0
                    var eligible = 0

                    for ingredient in ingredients {
                        if IngredientMatcher.isStaple(ingredient.name) {
                            statuses[ingredient.id] = .staple
                            continue
                        }
                        eligible += 1
                        let normalizedIngredient = IngredientMatcher.normalize(ingredient.name)

                        // Fuzzy matching: bidirectional contains check per locked decision
                        let isMatch = pantryNormalized.contains { pantryName in
                            pantryName.contains(normalizedIngredient) || normalizedIngredient.contains(pantryName)
                        }

                        if isMatch {
                            statuses[ingredient.id] = .available
                            matched += 1
                        } else {
                            statuses[ingredient.id] = .missing
                        }
                    }

                    let pct = eligible > 0 ? Int((Double(matched) / Double(eligible)) * 100) : 0
                    await send(.ingredientMatchComputed(statuses, matched, eligible, pct))
                }

            case let .ingredientMatchComputed(statuses, matched, eligible, pct):
                state.ingredientMatchStatuses = statuses
                state.matchedCount = matched
                state.eligibleCount = eligible
                state.matchPercentage = eligible > 0 ? pct : nil
                return .none

            case .showShoppingList:
                guard let recipe = state.recipe else { return .none }
                let missingIngredients = recipe.ingredients.filter { ingredient in
                    state.ingredientMatchStatuses[ingredient.id] == .missing
                }
                guard !missingIngredients.isEmpty else { return .none }
                state.shoppingList = ShoppingListReducer.State(
                    recipeName: recipe.name,
                    missingIngredients: missingIngredients,
                    matchedCount: state.matchedCount,
                    totalEligible: state.eligibleCount
                )
                return .none

            case .shoppingList:
                // Presentation actions handled by TCA
                return .none

            case let .currentStepIndexUpdated(index):
                state.currentStepIndex = index
                return .none

            case let .isAVSpeechActiveUpdated(active):
                state.isAVSpeechActive = active
                return .none

            case let .jumpToStep(stepIndex):
                // Delegate to AppReducer which routes to VoicePlaybackReducer
                return .send(.delegate(.jumpToStep(stepIndex)))

            case .delegate:
                // Delegate actions handled by parent reducer
                return .none
            }
        }
        .ifLet(\.$shoppingList, action: \.shoppingList) {
            ShoppingListReducer()
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
