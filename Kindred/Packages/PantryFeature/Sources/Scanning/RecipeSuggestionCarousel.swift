import DesignSystem
import SwiftUI

/// Recipe suggestion carousel shown after scanning items
public struct RecipeSuggestionCarousel: View {
    let recipes: [RecipeCard]
    let scannedItemNames: [String]
    let onDismiss: () -> Void
    let onRecipeTapped: (String) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        recipes: [RecipeCard],
        scannedItemNames: [String],
        onDismiss: @escaping () -> Void,
        onRecipeTapped: @escaping (String) -> Void
    ) {
        self.recipes = recipes
        self.scannedItemNames = scannedItemNames
        self.onDismiss = onDismiss
        self.onRecipeTapped = onRecipeTapped
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.accentColor)
                    Text(String(localized: "scan.suggestions.title", bundle: .main))
                        .font(.title2.bold())
                }

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel(String(localized: "common.close", defaultValue: "Close", bundle: .main))
            }
            .padding(.horizontal)

            // Recipe carousel or empty state
            if recipes.isEmpty {
                emptyState
            } else {
                recipeScrollView
            }
        }
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16))
        .shadow(radius: 8, y: -2)
    }

    @ViewBuilder
    private var recipeScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(recipes) { recipe in
                    Button {
                        onRecipeTapped(recipe.id)
                    } label: {
                        RecipeCardView(
                            recipe: recipe,
                            scannedItemNames: scannedItemNames
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text(String(localized: "scan.suggestions.no_matches", bundle: .main))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

/// Individual recipe card in the carousel
private struct RecipeCardView: View {
    let recipe: RecipeCard
    let scannedItemNames: [String]

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Recipe image
            AsyncImage(url: URL(string: recipe.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.tertiary)
                    }
            }
            .frame(width: 260, height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Recipe info
            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.name)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("\(recipe.prepTime) min")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)

                // Ingredients available indicator
                if let availableCount = matchingIngredientsCount {
                    Text(String(
                        format: String(localized: "scan.suggestions.ingredients_available", bundle: .main),
                        availableCount,
                        recipe.ingredients.count
                    ))
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
                }
            }
        }
        .frame(width: 260)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 16))
        .shadow(radius: 2, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var matchingIngredientsCount: Int? {
        recipe.matchingIngredientsCount(scannedItemNames: scannedItemNames)
    }

    private var accessibilityLabel: String {
        recipe.accessibilityLabel(scannedItemNames: scannedItemNames)
    }
}

// Placeholder recipe card model (will be replaced with actual RecipeCard from API)
public struct RecipeCard: Equatable, Identifiable {
    public let id: String
    public let name: String
    public let imageUrl: String?
    public let prepTime: Int
    public let ingredients: [RecipeIngredient]

    public init(id: String, name: String, imageUrl: String?, prepTime: Int, ingredients: [RecipeIngredient]) {
        self.id = id
        self.name = name
        self.imageUrl = imageUrl
        self.prepTime = prepTime
        self.ingredients = ingredients
    }

    public func matchingIngredientsCount(scannedItemNames: [String]) -> Int? {
        guard !scannedItemNames.isEmpty else { return nil }

        let normalizedScannedNames = Set(scannedItemNames.map { $0.lowercased() })
        let matchingCount = ingredients.filter { ingredient in
            normalizedScannedNames.contains(ingredient.normalizedName?.lowercased() ?? ingredient.name.lowercased())
        }.count

        return matchingCount > 0 ? matchingCount : nil
    }

    public func accessibilityLabel(scannedItemNames: [String]) -> String {
        var label = name
        label += ", \(prepTime) minutes"
        if let count = matchingIngredientsCount(scannedItemNames: scannedItemNames) {
            label += ", \(count) of \(ingredients.count) ingredients available"
        }
        return label
    }
}

public struct RecipeIngredient: Equatable {
    public let name: String
    public let normalizedName: String?

    public init(name: String, normalizedName: String?) {
        self.name = name
        self.normalizedName = normalizedName
    }
}
