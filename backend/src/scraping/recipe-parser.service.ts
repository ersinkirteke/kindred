import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { ParsedRecipe } from './dto/scraped-recipe.dto';

/**
 * AI-powered recipe parser using Gemini
 * Extracts structured recipe data from social media post text
 */
@Injectable()
export class RecipeParserService {
  private readonly logger = new Logger(RecipeParserService.name);
  private readonly genAI: GoogleGenerativeAI | null;
  private readonly model: any;

  constructor(private readonly configService: ConfigService) {
    const apiKey = this.configService.get<string>('GOOGLE_AI_API_KEY');

    if (!apiKey) {
      this.logger.warn(
        'GOOGLE_AI_API_KEY not configured - recipe parsing will be unavailable',
      );
      this.genAI = null;
      this.model = null;
    } else {
      this.genAI = new GoogleGenerativeAI(apiKey);
      // Use Gemini 2.0 Flash for fast, cost-effective parsing
      this.model = this.genAI.getGenerativeModel({
        model: 'gemini-2.0-flash-exp',
        generationConfig: {
          temperature: 0.1, // Low temperature for precise extraction
          responseMimeType: 'application/json',
        },
      });
    }
  }

  /**
   * Parse recipe details from raw social media text
   * Returns null if text is not a recipe or parsing fails
   */
  async parseRecipeFromText(rawText: string): Promise<ParsedRecipe | null> {
    if (!this.model) {
      this.logger.warn('Recipe parser not initialized - returning null');
      return null;
    }

    try {
      const prompt = `Extract recipe details from this social media post. Return JSON with the following structure:

{
  "name": "Recipe name (string, required)",
  "description": "Brief description (string, required)",
  "prepTime": "Preparation time in minutes (number, required)",
  "cookTime": "Cooking time in minutes (number, optional)",
  "servings": "Number of servings (number, optional)",
  "ingredients": [
    {
      "name": "Ingredient name (string, required)",
      "quantity": "Quantity as string (required, e.g., '2', '1/2', '1.5')",
      "unit": "Unit of measurement (required, e.g., 'cup', 'tbsp', 'g', 'whole')"
    }
  ],
  "steps": [
    {
      "text": "Step instruction (string, required)",
      "duration": "Duration in seconds (number, optional)",
      "techniqueTag": "Cooking technique (optional, e.g., 'sauté', 'bake', 'simmer')"
    }
  ],
  "dietaryTags": ["Array of dietary tags detected from ingredients. Possible values: vegan, vegetarian, gluten-free, dairy-free, keto, halal, nut-free"],
  "calories": "Estimated calories per serving (number, optional)",
  "protein": "Estimated protein in grams per serving (number, optional)",
  "carbs": "Estimated carbs in grams per serving (number, optional)",
  "fat": "Estimated fat in grams per serving (number, optional)",
  "difficulty": "Difficulty level based on techniques and ingredient count (string, required: BEGINNER, INTERMEDIATE, or ADVANCED)",
  "cuisineType": "Primary cuisine category (string, required - choose ONE from: Italian, Mexican, Chinese, Japanese, Sichuan, Cantonese, Indian, Thai, Korean, Vietnamese, Mediterranean, French, Spanish, Greek, Middle Eastern, Lebanese, Turkish, Moroccan, Ethiopian, American, Southern, Tex-Mex, Brazilian, Peruvian, Caribbean, British, German, Fusion, Other)",
  "mealType": "Meal category (string, required - choose ONE from: Breakfast, Lunch, Dinner, Snack, Dessert, Appetizer, Drink)"
}

Requirements:
- If the text is NOT a recipe, return {"isRecipe": false}
- Must have at least 1 ingredient and 1 step to be valid
- Estimate nutritional values based on common ingredient data
- Detect dietary tags from ingredients (e.g., no meat = vegetarian, no animal products = vegan)
- Difficulty: BEGINNER (≤5 ingredients, basic techniques), INTERMEDIATE (6-10 ingredients, moderate techniques), ADVANCED (>10 ingredients or complex techniques)
- If servings not specified, estimate based on ingredient quantities
- cuisineType MUST be one of the listed categories (case-sensitive)
- If cuisine doesn't fit listed categories, use "Fusion" for mixed cuisines or "Other"
- mealType MUST be one of the listed categories
- For ambiguous dishes, prioritize traditional cuisine origin (e.g., tacos = "Mexican" not "Tex-Mex")
- Base meal type on when the dish is traditionally served

Post text:
${rawText}`;

      const result = await this.model.generateContent(prompt);
      const response = result.response;
      const text = response.text();

      // Parse JSON response
      const parsed = JSON.parse(text);

      // Check if it's actually a recipe
      if (parsed.isRecipe === false) {
        this.logger.log('Text identified as non-recipe content');
        return null;
      }

      // Validate required fields
      if (
        !parsed.name ||
        !parsed.description ||
        !parsed.prepTime ||
        !parsed.ingredients ||
        parsed.ingredients.length === 0 ||
        !parsed.steps ||
        parsed.steps.length === 0 ||
        !parsed.difficulty ||
        !parsed.cuisineType ||
        !parsed.mealType
      ) {
        this.logger.warn('Parsed recipe missing required fields');
        return null;
      }

      // Validate difficulty enum
      if (
        !['BEGINNER', 'INTERMEDIATE', 'ADVANCED'].includes(parsed.difficulty)
      ) {
        this.logger.warn(
          `Invalid difficulty level: ${parsed.difficulty}, defaulting to INTERMEDIATE`,
        );
        parsed.difficulty = 'INTERMEDIATE';
      }

      // Ensure dietaryTags is an array
      if (!Array.isArray(parsed.dietaryTags)) {
        parsed.dietaryTags = [];
      }

      // Map cuisineType to Prisma enum format
      const cuisineType = this.mapToCuisineEnum(parsed.cuisineType);

      // Map mealType to Prisma enum format
      const mealType = this.mapToMealEnum(parsed.mealType);

      const recipe: ParsedRecipe = {
        name: parsed.name,
        description: parsed.description,
        prepTime: Number(parsed.prepTime),
        cookTime: parsed.cookTime ? Number(parsed.cookTime) : undefined,
        servings: parsed.servings ? Number(parsed.servings) : undefined,
        ingredients: parsed.ingredients.map((ing: any) => ({
          name: ing.name,
          quantity: String(ing.quantity),
          unit: ing.unit,
        })),
        steps: parsed.steps.map((step: any) => ({
          text: step.text,
          duration: step.duration ? Number(step.duration) : undefined,
          techniqueTag: step.techniqueTag || undefined,
        })),
        dietaryTags: parsed.dietaryTags,
        calories: parsed.calories ? Number(parsed.calories) : undefined,
        protein: parsed.protein ? Number(parsed.protein) : undefined,
        carbs: parsed.carbs ? Number(parsed.carbs) : undefined,
        fat: parsed.fat ? Number(parsed.fat) : undefined,
        difficulty: parsed.difficulty,
        cuisineType,
        mealType,
      };

      this.logger.log(`Successfully parsed recipe: ${recipe.name}`);
      return recipe;
    } catch (error) {
      this.logger.error(
        `Failed to parse recipe: ${error instanceof Error ? error.message : 'Unknown error'}`,
      );
      return null;
    }
  }

  /**
   * Map AI-extracted cuisine type to Prisma enum format
   * "Middle Eastern" -> "MIDDLE_EASTERN", "Tex-Mex" -> "TEX_MEX", etc.
   */
  private mapToCuisineEnum(cuisineType: string): string {
    const mapping: Record<string, string> = {
      Italian: 'ITALIAN',
      Mexican: 'MEXICAN',
      Chinese: 'CHINESE',
      Japanese: 'JAPANESE',
      Sichuan: 'SICHUAN',
      Cantonese: 'CANTONESE',
      Indian: 'INDIAN',
      Thai: 'THAI',
      Korean: 'KOREAN',
      Vietnamese: 'VIETNAMESE',
      Mediterranean: 'MEDITERRANEAN',
      French: 'FRENCH',
      Spanish: 'SPANISH',
      Greek: 'GREEK',
      'Middle Eastern': 'MIDDLE_EASTERN',
      Lebanese: 'LEBANESE',
      Turkish: 'TURKISH',
      Moroccan: 'MOROCCAN',
      Ethiopian: 'ETHIOPIAN',
      American: 'AMERICAN',
      Southern: 'SOUTHERN',
      'Tex-Mex': 'TEX_MEX',
      Brazilian: 'BRAZILIAN',
      Peruvian: 'PERUVIAN',
      Caribbean: 'CARIBBEAN',
      British: 'BRITISH',
      German: 'GERMAN',
      Fusion: 'FUSION',
      Other: 'OTHER',
    };

    const mapped = mapping[cuisineType];
    if (!mapped) {
      this.logger.warn(
        `Unknown cuisine type "${cuisineType}", defaulting to OTHER`,
      );
      return 'OTHER';
    }

    return mapped;
  }

  /**
   * Map AI-extracted meal type to Prisma enum format
   * "Breakfast" -> "BREAKFAST", etc.
   */
  private mapToMealEnum(mealType: string): string {
    const mapping: Record<string, string> = {
      Breakfast: 'BREAKFAST',
      Lunch: 'LUNCH',
      Dinner: 'DINNER',
      Snack: 'SNACK',
      Dessert: 'DESSERT',
      Appetizer: 'APPETIZER',
      Drink: 'DRINK',
    };

    const mapped = mapping[mealType];
    if (!mapped) {
      this.logger.warn(`Unknown meal type "${mealType}", defaulting to DINNER`);
      return 'DINNER';
    }

    return mapped;
  }
}
