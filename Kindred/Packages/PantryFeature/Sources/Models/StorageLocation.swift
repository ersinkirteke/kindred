import Foundation

public enum StorageLocation: String, CaseIterable, Codable, Equatable, Sendable {
    case fridge
    case freezer
    case pantry

    public var displayName: String {
        switch self {
        case .fridge: return String(localized: "pantry.storage.fridge", bundle: .main)
        case .freezer: return String(localized: "pantry.storage.freezer", bundle: .main)
        case .pantry: return String(localized: "pantry.storage.pantry", bundle: .main)
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
