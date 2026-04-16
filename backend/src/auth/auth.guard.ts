import { Injectable, CanActivate, ExecutionContext, Logger } from '@nestjs/common';
import { GqlExecutionContext } from '@nestjs/graphql';
import { AuthService } from './auth.service';

/**
 * GraphQL authentication guard using Clerk JWT verification.
 *
 * Apply to resolvers using @UseGuards(ClerkAuthGuard).
 * On success, attaches { clerkId, email } to req.user.
 * On failure, returns false (NestJS converts to 401 Unauthorized).
 *
 * Usage:
 * @Query(() => User)
 * @UseGuards(ClerkAuthGuard)
 * async me(@CurrentUser() user: CurrentUserContext) {
 *   return this.usersService.findByClerkId(user.clerkId);
 * }
 */
@Injectable()
export class ClerkAuthGuard implements CanActivate {
  private readonly logger = new Logger(ClerkAuthGuard.name);

  constructor(private authService: AuthService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    // Support both REST (http) and GraphQL contexts
    let request: any;
    const contextType = context.getType<string>();
    if (contextType === 'http') {
      request = context.switchToHttp().getRequest();
    } else {
      const ctx = GqlExecutionContext.create(context);
      request = ctx.getContext().req;
    }

    // Extract token from Authorization header
    const authHeader = request.headers.authorization;
    if (!authHeader) {
      this.logger.debug('No authorization header found');
      return false;
    }

    const [bearer, token] = authHeader.split(' ');
    if (bearer !== 'Bearer' || !token) {
      this.logger.debug('Invalid authorization header format');
      return false;
    }

    try {
      // Verify token using Clerk SDK
      const payload = await this.authService.verifyToken(token);

      // Attach user to request context
      request.user = {
        clerkId: payload.sub,
        email: payload.email,
      };

      return true;
    } catch (error) {
      this.logger.debug(`Authentication failed: ${error.message}`);
      return false;
    }
  }
}
