import { Resolver, Query, Mutation, Args } from '@nestjs/graphql';
import { UseGuards, ForbiddenException } from '@nestjs/common';
import { ClerkAuthGuard } from '../auth/auth.guard';
import {
  CurrentUser,
  CurrentUserContext,
} from '../common/decorators/current-user.decorator';
import { PrismaService } from '../prisma/prisma.service';
import { PantryService } from './pantry.service';
import { PantryItemModel } from './models/pantry-item.model';
import { IngredientCatalogEntry } from './models/ingredient-catalog.model';
import { AddPantryItemInput } from './dto/add-pantry-item.input';
import { BulkAddPantryItemsInput } from './dto/bulk-add-pantry-items.input';
import { UpdatePantryItemInput } from './dto/update-pantry-item.input';

@Resolver(() => PantryItemModel)
@UseGuards(ClerkAuthGuard)
export class PantryResolver {
  constructor(
    private pantryService: PantryService,
    private prisma: PrismaService,
  ) {}

  /** Resolve clerkId to database userId */
  private async resolveUserId(clerkId: string): Promise<string> {
    const user = await this.prisma.user.findUnique({ where: { clerkId } });
    if (!user) throw new ForbiddenException('User not found');
    return user.id;
  }

  @Query(() => [PantryItemModel], {
    description: 'Get all pantry items for authenticated user',
  })
  async pantryItems(
    @CurrentUser() user: CurrentUserContext,
    @Args('sinceTimestamp', { type: () => Date, nullable: true })
    sinceTimestamp?: Date,
    @Args('userId', { nullable: true, deprecationReason: 'Derived from auth token' }) _userId?: string,
  ): Promise<PantryItemModel[]> {
    const userId = await this.resolveUserId(user.clerkId);
    return this.pantryService.findAllForUser(userId, sinceTimestamp);
  }

  @Mutation(() => PantryItemModel, {
    description: 'Add a pantry item with normalization',
  })
  async addPantryItem(
    @CurrentUser() user: CurrentUserContext,
    @Args('input') input: AddPantryItemInput,
  ): Promise<PantryItemModel> {
    const userId = await this.resolveUserId(user.clerkId);
    // Override client-supplied userId with authenticated user's ID
    input.userId = userId;
    return this.pantryService.addItem(input);
  }

  @Mutation(() => [PantryItemModel], {
    description: 'Bulk add pantry items (receipt scan)',
  })
  async bulkAddPantryItems(
    @CurrentUser() user: CurrentUserContext,
    @Args('input') input: BulkAddPantryItemsInput,
  ): Promise<PantryItemModel[]> {
    const userId = await this.resolveUserId(user.clerkId);
    // Override client-supplied userId with authenticated user's ID
    input.userId = userId;
    return this.pantryService.bulkAddItems(input);
  }

  @Mutation(() => PantryItemModel, { description: 'Update a pantry item' })
  async updatePantryItem(
    @CurrentUser() user: CurrentUserContext,
    @Args('id') id: string,
    @Args('input') input: UpdatePantryItemInput,
    @Args('userId', { nullable: true, deprecationReason: 'Derived from auth token' }) _userId?: string,
  ): Promise<PantryItemModel> {
    const userId = await this.resolveUserId(user.clerkId);
    return this.pantryService.updateItem(id, userId, input);
  }

  @Mutation(() => PantryItemModel, { description: 'Soft delete a pantry item' })
  async deletePantryItem(
    @CurrentUser() user: CurrentUserContext,
    @Args('id') id: string,
    @Args('userId', { nullable: true, deprecationReason: 'Derived from auth token' }) _userId?: string,
  ): Promise<PantryItemModel> {
    const userId = await this.resolveUserId(user.clerkId);
    return this.pantryService.deleteItem(id, userId);
  }

  @Query(() => [IngredientCatalogEntry], {
    description: 'Search ingredient catalog',
  })
  async ingredientSearch(
    @Args('query') query: string,
    @Args('lang', { defaultValue: 'en' }) lang: string,
  ): Promise<IngredientCatalogEntry[]> {
    return this.pantryService.searchCatalog(query, lang);
  }
}
