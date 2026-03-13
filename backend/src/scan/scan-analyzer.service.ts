import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { DetectedItemDto } from './dto/scan-result.dto';

/**
 * AI-powered scan analyzer using Gemini 2.0 Flash
 *
 * Provides two analysis modes:
 * 1. Fridge photo analysis via Gemini Vision
 * 2. Receipt text parsing via Gemini
 *
 * Phase 15-01: Core AI analysis pipeline
 */
@Injectable()
export class ScanAnalyzerService {
  private readonly logger = new Logger(ScanAnalyzerService.name);
  private readonly genAI: GoogleGenerativeAI | null;
  private readonly model: any;

  constructor(private readonly configService: ConfigService) {
    const apiKey = this.configService.get<string>('GOOGLE_AI_API_KEY');

    if (!apiKey) {
      this.logger.warn(
        'GOOGLE_AI_API_KEY not configured - scan analysis will be unavailable',
      );
      this.genAI = null;
      this.model = null;
    } else {
      this.genAI = new GoogleGenerativeAI(apiKey);
      // Use Gemini 2.0 Flash for fast, cost-effective vision analysis
      this.model = this.genAI.getGenerativeModel({
        model: 'gemini-2.0-flash-exp',
        generationConfig: {
          temperature: 0.1, // Low temperature for precise detection
          responseMimeType: 'application/json',
        },
      });
    }
  }

  /**
   * Analyze a fridge photo using Gemini Vision
   *
   * @param photoUrl - R2 URL of the fridge photo
   * @returns Array of detected items with confidence scores
   */
  async analyzeFridgePhoto(photoUrl: string): Promise<DetectedItemDto[]> {
    if (!this.model) {
      this.logger.warn('Scan analyzer not initialized - returning empty results');
      return [];
    }

    try {
      // Fetch image from R2
      const response = await fetch(photoUrl);
      if (!response.ok) {
        throw new Error(`Failed to fetch image from R2: ${response.statusText}`);
      }

      const arrayBuffer = await response.arrayBuffer();
      const base64Data = Buffer.from(arrayBuffer).toString('base64');

      const prompt = `Analyze this fridge/pantry photo and detect food items. Return a JSON array of detected items.

CRITICAL RULES:
1. Only list clearly visible items - DO NOT guess at hidden items
2. Normalize all names to English (convert Turkish product names to English)
3. Categories MUST be one of: dairy, produce, meat, seafood, grains, baking, spices, beverages, snacks, condiments
4. Estimate quantities where possible (e.g., "~6" for eggs, "~500g" for chicken)
5. Storage location: "fridge", "freezer", or "pantry" based on item type and container
6. Expiry estimate: conservative days from today (be cautious for food safety)
7. Confidence: 0-100 score (lower for partially visible or unclear items)

Return JSON array with this structure:
[
  {
    "name": "eggs",
    "quantity": "~6",
    "category": "dairy",
    "storageLocation": "fridge",
    "estimatedExpiryDays": 14,
    "confidence": 90
  }
]

ONLY return the JSON array - no explanations, no markdown code blocks.`;

      // Create abort controller for 30-second timeout
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 30000);

      try {
        const result = await this.model.generateContent([
          prompt,
          {
            inlineData: {
              mimeType: 'image/jpeg',
              data: base64Data,
            },
          },
        ]);

        clearTimeout(timeoutId);

        const text = result.response.text();
        const parsed = JSON.parse(text);

        // Validate it's an array
        if (!Array.isArray(parsed)) {
          this.logger.warn('Gemini returned non-array response');
          return [];
        }

        // Map to DetectedItemDto
        const items: DetectedItemDto[] = parsed.map((item: any) => ({
          name: item.name || 'unknown',
          quantity: item.quantity || '1',
          category: item.category || 'other',
          storageLocation: item.storageLocation || 'pantry',
          estimatedExpiryDays: item.estimatedExpiryDays || 7,
          confidence: item.confidence || 50,
        }));

        this.logger.log(
          `Fridge photo analysis complete: detected ${items.length} items`,
        );
        return items;
      } catch (error) {
        clearTimeout(timeoutId);
        if (error.name === 'AbortError') {
          throw new Error('Gemini Vision request timed out after 30 seconds');
        }
        throw error;
      }
    } catch (error) {
      this.logger.error(
        `Failed to analyze fridge photo: ${error instanceof Error ? error.message : 'Unknown error'}`,
      );
      throw new Error(
        `Fridge photo analysis failed: ${error instanceof Error ? error.message : 'Unknown error'}`,
      );
    }
  }

  /**
   * Analyze receipt text using Gemini
   *
   * @param ocrText - OCR-extracted text from receipt
   * @returns Array of detected food items
   */
  async analyzeReceiptText(ocrText: string): Promise<DetectedItemDto[]> {
    if (!this.model) {
      this.logger.warn('Scan analyzer not initialized - returning empty results');
      return [];
    }

    try {
      const prompt = `Parse this receipt OCR text and extract FOOD items only. Return a JSON array.

CRITICAL RULES:
1. Expand abbreviations (e.g., "K FL MW" → "Kellogg's Froot Loops" → normalize to "cereal")
2. Normalize to English ingredient names - ignore brand names
3. ONLY extract FOOD items - skip toiletries, household goods, non-food
4. Categories MUST be one of: dairy, produce, meat, seafood, grains, baking, spices, beverages, snacks, condiments
5. Estimate quantities from receipt quantities (convert units to friendly format)
6. Storage location: infer from item type ("milk" = "fridge", "pasta" = "pantry", etc.)
7. Expiry estimate: conservative days from today based on food type
8. Confidence: lower (30-70) for ambiguous abbreviations

Return JSON array with this structure:
[
  {
    "name": "milk",
    "quantity": "1L",
    "category": "dairy",
    "storageLocation": "fridge",
    "estimatedExpiryDays": 7,
    "confidence": 85
  }
]

Receipt text:
${ocrText}

ONLY return the JSON array - no explanations, no markdown code blocks.`;

      // Create abort controller for 30-second timeout
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 30000);

      try {
        const result = await this.model.generateContent(prompt);
        clearTimeout(timeoutId);

        const text = result.response.text();
        const parsed = JSON.parse(text);

        // Validate it's an array
        if (!Array.isArray(parsed)) {
          this.logger.warn('Gemini returned non-array response for receipt');
          return [];
        }

        // Map to DetectedItemDto
        const items: DetectedItemDto[] = parsed.map((item: any) => ({
          name: item.name || 'unknown',
          quantity: item.quantity || '1',
          category: item.category || 'other',
          storageLocation: item.storageLocation || 'pantry',
          estimatedExpiryDays: item.estimatedExpiryDays || 7,
          confidence: item.confidence || 50,
        }));

        this.logger.log(
          `Receipt text analysis complete: detected ${items.length} food items`,
        );
        return items;
      } catch (error) {
        clearTimeout(timeoutId);
        if (error.name === 'AbortError') {
          throw new Error('Gemini text analysis timed out after 30 seconds');
        }
        throw error;
      }
    } catch (error) {
      this.logger.error(
        `Failed to analyze receipt text: ${error instanceof Error ? error.message : 'Unknown error'}`,
      );
      throw new Error(
        `Receipt text analysis failed: ${error instanceof Error ? error.message : 'Unknown error'}`,
      );
    }
  }
}
