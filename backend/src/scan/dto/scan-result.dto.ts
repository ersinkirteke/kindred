import { ObjectType, Field, Int } from '@nestjs/graphql';
import { ScanType } from './scan.dto';

/**
 * Detected item from AI scan analysis
 * Represents a single ingredient found in a fridge photo or receipt
 */
@ObjectType()
export class DetectedItemDto {
  @Field(() => String, { description: 'Ingredient name, normalized to English' })
  name: string;

  @Field(() => String, { description: 'Estimated quantity (e.g., "~6", "500g")' })
  quantity: string;

  @Field(() => String, { description: 'Food category (dairy, produce, etc.)' })
  category: string;

  @Field(() => String, { description: 'Storage location: fridge, freezer, or pantry' })
  storageLocation: string;

  @Field(() => Int, { description: 'Conservative days from today until expiry' })
  estimatedExpiryDays: number;

  @Field(() => Int, { description: 'Confidence score 0-100' })
  confidence: number;
}

/**
 * Response for scan analysis mutations
 * Contains the analyzed items and job metadata
 */
@ObjectType()
export class ScanResultResponse {
  @Field(() => String, { description: 'Scan job ID' })
  jobId: string;

  @Field(() => [DetectedItemDto], { description: 'Detected items from scan' })
  items: DetectedItemDto[];

  @Field(() => ScanType, { description: 'Type of scan performed' })
  scanType: ScanType;
}
