import { Resolver, Mutation, Args } from '@nestjs/graphql';
import { ForbiddenException, UseGuards } from '@nestjs/common';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { ScanService } from './scan.service';
import { ScanAnalyzerService } from './scan-analyzer.service';
import { ScanJobResponse, ScanType } from './dto/scan.dto';
import { ScanResultResponse } from './dto/scan-result.dto';
import { PrismaService } from '../prisma/prisma.service';

const DAILY_SCAN_LIMIT = 20;

/**
 * GraphQL resolver for scan photo upload and analysis
 *
 * Phase 14-01: uploadScanPhoto mutation for R2 upload
 * Phase 15-01: analyzeScan and analyzeReceiptText with Gemini Vision
 */
@Resolver()
export class ScanResolver {
  constructor(
    private readonly scanService: ScanService,
    private readonly scanAnalyzer: ScanAnalyzerService,
    private readonly prisma: PrismaService,
  ) {}

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

  /**
   * Analyze a fridge photo using Gemini Vision
   *
   * @param jobId - Scan job ID (from uploadScanPhoto)
   * @param userId - User ID for authorization
   * @returns Detected items with confidence scores
   */
  @Mutation(() => ScanResultResponse)
  @UseGuards(ThrottlerGuard)
  @Throttle({ default: { ttl: 60000, limit: 5 } })
  async analyzeScan(
    @Args('jobId') jobId: string,
    @Args('userId') userId: string,
  ): Promise<ScanResultResponse> {
    try {
      // 1. Verify job exists and belongs to user
      const job = await this.scanService.findJobById(jobId);
      if (!job || job.userId !== userId) {
        throw new Error('Scan job not found or unauthorized');
      }

      // 2. Check for duplicate scan (same content hash)
      if (job.contentHash) {
        const duplicate = await this.scanService.findDuplicateScan(
          userId,
          job.contentHash,
        );
        if (duplicate && duplicate.results) {
          await this.scanService.saveScanResults(jobId, duplicate.results as any);
          return {
            jobId,
            items: duplicate.results as any,
            scanType: job.scanType as ScanType,
          };
        }
      }

      // 3. Check free scan quota
      const scanCount = await this.scanService.getUserScanCount(userId);
      if (scanCount >= 1) {
        // Check for active subscription
        const subscription = await this.prisma.subscription.findFirst({
          where: {
            userId,
            isActive: true,
          },
        });

        if (!subscription) {
          throw new ForbiddenException(
            'Pro subscription required for additional scans',
          );
        }

        // 4. Check daily scan limit for Pro users
        const dailyCount = await this.scanService.getDailyScanCount(userId);
        if (dailyCount >= DAILY_SCAN_LIMIT) {
          throw new ForbiddenException(
            'Daily scan limit reached. Try again tomorrow.',
          );
        }
      }

      // 5. Analyze photo with Gemini Vision
      const items = await this.scanAnalyzer.analyzeFridgePhoto(job.photoUrl);

      // 6. Normalize detected items via IngredientCatalog
      const normalizedItems = await this.scanService.normalizeDetectedItems(items);

      // 7. Save results to database
      await this.scanService.saveScanResults(jobId, normalizedItems);

      return {
        jobId,
        items: normalizedItems,
        scanType: job.scanType as ScanType,
      };
    } catch (error) {
      // Mark job as failed
      await this.scanService.markJobFailed(
        jobId,
        error instanceof Error ? error.message : 'Unknown error',
      );
      throw error;
    }
  }

  /**
   * Analyze receipt text using Gemini
   *
   * @param userId - User ID for authorization
   * @param text - OCR-extracted receipt text
   * @returns Detected food items
   */
  @Mutation(() => ScanResultResponse)
  @UseGuards(ThrottlerGuard)
  @Throttle({ default: { ttl: 60000, limit: 5 } })
  async analyzeReceiptText(
    @Args('userId') userId: string,
    @Args('text') text: string,
  ): Promise<ScanResultResponse> {
    let jobId: string;

    try {
      // 1. Hash receipt text for deduplication
      const contentHash = this.scanService.hashContent(text);

      // 2. Check for duplicate scan
      const duplicate = await this.scanService.findDuplicateScan(
        userId,
        contentHash,
      );
      if (duplicate && duplicate.results) {
        // Create a completed job referencing cached results
        const job = await this.scanService.createScanJob(
          userId,
          ScanType.RECEIPT,
          undefined,
          contentHash,
        );
        jobId = job.id;
        await this.scanService.saveScanResults(jobId, duplicate.results as any);
        return {
          jobId,
          items: duplicate.results as any,
          scanType: ScanType.RECEIPT,
        };
      }

      // 3. Create scan job in database
      const job = await this.scanService.createScanJob(
        userId,
        ScanType.RECEIPT,
        undefined,
        contentHash,
      );
      jobId = job.id;

      // Store OCR text for debugging
      await this.prisma.scanJob.update({
        where: { id: jobId },
        data: { ocrText: text },
      });

      // 4. Check free scan quota
      const scanCount = await this.scanService.getUserScanCount(userId);
      if (scanCount >= 1) {
        // Check for active subscription
        const subscription = await this.prisma.subscription.findFirst({
          where: {
            userId,
            isActive: true,
          },
        });

        if (!subscription) {
          throw new ForbiddenException(
            'Pro subscription required for additional scans',
          );
        }

        // 5. Check daily scan limit for Pro users
        const dailyCount = await this.scanService.getDailyScanCount(userId);
        if (dailyCount >= DAILY_SCAN_LIMIT) {
          throw new ForbiddenException(
            'Daily scan limit reached. Try again tomorrow.',
          );
        }
      }

      // 6. Analyze receipt text with Gemini
      const items = await this.scanAnalyzer.analyzeReceiptText(text);

      // 7. Normalize detected items via IngredientCatalog
      const normalizedItems = await this.scanService.normalizeDetectedItems(items);

      // 8. Save results to database
      await this.scanService.saveScanResults(jobId, normalizedItems);

      return {
        jobId,
        items: normalizedItems,
        scanType: ScanType.RECEIPT,
      };
    } catch (error) {
      // Mark job as failed if we have a jobId
      if (jobId!) {
        await this.scanService.markJobFailed(
          jobId,
          error instanceof Error ? error.message : 'Unknown error',
        );
      }
      throw error;
    }
  }
}
