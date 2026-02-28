import { ObjectType, Field, Int } from '@nestjs/graphql';

@ObjectType()
export class RecipeStep {
  @Field(() => Int)
  orderIndex: number;

  @Field()
  text: string;

  @Field(() => Int, { nullable: true })
  duration?: number | null;

  @Field(() => String, { nullable: true })
  techniqueTag?: string | null;
}
