import Apollo
import Foundation
import KindredAPI

// MARK: - Pantry Network Operations

extension ApolloClient {

    // MARK: - Queries

    /// Fetch all pantry items for a user, optionally filtering by timestamp for sync
    /// - Parameters:
    ///   - userId: User ID to fetch items for
    ///   - sinceTimestamp: Optional ISO8601 timestamp string to fetch only items updated since
    ///   - cachePolicy: Apollo cache policy (default: .networkFirst)
    /// - Returns: Array of pantry items
    public func fetchPantryItems(
        userId: String,
        sinceTimestamp: String? = nil,
        cachePolicy: CachePolicy.Query.SingleResponse = .networkFirst
    ) async throws -> [PantryItemsQuery.Data.PantryItem] {
        let query = PantryItemsQuery(
            userId: userId,
            sinceTimestamp: sinceTimestamp.map(GraphQLNullable.some) ?? .none
        )

        let result = try await self.fetch(query: query, cachePolicy: cachePolicy)
        return result.data?.pantryItems ?? []
    }

    /// Search ingredient catalog with autocomplete
    /// - Parameters:
    ///   - query: Search query string
    ///   - lang: Language code (default: "en")
    ///   - cachePolicy: Apollo cache policy (default: .cacheFirst for fast autocomplete)
    /// - Returns: Array of matching ingredient catalog entries
    public func searchIngredients(
        query: String,
        lang: String = "en",
        cachePolicy: CachePolicy.Query.SingleResponse = .cacheFirst
    ) async throws -> [IngredientSearchQuery.Data.IngredientSearch] {
        let searchQuery = IngredientSearchQuery(query: query, lang: .some(lang))
        let result = try await self.fetch(query: searchQuery, cachePolicy: cachePolicy)
        return result.data?.ingredientSearch ?? []
    }

    // MARK: - Mutations

    /// Add a single pantry item with server-side normalization
    /// - Parameter input: Pantry item data
    /// - Returns: Created pantry item with normalized name
    public func addPantryItem(
        input: AddPantryItemInput
    ) async throws -> AddPantryItemMutation.Data.AddPantryItem {
        let mutation = AddPantryItemMutation(input: input)
        let result = try await self.perform(mutation: mutation)

        guard let addedItem = result.data?.addPantryItem else {
            throw PantryNetworkError.noData
        }

        return addedItem
    }

    /// Bulk add pantry items (typically from receipt scan)
    /// - Parameter input: Bulk pantry items data
    /// - Returns: Array of created pantry items with normalized names
    public func bulkAddPantryItems(
        input: BulkAddPantryItemsInput
    ) async throws -> [BulkAddPantryItemsMutation.Data.BulkAddPantryItem] {
        let mutation = BulkAddPantryItemsMutation(input: input)
        let result = try await self.perform(mutation: mutation)

        guard let items = result.data?.bulkAddPantryItems else {
            throw PantryNetworkError.noData
        }

        return items
    }

    /// Update an existing pantry item
    /// - Parameters:
    ///   - id: Item ID
    ///   - userId: User ID (for authorization)
    ///   - input: Updated fields
    /// - Returns: Updated pantry item
    public func updatePantryItem(
        id: String,
        userId: String,
        input: UpdatePantryItemInput
    ) async throws -> UpdatePantryItemMutation.Data.UpdatePantryItem {
        let mutation = UpdatePantryItemMutation(id: id, userId: userId, input: input)
        let result = try await self.perform(mutation: mutation)

        guard let updatedItem = result.data?.updatePantryItem else {
            throw PantryNetworkError.noData
        }

        return updatedItem
    }

    /// Soft delete a pantry item
    /// - Parameters:
    ///   - id: Item ID
    ///   - userId: User ID (for authorization)
    /// - Returns: Deleted pantry item (with isDeleted = true)
    public func deletePantryItem(
        id: String,
        userId: String
    ) async throws -> DeletePantryItemMutation.Data.DeletePantryItem {
        let mutation = DeletePantryItemMutation(id: id, userId: userId)
        let result = try await self.perform(mutation: mutation)

        guard let deletedItem = result.data?.deletePantryItem else {
            throw PantryNetworkError.noData
        }

        return deletedItem
    }
}

// MARK: - Errors

public enum PantryNetworkError: Error, LocalizedError {
    case noData

    public var errorDescription: String? {
        switch self {
        case .noData:
            return "No data returned from server"
        }
    }
}
