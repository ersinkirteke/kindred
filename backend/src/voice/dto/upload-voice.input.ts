import { InputType, Field } from '@nestjs/graphql';
import { IsString, IsNotEmpty, IsBoolean, IsOptional } from 'class-validator';

/**
 * UploadVoiceInput
 *
 * GraphQL input for voice upload metadata.
 * consentGiven MUST be true for upload to proceed (backend validation).
 */
@InputType()
export class UploadVoiceInput {
  @Field()
  @IsString()
  @IsNotEmpty()
  speakerName: string;

  @Field()
  @IsString()
  @IsNotEmpty()
  relationship: string;

  @Field()
  @IsBoolean()
  consentGiven: boolean;

  @Field({ nullable: true })
  @IsString()
  @IsOptional()
  appVersion?: string;
}
