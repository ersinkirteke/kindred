import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { GoogleGenerativeAI } from '@google/generative-ai';

/**
 * AI-powered expiry date estimator using IngredientCatalog + Gemini fallback
 *
 * Strategy:
 * 1. First check IngredientCatalog.defaultShelfLifeDays (fast, cost-free)
 * 2. If no catalog data, fallback to Gemini 2.0 Flash (AI estimation)
 * 3. If Gemini fails, use conservative defaults by storage type
 *
 * Phase 17-01: Expiry tracking backend
 */
@Injectable()
export class ExpiryEstimatorService {
  private readonly logger = new Logger(ExpiryEstimatorService.name);
  private readonly genAI: GoogleGenerativeAI | null;
  private readonly model: any;

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {
    const apiKey = this.configService.get<string>('GOOGLE_AI_API_KEY');

    if (!apiKey) {
      this.logger.warn(
        'GOOGLE_AI_API_KEY not configured - expiry estimation will use catalog + conservative defaults only',
      );
      this.genAI = null;
      this.model = null;
    } else {
      this.genAI = new GoogleGenerativeAI(apiKey);
      // Use Gemini 2.0 Flash for fast, cost-effective text inference
      this.model = this.genAI.getGenerativeModel({
        model: 'gemini-2.0-flash-exp',
        generationConfig: {
          temperature: 0.1, // Low temperature for consistent estimates
          responseMimeType: 'application/json',
        },
      });
    }
  }

  /**
   * Estimate shelf life in days for an ingredient.
   * Uses three-tier strategy: catalog → Gemini → defaults.
   *
   * @param itemName - Ingredient name (ideally normalized)
   * @param storageLocation - "fridge" | "freezer" | "pantry"
   * @returns Estimated shelf life in days
   */
  async estimateExpiryDate(
    itemName: string,
    storageLocation: string,
  ): Promise<number> {
    // 1. Try IngredientCatalog first (fastest, free)
    const catalogDays = await this.lookupCatalogShelfLife(itemName);
    if (catalogDays !== null) {
      this.logger.debug(
        `Found catalog shelf life for "${itemName}": ${catalogDays} days`,
      );
      return catalogDays;
    }

    // 2. Fallback to Gemini AI estimation
    if (this.model) {
      try {
        const aiDays = await this.estimateViaGemini(itemName, storageLocation);
        this.logger.log(
          `Gemini estimated shelf life for "${itemName}" in ${storageLocation}: ${aiDays} days`,
        );
        return aiDays;
      } catch (error) {
        this.logger.warn(
          `Gemini estimation failed for "${itemName}": ${error.message}. Using conservative default.`,
        );
      }
    }

    // 3. Conservative defaults by storage type (food safety first)
    const defaultDays = this.getConservativeDefault(storageLocation);
    this.logger.debug(
      `Using conservative default for "${itemName}" in ${storageLocation}: ${defaultDays} days`,
    );
    return defaultDays;
  }

  /**
   * Look up ingredient in catalog for default shelf life.
   * Case-insensitive search by canonicalName.
   */
  private async lookupCatalogShelfLife(
    itemName: string,
  ): Promise<number | null> {
    const normalizedName = itemName.toLowerCase().trim();

    const catalogEntry = await this.prisma.ingredientCatalog.findFirst({
      where: {
        canonicalName: { equals: normalizedName, mode: 'insensitive' },
      },
      select: { defaultShelfLifeDays: true },
    });

    return catalogEntry?.defaultShelfLifeDays ?? null;
  }

  /**
   * Estimate shelf life using Gemini 2.0 Flash.
   * 15-second timeout (shorter than photo analysis — simple text query).
   */
  private async estimateViaGemini(
    itemName: string,
    storageLocation: string,
  ): Promise<number> {
    const prompt = `Estimate the shelf life in days for "${itemName}" stored in "${storageLocation}". Return ONLY a JSON object: {"shelfLifeDays": N}. Be conservative for food safety. Consider:
- Storage location affects shelf life (freezer items last longer than fridge items, fridge items last longer than pantry items for most fresh foods)
- Unopened packaged foods vs. fresh produce
- Common safety guidelines

Examples:
- Fresh milk in fridge: 7 days
- Eggs in fridge: 21 days
- Chicken breast in freezer: 180 days
- Bread in pantry: 7 days

ONLY return the JSON object - no explanations.`;

    // Create abort controller for 15-second timeout
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 15000);

    try {
      const result = await this.model.generateContent(prompt);
      clearTimeout(timeoutId);

      const responseText = result.response.text();
      const parsed = JSON.parse(responseText);

      if (
        typeof parsed.shelfLifeDays !== 'number' ||
        parsed.shelfLifeDays < 1
      ) {
        throw new Error('Invalid shelfLifeDays in Gemini response');
      }

      return Math.round(parsed.shelfLifeDays);
    } catch (error) {
      clearTimeout(timeoutId);
      throw new Error(`Gemini estimation failed: ${error.message}`);
    }
  }

  /**
   * Conservative defaults by storage location for food safety.
   * Used when both catalog and Gemini are unavailable.
   */
  private getConservativeDefault(storageLocation: string): number {
    switch (storageLocation.toLowerCase()) {
      case 'freezer':
        return 30; // 1 month for frozen items (conservative)
      case 'fridge':
        return 7; // 1 week for refrigerated items
      case 'pantry':
        return 14; // 2 weeks for pantry items
      default:
        return 7; // Default to fridge-like behavior
    }
  }
}
