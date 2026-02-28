import { ObjectType, Field, Int } from '@nestjs/graphql';

@ObjectType()
export class Ingredient {
  @Field()
  name: string;

  @Field()
  quantity: string;

  @Field()
  unit: string;

  @Field(() => Int)
  orderIndex: number;
}
