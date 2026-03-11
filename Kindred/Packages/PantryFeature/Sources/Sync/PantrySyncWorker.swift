import Apollo
import Foundation
import KindredAPI
import NetworkClient

/// Result of a sync operation
public struct SyncResult: Equatable, Sendable {
    public let pushed: Int
    public let pulled: Int

    public init(pushed: Int, pulled: Int) {
        self.pushed = pushed
        self.pulled = pulled
    }
}

/// Handles bidirectional sync between local SwiftData and backend GraphQL API
public struct PantrySyncWorker {

    /// Perform a full sync cycle: push local changes, then pull server changes
    /// - Parameters:
    ///   - userId: User ID for filtering
    ///   - pantryClient: PantryClient for local data operations
    ///   - apolloClient: Apollo client for GraphQL mutations/queries
    /// - Returns: SyncResult with counts of pushed and pulled items
    public static func performSync(
        userId: String,
        pantryClient: PantryClient,
        apolloClient: ApolloClient
    ) async throws -> SyncResult {
        var pushCount = 0
        var pullCount = 0

        // STEP 1: Push local unsynced items to server
        let unsyncedItems = await pantryClient.fetchUnsyncedItems(userId)

        for item in unsyncedItems {
            do {
                if item.isDeleted {
                    // Push delete to server
                    _ = try await apolloClient.deletePantryItem(
                        id: item.id.uuidString,
                        userId: userId
                    )
                } else {
                    // Determine if this is a new item or an update
                    // Heuristic: if createdAt == updatedAt (within 1 second), it's new
                    let isNew = abs(item.createdAt.timeIntervalSince(item.updatedAt)) < 1.0

                    if isNew {
                        // New item - use addPantryItem
                        let input = AddPantryItemInput(
                            expiryDate: item.expiryDate.map { .some($0.ISO8601Format()) } ?? .none,
                            foodCategory: item.foodCategory.map { .some($0) } ?? .none,
                            name: item.name,
                            notes: item.notes.map { .some($0) } ?? .none,
                            quantity: item.quantity,
                            source: .some(item.source),
                            storageLocation: item.storageLocation,
                            unit: item.unit.map { .some($0) } ?? .none,
                            userId: userId
                        )
                        _ = try await apolloClient.addPantryItem(input: input)
                    } else {
                        // Updated item - use updatePantryItem
                        let input = UpdatePantryItemInput(
                            expiryDate: item.expiryDate.map { .some($0.ISO8601Format()) } ?? .none,
                            foodCategory: item.foodCategory.map { .some($0) } ?? .none,
                            name: .some(item.name),
                            notes: item.notes.map { .some($0) } ?? .none,
                            quantity: .some(item.quantity),
                            storageLocation: .some(item.storageLocation),
                            unit: item.unit.map { .some($0) } ?? .none
                        )
                        _ = try await apolloClient.updatePantryItem(
                            id: item.id.uuidString,
                            userId: userId,
                            input: input
                        )
                    }
                }

                // Mark item as synced
                try await pantryClient.markAsSynced(item.id)
                pushCount += 1
            } catch {
                // Individual item sync failure - continue with others
                print("Failed to sync item \(item.id): \(error)")
                continue
            }
        }

        // STEP 2: Pull server changes since last sync
        let lastSync = await pantryClient.lastSyncTimestamp(userId)
        let sinceTimestamp = lastSync?.ISO8601Format()

        let serverItems = try await apolloClient.fetchPantryItems(
            userId: userId,
            sinceTimestamp: sinceTimestamp
        )

        if !serverItems.isEmpty {
            // Map Apollo response to ServerPantryItem
            var mapped: [ServerPantryItem] = []

            for serverItem in serverItems {
                // Parse ID from String to UUID
                guard let itemId = UUID(uuidString: serverItem.id) else {
                    print("Invalid UUID from server: \(serverItem.id)")
                    continue
                }

                // Parse storage location
                guard let storageLocation = StorageLocation(rawValue: serverItem.storageLocation) else {
                    print("Invalid storage location from server: \(serverItem.storageLocation)")
                    continue
                }

                // Parse food category (optional)
                let foodCategory = serverItem.foodCategory.flatMap { FoodCategory(rawValue: $0) }

                // Parse source
                guard let source = ItemSource(rawValue: serverItem.source) else {
                    print("Invalid source from server: \(serverItem.source)")
                    continue
                }

                // Parse dates (DateTime is String in ISO8601 format)
                let expiryDate = serverItem.expiryDate.flatMap { dateString in
                    ISO8601DateFormatter().date(from: dateString)
                }
                guard let updatedAt = ISO8601DateFormatter().date(from: serverItem.updatedAt) else {
                    print("Invalid updatedAt from server: \(serverItem.updatedAt)")
                    continue
                }

                mapped.append(ServerPantryItem(
                    id: itemId,
                    name: serverItem.name,
                    quantity: serverItem.quantity,
                    unit: serverItem.unit,
                    storageLocation: storageLocation,
                    foodCategory: foodCategory,
                    normalizedName: serverItem.normalizedName,
                    notes: serverItem.notes,
                    source: source,
                    expiryDate: expiryDate,
                    isDeleted: serverItem.isDeleted,
                    updatedAt: updatedAt
                ))
            }

            try await pantryClient.mergeServerItems(userId, mapped)
            pullCount = mapped.count
        }

        // Update sync timestamp
        await pantryClient.updateSyncTimestamp(userId, Date())

        return SyncResult(pushed: pushCount, pulled: pullCount)
    }
}
