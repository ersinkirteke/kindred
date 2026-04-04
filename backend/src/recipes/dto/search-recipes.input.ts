import { InputType, Field, Int } from '@nestjs/graphql';

@InputType()
export class SearchRecipesInput {
  @Field({ nullable: true, description: 'Search query for recipe name or ingredients' })
  query?: string;

  @Field(() => [String], { nullable: true, description: 'Cuisine types to filter by' })
  cuisines?: string[];

  @Field(() => [String], { nullable: true, description: 'Diet types to filter by (e.g., vegetarian, vegan, keto)' })
  diets?: string[];

  @Field(() => [String], { nullable: true, description: 'Intolerances to exclude (e.g., gluten, dairy, nuts)' })
  intolerances?: string[];

  @Field(() => Int, { nullable: true, defaultValue: 20, description: 'Number of results to return' })
  first?: number;

  @Field({ nullable: true, description: 'Cursor for pagination (base64 encoded offset)' })
  after?: string;
}
