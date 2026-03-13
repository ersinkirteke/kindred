import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ScanService } from './scan.service';
import { ScanResolver } from './scan.resolver';
import { ScanAnalyzerService } from './scan-analyzer.service';
import { ImagesModule } from '../images/images.module';
import { PrismaModule } from '../prisma/prisma.module';
import { PantryModule } from '../pantry/pantry.module';

/**
 * Scan Module
 *
 * Provides pantry scan photo upload and processing functionality.
 *
 * Phase 14-01: Basic upload to R2
 * Phase 15-01: AI-powered ingredient detection with Gemini Vision
 */
@Module({
  imports: [ConfigModule, ImagesModule, PrismaModule, PantryModule],
  providers: [ScanService, ScanResolver, ScanAnalyzerService],
  exports: [ScanService],
})
export class ScanModule {}
