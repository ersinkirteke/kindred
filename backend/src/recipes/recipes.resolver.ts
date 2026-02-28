import { Resolver, Query, Args, ID, Int } from '@nestjs/graphql';
import { RecipesService } from './recipes.service';
import { Recipe } from '../graphql/models/recipe.model';

@Resolver(() => Recipe)
export class RecipesResolver {
  constructor(private recipesService: RecipesService) {}

  @Query(() => [Recipe], {
    description: 'Get all recipes with optional location filter and pagination',
  })
  async recipes(
    @Args('location', { nullable: true }) location?: string,
    @Args('limit', { type: () => Int, nullable: true, defaultValue: 20 })
    limit?: number,
    @Args('offset', { type: () => Int, nullable: true, defaultValue: 0 })
    offset?: number,
  ): Promise<Recipe[]> {
    return this.recipesService.findAll(location, limit, offset) as any;
  }

  @Query(() => Recipe, {
    nullable: true,
    description: 'Get a single recipe by ID',
  })
  async recipe(
    @Args('id', { type: () => ID }) id: string,
  ): Promise<Recipe | null> {
    return this.recipesService.findById(id) as any;
  }

  @Query(() => [Recipe], {
    description: 'Get viral recipes for a specific location',
  })
  async viralRecipes(
    @Args('location') location: string,
  ): Promise<Recipe[]> {
    return this.recipesService.findViral(location) as any;
  }
}
