import { Resolver, Query } from '@nestjs/graphql';
import { PrismaService } from '../prisma/prisma.service';
import { SpoonacularHealthStatus } from './dto/spoonacular-health.dto';
import { ConfigService } from '@nestjs/config';

@Resolver()
export class HealthResolver {
  constructor(
    private prisma: PrismaService,
    private configService: ConfigService,
  ) {}

  @Query(() => String, {
    description: 'Basic health check - returns "ok" if service is running',
  })
  async health(): Promise<string> {
    return 'ok';
  }

  @Query(() => Boolean, {
    description: 'Database health check - returns true if database is accessible',
  })
  async dbHealth(): Promise<boolean> {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return true;
    } catch (error) {
      return false;
    }
  }

  @Query(() => SpoonacularHealthStatus, {
    description: 'Spoonacular API health and quota status',
  })
  async spoonacularHealth(): Promise<SpoonacularHealthStatus> {
    const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
    const dailyQuota =
      this.configService.get<number>('SPOONACULAR_DAILY_QUOTA') || 50;

    // Get today's quota usage
    const usage = await this.prisma.apiQuotaUsage.findUnique({
      where: { date: today },
    });

    const quotaUsed = usage?.pointsUsed || 0;
    const quotaRemaining = dailyQuota - quotaUsed;

    // Calculate next midnight UTC for quota reset
    const now = new Date();
    const tomorrow = new Date(
      Date.UTC(
        now.getUTCFullYear(),
        now.getUTCMonth(),
        now.getUTCDate() + 1,
        0,
        0,
        0,
        0,
      ),
    );
    const quotaResetAt = tomorrow.toISOString();

    // Count cached recipes from Spoonacular
    const cachedRecipeCount = await this.prisma.recipe.count({
      where: { scrapedFrom: 'spoonacular' },
    });

    // Count cached searches
    const cachedSearchCount = await this.prisma.searchCache.count();

    return {
      quotaUsed,
      quotaLimit: dailyQuota,
      quotaRemaining,
      quotaResetAt,
      cachedRecipeCount,
      cachedSearchCount,
    };
  }
}
