import Foundation
import KindredAPI

public enum SwipeDirection: Equatable {
    case left   // Skip
    case right  // Bookmark
}

public struct RecipeCard: Equatable, Identifiable {
    public let id: String
    public let name: String
    public let description: String?
    public let prepTime: Int?
    public let cookTime: Int?
    public let calories: Int?
    public let imageUrl: String?
    public let isViral: Bool
    public let engagementLoves: Int
    public let dietaryTags: [String]
    public let difficulty: String?
    public let cuisineType: String?
    public let velocityScore: Double

    public init(
        id: String,
        name: String,
        description: String? = nil,
        prepTime: Int? = nil,
        cookTime: Int? = nil,
        calories: Int? = nil,
        imageUrl: String? = nil,
        isViral: Bool,
        engagementLoves: Int,
        dietaryTags: [String] = [],
        difficulty: String? = nil,
        cuisineType: String? = nil,
        velocityScore: Double = 0.0
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.calories = calories
        self.imageUrl = imageUrl
        self.isViral = isViral
        self.engagementLoves = engagementLoves
        self.dietaryTags = dietaryTags
        self.difficulty = difficulty
        self.cuisineType = cuisineType
        self.velocityScore = velocityScore
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

    // Map from GraphQL ViralRecipesQuery result
    public static func from(graphQL recipe: KindredAPI.ViralRecipesQuery.Data.ViralRecipe) -> RecipeCard {
        return RecipeCard(
            id: recipe.id,
            name: recipe.name,
            description: recipe.description,
            prepTime: recipe.prepTime,
            cookTime: recipe.cookTime,
            calories: recipe.calories,
            imageUrl: recipe.imageUrl,
            isViral: recipe.isViral ?? false,
            engagementLoves: recipe.engagementLoves ?? 0,
            dietaryTags: recipe.dietaryTags ?? [],
            difficulty: recipe.difficulty.rawValue,
            cuisineType: recipe.cuisineType.rawValue
        )
    }
}

public struct SwipedRecipe: Equatable {
    public let recipe: RecipeCard
    public let direction: SwipeDirection

    public init(recipe: RecipeCard, direction: SwipeDirection) {
        self.recipe = recipe
        self.direction = direction
    }
}
