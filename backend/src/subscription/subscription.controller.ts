import { Controller, Post, Body, Logger } from '@nestjs/common';
import { SubscriptionService } from './subscription.service';

interface AppleNotificationBody {
  signedPayload: string;
}

@Controller()
export class SubscriptionController {
  private readonly logger = new Logger(SubscriptionController.name);

  constructor(private subscriptionService: SubscriptionService) {}

  /**
   * Apple Server Notifications V2 webhook endpoint.
   * Apple sends POST requests to this endpoint with subscription lifecycle events.
   * No auth guard - JWS signature verification IS the authentication.
   *
   * @see https://developer.apple.com/documentation/appstoreservernotifications
   */
  @Post('apple/notifications')
  async handleAppleNotification(
    @Body() body: AppleNotificationBody,
  ): Promise<{ success: boolean }> {
    this.logger.log('Received Apple Server Notification');

    try {
      await this.subscriptionService.handleNotification(body.signedPayload);
      return { success: true };
    } catch (error) {
      this.logger.error('Failed to handle Apple notification', error);
      // Return success anyway to prevent Apple from retrying
      // (we log the error for investigation)
      return { success: true };
    }
  }
}
