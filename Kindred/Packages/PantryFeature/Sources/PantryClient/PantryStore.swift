import Foundation
import SwiftData

/// Server-side pantry item representation for sync operations
public struct ServerPantryItem: Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var quantity: String
    public var unit: String?
    public var storageLocation: StorageLocation
    public var foodCategory: FoodCategory?
    public var normalizedName: String?
    public var notes: String?
    public var source: ItemSource
    public var expiryDate: Date?
    public var isDeleted: Bool
    public var updatedAt: Date

    public init(
        id: UUID,
        name: String,
        quantity: String,
        unit: String?,
        storageLocation: StorageLocation,
        foodCategory: FoodCategory?,
        normalizedName: String?,
        notes: String?,
        source: ItemSource,
        expiryDate: Date?,
        isDeleted: Bool,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.storageLocation = storageLocation
        self.foodCategory = foodCategory
        self.normalizedName = normalizedName
        self.notes = notes
        self.source = source
        self.expiryDate = expiryDate
        self.isDeleted = isDeleted
        self.updatedAt = updatedAt
    }
}

public struct PantryItemInput: Equatable, Sendable {
    public var userId: String
    public var name: String
    public var quantity: String
    public var unit: String?
    public var storageLocation: StorageLocation
    public var foodCategory: FoodCategory?
    public var normalizedName: String?
    public var notes: String?
    public var source: ItemSource
    public var expiryDate: Date?

    public init(
        userId: String,
        name: String,
        quantity: String,
        unit: String? = nil,
        storageLocation: StorageLocation = .pantry,
        foodCategory: FoodCategory? = nil,
        normalizedName: String? = nil,
        notes: String? = nil,
        source: ItemSource = .manual,
        expiryDate: Date? = nil
    ) {
        self.userId = userId
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.storageLocation = storageLocation
        self.foodCategory = foodCategory
        self.normalizedName = normalizedName
        self.notes = notes
        self.source = source
        self.expiryDate = expiryDate
    }
}

@MainActor
class PantryStore {
    static let shared = PantryStore()

    private let modelContainer: ModelContainer
    private var modelContext: ModelContext {
        modelContainer.mainContext
    }

    private init() {
        do {
            modelContainer = try ModelContainer(for: PantryItem.self)
        } catch {
            fatalError("Failed to create PantryItem ModelContainer: \(error)")
        }
    }

    func addItem(_ input: PantryItemInput) async throws {
        let item = PantryItem(
            userId: input.userId,
            name: input.name,
            quantity: input.quantity,
            unit: input.unit,
            storageLocation: input.storageLocation,
            foodCategory: input.foodCategory,
            normalizedName: input.normalizedName,
            notes: input.notes,
            source: input.source,
            expiryDate: input.expiryDate
        )
        modelContext.insert(item)
        try modelContext.save()
    }

    func updateItem(id: UUID, input: PantryItemInput) async throws {
        let descriptor = FetchDescriptor<PantryItem>(
            predicate: #Predicate<PantryItem> { item in
                item.id == id && !item.isDeleted
            }
        )
        guard let item = try modelContext.fetch(descriptor).first else { return }
        item.name = input.name
        item.quantity = input.quantity
        item.unit = input.unit
        item.storageLocation = input.storageLocation.rawValue
        item.foodCategory = input.foodCategory?.rawValue
        item.normalizedName = input.normalizedName
        item.notes = input.notes
        item.expiryDate = input.expiryDate
        item.updatedAt = Date()
        item.isSynced = false
        try modelContext.save()
    }

    func deleteItem(id: UUID) async throws {
        let descriptor = FetchDescriptor<PantryItem>(
            predicate: #Predicate<PantryItem> { item in
                item.id == id
            }
        )
        guard let item = try modelContext.fetch(descriptor).first else { return }
        item.isDeleted = true
        item.updatedAt = Date()
        item.isSynced = false
        try modelContext.save()
    }

    func fetchAllItems(userId: String) async -> [PantryItem] {
        let descriptor = FetchDescriptor<PantryItem>(
            predicate: #Predicate<PantryItem> { item in
                item.userId == userId && !item.isDeleted
            },
            sortBy: [SortDescriptor(\PantryItem.updatedAt, order: .reverse)]
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
    }

    func fetchItemsByLocation(userId: String, location: StorageLocation) async -> [PantryItem] {
        let locationRaw = location.rawValue
        let descriptor = FetchDescriptor<PantryItem>(
            predicate: #Predicate<PantryItem> { item in
                item.userId == userId && !item.isDeleted && item.storageLocation == locationRaw
            },
            sortBy: [SortDescriptor(\PantryItem.name)]
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
    }

    func itemCount(userId: String) async -> Int {
        let descriptor = FetchDescriptor<PantryItem>(
            predicate: #Predicate<PantryItem> { item in
                item.userId == userId && !item.isDeleted
            }
        )
        do {
            return try modelContext.fetch(descriptor).count
        } catch {
            return 0
        }
    }

    func expiringItemCount(userId: String) async -> Int {
        let threeDaysFromNow = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        let now = Date()
        let descriptor = FetchDescriptor<PantryItem>(
            predicate: #Predicate<PantryItem> { item in
                item.userId == userId
                    && !item.isDeleted
                    && item.expiryDate != nil
                    && item.expiryDate! <= threeDaysFromNow
                    && item.expiryDate! >= now
            }
        )
        do {
            return try modelContext.fetch(descriptor).count
        } catch {
            return 0
        }
    }

    func markAsSynced(id: UUID) async throws {
        let descriptor = FetchDescriptor<PantryItem>(
            predicate: #Predicate<PantryItem> { item in item.id == id }
        )
        guard let item = try modelContext.fetch(descriptor).first else { return }
        item.isSynced = true
        try modelContext.save()
    }

    /// Fetch distinct item names that match the given prefix for autocomplete suggestions
    /// Returns unique names with their most recent unit and category
    func fetchDistinctItemNames(userId: String, prefix: String) async -> [(name: String, unit: String?, category: FoodCategory?)] {
        let descriptor = FetchDescriptor<PantryItem>(
            predicate: #Predicate<PantryItem> { item in
                item.userId == userId && !item.isDeleted
            },
            sortBy: [SortDescriptor(\PantryItem.updatedAt, order: .reverse)]
        )

        do {
            let items = try modelContext.fetch(descriptor)
            // Filter by prefix in Swift code (SwiftData predicate doesn't support .localizedStandardContains)
            let filtered = items.filter { $0.name.localizedStandardContains(prefix) }

            // Group by unique name (case-insensitive), keep most recent entry's metadata
            var seen = Set<String>()
            var results: [(name: String, unit: String?, category: FoodCategory?)] = []

            for item in filtered {
                let lowercaseName = item.name.lowercased()
                if !seen.contains(lowercaseName) {
                    seen.insert(lowercaseName)
                    results.append((
                        name: item.name,
                        unit: item.unit,
                        category: item.foodCategoryEnum
                    ))
                }
            }

            return results
        } catch {
            return []
        }
    }

    /// Check if a duplicate item exists (same name in same storage location)
    /// Uses case-insensitive comparison
    func checkDuplicate(userId: String, name: String, storageLocation: StorageLocation) async -> Bool {
        let locationRaw = storageLocation.rawValue
        let descriptor = FetchDescriptor<PantryItem>(
            predicate: #Predicate<PantryItem> { item in
                item.userId == userId && !item.isDeleted && item.storageLocation == locationRaw
            }
        )

        do {
            let items = try modelContext.fetch(descriptor)
            let lowercaseName = name.lowercased()
            // SwiftData predicates don't support .lowercased(), so compare in Swift code
            return items.contains { $0.name.lowercased() == lowercaseName }
        } catch {
            return false
        }
    }

    // MARK: - Sync Infrastructure

    /// Fetch all unsynced items for a user (including soft-deleted items that need deletion synced to server)
    /// Returns items ordered by updatedAt ascending (oldest first)
    func fetchUnsyncedItems(userId: String) async -> [PantryItem] {
        let descriptor = FetchDescriptor<PantryItem>(
            predicate: #Predicate<PantryItem> { item in
                item.userId == userId && !item.isSynced
            },
            sortBy: [SortDescriptor(\PantryItem.updatedAt, order: .forward)]
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
    }

    /// Merge server items into local storage using last-write-wins conflict resolution
    /// - Parameters:
    ///   - userId: User ID for filtering
    ///   - serverItems: Array of server pantry items to merge
    func mergeServerItems(userId: String, serverItems: [ServerPantryItem]) async throws {
        // Fetch all local items for this user once to avoid repeated fetches
        let descriptor = FetchDescriptor<PantryItem>(
            predicate: #Predicate<PantryItem> { item in
                item.userId == userId
            }
        )
        let allLocalItems = try modelContext.fetch(descriptor)

        // Create a dictionary for quick lookup by ID
        var localItemsById = [UUID: PantryItem]()
        for item in allLocalItems {
            localItemsById[item.id] = item
        }

        for serverItem in serverItems {
            if let localItem = localItemsById[serverItem.id] {
                // Item exists locally - use last-write-wins
                if serverItem.updatedAt > localItem.updatedAt {
                    // Server is newer - update local with server data
                    localItem.name = serverItem.name
                    localItem.quantity = serverItem.quantity
                    localItem.unit = serverItem.unit
                    localItem.storageLocation = serverItem.storageLocation.rawValue
                    localItem.foodCategory = serverItem.foodCategory?.rawValue
                    localItem.normalizedName = serverItem.normalizedName
                    localItem.notes = serverItem.notes
                    localItem.source = serverItem.source.rawValue
                    localItem.expiryDate = serverItem.expiryDate
                    localItem.isDeleted = serverItem.isDeleted
                    localItem.updatedAt = serverItem.updatedAt
                    localItem.isSynced = true
                }
                // If local is newer, skip (local will push in next sync)
            } else if !serverItem.isDeleted {
                // New item from server (not deleted) - insert into local storage
                let newItem = PantryItem(
                    id: serverItem.id,
                    userId: userId,
                    name: serverItem.name,
                    quantity: serverItem.quantity,
                    unit: serverItem.unit,
                    storageLocation: serverItem.storageLocation,
                    foodCategory: serverItem.foodCategory,
                    normalizedName: serverItem.normalizedName,
                    notes: serverItem.notes,
                    source: serverItem.source,
                    expiryDate: serverItem.expiryDate,
                    isDeleted: false,
                    isSynced: true,
                    createdAt: serverItem.updatedAt,
                    updatedAt: serverItem.updatedAt
                )
                modelContext.insert(newItem)
            }
        }

        // Save all changes at once
        try modelContext.save()
    }

    /// Get the most recent updatedAt timestamp from synced items for incremental sync
    func lastSyncTimestamp(userId: String) async -> Date? {
        let descriptor = FetchDescriptor<PantryItem>(
            predicate: #Predicate<PantryItem> { item in
                item.userId == userId && item.isSynced
            },
            sortBy: [SortDescriptor(\PantryItem.updatedAt, order: .reverse)]
        )
        do {
            let items = try modelContext.fetch(descriptor)
            return items.first?.updatedAt
        } catch {
            return nil
        }
    }

    /// Update the last successful sync timestamp in UserDefaults
    func updateSyncTimestamp(userId: String, timestamp: Date) async {
        UserDefaults.standard.set(timestamp, forKey: "pantry.lastSync.\(userId)")
    }
}
