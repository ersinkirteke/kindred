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
import { NarrationUrlDto } from './dto/narration-url.dto';
import { NarrationService } from './narration.service';
import { PrismaService } from '../prisma/prisma.service';
import { GraphQLError } from 'graphql';
import { GraphQLErrorCode } from '../common/errors/graphql-error-codes.enum';

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
   * Fire-and-forget pre-warm: queues narration generation for a recipe/voice/locale
   * so the next tap on that recipe plays from cache. Returns immediately; the
   * actual Gemini + ElevenLabs work happens in the background. Safe to call
   * repeatedly — getOrGenerate is idempotent and cache-first.
   */
  @Mutation(() => Boolean)
  @UseGuards(ClerkAuthGuard)
  async prewarmNarration(
    @Args('recipeId') recipeId: string,
    @Args('voiceProfileId') voiceProfileId: string,
    @Args('locale', { nullable: true, type: () => String }) locale: string | null,
    @CurrentUser() user: CurrentUserContext,
  ): Promise<boolean> {
    const dbUser = await this.prisma.user.findUnique({ where: { clerkId: user.clerkId } });
    if (!dbUser) return false;
    const effectiveLocale = (locale ?? 'en').split(/[-_]/)[0].toLowerCase();
    // Kick off in background — don't await. Feed can keep moving.
    this.narrationService
      .generateAndCacheNarration(recipeId, voiceProfileId, dbUser.id, effectiveLocale)
      .catch(() => { /* swallow — best-effort pre-warm */ });
    return true;
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

  /**
   * Query: narrationUrl
   *
   * Get cached narration URL with metadata and duration.
   * iOS client calls this to check if audio is cached before deciding
   * whether to trigger REST streaming. Returns null URL if not yet cached.
   */
  @Query(() => NarrationUrlDto)
  @UseGuards(ClerkAuthGuard)
  async narrationUrl(
    @Args('recipeId') recipeId: string,
    @Args('voiceProfileId', { nullable: true, type: () => String }) voiceProfileId: string | null,
    @Args('locale', { nullable: true, type: () => String }) locale: string | null,
    @CurrentUser() user: CurrentUserContext,
  ): Promise<NarrationUrlDto> {
    const effectiveLocale = locale ?? 'en';
    // Find database user from Clerk ID
    const dbUser = await this.prisma.user.findUnique({
      where: { clerkId: user.clerkId },
    });

    if (!dbUser) {
      throw new GraphQLError('User not found', {
        extensions: { code: GraphQLErrorCode.USER_NOT_FOUND },
      });
    }

    // If no voiceProfileId provided, use user's primary (first READY) voice profile
    let profileId = voiceProfileId;
    if (!profileId) {
      const primaryProfile = await this.prisma.voiceProfile.findFirst({
        where: { userId: dbUser.id, status: 'READY' },
        orderBy: { createdAt: 'asc' },
      });

      if (!primaryProfile) {
        throw new GraphQLError('No voice profiles found', {
          extensions: { code: GraphQLErrorCode.VOICE_PROFILE_NOT_FOUND },
        });
      }
      profileId = primaryProfile.id;
    }

    // Load voice profile for metadata (verifies ownership)
    const profile = await this.voiceService.getVoiceProfile(profileId, user.clerkId);

    // Load recipe
    const recipe = await this.prisma.recipe.findUnique({
      where: { id: recipeId },
      select: { id: true, name: true },
    });

    if (!recipe) {
      throw new GraphQLError('Recipe not found', {
        extensions: { code: 'RECIPE_NOT_FOUND' },
      });
    }

    // Normalize locale the same way the service does so the cache lookup keys
    // line up (we cache per language, not per region).
    const normalizedLocale = effectiveLocale.split(/[-_]/)[0].toLowerCase() || 'en';

    // Check for cached narration audio (per recipe+voice+locale)
    let cached = await this.prisma.narrationAudio.findUnique({
      where: {
        recipeId_voiceProfileId_locale: {
          recipeId,
          voiceProfileId: profileId,
          locale: normalizedLocale,
        },
      },
    });

    // If not cached and voice is READY, generate on-demand
    if (!cached && profile.status === 'READY' && profile.elevenLabsVoiceId) {
      try {
        const generated = await this.narrationService.generateAndCacheNarration(
          recipeId,
          profileId,
          dbUser.id,
          normalizedLocale,
        );
        return {
          url: generated.url,
          speakerName: profile.speakerName,
          relationship: profile.relationship,
          recipeName: recipe.name,
          durationMs: generated.durationMs,
        };
      } catch (error) {
        // Generation failed — return null URL, client will fallback to AVSpeech
        return {
          url: null,
          speakerName: profile.speakerName,
          relationship: profile.relationship,
          recipeName: recipe.name,
          durationMs: null,
        };
      }
    }

    return {
      url: cached?.r2Url ?? null,
      speakerName: profile.speakerName,
      relationship: profile.relationship,
      recipeName: recipe.name,
      durationMs: cached?.durationMs ?? null,
    };
  }
}
