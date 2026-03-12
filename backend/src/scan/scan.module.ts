import { Module } from '@nestjs/common';
import { ScanService } from './scan.service';
import { ScanResolver } from './scan.resolver';
import { ImagesModule } from '../images/images.module';

/**
 * Scan Module
 *
 * Provides pantry scan photo upload and processing functionality.
 *
 * Phase 14-01: Basic upload to R2
 * Phase 15: AI-powered ingredient detection with Gemini Vision
 */
@Module({
  imports: [ImagesModule],
  providers: [ScanService, ScanResolver],
  exports: [ScanService],
})
export class ScanModule {}
