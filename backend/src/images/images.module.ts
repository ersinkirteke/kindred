import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from '../prisma/prisma.module';
import { ImagesService } from './images.service';
import { R2StorageService } from './r2-storage.service';
import { ImageGenerationProcessor } from './image-generation.processor';

/**
 * Images Module
 *
 * Provides AI-powered hero image generation using Imagen 4 Fast
 * and Cloudflare R2 storage for CDN delivery.
 *
 * Exported services:
 * - ImagesService: Used by scraping module to queue image generation
 * - ImageGenerationProcessor: Background queue processor
 */
@Module({
  imports: [ConfigModule, PrismaModule],
  providers: [ImagesService, R2StorageService, ImageGenerationProcessor],
  exports: [ImagesService, ImageGenerationProcessor, R2StorageService],
})
export class ImagesModule {}
