import { Resolver, Query, Args, Float, Int, Context, ResolveField, Parent } from '@nestjs/graphql';
import { FeedService } from './feed.service';
import { RecipeConnection } from './dto/feed-connection.type';
import { RecipeCard } from './dto/recipe-card.type';
import { FeedFiltersInput } from './dto/feed-filters.input';
import { CitySuggestion } from '../geocoding/dto/location.dto';
import { GeocodingService } from '../geocoding/geocoding.service';
import { VelocityScorer } from './utils/velocity-scorer';

@Resolver(() => RecipeCard)
export class FeedResolver {
  constructor(
    private readonly feedService: FeedService,
    private readonly geocoding: GeocodingService,
  ) {}

  /**
   * Main feed query - Location-based recipe feed with velocity ranking
   * FEED-01, FEED-02, FEED-03, FEED-06, FEED-09
   */
  @Query(() => RecipeConnection, {
    description: 'Get location-based recipe feed with velocity ranking and filters',
    complexity: (options) => {
      const first = options.args.first || 20;
      return first * 10 + 50; // 20 items * 10 fields + base cost
    },
  })
  async feed(
    @Args('latitude', { type: () => Float, description: 'User latitude' }) latitude: number,
    @Args('longitude', { type: () => Float, description: 'User longitude' }) longitude: number,
    @Args('first', { type: () => Int, nullable: true, defaultValue: 20, description: 'Number of results to return' }) first: number,
    @Args('after', { type: () => String, nullable: true, description: 'Cursor for pagination' }) after?: string,
    @Args('filters', { type: () => FeedFiltersInput, nullable: true, description: 'Filter by cuisine, meal, dietary tags' }) filters?: FeedFiltersInput,
    @Args('lastFetchedAt', { type: () => String, nullable: true, description: 'ISO timestamp of last fetch for newSinceLastFetch count' }) lastFetchedAt?: string,
    @Context() context?: any,
  ): Promise<RecipeConnection> {
    // Validate coordinates
    if (Math.abs(latitude) > 90) {
      throw new Error(`Invalid latitude: ${latitude}. Must be between -90 and 90.`);
    }
    if (Math.abs(longitude) > 180) {
      throw new Error(`Invalid longitude: ${longitude}. Must be between -180 and 180.`);
    }

    // Validate pagination limit
    const validatedFirst = Math.min(Math.max(first, 1), 50);

    // Call service with filter relaxation support
    let result: RecipeConnection;
    if (filters) {
      result = await this.feedService.getFeedWithFilterRelaxation({
        lat: latitude,
        lng: longitude,
        first: validatedFirst,
        after,
        filters,
        lastFetchedAt,
      });
    } else {
      result = await this.feedService.getFeedWithFallback({
        lat: latitude,
        lng: longitude,
        first: validatedFirst,
        after,
        lastFetchedAt,
      });
    }

    // Set Cache-Control headers for offline-first mobile clients
    // 5 min fresh, 24 hour stale-while-revalidate
    if (context?.res) {
      context.res.setHeader(
        'Cache-Control',
        'public, max-age=300, stale-while-revalidate=86400'
      );

      // Generate ETag based on edge IDs and velocities
      const etag = this.generateETag(result);
      context.res.setHeader('ETag', etag);
    }

    return result;
  }

  /**
   * Reverse geocode - GPS coordinates to city name
   * FEED-07: Location badge display
   */
  @Query(() => String, {
    description: 'Reverse geocode GPS coordinates to city name for location badge',
  })
  async cityName(
    @Args('latitude', { type: () => Float }) latitude: number,
    @Args('longitude', { type: () => Float }) longitude: number,
  ): Promise<string> {
    // Validate coordinates
    if (Math.abs(latitude) > 90 || Math.abs(longitude) > 180) {
      return 'Unknown Location';
    }

    return this.geocoding.reverseGeocode(latitude, longitude);
  }

  /**
   * City search autocomplete
   * FEED-08: Manual location change
   */
  @Query(() => [CitySuggestion], {
    description: 'Search cities by name for manual location change autocomplete',
  })
  async searchCities(
    @Args('query', { type: () => String, description: 'City search query' }) query: string,
    @Args('limit', { type: () => Int, nullable: true, defaultValue: 5, description: 'Number of suggestions' }) limit: number,
  ): Promise<CitySuggestion[]> {
    return this.geocoding.searchCities(query, limit);
  }

  /**
   * Resolve engagementHumanized field on RecipeCard
   * Safety net if accessed via other resolvers (typically pre-computed by FeedService)
   */
  @ResolveField(() => String, {
    description: 'Humanized engagement count with time window',
  })
  engagementHumanized(@Parent() recipe: RecipeCard): string {
    // If already computed, return it
    if (recipe.engagementHumanized) {
      return recipe.engagementHumanized;
    }

    // Compute on the fly
    if (recipe.scrapedAt) {
      const ageHours = (Date.now() - new Date(recipe.scrapedAt).getTime()) / (1000 * 60 * 60);
      return VelocityScorer.humanize(recipe.engagementLoves, ageHours);
    }

    // Fallback
    return `${recipe.engagementLoves} loves`;
  }

  /**
   * Generate ETag for feed response
   */
  private generateETag(connection: RecipeConnection): string {
    const data = connection.edges
      .map((edge) => `${edge.node.id}:${edge.node.velocityScore}`)
      .join(',');
    // Simple hash for ETag - production might use crypto.createHash
    return `"${Buffer.from(data).toString('base64').substring(0, 32)}"`;
  }
}
