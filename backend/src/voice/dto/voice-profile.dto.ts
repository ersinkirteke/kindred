import { ObjectType, Field, ID, registerEnumType } from '@nestjs/graphql';
import { VoiceStatus } from '@prisma/client';

// Register Prisma enum for GraphQL schema
registerEnumType(VoiceStatus, {
  name: 'VoiceStatus',
  description: 'Voice profile cloning status',
});

/**
 * VoiceProfileDto
 *
 * GraphQL representation of a user's cloned voice profile.
 * Excludes internal fields (elevenLabsVoiceId, audioSampleUrl, consent data).
 */
@ObjectType('VoiceProfile')
export class VoiceProfileDto {
  @Field(() => ID)
  id: string;

  @Field(() => VoiceStatus)
  status: VoiceStatus;

  @Field()
  speakerName: string;

  @Field()
  relationship: string;

  @Field()
  createdAt: Date;

  @Field()
  updatedAt: Date;
}
