import { Resolver, Query, Mutation, Args } from '@nestjs/graphql';
import { UseGuards } from '@nestjs/common';
import { ClerkAuthGuard } from '../auth/auth.guard';
import {
  CurrentUser,
  CurrentUserContext,
} from '../common/decorators/current-user.decorator';
import { VoiceService } from './voice.service';
import { SubscriptionService } from '../subscription/subscription.service';
import { VoiceProfileDto } from './dto/voice-profile.dto';
import { NarrationMetadataDto } from './dto/narration-request.dto';
import { NarrationService } from './narration.service';
import { PrismaService } from '../prisma/prisma.service';

/**
 * VoiceResolver
 *
 * GraphQL queries and mutations for voice profile management.
 * File uploads (voice recording) are handled via REST controller.
 * This resolver handles queries and non-file mutations only.
 *
 * IMPORTANT: Voice CREATION is REST-only (POST /voice/upload in VoiceController).
 * This resolver has no creation mutation. If a createVoiceProfile mutation is ever
 * added to this resolver, it MUST call subscriptionService.checkVoiceSlotLimit(userId)
 * BEFORE creating the profile to enforce VOICE-07 slot limits (free users: 1 slot,
 * Pro users: unlimited). See VoiceController.uploadVoice() for reference implementation.
 */
@Resolver(() => VoiceProfileDto)
export class VoiceResolver {
  constructor(
    private readonly voiceService: VoiceService,
    private readonly narrationService: NarrationService,
    private readonly prisma: PrismaService,
    private readonly subscriptionService: SubscriptionService,
  ) {}

  /**
   * Query: myVoiceProfiles
   *
   * Returns all non-DELETED voice profiles for the current user.
   * Ordered by creation date (newest first).
   */
  @Query(() => [VoiceProfileDto])
  @UseGuards(ClerkAuthGuard)
  async myVoiceProfiles(
    @CurrentUser() user: CurrentUserContext,
  ): Promise<VoiceProfileDto[]> {
    return this.voiceService.getVoiceProfiles(user.clerkId);
  }

  /**
   * Query: voiceProfile
   *
   * Get a single voice profile by ID.
   * Validates ownership (user must own the profile).
   */
  @Query(() => VoiceProfileDto)
  @UseGuards(ClerkAuthGuard)
  async voiceProfile(
    @Args('id') id: string,
    @CurrentUser() user: CurrentUserContext,
  ): Promise<VoiceProfileDto> {
    return this.voiceService.getVoiceProfile(id, user.clerkId);
  }

  /**
   * Mutation: deleteVoiceProfile
   *
   * Delete a voice profile.
   * Removes ElevenLabs voice and R2 audio sample, updates status to DELETED.
   */
  @Mutation(() => VoiceProfileDto)
  @UseGuards(ClerkAuthGuard)
  async deleteVoiceProfile(
    @Args('id') id: string,
    @CurrentUser() user: CurrentUserContext,
  ): Promise<VoiceProfileDto> {
    return this.voiceService.deleteVoiceProfile(id, user.clerkId);
  }

  /**
   * Mutation: updateVoiceProfileName
   *
   * Update speakerName and relationship on an existing voice profile.
   * Useful for VOICE-05 (editing displayed name without re-recording).
   */
  @Mutation(() => VoiceProfileDto)
  @UseGuards(ClerkAuthGuard)
  async updateVoiceProfileName(
    @Args('id') id: string,
    @Args('speakerName') speakerName: string,
    @Args('relationship') relationship: string,
    @CurrentUser() user: CurrentUserContext,
  ): Promise<VoiceProfileDto> {
    // Verify ownership first
    const profile = await this.voiceService.getVoiceProfile(id, user.clerkId);

    // Update name and relationship fields only
    // Note: This doesn't trigger re-cloning since the voice audio remains the same
    const updatedProfile = await this.prisma.voiceProfile.update({
      where: { id: profile.id },
      data: {
        speakerName,
        relationship,
      },
    });

    return updatedProfile;
  }

  /**
   * Query: narrationMetadata
   *
   * Get metadata for recipe narration without streaming audio.
   * Mobile client calls this to display "Narrated by Mom" before user presses play.
   * Allows querying metadata alongside other recipe data in a single GraphQL request.
   */
  @Query(() => NarrationMetadataDto)
  @UseGuards(ClerkAuthGuard)
  async narrationMetadata(
    @Args('recipeId') recipeId: string,
    @Args('voiceProfileId') voiceProfileId: string,
    @CurrentUser() user: CurrentUserContext,
  ): Promise<NarrationMetadataDto> {
    return this.narrationService.getNarrationMetadata(
      recipeId,
      voiceProfileId,
      user.clerkId,
    );
  }
}
