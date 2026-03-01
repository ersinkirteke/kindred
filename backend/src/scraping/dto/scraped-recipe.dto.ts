/**
 * Data Transfer Objects for scraped recipe content
 */

export interface RawScrapedPost {
  sourceId: string;
  platform: 'x' | 'instagram';
  text: string;
  authorHandle: string;
  location?: string;
  engagementCount: number;
  postedAt: Date;
}

export interface ParsedRecipe {
  name: string;
  description: string;
  prepTime: number; // minutes
  cookTime?: number; // minutes
  servings?: number;
  ingredients: Array<{
    name: string;
    quantity: string;
    unit: string;
  }>;
  steps: Array<{
    text: string;
    duration?: number; // seconds
    techniqueTag?: string;
  }>;
  dietaryTags: string[]; // vegan, vegetarian, gluten-free, dairy-free, keto, halal, nut-free
  calories?: number;
  protein?: number; // grams
  carbs?: number; // grams
  fat?: number; // grams
  difficulty: 'BEGINNER' | 'INTERMEDIATE' | 'ADVANCED';
  cuisineType: string; // One of CuisineType enum values
  mealType: string; // One of MealType enum values
}
