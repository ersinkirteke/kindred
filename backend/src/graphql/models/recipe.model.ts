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

export enum CuisineType {
  ITALIAN = 'ITALIAN',
  MEXICAN = 'MEXICAN',
  CHINESE = 'CHINESE',
  JAPANESE = 'JAPANESE',
  SICHUAN = 'SICHUAN',
  CANTONESE = 'CANTONESE',
  INDIAN = 'INDIAN',
  THAI = 'THAI',
  KOREAN = 'KOREAN',
  VIETNAMESE = 'VIETNAMESE',
  MEDITERRANEAN = 'MEDITERRANEAN',
  FRENCH = 'FRENCH',
  SPANISH = 'SPANISH',
  GREEK = 'GREEK',
  MIDDLE_EASTERN = 'MIDDLE_EASTERN',
  LEBANESE = 'LEBANESE',
  TURKISH = 'TURKISH',
  MOROCCAN = 'MOROCCAN',
  ETHIOPIAN = 'ETHIOPIAN',
  AMERICAN = 'AMERICAN',
  SOUTHERN = 'SOUTHERN',
  TEX_MEX = 'TEX_MEX',
  BRAZILIAN = 'BRAZILIAN',
  PERUVIAN = 'PERUVIAN',
  CARIBBEAN = 'CARIBBEAN',
  BRITISH = 'BRITISH',
  GERMAN = 'GERMAN',
  FUSION = 'FUSION',
  OTHER = 'OTHER',
}

export enum MealType {
  BREAKFAST = 'BREAKFAST',
  LUNCH = 'LUNCH',
  DINNER = 'DINNER',
  SNACK = 'SNACK',
  DESSERT = 'DESSERT',
  APPETIZER = 'APPETIZER',
  DRINK = 'DRINK',
}

registerEnumType(DifficultyLevel, {
  name: 'DifficultyLevel',
  description: 'Recipe difficulty levels',
});

registerEnumType(ImageStatus, {
  name: 'ImageStatus',
  description: 'AI image generation status',
});

registerEnumType(CuisineType, {
  name: 'CuisineType',
  description: 'Recipe cuisine type classification',
});

registerEnumType(MealType, {
  name: 'MealType',
  description: 'Recipe meal type classification',
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

  @Field(() => CuisineType)
  cuisineType: CuisineType;

  @Field(() => MealType)
  mealType: MealType;

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

  @Field(() => String, { nullable: true })
  location?: string | null;

  @Field(() => Float, { nullable: true })
  latitude?: number | null;

  @Field(() => Float, { nullable: true })
  longitude?: number | null;

  @Field(() => Int, { nullable: true })
  spoonacularId?: number | null;

  @Field(() => Int, { nullable: true })
  popularityScore?: number | null;

  @Field(() => String, { nullable: true })
  sourceUrl?: string | null;

  @Field(() => String, { nullable: true })
  sourceName?: string | null;

  @Field(() => String, { nullable: true })
  plainText?: string | null;

  @Field(() => Int)
  engagementLoves: number;

  @Field(() => Int)
  engagementBookmarks: number;

  @Field(() => Int)
  engagementViews: number;

  @Field()
  isViral: boolean;

  @Field(() => Float)
  velocityScore: number;

  @Field()
  createdAt: Date;

  @Field()
  updatedAt: Date;

  @Field(() => [Ingredient])
  ingredients: Ingredient[];

  @Field(() => [RecipeStep])
  steps: RecipeStep[];
}
