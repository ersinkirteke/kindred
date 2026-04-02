import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GraphQLError } from 'graphql';
import { PrismaService } from '../prisma/prisma.service';
import { GraphQLErrorCode } from '../common/errors/graphql-error-codes.enum';
import {
  SignedDataVerifier,
  Environment,
  JWSTransactionDecodedPayload,
  ResponseBodyV2DecodedPayload,
  VerificationException,
} from '@apple/app-store-server-library';
import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class SubscriptionService implements OnModuleInit {
  private readonly logger = new Logger(SubscriptionService.name);
  private productionVerifier: SignedDataVerifier;
  private sandboxVerifier: SignedDataVerifier;
  private allowedProductIds: Set<string>;
  private bundleId: string;

  constructor(
    private prisma: PrismaService,
    private configService: ConfigService,
  ) {}

  onModuleInit() {
    // Get required configuration
    const bundleId = this.configService.get<string>('APPLE_BUNDLE_ID');
    if (!bundleId) {
      this.logger.warn('APPLE_BUNDLE_ID not configured - subscription verification disabled');
      return;
    }
    this.bundleId = bundleId;

    const appAppleIdStr = this.configService.get<string>('APPLE_APP_ID');
    const appAppleId = appAppleIdStr ? Number(appAppleIdStr) : undefined;
    if (!appAppleId) {
      this.logger.warn('APPLE_APP_ID not set - subscription verification disabled');
      return;
    }

    // Load Apple Root CA certificates
    const certDir = path.join(__dirname, '../../config/certs');
    const rootCAG2 = fs.readFileSync(path.join(certDir, 'AppleRootCA-G2.cer'));
    const rootCAG3 = fs.readFileSync(path.join(certDir, 'AppleRootCA-G3.cer'));
    const rootCAs = [rootCAG2, rootCAG3];

    // Parse allowed product IDs
    const productIdsEnv = this.configService.get<string>('APPLE_ALLOWED_PRODUCT_IDS', 'com.kindred.pro.monthly');
    this.allowedProductIds = new Set(productIdsEnv.split(',').map(id => id.trim()));
    this.logger.log(`Allowed product IDs: ${Array.from(this.allowedProductIds).join(', ')}`);

    // Initialize verifiers
    this.productionVerifier = new SignedDataVerifier(
      rootCAs,
      true, // enableOnlineChecks
      Environment.PRODUCTION,
      this.bundleId,
      appAppleId,
    );

    this.sandboxVerifier = new SignedDataVerifier(
      rootCAs,
      true, // enableOnlineChecks
      Environment.SANDBOX,
      this.bundleId,
      undefined, // appAppleId not required for sandbox
    );

    this.logger.log('SignedDataVerifier initialized for production and sandbox');
  }

  async verifyAndSyncSubscription(clerkId: string, jwsRepresentation: string): Promise<boolean> {
    if (!this.productionVerifier) {
      throw new GraphQLError('Subscription verification is not configured', {
        extensions: { code: GraphQLErrorCode.SUBSCRIPTION_VERIFICATION_FAILED },
      });
    }

    try {
      // Resolve database userId from clerkId
      const user = await this.prisma.user.findUnique({ where: { clerkId } });
      if (!user) {
        throw new GraphQLError('User not found', {
          extensions: { code: GraphQLErrorCode.USER_NOT_FOUND },
        });
      }

      const userId = user.id;
      let transaction: JWSTransactionDecodedPayload;
      let environment: Environment;

      // Try production verifier first, then sandbox fallback
      try {
        transaction = await this.productionVerifier.verifyAndDecodeTransaction(jwsRepresentation);
        environment = Environment.PRODUCTION;
        this.logger.log(`Transaction verified in PRODUCTION environment for user ${userId}`);
      } catch (productionError) {
        if (productionError instanceof VerificationException) {
          this.logger.debug(`Production verification failed, trying sandbox: ${productionError.message}`);
          try {
            transaction = await this.sandboxVerifier.verifyAndDecodeTransaction(jwsRepresentation);
            environment = Environment.SANDBOX;
            this.logger.log(`Transaction verified in SANDBOX environment for user ${userId}`);
          } catch (sandboxError) {
            // Both verifiers failed
            await this.prisma.transactionHistory.create({
              data: {
                userId,
                jwsPayload: jwsRepresentation,
                environment: 'UNKNOWN',
                verificationResult: 'FAILURE',
                errorMessage: `Production error: ${productionError.message}. Sandbox error: ${sandboxError.message}`,
                receivedAt: new Date(),
              },
            });

            throw new GraphQLError('Transaction verification failed', {
              extensions: {
                code: GraphQLErrorCode.SUBSCRIPTION_VERIFICATION_FAILED,
                details: 'Unable to verify transaction in production or sandbox',
              },
            });
          }
        } else {
          throw productionError;
        }
      }

      // Validate product ID against allowlist
      if (!transaction.productId || !this.allowedProductIds.has(transaction.productId)) {
        await this.prisma.transactionHistory.create({
          data: {
            userId,
            transactionId: transaction.transactionId,
            originalTransactionId: transaction.originalTransactionId,
            productId: transaction.productId,
            jwsPayload: jwsRepresentation,
            environment: environment === Environment.PRODUCTION ? 'PRODUCTION' : 'SANDBOX',
            verificationResult: 'FAILURE',
            errorMessage: `Product ID ${transaction.productId} not in allowed list`,
            receivedAt: new Date(),
          },
        });

        throw new GraphQLError('Invalid product ID', {
          extensions: {
            code: GraphQLErrorCode.SUBSCRIPTION_INVALID,
            details: `Product ${transaction.productId} is not allowed`,
          },
        });
      }

      // Check if subscription is expired
      const expiresDate = transaction.expiresDate ? new Date(transaction.expiresDate) : null;
      const isActive = expiresDate ? expiresDate > new Date() : false;

      // Store success in TransactionHistory
      await this.prisma.transactionHistory.create({
        data: {
          userId,
          transactionId: transaction.transactionId,
          originalTransactionId: transaction.originalTransactionId,
          productId: transaction.productId,
          jwsPayload: jwsRepresentation,
          environment: environment === Environment.PRODUCTION ? 'PRODUCTION' : 'SANDBOX',
          verificationResult: 'SUCCESS',
          expiresDate,
          receivedAt: new Date(),
        },
      });

      // Upsert subscription record
      await this.prisma.subscription.upsert({
        where: { userId },
        create: {
          userId,
          productId: transaction.productId || 'unknown',
          transactionId: transaction.transactionId || 'unknown',
          originalTransactionId: transaction.originalTransactionId || 'unknown',
          expiresDate: expiresDate || new Date(),
          isActive,
          jwsPayload: jwsRepresentation,
        },
        update: {
          transactionId: transaction.transactionId || 'unknown',
          expiresDate: expiresDate || new Date(),
          isActive,
          jwsPayload: jwsRepresentation,
          updatedAt: new Date(),
        },
      });

      if (!isActive) {
        throw new GraphQLError('Subscription has expired', {
          extensions: { code: GraphQLErrorCode.SUBSCRIPTION_EXPIRED },
        });
      }

      return true;
    } catch (error) {
      if (error instanceof GraphQLError) {
        throw error;
      }
      this.logger.error(`JWS verification failed for clerkId ${clerkId}`, error);
      throw new GraphQLError('Subscription verification failed', {
        extensions: { code: GraphQLErrorCode.SUBSCRIPTION_VERIFICATION_FAILED },
      });
    }
  }

  async handleNotification(signedPayload: string): Promise<void> {
    if (!this.productionVerifier) {
      this.logger.warn('Subscription verification not configured, ignoring notification');
      return;
    }

    try {
      let decodedPayload: ResponseBodyV2DecodedPayload;
      let environment: Environment;

      // Try production verifier first, then sandbox fallback
      try {
        decodedPayload = await this.productionVerifier.verifyAndDecodeNotification(signedPayload);
        environment = Environment.PRODUCTION;
      } catch (productionError) {
        if (productionError instanceof VerificationException) {
          try {
            decodedPayload = await this.sandboxVerifier.verifyAndDecodeNotification(signedPayload);
            environment = Environment.SANDBOX;
          } catch (sandboxError) {
            this.logger.error('Failed to verify notification in both environments', sandboxError);
            return;
          }
        } else {
          throw productionError;
        }
      }

      const notificationType = decodedPayload.notificationType;
      const signedTransactionInfo = decodedPayload.data?.signedTransactionInfo;

      // Store notification in TransactionHistory
      let transaction: JWSTransactionDecodedPayload | null = null;
      if (signedTransactionInfo) {
        try {
          transaction = environment === Environment.PRODUCTION
            ? await this.productionVerifier.verifyAndDecodeTransaction(signedTransactionInfo)
            : await this.sandboxVerifier.verifyAndDecodeTransaction(signedTransactionInfo);

          await this.prisma.transactionHistory.create({
            data: {
              transactionId: transaction.transactionId,
              originalTransactionId: transaction.originalTransactionId,
              productId: transaction.productId,
              jwsPayload: signedTransactionInfo,
              environment: environment === Environment.PRODUCTION ? 'PRODUCTION' : 'SANDBOX',
              verificationResult: 'SUCCESS',
              expiresDate: transaction.expiresDate ? new Date(transaction.expiresDate) : null,
              notificationType,
              receivedAt: new Date(),
            },
          });
        } catch (error) {
          this.logger.error('Failed to verify transaction in notification', error);
        }
      }

      // Handle notification based on type
      switch (notificationType) {
        case 'EXPIRED':
          if (transaction?.originalTransactionId) {
            await this.revokeSubscription(transaction.originalTransactionId);
            this.logger.log(`Subscription expired and revoked: ${transaction.originalTransactionId}`);
          }
          break;

        case 'DID_FAIL_TO_RENEW':
          // Grace period - do NOT revoke
          this.logger.warn(`Subscription failed to renew (grace period): ${transaction?.originalTransactionId}`);
          break;

        case 'DID_RENEW':
          if (transaction) {
            await this.updateSubscriptionExpiry(transaction);
            this.logger.log(`Subscription renewed: ${transaction.originalTransactionId}`);
          }
          break;

        case 'SUBSCRIBED':
        case 'DID_CHANGE_RENEWAL_STATUS':
          if (transaction) {
            await this.upsertSubscriptionFromTransaction(transaction);
            this.logger.log(`Subscription upserted: ${transaction.originalTransactionId}`);
          }
          break;

        case 'REFUND':
        case 'REVOKE':
          if (transaction?.originalTransactionId) {
            await this.revokeSubscription(transaction.originalTransactionId);
            this.logger.log(`Subscription refunded/revoked: ${transaction.originalTransactionId}`);
          }
          break;

        default:
          this.logger.debug(`Unhandled notification type: ${notificationType}`);
      }
    } catch (error) {
      this.logger.error('Error handling Apple notification', error);
    }
  }

  async checkVoiceSlotLimit(userId: string): Promise<{ allowed: boolean; currentCount: number; limit: number }> {
    const subscription = await this.prisma.subscription.findUnique({ where: { userId } });
    const isPro = subscription?.isActive ?? false;
    const voiceCount = await this.prisma.voiceProfile.count({ where: { userId } });
    const limit = isPro ? Infinity : 1;

    return {
      allowed: voiceCount < limit,
      currentCount: voiceCount,
      limit: isPro ? -1 : 1, // -1 = unlimited
    };
  }

  async resolveUserId(clerkId: string): Promise<string> {
    const user = await this.prisma.user.findUnique({ where: { clerkId } });
    if (!user) {
      throw new GraphQLError('User not found', {
        extensions: { code: GraphQLErrorCode.USER_NOT_FOUND },
      });
    }
    return user.id;
  }

  private async revokeSubscription(originalTransactionId: string): Promise<void> {
    await this.prisma.subscription.updateMany({
      where: { originalTransactionId },
      data: { isActive: false },
    });
  }

  private async updateSubscriptionExpiry(transaction: JWSTransactionDecodedPayload): Promise<void> {
    if (!transaction.expiresDate) return;

    const expiresDate = new Date(transaction.expiresDate);
    const isActive = expiresDate > new Date();

    await this.prisma.subscription.updateMany({
      where: { originalTransactionId: transaction.originalTransactionId || 'unknown' },
      data: {
        expiresDate,
        isActive,
        transactionId: transaction.transactionId || 'unknown',
        updatedAt: new Date(),
      },
    });
  }

  private async upsertSubscriptionFromTransaction(transaction: JWSTransactionDecodedPayload): Promise<void> {
    // Find user by originalTransactionId in existing subscription
    const existingSubscription = await this.prisma.subscription.findFirst({
      where: { originalTransactionId: transaction.originalTransactionId || 'unknown' },
    });

    if (!existingSubscription) {
      this.logger.warn(`Cannot upsert subscription - no user found for transaction ${transaction.originalTransactionId}`);
      return;
    }

    const expiresDate = transaction.expiresDate ? new Date(transaction.expiresDate) : new Date();
    const isActive = transaction.expiresDate ? new Date(transaction.expiresDate) > new Date() : false;

    await this.prisma.subscription.update({
      where: { id: existingSubscription.id },
      data: {
        transactionId: transaction.transactionId || 'unknown',
        expiresDate,
        isActive,
        productId: transaction.productId || 'unknown',
        updatedAt: new Date(),
      },
    });
  }
}
