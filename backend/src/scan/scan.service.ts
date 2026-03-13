import { Injectable, Logger } from '@nestjs/common';
import { R2StorageService } from '../images/r2-storage.service';
import { ScanType, ScanJobStatus, ScanJobResponse } from './dto/scan.dto';
import { DetectedItemDto } from './dto/scan-result.dto';
import { PrismaService } from '../prisma/prisma.service';
import { PantryService } from '../pantry/pantry.service';
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

  constructor(
    private readonly r2Storage: R2StorageService,
    private readonly prisma: PrismaService,
    private readonly pantryService: PantryService,
  ) {}

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
    const timestamp = Date.now();
    const key = `scans/${userId}/${timestamp}.jpg`;

    try {
      // Upload to R2 storage
      const photoUrl = await this.r2Storage.uploadImage(fileBuffer, key, mimeType);

      this.logger.log(`Scan photo uploaded successfully: ${key} for user ${userId}`);

      // Create scan job in database
      const job = await this.createScanJob(userId, scanType, photoUrl);

      return {
        id: job.id,
        status: job.status as ScanJobStatus,
        photoUrl: job.photoUrl!,
        scanType: job.scanType as ScanType,
        createdAt: job.createdAt,
      };
    } catch (error) {
      this.logger.error(`Failed to upload scan photo for user ${userId}`, error);
      throw error;
    }
  }

  /**
   * Create a scan job in the database
   */
  async createScanJob(
    userId: string,
    scanType: ScanType,
    photoUrl?: string,
  ): Promise<any> {
    return this.prisma.scanJob.create({
      data: {
        userId,
        scanType: scanType.toString(),
        photoUrl: photoUrl || null,
        status: 'PROCESSING',
      },
    });
  }

  /**
   * Save scan results to database
   */
  async saveScanResults(
    jobId: string,
    items: DetectedItemDto[],
  ): Promise<void> {
    await this.prisma.scanJob.update({
      where: { id: jobId },
      data: {
        results: items as any,
        status: 'COMPLETED',
        updatedAt: new Date(),
      },
    });
  }

  /**
   * Mark scan job as failed
   */
  async markJobFailed(jobId: string, error?: string): Promise<void> {
    await this.prisma.scanJob.update({
      where: { id: jobId },
      data: {
        status: 'FAILED',
        error: error || 'Unknown error',
        updatedAt: new Date(),
      },
    });
  }

  /**
   * Find scan job by ID
   */
  async findJobById(jobId: string): Promise<any> {
    return this.prisma.scanJob.findUnique({
      where: { id: jobId },
    });
  }

  /**
   * Get completed scan count for user (for free scan quota)
   */
  async getUserScanCount(userId: string): Promise<number> {
    return this.prisma.scanJob.count({
      where: {
        userId,
        status: 'COMPLETED',
      },
    });
  }

  /**
   * Normalize detected items using IngredientCatalog
   * Auto-creates catalog entries for unknown items (accept-and-learn)
   */
  async normalizeDetectedItems(
    items: DetectedItemDto[],
  ): Promise<DetectedItemDto[]> {
    const normalized: DetectedItemDto[] = [];

    for (const item of items) {
      // Normalize ingredient name via PantryService
      const normalizedName = await this.normalizeIngredient(item.name);

      // Look up catalog entry for category
      const catalogEntry = await this.prisma.ingredientCatalog.findFirst({
        where: { canonicalName: normalizedName },
      });

      normalized.push({
        ...item,
        name: normalizedName,
        category: catalogEntry?.defaultCategory || item.category,
      });
    }

    return normalized;
  }

  /**
   * Normalize ingredient name using IngredientCatalog
   * Delegates to PantryService pattern for consistency
   */
  private async normalizeIngredient(inputName: string): Promise<string> {
    const lowerInput = inputName.toLowerCase().trim();

    // Search catalog for match
    const catalogEntry = await this.prisma.ingredientCatalog.findFirst({
      where: {
        OR: [
          { canonicalName: { equals: lowerInput, mode: 'insensitive' } },
          { canonicalNameTR: { equals: lowerInput, mode: 'insensitive' } },
          { aliases: { has: lowerInput } },
        ],
      },
    });

    if (catalogEntry) {
      return catalogEntry.canonicalName;
    }

    // Unknown ingredient: auto-create catalog entry (accept and learn)
    const newEntry = await this.prisma.ingredientCatalog.create({
      data: {
        canonicalName: lowerInput,
        canonicalNameTR: lowerInput,
        aliases: [],
        defaultCategory: 'other',
        defaultShelfLifeDays: null,
      },
    });

    return newEntry.canonicalName;
  }
}
