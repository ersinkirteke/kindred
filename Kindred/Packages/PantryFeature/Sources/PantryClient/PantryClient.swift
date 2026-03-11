import Apollo
import Dependencies
import Foundation
import NetworkClient

public struct PantryClient {
    public var addItem: @Sendable (PantryItemInput) async throws -> Void
    public var updateItem: @Sendable (UUID, PantryItemInput) async throws -> Void
    public var deleteItem: @Sendable (UUID) async throws -> Void
    public var fetchAllItems: @Sendable (String) async -> [PantryItem]
    public var fetchItemsByLocation: @Sendable (String, StorageLocation) async -> [PantryItem]
    public var itemCount: @Sendable (String) async -> Int
    public var expiringItemCount: @Sendable (String) async -> Int
    public var markAsSynced: @Sendable (UUID) async throws -> Void
    public var fetchSuggestions: @Sendable (String, String) async -> [(name: String, unit: String?, category: FoodCategory?)]
    public var checkDuplicate: @Sendable (String, String, StorageLocation) async -> Bool
    public var searchIngredientCategory: @Sendable (String) async -> FoodCategory?
}

extension PantryClient: DependencyKey {
    public static var liveValue: PantryClient {
        @Dependency(\.apolloClient) var apollo: ApolloClient

        return PantryClient(
            addItem: { @MainActor input in try await PantryStore.shared.addItem(input) },
            updateItem: { @MainActor id, input in try await PantryStore.shared.updateItem(id: id, input: input) },
            deleteItem: { @MainActor id in try await PantryStore.shared.deleteItem(id: id) },
            fetchAllItems: { @MainActor userId in await PantryStore.shared.fetchAllItems(userId: userId) },
            fetchItemsByLocation: { @MainActor userId, loc in await PantryStore.shared.fetchItemsByLocation(userId: userId, location: loc) },
            itemCount: { @MainActor userId in await PantryStore.shared.itemCount(userId: userId) },
            expiringItemCount: { @MainActor userId in await PantryStore.shared.expiringItemCount(userId: userId) },
            markAsSynced: { @MainActor id in try await PantryStore.shared.markAsSynced(id: id) },
            fetchSuggestions: { @MainActor userId, prefix in
                await PantryStore.shared.fetchDistinctItemNames(userId: userId, prefix: prefix)
            },
            checkDuplicate: { @MainActor userId, name, location in
                await PantryStore.shared.checkDuplicate(userId: userId, name: name, storageLocation: location)
            },
            searchIngredientCategory: { query in
                do {
                    let results = try await apollo.searchIngredients(query: query)
                    guard let firstResult = results.first else {
                        return nil
                    }
                    // Map GraphQL category string to FoodCategory enum
                    // defaultCategory is a non-optional String in the GraphQL schema
                    return FoodCategory(rawValue: firstResult.defaultCategory)
                } catch {
                    return nil
                }
            }
        )
    }

    public static var testValue: PantryClient {
        PantryClient(
            addItem: { _ in },
            updateItem: { _, _ in },
            deleteItem: { _ in },
            fetchAllItems: { _ in [] },
            fetchItemsByLocation: { _, _ in [] },
            itemCount: { _ in 0 },
            expiringItemCount: { _ in 0 },
            markAsSynced: { _ in },
            fetchSuggestions: { _, _ in [] },
            checkDuplicate: { _, _, _ in false },
            searchIngredientCategory: { _ in nil }
        )
    }
}

extension DependencyValues {
    public var pantryClient: PantryClient {
        get { self[PantryClient.self] }
        set { self[PantryClient.self] = newValue }
    }
}
