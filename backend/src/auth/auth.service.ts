import { Injectable, UnauthorizedException, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClerkClient } from '@clerk/clerk-sdk-node';

export interface ClerkTokenPayload {
  sub: string; // Clerk user ID
  email?: string;
}

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  private readonly clerkClient;

  constructor(private configService: ConfigService) {
    const secretKey = this.configService.get<string>('CLERK_SECRET_KEY');

    if (!secretKey) {
      this.logger.warn('CLERK_SECRET_KEY not configured - auth will reject all tokens');
      this.clerkClient = null;
      return;
    }

    this.clerkClient = createClerkClient({
      secretKey,
    });

    this.logger.log('Clerk client initialized');
  }

  /**
   * Verify Clerk JWT token and return decoded payload.
   * Throws UnauthorizedException on invalid or expired tokens.
   */
  async verifyToken(token: string): Promise<ClerkTokenPayload> {
    if (!this.clerkClient) {
      throw new UnauthorizedException('Auth not configured');
    }
    try {
      // Clerk SDK's verifyToken validates the JWT signature, expiration, and issuer
      const payload = await this.clerkClient.verifyToken(token);

      return {
        sub: payload.sub,
        email: payload.email as string | undefined,
      };
    } catch (error) {
      this.logger.warn(`Token verification failed: ${error.message}`);
      throw new UnauthorizedException('Invalid or expired authentication token');
    }
  }

  /**
   * Fetch full user data from Clerk API.
   * Used for webhook enrichment if needed.
   */
  async getClerkUser(clerkId: string) {
    if (!this.clerkClient) {
      throw new Error('Auth not configured');
    }
    try {
      return await this.clerkClient.users.getUser(clerkId);
    } catch (error) {
      this.logger.error(`Failed to fetch Clerk user ${clerkId}: ${error.message}`);
      throw error;
    }
  }
}
