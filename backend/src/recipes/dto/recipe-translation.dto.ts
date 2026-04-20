import { ObjectType, Field, Int } from '@nestjs/graphql';

@ObjectType('TranslatedIngredient')
export class TranslatedIngredientDto {
  @Field()
  name!: string;

  @Field()
  quantity!: string;

  @Field()
  unit!: string;
}

@ObjectType('TranslatedStep')
export class TranslatedStepDto {
  @Field(() => Int)
  orderIndex!: number;

  @Field()
  text!: string;
}

@ObjectType('RecipeTranslation')
export class RecipeTranslationDto {
  @Field()
  recipeId!: string;

  @Field()
  locale!: string;

  @Field()
  name!: string;

  @Field(() => String, { nullable: true })
  description?: string | null;

  @Field(() => [TranslatedIngredientDto])
  ingredients!: TranslatedIngredientDto[];

  @Field(() => [TranslatedStepDto])
  steps!: TranslatedStepDto[];
}
