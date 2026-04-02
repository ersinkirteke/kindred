import Testing
@testable import PantryFeature

struct RecipeCardTests {

    // MARK: - Fixtures

    private func makeCard(
        ingredients: [RecipeIngredient] = [
            RecipeIngredient(name: "Eggs", normalizedName: "eggs"),
            RecipeIngredient(name: "Whole Milk", normalizedName: "milk"),
            RecipeIngredient(name: "Unsalted Butter", normalizedName: "butter"),
        ]
    ) -> RecipeCard {
        RecipeCard(
            id: "recipe-1",
            name: "Pancakes",
            imageUrl: "https://example.com/pancakes.jpg",
            prepTime: 15,
            ingredients: ingredients
        )
    }

    // MARK: - Model identity

    @Test("RecipeCard uses id for Identifiable conformance")
    func identifiable() {
        let card = makeCard()
        #expect(card.id == "recipe-1")
    }

    @Test("RecipeCard preserves all properties")
    func properties() {
        let card = makeCard()
        #expect(card.name == "Pancakes")
        #expect(card.imageUrl == "https://example.com/pancakes.jpg")
        #expect(card.prepTime == 15)
        #expect(card.ingredients.count == 3)
    }

    @Test("RecipeCard with nil imageUrl")
    func nilImageUrl() {
        let card = RecipeCard(id: "1", name: "Toast", imageUrl: nil, prepTime: 5, ingredients: [])
        #expect(card.imageUrl == nil)
    }

    // MARK: - Ingredient matching

    @Test("Returns nil when scanned items list is empty")
    func matchingReturnsNilForEmptyScannedItems() {
        let card = makeCard()
        #expect(card.matchingIngredientsCount(scannedItemNames: []) == nil)
    }

    @Test("Returns nil when no ingredients match")
    func matchingReturnsNilForNoMatches() {
        let card = makeCard()
        #expect(card.matchingIngredientsCount(scannedItemNames: ["flour", "sugar"]) == nil)
    }

    @Test("Matches by normalized name, case-insensitive")
    func matchesByNormalizedName() throws {
        let card = makeCard()
        let count = try #require(card.matchingIngredientsCount(scannedItemNames: ["EGGS", "Milk"]))
        #expect(count == 2, "Should match 'eggs' and 'milk' regardless of case")
    }

    @Test("Falls back to ingredient name when normalizedName is nil")
    func fallsBackToDisplayName() throws {
        let card = makeCard(ingredients: [
            RecipeIngredient(name: "Salt", normalizedName: nil),
            RecipeIngredient(name: "Pepper", normalizedName: nil),
        ])
        let count = try #require(card.matchingIngredientsCount(scannedItemNames: ["salt"]))
        #expect(count == 1)
    }

    @Test("Matches all ingredients when all are scanned")
    func matchesAllIngredients() throws {
        let card = makeCard()
        let count = try #require(card.matchingIngredientsCount(scannedItemNames: ["eggs", "milk", "butter"]))
        #expect(count == 3)
    }

    @Test(
        "Matching is case-insensitive for various casing styles",
        arguments: ["eggs", "EGGS", "Eggs", "eGgS"]
    )
    func caseInsensitiveMatching(scannedName: String) throws {
        let card = makeCard(ingredients: [
            RecipeIngredient(name: "Eggs", normalizedName: "eggs"),
        ])
        let count = try #require(card.matchingIngredientsCount(scannedItemNames: [scannedName]))
        #expect(count == 1)
    }

    @Test("Duplicate scanned names do not inflate match count")
    func duplicateScannedNames() throws {
        let card = makeCard()
        let count = try #require(card.matchingIngredientsCount(scannedItemNames: ["eggs", "eggs", "EGGS"]))
        #expect(count == 1, "Each ingredient should match at most once")
    }

    // MARK: - Accessibility label

    @Test("Accessibility label includes name and prep time")
    func accessibilityLabelBasic() {
        let card = makeCard()
        let label = card.accessibilityLabel(scannedItemNames: [])
        #expect(label == "Pancakes, 15 minutes")
    }

    @Test("Accessibility label includes matching ingredient count")
    func accessibilityLabelWithMatches() {
        let card = makeCard()
        let label = card.accessibilityLabel(scannedItemNames: ["eggs", "milk"])
        #expect(label == "Pancakes, 15 minutes, 2 of 3 ingredients available")
    }

    @Test("Accessibility label omits ingredient info when no matches")
    func accessibilityLabelNoMatches() {
        let card = makeCard()
        let label = card.accessibilityLabel(scannedItemNames: ["flour"])
        #expect(label == "Pancakes, 15 minutes")
    }
}

// MARK: - RecipeIngredient Tests

struct RecipeIngredientTests {
    @Test("Preserves name and normalizedName")
    func properties() {
        let ingredient = RecipeIngredient(name: "All-Purpose Flour", normalizedName: "flour")
        #expect(ingredient.name == "All-Purpose Flour")
        #expect(ingredient.normalizedName == "flour")
    }

    @Test("normalizedName can be nil")
    func nilNormalizedName() {
        let ingredient = RecipeIngredient(name: "Salt", normalizedName: nil)
        #expect(ingredient.normalizedName == nil)
    }
}
