import { ObjectType, Field, registerEnumType } from '@nestjs/graphql';

/**
 * Type of scan being performed
 */
export enum ScanType {
  FRIDGE = 'FRIDGE',
  RECEIPT = 'RECEIPT',
}

registerEnumType(ScanType, {
  name: 'ScanType',
  description: 'Type of pantry scan (fridge photo or receipt)',
});

/**
 * Status of a scan job
 */
export enum ScanJobStatus {
  UPLOADING = 'UPLOADING',
  PROCESSING = 'PROCESSING',
  COMPLETED = 'COMPLETED',
  FAILED = 'FAILED',
}

registerEnumType(ScanJobStatus, {
  name: 'ScanJobStatus',
  description: 'Current status of scan job processing',
});

/**
 * Response for scan photo upload mutation
 */
@ObjectType()
export class ScanJobResponse {
  @Field(() => String)
  id: string;

  @Field(() => ScanJobStatus)
  status: ScanJobStatus;

  @Field(() => String)
  photoUrl: string;

  @Field(() => ScanType)
  scanType: ScanType;

  @Field(() => Date)
  createdAt: Date;
}
