import { Resolver, Query } from '@nestjs/graphql';
import { UsersService } from './users.service';
import { User } from '../graphql/models/user.model';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Resolver(() => User)
export class UsersResolver {
  constructor(private usersService: UsersService) {}

  @Query(() => User, {
    nullable: true,
    description: 'Get the currently authenticated user (placeholder - auth in Plan 02)',
  })
  async me(@CurrentUser() user: any): Promise<User | null> {
    // This is a placeholder. Auth guard will be implemented in Plan 02.
    // For now, returns null if no user in context.
    if (!user?.clerkId) {
      return null;
    }
    return this.usersService.findByClerkId(user.clerkId);
  }
}
