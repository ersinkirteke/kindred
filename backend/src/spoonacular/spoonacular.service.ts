import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { SearchFilters, SpoonacularRecipe } from './dto/spoonacular-recipe.dto';

@Injectable()
export class SpoonacularService {
  private readonly logger = new Logger(SpoonacularService.name);

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
  ): Promise<any[]> {
    // TODO: Implement
    throw new Error('Not implemented');
  }

  async getRecipeInformationBulk(ids: number[]): Promise<SpoonacularRecipe[]> {
    // TODO: Implement
    throw new Error('Not implemented');
  }
}
