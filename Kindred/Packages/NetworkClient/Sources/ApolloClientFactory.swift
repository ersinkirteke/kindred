import Apollo
import ApolloAPI
import ApolloSQLite
import Foundation

/// Factory for creating configured ApolloClient instances with SQLite cache and authentication
public final class ApolloClientFactory: Sendable {
    /// Create an ApolloClient configured with:
    /// - SQLite offline cache
    /// - Authentication interceptor for JWT injection
    ///
    /// - Parameter tokenProvider: Async closure that returns JWT token (nil if guest)
    /// - Returns: Configured ApolloClient instance
    public static func create(tokenProvider: @escaping @Sendable () async -> String?) -> ApolloClient {
        // 1. SQLite cache for offline-first data persistence
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let sqliteFileURL = documentsURL.appendingPathComponent("kindred_apollo_cache.sqlite")

        let sqliteCache = try! SQLiteNormalizedCache(fileURL: sqliteFileURL)
        let store = ApolloStore(cache: sqliteCache)

        // 2. Custom interceptor provider with auth interceptor
        let interceptorProvider = KindredInterceptorProvider(
            tokenProvider: tokenProvider
        )

        // 3. Network transport with GraphQL endpoint
        // TODO: Make URL configurable per environment (dev/staging/prod)
        let url = URL(string: "https://api.kindred.app/graphql")!
        let transport = RequestChainNetworkTransport(
            urlSession: URLSession.shared,
            interceptorProvider: interceptorProvider,
            store: store,
            endpointURL: url
        )

        return ApolloClient(networkTransport: transport, store: store)
    }
}

/// Custom interceptor provider that adds AuthInterceptor to HTTP interceptors
public struct KindredInterceptorProvider: InterceptorProvider, Sendable {
    private let tokenProvider: @Sendable () async -> String?

    public init(tokenProvider: @escaping @Sendable () async -> String?) {
        self.tokenProvider = tokenProvider
    }

    public func httpInterceptors<Operation: GraphQLOperation>(
        for operation: Operation
    ) -> [any HTTPInterceptor] {
        [
            AuthInterceptor(tokenProvider: tokenProvider),
            ResponseCodeInterceptor()
        ]
    }
}
