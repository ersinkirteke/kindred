import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  /**
   * Find user by Clerk ID.
   * Used by auth guard to populate request context.
   */
  async findByClerkId(clerkId: string) {
    return this.prisma.user.findUnique({
      where: { clerkId },
    });
  }

  /**
   * Find user by internal ID.
   */
  async findById(id: string) {
    return this.prisma.user.findUnique({
      where: { id },
    });
  }

  /**
   * Create user from Clerk webhook.
   * Called when a new user signs up via Clerk authentication.
   */
  async createFromClerk(
    clerkId: string,
    email: string,
    displayName?: string,
  ) {
    return this.prisma.user.create({
      data: {
        clerkId,
        email,
        displayName,
      },
    });
  }

  /**
   * Upsert user from Clerk webhook.
   * Creates user if not exists, updates email/displayName if exists.
   * Used for both user.created and user.updated events.
   */
  async upsertFromClerk(
    clerkId: string,
    email: string,
    displayName?: string,
  ) {
    return this.prisma.user.upsert({
      where: { clerkId },
      update: {
        email,
        displayName,
      },
      create: {
        clerkId,
        email,
        displayName,
      },
    });
  }
}
