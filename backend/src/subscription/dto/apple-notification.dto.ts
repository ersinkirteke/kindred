/**
 * Apple Server Notifications V2 type definitions.
 * These are NOT validation DTOs (no class-validator decorators).
 * Used internally for type safety only.
 *
 * @see https://developer.apple.com/documentation/appstoreservernotifications
 */

export interface AppleNotificationPayload {
  signedPayload: string;
}

/**
 * Apple Server Notifications V2 notification types.
 * Subset of most common types used in subscription lifecycle.
 */
export type AppleNotificationType =
  | 'SUBSCRIBED'
  | 'DID_RENEW'
  | 'DID_FAIL_TO_RENEW'
  | 'DID_CHANGE_RENEWAL_STATUS'
  | 'EXPIRED'
  | 'GRACE_PERIOD_EXPIRED'
  | 'REFUND'
  | 'REVOKE'
  | 'CONSUMPTION_REQUEST'
  | 'RENEWAL_EXTENDED'
  | 'RENEWAL_EXTENSION'
  | 'PRICE_INCREASE'
  | 'OFFER_REDEEMED';
