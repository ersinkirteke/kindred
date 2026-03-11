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
        case .dairy: return "Dairy"
        case .produce: return "Produce"
        case .meat: return "Meat"
        case .seafood: return "Seafood"
        case .grains: return "Grains"
        case .baking: return "Baking"
        case .spices: return "Spices"
        case .beverages: return "Beverages"
        case .snacks: return "Snacks"
        case .condiments: return "Condiments"
        }
    }
}
