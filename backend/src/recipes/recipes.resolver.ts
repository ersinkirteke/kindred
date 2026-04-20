import { Resolver, Query, Args, ID, Int } from '@nestjs/graphql';
import { RecipesService } from './recipes.service';
import { RecipeTranslationService } from './recipe-translation.service';
import { Recipe } from '../graphql/models/recipe.model';
import { SearchRecipesInput } from './dto/search-recipes.input';
import { RecipeConnection } from '../feed/dto/feed-connection.type';
import { RecipeTranslationDto } from './dto/recipe-translation.dto';

@Resolver(() => Recipe)
export class RecipesResolver {
  constructor(
    private recipesService: RecipesService,
    private recipeTranslationService: RecipeTranslationService,
  ) {}

  @Query(() => RecipeConnection, {
    description: 'Search recipes with filters and pagination (cache-first with stale-while-revalidate)',
  })
  async searchRecipes(
    @Args('input') input: SearchRecipesInput,
  ): Promise<RecipeConnection> {
    return this.recipesService.searchRecipes(input);
  }

  @Query(() => RecipeConnection, {
    description: 'Get popular recipes sorted by popularity score (pre-warmed cache)',
  })
  async popularRecipes(
    @Args('first', { type: () => Int, nullable: true, defaultValue: 20 })
    first?: number,
    @Args('after', { nullable: true }) after?: string,
  ): Promise<RecipeConnection> {
    return this.recipesService.getPopularRecipes(first, after);
  }

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

  @Query(() => RecipeTranslationDto, {
    nullable: true,
    description:
      'Gemini-translated recipe content in the given locale. Returns null for English or when translation is unavailable.',
  })
  async recipeTranslation(
    @Args('recipeId') recipeId: string,
    @Args('locale') locale: string,
  ): Promise<RecipeTranslationDto | null> {
    return this.recipeTranslationService.getOrGenerate(recipeId, locale);
  }
}
