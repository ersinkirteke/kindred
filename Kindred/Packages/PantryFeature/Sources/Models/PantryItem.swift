import Foundation
import SwiftData

@Model
public class PantryItem {
    @Attribute(.unique) public var id: UUID
    public var userId: String
    public var name: String
    public var quantity: String
    public var unit: String?
    public var storageLocation: String  // Raw value of StorageLocation enum
    public var foodCategory: String?    // Raw value of FoodCategory enum
    public var normalizedName: String?
    public var photoUrl: String?
    public var notes: String?
    public var source: String           // Raw value of ItemSource enum
    public var expiryDate: Date?
    public var isDeleted: Bool
    public var isSynced: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        userId: String,
        name: String,
        quantity: String,
        unit: String? = nil,
        storageLocation: StorageLocation = .pantry,
        foodCategory: FoodCategory? = nil,
        normalizedName: String? = nil,
        photoUrl: String? = nil,
        notes: String? = nil,
        source: ItemSource = .manual,
        expiryDate: Date? = nil,
        isDeleted: Bool = false,
        isSynced: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.storageLocation = storageLocation.rawValue
        self.foodCategory = foodCategory?.rawValue
        self.normalizedName = normalizedName
        self.photoUrl = photoUrl
        self.notes = notes
        self.source = source.rawValue
        self.expiryDate = expiryDate
        self.isDeleted = isDeleted
        self.isSynced = isSynced
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Convenience computed properties for type-safe access
    public var storageLocationEnum: StorageLocation {
        StorageLocation(rawValue: storageLocation) ?? .pantry
    }

    public var foodCategoryEnum: FoodCategory? {
        foodCategory.flatMap { FoodCategory(rawValue: $0) }
    }

    public var sourceEnum: ItemSource {
        ItemSource(rawValue: source) ?? .manual
    }
}
