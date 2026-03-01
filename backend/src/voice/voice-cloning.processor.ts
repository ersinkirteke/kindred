import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ElevenLabsService } from './elevenlabs.service';
import { PushService } from '../push/push.service';
import { VoiceStatus } from '@prisma/client';

interface VoiceJob {
  userId: string;
  voiceProfileId: string;
  audioUrl: string;
}

/**
 * Background processor for voice cloning queue
 *
 * Simple in-memory queue for MVP. Processes voice cloning jobs
 * asynchronously with ElevenLabs API.
 *
 * Pattern: Same as ImageGenerationProcessor from Phase 1
 * Future: Upgrade to BullMQ with Redis when scaling to multiple instances.
 */
@Injectable()
export class VoiceCloningProcessor {
  private readonly logger = new Logger(VoiceCloningProcessor.name);
  private readonly queue: VoiceJob[] = [];
  private isProcessing = false;

  constructor(
    private readonly prisma: PrismaService,
    private readonly elevenLabsService: ElevenLabsService,
    private readonly pushService: PushService,
  ) {}

  /**
   * Add a voice cloning job to the queue
   * Updates VoiceProfile status to PROCESSING and starts queue if not already running
   */
  enqueue(userId: string, voiceProfileId: string, audioUrl: string): void {
    this.queue.push({ userId, voiceProfileId, audioUrl });
    this.logger.log(
      `Enqueued voice cloning for profile ${voiceProfileId}. Queue size: ${this.queue.length}`,
    );

    // Update status to PROCESSING
    this.prisma.voiceProfile
      .update({
        where: { id: voiceProfileId },
        data: { status: VoiceStatus.PROCESSING },
      })
      .catch((error) => {
        this.logger.error(
          `Failed to update voice profile status to PROCESSING: ${voiceProfileId}`,
          error,
        );
      });

    // Start processing if not already running
    if (!this.isProcessing) {
      this.processQueue();
    }
  }

  /**
   * Get current queue size
   */
  getQueueSize(): number {
    return this.queue.length;
  }

  /**
   * Process pending jobs from the queue
   * Processes jobs one at a time with 100ms delay between jobs
   */
  private async processQueue(): Promise<void> {
    if (this.queue.length === 0) {
      this.isProcessing = false;
      return;
    }

    this.isProcessing = true;
    const job = this.queue.shift();

    if (!job) {
      this.isProcessing = false;
      return;
    }

    this.logger.log(
      `Processing voice cloning job for profile ${job.voiceProfileId} (${this.queue.length} remaining)`,
    );

    try {
      await this.processJob(job);
    } catch (error) {
      this.logger.error(
        `Voice cloning job failed for profile ${job.voiceProfileId}:`,
        error,
      );
    }

    // Process next job after 100ms delay
    setTimeout(() => this.processQueue(), 100);
  }

  /**
   * Process a single voice cloning job
   *
   * 1. Download audio buffer from R2 URL
   * 2. Call ElevenLabs cloneVoice API
   * 3. Update VoiceProfile with result (READY or FAILED)
   * 4. Send push notification on success
   */
  private async processJob(job: VoiceJob): Promise<void> {
    try {
      // Download audio buffer from R2 URL
      this.logger.log(`Downloading audio sample from ${job.audioUrl}`);
      const response = await fetch(job.audioUrl);

      if (!response.ok) {
        throw new Error(
          `Failed to download audio sample: ${response.status} ${response.statusText}`,
        );
      }

      const arrayBuffer = await response.arrayBuffer();
      const audioBuffer = Buffer.from(arrayBuffer);

      // Clone voice with ElevenLabs
      this.logger.log(
        `Cloning voice for profile ${job.voiceProfileId} using ElevenLabs`,
      );
      const elevenLabsVoiceId = await this.elevenLabsService.cloneVoice({
        name: `kindred_${job.voiceProfileId}`,
        files: [audioBuffer],
      });

      // Update profile status to READY with voice ID
      await this.prisma.voiceProfile.update({
        where: { id: job.voiceProfileId },
        data: {
          status: VoiceStatus.READY,
          elevenLabsVoiceId,
        },
      });

      this.logger.log(
        `✓ Voice cloning completed for profile ${job.voiceProfileId} (ElevenLabs ID: ${elevenLabsVoiceId})`,
      );

      // Send push notification
      await this.pushService.sendToUser(job.userId, {
        title: "Your voice is ready!",
        body: "Start listening to recipes in your loved one's voice",
        data: {
          type: 'VOICE_READY',
          voiceProfileId: job.voiceProfileId,
        },
      });

      this.logger.log(
        `Push notification sent to user ${job.userId} for voice profile ${job.voiceProfileId}`,
      );
    } catch (error) {
      this.logger.error(
        `Voice cloning failed for profile ${job.voiceProfileId}:`,
        error,
      );

      // Update profile status to FAILED
      await this.prisma.voiceProfile.update({
        where: { id: job.voiceProfileId },
        data: { status: VoiceStatus.FAILED },
      });
    }
  }
}
