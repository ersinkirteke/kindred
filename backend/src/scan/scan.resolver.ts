import { Resolver, Mutation, Args } from '@nestjs/graphql';
import { ForbiddenException, UseGuards } from '@nestjs/common';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { ClerkAuthGuard } from '../auth/auth.guard';
import {
  CurrentUser,
  CurrentUserContext,
} from '../common/decorators/current-user.decorator';
import { ScanService } from './scan.service';
import { ScanAnalyzerService } from './scan-analyzer.service';
import { ScanJobResponse, ScanType } from './dto/scan.dto';
import { ScanResultResponse } from './dto/scan-result.dto';
import { PrismaService } from '../prisma/prisma.service';

const DAILY_SCAN_LIMIT = 20;
const MAX_PHOTO_BASE64_LENGTH = 14_000_000; // ~10MB decoded

/**
 * GraphQL resolver for scan photo upload and analysis
 *
 * Phase 14-01: uploadScanPhoto mutation for R2 upload
 * Phase 15-01: analyzeScan and analyzeReceiptText with Gemini Vision
 */
@Resolver()
@UseGuards(ClerkAuthGuard)
export class ScanResolver {
  constructor(
    private readonly scanService: ScanService,
    private readonly scanAnalyzer: ScanAnalyzerService,
    private readonly prisma: PrismaService,
  ) {}

  /** Resolve clerkId to database userId */
  private async resolveUserId(clerkId: string): Promise<string> {
    const user = await this.prisma.user.findUnique({ where: { clerkId } });
    if (!user) throw new ForbiddenException('User not found');
    return user.id;
  }

  @Mutation(() => ScanJobResponse)
  async uploadScanPhoto(
    @CurrentUser() user: CurrentUserContext,
    @Args('scanType', { type: () => ScanType }) scanType: ScanType,
    @Args('photoData') photoData: string,
    @Args('userId', { nullable: true, deprecationReason: 'Derived from auth token' }) _userId?: string,
  ): Promise<ScanJobResponse> {
    // Validate base64 size before decoding to prevent memory exhaustion
    if (photoData.length > MAX_PHOTO_BASE64_LENGTH) {
      throw new ForbiddenException('Photo data exceeds maximum size (10MB)');
    }

    const userId = await this.resolveUserId(user.clerkId);
    const fileBuffer = Buffer.from(photoData, 'base64');
    const mimeType = 'image/jpeg';

    return this.scanService.uploadScanPhoto(userId, scanType, fileBuffer, mimeType);
  }

  @Mutation(() => ScanResultResponse)
  @UseGuards(ThrottlerGuard)
  @Throttle({ default: { ttl: 60000, limit: 5 } })
  async analyzeScan(
    @CurrentUser() userCtx: CurrentUserContext,
    @Args('jobId') jobId: string,
    @Args('userId', { nullable: true, deprecationReason: 'Derived from auth token' }) _userId?: string,
  ): Promise<ScanResultResponse> {
    const userId = await this.resolveUserId(userCtx.clerkId);

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
        const subscription = await this.prisma.subscription.findFirst({
          where: { userId, isActive: true },
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
      await this.scanService.markJobFailed(
        jobId,
        error instanceof Error ? error.message : 'Unknown error',
      );
      throw error;
    }
  }

  @Mutation(() => ScanResultResponse)
  @UseGuards(ThrottlerGuard)
  @Throttle({ default: { ttl: 60000, limit: 5 } })
  async analyzeReceiptText(
    @CurrentUser() userCtx: CurrentUserContext,
    @Args('text') text: string,
    @Args('userId', { nullable: true, deprecationReason: 'Derived from auth token' }) _userId?: string,
  ): Promise<ScanResultResponse> {
    const userId = await this.resolveUserId(userCtx.clerkId);
    let jobId: string;

    try {
      // 1. Hash receipt text for deduplication
      const contentHash = this.scanService.hashContent(text);

      // 2. Check for duplicate scan
      const duplicate = await this.scanService.findDuplicateScan(userId, contentHash);
      if (duplicate && duplicate.results) {
        const job = await this.scanService.createScanJob(userId, ScanType.RECEIPT, undefined, contentHash);
        jobId = job.id;
        await this.scanService.saveScanResults(jobId, duplicate.results as any);
        return { jobId, items: duplicate.results as any, scanType: ScanType.RECEIPT };
      }

      // 3. Create scan job
      const job = await this.scanService.createScanJob(userId, ScanType.RECEIPT, undefined, contentHash);
      jobId = job.id;

      await this.prisma.scanJob.update({
        where: { id: jobId },
        data: { ocrText: text },
      });

      // 4. Check free scan quota
      const scanCount = await this.scanService.getUserScanCount(userId);
      if (scanCount >= 1) {
        const subscription = await this.prisma.subscription.findFirst({
          where: { userId, isActive: true },
        });

        if (!subscription) {
          throw new ForbiddenException('Pro subscription required for additional scans');
        }

        const dailyCount = await this.scanService.getDailyScanCount(userId);
        if (dailyCount >= DAILY_SCAN_LIMIT) {
          throw new ForbiddenException('Daily scan limit reached. Try again tomorrow.');
        }
      }

      // 5. Analyze receipt text with Gemini
      const items = await this.scanAnalyzer.analyzeReceiptText(text);
      const normalizedItems = await this.scanService.normalizeDetectedItems(items);
      await this.scanService.saveScanResults(jobId, normalizedItems);

      return { jobId, items: normalizedItems, scanType: ScanType.RECEIPT };
    } catch (error) {
      if (jobId!) {
        await this.scanService.markJobFailed(jobId, error instanceof Error ? error.message : 'Unknown error');
      }
      throw error;
    }
  }
}
