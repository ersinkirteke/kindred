import { Field, ObjectType } from '@nestjs/graphql';

/**
 * NarrationMetadataDto
 *
 * Metadata for recipe narration, returned alongside streaming audio URL.
 * Mobile clients use this to display "Narrated by Mom" before user presses play.
 */
@ObjectType()
export class NarrationMetadataDto {
  @Field(() => String, {
    description: "Speaker's name (e.g., 'Mom', 'Nonna Maria')",
  })
  speakerName: string;

  @Field(() => String, {
    description: "Relationship to user (e.g., 'Mother', 'Grandmother')",
  })
  relationship: string;

  @Field(() => String, { description: 'Recipe ID being narrated' })
  recipeId: string;

  @Field(() => String, { description: 'Recipe name' })
  recipeName: string;
}
