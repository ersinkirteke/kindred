import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { R2StorageService } from './r2-storage.service';

/**
 * Images Module
 *
 * Provides Cloudflare R2 storage for CDN delivery.
 * Used by VoiceModule for voice file uploads.
 *
 * Exported services:
 * - R2StorageService: Upload/download files to Cloudflare R2
 */
@Module({
  imports: [ConfigModule],
  providers: [R2StorageService],
  exports: [R2StorageService],
})
export class ImagesModule {}
