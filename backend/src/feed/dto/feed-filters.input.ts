import { InputType, Field } from '@nestjs/graphql';
import { CuisineType, MealType } from '../../graphql/models/recipe.model';

/**
 * FeedFiltersInput - Multi-category filter combination
 *
 * Filter logic:
 * - Within category: OR (any cuisineType OR any mealType)
 * - Across categories: AND (cuisineType AND mealType AND dietaryTags)
 * - DietaryTags: AND logic (must have ALL specified tags)
 */
@InputType()
export class FeedFiltersInput {
  @Field(() => [CuisineType], { nullable: true })
  cuisineTypes?: CuisineType[]; // OR within category

  @Field(() => [MealType], { nullable: true })
  mealTypes?: MealType[]; // OR within category

  @Field(() => [String], { nullable: true })
  dietaryTags?: string[]; // AND logic (must have ALL tags)
}
