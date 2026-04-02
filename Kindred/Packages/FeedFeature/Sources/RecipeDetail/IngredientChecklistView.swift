import SwiftUI
import DesignSystem

// MARK: - Ingredient Checklist View

struct IngredientChecklistView: View {

    let ingredients: [RecipeIngredient]
    let checkedIngredients: Set<String>
    let ingredientMatchStatuses: [String: IngredientMatchStatus]
    let onToggle: (String) -> Void

    init(
        ingredients: [RecipeIngredient],
        checkedIngredients: Set<String>,
        ingredientMatchStatuses: [String: IngredientMatchStatus] = [:],
        onToggle: @escaping (String) -> Void
    ) {
        self.ingredients = ingredients
        self.checkedIngredients = checkedIngredients
        self.ingredientMatchStatuses = ingredientMatchStatuses
        self.onToggle = onToggle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(sortedIngredients) { ingredient in
                IngredientRow(
                    ingredient: ingredient,
                    isChecked: checkedIngredients.contains(ingredient.id),
                    matchStatus: ingredientMatchStatuses[ingredient.id],
                    onToggle: {
                        onToggle(ingredient.id)
                    }
                )
                .padding(.vertical, KindredSpacing.sm)

                if ingredient.id != sortedIngredients.last?.id {
                    Divider()
                        .background(Color.kindredDivider)
                }
            }
        }
    }

    private var sortedIngredients: [RecipeIngredient] {
        ingredients.sorted { $0.orderIndex < $1.orderIndex }
    }
}

// MARK: - Ingredient Row

private struct IngredientRow: View {

    let ingredient: RecipeIngredient
    let isChecked: Bool
    let matchStatus: IngredientMatchStatus?
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .center, spacing: KindredSpacing.md) {
                // Match status indicator (before checkbox)
                if let status = matchStatus, status != .staple {
                    matchStatusIcon(for: status)
                        .font(.system(size: 16))
                }

                // Checkbox icon
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(isChecked ? .kindredSuccess : .kindredTextSecondary)

                // Ingredient text
                Text(ingredient.formattedText)
                    .font(.kindredBody())
                    .foregroundStyle(isChecked ? .kindredTextSecondary : .kindredTextPrimary)
                    .strikethrough(isChecked, color: .kindredTextSecondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 56)  // WCAG AAA touch target
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private func matchStatusIcon(for status: IngredientMatchStatus) -> some View {
        switch status {
        case .available:
            Image(systemName: "leaf.circle.fill")
                .foregroundStyle(.kindredSuccess)
        case .missing:
            Image(systemName: "cart.circle")
                .foregroundStyle(.kindredAccent)
        case .staple:
            EmptyView()
        }
    }

    private var accessibilityLabel: String {
        var label = isChecked ? String(localized: "Uncheck \(ingredient.name)", bundle: .main) : String(localized: "Check \(ingredient.name)", bundle: .main)

        if let status = matchStatus {
            switch status {
            case .available:
                label += ", " + String(localized: "in pantry", bundle: .main)
            case .missing:
                label += ", " + String(localized: "need to buy", bundle: .main)
            case .staple:
                break
            }
        }

        return label
    }
}

// MARK: - Preview

#if DEBUG
struct IngredientChecklistView_Previews: PreviewProvider {
    static var previews: some View {
        IngredientChecklistView(
            ingredients: [
                RecipeIngredient(name: "Flour", quantity: "2", unit: "cups", orderIndex: 0),
                RecipeIngredient(name: "Sugar", quantity: "1", unit: "cup", orderIndex: 1),
                RecipeIngredient(name: "Eggs", quantity: "3", unit: nil, orderIndex: 2),
                RecipeIngredient(name: "Vanilla extract", quantity: "1", unit: "tsp", orderIndex: 3)
            ],
            checkedIngredients: ["1-Sugar"],
            onToggle: { _ in }
        )
        .padding()
        .background(Color.kindredBackground)
    }
}
#endif
