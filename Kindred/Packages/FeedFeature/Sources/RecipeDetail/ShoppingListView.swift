import SwiftUI
import ComposableArchitecture
import DesignSystem
import PantryFeature

// MARK: - Shopping List View

public struct ShoppingListView: View {

    @Bindable var store: StoreOf<ShoppingListReducer>

    @ScaledMetric(relativeTo: .title3) private var titleSize: CGFloat = 20
    @ScaledMetric(relativeTo: .headline) private var headlineSize: CGFloat = 17
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 17

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showCopiedFeedback: Bool = false

    public init(store: StoreOf<ShoppingListReducer>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Summary header
                summaryHeader
                    .padding(.horizontal, KindredSpacing.md)
                    .padding(.top, KindredSpacing.md)
                    .padding(.bottom, KindredSpacing.sm)

                Divider()
                    .background(Color.kindredDivider)

                ScrollView {
                    VStack(alignment: .leading, spacing: KindredSpacing.lg) {
                        // Grouped ingredients by category
                        ForEach(groupedIngredients, id: \.category) { group in
                            categorySection(group)
                        }

                        // Celebration section when all checked
                        if store.allChecked {
                            celebrationSection
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, KindredSpacing.md)
                    .padding(.vertical, KindredSpacing.lg)
                }

                Divider()
                    .background(Color.kindredDivider)

                // Bottom action buttons
                bottomActions
                    .padding(.horizontal, KindredSpacing.md)
                    .padding(.vertical, KindredSpacing.md)
            }
            .background(Color.kindredBackground)
            .navigationTitle(String(localized: "Shopping List", bundle: .main))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.kindredTextSecondary)
                            .font(.system(size: 24))
                    }
                    .accessibilityLabel(String(localized: "Close", bundle: .main))
                }
            }
        }
        .accessibilityLabel(String(localized: "Shopping list for \(store.recipeName)", bundle: .main))
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        Text("You have \(store.matchedCount) of \(store.totalEligible) ingredients. Missing:")
            .font(.kindredBodyScaled(size: bodySize))
            .foregroundStyle(.kindredTextSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Category Section

    private func categorySection(_ group: IngredientGroup) -> some View {
        VStack(alignment: .leading, spacing: KindredSpacing.sm) {
            // Category header
            Text(group.categoryName)
                .font(.kindredHeading2Scaled(size: headlineSize))
                .foregroundStyle(.kindredTextPrimary)
                .accessibilityAddTraits(.isHeader)

            // Items in category
            VStack(alignment: .leading, spacing: 0) {
                ForEach(group.ingredients) { ingredient in
                    ShoppingListItemRow(
                        ingredient: ingredient,
                        isChecked: store.checkedItems.contains(ingredient.id),
                        onToggle: {
                            store.send(.toggleItem(ingredient.id))
                        }
                    )
                    .padding(.vertical, KindredSpacing.sm)

                    if ingredient.id != group.ingredients.last?.id {
                        Divider()
                            .background(Color.kindredDivider)
                    }
                }
            }
        }
    }

    // MARK: - Celebration Section

    private var celebrationSection: some View {
        VStack(spacing: KindredSpacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.kindredSuccess)

            Text(String(localized: "All done!", bundle: .main))
                .font(.kindredHeading2Scaled(size: headlineSize))
                .foregroundStyle(.kindredTextPrimary)

            Button {
                dismiss()
            } label: {
                Text(String(localized: "Ready to cook? Start listening", bundle: .main))
                    .font(.kindredBodyBoldScaled(size: bodySize))
                    .foregroundStyle(.white)
                    .padding(.horizontal, KindredSpacing.lg)
                    .padding(.vertical, KindredSpacing.md)
                    .background(Color.kindredAccent)
                    .clipShape(.rect(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, KindredSpacing.lg)
        .accessibilityLabel(String(localized: "All items checked. Ready to cook.", bundle: .main))
        .animation(reduceMotion ? .none : .easeInOut, value: store.allChecked)
    }

    // MARK: - Bottom Actions

    private var bottomActions: some View {
        HStack(spacing: KindredSpacing.md) {
            // Copy button
            Button {
                copyToClipboard()
            } label: {
                HStack(spacing: KindredSpacing.sm) {
                    Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 16))
                    Text(showCopiedFeedback ? String(localized: "Copied!", bundle: .main) : String(localized: "Copy", bundle: .main))
                        .font(.kindredBodyBoldScaled(size: bodySize))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .foregroundStyle(.kindredAccent)
                .background(Color.clear)
                .clipShape(.rect(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.kindredAccent, lineWidth: 2)
                )
            }
            .accessibilityLabel(String(localized: "Copy shopping list to clipboard", bundle: .main))

            // Share button
            ShareLink(
                item: generateShoppingListText(),
                preview: SharePreview(
                    String(localized: "Shopping list for \(store.recipeName)", bundle: .main),
                    image: Image(systemName: "cart")
                )
            ) {
                HStack(spacing: KindredSpacing.sm) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                    Text(String(localized: "Share list", bundle: .main))
                        .font(.kindredBodyBoldScaled(size: bodySize))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .foregroundStyle(.white)
                .background(Color.kindredAccent)
                .clipShape(.rect(cornerRadius: 12))
            }
            .accessibilityHint(String(localized: "Share shopping list via Messages, Mail, or other apps", bundle: .main))
        }
    }

    // MARK: - Grouped Ingredients

    private var groupedIngredients: [IngredientGroup] {
        var groups: [FoodCategory: [RecipeIngredient]] = [:]

        for ingredient in store.missingIngredients {
            let category = categoryForIngredient(ingredient.name)
            groups[category, default: []].append(ingredient)
        }

        // Sort groups by category order, then create IngredientGroup objects
        return FoodCategory.allCases
            .compactMap { category in
                guard let ingredients = groups[category] else { return nil }
                return IngredientGroup(
                    category: category,
                    categoryName: category.displayName,
                    ingredients: ingredients.sorted { $0.orderIndex < $1.orderIndex }
                )
            }
    }

    // MARK: - Category Heuristic

    private func categoryForIngredient(_ name: String) -> FoodCategory {
        let lowercased = name.lowercased()

        // Dairy
        if ["milk", "cheese", "yogurt", "butter", "cream", "sour cream", "ricotta", "mozzarella", "parmesan", "cheddar"].contains(where: { lowercased.contains($0) }) {
            return .dairy
        }

        // Produce
        if ["tomato", "onion", "garlic", "lettuce", "spinach", "carrot", "potato", "bell pepper", "cucumber", "avocado", "lemon", "lime", "apple", "banana", "orange", "berry", "strawberry", "blueberry", "mushroom", "cilantro", "parsley", "basil", "thyme", "rosemary"].contains(where: { lowercased.contains($0) }) {
            return .produce
        }

        // Meat
        if ["chicken", "beef", "pork", "lamb", "turkey", "bacon", "sausage", "ham", "steak", "ground beef", "ground turkey", "ground chicken"].contains(where: { lowercased.contains($0) }) {
            return .meat
        }

        // Seafood
        if ["fish", "salmon", "tuna", "shrimp", "prawn", "crab", "lobster", "cod", "tilapia", "mackerel"].contains(where: { lowercased.contains($0) }) {
            return .seafood
        }

        // Grains
        if ["rice", "pasta", "bread", "noodle", "quinoa", "oat", "barley", "couscous", "tortilla", "pita"].contains(where: { lowercased.contains($0) }) {
            return .grains
        }

        // Baking
        if ["flour", "sugar", "baking powder", "baking soda", "yeast", "vanilla", "cocoa", "chocolate chip", "brown sugar", "powdered sugar", "cornstarch"].contains(where: { lowercased.contains($0) }) {
            return .baking
        }

        // Spices
        if ["salt", "pepper", "cumin", "paprika", "cinnamon", "nutmeg", "oregano", "cayenne", "chili powder", "turmeric", "curry", "ginger", "coriander"].contains(where: { lowercased.contains($0) }) {
            return .spices
        }

        // Condiments
        if ["sauce", "ketchup", "mustard", "mayo", "mayonnaise", "vinegar", "soy sauce", "hot sauce", "salsa", "dressing", "olive oil", "vegetable oil", "honey", "maple syrup", "jam", "jelly", "peanut butter"].contains(where: { lowercased.contains($0) }) {
            return .condiments
        }

        // Beverages
        if ["juice", "water", "coffee", "tea", "soda", "wine", "beer", "broth", "stock"].contains(where: { lowercased.contains($0) }) {
            return .beverages
        }

        // Snacks
        if ["chip", "cracker", "cookie", "candy", "chocolate", "nut", "almond", "cashew", "peanut", "walnut", "granola", "trail mix"].contains(where: { lowercased.contains($0) }) {
            return .snacks
        }

        // Default to condiments for "Other" category
        return .condiments
    }

    // MARK: - Helper Functions

    private func generateShoppingListText() -> String {
        var text = "Shopping list for \(store.recipeName):\n\n"

        for group in groupedIngredients {
            text += "\(group.categoryName):\n"
            for ingredient in group.ingredients {
                text += "- \(ingredient.formattedText)\n"
            }
            text += "\n"
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func copyToClipboard() {
        #if os(iOS)
        UIPasteboard.general.string = generateShoppingListText()
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(generateShoppingListText(), forType: .string)
        #endif

        // Show feedback
        withAnimation {
            showCopiedFeedback = true
        }

        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedFeedback = false
            }
        }
    }
}

// MARK: - Shopping List Item Row

private struct ShoppingListItemRow: View {

    let ingredient: RecipeIngredient
    let isChecked: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .center, spacing: KindredSpacing.md) {
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
        .accessibilityLabel(isChecked ? String(localized: "Uncheck \(ingredient.name)", bundle: .main) : String(localized: "Check \(ingredient.name)", bundle: .main))
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Ingredient Group

private struct IngredientGroup {
    let category: FoodCategory
    let categoryName: String
    let ingredients: [RecipeIngredient]
}

// MARK: - Preview

#if DEBUG
struct ShoppingListView_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingListView(
            store: Store(
                initialState: ShoppingListReducer.State(
                    recipeName: "Classic Pasta Carbonara",
                    missingIngredients: [
                        RecipeIngredient(name: "Spaghetti", quantity: "1", unit: "lb", orderIndex: 0),
                        RecipeIngredient(name: "Parmesan cheese", quantity: "1", unit: "cup", orderIndex: 1),
                        RecipeIngredient(name: "Eggs", quantity: "4", unit: nil, orderIndex: 2),
                        RecipeIngredient(name: "Bacon", quantity: "8", unit: "slices", orderIndex: 3),
                        RecipeIngredient(name: "Garlic", quantity: "3", unit: "cloves", orderIndex: 4)
                    ],
                    matchedCount: 4,
                    totalEligible: 9
                )
            ) {
                ShoppingListReducer()
            }
        )
    }
}
#endif
