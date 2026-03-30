import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from '../prisma/prisma.module';
import { PushModule } from '../push/push.module';
import { PantryService } from './pantry.service';
import { PantryResolver } from './pantry.resolver';
import { ExpiryEstimatorService } from './expiry-estimator.service';
import { ExpiryNotificationScheduler } from './expiry-notification.scheduler';
import { EngagementNotificationScheduler } from './engagement-notification.scheduler';

/**
 * PantryModule
 *
 * Manages pantry inventory with server-side ingredient normalization.
 * Provides GraphQL API for CRUD operations and bilingual ingredient search.
 *
 * Features:
 * - Server-side normalization via IngredientCatalog (200+ bilingual entries)
 * - Duplicate detection and quantity merging
 * - Accept-and-learn for unknown ingredients
 * - Bulk operations for receipt scanning
 * - AI-powered expiry date estimation (catalog + Gemini fallback)
 * - Daily expiry digest notifications at 8 AM UTC
 * - Daily engagement nudge notifications at 10 AM UTC
 */
@Module({
  imports: [PrismaModule, PushModule, ConfigModule],
  providers: [
    PantryService,
    PantryResolver,
    ExpiryEstimatorService,
    ExpiryNotificationScheduler,
    EngagementNotificationScheduler,
  ],
  exports: [PantryService],
})
export class PantryModule {}
