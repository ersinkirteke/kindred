import ComposableArchitecture
import Foundation
import PantryFeature

@Reducer
public struct ShoppingListReducer {

    @ObservableState
    public struct State: Equatable, Identifiable {
        public var id: String { recipeName }
        public let recipeName: String
        public let missingIngredients: [RecipeIngredient]
        public let matchedCount: Int
        public let totalEligible: Int
        public var checkedItems: Set<String> = []  // Set of ingredient.id

        public var allChecked: Bool {
            checkedItems.count == missingIngredients.count && !missingIngredients.isEmpty
        }

        public var checkedCount: Int {
            checkedItems.count
        }

        public init(
            recipeName: String,
            missingIngredients: [RecipeIngredient],
            matchedCount: Int,
            totalEligible: Int
        ) {
            self.recipeName = recipeName
            self.missingIngredients = missingIngredients
            self.matchedCount = matchedCount
            self.totalEligible = totalEligible
        }
    }

    public enum Action: Equatable {
        case toggleItem(String)  // ingredient.id
        case shareList
        case dismiss
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .toggleItem(id):
                if state.checkedItems.contains(id) {
                    state.checkedItems.remove(id)
                } else {
                    state.checkedItems.insert(id)
                }
                return .none

            case .shareList:
                // Share handled by view layer (ShareLink)
                return .none

            case .dismiss:
                // Handled by parent via PresentationAction
                return .none
            }
        }
    }

    public init() {}
}
