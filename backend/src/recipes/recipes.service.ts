import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SpoonacularService } from '../spoonacular/spoonacular.service';
import { SpoonacularCacheService } from '../spoonacular/spoonacular-cache.service';
import { SearchRecipesInput } from './dto/search-recipes.input';
import { RecipeConnection } from '../feed/dto/feed-connection.type';
import { mapSpoonacularToRecipe, validateRecipe } from '../spoonacular/dto/recipe-mapper';
import { Recipe } from '@prisma/client';

@Injectable()
export class RecipesService {
  private readonly logger = new Logger(RecipesService.name);

  constructor(
    private prisma: PrismaService,
    private spoonacularService: SpoonacularService,
    private cacheService: SpoonacularCacheService,
  ) {}

  /**
   * Search recipes with cache-first pattern and stale-while-revalidate
   */
  async searchRecipes(input: SearchRecipesInput): Promise<RecipeConnection> {
    const { query = '', cuisines = [], diets = [], intolerances = [], first = 20, after } = input;

    // Build normalized cache key
    const filters = {
      ...(cuisines.length > 0 && { cuisines: cuisines.join(',') }),
      ...(diets.length > 0 && { diets: diets.join(',') }),
      ...(intolerances.length > 0 && { intolerances: intolerances.join(',') }),
    };
    const normalizedKey = this.cacheService.normalizeCacheKey(query, filters);

    // Check cache first
    const cached = await this.cacheService.getCachedSearch(normalizedKey);

    if (cached) {
      const { recipes, isStale } = cached;

      // If stale, trigger background refresh but return stale data immediately
      if (isStale) {
        this.logger.log(`Serving stale cache for ${normalizedKey}, triggering background refresh`);
        this.refreshCacheInBackground(normalizedKey, query, filters, first, 0).catch((err) => {
          this.logger.error(`Background refresh failed: ${err.message}`);
        });
      }

      return this.buildRecipeConnection(recipes, recipes.length, first, after);
    }

    // Cache miss - check quota
    const hasQuota = await this.spoonacularService.hasQuotaRemaining();

    if (!hasQuota) {
      this.logger.warn('Quota exhausted, attempting fallback to popular recipes');
      return this.getQuotaExhaustedFallback(first, after);
    }

    // Fetch from Spoonacular API
    try {
      const offset = after ? this.decodeCursor(after) : 0;
      const spoonacularRecipes = await this.spoonacularService.search(
        query,
        {
          cuisines,
          diets,
          intolerances,
        },
        first,
        offset,
      );

      // Validate and map recipes
      const validRecipes = spoonacularRecipes.filter(validateRecipe);
      const mappedRecipes = validRecipes.map(mapSpoonacularToRecipe);

      // Cache results
      if (mappedRecipes.length > 0) {
        await this.cacheService.cacheSearchResults(normalizedKey, mappedRecipes);
      }

      // Fetch cached recipes to get IDs
      const cachedResult = await this.cacheService.getCachedSearch(normalizedKey);
      const recipes = cachedResult ? cachedResult.recipes : [];

      return this.buildRecipeConnection(recipes, recipes.length, first, after);
    } catch (error) {
      this.logger.error(`Spoonacular search failed: ${error.message}`);
      return this.getQuotaExhaustedFallback(first, after);
    }
  }

  /**
   * Get popular recipes sorted by popularity score
   */
  async getPopularRecipes(first: number = 20, after?: string): Promise<RecipeConnection> {
    const offset = after ? this.decodeCursor(after) : 0;

    const [recipes, totalCount] = await Promise.all([
      this.prisma.recipe.findMany({
        where: {
          spoonacularId: { not: null },
          popularityScore: { not: null },
        },
        orderBy: { popularityScore: 'desc' },
        take: first,
        skip: offset,
        include: {
          ingredients: {
            orderBy: { orderIndex: 'asc' },
          },
          steps: {
            orderBy: { orderIndex: 'asc' },
          },
        },
      }),
      this.prisma.recipe.count({
        where: {
          spoonacularId: { not: null },
          popularityScore: { not: null },
        },
      }),
    ]);

    return this.buildRecipeConnection(recipes as any, totalCount, first, after);
  }

  /**
   * Quota exhausted fallback - return popular pre-warmed recipes
   */
  private async getQuotaExhaustedFallback(
    first: number,
    after?: string,
  ): Promise<RecipeConnection> {
    const offset = after ? this.decodeCursor(after) : 0;

    const [recipes, totalCount] = await Promise.all([
      this.prisma.recipe.findMany({
        where: {
          popularityScore: { not: null },
        },
        orderBy: { popularityScore: 'desc' },
        take: first,
        skip: offset,
        include: {
          ingredients: {
            orderBy: { orderIndex: 'asc' },
          },
          steps: {
            orderBy: { orderIndex: 'asc' },
          },
        },
      }),
      this.prisma.recipe.count({
        where: {
          popularityScore: { not: null },
        },
      }),
    ]);

    return this.buildRecipeConnection(recipes as any, totalCount, first, after);
  }

  /**
   * Background refresh for stale cache
   */
  private async refreshCacheInBackground(
    normalizedKey: string,
    query: string,
    filters: Record<string, string>,
    first: number,
    offset: number,
  ): Promise<void> {
    const hasQuota = await this.spoonacularService.hasQuotaRemaining();
    if (!hasQuota) {
      this.logger.warn('Quota exhausted, skipping background refresh');
      return;
    }

    const spoonacularRecipes = await this.spoonacularService.search(
      query,
      filters,
      first,
      offset,
    );

    const validRecipes = spoonacularRecipes.filter(validateRecipe);
    const mappedRecipes = validRecipes.map(mapSpoonacularToRecipe);

    if (mappedRecipes.length > 0) {
      await this.cacheService.cacheSearchResults(normalizedKey, mappedRecipes);
      this.logger.log(`Background refresh completed for ${normalizedKey}`);
    }
  }

  /**
   * Build RecipeConnection with cursor pagination
   */
  private buildRecipeConnection(
    recipes: Recipe[],
    totalCount: number,
    first: number,
    after?: string,
  ): RecipeConnection {
    const offset = after ? this.decodeCursor(after) : 0;

    const edges = recipes.map((recipe, index) => ({
      node: recipe as any,
      cursor: this.encodeCursor(offset + index),
    }));

    const hasNextPage = offset + recipes.length < totalCount;
    const hasPreviousPage = offset > 0;

    return {
      edges,
      pageInfo: {
        hasNextPage,
        hasPreviousPage,
        startCursor: edges.length > 0 ? edges[0].cursor : null,
        endCursor: edges.length > 0 ? edges[edges.length - 1].cursor : null,
      },
      totalCount,
      lastRefreshed: new Date().toISOString(),
      expandedFrom: null,
      expandedTo: null,
      newSinceLastFetch: null,
      partialMatch: null,
      filtersRelaxed: null,
    };
  }

  /**
   * Encode offset as base64 cursor
   */
  private encodeCursor(offset: number): string {
    return Buffer.from(offset.toString()).toString('base64');
  }

  /**
   * Decode base64 cursor to offset
   */
  private decodeCursor(cursor: string): number {
    return parseInt(Buffer.from(cursor, 'base64').toString('utf-8'), 10);
  }

  // =========================================================
  // Legacy methods (deprecated, kept for backward compatibility)
  // Will be removed in Phase 26
  // =========================================================

  /**
   * Find all recipes with optional location filter and pagination.
   * Returns recipes ordered by scraping date (newest first).
   */
  async findAll(location?: string, limit: number = 20, offset: number = 0) {
    return this.prisma.recipe.findMany({
      where: location ? { location } : undefined,
      include: {
        ingredients: {
          orderBy: { orderIndex: 'asc' },
        },
        steps: {
          orderBy: { orderIndex: 'asc' },
        },
      },
      orderBy: { scrapedAt: 'desc' },
      take: limit,
      skip: offset,
    });
  }

  /**
   * Find a single recipe by ID with all relations.
   */
  async findById(id: string) {
    return this.prisma.recipe.findUnique({
      where: { id },
      include: {
        ingredients: {
          orderBy: { orderIndex: 'asc' },
        },
        steps: {
          orderBy: { orderIndex: 'asc' },
        },
      },
    });
  }

  /**
   * Find viral recipes for a specific location.
   * Returns up to 10 viral recipes ordered by engagement.
   */
  async findViral(location: string) {
    return this.prisma.recipe.findMany({
      where: {
        location,
        isViral: true,
      },
      include: {
        ingredients: {
          orderBy: { orderIndex: 'asc' },
        },
        steps: {
          orderBy: { orderIndex: 'asc' },
        },
      },
      orderBy: [
        { engagementLoves: 'desc' },
        { engagementViews: 'desc' },
      ],
      take: 10,
    });
  }

  /**
   * Count cached recipes for a location
   * Used by fallback logic to determine if cached data exists
   */
  async countByLocation(location: string): Promise<number> {
    return this.prisma.recipe.count({
      where: { location },
    });
  }

  /**
   * Find most recent recipes for a location
   * Used when scraping fails but cached data exists (INFR-04)
   */
  async findRecent(location: string, limit: number = 20) {
    return this.prisma.recipe.findMany({
      where: { location },
      include: {
        ingredients: {
          orderBy: { orderIndex: 'asc' },
        },
        steps: {
          orderBy: { orderIndex: 'asc' },
        },
      },
      orderBy: { scrapedAt: 'desc' },
      take: limit,
    });
  }
}
