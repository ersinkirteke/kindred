import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { Response } from 'express';
import { PrismaService } from '../prisma/prisma.service';
import { ElevenLabsService } from './elevenlabs.service';
import { R2StorageService } from '../images/r2-storage.service';
import { NarrationMetadataDto } from './dto/narration-request.dto';

/**
 * NarrationService
 *
 * Narration pipeline: Gemini rewrites recipe steps into warm conversational text,
 * ElevenLabs generates streaming audio in the cloned voice, and REST endpoint
 * delivers chunked audio to mobile clients.
 *
 * Purpose: Core emotional feature - hearing a loved one's voice guide you through cooking.
 */
@Injectable()
export class NarrationService {
  private readonly logger = new Logger(NarrationService.name);
  private readonly genAI: GoogleGenerativeAI | null;
  private readonly model: any;

  constructor(
    private readonly prisma: PrismaService,
    private readonly elevenLabsService: ElevenLabsService,
    private readonly r2Storage: R2StorageService,
    private readonly configService: ConfigService,
  ) {
    const apiKey = this.configService.get<string>('GOOGLE_AI_API_KEY');

    if (!apiKey) {
      this.logger.warn(
        'GOOGLE_AI_API_KEY not configured - narration will be unavailable',
      );
      this.genAI = null;
      this.model = null;
    } else {
      this.genAI = new GoogleGenerativeAI(apiKey);
      // Use Gemini 2.0 Flash for conversational rewriting
      this.model = this.genAI.getGenerativeModel({
        model: 'gemini-2.0-flash',
        generationConfig: {
          temperature: 0.7, // Higher temperature for warm, natural conversation
        },
      });
      this.logger.log('Narration service initialized with Gemini 2.0 Flash');
    }
  }

  /**
   * Rewrite recipe into warm conversational narration text
   *
   * Uses Gemini to transform dry recipe steps into warm narration as if
   * a loved one is guiding you through cooking. Results cached per recipe.
   *
   * @param recipe - Recipe data with name, description, steps, ingredients
   * @returns Conversational narration text with [PAUSE] markers
   */
  async rewriteToConversational(recipe: {
    id: string;
    name: string;
    description: string | null;
    steps: Array<{ text: string; orderIndex: number }>;
    ingredients: Array<{ name: string; quantity: string; unit: string }>;
  }): Promise<string> {
    // Check cache first (works regardless of Gemini availability)
    const cached = await this.prisma.narrationScript.findUnique({
      where: { recipeId: recipe.id },
    });

    if (cached) {
      this.logger.log(`Using cached narration for recipe: ${recipe.id}`);
      return cached.conversationalText;
    }

    // Gemini not configured — use plain readout so ElevenLabs still speaks the recipe in the user's cloned voice
    if (!this.model) {
      this.logger.warn(
        `GOOGLE_AI_API_KEY not configured — using plain narration for recipe ${recipe.id}`,
      );
      return this.buildPlainNarration(recipe);
    }

    this.logger.log(`Generating conversational narration for: ${recipe.name}`);

    // Sort steps by order
    const sortedSteps = [...recipe.steps].sort(
      (a, b) => a.orderIndex - b.orderIndex,
    );

    // Build Gemini prompt
    const ingredientsList = recipe.ingredients
      .map((i) => `- ${i.name}: ${i.quantity} ${i.unit}`)
      .join('\n');

    const stepsList = sortedSteps
      .map((s, i) => `${i + 1}. ${s.text}`)
      .join('\n');

    const prompt = `Rewrite this recipe into warm, conversational narration as if a loved one is guiding you through cooking.

Recipe: ${recipe.name}
Description: ${recipe.description || 'A delicious recipe'}

Ingredients:
${ingredientsList}

Steps:
${stepsList}

Guidelines:
- Start with warm intro: "Today we're making ${recipe.name}"
- List ingredients overview: "You'll need ${recipe.ingredients.length} ingredients..."
- Rewrite each step conversationally: "Chop onions" → "Now, let's chop up those onions"
- Add natural pauses between steps (insert "[PAUSE]" markers for 2-second gaps)
- Keep it warm and encouraging, like a loved one talking you through it
- Total length: suitable for 2-5 minutes when spoken aloud
- Use phrases like "Now", "Next", "While that's cooking", "Don't forget to"
- Add little tips and encouragement: "This is the best part", "Almost there", "Smells amazing, right?"

Output only the narration script, no explanations.`;

    try {
      const result = await this.model.generateContent(prompt);
      const response = result.response;
      const conversationalText = response.text();

      // Cache the result
      await this.prisma.narrationScript.upsert({
        where: { recipeId: recipe.id },
        update: { conversationalText, generatedAt: new Date() },
        create: {
          recipeId: recipe.id,
          conversationalText,
          generatedAt: new Date(),
        },
      });

      this.logger.log(`Cached narration for recipe: ${recipe.id}`);
      return conversationalText;
    } catch (error) {
      this.logger.error(
        `Failed to generate narration for recipe ${recipe.id}; falling back to plain readout`,
        error,
      );
      return this.buildPlainNarration(recipe);
    }
  }

  /**
   * Build a plain, TTS-safe readout of the recipe without Gemini rewriting.
   *
   * Used as a fallback when Gemini is unavailable (no API key, quota exceeded,
   * network error). ElevenLabs still synthesizes this in the user's cloned
   * voice — the only thing missing is the conversational polish.
   *
   * Not persisted to narrationScript table so that a later successful Gemini
   * call can replace it for the same recipe.
   */
  private buildPlainNarration(recipe: {
    name: string;
    description: string | null;
    steps: Array<{ text: string; orderIndex: number }>;
    ingredients: Array<{ name: string; quantity: string; unit: string }>;
  }): string {
    const sortedSteps = [...recipe.steps].sort(
      (a, b) => a.orderIndex - b.orderIndex,
    );

    const parts: string[] = [`${recipe.name}.`];
    if (recipe.description) {
      parts.push(recipe.description, '[PAUSE]');
    }

    if (recipe.ingredients.length > 0) {
      const ingredientsText = recipe.ingredients
        .map((i) => `${i.quantity} ${i.unit} ${i.name}`.trim().replace(/\s+/g, ' '))
        .join(', ');
      parts.push(`Ingredients: ${ingredientsText}.`, '[PAUSE]');
    }

    sortedSteps.forEach((s, i) => {
      parts.push(`Step ${i + 1}. ${s.text}`, '[PAUSE]');
    });

    return parts.join(' ');
  }

  /**
   * Check for cached narration audio and return CDN URL if available
   *
   * @returns CDN URL if cached, null if not
   */
  async getCachedNarrationUrl(
    recipeId: string,
    voiceProfileId: string,
  ): Promise<string | null> {
    const cached = await this.prisma.narrationAudio.findUnique({
      where: {
        recipeId_voiceProfileId: { recipeId, voiceProfileId },
      },
    });
    return cached?.r2Url ?? null;
  }

  /**
   * Stream recipe narration audio to client
   *
   * Rewrites recipe text via Gemini, then streams ElevenLabs TTS audio
   * with chunked transfer encoding for low-latency playback.
   * After streaming completes, uploads the audio to R2 for future cache hits.
   *
   * @param recipeId - Recipe to narrate
   * @param voiceProfileId - Voice profile to use
   * @param userId - Current user (for auth)
   * @param response - Express response object for streaming
   */
  async streamRecipeNarration(
    recipeId: string,
    voiceProfileId: string,
    userId: string,
    response: Response,
  ): Promise<void> {
    // Verify voice profile ownership and status
    const voiceProfile = await this.prisma.voiceProfile.findFirst({
      where: {
        id: voiceProfileId,
        userId,
      },
    });

    if (!voiceProfile) {
      throw new NotFoundException(
        `Voice profile ${voiceProfileId} not found for user ${userId}`,
      );
    }

    if (voiceProfile.status !== 'READY') {
      throw new Error(
        `Voice profile ${voiceProfileId} is not ready (status: ${voiceProfile.status})`,
      );
    }

    if (!voiceProfile.elevenLabsVoiceId) {
      throw new Error(
        `Voice profile ${voiceProfileId} has no ElevenLabs voice ID`,
      );
    }

    // Load recipe with steps and ingredients
    const recipe = await this.prisma.recipe.findUnique({
      where: { id: recipeId },
      include: {
        steps: true,
        ingredients: true,
      },
    });

    if (!recipe) {
      throw new NotFoundException(`Recipe ${recipeId} not found`);
    }

    // Get conversational narration text
    const narrationText = await this.rewriteToConversational(recipe);

    // Replace [PAUSE] markers with natural pause (ellipsis for TTS)
    const ttsText = narrationText.replace(/\[PAUSE\]/g, '...');

    // Set streaming headers
    response.setHeader('Content-Type', 'audio/mpeg');
    response.setHeader('Transfer-Encoding', 'chunked');
    response.setHeader('Cache-Control', 'no-cache');
    response.setHeader('X-Speaker-Name', voiceProfile.speakerName);
    response.setHeader('X-Speaker-Relationship', voiceProfile.relationship);
    response.setHeader('X-Recipe-Name', recipe.name);

    this.logger.log(
      `Streaming narration for recipe ${recipeId} with voice ${voiceProfile.speakerName}`,
    );

    try {
      // Get ElevenLabs TTS stream
      const audioStream =
        await this.elevenLabsService.generateSpeechStream(
          voiceProfile.elevenLabsVoiceId,
          ttsText,
        );

      const reader = audioStream.getReader();
      const chunks: Buffer[] = [];

      // Pipe chunks to response while collecting for cache
      let done = false;
      while (!done) {
        const { value, done: streamDone } = await reader.read();
        done = streamDone;

        if (value) {
          const buf = Buffer.from(value);
          response.write(buf);
          chunks.push(buf);
        }
      }

      response.end();
      this.logger.log(`Narration stream completed for recipe ${recipeId}`);

      // Upload to R2 cache in background (non-blocking, failure won't break playback)
      const fullBuffer = Buffer.concat(chunks);
      this.cacheNarrationAudio(recipeId, voiceProfileId, fullBuffer).catch(
        (err) =>
          this.logger.warn(
            `Failed to cache narration audio for recipe ${recipeId}: ${err.message}`,
          ),
      );
    } catch (error) {
      this.logger.error(
        `Failed to stream narration for recipe ${recipeId}`,
        error,
      );
      // Attempt to end response gracefully
      if (!response.headersSent) {
        response.status(502).json({
          error: 'Failed to generate speech',
          message:
            error instanceof Error ? error.message : 'Unknown error',
        });
      } else {
        response.end();
      }
    }
  }

  /**
   * Generate narration audio on-demand (non-streaming), cache in R2, and return the URL.
   * Called when narrationUrl query finds no cached audio.
   */
  async generateAndCacheNarration(
    recipeId: string,
    voiceProfileId: string,
    userId: string,
  ): Promise<{ url: string; durationMs: number | null }> {
    // Verify voice profile ownership and status
    const voiceProfile = await this.prisma.voiceProfile.findFirst({
      where: { id: voiceProfileId, userId },
    });

    if (!voiceProfile || voiceProfile.status !== 'READY' || !voiceProfile.elevenLabsVoiceId) {
      throw new Error(`Voice profile ${voiceProfileId} is not ready for TTS`);
    }

    // Load recipe
    const recipe = await this.prisma.recipe.findUnique({
      where: { id: recipeId },
      include: { steps: true, ingredients: true },
    });

    if (!recipe) {
      throw new Error(`Recipe ${recipeId} not found`);
    }

    // Generate conversational narration text via Gemini
    const narrationText = await this.rewriteToConversational(recipe);
    const ttsText = narrationText.replace(/\[PAUSE\]/g, '...');

    this.logger.log(
      `Generating on-demand narration for recipe ${recipeId} with voice ${voiceProfile.speakerName}`,
    );

    // Generate full audio via ElevenLabs TTS
    const audioStream = await this.elevenLabsService.generateSpeechStream(
      voiceProfile.elevenLabsVoiceId,
      ttsText,
    );

    const reader = audioStream.getReader();
    const chunks: Buffer[] = [];
    let done = false;
    while (!done) {
      const { value, done: streamDone } = await reader.read();
      done = streamDone;
      if (value) {
        chunks.push(Buffer.from(value));
      }
    }

    const fullBuffer = Buffer.concat(chunks);
    this.logger.log(
      `Generated ${fullBuffer.length} bytes of narration audio for recipe ${recipeId}`,
    );

    // Cache in R2 and save to DB
    await this.cacheNarrationAudio(recipeId, voiceProfileId, fullBuffer);

    // Retrieve the cached record for the URL and duration
    const cached = await this.prisma.narrationAudio.findUnique({
      where: { recipeId_voiceProfileId: { recipeId, voiceProfileId } },
    });

    return {
      url: cached!.r2Url,
      durationMs: cached?.durationMs ?? null,
    };
  }

  /**
   * Upload narration audio to R2 and save cache record with duration metadata
   */
  async cacheNarrationAudio(
    recipeId: string,
    voiceProfileId: string,
    audioBuffer: Buffer,
  ): Promise<void> {
    const crypto = require('crypto');
    const getMp3Duration = require('get-mp3-duration');

    // Generate hash from audio content for cache busting
    const hash = crypto.createHash('md5').update(audioBuffer).digest('hex').substring(0, 8);
    const key = `narration/${recipeId}/${voiceProfileId}-${hash}.mp3`;

    // Calculate duration from MP3 buffer
    let durationMs: number | null = null;
    try {
      durationMs = getMp3Duration(audioBuffer);
    } catch (err) {
      this.logger.warn(`Failed to calculate MP3 duration: ${err.message}`);
    }

    const r2Url = await this.r2Storage.uploadNarrationAudio(
      recipeId,
      voiceProfileId,
      audioBuffer,
      key,
    );

    await this.prisma.narrationAudio.upsert({
      where: {
        recipeId_voiceProfileId: { recipeId, voiceProfileId },
      },
      update: { r2Url, sizeBytes: audioBuffer.length, durationMs },
      create: {
        recipeId,
        voiceProfileId,
        r2Url,
        sizeBytes: audioBuffer.length,
        durationMs,
      },
    });

    this.logger.log(
      `Cached narration audio for recipe ${recipeId}, voice ${voiceProfileId} (${audioBuffer.length} bytes, ${durationMs}ms, key: ${key})`,
    );
  }

  /**
   * Get narration metadata without streaming audio
   *
   * Used for UI display before user presses play.
   * Mobile client shows "Narrated by Mom" before loading audio.
   *
   * @param recipeId - Recipe to narrate
   * @param voiceProfileId - Voice profile to use
   * @param userId - Current user (for auth)
   * @returns Metadata with speaker name, relationship, recipe info
   */
  async getNarrationMetadata(
    recipeId: string,
    voiceProfileId: string,
    userId: string,
  ): Promise<NarrationMetadataDto> {
    // Verify voice profile ownership
    const voiceProfile = await this.prisma.voiceProfile.findFirst({
      where: {
        id: voiceProfileId,
        userId,
      },
    });

    if (!voiceProfile) {
      throw new NotFoundException(
        `Voice profile ${voiceProfileId} not found for user ${userId}`,
      );
    }

    // Load recipe
    const recipe = await this.prisma.recipe.findUnique({
      where: { id: recipeId },
      select: { id: true, name: true },
    });

    if (!recipe) {
      throw new NotFoundException(`Recipe ${recipeId} not found`);
    }

    return {
      speakerName: voiceProfile.speakerName,
      relationship: voiceProfile.relationship,
      recipeId: recipe.id,
      recipeName: recipe.name,
    };
  }
}
