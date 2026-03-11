import { InputType, Field } from '@nestjs/graphql';

@InputType()
export class BulkPantryItemInput {
  @Field()
  name: string;

  @Field()
  quantity: string;

  @Field({ nullable: true })
  unit?: string;

  @Field({ nullable: true, defaultValue: 'pantry' })
  storageLocation?: string;

  @Field({ nullable: true })
  source?: string;
}

@InputType()
export class BulkAddPantryItemsInput {
  @Field()
  userId: string;

  @Field(() => [BulkPantryItemInput])
  items: BulkPantryItemInput[];
}
