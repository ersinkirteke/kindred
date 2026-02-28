import { Resolver, Query } from '@nestjs/graphql';
import { PrismaService } from '../prisma/prisma.service';

@Resolver()
export class HealthResolver {
  constructor(private prisma: PrismaService) {}

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
}
