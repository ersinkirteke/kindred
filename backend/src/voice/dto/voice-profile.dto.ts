import { ObjectType, Field, ID, registerEnumType } from '@nestjs/graphql';

/**
 * VoiceStatus enum for GraphQL
 *
 * Tracks the lifecycle of a voice cloning operation.
 */
export enum VoiceStatus {
  PENDING = 'PENDING',
  PROCESSING = 'PROCESSING',
  READY = 'READY',
  FAILED = 'FAILED',
  DELETED = 'DELETED',
}

// Register enum for GraphQL schema
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
