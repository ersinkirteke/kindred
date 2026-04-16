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
    public var deleteAccount: @Sendable () async throws -> Void
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
            return nil
        case .networkError:
            return "Connection failed. Please try again."
        case .clerkError(let msg):
            return msg
        }
    }
}

// MARK: - Clerk Configuration Tracking

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

            // Attempt sign-in action
            do {
                try await action()
            } catch {
                let msg = error.localizedDescription
                let nsError = error as NSError

                // User cancelled — suppress error
                if nsError.domain.contains("AuthenticationServices") && (nsError.code == 1 || nsError.code == 1001) {
                    throw SignInError.cancelled
                }
                if msg.contains("cancel") || msg.contains("Cancel") || msg.contains("1001") {
                    throw SignInError.cancelled
                }

                // "Already signed in" — session exists, read user below
                if msg.contains("already signed in") || msg.contains("Already signed in") {
                    // Fall through to read user
                } else if msg.contains("network") || msg.contains("internet") || nsError.domain == NSURLErrorDomain {
                    throw SignInError.networkError(msg)
                } else {
                    throw SignInError.clerkError(msg)
                }
            }

            // Wait for Clerk SDK to propagate user state
            var user = Clerk.shared.user
            if user == nil {
                try? await Task.sleep(nanoseconds: 500_000_000)
                user = Clerk.shared.user
            }
            if user == nil {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                user = Clerk.shared.user
            }

            guard let user else {
                throw SignInError.clerkError("User not found after sign-in")
            }

            return ClerkUser(
                id: user.id,
                email: user.emailAddresses.first?.emailAddress ?? "",
                displayName: user.firstName ?? user.username ?? ""
            )
        }

        return SignInClient(
            signInWithApple: {
                try await performSignIn {
                    _ = try await Clerk.shared.auth.signInWithOAuth(provider: .apple)
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
            deleteAccount: {
                guard await ClerkConfigurationState.isConfigured else {
                    throw SignInError.clerkError("Account deletion is not available. Clerk is not configured.")
                }
                guard let user = await Clerk.shared.user else {
                    throw SignInError.clerkError("No authenticated user to delete.")
                }
                _ = try await user.delete()
            },
            observeAuthState: {
                // Poll for Clerk user resolution (keychain load is async)
                let authState: AuthState = await MainActor.run {
                    guard ClerkConfigurationState.isConfigured else {
                        return .guest
                    }
                    if let user = Clerk.shared.user {
                        return .authenticated(ClerkUser(
                            id: user.id,
                            email: user.emailAddresses.first?.emailAddress ?? "",
                            displayName: user.firstName ?? user.username ?? ""
                        ))
                    }
                    return .guest
                }

                // If guest, poll up to 3s for Clerk to resolve user from keychain
                if case .guest = authState {
                    return AsyncStream { continuation in
                        continuation.yield(.guest)
                        Task { @MainActor in
                            for _ in 0..<6 {
                                try? await Task.sleep(nanoseconds: 500_000_000)
                                if let user = Clerk.shared.user {
                                    continuation.yield(.authenticated(ClerkUser(
                                        id: user.id,
                                        email: user.emailAddresses.first?.emailAddress ?? "",
                                        displayName: user.firstName ?? user.username ?? ""
                                    )))
                                    continuation.finish()
                                    return
                                }
                            }
                            // Timeout — user is genuinely a guest
                            continuation.finish()
                        }
                    }
                }

                return AsyncStream { continuation in
                    continuation.yield(authState)
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
