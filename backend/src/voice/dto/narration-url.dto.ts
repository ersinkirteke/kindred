import { Field, ObjectType, Int } from '@nestjs/graphql';

@ObjectType()
export class NarrationUrlDto {
  @Field(() => String, { nullable: true, description: 'R2 CDN URL for cached narration audio, null if not yet generated' })
  url: string | null;

  @Field(() => String, { description: "Speaker's name (e.g., 'Mom', 'Nonna Maria')" })
  speakerName: string;

  @Field(() => String, { description: "Relationship to user (e.g., 'Mother', 'Grandmother')" })
  relationship: string;

  @Field(() => String, { description: 'Recipe name' })
  recipeName: string;

  @Field(() => Int, { nullable: true, description: 'Audio duration in milliseconds, null if not yet cached' })
  durationMs: number | null;
}
