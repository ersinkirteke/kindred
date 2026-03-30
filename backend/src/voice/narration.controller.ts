import {
  Controller,
  Get,
  Param,
  Query,
  Res,
  UseGuards,
  NotFoundException,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { Response } from 'express';
import { ClerkAuthGuard } from '../auth/auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { NarrationService } from './narration.service';
import { NarrationMetadataDto } from './dto/narration-request.dto';

/**
 * NarrationController
 *
 * REST endpoints for recipe narration streaming.
 * Voice features require authentication per project decision.
 *
 * Endpoints:
 * - GET /narration/:recipeId/stream - Stream audio/mpeg narration
 * - GET /narration/:recipeId/metadata - Get speaker/recipe metadata
 */
@Controller('narration')
@UseGuards(ClerkAuthGuard)
export class NarrationController {
  constructor(private readonly narrationService: NarrationService) {}

  /**
   * Stream recipe narration audio
   *
   * Returns chunked audio/mpeg stream with speaker metadata in headers.
   * Mobile client plays audio with low-latency streaming.
   *
   * @param recipeId - Recipe to narrate
   * @param voiceProfileId - Voice profile to use (query param)
   * @param user - Current user (from ClerkAuthGuard)
   * @param response - Express response for streaming
   */
  @Get(':recipeId/stream')
  @Throttle({ expensive: { limit: 10, ttl: 60000 } })
  async streamNarration(
    @Param('recipeId') recipeId: string,
    @Query('voiceProfileId') voiceProfileId: string,
    @CurrentUser() user: { userId: string },
    @Res({ passthrough: false }) response: Response,
  ): Promise<void> {
    if (!voiceProfileId) {
      throw new NotFoundException('voiceProfileId query parameter is required');
    }

    try {
      // Check for cached narration audio → redirect to CDN
      const cachedUrl = await this.narrationService.getCachedNarrationUrl(
        recipeId,
        voiceProfileId,
      );
      if (cachedUrl) {
        response.redirect(302, cachedUrl);
        return;
      }

      // No cache — stream from ElevenLabs (will cache after completion)
      await this.narrationService.streamRecipeNarration(
        recipeId,
        voiceProfileId,
        user.userId,
        response,
      );
    } catch (error) {
      // Error handling for various failure cases
      if (error instanceof NotFoundException) {
        response.status(404).json({
          error: 'Not found',
          message: error.message,
        });
      } else if (
        error instanceof Error &&
        error.message.includes('not ready')
      ) {
        response.status(400).json({
          error: 'Voice profile not ready',
          message: error.message,
        });
      } else if (
        error instanceof Error &&
        error.message.includes('ElevenLabs')
      ) {
        response.status(502).json({
          error: 'TTS service error',
          message: error.message,
        });
      } else {
        response.status(500).json({
          error: 'Internal server error',
          message:
            error instanceof Error
              ? error.message
              : 'Unknown error',
        });
      }
    }
  }

  /**
   * Get narration metadata
   *
   * Returns speaker and recipe metadata without streaming audio.
   * Mobile client calls this first to display "Narrated by Mom"
   * before user presses play.
   *
   * @param recipeId - Recipe to narrate
   * @param voiceProfileId - Voice profile to use (query param)
   * @param user - Current user (from ClerkAuthGuard)
   * @returns Metadata with speaker name, relationship, recipe info
   */
  @Get(':recipeId/metadata')
  async getNarrationMetadata(
    @Param('recipeId') recipeId: string,
    @Query('voiceProfileId') voiceProfileId: string,
    @CurrentUser() user: { userId: string },
  ): Promise<NarrationMetadataDto> {
    if (!voiceProfileId) {
      throw new NotFoundException('voiceProfileId query parameter is required');
    }

    return this.narrationService.getNarrationMetadata(
      recipeId,
      voiceProfileId,
      user.userId,
    );
  }
}
