import Foundation
import PantryFeature

public struct IngredientMatcher {
    // Common qualifiers to strip from ingredient names before matching
    static let commonQualifiers = [
        "fresh", "large", "small", "medium", "organic", "free-range",
        "whole", "chopped", "diced", "sliced", "minced", "crushed",
        "ground", "dried", "frozen", "canned", "raw", "cooked",
        "boneless", "skinless", "extra-virgin", "unsalted", "salted",
        "light", "heavy", "thick", "thin"
    ]

    // Pantry staples excluded from match calculation (inflates scores)
    static let commonStaples = [
        "salt", "pepper", "black pepper", "water", "cooking oil",
        "olive oil", "vegetable oil", "canola oil", "sesame oil",
        "butter", "sugar", "flour", "garlic", "onion"
    ]

    /// Normalize an ingredient name for matching:
    /// lowercase, trim whitespace, strip common qualifiers, simple plural handling
    public static func normalize(_ name: String) -> String {
        var normalized = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        // Strip common qualifiers (word boundary: "fresh basil" -> "basil", not "refresh")
        for qualifier in commonQualifiers {
            normalized = normalized.replacingOccurrences(of: qualifier + " ", with: "")
        }
        normalized = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
        // Simple plural stripping: remove trailing "s" if length > 3 (avoids "egg" from "eggs", but not "s" from "s")
        if normalized.count > 3 && normalized.hasSuffix("s") && !normalized.hasSuffix("ss") {
            normalized = String(normalized.dropLast())
        }
        return normalized
    }

    /// Check if an ingredient name is a common pantry staple
    public static func isStaple(_ name: String) -> Bool {
        let normalized = normalize(name)
        return commonStaples.contains(normalized)
    }

    /// Compute match percentage between recipe ingredients and pantry items.
    /// Excludes staples and expired/deleted pantry items.
    /// Returns 0-100 integer, or nil if no eligible ingredients.
    public static func computeMatchPercentage(
        recipeIngredientNames: [String],
        pantryItems: [PantryItem]
    ) -> Int? {
        // Filter out staples from recipe ingredients
        let eligibleIngredients = recipeIngredientNames.filter { !isStaple($0) }
        guard !eligibleIngredients.isEmpty else { return nil }

        // Filter pantry: non-deleted, non-expired items only
        let validPantryItems = pantryItems.filter { item in
            !item.isDeleted && (item.expiryDate == nil || item.expiryDate! > Date())
        }

        // Build set of normalized pantry names
        let pantryNormalizedNames = Set(validPantryItems.map { item in
            item.normalizedName.map { normalize($0) } ?? normalize(item.name)
        })

        // Count matches
        let matchedCount = eligibleIngredients.filter { ingredientName in
            let normalizedIngredient = normalize(ingredientName)
            return pantryNormalizedNames.contains(normalizedIngredient)
        }.count

        return Int((Double(matchedCount) / Double(eligibleIngredients.count)) * 100)
    }
}
