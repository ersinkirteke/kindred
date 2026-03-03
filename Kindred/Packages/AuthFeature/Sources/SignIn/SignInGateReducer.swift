import Foundation
import ComposableArchitecture
import AuthClient

/// TCA reducer for the sign-in gate lifecycle
@Reducer
public struct SignInGateReducer {
    @ObservableState
    public struct State: Equatable {
        public var isSigningIn = false
        public var signInError: String?
        public var deferredActionId: String?  // Opaque ID for the action to execute after sign-in

        public init(deferredActionId: String? = nil) {
            self.deferredActionId = deferredActionId
        }
    }

    public enum Action: Equatable {
        case appleSignInTapped
        case googleSignInTapped
        case signInSucceeded(ClerkUser)
        case signInFailed(String)
        case dismissed  // User tapped skip or swiped down
        case continueAsGuestTapped
    }

    @Dependency(\.signInClient) var signInClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .appleSignInTapped:
                state.isSigningIn = true
                state.signInError = nil

                return .run { send in
                    do {
                        let user = try await signInClient.signInWithApple()
                        await send(.signInSucceeded(user))
                    } catch let error as SignInError {
                        if case .cancelled = error {
                            // User cancelled - just stop loading, don't show error
                            await send(.signInFailed(""))
                        } else {
                            await send(.signInFailed(error.localizedDescription ?? "Sign in failed"))
                        }
                    } catch {
                        await send(.signInFailed(error.localizedDescription))
                    }
                }

            case .googleSignInTapped:
                state.isSigningIn = true
                state.signInError = nil

                return .run { send in
                    do {
                        let user = try await signInClient.signInWithGoogle()
                        await send(.signInSucceeded(user))
                    } catch let error as SignInError {
                        if case .cancelled = error {
                            // User cancelled - just stop loading, don't show error
                            await send(.signInFailed(""))
                        } else {
                            await send(.signInFailed(error.localizedDescription ?? "Sign in failed"))
                        }
                    } catch {
                        await send(.signInFailed(error.localizedDescription))
                    }
                }

            case .signInSucceeded:
                state.isSigningIn = false
                // Parent reducer handles the rest (auto-complete deferred action, persist cooldown)
                return .none

            case .signInFailed(let message):
                state.isSigningIn = false
                // Only set error if not empty (cancelled case sends empty string)
                if !message.isEmpty {
                    state.signInError = message
                }
                return .none

            case .dismissed, .continueAsGuestTapped:
                // No state change. Parent reducer handles dismissal and cooldown timestamp persistence
                return .none
            }
        }
    }
}
