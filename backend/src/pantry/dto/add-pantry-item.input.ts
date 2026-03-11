import { InputType, Field } from '@nestjs/graphql';

@InputType()
export class AddPantryItemInput {
  @Field()
  userId: string;

  @Field()
  name: string;

  @Field()
  quantity: string;

  @Field({ nullable: true })
  unit?: string;

  @Field()
  storageLocation: string; // "fridge" | "freezer" | "pantry"

  @Field({ nullable: true })
  foodCategory?: string;

  @Field({ nullable: true })
  notes?: string;

  @Field({ nullable: true, defaultValue: 'manual' })
  source?: string;

  @Field({ nullable: true })
  expiryDate?: Date;
}
