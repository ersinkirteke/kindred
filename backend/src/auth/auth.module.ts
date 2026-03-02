import { Global, Module } from '@nestjs/common';
import { ConfigModule } from '../config/config.module';
import { UsersModule } from '../users/users.module';
import { AuthService } from './auth.service';
import { ClerkAuthGuard } from './auth.guard';
import { ClerkWebhookController } from './clerk-webhook.controller';

/**
 * Authentication module providing Clerk JWT verification and webhook handling.
 *
 * Exports:
 * - AuthService: Token verification and Clerk API access
 * - ClerkAuthGuard: GraphQL guard for protected resolvers
 *
 * Controllers:
 * - ClerkWebhookController: REST endpoint for user sync webhooks
 */
@Global()
@Module({
  imports: [ConfigModule, UsersModule],
  controllers: [ClerkWebhookController],
  providers: [AuthService, ClerkAuthGuard],
  exports: [AuthService, ClerkAuthGuard],
})
export class AuthModule {}
