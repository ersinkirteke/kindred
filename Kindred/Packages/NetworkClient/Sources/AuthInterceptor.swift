import Apollo
import Foundation

/// HTTP interceptor that injects JWT token from Clerk into GraphQL request headers
public struct AuthInterceptor: HTTPInterceptor, Sendable {
    private let tokenProvider: @Sendable () async -> String?

    public init(tokenProvider: @escaping @Sendable () async -> String?) {
        self.tokenProvider = tokenProvider
    }

    public func intercept(
        request: URLRequest,
        next: NextHTTPInterceptorFunction
    ) async throws -> HTTPResponse {
        var request = request

        // Get fresh JWT token
        if let token = await tokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        // If no token (guest user), proceed without auth header
        // Backend allows unauthenticated queries for feed browsing

        return try await next(request)
    }
}
