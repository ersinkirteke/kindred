import { Module } from '@nestjs/common';
import { ConfigModule } from '../config/config.module';
import { AuthService } from './auth.service';
import { ClerkAuthGuard } from './auth.guard';

/**
 * Authentication module providing Clerk JWT verification.
 *
 * Exports:
 * - AuthService: Token verification and Clerk API access
 * - ClerkAuthGuard: GraphQL guard for protected resolvers
 */
@Module({
  imports: [ConfigModule],
  providers: [AuthService, ClerkAuthGuard],
  exports: [AuthService, ClerkAuthGuard],
})
export class AuthModule {}
