import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';
import { PrismaService } from '../prisma/prisma.service';
import { DeviceToken, Platform } from '@prisma/client';

interface NotificationPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

interface SendResult {
  success: number;
  failures: number;
}

/**
 * Push notification service using Firebase Cloud Messaging (FCM).
 *
 * Features:
 * - Multi-device support (one user can have multiple device tokens)
 * - Platform-specific payloads (APNs for iOS, FCM for Android)
 * - Automatic cleanup of invalid tokens (uninstalled apps)
 * - Batch sending for multiple users (up to 500 devices per batch)
 * - Graceful degradation when Firebase credentials are not provided
 */
@Injectable()
export class PushService implements OnModuleInit {
  private readonly logger = new Logger(PushService.name);
  private firebaseApp: admin.app.App | null = null;
  private isFirebaseEnabled = false;

  constructor(
    private configService: ConfigService,
    private prisma: PrismaService,
  ) {}

  onModuleInit() {
    const serviceAccountPath = this.configService.get<string>(
      'FIREBASE_SERVICE_ACCOUNT_PATH',
    );

    if (!serviceAccountPath) {
      this.logger.warn(
        'FIREBASE_SERVICE_ACCOUNT_PATH not set. Push notifications disabled. Set this env var to enable FCM.',
      );
      return;
    }

    try {
      // Initialize Firebase Admin SDK
      const serviceAccount = require(serviceAccountPath);
      this.firebaseApp = admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      this.isFirebaseEnabled = true;
      this.logger.log('Firebase Cloud Messaging initialized successfully');
    } catch (error) {
      this.logger.error(
        `Failed to initialize Firebase: ${error.message}. Push notifications disabled.`,
      );
    }
  }

  /**
   * Register or update a device token for push notifications.
   * One user can have multiple devices (phone + tablet).
   */
  async registerDeviceToken(
    userId: string,
    token: string,
    platform: Platform,
  ): Promise<DeviceToken> {
    this.logger.debug(
      `Registering device token for user ${userId} on ${platform}`,
    );

    return this.prisma.deviceToken.upsert({
      where: { token },
      update: {
        userId,
        platform,
        updatedAt: new Date(),
      },
      create: {
        userId,
        token,
        platform,
      },
    });
  }

  /**
   * Remove a device token (called when token becomes invalid).
   */
  async removeDeviceToken(token: string): Promise<void> {
    this.logger.debug(`Removing device token: ${token}`);
    await this.prisma.deviceToken.delete({
      where: { token },
    });
  }

  /**
   * Send a push notification to all devices registered for a user.
   * Returns success/failure counts.
   * Automatically removes invalid tokens (uninstalled apps).
   */
  async sendToUser(
    userId: string,
    notification: NotificationPayload,
  ): Promise<SendResult> {
    if (!this.isFirebaseEnabled) {
      this.logger.warn(
        'Firebase not initialized. Cannot send push notification.',
      );
      return { success: 0, failures: 0 };
    }

    // Find all device tokens for this user
    const deviceTokens = await this.prisma.deviceToken.findMany({
      where: { userId },
    });

    if (deviceTokens.length === 0) {
      this.logger.debug(`No device tokens found for user ${userId}`);
      return { success: 0, failures: 0 };
    }

    // Group tokens by platform for optimized sending
    const iosTokens = deviceTokens
      .filter((dt) => dt.platform === Platform.IOS)
      .map((dt) => dt.token);
    const androidTokens = deviceTokens
      .filter((dt) => dt.platform === Platform.ANDROID)
      .map((dt) => dt.token);

    let successCount = 0;
    let failureCount = 0;

    // Send to iOS devices (with APNs headers)
    if (iosTokens.length > 0) {
      const iosResult = await this.sendMulticast(iosTokens, notification, true);
      successCount += iosResult.success;
      failureCount += iosResult.failures;
    }

    // Send to Android devices (with FCM notification channel)
    if (androidTokens.length > 0) {
      const androidResult = await this.sendMulticast(
        androidTokens,
        notification,
        false,
      );
      successCount += androidResult.success;
      failureCount += androidResult.failures;
    }

    return { success: successCount, failures: failureCount };
  }

  /**
   * Send a push notification to multiple users in batches.
   * Used for expiry alerts and engagement nudges.
   */
  async sendToMultipleUsers(
    userIds: string[],
    notification: NotificationPayload,
  ): Promise<void> {
    if (!this.isFirebaseEnabled) {
      this.logger.warn(
        'Firebase not initialized. Cannot send push notifications.',
      );
      return;
    }

    this.logger.log(
      `Sending notification to ${userIds.length} users: "${notification.title}"`,
    );

    // Process in parallel for better performance
    const results = await Promise.allSettled(
      userIds.map((userId) => this.sendToUser(userId, notification)),
    );

    const totalSuccess = results
      .filter((r) => r.status === 'fulfilled')
      .reduce((sum, r) => sum + (r as any).value.success, 0);
    const totalFailures = results
      .filter((r) => r.status === 'fulfilled')
      .reduce((sum, r) => sum + (r as any).value.failures, 0);

    this.logger.log(
      `Batch send complete. Success: ${totalSuccess}, Failures: ${totalFailures}`,
    );
  }

  /**
   * Send a test notification to verify push is working.
   */
  async sendTestNotification(userId: string): Promise<boolean> {
    const result = await this.sendToUser(userId, {
      title: 'Kindred',
      body: 'Push notifications are working!',
      data: { type: 'test' },
    });

    return result.success > 0;
  }

  /**
   * Internal: Send multicast message to multiple tokens.
   * Handles platform-specific payloads and invalid token cleanup.
   */
  private async sendMulticast(
    tokens: string[],
    notification: NotificationPayload,
    isIOS: boolean,
  ): Promise<SendResult> {
    if (!this.firebaseApp) {
      this.logger.error('Firebase app not initialized');
      return { success: 0, failures: tokens.length };
    }

    const messaging = admin.messaging(this.firebaseApp);

    // Build platform-specific message
    const message: admin.messaging.MulticastMessage = {
      tokens,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: notification.data || {},
    };

    // Add iOS-specific APNs config
    if (isIOS) {
      message.apns = {
        headers: {
          'apns-priority': '10',
        },
        payload: {
          aps: {
            sound: 'default',
          },
        },
      };
    }

    // Add Android-specific FCM config
    if (!isIOS) {
      message.android = {
        notification: {
          channelId: 'default',
        },
      };
    }

    try {
      // Send in batches of 500 (FCM limit)
      const batchSize = 500;
      let successCount = 0;
      let failureCount = 0;

      for (let i = 0; i < tokens.length; i += batchSize) {
        const batchTokens = tokens.slice(i, i + batchSize);
        const batchMessage = { ...message, tokens: batchTokens };

        const response = await messaging.sendEachForMulticast(batchMessage);

        successCount += response.successCount;
        failureCount += response.failureCount;

        // Clean up invalid tokens
        const invalidTokens: string[] = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            const errorCode = resp.error?.code;
            // Remove tokens that are no longer valid
            if (
              errorCode === 'messaging/invalid-registration-token' ||
              errorCode === 'messaging/registration-token-not-registered'
            ) {
              invalidTokens.push(batchTokens[idx]);
            }
          }
        });

        // Remove invalid tokens from database
        if (invalidTokens.length > 0) {
          this.logger.debug(
            `Removing ${invalidTokens.length} invalid tokens from database`,
          );
          await Promise.all(
            invalidTokens.map((token) => this.removeDeviceToken(token)),
          );
        }
      }

      return { success: successCount, failures: failureCount };
    } catch (error) {
      this.logger.error(`Failed to send multicast message: ${error.message}`);
      return { success: 0, failures: tokens.length };
    }
  }
}
