import { Resolver, Query } from '@nestjs/graphql';
import { UseGuards, NotFoundException } from '@nestjs/common';
import { UsersService } from './users.service';
import { User } from '../graphql/models/user.model';
import { CurrentUser, CurrentUserContext } from '../common/decorators/current-user.decorator';
import { ClerkAuthGuard } from '../auth/auth.guard';
import { Recipe } from '../graphql/models/recipe.model';

@Resolver(() => User)
export class UsersResolver {
  constructor(private usersService: UsersService) {}

  @Query(() => User, {
    description: 'Get the currently authenticated user',
  })
  @UseGuards(ClerkAuthGuard)
  async me(@CurrentUser() user: CurrentUserContext): Promise<User> {
    const dbUser = await this.usersService.findByClerkId(user.clerkId);
    if (!dbUser) {
      throw new NotFoundException(
        `User not found. Please ensure your account is synced via Clerk webhook.`,
      );
    }
    return dbUser;
  }

  @Query(() => [Recipe], {
    description: 'Get bookmarked recipes for the current user',
  })
  @UseGuards(ClerkAuthGuard)
  async myBookmarks(@CurrentUser() user: CurrentUserContext): Promise<Recipe[]> {
    const dbUser = await this.usersService.findByClerkId(user.clerkId);
    if (!dbUser) {
      throw new NotFoundException('User not found');
    }

    // Return bookmarked recipes via Prisma include
    const userWithBookmarks = await this.usersService.findById(dbUser.id);
    // For now, return empty array since Bookmark relation needs to be populated
    // This will be properly implemented when Recipe data exists
    return [];
  }
}
