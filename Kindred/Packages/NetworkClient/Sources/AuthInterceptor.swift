import Apollo
import ApolloAPI
import Foundation

/// Interceptor that injects JWT token from Clerk into GraphQL request headers
public class AuthInterceptor: ApolloInterceptor {
    public var id: String = "AuthInterceptor"

    private let tokenProvider: () async -> String?

    public init(tokenProvider: @escaping () async -> String?) {
        self.tokenProvider = tokenProvider
    }

    public func interceptAsync<Operation>(
        chain: any RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Result<GraphQLResult<Operation.Data>, any Error>) -> Void
    ) where Operation: GraphQLOperation {
        Task {
            // Get fresh JWT token
            if let token = await tokenProvider() {
                request.addHeader(name: "Authorization", value: "Bearer \(token)")
            }
            // If no token (guest user), proceed without auth header
            // Backend allows unauthenticated queries for feed browsing

            chain.proceedAsync(
                request: request,
                response: response,
                interceptor: self,
                completion: completion
            )
        }
    }
}
