import Foundation
import Dependencies
import DependenciesMacros
import AuthClient
import ClerkKit

/// TCA dependency client for sign-in operations
@DependencyClient
public struct SignInClient: Sendable {
    public var signInWithApple: @Sendable () async throws -> ClerkUser
    public var signInWithGoogle: @Sendable () async throws -> ClerkUser
    public var signOut: @Sendable () async throws -> Void
    public var observeAuthState: @Sendable () async -> AsyncStream<AuthState> = { AsyncStream { $0.finish() } }
}

/// Sign-in specific errors
public enum SignInError: Error, LocalizedError {
    case cancelled
    case networkError(String)
    case clerkError(String)

    public var errorDescription: String? {
        switch self {
        case .cancelled:
            return nil  // Don't show error for user cancellation
        case .networkError:
            return "Connection failed. Please try again."
        case .clerkError(let msg):
            return msg
        }
    }
}

// MARK: - Dependency Registration

extension SignInClient: DependencyKey {
    public static let liveValue: SignInClient = {
        @MainActor
        func performSignIn(_ action: @Sendable () async throws -> Void) async throws -> ClerkUser {
            do {
                try await action()

                // Read user from Clerk SDK after successful sign-in
                guard let user = Clerk.shared.user else {
                    throw SignInError.clerkError("User not found after sign-in")
                }

                return ClerkUser(
                    id: user.id,
                    email: user.emailAddresses.first?.emailAddress ?? "",
                    displayName: user.firstName ?? user.username ?? ""
                )
            } catch {
                // Map Clerk errors to SignInError
                let errorMessage = error.localizedDescription

                // Check for cancellation patterns
                if errorMessage.contains("cancel") || errorMessage.contains("Cancel") {
                    throw SignInError.cancelled
                }

                // Check for network errors
                if errorMessage.contains("network") || errorMessage.contains("internet") {
                    throw SignInError.networkError(errorMessage)
                }

                throw SignInError.clerkError(errorMessage)
            }
        }

        return SignInClient(
            signInWithApple: {
                try await performSignIn {
                    _ = try await Clerk.shared.auth.signInWithApple()
                }
            },
            signInWithGoogle: {
                try await performSignIn {
                    _ = try await Clerk.shared.auth.signInWithOAuth(provider: .google)
                }
            },
            signOut: {
                try await Clerk.shared.auth.signOut()
            },
            observeAuthState: {
                AsyncStream { continuation in
                    @MainActor
                    func checkAuthState() -> AuthState {
                        if let user = Clerk.shared.user {
                            return .authenticated(ClerkUser(
                                id: user.id,
                                email: user.emailAddresses.first?.emailAddress ?? "",
                                displayName: user.firstName ?? user.username ?? ""
                            ))
                        }
                        return .guest
                    }

                    Task { @MainActor in
                        // Yield initial state immediately
                        continuation.yield(checkAuthState())

                        // Note: Clerk SDK doesn't have a native observer API
                        // In a real app, you'd set up NotificationCenter observers
                        // or poll Clerk.shared.session changes
                        // For now, this yields the initial state

                        continuation.finish()
                    }
                }
            }
        )
    }()

    public static let testValue = SignInClient()
}

extension DependencyValues {
    public var signInClient: SignInClient {
        get { self[SignInClient.self] }
        set { self[SignInClient.self] = newValue }
    }
}
