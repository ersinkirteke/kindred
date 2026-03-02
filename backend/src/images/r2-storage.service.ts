import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  S3Client,
  PutObjectCommand,
  DeleteObjectCommand,
  PutObjectCommandInput,
  DeleteObjectCommandInput,
} from '@aws-sdk/client-s3';

/**
 * Service for managing image storage in Cloudflare R2 (S3-compatible)
 *
 * Cloudflare R2 provides zero-egress CDN delivery, making it cost-effective
 * for serving recipe hero images at scale.
 */
@Injectable()
export class R2StorageService {
  private readonly logger = new Logger(R2StorageService.name);
  private readonly s3Client: S3Client;
  private readonly bucketName: string;
  private readonly publicUrl: string;

  constructor(private readonly configService: ConfigService) {
    const accountId = this.configService.get<string>('CLOUDFLARE_ACCOUNT_ID', 'dummy');
    const accessKeyId = this.configService.get<string>('R2_ACCESS_KEY_ID', 'dummy');
    const secretAccessKey = this.configService.get<string>('R2_SECRET_ACCESS_KEY', 'dummy');
    this.bucketName = this.configService.get<string>('R2_BUCKET_NAME', 'kindred-images');
    this.publicUrl = this.configService.get<string>('R2_PUBLIC_URL', 'https://images.kindred.app');

    // Initialize S3 client with R2 endpoint
    this.s3Client = new S3Client({
      region: 'auto',
      endpoint: `https://${accountId}.r2.cloudflarestorage.com`,
      credentials: {
        accessKeyId,
        secretAccessKey,
      },
    });

    this.logger.log(`R2 Storage initialized for bucket: ${this.bucketName}`);
  }

  /**
   * Upload an image buffer to R2 storage
   *
   * @param imageBuffer - Binary image data
   * @param key - Object key/path (e.g., "recipes/{recipeId}/hero.jpg")
   * @param contentType - MIME type (default: image/jpeg)
   * @returns Public CDN URL for the uploaded image
   * @throws Error if upload fails
   */
  async uploadImage(
    imageBuffer: Buffer,
    key: string,
    contentType: string = 'image/jpeg',
  ): Promise<string> {
    try {
      const command: PutObjectCommandInput = {
        Bucket: this.bucketName,
        Key: key,
        Body: imageBuffer,
        ContentType: contentType,
      };

      await this.s3Client.send(new PutObjectCommand(command));

      const publicUrl = `${this.publicUrl}/${key}`;
      this.logger.log(`Image uploaded successfully: ${key} -> ${publicUrl}`);

      return publicUrl;
    } catch (error) {
      this.logger.error(`Failed to upload image to R2: ${key}`, error);
      throw new Error(`R2 upload failed: ${error.message}`);
    }
  }

  /**
   * Delete an image from R2 storage
   *
   * Used for cleanup or when regenerating images for a recipe.
   *
   * @param key - Object key/path to delete
   * @throws Error if deletion fails
   */
  async deleteImage(key: string): Promise<void> {
    try {
      const command: DeleteObjectCommandInput = {
        Bucket: this.bucketName,
        Key: key,
      };

      await this.s3Client.send(new DeleteObjectCommand(command));
      this.logger.log(`Image deleted successfully: ${key}`);
    } catch (error) {
      this.logger.error(`Failed to delete image from R2: ${key}`, error);
      throw new Error(`R2 deletion failed: ${error.message}`);
    }
  }

  /**
   * Upload a voice sample to R2 storage
   *
   * Stores audio files for voice cloning backup and compliance.
   *
   * @param userId - User ID for key generation
   * @param audioBuffer - Binary audio data (MP3)
   * @returns Public CDN URL for the uploaded voice sample
   * @throws Error if upload fails
   */
  async uploadVoiceSample(userId: string, audioBuffer: Buffer): Promise<string> {
    const key = `voice-samples/${userId}/${Date.now()}.mp3`;

    try {
      const command: PutObjectCommandInput = {
        Bucket: this.bucketName,
        Key: key,
        Body: audioBuffer,
        ContentType: 'audio/mpeg',
      };

      await this.s3Client.send(new PutObjectCommand(command));

      const publicUrl = `${this.publicUrl}/${key}`;
      this.logger.log(`Voice sample uploaded successfully: ${key} -> ${publicUrl}`);

      return publicUrl;
    } catch (error) {
      this.logger.error(`Failed to upload voice sample to R2: ${key}`, error);
      throw new Error(`R2 voice sample upload failed: ${error.message}`);
    }
  }

  /**
   * Delete a voice sample from R2 storage
   *
   * Used for cleanup when user deletes their voice profile.
   *
   * @param url - Public URL of the voice sample
   */
  async deleteVoiceSample(url: string): Promise<void> {
    try {
      // Extract key from URL (e.g., "https://cdn.example.com/voice-samples/user123/123456.mp3" -> "voice-samples/user123/123456.mp3")
      const key = url.replace(`${this.publicUrl}/`, '');

      const command: DeleteObjectCommandInput = {
        Bucket: this.bucketName,
        Key: key,
      };

      await this.s3Client.send(new DeleteObjectCommand(command));
      this.logger.log(`Voice sample deleted successfully: ${key}`);
    } catch (error) {
      // Swallow errors if file already deleted
      this.logger.warn(`Failed to delete voice sample (may already be deleted): ${url}`, error);
    }
  }
}
