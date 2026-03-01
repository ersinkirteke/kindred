import Foundation
import Apollo

// Re-export public APIs for easier consumption
@_exported import KindredAPI

/// NetworkClient package providing Apollo GraphQL client with offline-first SQLite cache
/// and JWT authentication via Clerk
///
/// Main components:
/// - ApolloClientFactory: Creates configured ApolloClient instances
/// - AuthInterceptor: Injects JWT tokens into GraphQL requests
/// - CachePolicy: Predefined cache policies for different use cases
///
/// Usage:
/// ```swift
/// let client = ApolloClientFactory.create { await authClient.getToken() }
/// client.fetch(query: HealthCheckQuery(), cachePolicy: .offlineFirst)
/// ```
