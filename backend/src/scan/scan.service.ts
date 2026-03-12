import { Injectable, Logger } from '@nestjs/common';
import { R2StorageService } from '../images/r2-storage.service';
import { ScanType, ScanJobStatus, ScanJobResponse } from './dto/scan.dto';
import { randomUUID } from 'crypto';

/**
 * Service for handling pantry scan photo uploads
 *
 * Phase 14-01: Basic upload to R2 with job tracking
 * Phase 15: AI-powered ingredient detection with Gemini Vision
 */
@Injectable()
export class ScanService {
  private readonly logger = new Logger(ScanService.name);

  constructor(private readonly r2Storage: R2StorageService) {}

  /**
   * Upload a scan photo to R2 storage
   *
   * @param userId - User ID for key generation
   * @param scanType - Type of scan (fridge or receipt)
   * @param fileBuffer - Binary image data
   * @param mimeType - MIME type (e.g., image/jpeg)
   * @returns Scan job response with processing status
   */
  async uploadScanPhoto(
    userId: string,
    scanType: ScanType,
    fileBuffer: Buffer,
    mimeType: string,
  ): Promise<ScanJobResponse> {
    const jobId = randomUUID();
    const timestamp = Date.now();
    const key = `scans/${userId}/${timestamp}.jpg`;

    try {
      // Upload to R2 storage
      const photoUrl = await this.r2Storage.uploadImage(fileBuffer, key, mimeType);

      this.logger.log(`Scan photo uploaded successfully: ${key} for user ${userId}`);

      // Return job response (Phase 15 will add Prisma persistence and AI processing)
      return {
        id: jobId,
        status: ScanJobStatus.PROCESSING,
        photoUrl,
        scanType,
        createdAt: new Date(),
      };
    } catch (error) {
      this.logger.error(`Failed to upload scan photo for user ${userId}`, error);
      throw error;
    }
  }
}
