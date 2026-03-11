import { ObjectType, Field, ID } from '@nestjs/graphql';

@ObjectType({ description: 'An ingredient catalog entry for normalization' })
export class IngredientCatalogEntry {
  @Field(() => ID)
  id: string;

  @Field()
  canonicalName: string;

  @Field()
  canonicalNameTR: string;

  @Field(() => [String])
  aliases: string[];

  @Field()
  defaultCategory: string;

  @Field({ nullable: true })
  defaultShelfLifeDays?: number;
}
