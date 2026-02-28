import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ImagesService } from './images.service';

interface ImageJob {
  recipeId: string;
  recipeName: string;
  ingredients: string[];
}

/**
 * Background processor for image generation queue
 *
 * Simple in-memory queue for MVP. Processes image generation jobs
 * asynchronously with rate limiting to stay within Imagen API quotas.
 *
 * Future: Upgrade to BullMQ with Redis when scaling to multiple instances.
 */
@Injectable()
export class ImageGenerationProcessor implements OnModuleInit {
  private readonly logger = new Logger(ImageGenerationProcessor.name);
  private readonly queue: ImageJob[] = [];
  private isProcessing = false;
  private readonly concurrency = 3; // Process up to 3 images in parallel
  private readonly rateLimit = 10; // Max 10 images per minute
  private readonly rateLimitWindow = 60000; // 1 minute in milliseconds
  private generationsInWindow = 0;
  private windowStartTime = Date.now();

  constructor(private readonly imagesService: ImagesService) {}

  /**
   * Start the background queue processor when module initializes
   */
  onModuleInit() {
    this.logger.log('Image generation processor initialized');
    this.startQueueProcessor();
  }

  /**
   * Add an image generation job to the queue
   *
   * @param job - Image generation job details
   */
  enqueue(job: ImageJob): void {
    this.queue.push(job);
    this.logger.log(
      `Enqueued image generation for recipe ${job.recipeId} (${job.recipeName}). Queue size: ${this.queue.length}`,
    );
  }

  /**
   * Get current queue size
   */
  getQueueSize(): number {
    return this.queue.length;
  }

  /**
   * Start the background queue processor
   * Checks queue every 5 seconds and processes jobs with rate limiting
   */
  private startQueueProcessor(): void {
    setInterval(() => {
      if (!this.isProcessing && this.queue.length > 0) {
        this.processQueue();
      }
    }, 5000); // Check every 5 seconds
  }

  /**
   * Process pending jobs from the queue
   * Respects rate limits and concurrency limits
   */
  private async processQueue(): Promise<void> {
    if (this.queue.length === 0) {
      return;
    }

    this.isProcessing = true;
    this.logger.log(`Processing image generation queue (${this.queue.length} pending)`);

    try {
      // Reset rate limit window if needed
      const now = Date.now();
      if (now - this.windowStartTime >= this.rateLimitWindow) {
        this.generationsInWindow = 0;
        this.windowStartTime = now;
      }

      // Process jobs in batches with concurrency and rate limiting
      const batchSize = Math.min(
        this.concurrency,
        this.rateLimit - this.generationsInWindow,
        this.queue.length,
      );

      if (batchSize === 0) {
        this.logger.warn(
          'Rate limit reached. Waiting for next rate limit window.',
        );
        this.isProcessing = false;
        return;
      }

      // Dequeue batch
      const batch = this.queue.splice(0, batchSize);
      this.logger.log(
        `Processing batch of ${batch.length} images (${this.queue.length} remaining in queue)`,
      );

      // Process batch in parallel
      const results = await Promise.allSettled(
        batch.map((job, index) =>
          this.processJob(job, index + 1, batch.length),
        ),
      );

      // Update rate limit counter
      this.generationsInWindow += batch.length;

      // Log results
      const successful = results.filter((r) => r.status === 'fulfilled').length;
      const failed = results.filter((r) => r.status === 'rejected').length;

      this.logger.log(
        `Batch complete: ${successful} successful, ${failed} failed. Rate limit: ${this.generationsInWindow}/${this.rateLimit} per minute`,
      );
    } catch (error) {
      this.logger.error('Queue processing error:', error);
    } finally {
      this.isProcessing = false;
    }
  }

  /**
   * Process a single image generation job
   *
   * @param job - Image generation job
   * @param index - Job index in batch (for logging)
   * @param total - Total jobs in batch (for logging)
   */
  private async processJob(
    job: ImageJob,
    index: number,
    total: number,
  ): Promise<void> {
    this.logger.log(
      `Processing image ${index}/${total} for recipe "${job.recipeName}" (${job.recipeId})`,
    );

    try {
      const imageUrl = await this.imagesService.generateAndStoreImage(
        job.recipeId,
        job.recipeName,
        job.ingredients,
      );

      if (imageUrl) {
        this.logger.log(
          `✓ Image generated successfully for "${job.recipeName}": ${imageUrl}`,
        );
      } else {
        this.logger.warn(
          `✗ Image generation failed for "${job.recipeName}" (marked as FAILED)`,
        );
      }
    } catch (error) {
      this.logger.error(
        `Image generation error for "${job.recipeName}":`,
        error,
      );
      throw error;
    }
  }
}
