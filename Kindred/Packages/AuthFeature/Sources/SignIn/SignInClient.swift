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

// MARK: - Clerk Configuration Tracking

/// Tracks whether Clerk.configure() has been called.
/// Set to `true` from AppDelegate after calling Clerk.configure(publishableKey:).
/// Avoids accessing Clerk.shared before configuration (which triggers assertionFailure).
public enum ClerkConfigurationState {
    @MainActor public static var isConfigured = false
}

// MARK: - Dependency Registration

extension SignInClient: DependencyKey {
    public static let liveValue: SignInClient = {
        @MainActor
        func performSignIn(_ action: @Sendable () async throws -> Void) async throws -> ClerkUser {
            guard ClerkConfigurationState.isConfigured else {
                throw SignInError.clerkError("Sign-in is not available yet. Please set up your Clerk account first.")
            }

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
            } catch let error as SignInError {
                throw error
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
                guard await ClerkConfigurationState.isConfigured else {
                    throw SignInError.clerkError("Sign-out is not available. Clerk is not configured.")
                }
                try await Clerk.shared.auth.signOut()
            },
            observeAuthState: {
                AsyncStream { continuation in
                    // Start as guest; Clerk.shared is only safe after configure() with a real key
                    continuation.yield(.guest)
                    continuation.finish()
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
