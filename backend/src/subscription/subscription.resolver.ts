import { Resolver, Mutation, Args, Query } from '@nestjs/graphql';
import { UseGuards } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { ClerkAuthGuard } from '../auth/auth.guard';
import { CurrentUser, CurrentUserContext } from '../common/decorators/current-user.decorator';
import { SubscriptionService } from './subscription.service';

@Resolver()
export class SubscriptionResolver {
  constructor(private subscriptionService: SubscriptionService) {}

  @Mutation(() => Boolean)
  @UseGuards(ClerkAuthGuard)
  @Throttle({ expensive: { limit: 10, ttl: 60000 } })
  async verifySubscription(
    @Args('jwsRepresentation') jwsRepresentation: string,
    @CurrentUser() user: CurrentUserContext,
  ): Promise<boolean> {
    return this.subscriptionService.verifyAndSyncSubscription(user.clerkId, jwsRepresentation);
  }

  @Query(() => Boolean)
  @UseGuards(ClerkAuthGuard)
  async canCreateVoiceProfile(
    @CurrentUser() user: CurrentUserContext,
  ): Promise<boolean> {
    // Resolve database userId from clerkId
    const dbUserId = await this.subscriptionService.resolveUserId(user.clerkId);
    const result = await this.subscriptionService.checkVoiceSlotLimit(dbUserId);
    return result.allowed;
  }
}
