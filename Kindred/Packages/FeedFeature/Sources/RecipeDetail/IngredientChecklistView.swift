import SwiftUI
import DesignSystem

// MARK: - Ingredient Checklist View

struct IngredientChecklistView: View {

    let ingredients: [RecipeIngredient]
    let checkedIngredients: Set<String>
    let onToggle: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(sortedIngredients) { ingredient in
                IngredientRow(
                    ingredient: ingredient,
                    isChecked: checkedIngredients.contains(ingredient.id),
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
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .center, spacing: KindredSpacing.md) {
                // Checkbox icon
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isChecked ? .kindredSuccess : .kindredTextSecondary)

                // Ingredient text
                Text(ingredient.formattedText)
                    .font(.kindredBody())
                    .foregroundColor(isChecked ? .kindredTextSecondary : .kindredTextPrimary)
                    .strikethrough(isChecked, color: .kindredTextSecondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 56)  // WCAG AAA touch target
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(isChecked ? String(localized: "Uncheck \(ingredient.name)") : String(localized: "Check \(ingredient.name)"))
        .accessibilityAddTraits(.isButton)
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
