// Spoonacular API response types

export interface SpoonacularSearchResult {
  id: number;
  title: string;
  image: string;
  imageType: string;
}

export interface SpoonacularSearchResponse {
  results: SpoonacularSearchResult[];
  offset: number;
  number: number;
  totalResults: number;
}

export interface SpoonacularNutrient {
  name: string;
  amount: number;
  unit: string;
}

export interface SpoonacularNutrition {
  nutrients: SpoonacularNutrient[];
}

export interface SpoonacularIngredient {
  id: number;
  name: string;
  amount: number;
  unit: string;
  original: string;
}

export interface SpoonacularStep {
  number: number;
  step: string;
  ingredients?: any[];
  equipment?: any[];
}

export interface SpoonacularInstruction {
  name: string;
  steps: SpoonacularStep[];
}

export interface SpoonacularRecipe {
  id: number;
  title: string;
  image: string | null;
  imageType?: string;
  servings: number;
  readyInMinutes: number;
  sourceUrl: string;
  sourceName: string;
  summary: string;
  cuisines: string[];
  dishTypes: string[];
  diets: string[];
  aggregateLikes: number;
  analyzedInstructions: SpoonacularInstruction[];
  extendedIngredients: SpoonacularIngredient[];
  nutrition: SpoonacularNutrition;
}

export interface SearchFilters {
  query?: string;
  cuisines?: string[];
  diets?: string[];
  intolerances?: string[];
}
