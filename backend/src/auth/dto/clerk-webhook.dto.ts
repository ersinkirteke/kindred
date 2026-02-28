/**
 * Clerk webhook payload structure.
 * Matches Clerk's webhook event format for user.created, user.updated, and user.deleted events.
 *
 * Reference: https://clerk.com/docs/integrations/webhooks/overview
 */

export interface ClerkWebhookPayload {
  data: {
    id: string; // Clerk user ID
    email_addresses: Array<{
      email_address: string;
      id: string;
    }>;
    first_name?: string;
    last_name?: string;
    image_url?: string;
  };
  type: 'user.created' | 'user.updated' | 'user.deleted';
  object: 'event';
}
