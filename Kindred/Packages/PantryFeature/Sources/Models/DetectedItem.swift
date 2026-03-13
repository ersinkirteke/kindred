import Foundation

/// AI-detected pantry item from fridge or receipt scan
public struct DetectedItem: Equatable, Sendable, Identifiable {
    public let id: UUID
    public var name: String
    public var quantity: String
    public var category: FoodCategory
    public var storageLocation: StorageLocation
    public var estimatedExpiryDays: Int
    public var confidence: Int

    public init(
        id: UUID = UUID(),
        name: String,
        quantity: String,
        category: FoodCategory,
        storageLocation: StorageLocation,
        estimatedExpiryDays: Int,
        confidence: Int
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.category = category
        self.storageLocation = storageLocation
        self.estimatedExpiryDays = estimatedExpiryDays
        self.confidence = confidence
    }
}
