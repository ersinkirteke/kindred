import { Module } from '@nestjs/common';
import { ScheduleModule } from '@nestjs/schedule';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from '../prisma/prisma.module';
import { XApiService } from './x-api.service';
import { InstagramService } from './instagram.service';
import { RecipeParserService } from './recipe-parser.service';

/**
 * Scraping module for automated recipe discovery
 * Orchestrates X API, Instagram (placeholder), and AI parsing
 */
@Module({
  imports: [
    ScheduleModule.forRoot(),
    ConfigModule,
    PrismaModule,
  ],
  providers: [
    XApiService,
    InstagramService,
    RecipeParserService,
    // ScrapingService and ScrapingScheduler will be added in Task 2
  ],
  exports: [
    XApiService,
    InstagramService,
    RecipeParserService,
  ],
})
export class ScrapingModule {}
