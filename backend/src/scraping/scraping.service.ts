import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { XApiService } from './x-api.service';
import { InstagramService } from './instagram.service';
import { RecipeParserService } from './recipe-parser.service';
import { RawScrapedPost } from './dto/scraped-recipe.dto';
import { ImageGenerationProcessor } from '../images/image-generation.processor';

interface ScrapingResult {
  newRecipes: number;
  duplicates: number;
  parseFailures: number;
}

/**
 * Orchestrates the recipe scraping pipeline
 * Fetch -> Parse -> Deduplicate -> Store -> Queue Image Generation
 */
@Injectable()
export class ScrapingService {
  private readonly logger = new Logger(ScrapingService.name);
  private readonly viralThreshold: number;

  constructor(
    private readonly xApiService: XApiService,
    private readonly instagramService: InstagramService,
    private readonly recipeParser: RecipeParserService,
    private readonly prisma: PrismaService,
    private readonly imageProcessor: ImageGenerationProcessor,
  ) {
    // Engagement count threshold for viral flag (configurable)
    this.viralThreshold = 1000;
  }

  /**
   * Scrape recipes for a specific city
   * Returns counts for monitoring
   */
  async scrapeForCity(city: string): Promise<ScrapingResult> {
    this.logger.log(`Starting scrape for city: ${city}`);

    const result: ScrapingResult = {
      newRecipes: 0,
      duplicates: 0,
      parseFailures: 0,
    };

    try {
      // 1. Fetch raw posts from all sources
      const [xPosts, instagramPosts] = await Promise.all([
        this.xApiService.searchRecipeTweets(city, 20),
        this.instagramService.searchRecipePosts(city, 20),
      ]);

      const allPosts = [...xPosts, ...instagramPosts];
      this.logger.log(`Fetched ${allPosts.length} total posts for ${city}`);

      if (allPosts.length === 0) {
        this.logger.log(`No posts found for city: ${city}`);
        return result;
      }

      // 2. Deduplicate by sourceId - check existing recipes
      const sourceIds = allPosts.map((post) => post.sourceId);
      const existingRecipes = await this.prisma.recipe.findMany({
        where: {
          sourceId: { in: sourceIds },
        },
        select: { sourceId: true },
      });

      const existingSourceIds = new Set(
        existingRecipes.map((r) => r.sourceId),
      );
      const newPosts = allPosts.filter(
        (post) => !existingSourceIds.has(post.sourceId),
      );

      result.duplicates = allPosts.length - newPosts.length;
      this.logger.log(
        `Filtered out ${result.duplicates} duplicate posts, ${newPosts.length} new posts to process`,
      );

      // 3. Parse each new post
      for (const post of newPosts) {
        try {
          const parsedRecipe = await this.recipeParser.parseRecipeFromText(
            post.text,
          );

          if (!parsedRecipe) {
            result.parseFailures++;
            this.logger.debug(
              `Failed to parse recipe from post: ${post.sourceId}`,
            );
            continue;
          }

          // 4. Store in database
          const isViral = post.engagementCount >= this.viralThreshold;

          const createdRecipe = await this.prisma.recipe.create({
            data: {
              // Recipe metadata
              name: parsedRecipe.name,
              description: parsedRecipe.description,
              prepTime: parsedRecipe.prepTime,
              cookTime: parsedRecipe.cookTime,
              servings: parsedRecipe.servings,
              difficulty: parsedRecipe.difficulty,
              dietaryTags: parsedRecipe.dietaryTags,

              // Nutrition
              calories: parsedRecipe.calories,
              protein: parsedRecipe.protein,
              carbs: parsedRecipe.carbs,
              fat: parsedRecipe.fat,

              // Scraping metadata
              scrapedFrom: post.platform,
              sourceId: post.sourceId,
              location: city,
              scrapedAt: new Date(),
              imageStatus: 'PENDING', // Will be updated by image processor

              // Engagement
              isViral,
              engagementLoves: post.engagementCount, // We'll use this field for total engagement
              engagementViews: 0, // Not available from X API v2

              // Create nested ingredients
              ingredients: {
                create: parsedRecipe.ingredients.map((ing, index) => ({
                  name: ing.name,
                  quantity: ing.quantity,
                  unit: ing.unit,
                  orderIndex: index,
                })),
              },

              // Create nested steps
              steps: {
                create: parsedRecipe.steps.map((step, index) => ({
                  text: step.text,
                  duration: step.duration,
                  techniqueTag: step.techniqueTag,
                  orderIndex: index,
                })),
              },
            },
          });

          // 5. Queue background image generation (non-blocking)
          this.imageProcessor.enqueue({
            recipeId: createdRecipe.id,
            recipeName: createdRecipe.name,
            ingredients: parsedRecipe.ingredients.map((i) => i.name),
          });

          result.newRecipes++;
          this.logger.log(
            `✓ Stored recipe: ${parsedRecipe.name} (${post.sourceId})`,
          );
        } catch (error) {
          result.parseFailures++;
          this.logger.error(
            `Failed to process post ${post.sourceId}: ${error instanceof Error ? error.message : 'Unknown error'}`,
          );
        }
      }

      this.logger.log(
        `Scraping complete for ${city}: ${result.newRecipes} new, ${result.duplicates} duplicates, ${result.parseFailures} failures`,
      );

      return result;
    } catch (error) {
      this.logger.error(
        `Scraping failed for ${city}: ${error instanceof Error ? error.message : 'Unknown error'}`,
      );
      throw error;
    }
  }

  /**
   * Scrape with fallback strategy (city -> country -> global)
   * Implements INFR-04: expand radius when no results found
   */
  async scrapeWithFallback(city: string): Promise<void> {
    this.logger.log(`Starting scrape with fallback for city: ${city}`);

    // Try city-level scraping first
    const cityResult = await this.scrapeForCity(city);

    // If we got new recipes, we're done
    if (cityResult.newRecipes > 0) {
      this.logger.log(`City scrape successful: ${cityResult.newRecipes} recipes`);
      return;
    }

    // Check if we have cached recipes for this city
    const cachedCount = await this.prisma.recipe.count({
      where: { location: city },
    });

    if (cachedCount > 0) {
      this.logger.log(
        `No new recipes for ${city}, but ${cachedCount} cached recipes available`,
      );
      return;
    }

    // Fallback 1: Expand to country level
    this.logger.log(`No recipes found for ${city}, expanding to country level`);
    const country = this.deriveCountryFromCity(city);
    const countryResult = await this.scrapeForCity(country);

    if (countryResult.newRecipes > 0) {
      this.logger.log(
        `Country-level scrape successful: ${countryResult.newRecipes} recipes`,
      );
      return;
    }

    // Fallback 2: Global trending
    this.logger.log(
      `No recipes at country level, fetching global trending recipes`,
    );
    const globalResult = await this.scrapeForCity('global');

    if (globalResult.newRecipes > 0) {
      this.logger.log(
        `Global scrape successful: ${globalResult.newRecipes} recipes`,
      );
    } else {
      this.logger.warn(
        `All scraping sources exhausted for ${city}. App will serve cached content.`,
      );
    }
  }

  /**
   * Derive country from city name
   * Simple mapping - can be enhanced with geocoding API later
   */
  private deriveCountryFromCity(city: string): string {
    // Simple US city mapping
    const usCities = [
      'New York',
      'Los Angeles',
      'Chicago',
      'Houston',
      'Phoenix',
      'Philadelphia',
      'San Antonio',
      'San Diego',
      'Dallas',
      'San Jose',
      'Austin',
      'Jacksonville',
      'Fort Worth',
      'Columbus',
      'San Francisco',
      'Charlotte',
      'Indianapolis',
      'Seattle',
      'Denver',
      'Boston',
      'Miami',
      'Portland',
      'Las Vegas',
    ];

    if (usCities.some((c) => city.toLowerCase().includes(c.toLowerCase()))) {
      return 'United States';
    }

    // TODO: Add more country mappings or integrate geocoding API
    // For now, default to United States
    return 'United States';
  }
}
