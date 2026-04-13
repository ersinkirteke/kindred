import Foundation
import SwiftUI
import KindredAPI

// MARK: - Ingredient Match Status

public enum IngredientMatchStatus: Equatable {
    case available   // User has this ingredient in pantry
    case missing     // User needs to buy this
    case staple      // Common pantry staple (excluded from calculation)
}

// MARK: - Recipe Detail Models

public struct RecipeDetail: Equatable, Identifiable {
    public let id: String
    public let name: String
    public let description: String?
    public let prepTime: Int?
    public let cookTime: Int?
    public let servings: Int?
    public let calories: Int?
    public let imageUrl: String?
    public let popularityScore: Int?
    public let engagementLoves: Int
    public let dietaryTags: [String]
    public let difficulty: String?
    public let sourceUrl: String?
    public let sourceName: String?
    public let ingredients: [RecipeIngredient]
    public let steps: [RecipeStep]

    public init(
        id: String,
        name: String,
        description: String? = nil,
        prepTime: Int? = nil,
        cookTime: Int? = nil,
        servings: Int? = nil,
        calories: Int? = nil,
        imageUrl: String? = nil,
        popularityScore: Int? = nil,
        engagementLoves: Int,
        dietaryTags: [String] = [],
        difficulty: String? = nil,
        sourceUrl: String? = nil,
        sourceName: String? = nil,
        ingredients: [RecipeIngredient] = [],
        steps: [RecipeStep] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.servings = servings
        self.calories = calories
        self.imageUrl = imageUrl
        self.popularityScore = popularityScore
        self.engagementLoves = engagementLoves
        self.dietaryTags = dietaryTags
        self.difficulty = difficulty
        self.sourceUrl = sourceUrl
        self.sourceName = sourceName
        self.ingredients = ingredients
        self.steps = steps
    }

    public var totalTime: Int? {
        // If both exist, show total. Otherwise show whichever exists.
        if let prep = prepTime, let cook = cookTime {
            return prep + cook
        }
        return prepTime ?? cookTime
    }

    public var formattedLoves: String {
        // Abbreviated: 2300 → "2.3k", 15000 → "15k"
        if engagementLoves >= 1000 {
            let k = Double(engagementLoves) / 1000.0
            let formatted = String(format: "%.1fk", k)
            return formatted.replacingOccurrences(of: ".0k", with: "k")
        }
        return "\(engagementLoves)"
    }

    // Map from GraphQL RecipeDetailQuery result
    public static func from(graphQL recipe: KindredAPI.RecipeDetailQuery.Data.Recipe) -> RecipeDetail {
        return RecipeDetail(
            id: recipe.id,
            name: recipe.name,
            description: recipe.description,
            prepTime: recipe.prepTime,
            cookTime: recipe.cookTime,
            servings: recipe.servings,
            calories: recipe.calories,
            imageUrl: recipe.imageUrl,
            popularityScore: nil, // RecipeDetailQuery doesn't have popularityScore yet
            engagementLoves: recipe.engagementLoves ?? 0,
            dietaryTags: recipe.dietaryTags ?? [],
            difficulty: recipe.difficulty.rawValue,
            sourceUrl: recipe.sourceUrl,
            sourceName: recipe.sourceName,
            ingredients: recipe.ingredients.map { RecipeIngredient.from(graphQL: $0) },
            steps: recipe.steps.map { RecipeStep.from(graphQL: $0) }
        )
    }
}

public struct RecipeIngredient: Equatable, Identifiable {
    public var id: String { "\(orderIndex)-\(name)" }
    public let name: String
    public let quantity: String?
    public let unit: String?
    public let orderIndex: Int

    public init(
        name: String,
        quantity: String? = nil,
        unit: String? = nil,
        orderIndex: Int
    ) {
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.orderIndex = orderIndex
    }

    public var formattedText: String {
        var parts: [String] = []
        if let qty = quantity {
            parts.append(qty)
        }
        if let u = unit {
            parts.append(u)
        }
        parts.append(name)
        return parts.joined(separator: " ")
    }

    public static func from(graphQL ingredient: KindredAPI.RecipeDetailQuery.Data.Recipe.Ingredient) -> RecipeIngredient {
        return RecipeIngredient(
            name: ingredient.name,
            quantity: ingredient.quantity,
            unit: ingredient.unit,
            orderIndex: ingredient.orderIndex
        )
    }
}

public struct RecipeStep: Equatable, Identifiable {
    public var id: Int { orderIndex }
    public let orderIndex: Int
    public let text: String
    public let duration: Int?  // minutes
    public let techniqueTag: String?

    public init(
        orderIndex: Int,
        text: String,
        duration: Int? = nil,
        techniqueTag: String? = nil
    ) {
        self.orderIndex = orderIndex
        self.text = text
        self.duration = duration
        self.techniqueTag = techniqueTag
    }

    public static func from(graphQL step: KindredAPI.RecipeDetailQuery.Data.Recipe.Step) -> RecipeStep {
        return RecipeStep(
            orderIndex: step.orderIndex,
            text: step.text,
            duration: step.duration,
            techniqueTag: step.techniqueTag
        )
    }
}

// MARK: - Dietary Tag Colors

public extension String {
    var dietaryTagColor: Color {
        switch self.lowercased() {
        case "vegan":
            return .green
        case "vegetarian":
            return .green.opacity(0.8)
        case "keto":
            return .blue
        case "halal":
            return .purple
        case "gluten-free":
            return .orange
        case "dairy-free":
            return .cyan
        default:
            return .gray
        }
    }
}
