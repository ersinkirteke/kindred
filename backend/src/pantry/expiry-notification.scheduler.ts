import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { PantryService } from './pantry.service';
import { PushService } from '../push/push.service';
import { PrismaService } from '../prisma/prisma.service';

interface NotificationPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

/**
 * Scheduled expiry digest notifications
 *
 * Daily cron job queries items expiring soon, groups by user,
 * sends personalized FCM push notifications.
 *
 * MVP: Batch notification at 8 AM UTC (morning across Europe/Americas)
 * Future: Per-timezone delivery requires storing user timezone and
 *         scheduling per-zone batches at 9 AM local time
 *
 * Phase 17-01: Expiry tracking backend
 */
@Injectable()
export class ExpiryNotificationScheduler {
  private readonly logger = new Logger(ExpiryNotificationScheduler.name);

  constructor(
    private readonly pantryService: PantryService,
    private readonly pushService: PushService,
    private readonly prisma: PrismaService,
  ) {}

  /**
   * Daily expiry digest at 8 AM UTC (MVP)
   *
   * TODO: Per-timezone delivery — store user timezone, schedule per-zone batches
   * (CONTEXT.md: "9 AM local time")
   */
  @Cron('0 8 * * *', {
    name: 'expiry-digest',
    timeZone: 'UTC',
  })
  async handleExpiryDigest() {
    this.logger.log('Starting expiry digest notification job (8:00 AM UTC)');

    try {
      // Get items expiring within the next 2 days (with userId for grouping)
      const expiringItems =
        await this.pantryService.getExpiringItemsWithUser({
          daysAhead: 2,
        });

      if (expiringItems.length === 0) {
        this.logger.log('No items expiring soon — skipping notifications');
        return;
      }

      // Group items by userId
      const itemsByUser = new Map<string, any[]>();
      for (const item of expiringItems) {
        const userId = item.userId;
        if (!itemsByUser.has(userId)) {
          itemsByUser.set(userId, []);
        }
        itemsByUser.get(userId)!.push(item);
      }

      this.logger.log(
        `Found ${expiringItems.length} items expiring soon for ${itemsByUser.size} users`,
      );

      // Send notification to each user
      for (const [userId, items] of itemsByUser) {
        await this.sendExpiryNotification(userId, items);
      }

      this.logger.log('Expiry digest notifications sent successfully');
    } catch (error) {
      this.logger.error(
        `Expiry digest notification job failed: ${error.message}`,
        error.stack,
      );
    }
  }

  /**
   * Send personalized expiry notification to a single user.
   */
  private async sendExpiryNotification(userId: string, items: any[]) {
    try {
      // Check if user enabled expiry alerts
      const prefs = await this.prisma.notificationPreferences.findUnique({
        where: { userId },
      });

      // Default to enabled if no preferences record exists (all default true)
      if (prefs && !prefs.expiryAlerts) {
        this.logger.debug(`User ${userId} disabled expiry alerts, skipping`);
        return;
      }

      const notification = this.buildNotificationMessage(items);
      await this.pushService.sendToUser(userId, notification);

      // Log notification for analytics
      await this.prisma.notificationLog.create({
        data: { userId, type: 'EXPIRY', sentAt: new Date() },
      });

      this.logger.debug(
        `Sent expiry notification to user ${userId} (${items.length} items)`,
      );
    } catch (error) {
      this.logger.error(
        `Failed to send notification to user ${userId}: ${error.message}`,
      );
    }
  }

  /**
   * Build personalized notification message based on expiring items.
   * Warm, helpful tone matching Kindred personality.
   */
  private buildNotificationMessage(items: any[]): NotificationPayload {
    const count = items.length;

    if (count === 1) {
      const item = items[0];
      return {
        title: 'Pantry Reminder',
        body: `Your ${item.name} expires soon — time to use it up! 🍳`,
        data: { type: 'expiry_digest' },
      };
    }

    if (count === 2) {
      return {
        title: 'Pantry Reminder',
        body: `Your ${items[0].name} and ${items[1].name} expire soon — check your pantry!`,
        data: { type: 'expiry_digest' },
      };
    }

    // 3+ items
    return {
      title: 'Pantry Reminder',
      body: `${count} items expire soon (${items[0].name}, ${items[1].name}, and more)`,
      data: { type: 'expiry_digest' },
    };
  }
}
