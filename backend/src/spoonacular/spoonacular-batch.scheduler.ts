import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { SpoonacularService } from './spoonacular.service';
import { SpoonacularCacheService } from './spoonacular-cache.service';
import { PrismaService } from '../prisma/prisma.service';
import { mapSpoonacularToRecipe, validateRecipe } from './dto/recipe-mapper';

@Injectable()
export class SpoonacularBatchScheduler {
  private readonly logger = new Logger(SpoonacularBatchScheduler.name);
  private lastSuccessfulRun: Date | null = null;

  // Popular cuisines for diverse recipe coverage
  private readonly CUISINES = [
    'italian',
    'mexican',
    'chinese',
    'indian',
    'thai',
    'french',
    'japanese',
    'mediterranean',
    'american',
    'korean',
  ];

  // Popular search queries to pre-warm
  private readonly POPULAR_QUERIES = [
    'chicken',
    'pasta',
    'vegan',
    'dessert',
    'salad',
    'soup',
    'breakfast',
    'quick dinner',
    'healthy',
    'keto',
  ];

  constructor(
    private readonly spoonacularService: SpoonacularService,
    private readonly cacheService: SpoonacularCacheService,
    private readonly prisma: PrismaService,
  ) {}

  @Cron('0 2 * * *', { name: 'prewarm-recipes', timeZone: 'UTC' })
  async prewarmRecipes() {
    await this.executePrewarm('2:00 AM UTC');
  }

  @Cron('0 3 * * *', { name: 'prewarm-retry-1', timeZone: 'UTC' })
  async retryPrewarm1() {
    if (this.shouldRetry(1)) {
      this.logger.warn('2 AM job failed, retrying at 3 AM');
      await this.executePrewarm('3:00 AM UTC (retry 1)');
    }
  }

  @Cron('0 4 * * *', { name: 'prewarm-retry-2', timeZone: 'UTC' })
  async retryPrewarm2() {
    if (this.shouldRetry(2)) {
      this.logger.error('2 AM and 3 AM jobs failed, final retry at 4 AM');
      await this.executePrewarm('4:00 AM UTC (retry 2)');
    }
  }

  /**
   * Execute pre-warming of recipes and search queries.
   * Can be called directly for one-time trigger after deployment.
   */
  async executePrewarm(jobName: string): Promise<void> {
    this.logger.log(`Starting pre-warm job: ${jobName}`);

    try {
      const allRecipeIds: number[] = [];
      let validCount = 0;
      let skippedCount = 0;

      // Step 1: Fetch recipes from diverse cuisines
      this.logger.log(`Fetching recipes from ${this.CUISINES.length} cuisines...`);

      for (const cuisine of this.CUISINES) {
        try {
          // Fetch recipe IDs via search (lightweight call)
          const recipes = await this.spoonacularService.search(
            '',
            { cuisines: [cuisine] },
            10,
            0,
          );

          // Collect recipe IDs for bulk fetch
          const ids = recipes.map((r) => r.id);
          allRecipeIds.push(...ids);
        } catch (error) {
          this.logger.error(`Failed to search ${cuisine} recipes: ${error.message}`);
          // Continue with other cuisines
        }
      }

      // Step 2: Fetch full recipe information in bulk (deduplicate IDs first)
      const uniqueIds = [...new Set(allRecipeIds)];

      if (uniqueIds.length > 0) {
        try {
          const fullRecipes = await this.spoonacularService.getRecipeInformationBulk(
            uniqueIds.slice(0, 100), // Limit to 100 recipes
          );

          // Validate and map recipes
          const validRecipes: any[] = [];

          for (const recipe of fullRecipes) {
            if (validateRecipe(recipe)) {
              const mapped = mapSpoonacularToRecipe(recipe);
              validRecipes.push(mapped);
              validCount++;
            } else {
              skippedCount++;
              this.logger.warn(
                `Skipped invalid recipe ${recipe.id}: missing instructions or image`,
              );
            }
          }

          // Store all valid recipes in one batch
          if (validRecipes.length > 0) {
            await this.cacheService.upsertRecipes(validRecipes);
          }
        } catch (error) {
          this.logger.error(`Failed to fetch bulk recipe information: ${error.message}`);
          // Don't throw - continue with search query pre-warming
        }
      }

      // Step 3: Pre-warm popular search queries
      this.logger.log(`Pre-warming ${this.POPULAR_QUERIES.length} popular searches...`);

      for (const query of this.POPULAR_QUERIES) {
        try {
          const results = await this.spoonacularService.search(
            query,
            {},
            20,
            0,
          );

          // Fetch full data for search results if needed
          const resultIds = results.map((r) => r.id);
          const fullResults = await this.spoonacularService.getRecipeInformationBulk(
            resultIds,
          );

          // Validate and map results
          const validRecipes: any[] = [];

          for (const recipe of fullResults) {
            if (validateRecipe(recipe)) {
              validRecipes.push(mapSpoonacularToRecipe(recipe));
            }
          }

          if (validRecipes.length > 0) {
            // Store recipes
            await this.cacheService.upsertRecipes(validRecipes);

            // Cache search results
            const cacheKey = this.cacheService.normalizeCacheKey(query, {});
            await this.cacheService.cacheSearchResults(cacheKey, validRecipes);

            validCount += validRecipes.length;
          }

          skippedCount += fullResults.length - validRecipes.length;
        } catch (error) {
          this.logger.error(`Failed to pre-warm search "${query}": ${error.message}`);
          // Continue with other queries
        }
      }

      // Mark success
      this.lastSuccessfulRun = new Date();

      this.logger.log(
        `Pre-warm complete: ${validCount} recipes cached, ${skippedCount} skipped, ${this.POPULAR_QUERIES.length} searches cached`,
      );
    } catch (error) {
      this.logger.error(`Pre-warm job failed: ${error.message}`, error.stack);
      throw error;
    }
  }

  /**
   * Check if retry should execute based on time since last successful run
   */
  private shouldRetry(minHours: number): boolean {
    if (!this.lastSuccessfulRun) {
      return true; // No successful run yet, retry
    }

    const hoursSinceLastRun =
      (Date.now() - this.lastSuccessfulRun.getTime()) / (1000 * 60 * 60);

    return hoursSinceLastRun >= minHours;
  }
}
