import {
  Controller,
  Post,
  Body,
  Headers,
  UnauthorizedException,
  BadRequestException,
  Logger,
  RawBodyRequest,
  Req,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ModuleRef } from '@nestjs/core';
import { Webhook } from 'svix';
import { ClerkWebhookPayload } from './dto/clerk-webhook.dto';
import { UsersService } from '../users/users.service';
import { PrismaService } from '../prisma/prisma.service';
import { R2StorageService } from '../images/r2-storage.service';
import { VoiceService } from '../voice/voice.service';
import { Request } from 'express';

/**
 * REST controller for Clerk webhook events.
 * Handles user.created, user.updated, and user.deleted events to sync user data.
 *
 * SECURITY: Verifies webhook signatures using svix to prevent unauthorized access.
 * Endpoint: POST /webhooks/clerk
 */
@Controller('webhooks')
export class ClerkWebhookController {
  private readonly logger = new Logger(ClerkWebhookController.name);
  private readonly webhookSecret: string | undefined;

  constructor(
    private readonly configService: ConfigService,
    private readonly usersService: UsersService,
    private readonly prisma: PrismaService,
    private readonly r2Storage: R2StorageService,
    private readonly moduleRef: ModuleRef,
  ) {
    this.webhookSecret = this.configService.get<string>('CLERK_WEBHOOK_SECRET');
    if (!this.webhookSecret) {
      this.logger.warn(
        'CLERK_WEBHOOK_SECRET is not configured. Webhook signature verification will fail.',
      );
    }
  }

  @Post('clerk')
  async handleWebhook(
    @Req() req: RawBodyRequest<Request>,
    @Headers('svix-id') svixId: string,
    @Headers('svix-timestamp') svixTimestamp: string,
    @Headers('svix-signature') svixSignature: string,
    @Body() payload: ClerkWebhookPayload,
  ) {
    // Verify webhook signature using svix
    if (!this.webhookSecret) {
      throw new UnauthorizedException('Webhook secret not configured');
    }

    if (!svixId || !svixTimestamp || !svixSignature) {
      this.logger.warn('Missing svix headers');
      throw new UnauthorizedException('Missing webhook signature headers');
    }

    try {
      const wh = new Webhook(this.webhookSecret);

      // Verify signature using raw body
      const rawBody = req.rawBody?.toString('utf-8');
      if (!rawBody) {
        throw new UnauthorizedException('Raw body not available for signature verification');
      }

      // svix.verify validates signature, timestamp, and prevents replay attacks
      wh.verify(rawBody, {
        'svix-id': svixId,
        'svix-timestamp': svixTimestamp,
        'svix-signature': svixSignature,
      }) as ClerkWebhookPayload;

      this.logger.log(`Verified webhook event: ${payload.type}`);
    } catch (error) {
      this.logger.error(`Webhook signature verification failed: ${error.message}`);
      throw new UnauthorizedException('Invalid webhook signature');
    }

    // Process webhook event
    try {
      switch (payload.type) {
        case 'user.created':
        case 'user.updated':
          await this.handleUserUpsert(payload);
          break;

        case 'user.deleted':
          await this.handleUserDelete(payload);
          break;

        default:
          this.logger.warn(`Unhandled webhook event type: ${payload.type}`);
      }

      return { received: true };
    } catch (error) {
      this.logger.error(`Error processing webhook: ${error.message}`, error.stack);
      throw new BadRequestException('Failed to process webhook event');
    }
  }

  /**
   * Handle user.created and user.updated events.
   * Upserts user record in database.
   */
  private async handleUserUpsert(payload: ClerkWebhookPayload) {
    const { id: clerkId, email_addresses, first_name, last_name } = payload.data;

    // Get primary email address
    const email = email_addresses[0]?.email_address;
    if (!email) {
      throw new BadRequestException('User has no email address');
    }

    // Build display name from first and last name
    const displayName = [first_name, last_name].filter(Boolean).join(' ') || undefined;

    this.logger.log(`Upserting user ${clerkId} (${email})`);

    await this.usersService.upsertFromClerk(clerkId, email, displayName);
  }

  /**
   * Handle user.deleted events (account deletion, App Store guideline 5.1.1(v)).
   * Deletes voice clones (ElevenLabs + R2), scan photos and all database records.
   */
  private async handleUserDelete(payload: ClerkWebhookPayload) {
    const { id: clerkId } = payload.data;

    const user = await this.usersService.findByClerkId(clerkId);
    if (!user) {
      this.logger.log(`user.deleted for unknown user ${clerkId}, nothing to delete`);
      return;
    }

    this.logger.log(`Deleting account data for user ${clerkId}`);

    // Voice profiles: VoiceService removes the ElevenLabs voice, the R2 sample and
    // narration audio. Resolved at runtime: importing VoiceModule here would
    // create a module cycle (VoiceModule -> SubscriptionModule -> AuthModule).
    const voiceService = this.moduleRef.get(VoiceService, { strict: false });
    const voiceProfiles = await voiceService.getVoiceProfiles(clerkId);
    for (const profile of voiceProfiles) {
      try {
        await voiceService.deleteVoiceProfile(profile.id, clerkId);
      } catch (error) {
        this.logger.warn(`Failed to delete voice profile ${profile.id}: ${error.message}`);
      }
    }

    // Fridge scan photos stored in R2
    const scans = await this.prisma.scanJob.findMany({
      where: { userId: user.id, photoUrl: { not: null } },
      select: { photoUrl: true },
    });
    for (const scan of scans) {
      await this.r2Storage.deleteUserFile(scan.photoUrl!);
    }

    const result = await this.usersService.deleteAccountData(user.id);
    this.logger.log(
      `Deleted account ${clerkId}: ${voiceProfiles.length} voice profiles, ${scans.length} scan photos, ` +
        `${result.notificationLogs} notification logs, ${result.detachedTransactions} transactions detached`,
    );
  }
}
