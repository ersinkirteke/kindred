import { Resolver, Mutation, Args } from '@nestjs/graphql';
import { UseGuards } from '@nestjs/common';
import { ClerkAuthGuard } from '../auth/auth.guard';
import {
  CurrentUser,
  CurrentUserContext,
} from '../common/decorators/current-user.decorator';
import { PushService } from './push.service';
import {
  DeviceToken,
  Platform,
} from '../graphql/models/device-token.model';
import { RegisterDeviceInput } from './dto/register-device.input';
import { PrismaService } from '../prisma/prisma.service';

/**
 * GraphQL resolver for device token management.
 * Handles push notification device registration and unregistration.
 */
@Resolver()
export class DeviceTokenResolver {
  constructor(
    private pushService: PushService,
    private prisma: PrismaService,
  ) {}

  /**
   * Register a device for push notifications.
   * Protected - requires authentication.
   */
  @Mutation(() => DeviceToken)
  @UseGuards(ClerkAuthGuard)
  async registerDevice(
    @CurrentUser() user: CurrentUserContext,
    @Args('input') input: RegisterDeviceInput,
  ): Promise<DeviceToken> {
    // Find the user's database ID from their Clerk ID
    const dbUser = await this.prisma.user.findUnique({
      where: { clerkId: user.clerkId },
    });

    if (!dbUser) {
      throw new Error('User not found');
    }

    const deviceToken = await this.pushService.registerDeviceToken(
      dbUser.id,
      input.token,
      input.platform,
    );

    // Map Prisma Platform enum to GraphQL Platform enum
    return {
      id: deviceToken.id,
      platform: deviceToken.platform as unknown as Platform,
      createdAt: deviceToken.createdAt,
    };
  }

  /**
   * Unregister a device from push notifications.
   * Protected - requires authentication.
   */
  @Mutation(() => Boolean)
  @UseGuards(ClerkAuthGuard)
  async unregisterDevice(
    @CurrentUser() user: CurrentUserContext,
    @Args('token') token: string,
  ): Promise<boolean> {
    try {
      // Verify the token belongs to this user before deleting
      const deviceToken = await this.prisma.deviceToken.findUnique({
        where: { token },
        include: { user: true },
      });

      if (!deviceToken || deviceToken.user.clerkId !== user.clerkId) {
        throw new Error('Device token not found or does not belong to user');
      }

      await this.pushService.removeDeviceToken(token);
      return true;
    } catch (error) {
      throw new Error(`Failed to unregister device: ${error.message}`);
    }
  }
}
