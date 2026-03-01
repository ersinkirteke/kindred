import { Module } from '@nestjs/common';
import { ScheduleModule } from '@nestjs/schedule';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from '../prisma/prisma.module';
import { ImagesModule } from '../images/images.module';
import { GeocodingModule } from '../geocoding/geocoding.module';
import { XApiService } from './x-api.service';
import { InstagramService } from './instagram.service';
import { RecipeParserService } from './recipe-parser.service';
import { ScrapingService } from './scraping.service';
import { ScrapingScheduler } from './scraping.scheduler';

/**
 * Scraping module for automated recipe discovery
 * Orchestrates X API, Instagram (placeholder), AI parsing, and image generation
 * Runs scheduled scraping 4 times per day
 */
@Module({
  imports: [
    ScheduleModule.forRoot(),
    ConfigModule,
    PrismaModule,
    ImagesModule,
    GeocodingModule,
  ],
  providers: [
    XApiService,
    InstagramService,
    RecipeParserService,
    ScrapingService,
    ScrapingScheduler,
  ],
  exports: [
    XApiService,
    InstagramService,
    RecipeParserService,
    ScrapingService,
    ScrapingScheduler,
  ],
})
export class ScrapingModule {}
