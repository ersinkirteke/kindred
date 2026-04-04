import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Recipe, CuisineType, MealType, DifficultyLevel, ImageStatus } from '@prisma/client';

export interface MappedRecipeData {
  spoonacularId: number;
  name: string;
  description: string | null;
  prepTime: number;
  cookTime: number | null;
  servings: number | null;
  calories: number | null;
  protein: number | null;
  carbs: number | null;
  fat: number | null;
  difficulty: DifficultyLevel;
  dietaryTags: string[];
  cuisineType: CuisineType;
  mealType: MealType;
  imageUrl: string | null;
  imageStatus: ImageStatus;
  scrapedFrom: string;
  sourceId: string | null;
  sourceUrl: string | null;
  sourceName: string | null;
  plainText: string | null;
  location: string | null;
  latitude: number | null;
  longitude: number | null;
  popularityScore: number | null;
  engagementLoves: number;
  engagementBookmarks: number;
  engagementViews: number;
  isViral: boolean;
  velocityScore: number;
  ingredients: Array<{
    name: string;
    quantity: string;
    unit: string;
    orderIndex: number;
  }>;
  steps: Array<{
    text: string;
    orderIndex: number;
    duration: number | null;
  }>;
}

export interface SearchFilters {
  cuisine?: string;
  diet?: string;
  intolerances?: string;
  [key: string]: string | undefined;
}

@Injectable()
export class SpoonacularCacheService {
  private readonly TTL_MS = 6 * 60 * 60 * 1000; // 6 hours
  private readonly CLEANUP_THRESHOLD_MS = 24 * 60 * 60 * 1000; // 24 hours

  constructor(
    private prisma: PrismaService,
    private logger: Logger,
  ) {}

  /**
   * Check cache first, return recipes + staleness status
   */
  async getCachedSearch(
    normalizedKey: string,
  ): Promise<{ recipes: Recipe[]; isStale: boolean } | null> {
    const cache = await this.prisma.searchCache.findUnique({
      where: { normalizedKey },
    });

    if (!cache) {
      return null;
    }

    const recipes = await this.getCachedRecipes(cache.recipeIds);
    const isStale = this.isStale(cache.cachedAt);

    return { recipes, isStale };
  }

  /**
   * Store search results: upsert SearchCache entry, upsert recipes by spoonacularId
   */
  async cacheSearchResults(
    normalizedKey: string,
    recipes: MappedRecipeData[],
  ): Promise<void> {
    const recipeIds = await this.upsertRecipes(recipes);

    await this.prisma.searchCache.upsert({
      where: { normalizedKey },
      update: {
        recipeIds,
        cachedAt: new Date(),
      },
      create: {
        normalizedKey,
        recipeIds,
        cachedAt: new Date(),
      },
    });

    this.logger.log(
      `Cached search results for key: ${normalizedKey} (${recipeIds.length} recipes)`,
    );
  }

  /**
   * Get cached recipes by internal IDs
   */
  async getCachedRecipes(recipeIds: string[]): Promise<Recipe[]> {
    return this.prisma.recipe.findMany({
      where: { id: { in: recipeIds } },
      include: {
        ingredients: {
          orderBy: { orderIndex: 'asc' },
        },
        steps: {
          orderBy: { orderIndex: 'asc' },
        },
      },
    }) as any;
  }

  /**
   * Normalize cache key: lowercase query, sort filter keys alphabetically, JSON.stringify
   */
  normalizeCacheKey(query: string, filters: SearchFilters): string {
    const normalizedQuery = query.trim().toLowerCase();
    const sortedFilters = Object.keys(filters)
      .sort()
      .reduce((acc, key) => {
        acc[key] = filters[key];
        return acc;
      }, {} as SearchFilters);

    return JSON.stringify({
      q: normalizedQuery,
      f: sortedFilters,
    });
  }

  /**
   * Check if a cache entry is stale
   */
  isStale(cachedAt: Date): boolean {
    const age = Date.now() - cachedAt.getTime();
    return age > this.TTL_MS;
  }

  /**
   * Upsert recipes by spoonacularId (create if new, update if exists)
   */
  async upsertRecipes(recipes: MappedRecipeData[]): Promise<string[]> {
    const recipeIds: string[] = [];

    await this.prisma.$transaction(async (tx) => {
      for (const recipeData of recipes) {
        const { ingredients, steps, ...recipeFields } = recipeData;

        // Delete old ingredients and steps before upserting recipe
        // This ensures we don't have duplicate ingredients/steps on update
        const existingRecipe = await tx.recipe.findUnique({
          where: { spoonacularId: recipeData.spoonacularId },
          select: { id: true },
        });

        if (existingRecipe) {
          await tx.ingredient.deleteMany({
            where: { recipeId: existingRecipe.id },
          });
          await tx.recipeStep.deleteMany({
            where: { recipeId: existingRecipe.id },
          });
        }

        const recipe = await tx.recipe.upsert({
          where: { spoonacularId: recipeData.spoonacularId },
          update: {
            ...recipeFields,
            scrapedAt: new Date(),
            updatedAt: new Date(),
            ingredients: {
              create: ingredients.map((ing) => ({
                name: ing.name,
                quantity: ing.quantity,
                unit: ing.unit,
                orderIndex: ing.orderIndex,
              })),
            },
            steps: {
              create: steps.map((step) => ({
                text: step.text,
                orderIndex: step.orderIndex,
                duration: step.duration,
              })),
            },
          },
          create: {
            ...recipeFields,
            scrapedAt: new Date(),
            createdAt: new Date(),
            updatedAt: new Date(),
            ingredients: {
              create: ingredients.map((ing) => ({
                name: ing.name,
                quantity: ing.quantity,
                unit: ing.unit,
                orderIndex: ing.orderIndex,
              })),
            },
            steps: {
              create: steps.map((step) => ({
                text: step.text,
                orderIndex: step.orderIndex,
                duration: step.duration,
              })),
            },
          },
        });

        recipeIds.push(recipe.id);
      }
    });

    return recipeIds;
  }

  /**
   * Remove stale cache entries (>24 hours)
   */
  async cleanExpiredCache(): Promise<number> {
    const cutoffDate = new Date(Date.now() - this.CLEANUP_THRESHOLD_MS);

    const result = await this.prisma.searchCache.deleteMany({
      where: {
        cachedAt: { lt: cutoffDate },
      },
    });

    if (result.count > 0) {
      this.logger.log(`Cleaned ${result.count} expired cache entries`);
    }

    return result.count;
  }
}
