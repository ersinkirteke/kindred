import Foundation

public enum FoodCategory: String, CaseIterable, Codable, Equatable, Sendable {
    case dairy
    case produce
    case meat
    case seafood
    case grains
    case baking
    case spices
    case beverages
    case snacks
    case condiments

    public var displayName: String {
        switch self {
        case .dairy: return String(localized: "pantry.category.dairy", bundle: .main)
        case .produce: return String(localized: "pantry.category.produce", bundle: .main)
        case .meat: return String(localized: "pantry.category.meat", bundle: .main)
        case .seafood: return String(localized: "pantry.category.seafood", bundle: .main)
        case .grains: return String(localized: "pantry.category.grains", bundle: .main)
        case .baking: return String(localized: "pantry.category.baking", bundle: .main)
        case .spices: return String(localized: "pantry.category.spices", bundle: .main)
        case .beverages: return String(localized: "pantry.category.beverages", bundle: .main)
        case .snacks: return String(localized: "pantry.category.snacks", bundle: .main)
        case .condiments: return String(localized: "pantry.category.condiments", bundle: .main)
        }
    }
}
