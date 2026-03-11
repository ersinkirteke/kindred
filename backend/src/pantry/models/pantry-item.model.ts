import { ObjectType, Field, ID } from '@nestjs/graphql';

@ObjectType({ description: 'A pantry inventory item' })
export class PantryItemModel {
  @Field(() => ID)
  id: string;

  @Field()
  name: string;

  @Field({ nullable: true })
  normalizedName?: string;

  @Field()
  quantity: string;

  @Field({ nullable: true })
  unit?: string;

  @Field()
  storageLocation: string;

  @Field({ nullable: true })
  foodCategory?: string;

  @Field({ nullable: true })
  photoUrl?: string;

  @Field({ nullable: true })
  notes?: string;

  @Field()
  source: string;

  @Field({ nullable: true })
  expiryDate?: Date;

  @Field()
  isDeleted: boolean;

  @Field()
  createdAt: Date;

  @Field()
  updatedAt: Date;
}
