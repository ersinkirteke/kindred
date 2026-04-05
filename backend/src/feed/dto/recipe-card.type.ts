import { ObjectType, Field, ID, Int, Float } from '@nestjs/graphql';
import { CuisineType, MealType, ImageStatus, DifficultyLevel } from '../../graphql/models/recipe.model';
import { Ingredient } from '../../graphql/models/ingredient.model';

/**
 * RecipeCard - Recipe summary for feed cards
 *
 * Extended to include iOS-required fields (popularityScore, description, cookTime,
 * dietaryTags, difficulty, ingredients) for Phase 26 feed UI migration.
 * These fields are now exposed in GraphQL for PopularRecipesQuery.
 */
@ObjectType()
export class RecipeCard {
  @Field(() => ID)
  id: string;

  @Field()
  name: string;

  @Field(() => String, { nullable: true })
  description?: string | null;

  @Field(() => String, { nullable: true })
  imageUrl?: string | null;

  @Field(() => ImageStatus)
  imageStatus: ImageStatus;

  @Field(() => Int)
  prepTime: number;

  @Field(() => Int, { nullable: true })
  cookTime?: number | null;

  @Field(() => Int, { nullable: true })
  calories?: number | null;

  @Field(() => Int)
  engagementLoves: number;

  @Field()
  engagementHumanized: string; // "1.2k loves today"

  @Field()
  isViral: boolean;

  @Field(() => Int, { nullable: true })
  popularityScore?: number | null;

  @Field(() => [String], { nullable: true })
  dietaryTags?: string[];

  @Field(() => DifficultyLevel, { nullable: true })
  difficulty?: DifficultyLevel;

  @Field(() => CuisineType)
  cuisineType: CuisineType;

  @Field(() => MealType)
  mealType: MealType;

  @Field(() => Float)
  velocityScore: number;

  @Field(() => Float, { nullable: true })
  distanceMiles?: number | null;

  @Field(() => [Ingredient], { nullable: true })
  ingredients?: Ingredient[];

  // Internal field for humanization calculation (not exposed in GraphQL)
  scrapedAt?: Date;
}
