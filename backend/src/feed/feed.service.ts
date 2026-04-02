import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { GeocodingService } from '../geocoding/geocoding.service';
import { RecipeCard } from './dto/recipe-card.type';
import { RecipeConnection, RecipeCardEdge, PageInfo } from './dto/feed-connection.type';
import { FeedFiltersInput } from './dto/feed-filters.input';
import { VelocityScorer } from './utils/velocity-scorer';
import { Prisma } from '@prisma/client';

interface GetFeedParams {
  lat: number;
  lng: number;
  radiusMiles?: number;
  first?: number;
  after?: string;
  filters?: FeedFiltersInput;
  lastFetchedAt?: string;
}

interface CursorData {
  id: string;
  velocity: number;
}

@Injectable()
export class FeedService {
  private readonly logger = new Logger(FeedService.name);
  private readonly METERS_PER_MILE = 1609.34;

  constructor(
    private readonly prisma: PrismaService,
    private readonly geocoding: GeocodingService,
  ) {}

  /**
   * Main feed query with PostGIS spatial filtering
   */
  async getFeed(params: GetFeedParams): Promise<RecipeConnection> {
    const {
      lat,
      lng,
      radiusMiles = 10,
      first = 20,
      after,
      filters,
      lastFetchedAt,
    } = params;

    // Validate coordinates
    if (Math.abs(lat) > 90 || Math.abs(lng) > 180) {
      throw new Error(`Invalid coordinates: lat=${lat}, lng=${lng}`);
    }

    // Validate pagination limit
    const limit = Math.min(Math.max(first, 1), 50);
    const radiusMeters = radiusMiles * this.METERS_PER_MILE;

    // Build filter clause
    const filterConditions = this.buildFilterClause(filters);

    // Build cursor condition
    let cursorCondition = '';
    if (after) {
      try {
        const cursor = this.decodeCursor(after);
        // Validate cursor values to prevent SQL injection
        const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
        if (!UUID_REGEX.test(cursor.id)) {
          throw new Error('Invalid cursor id format');
        }
        if (typeof cursor.velocity !== 'number' || !isFinite(cursor.velocity)) {
          throw new Error('Invalid cursor velocity');
        }
        // Safe: cursor.id validated as UUID, cursor.velocity validated as finite number
        cursorCondition = `AND ("velocityScore" < ${cursor.velocity} OR ("velocityScore" = ${cursor.velocity} AND id > '${cursor.id}'))`;
      } catch (error) {
        this.logger.warn(`Invalid cursor: ${after}`);
        // Continue without cursor if invalid
      }
    }

    // Execute PostGIS query
    // ST_MakePoint(longitude, latitude) - LONGITUDE FIRST!
    const query = Prisma.sql`
      SELECT
        id, name, "imageUrl", "imageStatus", "prepTime", calories,
        "engagementLoves", "isViral", "cuisineType", "mealType", "velocityScore",
        "scrapedAt",
        ST_Distance(
          ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography,
          ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)::geography
        ) / ${this.METERS_PER_MILE} as "distanceMiles"
      FROM "Recipe"
      WHERE ST_DWithin(
        ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography,
        ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)::geography,
        ${radiusMeters}
      )
      AND latitude IS NOT NULL
      AND longitude IS NOT NULL
      AND "scrapedAt" > NOW() - INTERVAL '7 days'
      ${filterConditions ? Prisma.raw(filterConditions) : Prisma.empty}
      ${cursorCondition ? Prisma.raw(cursorCondition) : Prisma.empty}
      ORDER BY "velocityScore" DESC, id ASC
      LIMIT ${limit + 1}
    `;

    let recipes: any[];
    try {
      recipes = await this.prisma.$queryRaw(query);
    } catch (error) {
      this.logger.error(`PostGIS query failed: ${error.message}`, error.stack);

      // Fall back to basic Prisma query without PostGIS
      this.logger.warn('Falling back to non-spatial query');
      recipes = await this.prisma.recipe.findMany({
        where: {
          latitude: { not: null },
          longitude: { not: null },
          scrapedAt: { gt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) },
        },
        orderBy: [{ velocityScore: 'desc' }, { id: 'asc' }],
        take: limit + 1,
      });
    }

    // Determine hasNextPage
    const hasNextPage = recipes.length > limit;
    const edges = recipes.slice(0, limit);

    // Count new recipes since last fetch
    let newSinceLastFetch: number | undefined;
    if (lastFetchedAt) {
      try {
        const lastFetchDate = new Date(lastFetchedAt);
        const countQuery = Prisma.sql`
          SELECT COUNT(*)::int as count
          FROM "Recipe"
          WHERE ST_DWithin(
            ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography,
            ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)::geography,
            ${radiusMeters}
          )
          AND latitude IS NOT NULL
          AND longitude IS NOT NULL
          AND "scrapedAt" > ${lastFetchDate}
        `;
        const result: any = await this.prisma.$queryRaw(countQuery);
        newSinceLastFetch = result[0]?.count || 0;
      } catch (error) {
        this.logger.warn(`Failed to count new recipes: ${error.message}`);
      }
    }

    // Get total count in radius
    let totalCount = edges.length;
    try {
      const countQuery = Prisma.sql`
        SELECT COUNT(*)::int as count
        FROM "Recipe"
        WHERE ST_DWithin(
          ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography,
          ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)::geography,
          ${radiusMeters}
        )
        AND latitude IS NOT NULL
        AND longitude IS NOT NULL
        AND "scrapedAt" > NOW() - INTERVAL '7 days'
        ${filterConditions ? Prisma.raw(filterConditions) : Prisma.empty}
      `;
      const result: any = await this.prisma.$queryRaw(countQuery);
      totalCount = result[0]?.count || edges.length;
    } catch (error) {
      this.logger.warn(`Failed to get total count: ${error.message}`);
    }

    // Build connection
    const recipeEdges: RecipeCardEdge[] = edges.map((recipe) => {
      const ageHours = (Date.now() - new Date(recipe.scrapedAt).getTime()) / (1000 * 60 * 60);
      const engagementHumanized = VelocityScorer.humanize(recipe.engagementLoves, ageHours);

      const card: RecipeCard = {
        id: recipe.id,
        name: recipe.name,
        imageUrl: recipe.imageUrl,
        imageStatus: recipe.imageStatus as any,
        prepTime: recipe.prepTime,
        calories: recipe.calories,
        engagementLoves: recipe.engagementLoves,
        engagementHumanized,
        isViral: recipe.isViral,
        cuisineType: recipe.cuisineType as any,
        mealType: recipe.mealType as any,
        velocityScore: recipe.velocityScore,
        distanceMiles: recipe.distanceMiles,
        scrapedAt: recipe.scrapedAt,
      };

      return {
        node: card,
        cursor: this.encodeCursor({ id: recipe.id, velocity: recipe.velocityScore }),
      };
    });

    const pageInfo: PageInfo = {
      hasNextPage,
      hasPreviousPage: false, // Forward-only pagination
      startCursor: recipeEdges[0]?.cursor || null,
      endCursor: recipeEdges[recipeEdges.length - 1]?.cursor || null,
    };

    return {
      edges: recipeEdges,
      pageInfo,
      totalCount,
      lastRefreshed: new Date().toISOString(),
      newSinceLastFetch,
    };
  }

  /**
   * Feed query with expanded radius fallback (never empty)
   */
  async getFeedWithFallback(params: GetFeedParams): Promise<RecipeConnection> {
    // Try with user's radius first
    let result = await this.getFeed(params);

    if (result.edges.length === 0) {
      this.logger.log(`Zero results at ${params.radiusMiles || 10} miles, expanding to city-level (50 miles)`);

      // Expand to city-level (50 miles)
      result = await this.getFeed({ ...params, radiusMiles: 50 });

      if (result.edges.length > 0) {
        result.expandedFrom = 'city';
        result.expandedTo = null;
        return result;
      }

      this.logger.log('Zero results at city-level, expanding to country-level (500 miles)');

      // Expand to country-level (500 miles)
      result = await this.getFeed({ ...params, radiusMiles: 500 });

      if (result.edges.length > 0) {
        result.expandedFrom = 'city';
        result.expandedTo = 'country';
        return result;
      }

      this.logger.log('Zero results at country-level, expanding to global');

      // Global fallback - get most recent viral recipes anywhere
      const recipes = await this.prisma.recipe.findMany({
        where: {
          latitude: { not: null },
          longitude: { not: null },
          scrapedAt: { gt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) },
        },
        orderBy: [{ velocityScore: 'desc' }, { id: 'asc' }],
        take: params.first || 20,
      });

      const recipeEdges: RecipeCardEdge[] = recipes.map((recipe) => {
        const ageHours = (Date.now() - new Date(recipe.scrapedAt).getTime()) / (1000 * 60 * 60);
        const engagementHumanized = VelocityScorer.humanize(recipe.engagementLoves, ageHours);

        const card: RecipeCard = {
          id: recipe.id,
          name: recipe.name,
          imageUrl: recipe.imageUrl,
          imageStatus: recipe.imageStatus as any,
          prepTime: recipe.prepTime,
          calories: recipe.calories,
          engagementLoves: recipe.engagementLoves,
          engagementHumanized,
          isViral: recipe.isViral,
          cuisineType: recipe.cuisineType as any,
          mealType: recipe.mealType as any,
          velocityScore: recipe.velocityScore,
          distanceMiles: null, // No distance for global results
          scrapedAt: recipe.scrapedAt,
        };

        return {
          node: card,
          cursor: this.encodeCursor({ id: recipe.id, velocity: recipe.velocityScore }),
        };
      });

      result = {
        edges: recipeEdges,
        pageInfo: {
          hasNextPage: recipes.length >= (params.first || 20),
          hasPreviousPage: false,
          startCursor: recipeEdges[0]?.cursor || null,
          endCursor: recipeEdges[recipeEdges.length - 1]?.cursor || null,
        },
        totalCount: recipeEdges.length,
        lastRefreshed: new Date().toISOString(),
        expandedFrom: 'city',
        expandedTo: 'global',
      };
    }

    return result;
  }

  /**
   * Feed query with filter relaxation for zero-result queries
   */
  async getFeedWithFilterRelaxation(params: GetFeedParams): Promise<RecipeConnection> {
    if (!params.filters) {
      return this.getFeedWithFallback(params);
    }

    // Try with all filters
    let result = await this.getFeedWithFallback(params);

    if (result.edges.length > 0) {
      return result;
    }

    // Progressive filter relaxation
    const filtersRelaxed: string[] = [];

    // 1. Drop dietaryTags (most restrictive)
    if (params.filters.dietaryTags && params.filters.dietaryTags.length > 0) {
      filtersRelaxed.push(...params.filters.dietaryTags);
      result = await this.getFeedWithFallback({
        ...params,
        filters: {
          ...params.filters,
          dietaryTags: undefined,
        },
      });

      if (result.edges.length > 0) {
        result.partialMatch = true;
        result.filtersRelaxed = filtersRelaxed;
        return result;
      }
    }

    // 2. Drop mealTypes
    if (params.filters.mealTypes && params.filters.mealTypes.length > 0) {
      filtersRelaxed.push('mealTypes');
      result = await this.getFeedWithFallback({
        ...params,
        filters: {
          ...params.filters,
          dietaryTags: undefined,
          mealTypes: undefined,
        },
      });

      if (result.edges.length > 0) {
        result.partialMatch = true;
        result.filtersRelaxed = filtersRelaxed;
        return result;
      }
    }

    // 3. Drop cuisineTypes
    if (params.filters.cuisineTypes && params.filters.cuisineTypes.length > 0) {
      filtersRelaxed.push('cuisineTypes');
      result = await this.getFeedWithFallback({
        ...params,
        filters: undefined,
      });

      if (result.edges.length > 0) {
        result.partialMatch = true;
        result.filtersRelaxed = filtersRelaxed;
        return result;
      }
    }

    // If still nothing, return unfiltered results
    return this.getFeedWithFallback({ ...params, filters: undefined });
  }

  /**
   * Build SQL filter clause from FeedFiltersInput
   */
  // Valid enum values for SQL injection prevention
  private static readonly VALID_CUISINE_TYPES = new Set([
    'ITALIAN', 'CHINESE', 'INDIAN', 'JAPANESE', 'MEXICAN', 'THAI', 'FRENCH',
    'SPANISH', 'GREEK', 'KOREAN', 'VIETNAMESE', 'TURKISH', 'LEBANESE',
    'MOROCCAN', 'ETHIOPIAN', 'BRAZILIAN', 'PERUVIAN', 'CARIBBEAN',
    'AMERICAN', 'BRITISH', 'GERMAN', 'RUSSIAN', 'POLISH', 'IRISH',
    'AUSTRALIAN', 'FILIPINO', 'INDONESIAN', 'MALAYSIAN', 'OTHER',
  ]);

  private static readonly VALID_MEAL_TYPES = new Set([
    'BREAKFAST', 'LUNCH', 'DINNER', 'SNACK', 'DESSERT', 'APPETIZER', 'DRINK',
  ]);

  // Strict pattern for dietary tags: only letters, numbers, spaces, hyphens
  private static readonly SAFE_TAG_REGEX = /^[a-zA-Z0-9 -]{1,50}$/;

  private buildFilterClause(filters?: FeedFiltersInput): string {
    if (!filters) return '';

    const conditions: string[] = [];

    // CuisineTypes: validate against enum whitelist to prevent SQL injection
    if (filters.cuisineTypes && filters.cuisineTypes.length > 0) {
      const validCuisines = filters.cuisineTypes.filter(c => FeedService.VALID_CUISINE_TYPES.has(c));
      if (validCuisines.length > 0) {
        const cuisines = validCuisines.map(c => `'${c}'`).join(',');
        conditions.push(`"cuisineType" = ANY(ARRAY[${cuisines}]::"CuisineType"[])`);
      }
    }

    // MealTypes: validate against enum whitelist to prevent SQL injection
    if (filters.mealTypes && filters.mealTypes.length > 0) {
      const validMeals = filters.mealTypes.filter(m => FeedService.VALID_MEAL_TYPES.has(m));
      if (validMeals.length > 0) {
        const meals = validMeals.map(m => `'${m}'`).join(',');
        conditions.push(`"mealType" = ANY(ARRAY[${meals}]::"MealType"[])`);
      }
    }

    // DietaryTags: strict regex validation to prevent SQL injection (free-form strings)
    if (filters.dietaryTags && filters.dietaryTags.length > 0) {
      const validTags = filters.dietaryTags.filter(t => FeedService.SAFE_TAG_REGEX.test(t));
      if (validTags.length > 0) {
        const tags = validTags.map(t => `'${t}'`).join(',');
        conditions.push(`"dietaryTags" @> ARRAY[${tags}]::text[]`);
      }
    }

    // Combine across categories with AND
    return conditions.length > 0 ? 'AND ' + conditions.join(' AND ') : '';
  }

  /**
   * Encode cursor for pagination
   */
  private encodeCursor(data: CursorData): string {
    return Buffer.from(JSON.stringify(data)).toString('base64');
  }

  /**
   * Decode cursor from pagination
   */
  private decodeCursor(cursor: string): CursorData {
    const json = Buffer.from(cursor, 'base64').toString('utf-8');
    return JSON.parse(json);
  }
}
