import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { GqlExecutionContext } from '@nestjs/graphql';

export interface CurrentUserContext {
  clerkId: string;
  email?: string;
}

/**
 * Custom parameter decorator to extract the current user from GraphQL context.
 * User is populated by the auth guard (to be implemented in Plan 02).
 *
 * Usage in resolvers:
 * @Query()
 * async me(@CurrentUser() user: CurrentUserContext) {
 *   return this.usersService.findByClerkId(user.clerkId);
 * }
 */
export const CurrentUser = createParamDecorator(
  (data: unknown, context: ExecutionContext): CurrentUserContext | null => {
    const ctx = GqlExecutionContext.create(context);
    const request = ctx.getContext().req;
    return request.user || null;
  },
);
