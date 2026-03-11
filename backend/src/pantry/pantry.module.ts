import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { PantryService } from './pantry.service';
import { PantryResolver } from './pantry.resolver';

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
 */
@Module({
  imports: [PrismaModule],
  providers: [PantryService, PantryResolver],
  exports: [PantryService],
})
export class PantryModule {}
