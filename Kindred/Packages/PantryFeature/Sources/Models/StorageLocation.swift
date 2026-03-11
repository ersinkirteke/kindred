import Foundation

public enum StorageLocation: String, CaseIterable, Codable, Equatable, Sendable {
    case fridge
    case freezer
    case pantry

    public var displayName: String {
        switch self {
        case .fridge: return "Fridge"
        case .freezer: return "Freezer"
        case .pantry: return "Pantry"
        }
    }

    public var iconName: String {
        switch self {
        case .fridge: return "refrigerator.fill"
        case .freezer: return "snowflake"
        case .pantry: return "cabinet.fill"
        }
    }
}
