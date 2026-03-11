import { InputType, Field } from '@nestjs/graphql';

@InputType()
export class UpdatePantryItemInput {
  @Field({ nullable: true })
  name?: string;

  @Field({ nullable: true })
  quantity?: string;

  @Field({ nullable: true })
  unit?: string;

  @Field({ nullable: true })
  storageLocation?: string;

  @Field({ nullable: true })
  foodCategory?: string;

  @Field({ nullable: true })
  notes?: string;

  @Field({ nullable: true })
  expiryDate?: Date;
}
