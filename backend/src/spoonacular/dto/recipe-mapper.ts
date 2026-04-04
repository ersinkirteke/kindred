import { SpoonacularRecipe } from './spoonacular-recipe.dto';
import { DifficultyLevel, CuisineType, MealType, ImageStatus } from '@prisma/client';
import * as striptags from 'striptags';

export function mapSpoonacularToRecipe(spoon: SpoonacularRecipe): any {
  const stepCount = spoon.analyzedInstructions[0]?.steps?.length || 0;

  return {
    name: spoon.title,
    description: striptags(spoon.summary),
    prepTime: spoon.readyInMinutes,
    cookTime: null,
    servings: spoon.servings || null,
    calories: extractNutrient(spoon, 'Calories'),
    protein: extractNutrient(spoon, 'Protein'),
    carbs: extractNutrient(spoon, 'Carbohydrates'),
    fat: extractNutrient(spoon, 'Fat'),
    difficulty: deriveDifficulty(spoon.readyInMinutes, stepCount),
    dietaryTags: spoon.diets || [],
    cuisineType: mapCuisine(spoon.cuisines[0]),
    mealType: mapMealType(spoon.dishTypes),
    imageUrl: spoon.image,
    imageStatus: ImageStatus.COMPLETED,
    scrapedFrom: 'spoonacular',
    sourceId: null,
    location: null,
    latitude: null,
    longitude: null,
    spoonacularId: spoon.id,
    popularityScore: spoon.aggregateLikes,
    sourceUrl: spoon.sourceUrl,
    sourceName: spoon.sourceName,
    plainText: generatePlainText(spoon),
    ingredients: spoon.extendedIngredients.map((ing, index) => ({
      name: ing.name,
      normalizedName: null,
      quantity: ing.amount.toString(),
      unit: ing.unit,
      orderIndex: index,
    })),
    steps: (spoon.analyzedInstructions[0]?.steps || []).map((step, index) => ({
      orderIndex: index,
      text: step.step,
      duration: null,
      techniqueTag: null,
    })),
  };
}

export function deriveDifficulty(readyInMinutes: number, stepCount: number): DifficultyLevel {
  if (readyInMinutes < 30 && stepCount < 8) {
    return DifficultyLevel.BEGINNER;
  } else if (readyInMinutes < 60) {
    return DifficultyLevel.INTERMEDIATE;
  } else {
    return DifficultyLevel.ADVANCED;
  }
}

export function mapCuisine(cuisine: string | undefined): CuisineType {
  if (!cuisine) return CuisineType.OTHER;

  const normalized = cuisine.toLowerCase().replace(/\s+/g, '_');

  const mapping: Record<string, CuisineType> = {
    italian: CuisineType.ITALIAN,
    mexican: CuisineType.MEXICAN,
    chinese: CuisineType.CHINESE,
    japanese: CuisineType.JAPANESE,
    sichuan: CuisineType.SICHUAN,
    cantonese: CuisineType.CANTONESE,
    indian: CuisineType.INDIAN,
    thai: CuisineType.THAI,
    korean: CuisineType.KOREAN,
    vietnamese: CuisineType.VIETNAMESE,
    mediterranean: CuisineType.MEDITERRANEAN,
    french: CuisineType.FRENCH,
    spanish: CuisineType.SPANISH,
    greek: CuisineType.GREEK,
    middle_eastern: CuisineType.MIDDLE_EASTERN,
    'middle eastern': CuisineType.MIDDLE_EASTERN,
    lebanese: CuisineType.LEBANESE,
    turkish: CuisineType.TURKISH,
    moroccan: CuisineType.MOROCCAN,
    ethiopian: CuisineType.ETHIOPIAN,
    american: CuisineType.AMERICAN,
    southern: CuisineType.SOUTHERN,
    tex_mex: CuisineType.TEX_MEX,
    'tex-mex': CuisineType.TEX_MEX,
    brazilian: CuisineType.BRAZILIAN,
    peruvian: CuisineType.PERUVIAN,
    caribbean: CuisineType.CARIBBEAN,
    british: CuisineType.BRITISH,
    german: CuisineType.GERMAN,
    fusion: CuisineType.FUSION,
  };

  return mapping[normalized] || CuisineType.OTHER;
}

export function mapMealType(dishTypes: string[]): MealType {
  if (!dishTypes || dishTypes.length === 0) {
    return MealType.DINNER;
  }

  // Check each dish type in order
  for (const type of dishTypes) {
    const normalized = type.toLowerCase();

    if (normalized === 'breakfast') return MealType.BREAKFAST;
    if (normalized === 'lunch') return MealType.LUNCH;
    if (normalized === 'dinner' || normalized === 'main course') return MealType.DINNER;
    if (normalized === 'dessert') return MealType.DESSERT;
    if (normalized === 'appetizer' || normalized === 'starter') return MealType.APPETIZER;
    if (normalized === 'snack') return MealType.SNACK;
    if (normalized === 'drink' || normalized === 'beverage') return MealType.DRINK;
  }

  return MealType.DINNER;
}

export function validateRecipe(spoon: SpoonacularRecipe): boolean {
  // Must have instructions
  if (!spoon.analyzedInstructions || spoon.analyzedInstructions.length === 0) {
    return false;
  }

  if (!spoon.analyzedInstructions[0]?.steps || spoon.analyzedInstructions[0].steps.length === 0) {
    return false;
  }

  // Must have image
  if (!spoon.image) {
    return false;
  }

  return true;
}

export function generatePlainText(spoon: SpoonacularRecipe): string {
  const parts: string[] = [];

  // Add ingredients
  parts.push('Ingredients:');
  for (const ing of spoon.extendedIngredients) {
    parts.push(`${ing.amount} ${ing.unit} ${ing.name}.`);
  }

  // Add instructions
  parts.push('Instructions:');
  if (spoon.analyzedInstructions[0]?.steps) {
    for (const step of spoon.analyzedInstructions[0].steps) {
      parts.push(`${step.step}.`);
    }
  }

  return parts.join(' ');
}

function extractNutrient(spoon: SpoonacularRecipe, name: string): number | null {
  if (!spoon.nutrition?.nutrients) {
    return null;
  }

  const nutrient = spoon.nutrition.nutrients.find((n) => n.name === name);
  if (!nutrient) {
    return null;
  }

  // Round calories to integer, keep others as-is
  if (name === 'Calories') {
    return Math.round(nutrient.amount);
  }

  return nutrient.amount;
}
