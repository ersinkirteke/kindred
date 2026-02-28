import { Injectable, Logger } from '@nestjs/common';
import { RawScrapedPost } from './dto/scraped-recipe.dto';

/**
 * Placeholder service for Instagram Partner API integration
 *
 * Instagram requires Partner Program approval (SociaVault/Phyllo).
 * This service is intentionally a stub to allow the pipeline to work
 * with X API only, then seamlessly add Instagram later.
 *
 * TODO: Integrate Instagram Partner API when partnership is established
 * - Apply for Instagram Partner Program
 * - Choose partner (SociaVault or Phyllo based on pricing)
 * - Implement searchRecipePosts with partner API client
 * - Add rate limiting and auth handling
 */
@Injectable()
export class InstagramService {
  private readonly logger = new Logger(InstagramService.name);

  /**
   * Search for recipe posts on Instagram by location
   * Currently returns empty array - partner API integration pending
   */
  async searchRecipePosts(
    city: string,
    limit: number = 20,
  ): Promise<RawScrapedPost[]> {
    this.logger.log(
      'Instagram scraping not yet configured -- skipping. Partner API integration pending.',
    );

    // TODO: When partner API is integrated:
    // 1. Call partner API (SociaVault/Phyllo) with location filter
    // 2. Search for posts with hashtags: #recipe #cooking #homemade
    // 3. Filter by engagement metrics (likes + comments)
    // 4. Map response to RawScrapedPost format
    // 5. Return posts array

    return [];
  }
}
