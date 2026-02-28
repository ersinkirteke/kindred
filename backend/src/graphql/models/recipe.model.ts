import { ObjectType, Field, ID, Int, Float, registerEnumType } from '@nestjs/graphql';
import { Ingredient } from './ingredient.model';
import { RecipeStep } from './recipe-step.model';

export enum DifficultyLevel {
  BEGINNER = 'BEGINNER',
  INTERMEDIATE = 'INTERMEDIATE',
  ADVANCED = 'ADVANCED',
}

export enum ImageStatus {
  PENDING = 'PENDING',
  GENERATING = 'GENERATING',
  COMPLETED = 'COMPLETED',
  FAILED = 'FAILED',
}

registerEnumType(DifficultyLevel, {
  name: 'DifficultyLevel',
  description: 'Recipe difficulty levels',
});

registerEnumType(ImageStatus, {
  name: 'ImageStatus',
  description: 'AI image generation status',
});

@ObjectType()
export class Recipe {
  @Field(() => ID)
  id: string;

  @Field()
  name: string;

  @Field(() => String, { nullable: true })
  description?: string | null;

  @Field(() => Int)
  prepTime: number;

  @Field(() => Int, { nullable: true })
  cookTime?: number | null;

  @Field(() => Int, { nullable: true })
  servings?: number | null;

  @Field(() => Int, { nullable: true })
  calories?: number | null;

  @Field(() => Float, { nullable: true })
  protein?: number | null;

  @Field(() => Float, { nullable: true })
  carbs?: number | null;

  @Field(() => Float, { nullable: true })
  fat?: number | null;

  @Field(() => DifficultyLevel)
  difficulty: DifficultyLevel;

  @Field(() => [String])
  dietaryTags: string[];

  @Field(() => String, { nullable: true })
  imageUrl?: string | null;

  @Field(() => ImageStatus)
  imageStatus: ImageStatus;

  @Field()
  scrapedFrom: string;

  @Field(() => String, { nullable: true })
  sourceId?: string | null;

  @Field()
  scrapedAt: Date;

  @Field()
  location: string;

  @Field(() => Int)
  engagementLoves: number;

  @Field(() => Int)
  engagementBookmarks: number;

  @Field(() => Int)
  engagementViews: number;

  @Field()
  isViral: boolean;

  @Field()
  createdAt: Date;

  @Field()
  updatedAt: Date;

  @Field(() => [Ingredient])
  ingredients: Ingredient[];

  @Field(() => [RecipeStep])
  steps: RecipeStep[];
}
