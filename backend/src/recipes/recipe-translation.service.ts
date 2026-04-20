import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { PrismaService } from '../prisma/prisma.service';
import {
  RecipeTranslationDto,
  TranslatedIngredientDto,
  TranslatedStepDto,
} from './dto/recipe-translation.dto';

interface TranslationPayload {
  name: string;
  description: string | null;
  ingredients: TranslatedIngredientDto[];
  steps: TranslatedStepDto[];
}

/**
 * RecipeTranslationService
 *
 * Gemini-backed on-demand translation of recipe fields (name, description,
 * ingredients, steps) into the user's locale. Results are cached per
 * (recipeId, locale) so each language pays the Gemini call once across the
 * entire user base.
 */
@Injectable()
export class RecipeTranslationService {
  private readonly logger = new Logger(RecipeTranslationService.name);
  private readonly model: any;

  constructor(
    private readonly prisma: PrismaService,
    configService: ConfigService,
  ) {
    const apiKey = configService.get<string>('GOOGLE_AI_API_KEY');
    if (!apiKey) {
      this.logger.warn(
        'GOOGLE_AI_API_KEY not configured — recipe translation disabled',
      );
      this.model = null;
      return;
    }
    const genAI = new GoogleGenerativeAI(apiKey);
    this.model = genAI.getGenerativeModel({
      model: 'gemini-2.5-flash',
      generationConfig: {
        temperature: 0.2, // Low temperature for faithful translations
        responseMimeType: 'application/json',
      },
    });
    this.logger.log('RecipeTranslationService initialized with gemini-2.5-flash');
  }

  async getOrGenerate(
    recipeId: string,
    locale: string,
  ): Promise<RecipeTranslationDto | null> {
    const normalized = this.normalizeLocale(locale);

    // English is the source language; never translate to itself.
    if (normalized === 'en') return null;

    // Cache hit
    const cached = await this.prisma.recipeTranslation.findUnique({
      where: { recipeId_locale: { recipeId, locale: normalized } },
    });
    if (cached) {
      return this.toDto(recipeId, normalized, {
        name: cached.name,
        description: cached.description,
        ingredients: cached.ingredients as any,
        steps: cached.steps as any,
      });
    }

    if (!this.model) {
      this.logger.warn(
        `Gemini unavailable — cannot translate recipe ${recipeId} to ${normalized}`,
      );
      return null;
    }

    // Load recipe
    const recipe = await this.prisma.recipe.findUnique({
      where: { id: recipeId },
      include: { steps: true, ingredients: true },
    });
    if (!recipe) throw new NotFoundException(`Recipe ${recipeId} not found`);

    const translated = await this.translateViaGemini(recipe, normalized);
    if (!translated) return null;

    // Cache
    try {
      await this.prisma.recipeTranslation.upsert({
        where: { recipeId_locale: { recipeId, locale: normalized } },
        update: {
          name: translated.name,
          description: translated.description,
          ingredients: translated.ingredients as any,
          steps: translated.steps as any,
          generatedAt: new Date(),
        },
        create: {
          recipeId,
          locale: normalized,
          name: translated.name,
          description: translated.description,
          ingredients: translated.ingredients as any,
          steps: translated.steps as any,
        },
      });
    } catch (err) {
      this.logger.warn(
        `Failed to cache recipe translation ${recipeId}/${normalized}: ${err instanceof Error ? err.message : err}`,
      );
    }

    return this.toDto(recipeId, normalized, translated);
  }

  private async translateViaGemini(
    recipe: {
      name: string;
      description: string | null;
      ingredients: Array<{ name: string; quantity: string; unit: string }>;
      steps: Array<{ text: string; orderIndex: number }>;
    },
    locale: string,
  ): Promise<TranslationPayload | null> {
    const language = this.languageNameForLocale(locale);

    const sortedSteps = [...recipe.steps].sort(
      (a, b) => a.orderIndex - b.orderIndex,
    );

    const input = {
      name: recipe.name,
      description: recipe.description ?? '',
      ingredients: recipe.ingredients.map((i) => ({
        name: i.name,
        quantity: i.quantity,
        unit: i.unit,
      })),
      steps: sortedSteps.map((s) => ({ orderIndex: s.orderIndex, text: s.text })),
    };

    const prompt = `Translate the following recipe into natural, native-level ${language} (locale ${locale}).

STRICT rules:
- Translate EVERY English word into ${language} — including measurement units (cup → ${language} equivalent like "su bardağı" for tr, tablespoon → "yemek kaşığı", teaspoon → "çay kaşığı", ounce → "ons", pound → "libre", package → "paket", can → "kutu", slice → "dilim", pinch → "tutam", to taste → "tadımlık"), time units (minutes → "dakika", hours → "saat", seconds → "saniye"), dimensions (inch → "inç" or size in cm, foot/feet → "adım"), number-words (one/two/three → "bir"/"iki"/"üç" — or better, replace with digits), food words (icing, baking, semi, chocolate, flour), and common nouns (serving → "porsiyon" for tr).
- Keep numeric quantities as digits ("3", "1/2", "2.5"). Do NOT translate numbers.
- Keep brand names and proper nouns untouched (Oreo, Coca-Cola, Heinz, KitchenAid). These are recognizable by being capitalized product names.
- No half-English words, no transliterations of English, no leftover English terms. If a term has no direct ${language} equivalent, use the standard ${language} culinary term.

Return STRICT JSON only — no commentary, no markdown, no explanations:
{
  "name": string,
  "description": string,
  "ingredients": [{ "name": string, "quantity": string, "unit": string }],
  "steps": [{ "orderIndex": number, "text": string }]
}

Source recipe (JSON):
${JSON.stringify(input)}`;

    try {
      this.logger.log(
        `Translating recipe "${recipe.name}" to ${language} (${locale})`,
      );
      const result = await this.model.generateContent(prompt);
      const raw = result.response.text();
      const parsed = JSON.parse(raw) as TranslationPayload;

      // Defensive: ensure arrays are present and shaped
      if (
        !parsed ||
        typeof parsed.name !== 'string' ||
        !Array.isArray(parsed.ingredients) ||
        !Array.isArray(parsed.steps)
      ) {
        this.logger.warn(
          `Gemini translation response was malformed for recipe in ${locale}`,
        );
        return null;
      }

      return {
        name: parsed.name,
        description: parsed.description || null,
        ingredients: parsed.ingredients.map((i) => ({
          name: String(i.name ?? ''),
          quantity: String(i.quantity ?? ''),
          unit: String(i.unit ?? ''),
        })),
        steps: parsed.steps.map((s) => ({
          orderIndex: Number(s.orderIndex ?? 0),
          text: String(s.text ?? ''),
        })),
      };
    } catch (err) {
      this.logger.error(
        `Gemini translation failed for locale ${locale}: ${err instanceof Error ? err.message : err}`,
      );
      return null;
    }
  }

  private toDto(
    recipeId: string,
    locale: string,
    payload: TranslationPayload,
  ): RecipeTranslationDto {
    return {
      recipeId,
      locale,
      name: payload.name,
      description: payload.description ?? null,
      ingredients: payload.ingredients,
      steps: payload.steps,
    };
  }

  /**
   * Batch translate: returns cached translations for the given recipe IDs,
   * generating any that are missing in parallel and awaiting them so the
   * caller can render all cards in the user's language at once (no English
   * flicker). First call for a locale is slow (one Gemini request per
   * missing recipe, fanned out); subsequent calls are served from cache.
   */
  async getBatch(
    recipeIds: string[],
    locale: string,
  ): Promise<RecipeTranslationDto[]> {
    const normalized = this.normalizeLocale(locale);
    if (normalized === 'en' || recipeIds.length === 0) return [];

    const cached = await this.prisma.recipeTranslation.findMany({
      where: { locale: normalized, recipeId: { in: recipeIds } },
    });

    const cachedMap = new Map(cached.map((t) => [t.recipeId, t]));
    const missing = recipeIds.filter((id) => !cachedMap.has(id));

    if (missing.length > 0) {
      this.logger.log(
        `Batch translating ${missing.length} missing recipes to ${normalized}`,
      );
      // Fan out Gemini calls in parallel; settle all so one failure doesn't
      // take down the rest of the feed.
      const generated = await Promise.allSettled(
        missing.map((id) => this.getOrGenerate(id, normalized)),
      );
      generated.forEach((result, i) => {
        if (result.status === 'fulfilled' && result.value) {
          // getOrGenerate already upserted the DB row, so just merge into map
          cachedMap.set(missing[i], {
            recipeId: missing[i],
            locale: normalized,
            name: result.value.name,
            description: result.value.description ?? null,
            ingredients: result.value.ingredients as any,
            steps: result.value.steps as any,
            generatedAt: new Date(),
            id: '',
          } as any);
        } else if (result.status === 'rejected') {
          this.logger.warn(
            `Batch translation failed for recipe ${missing[i]}: ${result.reason?.message ?? result.reason}`,
          );
        }
      });
    }

    // Return in the order the caller requested, skipping ids we couldn't
    // translate (caller falls back to English for those).
    return recipeIds
      .map((id) => cachedMap.get(id))
      .filter((t): t is NonNullable<typeof t> => t != null)
      .map((t) =>
        this.toDto(t.recipeId, normalized, {
          name: t.name,
          description: t.description,
          ingredients: t.ingredients as any,
          steps: t.steps as any,
        }),
      );
  }

  private normalizeLocale(locale: string): string {
    const lang = (locale || 'en').split(/[-_]/)[0].toLowerCase();
    return lang.length >= 2 ? lang : 'en';
  }

  private languageNameForLocale(locale: string): string {
    const names: Record<string, string> = {
      ar: 'Arabic', de: 'German', en: 'English', es: 'Spanish', fr: 'French',
      hi: 'Hindi', id: 'Indonesian', it: 'Italian', ja: 'Japanese', ko: 'Korean',
      nl: 'Dutch', pl: 'Polish', pt: 'Portuguese', ru: 'Russian', sv: 'Swedish',
      tr: 'Turkish', uk: 'Ukrainian', vi: 'Vietnamese', zh: 'Chinese',
    };
    return names[locale] ?? locale;
  }
}
