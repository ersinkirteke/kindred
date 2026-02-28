import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { RawScrapedPost } from './dto/scraped-recipe.dto';

interface XApiRateLimit {
  remaining: number;
  resetAt: Date;
}

interface XApiTweet {
  id: string;
  text: string;
  author_id?: string;
  created_at?: string;
  public_metrics?: {
    like_count: number;
    retweet_count: number;
    reply_count: number;
  };
  geo?: {
    place_id: string;
  };
}

interface XApiResponse {
  data?: XApiTweet[];
  includes?: {
    users?: Array<{ id: string; username: string }>;
  };
  meta?: {
    result_count: number;
  };
}

@Injectable()
export class XApiService {
  private readonly logger = new Logger(XApiService.name);
  private lastRateLimit?: XApiRateLimit;
  private readonly bearerToken: string;
  private readonly baseUrl = 'https://api.x.com/2';

  constructor(private readonly configService: ConfigService) {
    this.bearerToken = this.configService.get<string>('X_API_BEARER_TOKEN') || '';
  }

  /**
   * Search for recipe-related tweets by location
   * Returns empty array on rate limit or auth errors (graceful degradation)
   */
  async searchRecipeTweets(
    city: string,
    limit: number = 20,
  ): Promise<RawScrapedPost[]> {
    if (!this.bearerToken) {
      this.logger.warn('X API bearer token not configured - skipping X search');
      return [];
    }

    try {
      const query = `(recipe OR cooking OR homemade) place:${city}`;
      const url = new URL(`${this.baseUrl}/tweets/search/recent`);
      url.searchParams.set('query', query);
      url.searchParams.set('max_results', Math.min(limit, 100).toString());
      url.searchParams.set('tweet.fields', 'created_at,public_metrics,geo');
      url.searchParams.set('expansions', 'author_id');
      url.searchParams.set('user.fields', 'username');

      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 10000); // 10s timeout

      const response = await fetch(url.toString(), {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${this.bearerToken}`,
          'Content-Type': 'application/json',
        },
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      // Handle rate limiting gracefully
      if (response.status === 429) {
        const resetTime = response.headers.get('x-rate-limit-reset');
        const resetAt = resetTime
          ? new Date(parseInt(resetTime) * 1000)
          : new Date(Date.now() + 15 * 60 * 1000); // default 15 min
        this.lastRateLimit = {
          remaining: 0,
          resetAt,
        };
        this.logger.warn(
          `X API rate limit exceeded. Resets at ${resetAt.toISOString()}`,
        );
        return [];
      }

      // Handle auth errors gracefully
      if (response.status === 401 || response.status === 403) {
        this.logger.error(
          `X API authentication failed (${response.status}). Check X_API_BEARER_TOKEN`,
        );
        return [];
      }

      if (!response.ok) {
        this.logger.error(
          `X API request failed: ${response.status} ${response.statusText}`,
        );
        return [];
      }

      // Update rate limit info from headers
      const remaining = response.headers.get('x-rate-limit-remaining');
      const reset = response.headers.get('x-rate-limit-reset');
      if (remaining && reset) {
        this.lastRateLimit = {
          remaining: parseInt(remaining),
          resetAt: new Date(parseInt(reset) * 1000),
        };
      }

      const data: XApiResponse = await response.json();

      if (!data.data || data.data.length === 0) {
        this.logger.log(`No tweets found for city: ${city}`);
        return [];
      }

      // Build username lookup map
      const userMap = new Map<string, string>();
      if (data.includes?.users) {
        for (const user of data.includes.users) {
          userMap.set(user.id, user.username);
        }
      }

      // Map to RawScrapedPost
      const posts: RawScrapedPost[] = data.data.map((tweet) => {
        const engagement =
          (tweet.public_metrics?.like_count || 0) +
          (tweet.public_metrics?.retweet_count || 0) * 2 + // retweets count more
          (tweet.public_metrics?.reply_count || 0);

        return {
          sourceId: `x-${tweet.id}`,
          platform: 'x',
          text: tweet.text,
          authorHandle: tweet.author_id
            ? userMap.get(tweet.author_id) || 'unknown'
            : 'unknown',
          location: city,
          engagementCount: engagement,
          postedAt: tweet.created_at
            ? new Date(tweet.created_at)
            : new Date(),
        };
      });

      this.logger.log(
        `Found ${posts.length} recipe tweets for city: ${city}`,
      );
      return posts;
    } catch (error) {
      if (error instanceof Error && error.name === 'AbortError') {
        this.logger.warn('X API request timed out after 10 seconds');
      } else {
        this.logger.error(
          `X API search failed: ${error instanceof Error ? error.message : 'Unknown error'}`,
        );
      }
      return [];
    }
  }

  /**
   * Check remaining quota from last request
   */
  async checkQuotaRemaining(): Promise<{ remaining: number; resetAt: Date }> {
    if (!this.lastRateLimit) {
      return {
        remaining: -1, // unknown
        resetAt: new Date(),
      };
    }
    return this.lastRateLimit;
  }
}
