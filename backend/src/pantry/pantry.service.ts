import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AddPantryItemInput } from './dto/add-pantry-item.input';
import { BulkAddPantryItemsInput } from './dto/bulk-add-pantry-items.input';
import { UpdatePantryItemInput } from './dto/update-pantry-item.input';
import { PantryItemModel } from './models/pantry-item.model';
import { IngredientCatalogEntry } from './models/ingredient-catalog.model';
import { ExpiryEstimatorService } from './expiry-estimator.service';

@Injectable()
export class PantryService {
  constructor(
    private prisma: PrismaService,
    private expiryEstimator: ExpiryEstimatorService,
  ) {}

  /**
   * Get all non-deleted pantry items for a user.
   * Optionally filter by sinceTimestamp for sync.
   */
  async findAllForUser(
    userId: string,
    sinceTimestamp?: Date,
  ): Promise<PantryItemModel[]> {
    const where: any = {
      userId,
      isDeleted: false,
    };

    if (sinceTimestamp) {
      where.updatedAt = { gt: sinceTimestamp };
    }

    const items = await this.prisma.pantryItem.findMany({
      where,
      orderBy: { updatedAt: 'desc' },
    });

    return items.map(this.toPantryItemModel);
  }

  /**
   * Get items expiring within the next N days.
   * Used by expiry notification scheduler.
   *
   * @param daysAhead - Number of days to look ahead (e.g., 2 for items expiring in next 2 days)
   * @returns Items with expiryDate between now and now + daysAhead, sorted by expiryDate
   */
  async getExpiringItems(params: {
    daysAhead: number;
  }): Promise<PantryItemModel[]> {
    const now = new Date();
    const futureDate = new Date();
    futureDate.setDate(now.getDate() + params.daysAhead);

    const items = await this.prisma.pantryItem.findMany({
      where: {
        expiryDate: { gte: now, lte: futureDate },
        isDeleted: false,
      },
      orderBy: { expiryDate: 'asc' },
    });

    return items.map(this.toPantryItemModel);
  }

  /**
   * Add a pantry item with server-side normalization and duplicate merging.
   */
  async addItem(input: AddPantryItemInput): Promise<PantryItemModel> {
    // 1. Normalize ingredient name
    const normalizedName = await this.normalizeIngredient(input.name);

    // 2. Look up catalog entry for auto-filling category
    const catalogEntry = await this.prisma.ingredientCatalog.findFirst({
      where: { canonicalName: normalizedName },
    });

    const foodCategory =
      input.foodCategory || catalogEntry?.defaultCategory || null;

    // 3. Check for existing non-deleted item with same normalized name
    const existingItem = await this.prisma.pantryItem.findFirst({
      where: {
        userId: input.userId,
        normalizedName,
        isDeleted: false,
      },
    });

    if (existingItem) {
      // 4. Merge quantities
      const mergedQuantity = this.mergeQuantities(
        existingItem.quantity,
        input.quantity,
      );

      const updated = await this.prisma.pantryItem.update({
        where: { id: existingItem.id },
        data: {
          quantity: mergedQuantity,
          updatedAt: new Date(),
        },
      });

      return this.toPantryItemModel(updated);
    }

    // 5. Create new item
    const created = await this.prisma.pantryItem.create({
      data: {
        userId: input.userId,
        name: input.name,
        normalizedName,
        quantity: input.quantity,
        unit: input.unit,
        storageLocation: input.storageLocation,
        foodCategory,
        notes: input.notes,
        source: input.source || 'manual',
        expiryDate: input.expiryDate,
      },
    });

    // If no expiry date provided, estimate it in the background (fire-and-forget)
    if (!input.expiryDate) {
      this.estimateAndSetExpiry(created.id).catch(() => {
        // Errors already logged in estimateAndSetExpiry
      });
    }

    return this.toPantryItemModel(created);
  }

  /**
   * Bulk add pantry items (e.g., from receipt scan).
   */
  async bulkAddItems(
    input: BulkAddPantryItemsInput,
  ): Promise<PantryItemModel[]> {
    const results: PantryItemModel[] = [];

    for (const item of input.items) {
      const pantryItem = await this.addItem({
        userId: input.userId,
        name: item.name,
        quantity: item.quantity,
        unit: item.unit,
        storageLocation: item.storageLocation || 'pantry',
        source: item.source || 'receipt_scan',
      });

      results.push(pantryItem);
    }

    return results;
  }

  /**
   * Update a pantry item.
   */
  async updateItem(
    id: string,
    userId: string,
    input: UpdatePantryItemInput,
  ): Promise<PantryItemModel> {
    // Security check: ensure item belongs to user
    const item = await this.prisma.pantryItem.findFirst({
      where: { id, userId },
    });

    if (!item) {
      throw new Error('Pantry item not found');
    }

    // If name changed, re-normalize
    let normalizedName = item.normalizedName;
    if (input.name && input.name !== item.name) {
      normalizedName = await this.normalizeIngredient(input.name);
    }

    const updated = await this.prisma.pantryItem.update({
      where: { id },
      data: {
        ...input,
        normalizedName,
      },
    });

    return this.toPantryItemModel(updated);
  }

  /**
   * Soft delete a pantry item.
   */
  async deleteItem(id: string, userId: string): Promise<PantryItemModel> {
    // Security check: ensure item belongs to user
    const item = await this.prisma.pantryItem.findFirst({
      where: { id, userId },
    });

    if (!item) {
      throw new Error('Pantry item not found');
    }

    const deleted = await this.prisma.pantryItem.update({
      where: { id },
      data: {
        isDeleted: true,
        updatedAt: new Date(),
      },
    });

    return this.toPantryItemModel(deleted);
  }

  /**
   * Search ingredient catalog (bilingual).
   */
  async searchCatalog(
    query: string,
    lang: string = 'en',
  ): Promise<IngredientCatalogEntry[]> {
    const lowerQuery = query.toLowerCase();

    const results = await this.prisma.ingredientCatalog.findMany({
      where: {
        OR: [
          { canonicalName: { contains: lowerQuery, mode: 'insensitive' } },
          { canonicalNameTR: { contains: lowerQuery, mode: 'insensitive' } },
          { aliases: { has: lowerQuery } },
        ],
      },
      take: 10,
    });

    const entries = results.map(this.toIngredientCatalogEntry);

    // Sort Turkish matches first if lang is "tr"
    if (lang === 'tr') {
      return entries.sort((a, b) => {
        const aMatchesTR = a.canonicalNameTR
          .toLowerCase()
          .includes(lowerQuery);
        const bMatchesTR = b.canonicalNameTR
          .toLowerCase()
          .includes(lowerQuery);
        if (aMatchesTR && !bMatchesTR) return -1;
        if (!aMatchesTR && bMatchesTR) return 1;
        return 0;
      });
    }

    return entries;
  }

  /**
   * Estimate and set expiry date for a pantry item.
   * Only runs if item doesn't already have an expiryDate.
   * Fire-and-forget operation (async, non-blocking).
   *
   * @param itemId - ID of the pantry item
   */
  async estimateAndSetExpiry(itemId: string): Promise<void> {
    try {
      const item = await this.prisma.pantryItem.findUnique({
        where: { id: itemId },
      });

      if (!item || item.expiryDate) {
        // Item not found or already has expiry date
        return;
      }

      // Use normalized name if available, fall back to display name
      const shelfLifeDays = await this.expiryEstimator.estimateExpiryDate(
        item.normalizedName || item.name,
        item.storageLocation,
      );

      const expiryDate = new Date();
      expiryDate.setDate(expiryDate.getDate() + shelfLifeDays);

      await this.prisma.pantryItem.update({
        where: { id: itemId },
        data: { expiryDate },
      });
    } catch (error) {
      // Log but don't throw — this is a best-effort background operation
      console.error(
        `Failed to estimate expiry for item ${itemId}: ${error.message}`,
      );
    }
  }

  /**
   * Normalize ingredient name using IngredientCatalog.
   * Returns canonical name if found, otherwise lowercase trimmed input.
   * Auto-creates catalog entry for unknown ingredients (accept and learn).
   */
  private async normalizeIngredient(inputName: string): Promise<string> {
    const lowerInput = inputName.toLowerCase().trim();

    // Search catalog for match
    const catalogEntry = await this.prisma.ingredientCatalog.findFirst({
      where: {
        OR: [
          { canonicalName: { equals: lowerInput, mode: 'insensitive' } },
          { canonicalNameTR: { equals: lowerInput, mode: 'insensitive' } },
          { aliases: { has: lowerInput } },
        ],
      },
    });

    if (catalogEntry) {
      return catalogEntry.canonicalName;
    }

    // Unknown ingredient: auto-create catalog entry (accept and learn)
    const newEntry = await this.prisma.ingredientCatalog.create({
      data: {
        canonicalName: lowerInput,
        canonicalNameTR: lowerInput,
        aliases: [],
        defaultCategory: 'other',
        defaultShelfLifeDays: null,
      },
    });

    return newEntry.canonicalName;
  }

  /**
   * Merge quantities intelligently.
   * Try to parse as numbers and add. Otherwise concatenate with " + ".
   */
  private mergeQuantities(existing: string, incoming: string): string {
    const existingNum = parseFloat(existing);
    const incomingNum = parseFloat(incoming);

    if (!isNaN(existingNum) && !isNaN(incomingNum)) {
      return String(existingNum + incomingNum);
    }

    return `${existing} + ${incoming}`;
  }

  /**
   * Convert Prisma PantryItem to GraphQL PantryItemModel.
   * Converts null to undefined for GraphQL compatibility.
   */
  private toPantryItemModel(item: any): PantryItemModel {
    return {
      id: item.id,
      name: item.name,
      normalizedName: item.normalizedName ?? undefined,
      quantity: item.quantity,
      unit: item.unit ?? undefined,
      storageLocation: item.storageLocation,
      foodCategory: item.foodCategory ?? undefined,
      photoUrl: item.photoUrl ?? undefined,
      notes: item.notes ?? undefined,
      source: item.source,
      expiryDate: item.expiryDate ?? undefined,
      isDeleted: item.isDeleted,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    };
  }

  /**
   * Convert Prisma IngredientCatalog to GraphQL IngredientCatalogEntry.
   * Converts null to undefined for GraphQL compatibility.
   */
  private toIngredientCatalogEntry(entry: any): IngredientCatalogEntry {
    return {
      id: entry.id,
      canonicalName: entry.canonicalName,
      canonicalNameTR: entry.canonicalNameTR,
      aliases: entry.aliases,
      defaultCategory: entry.defaultCategory,
      defaultShelfLifeDays: entry.defaultShelfLifeDays ?? undefined,
    };
  }
}
