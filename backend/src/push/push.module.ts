import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { ConfigModule } from '../config/config.module';
import { AuthModule } from '../auth/auth.module';
import { PushService } from './push.service';
import { DeviceTokenResolver } from './device-token.resolver';

/**
 * Push notification module using Firebase Cloud Messaging.
 *
 * Provides:
 * - PushService for sending notifications to iOS (APNs) and Android (FCM)
 * - DeviceTokenResolver for GraphQL mutations (registerDevice, unregisterDevice)
 * - Automatic invalid token cleanup
 */
@Module({
  imports: [PrismaModule, ConfigModule, AuthModule],
  providers: [PushService, DeviceTokenResolver],
  exports: [PushService], // Other modules can use PushService
})
export class PushModule {}
