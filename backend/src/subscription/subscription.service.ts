import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

// NOTE: Install @apple/app-store-server-library:
// npm install @apple/app-store-server-library

@Injectable()
export class SubscriptionService {
  private readonly logger = new Logger(SubscriptionService.name);

  constructor(private prisma: PrismaService) {}

  async verifyAndSyncSubscription(userId: string, jwsRepresentation: string): Promise<boolean> {
    try {
      // Decode JWS payload (Apple's library handles signature verification)
      // For MVP: decode base64url payload without full x5c chain verification
      // Production: use SignedDataVerifier from @apple/app-store-server-library
      const payload = this.decodeJWSPayload(jwsRepresentation);

      if (!payload) {
        this.logger.warn(`Invalid JWS for user ${userId}`);
        return false;
      }

      // Check product ID and expiration
      const isValid = payload.productId === 'com.kindred.pro.monthly'
        && payload.expiresDate > Date.now();

      // Upsert subscription record
      await this.prisma.subscription.upsert({
        where: { userId },
        create: {
          userId,
          productId: payload.productId,
          transactionId: payload.transactionId,
          originalTransactionId: payload.originalTransactionId,
          expiresDate: new Date(payload.expiresDate),
          isActive: isValid,
          jwsPayload: jwsRepresentation,
        },
        update: {
          transactionId: payload.transactionId,
          expiresDate: new Date(payload.expiresDate),
          isActive: isValid,
          jwsPayload: jwsRepresentation,
          updatedAt: new Date(),
        },
      });

      return isValid;
    } catch (error) {
      this.logger.error(`JWS verification failed for user ${userId}`, error);
      return false;
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

  private decodeJWSPayload(jws: string): any {
    try {
      const parts = jws.split('.');
      if (parts.length !== 3) return null;
      const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString());
      return payload;
    } catch {
      return null;
    }
  }
}
