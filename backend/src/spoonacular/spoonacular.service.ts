import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import {
  SearchFilters,
  SpoonacularRecipe,
  SpoonacularSearchResponse,
} from './dto/spoonacular-recipe.dto';
import { firstValueFrom } from 'rxjs';

@Injectable()
export class SpoonacularService {
  private readonly logger = new Logger(SpoonacularService.name);
  private consecutiveFailures = 0;
  private circuitOpenUntil: Date | null = null;
  private lastRequestTime: number | null = null;

  constructor(
    private readonly httpService: HttpService,
    private readonly prismaService: PrismaService,
    private readonly configService: ConfigService,
  ) {}

  async search(
    query: string,
    filters: SearchFilters,
    number: number,
    offset: number,
  ): Promise<SpoonacularRecipe[]> {
    const apiKey = this.configService.get<string>('SPOONACULAR_API_KEY');
    if (!apiKey) {
      throw new Error('SPOONACULAR_API_KEY not configured');
    }

    // Calculate point cost: 1 + 0.01*results + 0.025*results (with addRecipeInformation)
    const estimatedPointCost = 1 + number * (0.01 + 0.025);

    // Check quota before making request
    const hasQuota = await this.checkQuota(estimatedPointCost);
    if (!hasQuota) {
      throw new Error('Daily API quota exhausted');
    }

    // Check circuit breaker
    if (this.circuitOpenUntil && new Date() < this.circuitOpenUntil) {
      throw new Error('Circuit breaker is open');
    }

    // Apply rate limiting
    await this.enforceRateLimit();

    // Build query params
    const params: any = {
      apiKey,
      query,
      addRecipeInformation: true,
      sort: 'popularity',
      number,
      offset,
    };

    if (filters.cuisines && filters.cuisines.length > 0) {
      params.cuisine = filters.cuisines.join(',');
    }

    if (filters.diets && filters.diets.length > 0) {
      params.diet = filters.diets[0]; // Spoonacular only accepts one diet
    }

    if (filters.intolerances && filters.intolerances.length > 0) {
      params.intolerances = filters.intolerances.join(',');
    }

    try {
      this.logger.log(
        `Searching recipes: query="${query}", number=${number}, offset=${offset}`,
      );

      const response = await firstValueFrom(
        this.httpService.get<SpoonacularSearchResponse>(
          '/recipes/complexSearch',
          { params },
        ),
      );

      const results = response.data.results;

      // Calculate actual point cost based on results returned
      const actualPointCost = 1 + results.length * (0.01 + 0.025);
      await this.incrementQuotaUsage(actualPointCost);

      // Reset circuit breaker on success
      this.consecutiveFailures = 0;
      this.circuitOpenUntil = null;

      this.logger.log(`Found ${results.length} recipes`);
      return results as any[];
    } catch (error) {
      this.handleFailure();
      throw error;
    }
  }

  async getRecipeInformationBulk(ids: number[]): Promise<SpoonacularRecipe[]> {
    const apiKey = this.configService.get<string>('SPOONACULAR_API_KEY');
    if (!apiKey) {
      throw new Error('SPOONACULAR_API_KEY not configured');
    }

    // Calculate point cost: 1 + (ids.length - 1) * 0.5
    const pointCost = 1 + (ids.length - 1) * 0.5;

    // Check quota
    const hasQuota = await this.checkQuota(pointCost);
    if (!hasQuota) {
      throw new Error('Daily API quota exhausted');
    }

    // Check circuit breaker
    if (this.circuitOpenUntil && new Date() < this.circuitOpenUntil) {
      throw new Error('Circuit breaker is open');
    }

    // Apply rate limiting
    await this.enforceRateLimit();

    const params = {
      apiKey,
      ids: ids.join(','),
      includeNutrition: true,
    };

    try {
      this.logger.log(`Fetching bulk recipe information for ${ids.length} recipes`);

      const response = await firstValueFrom(
        this.httpService.get<SpoonacularRecipe[]>(
          '/recipes/informationBulk',
          { params },
        ),
      );

      await this.incrementQuotaUsage(pointCost);

      // Reset circuit breaker on success
      this.consecutiveFailures = 0;
      this.circuitOpenUntil = null;

      return response.data;
    } catch (error) {
      this.handleFailure();
      throw error;
    }
  }

  async checkQuota(pointCost: number): Promise<boolean> {
    const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
    const dailyQuota = this.configService.get<number>('SPOONACULAR_DAILY_QUOTA') || 50;

    const usage = await this.prismaService.apiQuotaUsage.findUnique({
      where: { date: today },
    });

    const currentUsage = usage?.pointsUsed || 0;

    // Check if we would exceed quota
    if (currentUsage + pointCost > dailyQuota) {
      this.logger.error(
        `Quota exhausted: ${currentUsage}/${dailyQuota} points used`,
      );
      return false;
    }

    // Warn at 80% threshold
    if (currentUsage >= dailyQuota * 0.8 && currentUsage + pointCost <= dailyQuota) {
      this.logger.warn(
        `Approaching 80% quota threshold: ${currentUsage}/${dailyQuota} points used`,
      );
    }

    return true;
  }

  async incrementQuotaUsage(points: number): Promise<void> {
    const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD

    await this.prismaService.apiQuotaUsage.upsert({
      where: { date: today },
      update: {
        pointsUsed: {
          increment: points,
        },
      },
      create: {
        date: today,
        pointsUsed: points,
      },
    });
  }

  async hasQuotaRemaining(): Promise<boolean> {
    return this.checkQuota(1);
  }

  private handleFailure(): void {
    this.consecutiveFailures++;

    if (this.consecutiveFailures >= 5) {
      // Open circuit for 15 minutes
      this.circuitOpenUntil = new Date(Date.now() + 15 * 60 * 1000);
      this.logger.error(
        `Circuit breaker opened after ${this.consecutiveFailures} failures. Will retry after ${this.circuitOpenUntil.toISOString()}`,
      );
    } else {
      this.logger.warn(`Request failed (${this.consecutiveFailures}/5 failures)`);
    }
  }

  private async enforceRateLimit(): Promise<void> {
    if (this.lastRequestTime) {
      const timeSinceLastRequest = Date.now() - this.lastRequestTime;
      const minimumDelay = 1000; // 1 second

      if (timeSinceLastRequest < minimumDelay) {
        const waitTime = minimumDelay - timeSinceLastRequest;
        await new Promise((resolve) => setTimeout(resolve, waitTime));
      }
    }

    this.lastRequestTime = Date.now();
  }
}
