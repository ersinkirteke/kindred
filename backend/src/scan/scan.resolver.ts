import { Resolver, Mutation, Args } from '@nestjs/graphql';
import { ScanService } from './scan.service';
import { ScanJobResponse, ScanType } from './dto/scan.dto';

/**
 * GraphQL resolver for scan photo upload
 *
 * Provides uploadScanPhoto mutation for pantry scanning feature.
 * Uses base64-encoded image data for file upload (Apollo iOS compatible).
 */
@Resolver()
export class ScanResolver {
  constructor(private readonly scanService: ScanService) {}

  /**
   * Upload a scan photo for AI processing
   *
   * @param userId - User ID (required for authentication)
   * @param scanType - Type of scan (FRIDGE or RECEIPT)
   * @param photoData - Base64-encoded image data
   * @returns Scan job response with processing status
   */
  @Mutation(() => ScanJobResponse)
  async uploadScanPhoto(
    @Args('userId') userId: string,
    @Args('scanType', { type: () => ScanType }) scanType: ScanType,
    @Args('photoData') photoData: string,
  ): Promise<ScanJobResponse> {
    // Decode base64 to buffer
    const fileBuffer = Buffer.from(photoData, 'base64');
    const mimeType = 'image/jpeg'; // Default to JPEG (can be detected from base64 header if needed)

    return this.scanService.uploadScanPhoto(userId, scanType, fileBuffer, mimeType);
  }
}
