import { ObjectType, Field, Float } from '@nestjs/graphql';

@ObjectType()
export class CityCoordinates {
  @Field(() => Float)
  lat: number;

  @Field(() => Float)
  lng: number;

  @Field()
  city: string;

  @Field(() => String, { nullable: true })
  country?: string;
}

@ObjectType()
export class CitySuggestion {
  @Field()
  name: string; // "Austin, Texas, United States"

  @Field(() => Float)
  lat: number;

  @Field(() => Float)
  lng: number;
}
