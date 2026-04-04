import { InputType, Field, Int } from '@nestjs/graphql';
import { IsOptional, IsString, IsArray, IsInt } from 'class-validator';

@InputType()
export class SearchRecipesInput {
  @Field({ nullable: true, description: 'Search query for recipe name or ingredients' })
  @IsOptional()
  @IsString()
  query?: string;

  @Field(() => [String], { nullable: true, description: 'Cuisine types to filter by' })
  @IsOptional()
  @IsArray()
  cuisines?: string[];

  @Field(() => [String], { nullable: true, description: 'Diet types to filter by (e.g., vegetarian, vegan, keto)' })
  @IsOptional()
  @IsArray()
  diets?: string[];

  @Field(() => [String], { nullable: true, description: 'Intolerances to exclude (e.g., gluten, dairy, nuts)' })
  @IsOptional()
  @IsArray()
  intolerances?: string[];

  @Field(() => Int, { nullable: true, defaultValue: 20, description: 'Number of results to return' })
  @IsOptional()
  @IsInt()
  first?: number;

  @Field({ nullable: true, description: 'Cursor for pagination (base64 encoded offset)' })
  @IsOptional()
  @IsString()
  after?: string;
}
