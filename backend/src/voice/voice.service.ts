import {
  Injectable,
  BadRequestException,
  ForbiddenException,
  NotFoundException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { R2StorageService } from '../images/r2-storage.service';
import { VoiceCloningProcessor } from './voice-cloning.processor';
import { ElevenLabsService } from './elevenlabs.service';
import { UploadVoiceInput } from './dto/upload-voice.input';
import { VoiceProfile, VoiceStatus } from '@prisma/client';

/**
 * VoiceService
 *
 * Manages voice profile CRUD operations with tier enforcement.
 * Coordinates voice upload, R2 storage, and background cloning.
 */
@Injectable()
export class VoiceService {
  private readonly logger = new Logger(VoiceService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly r2Storage: R2StorageService,
    private readonly voiceCloningProcessor: VoiceCloningProcessor,
    private readonly elevenLabsService: ElevenLabsService,
  ) {}

  /**
   * Upload a voice sample and enqueue for cloning
   *
   * Tier limits:
   * - FREE: 1 active voice profile
   * - PRO: Unlimited voices
   *
   * @param userId - User ID
   * @param audioBuffer - Audio file buffer (MP3)
   * @param input - Upload metadata (speakerName, relationship, consentGiven)
   * @param ipAddress - IP address for consent tracking
   * @returns Created VoiceProfile with PENDING status
   * @throws BadRequestException if consent not given
   * @throws ForbiddenException if tier limit exceeded
   */
  async uploadVoice(
    userId: string,
    audioBuffer: Buffer,
    input: UploadVoiceInput,
    ipAddress: string,
  ): Promise<VoiceProfile> {
    // Validate consent
    if (!input.consentGiven) {
      throw new BadRequestException('Voice consent is required');
    }

    // Resolve Clerk ID to internal User ID (auto-create if user doesn't exist yet)
    let user = await this.prisma.user.findUnique({
      where: { clerkId: userId },
    });
    if (!user) {
      this.logger.log(`User not found for clerkId ${userId}, creating...`);
      user = await this.prisma.user.create({
        data: { clerkId: userId, email: `${userId}@pending.kindred` },
      });
    }
    const internalUserId = user.id;

    // Check tier limits using actual subscription status
    const subscription = await this.prisma.subscription.findUnique({
      where: { userId: internalUserId },
    });
    const isPro = subscription?.isActive ?? false;

    if (!isPro) {
      const activeCount = await this.prisma.voiceProfile.count({
        where: {
          userId: internalUserId,
          status: { notIn: [VoiceStatus.DELETED, VoiceStatus.FAILED] },
        },
      });
      if (activeCount >= 1) {
        throw new ForbiddenException({
          code: 'VOICE_SLOT_LIMIT',
          message: 'Free tier allows 1 voice. Upgrade to Pro for unlimited voices.',
        });
      }
    }

    // Upload audio to R2
    this.logger.log(`Uploading voice sample for user ${userId}`);
    const audioSampleUrl = await this.r2Storage.uploadVoiceSample(
      userId,
      audioBuffer,
    );

    // Create VoiceProfile record
    const voiceProfile = await this.prisma.voiceProfile.create({
      data: {
        userId: internalUserId,
        status: VoiceStatus.PENDING,
        audioSampleUrl,
        speakerName: input.speakerName,
        relationship: input.relationship,
        consentedAt: new Date(),
        consentIpAddress: ipAddress,
        consentAppVersion: input.appVersion ?? null,
      },
    });

    this.logger.log(
      `Voice profile created: ${voiceProfile.id} for user ${userId}`,
    );

    // Enqueue background cloning
    this.voiceCloningProcessor.enqueue(
      userId,
      voiceProfile.id,
      audioSampleUrl,
    );

    return voiceProfile;
  }

  /**
   * Get all non-DELETED voice profiles for a user
   * Ordered by creation date (newest first)
   */
  async getVoiceProfiles(clerkId: string): Promise<VoiceProfile[]> {
    // Resolve Clerk ID to internal User ID
    const user = await this.prisma.user.findUnique({
      where: { clerkId },
    });
    if (!user) {
      return [];
    }

    return this.prisma.voiceProfile.findMany({
      where: {
        userId: user.id,
        status: { not: VoiceStatus.DELETED },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Get a single voice profile by ID
   * Validates ownership
   *
   * @throws NotFoundException if profile not found or doesn't belong to user
   */
  async getVoiceProfile(id: string, userId: string): Promise<VoiceProfile> {
    const profile = await this.prisma.voiceProfile.findFirst({
      where: { id, userId },
    });

    if (!profile) {
      throw new NotFoundException('Voice profile not found');
    }

    return profile;
  }

  /**
   * Delete a voice profile
   * Removes ElevenLabs voice and R2 audio sample, updates status to DELETED
   * Cascade deletes all narration audio for this voice profile
   *
   * @throws NotFoundException if profile not found or doesn't belong to user
   */
  async deleteVoiceProfile(id: string, userId: string): Promise<VoiceProfile> {
    // Verify ownership
    const profile = await this.getVoiceProfile(id, userId);

    // Cascade delete: remove all narration audio for this voice profile
    const narrationAudios = await this.prisma.narrationAudio.findMany({
      where: { voiceProfileId: id },
    });

    // Delete R2 files
    for (const audio of narrationAudios) {
      await this.r2Storage.deleteNarrationAudio(audio.r2Url);
    }

    // Delete database records
    await this.prisma.narrationAudio.deleteMany({
      where: { voiceProfileId: id },
    });

    this.logger.log(`Cascade-deleted ${narrationAudios.length} narration audios for voice profile ${id}`);

    // Delete ElevenLabs voice if exists (swallow errors)
    if (profile.elevenLabsVoiceId) {
      try {
        await this.elevenLabsService.deleteVoice(profile.elevenLabsVoiceId);
        this.logger.log(
          `Deleted ElevenLabs voice: ${profile.elevenLabsVoiceId}`,
        );
      } catch (error) {
        this.logger.warn(
          `Failed to delete ElevenLabs voice (may already be deleted): ${profile.elevenLabsVoiceId}`,
          error,
        );
      }
    }

    // Delete R2 voice sample (swallow errors)
    try {
      await this.r2Storage.deleteVoiceSample(profile.audioSampleUrl);
      this.logger.log(
        `Deleted R2 voice sample: ${profile.audioSampleUrl}`,
      );
    } catch (error) {
      this.logger.warn(
        `Failed to delete R2 voice sample (may already be deleted): ${profile.audioSampleUrl}`,
        error,
      );
    }

    // Update status to DELETED
    const updatedProfile = await this.prisma.voiceProfile.update({
      where: { id },
      data: { status: VoiceStatus.DELETED },
    });

    this.logger.log(`Voice profile deleted: ${id}`);
    return updatedProfile;
  }

  /**
   * Replace/re-record an existing voice profile
   * Implements VOICE-07 re-record flow
   *
   * @param id - Voice profile ID
   * @param userId - User ID
   * @param audioBuffer - New audio file buffer
   * @param ipAddress - IP address for consent tracking
   * @param appVersion - App version for consent audit trail
   * @returns Updated VoiceProfile with PENDING status
   * @throws NotFoundException if profile not found or doesn't belong to user
   */
  async replaceVoice(
    id: string,
    userId: string,
    audioBuffer: Buffer,
    ipAddress: string,
    appVersion?: string,
  ): Promise<VoiceProfile> {
    // Verify ownership
    const profile = await this.getVoiceProfile(id, userId);

    // Delete old ElevenLabs voice if exists
    if (profile.elevenLabsVoiceId) {
      try {
        await this.elevenLabsService.deleteVoice(profile.elevenLabsVoiceId);
        this.logger.log(
          `Deleted old ElevenLabs voice: ${profile.elevenLabsVoiceId}`,
        );
      } catch (error) {
        this.logger.warn(
          `Failed to delete old ElevenLabs voice: ${profile.elevenLabsVoiceId}`,
          error,
        );
      }
    }

    // Delete old R2 file
    try {
      await this.r2Storage.deleteVoiceSample(profile.audioSampleUrl);
      this.logger.log(
        `Deleted old R2 voice sample: ${profile.audioSampleUrl}`,
      );
    } catch (error) {
      this.logger.warn(
        `Failed to delete old R2 voice sample: ${profile.audioSampleUrl}`,
        error,
      );
    }

    // Upload new audio to R2
    this.logger.log(`Uploading new voice sample for profile ${id}`);
    const audioSampleUrl = await this.r2Storage.uploadVoiceSample(
      userId,
      audioBuffer,
    );

    // Update profile with new audio URL and reset status
    const updatedProfile = await this.prisma.voiceProfile.update({
      where: { id },
      data: {
        audioSampleUrl,
        status: VoiceStatus.PENDING,
        elevenLabsVoiceId: null,
        consentedAt: new Date(),
        consentIpAddress: ipAddress,
        consentAppVersion: appVersion ?? null,
      },
    });

    this.logger.log(`Voice profile replaced: ${id}`);

    // Enqueue new cloning job
    this.voiceCloningProcessor.enqueue(userId, id, audioSampleUrl);

    return updatedProfile;
  }
}
