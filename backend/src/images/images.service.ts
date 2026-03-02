import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { R2StorageService } from './r2-storage.service';
import { ImageStatus } from '@prisma/client';

// Google Cloud AI Platform imports for Imagen
import { PredictionServiceClient } from '@google-cloud/aiplatform';
import { google } from '@google-cloud/aiplatform/build/protos/protos';

/**
 * Service for AI-powered hero image generation using Imagen 4 Fast
 *
 * Generates flat lay editorial-style food photography for recipes,
 * uploads to Cloudflare R2, and updates recipe records.
 *
 * Process:
 * 1. Update recipe status to GENERATING
 * 2. Generate image with Imagen 4 Fast via Vertex AI
 * 3. Upload to R2 storage
 * 4. Update recipe with CDN URL and COMPLETED status
 * 5. On failure: set status to FAILED (non-blocking)
 */
@Injectable()
export class ImagesService {
  private readonly logger = new Logger(ImagesService.name);
  private readonly projectId: string;
  private readonly location = 'us-central1';
  private readonly predictionClient: PredictionServiceClient;

  constructor(
    private readonly r2Storage: R2StorageService,
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {
    this.projectId = this.configService.get<string>('GOOGLE_CLOUD_PROJECT', 'kindred-dev');

    // Initialize Vertex AI Prediction Service Client
    // Uses GOOGLE_APPLICATION_CREDENTIALS environment variable for auth
    this.predictionClient = new PredictionServiceClient({
      apiEndpoint: `${this.location}-aiplatform.googleapis.com`,
    });

    this.logger.log('Imagen 4 Fast service initialized');
  }

  /**
   * Generate and store a hero image for a recipe
   *
   * @param recipeId - Recipe ID
   * @param recipeName - Recipe name for prompt
   * @param ingredients - List of ingredient names for prompt context
   * @returns Public CDN URL of generated image, or null if generation failed
   */
  async generateAndStoreImage(
    recipeId: string,
    recipeName: string,
    ingredients: string[],
  ): Promise<string | null> {
    this.logger.log(`Starting image generation for recipe: ${recipeId} (${recipeName})`);

    try {
      // Step 1: Update status to GENERATING
      await this.prisma.recipe.update({
        where: { id: recipeId },
        data: { imageStatus: ImageStatus.GENERATING },
      });

      // Step 2: Build Imagen prompt for flat lay editorial style
      const topIngredients = ingredients.slice(0, 5).join(', ');
      const prompt = `Professional flat lay top-down food photograph of ${recipeName}. Key ingredients (${topIngredients}) arranged artistically around the finished dish. Clean white marble surface, natural soft lighting, warm tones, Instagram-worthy editorial food photography style. No text, no watermarks, no hands.`;

      this.logger.debug(`Imagen prompt: ${prompt}`);

      // Step 3: Generate image with Imagen 4 Fast
      const imageBuffer = await this.generateImageWithImagen(prompt);

      // Step 4: Upload to R2
      const key = `recipes/${recipeId}/hero.jpg`;
      const imageUrl = await this.r2Storage.uploadImage(imageBuffer, key, 'image/jpeg');

      // Step 5: Update recipe with URL and COMPLETED status
      await this.prisma.recipe.update({
        where: { id: recipeId },
        data: {
          imageUrl,
          imageStatus: ImageStatus.COMPLETED,
        },
      });

      this.logger.log(`Image generation completed for recipe ${recipeId}: ${imageUrl}`);
      return imageUrl;
    } catch (error) {
      // On failure: mark as FAILED (non-blocking - recipe still available)
      this.logger.error(`Image generation failed for recipe ${recipeId}:`, error);

      await this.prisma.recipe.update({
        where: { id: recipeId },
        data: { imageStatus: ImageStatus.FAILED },
      });

      return null;
    }
  }

  /**
   * Call Imagen 4 Fast API via Vertex AI
   *
   * @param prompt - Image generation prompt
   * @returns Buffer containing JPEG image data
   * @throws Error if generation fails
   */
  private async generateImageWithImagen(prompt: string): Promise<Buffer> {
    try {
      // Construct the model endpoint path
      const endpoint = `projects/${this.projectId}/locations/${this.location}/publishers/google/models/imagegeneration@006`;

      // Build prediction request with proper structure
      const instanceValue = {
        prompt,
      };

      const parametersValue = {
        sampleCount: 1,
        aspectRatio: '1:1', // Square images for recipe cards
        safetyFilterLevel: 'block_some',
        personGeneration: 'dont_allow', // No people in food photography
      };

      const request = {
        endpoint,
        instances: [
          {
            structValue: {
              fields: {
                prompt: {
                  stringValue: prompt,
                },
              },
            },
          },
        ],
        parameters: {
          structValue: {
            fields: {
              sampleCount: {
                numberValue: 1,
              },
              aspectRatio: {
                stringValue: '1:1',
              },
              safetyFilterLevel: {
                stringValue: 'block_some',
              },
              personGeneration: {
                stringValue: 'dont_allow',
              },
            },
          },
        },
      };

      // Call prediction API
      this.logger.debug('Calling Imagen API...');
      const [response] = await this.predictionClient.predict(request);

      // Extract image from response
      if (!response.predictions || response.predictions.length === 0) {
        throw new Error('No images returned from Imagen API');
      }

      const prediction = response.predictions[0];
      const imageData = (prediction?.structValue?.fields?.bytesBase64Encoded?.stringValue as string) || null;

      if (!imageData) {
        throw new Error('Image data not found in Imagen response');
      }

      // Decode base64 to buffer
      const imageBuffer = Buffer.from(imageData, 'base64');
      this.logger.debug(`Generated image size: ${imageBuffer.length} bytes`);

      return imageBuffer;
    } catch (error) {
      this.logger.error('Imagen API call failed:', error);
      throw new Error(`Imagen generation failed: ${error.message}`);
    }
  }

  /**
   * Retry failed image generations
   *
   * Finds recipes with FAILED status and attempts to regenerate.
   * Useful for batch recovery after API outages or quota issues.
   *
   * @param limit - Maximum number of recipes to retry (default: 10)
   * @returns Count of successfully generated images
   */
  async retryFailedImages(limit: number = 10): Promise<number> {
    this.logger.log(`Retrying failed image generations (limit: ${limit})`);

    const failedRecipes = await this.prisma.recipe.findMany({
      where: { imageStatus: ImageStatus.FAILED },
      take: limit,
      select: {
        id: true,
        name: true,
        ingredients: {
          select: { name: true },
        },
      },
    });

    let successCount = 0;

    for (const recipe of failedRecipes) {
      const ingredientNames = recipe.ingredients.map((i) => i.name);
      const imageUrl = await this.generateAndStoreImage(recipe.id, recipe.name, ingredientNames);

      if (imageUrl) {
        successCount++;
      }
    }

    this.logger.log(`Retry complete: ${successCount}/${failedRecipes.length} images generated`);
    return successCount;
  }
}
