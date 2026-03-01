import { ObjectType, Field, ID, Int, Float } from '@nestjs/graphql';
import { CuisineType, MealType, ImageStatus } from '../../graphql/models/recipe.model';

/**
 * RecipeCard - Summary-level recipe for feed cards
 *
 * Contains only card-level fields displayed in feed view.
 * Detail fields (dietaryTags, cookTime, difficulty) are excluded
 * per user decision - those only appear in detail view.
 */
@ObjectType()
export class RecipeCard {
  @Field(() => ID)
  id: string;

  @Field()
  name: string;

  @Field(() => String, { nullable: true })
  imageUrl?: string | null;

  @Field(() => ImageStatus)
  imageStatus: ImageStatus;

  @Field(() => Int)
  prepTime: number;

  @Field(() => Int, { nullable: true })
  calories?: number | null;

  @Field(() => Int)
  engagementLoves: number;

  @Field()
  engagementHumanized: string; // "1.2k loves today"

  @Field()
  isViral: boolean;

  @Field(() => CuisineType)
  cuisineType: CuisineType;

  @Field(() => MealType)
  mealType: MealType;

  @Field(() => Float)
  velocityScore: number;

  @Field(() => Float, { nullable: true })
  distanceMiles?: number | null;

  // Internal field for humanization calculation (not exposed in GraphQL)
  scrapedAt?: Date;
}
