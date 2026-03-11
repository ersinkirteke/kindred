import Foundation
import SwiftData

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
}
