import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class RecipesService {
  constructor(private prisma: PrismaService) {}

  /**
   * Find all recipes with optional location filter and pagination.
   * Returns recipes ordered by scraping date (newest first).
   */
  async findAll(location?: string, limit: number = 20, offset: number = 0) {
    return this.prisma.recipe.findMany({
      where: location ? { location } : undefined,
      include: {
        ingredients: {
          orderBy: { orderIndex: 'asc' },
        },
        steps: {
          orderBy: { orderIndex: 'asc' },
        },
      },
      orderBy: { scrapedAt: 'desc' },
      take: limit,
      skip: offset,
    });
  }

  /**
   * Find a single recipe by ID with all relations.
   */
  async findById(id: string) {
    return this.prisma.recipe.findUnique({
      where: { id },
      include: {
        ingredients: {
          orderBy: { orderIndex: 'asc' },
        },
        steps: {
          orderBy: { orderIndex: 'asc' },
        },
      },
    });
  }

  /**
   * Find viral recipes for a specific location.
   * Returns up to 10 viral recipes ordered by engagement.
   */
  async findViral(location: string) {
    return this.prisma.recipe.findMany({
      where: {
        location,
        isViral: true,
      },
      include: {
        ingredients: {
          orderBy: { orderIndex: 'asc' },
        },
        steps: {
          orderBy: { orderIndex: 'asc' },
        },
      },
      orderBy: [
        { engagementLoves: 'desc' },
        { engagementViews: 'desc' },
      ],
      take: 10,
    });
  }
}
