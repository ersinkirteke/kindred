import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { PrismaService } from '../prisma/prisma.service';
import { PushService } from '../push/push.service';

interface NotificationPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

/**
 * Scheduled engagement nudge notifications
 *
 * Daily cron job detects inactive users (7+ days since last activity)
 * and sends re-engagement push notifications.
 *
 * Rate limiting: Max 3 notifications per user per week to avoid being annoying.
 * Respects NotificationPreferences.engagement opt-out.
 *
 * Activity tracked via DeviceToken.updatedAt (updated on app launch).
 *
 * Phase 19-03: Production Hardening - Engagement Notifications
 */
@Injectable()
export class EngagementNotificationScheduler {
  private readonly logger = new Logger(EngagementNotificationScheduler.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly pushService: PushService,
  ) {}

  /**
   * Daily engagement nudge at 10:00 AM UTC
   *
   * Detects users inactive for 7+ days, checks preferences and rate limits,
   * sends friendly re-engagement push notification.
   */
  @Cron('0 10 * * *', {
    name: 'engagement-nudge',
    timeZone: 'UTC',
  })
  async handleEngagementNudge() {
    this.logger.log('Starting engagement nudge notification job (10:00 AM UTC)');

    try {
      const sevenDaysAgo = new Date();
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

      const weekAgo = new Date();
      weekAgo.setDate(weekAgo.getDate() - 7);

      // Find inactive users: last device token update > 7 days ago
      // Group by userId to get most recent activity per user
      const inactiveUsers = await this.prisma.deviceToken.groupBy({
        by: ['userId'],
        where: {
          updatedAt: { lt: sevenDaysAgo },
        },
        _max: {
          updatedAt: true,
        },
      });

      if (inactiveUsers.length === 0) {
        this.logger.log('No inactive users found — skipping engagement notifications');
        return;
      }

      this.logger.log(
        `Found ${inactiveUsers.length} users inactive for 7+ days`,
      );

      let sentCount = 0;
      let skippedCount = 0;

      // Process each inactive user
      for (const user of inactiveUsers) {
        const userId = user.userId;

        // Check notification preferences
        const prefs = await this.prisma.notificationPreferences.findUnique({
          where: { userId },
        });

        // Skip if user disabled engagement notifications
        if (prefs && !prefs.engagement) {
          this.logger.debug(`User ${userId} disabled engagement notifications, skipping`);
          skippedCount++;
          continue;
        }

        // Check weekly rate limit: max 3 notifications per week
        const notificationCount = await this.prisma.notificationLog.count({
          where: {
            userId,
            type: 'ENGAGEMENT',
            sentAt: { gte: weekAgo },
          },
        });

        if (notificationCount >= 3) {
          this.logger.debug(`User ${userId} already received 3 engagement notifications this week, skipping`);
          skippedCount++;
          continue;
        }

        // Send engagement nudge
        await this.sendEngagementNudge(userId);
        sentCount++;
      }

      this.logger.log(
        `Engagement nudge notifications complete. Sent: ${sentCount}, Skipped: ${skippedCount}`,
      );
    } catch (error) {
      this.logger.error(
        `Engagement nudge notification job failed: ${error.message}`,
        error.stack,
      );
    }
  }

  /**
   * Send engagement nudge notification to a single user.
   */
  private async sendEngagementNudge(userId: string) {
    try {
      const notification: NotificationPayload = {
        title: 'Missing you in the kitchen!',
        body: 'Check out the latest trending recipes in your area',
        data: { type: 'engagement_nudge' },
      };

      await this.pushService.sendToUser(userId, notification);

      // Log notification for rate limiting and analytics
      await this.prisma.notificationLog.create({
        data: { userId, type: 'ENGAGEMENT', sentAt: new Date() },
      });

      this.logger.debug(`Sent engagement nudge to user ${userId}`);
    } catch (error) {
      this.logger.error(
        `Failed to send engagement nudge to user ${userId}: ${error.message}`,
      );
    }
  }
}
