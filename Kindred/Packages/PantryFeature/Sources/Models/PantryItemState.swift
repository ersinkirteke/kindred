import Foundation

/// View-layer state representation of a PantryItem for use in IdentifiedArray
public struct PantryItemState: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let quantity: String
    public let unit: String?
    public let storageLocation: StorageLocation
    public let foodCategory: FoodCategory?
    public let expiryDate: Date?
    public let notes: String?
    public let isSynced: Bool
    public let source: ItemSource

    public init(from item: PantryItem) {
        self.id = item.id
        self.name = item.name
        self.quantity = item.quantity
        self.unit = item.unit
        self.storageLocation = item.storageLocationEnum
        self.foodCategory = item.foodCategoryEnum
        self.expiryDate = item.expiryDate
        self.notes = item.notes
        self.isSynced = item.isSynced
        self.source = item.sourceEnum
    }
}
