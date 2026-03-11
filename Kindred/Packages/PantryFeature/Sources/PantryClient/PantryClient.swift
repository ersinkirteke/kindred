import Dependencies
import Foundation

public struct PantryClient {
    public var addItem: @Sendable (PantryItemInput) async throws -> Void
    public var updateItem: @Sendable (UUID, PantryItemInput) async throws -> Void
    public var deleteItem: @Sendable (UUID) async throws -> Void
    public var fetchAllItems: @Sendable (String) async -> [PantryItem]
    public var fetchItemsByLocation: @Sendable (String, StorageLocation) async -> [PantryItem]
    public var itemCount: @Sendable (String) async -> Int
    public var expiringItemCount: @Sendable (String) async -> Int
    public var markAsSynced: @Sendable (UUID) async throws -> Void
}

extension PantryClient: DependencyKey {
    public static var liveValue: PantryClient {
        let store = PantryStore.shared
        return PantryClient(
            addItem: { input in try await store.addItem(input) },
            updateItem: { id, input in try await store.updateItem(id: id, input: input) },
            deleteItem: { id in try await store.deleteItem(id: id) },
            fetchAllItems: { userId in await store.fetchAllItems(userId: userId) },
            fetchItemsByLocation: { userId, loc in await store.fetchItemsByLocation(userId: userId, location: loc) },
            itemCount: { userId in await store.itemCount(userId: userId) },
            expiringItemCount: { userId in await store.expiringItemCount(userId: userId) },
            markAsSynced: { id in try await store.markAsSynced(id: id) }
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
            markAsSynced: { _ in }
        )
    }
}

extension DependencyValues {
    public var pantryClient: PantryClient {
        get { self[PantryClient.self] }
        set { self[PantryClient.self] = newValue }
    }
}
