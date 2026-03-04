import ComposableArchitecture
import FeedFeature
import Foundation
import ProfileFeature
import VoicePlaybackFeature
import AuthClient
import AuthFeature

@Reducer
struct AppReducer {
    @ObservableState
    struct State: Equatable {
        var feedState = FeedReducer.State()
        var profileState = ProfileReducer.State()
        var voicePlaybackState = VoicePlaybackReducer.State()
        var selectedTab: Tab = .feed

        // Auth state management
        var currentAuthState: AuthClient.AuthState = .guest
        @Presents var authGate: SignInGateReducer.State?
        var isMigrating: Bool = false
        var migrationRetryCount: Int = 0
        var pendingGatedAction: GatedAction? = nil
    }

    enum Tab: Int, Equatable {
        case feed = 0
        case me = 1
    }

    /// Gated actions that require authentication
    enum GatedAction: Equatable {
        case bookmark(recipeId: String, recipeName: String, imageUrl: String?, cuisineType: String?)
        case toggleBookmark(recipeId: String)
        case listenToRecipe(recipeId: String, recipeName: String, artworkURL: String?, steps: [String])
    }

    enum Action {
        case feed(FeedReducer.Action)
        case profile(ProfileReducer.Action)
        case voicePlayback(VoicePlaybackReducer.Action)
        case tabSelected(Tab)

        // Auth actions
        case authStateChanged(AuthClient.AuthState)
        case authGate(PresentationAction<SignInGateReducer.Action>)
        case authGateRequested(GatedAction)
        case observeAuth

        // Migration actions
        case startMigration
        case migrationSucceeded
        case migrationFailed
        case retryMigration
    }

    @Dependency(\.signInClient) var signInClient
    @Dependency(\.guestMigrationClient) var guestMigrationClient
    @Dependency(\.continuousClock) var clock

    var body: some ReducerOf<Self> {
        Scope(state: \.feedState, action: \.feed) {
            FeedReducer()
        }
        Scope(state: \.profileState, action: \.profile) {
            ProfileReducer()
        }
        Scope(state: \.voicePlaybackState, action: \.voicePlayback) {
            VoicePlaybackReducer()
        }
        Reduce { state, action in
            switch action {
            case .tabSelected(let tab):
                state.selectedTab = tab
                return .none

            case .observeAuth:
                return .run { send in
                    for await authState in await signInClient.observeAuthState() {
                        await send(.authStateChanged(authState))
                    }
                }

            case let .authStateChanged(authState):
                state.currentAuthState = authState

                // Forward auth state to child reducers
                return .merge(
                    .send(.feed(.authStateUpdated(authState))),
                    .send(.feed(.recipeDetail(.presented(.authStateUpdated(authState)))))
                )

            case let .authGateRequested(gatedAction):
                // Check cooldown - don't show gate if dismissed within 5 minutes
                if let lastDismissedAt = UserDefaults.standard.object(forKey: "lastGateDismissedAt") as? Date {
                    let fiveMinutesAgo = Date().addingTimeInterval(-5 * 60)
                    if lastDismissedAt > fiveMinutesAgo {
                        // Within cooldown period - execute action directly without showing gate
                        print("✅ [AuthGate] Cooldown active - executing action without gate")
                        return executePendingGatedAction(gatedAction)
                    }
                }

                // Store pending action and present gate
                state.pendingGatedAction = gatedAction
                state.authGate = SignInGateReducer.State()
                return .none

            case .authGate(.presented(.signInSucceeded(let user))):
                // Update auth state
                state.currentAuthState = .authenticated(user)

                // Dismiss auth gate
                state.authGate = nil

                // Execute pending gated action
                let pendingAction = state.pendingGatedAction
                state.pendingGatedAction = nil

                // Start migration
                let executePending = executePendingGatedAction(pendingAction)
                return .merge(
                    .send(.startMigration),
                    executePending
                )

            case .authGate(.presented(.dismissed)), .authGate(.presented(.continueAsGuestTapped)):
                // Record dismissal timestamp for cooldown
                UserDefaults.standard.set(Date(), forKey: "lastGateDismissedAt")

                // Dismiss gate and clear pending action
                state.authGate = nil
                state.pendingGatedAction = nil
                return .none

            case .authGate:
                // Other auth gate actions handled by child reducer
                return .none

            case .startMigration:
                state.isMigrating = true
                state.migrationRetryCount = 0

                return .run { send in
                    do {
                        try await guestMigrationClient.migrateGuestData()
                        await send(.migrationSucceeded)
                    } catch {
                        print("❌ [Migration] Failed: \(error)")
                        await send(.migrationFailed)
                    }
                }

            case .migrationSucceeded:
                state.isMigrating = false
                state.migrationRetryCount = 0
                print("✅ [Migration] Guest data migration succeeded")
                return .none

            case .migrationFailed:
                state.isMigrating = false
                state.migrationRetryCount += 1

                // Retry with exponential backoff (2s, 4s, 8s)
                if state.migrationRetryCount <= 3 {
                    let delay = pow(2.0, Double(state.migrationRetryCount))
                    print("⏱️ [Migration] Retry \(state.migrationRetryCount)/3 in \(delay)s")

                    return .run { send in
                        try await clock.sleep(for: .seconds(delay))
                        await send(.retryMigration)
                    }
                } else {
                    print("⚠️ [Migration] Max retries exceeded - data remains local")
                    return .none
                }

            case .retryMigration:
                return .run { send in
                    do {
                        try await guestMigrationClient.migrateGuestData()
                        await send(.migrationSucceeded)
                    } catch {
                        print("❌ [Migration] Retry failed: \(error)")
                        await send(.migrationFailed)
                    }
                }

            case let .feed(.recipeDetail(.presented(recipeDetailAction))):
                // Handle recipe detail delegate actions
                if case .delegate(let delegateAction) = recipeDetailAction {
                    switch delegateAction {
                    case .authGateRequested(let actionType):
                        if let recipe = state.feedState.recipeDetail?.recipe {
                            let gatedAction: GatedAction
                            switch actionType {
                            case "bookmark":
                                gatedAction = .toggleBookmark(recipeId: recipe.id)
                            case "listen":
                                gatedAction = .listenToRecipe(
                                    recipeId: recipe.id,
                                    recipeName: recipe.name,
                                    artworkURL: recipe.imageUrl,
                                    steps: recipe.steps.map(\.text)
                                )
                            default:
                                return .none
                            }
                            return .send(.authGateRequested(gatedAction))
                        }
                    case .pausePlayback:
                        return .send(.voicePlayback(.pause))
                    }
                    return .none
                }

                // Forward listenTapped to voice playback
                if case .listenTapped = recipeDetailAction,
                   let recipe = state.feedState.recipeDetail?.recipe {
                    // Toggle play/pause if playback is active for this recipe
                    if let playback = state.voicePlaybackState.currentPlayback,
                       playback.recipeId == recipe.id {
                        if playback.status == .playing {
                            return .send(.voicePlayback(.pause))
                        } else if playback.status == .paused {
                            return .send(.voicePlayback(.play))
                        }
                    }

                    // Check auth state
                    if case .guest = state.currentAuthState {
                        // Guest user - trigger auth gate
                        let gatedAction = GatedAction.listenToRecipe(
                            recipeId: recipe.id,
                            recipeName: recipe.name,
                            artworkURL: recipe.imageUrl,
                            steps: recipe.steps.map(\.text)
                        )
                        return .send(.authGateRequested(gatedAction))
                    }

                    // Authenticated user - proceed with playback
                    return .send(.voicePlayback(.startPlayback(
                        recipeId: recipe.id,
                        recipeName: recipe.name,
                        artworkURL: recipe.imageUrl,
                        steps: recipe.steps.map(\.text)
                    )))
                }
                return .none

            case .feed(.delegate(let delegateAction)):
                // Handle feed delegate actions
                switch delegateAction {
                case let .authGateRequested(recipeId, recipeName, imageUrl, cuisineType, actionType):
                    let gatedAction: GatedAction
                    switch actionType {
                    case "bookmark":
                        gatedAction = .bookmark(
                            recipeId: recipeId,
                            recipeName: recipeName,
                            imageUrl: imageUrl,
                            cuisineType: cuisineType
                        )
                    default:
                        return .none
                    }
                    return .send(.authGateRequested(gatedAction))
                }

            case .voicePlayback:
                // HARD TEST: force .paused to check if button changes
                if var detail = state.feedState.recipeDetail {
                    detail.playbackStatus = .paused
                    state.feedState.recipeDetail = detail
                }
                return .none

            case .feed, .profile:
                return .none
            }
        }
        .ifLet(\.$authGate, action: \.authGate) {
            SignInGateReducer()
        }
    }

    // MARK: - Helper Methods

    private func executePendingGatedAction(_ gatedAction: GatedAction?) -> Effect<Action> {
        guard let gatedAction = gatedAction else { return .none }

        switch gatedAction {
        case let .bookmark(recipeId, recipeName, imageUrl, cuisineType):
            // Execute bookmark via feed reducer
            return .send(.feed(.swipeCard(recipeId, .right)))

        case let .toggleBookmark(recipeId):
            // Execute bookmark toggle via recipe detail
            return .send(.feed(.recipeDetail(.presented(.toggleBookmark))))

        case let .listenToRecipe(recipeId, recipeName, artworkURL, steps):
            // Execute voice playback
            return .send(.voicePlayback(.startPlayback(
                recipeId: recipeId,
                recipeName: recipeName,
                artworkURL: artworkURL,
                steps: steps
            )))
        }
    }
}
