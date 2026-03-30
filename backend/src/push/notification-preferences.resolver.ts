import { Resolver, Query, Mutation, Args, ObjectType, Field } from '@nestjs/graphql';
import { UseGuards } from '@nestjs/common';
import { ClerkAuthGuard } from '../auth/auth.guard';
import {
  CurrentUser,
  CurrentUserContext,
} from '../common/decorators/current-user.decorator';
import { PrismaService } from '../prisma/prisma.service';

/**
 * GraphQL DTO for notification preferences.
 */
@ObjectType()
class NotificationPreferencesDto {
  @Field(() => Boolean)
  expiryAlerts: boolean;

  @Field(() => Boolean)
  voiceReady: boolean;

  @Field(() => Boolean)
  engagement: boolean;
}

/**
 * GraphQL resolver for user notification preferences.
 *
 * Users can query and update their per-category notification opt-in/opt-out settings.
 * All categories default to enabled (true) if no preferences record exists.
 *
 * Phase 19-03: Production Hardening - Push Notification Preferences
 */
@Resolver()
export class NotificationPreferencesResolver {
  constructor(private prisma: PrismaService) {}

  /**
   * Get current user's notification preferences.
   * Creates default record (all enabled) if none exists.
   */
  @Query(() => NotificationPreferencesDto)
  @UseGuards(ClerkAuthGuard)
  async myNotificationPreferences(
    @CurrentUser() user: CurrentUserContext,
  ): Promise<NotificationPreferencesDto> {
    const dbUser = await this.prisma.user.findUnique({
      where: { clerkId: user.clerkId },
    });

    if (!dbUser) {
      throw new Error('User not found');
    }

    // Return existing or create with defaults (all enabled)
    const prefs = await this.prisma.notificationPreferences.upsert({
      where: { userId: dbUser.id },
      create: { userId: dbUser.id },
      update: {},
    });

    return prefs;
  }

  /**
   * Update current user's notification preferences.
   * All parameters are optional — only provided values are updated.
   */
  @Mutation(() => NotificationPreferencesDto)
  @UseGuards(ClerkAuthGuard)
  async updateNotificationPreferences(
    @CurrentUser() user: CurrentUserContext,
    @Args('expiryAlerts', { nullable: true }) expiryAlerts?: boolean,
    @Args('voiceReady', { nullable: true }) voiceReady?: boolean,
    @Args('engagement', { nullable: true }) engagement?: boolean,
  ): Promise<NotificationPreferencesDto> {
    const dbUser = await this.prisma.user.findUnique({
      where: { clerkId: user.clerkId },
    });

    if (!dbUser) {
      throw new Error('User not found');
    }

    const data: any = {};
    if (expiryAlerts !== undefined) data.expiryAlerts = expiryAlerts;
    if (voiceReady !== undefined) data.voiceReady = voiceReady;
    if (engagement !== undefined) data.engagement = engagement;

    return this.prisma.notificationPreferences.upsert({
      where: { userId: dbUser.id },
      create: { userId: dbUser.id, ...data },
      update: data,
    });
  }
}
