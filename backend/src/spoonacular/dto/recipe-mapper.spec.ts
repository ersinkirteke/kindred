import {
  mapSpoonacularToRecipe,
  deriveDifficulty,
  mapCuisine,
  mapMealType,
  validateRecipe,
  generatePlainText,
} from './recipe-mapper';
import * as fixtures from '../../../test/fixtures/spoonacular-responses.json';
import { DifficultyLevel } from '@prisma/client';

describe('Recipe Mapper', () => {
  describe('mapSpoonacularToRecipe', () => {
    it('should map title to name', () => {
      const recipe = fixtures.bulkRecipeResponse[0];
      const result = mapSpoonacularToRecipe(recipe);

      expect(result.name).toBe('Pasta with Garlic, Scallions, Cauliflower & Breadcrumbs');
    });

    it('should strip HTML from summary for description field', () => {
      const recipe = fixtures.htmlSummaryRecipe;
      const result = mapSpoonacularToRecipe(recipe);

      expect(result.description).not.toContain('<b>');
      expect(result.description).not.toContain('<a');
      expect(result.description).not.toContain('<i>');
      expect(result.description).toContain('Delicious');
      expect(result.description).toContain('amazing flavors');
    });

    it('should generate plainText from ingredients and steps', () => {
      const recipe = fixtures.bulkRecipeResponse[0];
      const result = mapSpoonacularToRecipe(recipe);

      expect(result.plainText).toContain('Ingredients:');
      expect(result.plainText).toContain('cauliflower');
      expect(result.plainText).toContain('Instructions:');
      expect(result.plainText).toContain('Bring a large pot of salted water to a boil');
    });

    it('should set imageUrl to Spoonacular CDN URL and imageStatus to COMPLETED', () => {
      const recipe = fixtures.bulkRecipeResponse[0];
      const result = mapSpoonacularToRecipe(recipe);

      expect(result.imageUrl).toBe('https://spoonacular.com/recipeImages/716429-556x370.jpg');
      expect(result.imageStatus).toBe('COMPLETED');
    });

    it('should map spoonacularId, sourceUrl, sourceName correctly', () => {
      const recipe = fixtures.bulkRecipeResponse[0];
      const result = mapSpoonacularToRecipe(recipe);

      expect(result.spoonacularId).toBe(716429);
      expect(result.sourceUrl).toBe('https://foodista.com/recipe/ABCD1234');
      expect(result.sourceName).toBe('Foodista');
    });

    it('should map readyInMinutes to prepTime and set cookTime to null', () => {
      const recipe = fixtures.bulkRecipeResponse[0];
      const result = mapSpoonacularToRecipe(recipe);

      expect(result.prepTime).toBe(45);
      expect(result.cookTime).toBeNull();
    });

    it('should map first cuisine to CuisineType enum with default OTHER', () => {
      const recipe = fixtures.bulkRecipeResponse[0];
      const result = mapSpoonacularToRecipe(recipe);

      expect(result.cuisineType).toBe('MEDITERRANEAN');
    });

    it('should map dishTypes to MealType with default DINNER', () => {
      const recipe = fixtures.bulkRecipeResponse[0];
      const result = mapSpoonacularToRecipe(recipe);

      // dishTypes: ['lunch', 'main course', 'dinner']
      expect(result.mealType).toBe('LUNCH'); // First matching type
    });

    it('should store diets array as dietaryTags', () => {
      const recipe = fixtures.bulkRecipeResponse[0];
      const result = mapSpoonacularToRecipe(recipe);

      expect(result.dietaryTags).toEqual(['lacto ovo vegetarian']);
    });

    it('should map aggregateLikes to popularityScore', () => {
      const recipe = fixtures.bulkRecipeResponse[0];
      const result = mapSpoonacularToRecipe(recipe);

      expect(result.popularityScore).toBe(209);
    });

    it('should map analyzedInstructions steps to RecipeStep data', () => {
      const recipe = fixtures.bulkRecipeResponse[0];
      const result = mapSpoonacularToRecipe(recipe);

      expect(result.steps).toHaveLength(3);
      expect(result.steps[0]).toEqual({
        orderIndex: 0,
        text: 'Bring a large pot of salted water to a boil.',
        duration: null,
        techniqueTag: null,
      });
      expect(result.steps[1].orderIndex).toBe(1);
      expect(result.steps[2].orderIndex).toBe(2);
    });

    it('should map extendedIngredients to Ingredient data', () => {
      const recipe = fixtures.bulkRecipeResponse[0];
      const result = mapSpoonacularToRecipe(recipe);

      expect(result.ingredients).toHaveLength(3);
      expect(result.ingredients[0]).toEqual({
        name: 'cauliflower',
        normalizedName: null,
        quantity: '2',
        unit: 'cups',
        orderIndex: 0,
      });
      expect(result.ingredients[1].name).toBe('pasta');
      expect(result.ingredients[1].quantity).toBe('8');
      expect(result.ingredients[1].unit).toBe('oz');
    });

    it('should derive difficulty: <30min & <8 steps = BEGINNER', () => {
      const recipe = fixtures.recipeWithoutImage;
      const result = mapSpoonacularToRecipe(recipe);

      // readyInMinutes: 20, steps: 1
      expect(result.difficulty).toBe('BEGINNER');
    });

    it('should derive difficulty: <60min = INTERMEDIATE', () => {
      const recipe = fixtures.bulkRecipeResponse[0];
      const result = mapSpoonacularToRecipe(recipe);

      // readyInMinutes: 45, steps: 3
      expect(result.difficulty).toBe('INTERMEDIATE');
    });

    it('should derive difficulty: >=60min = ADVANCED', () => {
      const recipe = fixtures.htmlSummaryRecipe;
      const result = mapSpoonacularToRecipe(recipe);

      // readyInMinutes: 60, steps: 2
      expect(result.difficulty).toBe('ADVANCED');
    });

    it('should extract nutrition nutrients (calories, protein, carbs, fat)', () => {
      const recipe = fixtures.bulkRecipeResponse[0];
      const result = mapSpoonacularToRecipe(recipe);

      expect(result.calories).toBe(451); // Rounded from 450.5
      expect(result.protein).toBe(15.2);
      expect(result.carbs).toBe(68.4);
      expect(result.fat).toBe(12.3);
    });

    it('should set nutrition to null if missing', () => {
      const recipe = fixtures.recipeWithoutInstructions;
      const result = mapSpoonacularToRecipe(recipe);

      expect(result.calories).toBeNull();
      expect(result.protein).toBeNull();
      expect(result.carbs).toBeNull();
      expect(result.fat).toBeNull();
    });

    it('should map servings from Spoonacular', () => {
      const recipe = fixtures.bulkRecipeResponse[0];
      const result = mapSpoonacularToRecipe(recipe);

      expect(result.servings).toBe(2);
    });
  });

  describe('validateRecipe', () => {
    it('should return false for recipes without analyzedInstructions', () => {
      const recipe = fixtures.recipeWithoutInstructions;
      const result = validateRecipe(recipe);

      expect(result).toBe(false);
    });

    it('should return false for recipes without images', () => {
      const recipe = fixtures.recipeWithoutImage;
      const result = validateRecipe(recipe);

      expect(result).toBe(false);
    });

    it('should return true for valid recipes', () => {
      const recipe = fixtures.bulkRecipeResponse[0];
      const result = validateRecipe(recipe);

      expect(result).toBe(true);
    });
  });

  describe('generatePlainText', () => {
    it('should produce clean plainText without HTML', () => {
      const recipe = fixtures.htmlSummaryRecipe;
      const plainText = generatePlainText(recipe);

      expect(plainText).not.toContain('<');
      expect(plainText).not.toContain('>');
      expect(plainText).toContain('Ingredients:');
      expect(plainText).toContain('flour');
      expect(plainText).toContain('Instructions:');
      expect(plainText).toContain('Preheat oven');
    });
  });

  describe('deriveDifficulty', () => {
    it('should return BEGINNER for <30min and <8 steps', () => {
      expect(deriveDifficulty(25, 5)).toBe(DifficultyLevel.BEGINNER);
    });

    it('should return INTERMEDIATE for <60min', () => {
      expect(deriveDifficulty(45, 10)).toBe(DifficultyLevel.INTERMEDIATE);
    });

    it('should return ADVANCED for >=60min', () => {
      expect(deriveDifficulty(90, 5)).toBe(DifficultyLevel.ADVANCED);
    });
  });

  describe('mapCuisine', () => {
    it('should map Italian to ITALIAN', () => {
      expect(mapCuisine('Italian')).toBe('ITALIAN');
    });

    it('should map mediterranean to MEDITERRANEAN', () => {
      expect(mapCuisine('mediterranean')).toBe('MEDITERRANEAN');
    });

    it('should default to OTHER for unknown cuisines', () => {
      expect(mapCuisine('Unknown')).toBe('OTHER');
      expect(mapCuisine(undefined)).toBe('OTHER');
    });
  });

  describe('mapMealType', () => {
    it('should map breakfast to BREAKFAST', () => {
      expect(mapMealType(['breakfast'])).toBe('BREAKFAST');
    });

    it('should map main course to DINNER', () => {
      expect(mapMealType(['main course'])).toBe('DINNER');
    });

    it('should map dessert to DESSERT', () => {
      expect(mapMealType(['dessert'])).toBe('DESSERT');
    });

    it('should default to DINNER for unknown types', () => {
      expect(mapMealType(['unknown'])).toBe('DINNER');
      expect(mapMealType([])).toBe('DINNER');
    });
  });
});
