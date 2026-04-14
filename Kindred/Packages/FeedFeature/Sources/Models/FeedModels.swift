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
    public let popularityScore: Int?
    public let engagementLoves: Int
    public let dietaryTags: [String]
    public let difficulty: String?
    public let cuisineType: String?
    public let ingredientNames: [String]
    public var matchPercentage: Int?

    public init(
        id: String,
        name: String,
        description: String? = nil,
        prepTime: Int? = nil,
        cookTime: Int? = nil,
        calories: Int? = nil,
        imageUrl: String? = nil,
        popularityScore: Int? = nil,
        engagementLoves: Int,
        dietaryTags: [String] = [],
        difficulty: String? = nil,
        cuisineType: String? = nil,
        ingredientNames: [String] = [],
        matchPercentage: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.calories = calories
        self.imageUrl = imageUrl
        self.popularityScore = popularityScore
        self.engagementLoves = engagementLoves
        self.dietaryTags = dietaryTags
        self.difficulty = difficulty
        self.cuisineType = cuisineType
        self.ingredientNames = ingredientNames
        self.matchPercentage = matchPercentage
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

    // Map from GraphQL SearchRecipesQuery result
    public static func from(searchRecipe node: KindredAPI.SearchRecipesQuery.Data.SearchRecipes.Edge.Node) -> RecipeCard {
        return RecipeCard(
            id: node.id,
            name: node.name,
            description: node.description,
            prepTime: node.prepTime,
            cookTime: node.cookTime,
            calories: node.calories,
            imageUrl: node.imageUrl,
            popularityScore: node.popularityScore,
            engagementLoves: node.engagementLoves ?? 0,
            dietaryTags: node.dietaryTags ?? [],
            difficulty: node.difficulty?.rawValue,
            cuisineType: node.cuisineType.rawValue,
            ingredientNames: (node.ingredients ?? []).map { $0.name }
        )
    }

    // Map from GraphQL PopularRecipesQuery result
    public static func from(popularRecipe node: KindredAPI.PopularRecipesQuery.Data.PopularRecipes.Edge.Node) -> RecipeCard {
        return RecipeCard(
            id: node.id,
            name: node.name,
            description: node.description,
            prepTime: node.prepTime,
            cookTime: node.cookTime,
            calories: node.calories,
            imageUrl: node.imageUrl,
            popularityScore: node.popularityScore,
            engagementLoves: node.engagementLoves ?? 0,
            dietaryTags: node.dietaryTags ?? [],
            difficulty: node.difficulty?.rawValue,
            cuisineType: node.cuisineType.rawValue,
            ingredientNames: (node.ingredients ?? []).map { $0.name }
        )
    }

    /// Return a copy of this RecipeCard with the match percentage set
    public func withMatchPercentage(_ pct: Int?) -> RecipeCard {
        return RecipeCard(
            id: self.id,
            name: self.name,
            description: self.description,
            prepTime: self.prepTime,
            cookTime: self.cookTime,
            calories: self.calories,
            imageUrl: self.imageUrl,
            popularityScore: self.popularityScore,
            engagementLoves: self.engagementLoves,
            dietaryTags: self.dietaryTags,
            difficulty: self.difficulty,
            cuisineType: self.cuisineType,
            ingredientNames: self.ingredientNames,
            matchPercentage: pct
        )
    }
}

// MARK: - Chip to Spoonacular Parameter Mapping

// Diet chips map to Spoonacular `diets` param
private let chipToSpoonacularDiet: [String: String] = [
    "Vegan": "vegan",
    "Vegetarian": "vegetarian",
    "Keto": "ketogenic",
    "Pescatarian": "pescetarian",
    "Low-Carb": "paleo",
    "Halal": "halal",
    "Kosher": "kosher"
]

// Intolerance chips map to Spoonacular `intolerances` param
private let chipToSpoonacularIntolerance: [String: String] = [
    "Gluten-Free": "gluten",
    "Dairy-Free": "dairy",
    "Nut-Free": "tree nut"
]

public func mapChipsToSearchParams(_ chips: Set<String>) -> (diets: [String], intolerances: [String]) {
    var diets: [String] = []
    var intolerances: [String] = []
    for chip in chips {
        if let diet = chipToSpoonacularDiet[chip] { diets.append(diet) }
        else if let intolerance = chipToSpoonacularIntolerance[chip] { intolerances.append(intolerance) }
    }
    return (diets, intolerances)
}

public struct SwipedRecipe: Equatable {
    public let recipe: RecipeCard
    public let direction: SwipeDirection

    public init(recipe: RecipeCard, direction: SwipeDirection) {
        self.recipe = recipe
        self.direction = direction
    }
}
