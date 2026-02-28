import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { ConfigService } from '@nestjs/config';
import { ScrapingService } from './scraping.service';

/**
 * Scheduled scraping jobs
 * Runs recipe discovery pipeline 4 times per day
 */
@Injectable()
export class ScrapingScheduler {
  private readonly logger = new Logger(ScrapingScheduler.name);
  private readonly targetCities: string[];

  constructor(
    private readonly scrapingService: ScrapingService,
    private readonly configService: ConfigService,
  ) {
    // Parse target cities from env var
    const citiesEnv = this.configService.get<string>('SCRAPING_TARGET_CITIES');
    this.targetCities = citiesEnv
      ? citiesEnv.split(',').map((city) => city.trim())
      : ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix'];

    this.logger.log(
      `Scraping scheduler initialized with cities: ${this.targetCities.join(', ')}`,
    );
  }

  /**
   * Morning scrape - 8:00 AM UTC (3:00 AM EST, 12:00 AM PST)
   */
  @Cron('0 8 * * *', {
    name: 'morning-scrape',
    timeZone: 'UTC',
  })
  async handleMorningScrape() {
    this.logger.log('Starting morning scrape cycle (8:00 AM UTC)');
    await this.runScrapeCycle('morning');
  }

  /**
   * Midday scrape - 12:00 PM UTC (7:00 AM EST, 4:00 AM PST)
   */
  @Cron('0 12 * * *', {
    name: 'midday-scrape',
    timeZone: 'UTC',
  })
  async handleMiddayScrape() {
    this.logger.log('Starting midday scrape cycle (12:00 PM UTC)');
    await this.runScrapeCycle('midday');
  }

  /**
   * Evening scrape - 6:00 PM UTC (1:00 PM EST, 10:00 AM PST)
   */
  @Cron('0 18 * * *', {
    name: 'evening-scrape',
    timeZone: 'UTC',
  })
  async handleEveningScrape() {
    this.logger.log('Starting evening scrape cycle (6:00 PM UTC)');
    await this.runScrapeCycle('evening');
  }

  /**
   * Night scrape - 9:00 PM UTC (4:00 PM EST, 1:00 PM PST)
   */
  @Cron('0 21 * * *', {
    name: 'night-scrape',
    timeZone: 'UTC',
  })
  async handleNightScrape() {
    this.logger.log('Starting night scrape cycle (9:00 PM UTC)');
    await this.runScrapeCycle('night');
  }

  /**
   * Manual trigger for testing/admin use
   * Can be called from admin API or CLI
   */
  async triggerScrape(city?: string): Promise<void> {
    this.logger.log(
      `Manual scrape triggered${city ? ` for city: ${city}` : ' for all cities'}`,
    );

    if (city) {
      await this.scrapingService.scrapeWithFallback(city);
    } else {
      await this.runScrapeCycle('manual');
    }
  }

  /**
   * Run full scrape cycle for all target cities
   */
  private async runScrapeCycle(cycleName: string): Promise<void> {
    const startTime = Date.now();
    this.logger.log(
      `${cycleName} cycle started for ${this.targetCities.length} cities`,
    );

    let successCount = 0;
    let errorCount = 0;

    for (const city of this.targetCities) {
      try {
        await this.scrapingService.scrapeWithFallback(city);
        successCount++;
      } catch (error) {
        errorCount++;
        this.logger.error(
          `Failed to scrape ${city}: ${error instanceof Error ? error.message : 'Unknown error'}`,
        );
      }
    }

    const duration = ((Date.now() - startTime) / 1000).toFixed(2);
    this.logger.log(
      `${cycleName} cycle complete: ${successCount} successful, ${errorCount} errors, ${duration}s elapsed`,
    );
  }
}
