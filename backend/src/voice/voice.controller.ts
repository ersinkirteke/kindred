import {
  Controller,
  Post,
  Body,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  Req,
  Param,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ClerkAuthGuard } from '../auth/auth.guard';
import { VoiceService } from './voice.service';
import { SubscriptionService } from '../subscription/subscription.service';
import { UploadVoiceInput } from './dto/upload-voice.input';
import { VoiceProfile } from '@prisma/client';

/**
 * VoiceController
 *
 * REST endpoints for voice file uploads.
 * Uses Multer for multipart/form-data file handling.
 * GraphQL doesn't support file uploads natively, so we use REST here.
 */
@Controller('voice')
@UseGuards(ClerkAuthGuard)
export class VoiceController {
  constructor(
    private readonly voiceService: VoiceService,
    private readonly subscriptionService: SubscriptionService,
  ) {}

  /**
   * POST /voice/upload
   *
   * Upload a voice sample for cloning.
   * Accepts multipart/form-data with:
   * - audio: Audio file (MP3, max 10MB)
   * - speakerName: Speaker's name (e.g., "Mom")
   * - relationship: Relationship to user (e.g., "Mother")
   * - consentGiven: Boolean consent flag (must be true)
   *
   * Returns created VoiceProfile with PENDING status.
   * Voice cloning happens asynchronously in background.
   */
  @Post('upload')
  @UseInterceptors(
    FileInterceptor('audio', {
      limits: {
        fileSize: 10 * 1024 * 1024, // 10MB max
      },
      fileFilter: (req, file, callback) => {
        // Only accept audio files
        if (!file.mimetype.startsWith('audio/')) {
          return callback(
            new BadRequestException('Only audio files are allowed'),
            false,
          );
        }
        callback(null, true);
      },
    }),
  )
  async uploadVoice(
    @UploadedFile() file: Express.Multer.File,
    @Body('speakerName') speakerName: string,
    @Body('relationship') relationship: string,
    @Body('consentGiven') consentGiven: string, // Form data sends as string
    @Body('appVersion') appVersion: string,
    @Req() req: any,
  ): Promise<VoiceProfile> {
    if (!file) {
      throw new BadRequestException('Audio file is required');
    }

    // Extract user from request (set by ClerkAuthGuard)
    const userId = req.user.clerkId;

    // Server-side voice slot enforcement (VOICE-07)
    // Free users limited to 1 voice profile; Pro users unlimited
    const slotCheck = await this.subscriptionService.checkVoiceSlotLimit(userId);
    if (!slotCheck.allowed) {
      throw new ForbiddenException(
        `Voice slot limit reached (${slotCheck.currentCount}/${slotCheck.limit === -1 ? 'unlimited' : slotCheck.limit}). Upgrade to Pro for unlimited voice profiles.`,
      );
    }

    // Extract IP address
    const ipAddress = req.ip || req.headers['x-forwarded-for'] || 'unknown';

    // Build input (convert consentGiven string to boolean)
    const input: UploadVoiceInput = {
      speakerName,
      relationship,
      consentGiven: consentGiven === 'true',
      appVersion: appVersion || undefined,
    };

    // Upload and enqueue for cloning
    return this.voiceService.uploadVoice(userId, file.buffer, input, ipAddress);
  }

  /**
   * POST /voice/:id/replace
   *
   * Replace/re-record an existing voice profile.
   * Accepts multipart/form-data with:
   * - audio: New audio file (MP3, max 10MB)
   *
   * Implements VOICE-07 re-record flow with preview before confirming replacement.
   */
  @Post(':id/replace')
  @UseInterceptors(
    FileInterceptor('audio', {
      limits: {
        fileSize: 10 * 1024 * 1024, // 10MB max
      },
      fileFilter: (req, file, callback) => {
        // Only accept audio files
        if (!file.mimetype.startsWith('audio/')) {
          return callback(
            new BadRequestException('Only audio files are allowed'),
            false,
          );
        }
        callback(null, true);
      },
    }),
  )
  async replaceVoice(
    @Param('id') id: string,
    @UploadedFile() file: Express.Multer.File,
    @Req() req: any,
  ): Promise<VoiceProfile> {
    if (!file) {
      throw new BadRequestException('Audio file is required');
    }

    // Extract user from request
    const userId = req.user.clerkId;

    // Extract IP address
    const ipAddress = req.ip || req.headers['x-forwarded-for'] || 'unknown';

    // Replace voice and enqueue for re-cloning
    return this.voiceService.replaceVoice(id, userId, file.buffer, ipAddress);
  }
}
