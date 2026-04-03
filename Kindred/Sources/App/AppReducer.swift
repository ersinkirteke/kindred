import ComposableArchitecture
import FeedFeature
import Foundation
import PantryFeature
import ProfileFeature
import VoicePlaybackFeature
import AuthClient
import AuthFeature
import MonetizationFeature
import UIKit
import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    static let migration = Logger(subsystem: subsystem, category: "migration")
}

@Reducer
struct AppReducer {
    @ObservableState
    struct State: Equatable {
        var feedState = FeedReducer.State()
        var pantryState = PantryReducer.State()
        var profileState = ProfileReducer.State()
        var voicePlaybackState = VoicePlaybackReducer.State()
        var consentState = ConsentReducer.State()
        var selectedTab: Tab = .feed

        // Auth state management
        var currentAuthState: AuthClient.AuthState = .guest
        @Presents var authGate: SignInGateReducer.State?
        @Presents var onboarding: OnboardingReducer.State?
        var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        var isMigrating: Bool = false
        var migrationRetryCount: Int = 0
        var pendingGatedAction: GatedAction? = nil

        // Consent state
        var needsConsentFlow: Bool = false

        // Connectivity state
        var isOffline: Bool = false
    }

    enum Tab: Int, Equatable {
        case feed = 0
        case pantry = 1
        case me = 2
    }

    /// Gated actions that require authentication
    enum GatedAction: Equatable {
        case bookmark(recipeId: String, recipeName: String, imageUrl: String?, cuisineType: String?)
        case toggleBookmark(recipeId: String)
        case listenToRecipe(recipeId: String, recipeName: String, artworkURL: String?, steps: [String])
    }

    enum Action {
        case feed(FeedReducer.Action)
        case pantry(PantryReducer.Action)
        case profile(ProfileReducer.Action)
        case voicePlayback(VoicePlaybackReducer.Action)
        case consent(ConsentReducer.Action)
        case tabSelected(Tab)

        // Auth actions
        case authStateChanged(AuthClient.AuthState)
        case authGate(PresentationAction<SignInGateReducer.Action>)
        case authGateRequested(GatedAction)
        case observeAuth

        // Onboarding actions
        case onboarding(PresentationAction<OnboardingReducer.Action>)
        case presentOnboarding
        case persistOnboardingCompletion

        // Consent actions
        case checkConsentStatus
        case triggerConsentFlow

        // Migration actions
        case startMigration
        case migrationSucceeded
        case migrationFailed
        case retryMigration
        case checkPendingMigration

        // Connectivity actions
        case startConnectivityMonitor
        case connectivityChanged(Bool)
    }

    @Dependency(\.signInClient) var signInClient
    @Dependency(\.guestMigrationClient) var guestMigrationClient
    @Dependency(\.guestSessionClient) var guestSession
    @Dependency(\.continuousClock) var clock
    @Dependency(\.networkMonitorClient) var networkMonitor
    @Dependency(\.consentClient) var consentClient
    @Dependency(\.adClient) var adClient

    var body: some ReducerOf<Self> {
        Scope(state: \.feedState, action: \.feed) {
            FeedReducer()
        }
        Scope(state: \.pantryState, action: \.pantry) {
            PantryReducer()
        }
        Scope(state: \.profileState, action: \.profile) {
            ProfileReducer()
        }
        Scope(state: \.voicePlaybackState, action: \.voicePlayback) {
            VoicePlaybackReducer()
        }
        Scope(state: \.consentState, action: \.consent) {
            ConsentReducer()
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

            case .startConnectivityMonitor:
                return .run { send in
                    for await isConnected in await networkMonitor.connectivityStream() {
                        await send(.connectivityChanged(!isConnected))
                    }
                }

            case let .connectivityChanged(isOffline):
                let wasOffline = state.isOffline
                state.isOffline = isOffline

                // VoiceOver announcement for connectivity changes
                UIAccessibility.post(
                    notification: .announcement,
                    argument: isOffline ? "You're offline" : "Back online"
                )

                // Auto-refresh feed and retry pending migration when connectivity returns
                if wasOffline && !isOffline {
                    var effects: [Effect<Action>] = [.send(.feed(.refreshFeed))]

                    // Retry pending migration when connectivity returns
                    if UserDefaults.standard.bool(forKey: "pendingMigration"),
                       !state.isMigrating,
                       state.migrationRetryCount < 3 {
                        effects.append(.send(.startMigration))
                    }

                    return .merge(effects)
                }

                return .none

            case let .authStateChanged(authState):
                state.currentAuthState = authState

                // Check for pending migration on authenticated app launch
                // Map to profile auth state
                let profileAuthState: ProfileFeature.AuthState
                let pantryUserId: String?
                if case .authenticated(let user) = authState {
                    profileAuthState = .authenticated(userId: user.id)
                    pantryUserId = user.id
                } else {
                    profileAuthState = .guest
                    pantryUserId = nil
                }

                if case .authenticated = authState, state.hasCompletedOnboarding {
                    return .merge(
                        .send(.feed(.authStateUpdated(authState))),
                        .send(.pantry(.authStateUpdated(pantryUserId))),
                        .send(.profile(.authStateUpdated(profileAuthState))),
                        .send(.checkPendingMigration),
                        .send(.checkConsentStatus)
                    )
                }

                // Trigger onboarding after first sign-in
                if case .authenticated = authState, !state.hasCompletedOnboarding {
                    return .concatenate(
                        .send(.feed(.authStateUpdated(authState))),
                        .send(.pantry(.authStateUpdated(pantryUserId))),
                        .send(.profile(.authStateUpdated(profileAuthState))),
                        .run { send in
                            try await clock.sleep(for: .milliseconds(300))
                            await send(.presentOnboarding)
                        }
                    )
                }

                // Forward auth state to child reducers
                return .merge(
                    .send(.feed(.authStateUpdated(authState))),
                    .send(.pantry(.authStateUpdated(pantryUserId))),
                    .send(.profile(.authStateUpdated(profileAuthState)))
                )

            case let .authGateRequested(gatedAction):
                // Check cooldown - don't show gate if dismissed within 5 minutes
                if let lastDismissedAt = UserDefaults.standard.object(forKey: "lastGateDismissedAt") as? Date {
                    let fiveMinutesAgo = Date().addingTimeInterval(-5 * 60)
                    if lastDismissedAt > fiveMinutesAgo {
                        // Within cooldown period - execute action directly without showing gate
                        // IMPORTANT: Execute bookmark directly here to avoid infinite loop
                        // (re-sending toggleBookmark would trigger auth check again)
                        switch gatedAction {
                        case let .bookmark(recipeId, recipeName, imageUrl, cuisineType):
                            return .run { [guestSession] send in
                                try? await guestSession.bookmarkRecipe(recipeId, recipeName ?? "", imageUrl, cuisineType)
                                let count = await guestSession.bookmarkCount()
                                await send(.feed(.bookmarkCountLoaded(count)))
                            }

                        case let .toggleBookmark(recipeId):
                            if var detail = state.feedState.recipeDetail {
                                let wasBookmarked = detail.isBookmarked
                                detail.isBookmarked.toggle()
                                state.feedState.recipeDetail = detail
                                return .run { [guestSession] send in
                                    do {
                                        if wasBookmarked {
                                            try await guestSession.unbookmarkRecipe(recipeId)
                                        } else {
                                            try await guestSession.bookmarkRecipe(
                                                recipeId,
                                                detail.recipe?.name ?? "",
                                                detail.recipe?.imageUrl,
                                                nil
                                            )
                                        }
                                        let count = await guestSession.bookmarkCount()
                                        await send(.feed(.bookmarkCountLoaded(count)))
                                    } catch {
                                        await send(.feed(.recipeDetail(.presented(.bookmarkStatusLoaded(wasBookmarked)))))
                                    }
                                }
                            }
                            return .none

                        case let .listenToRecipe(recipeId, recipeName, artworkURL, steps):
                            return .send(.voicePlayback(.startPlayback(
                                recipeId: recipeId,
                                recipeName: recipeName,
                                artworkURL: artworkURL,
                                steps: steps
                            )))
                        }
                    }
                }

                // Store pending action and present gate
                state.pendingGatedAction = gatedAction
                state.authGate = SignInGateReducer.State()
                return .none

            case .authGate(.presented(.signInSucceeded(let user))):
                // Dismiss auth gate first
                state.authGate = nil

                // Execute pending gated action
                let pendingAction = state.pendingGatedAction
                state.pendingGatedAction = nil

                // Route through authStateChanged so onboarding check runs
                let executePending = executePendingGatedAction(pendingAction)
                return .merge(
                    .send(.authStateChanged(.authenticated(user))),
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

            case .presentOnboarding:
                guard !state.hasCompletedOnboarding else { return .none }
                state.authGate = nil  // Ensure auth gate is dismissed

                // Get displayName from authenticated user
                var firstName: String? = nil
                if case .authenticated(let user) = state.currentAuthState {
                    firstName = user.displayName.isEmpty ? nil : user.displayName
                }
                state.onboarding = OnboardingReducer.State(firstName: firstName)
                return .none

            case .onboarding(.presented(.delegate(.completed(let prefs, let city, let wantsVoiceUpload)))):
                state.hasCompletedOnboarding = true
                state.onboarding = nil

                var effects: [Effect<Action>] = [
                    .send(.persistOnboardingCompletion)
                ]

                if !prefs.isEmpty {
                    effects.append(.send(.feed(.dietaryFilterChanged(prefs))))
                }

                if let city = city {
                    effects.append(.send(.feed(.changeLocation(city))))
                } else {
                    effects.append(.send(.feed(.refreshFeed)))
                }

                // If user wants voice upload, present it after onboarding dismisses
                // Skip consent flow when voice upload is active — two sheets crash SwiftUI
                // Consent will trigger on next app launch via checkConsentStatus
                if wantsVoiceUpload {
                    effects.append(.run { send in
                        try await clock.sleep(for: .milliseconds(300))
                        await send(.voicePlayback(.showVoiceUpload))
                    })
                } else {
                    // Trigger consent flow after onboarding (only when no voice upload sheet)
                    effects.append(.send(.triggerConsentFlow))
                }

                return .concatenate(effects)

            case .onboarding(.dismiss):
                // User dismissed onboarding — save current step progress, will reappear next launch
                // Don't set hasCompletedOnboarding = true — it reappears
                return .none

            case .onboarding:
                return .none

            case .persistOnboardingCompletion:
                return .run { _ in
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    // Clean up step persistence
                    UserDefaults.standard.removeObject(forKey: "onboardingCurrentStep")
                }

            case .checkConsentStatus:
                // Check if consent flow is needed for existing users on app launch
                guard state.hasCompletedOnboarding else { return .none }
                guard case .authenticated = state.currentAuthState else { return .none }

                // Skip consent for pro subscribers (no ads = no consent needed)
                if case .pro = state.profileState.subscriptionStatus {
                    return .none
                }

                // Check ATT status
                let attStatus = consentClient.checkATTStatus()
                guard attStatus == .notDetermined else { return .none }

                state.needsConsentFlow = true
                return .send(.consent(.checkConsentOnLaunch))

            case .triggerConsentFlow:
                // Trigger consent flow after onboarding for new users
                guard case .authenticated = state.currentAuthState else { return .none }

                // Skip consent for pro subscribers
                if case .pro = state.profileState.subscriptionStatus {
                    return .none
                }

                // Check ATT status
                let attStatus = consentClient.checkATTStatus()
                guard attStatus == .notDetermined else { return .none }

                state.needsConsentFlow = true
                return .send(.consent(.checkConsentOnLaunch))

            case .consent(.consentFlowCompleted(let status)):
                state.needsConsentFlow = false
                Logger(subsystem: "com.ersinkirteke.kindred", category: "consent")
                    .info("Consent flow completed with status: \(String(describing: status))")

                // Configure ad personalization based on consent status
                adClient.configurePersonalization(status)
                return .none

            case .consent:
                // Other consent actions handled by child reducer
                return .none

            case .checkPendingMigration:
                if UserDefaults.standard.bool(forKey: "pendingMigration"),
                   case .authenticated = state.currentAuthState,
                   !state.isMigrating {
                    return .send(.startMigration)
                }
                return .none

            case .startMigration:
                state.isMigrating = true
                state.migrationRetryCount = 0

                return .run { send in
                    do {
                        let result = try await guestMigrationClient.migrateGuestData()
                        Logger.migration.notice("Migrated \(result.migratedBookmarks, privacy: .public) bookmarks, \(result.migratedSkips, privacy: .public) skips")
                        await send(.migrationSucceeded)
                    } catch {
                        Logger.migration.error("Failed: \(error.localizedDescription, privacy: .public)")
                        await send(.migrationFailed)
                    }
                }

            case .migrationSucceeded:
                state.isMigrating = false
                state.migrationRetryCount = 0
                Logger.migration.notice("Guest data migration succeeded")
                return .run { _ in
                    UserDefaults.standard.removeObject(forKey: "pendingMigration")
                }

            case .migrationFailed:
                state.isMigrating = false
                state.migrationRetryCount += 1

                // Retry with exponential backoff (2s, 4s, 8s)
                if state.migrationRetryCount <= 3 {
                    let retryCount = state.migrationRetryCount
                    let delay = pow(2.0, Double(retryCount))
                    Logger.migration.info("Retry \(retryCount, privacy: .public)/3 in \(delay, privacy: .public)s")

                    return .run { send in
                        try await clock.sleep(for: .seconds(delay))
                        await send(.retryMigration)
                    }
                } else {
                    Logger.migration.warning("Max retries exceeded - data remains local")
                    return .none
                }

            case .retryMigration:
                return .run { send in
                    do {
                        let result = try await guestMigrationClient.migrateGuestData()
                        Logger.migration.notice("Retry succeeded: \(result.migratedBookmarks, privacy: .public) bookmarks, \(result.migratedSkips, privacy: .public) skips")
                        await send(.migrationSucceeded)
                    } catch {
                        Logger.migration.error("Retry failed: \(error.localizedDescription, privacy: .public)")
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
                // Sync playback status and mini player visibility to recipe detail via actions
                // Always send (no equality guard) — TCA's @ObservableState deduplicates renders
                if state.feedState.recipeDetail != nil {
                    let isMiniPlayerVisible = state.voicePlaybackState.currentPlayback != nil
                    let status: PlaybackStatus
                    if let playback = state.voicePlaybackState.currentPlayback,
                       playback.recipeId == state.feedState.recipeDetail!.recipeId {
                        status = playback.status
                    } else if state.voicePlaybackState.isLoadingNarration,
                              let pendingId = state.voicePlaybackState.pendingRecipeId,
                              pendingId == state.feedState.recipeDetail!.recipeId {
                        status = .loading
                    } else {
                        status = .idle
                    }

                    return .merge(
                        .send(.feed(.recipeDetail(.presented(.playbackStatusUpdated(status))))),
                        .send(.feed(.recipeDetail(.presented(.miniPlayerVisibilityChanged(isMiniPlayerVisible)))))
                    )
                }
                return .none

            case .profile(.signInTapped):
                // Present auth gate from profile tab
                state.authGate = SignInGateReducer.State()
                return .none

            case .pantry(.delegate(.authGateRequested)):
                // Present auth gate from pantry tab
                state.authGate = SignInGateReducer.State()
                return .none

            case let .pantry(.delegate(.openRecipe(id: recipeId))):
                // Switch to Feed tab per locked decision
                state.selectedTab = .feed
                // Push recipe detail onto Feed navigation stack
                return .send(.feed(.openRecipeDetail(recipeId)))

            case .profile(.signOutTapped):
                return .run { send in
                    try await signInClient.signOut()
                    // Reset onboarding so it triggers again on next sign-in
                    UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                    UserDefaults.standard.removeObject(forKey: "onboardingCurrentStep")
                    UserDefaults.standard.removeObject(forKey: "guestMigrated")
                    UserDefaults.standard.removeObject(forKey: "pendingMigration")
                    await send(.authStateChanged(.guest))
                }

            case .pantry:
                return .none

            case .feed, .profile:
                return .none
            }
        }
        .ifLet(\.$authGate, action: \.authGate) {
            SignInGateReducer()
        }
        .ifLet(\.$onboarding, action: \.onboarding) {
            OnboardingReducer()
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
