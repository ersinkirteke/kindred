import { Resolver, Mutation, Args, Query } from '@nestjs/graphql';
import { SubscriptionService } from './subscription.service';
// import { UseGuards } from '@nestjs/common';
// import { JwtAuthGuard } from '../auth/jwt-auth.guard';
// import { CurrentUser } from '../auth/current-user.decorator';

@Resolver()
export class SubscriptionResolver {
  constructor(private subscriptionService: SubscriptionService) {}

  @Mutation(() => Boolean)
  // @UseGuards(JwtAuthGuard)
  async verifySubscription(
    @Args('jwsRepresentation') jwsRepresentation: string,
    // @CurrentUser() user: { id: string },
  ): Promise<boolean> {
    // TODO: Uncomment auth guard and CurrentUser decorator for production
    const userId = 'placeholder-user-id'; // Replace with user.id
    return this.subscriptionService.verifyAndSyncSubscription(userId, jwsRepresentation);
  }

  @Query(() => Boolean)
  // @UseGuards(JwtAuthGuard)
  async canCreateVoiceProfile(
    // @CurrentUser() user: { id: string },
  ): Promise<boolean> {
    const userId = 'placeholder-user-id'; // Replace with user.id
    const result = await this.subscriptionService.checkVoiceSlotLimit(userId);
    return result.allowed;
  }
}
