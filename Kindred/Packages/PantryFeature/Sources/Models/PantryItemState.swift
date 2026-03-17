import Foundation
import SwiftUI

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

public enum ExpiryStatus: Equatable, Sendable {
    case fresh      // > 3 days until expiry
    case expiring   // 1-3 days until expiry
    case expired    // past expiry date
    case none       // no expiry date set
}

extension PantryItemState {
    public var expiryStatus: ExpiryStatus {
        guard let expiry = expiryDate else { return .none }
        let daysUntilExpiry = Calendar.current.dateComponents(
            [.day], from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: expiry)
        ).day ?? 0

        if daysUntilExpiry < 0 { return .expired }
        if daysUntilExpiry <= 3 { return .expiring }
        return .fresh
    }

    public var expiryColor: Color {
        switch expiryStatus {
        case .fresh: return .green
        case .expiring: return .yellow
        case .expired: return .red
        case .none: return .clear
        }
    }
}
