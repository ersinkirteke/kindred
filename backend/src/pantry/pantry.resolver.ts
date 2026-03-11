import { Resolver, Query, Mutation, Args } from '@nestjs/graphql';
import { PantryService } from './pantry.service';
import { PantryItemModel } from './models/pantry-item.model';
import { IngredientCatalogEntry } from './models/ingredient-catalog.model';
import { AddPantryItemInput } from './dto/add-pantry-item.input';
import { BulkAddPantryItemsInput } from './dto/bulk-add-pantry-items.input';
import { UpdatePantryItemInput } from './dto/update-pantry-item.input';

@Resolver(() => PantryItemModel)
export class PantryResolver {
  constructor(private pantryService: PantryService) {}

  @Query(() => [PantryItemModel], {
    description: 'Get all pantry items for user',
  })
  async pantryItems(
    @Args('userId') userId: string,
    @Args('sinceTimestamp', { type: () => Date, nullable: true })
    sinceTimestamp?: Date,
  ): Promise<PantryItemModel[]> {
    return this.pantryService.findAllForUser(userId, sinceTimestamp);
  }

  @Mutation(() => PantryItemModel, {
    description: 'Add a pantry item with normalization',
  })
  async addPantryItem(
    @Args('input') input: AddPantryItemInput,
  ): Promise<PantryItemModel> {
    return this.pantryService.addItem(input);
  }

  @Mutation(() => [PantryItemModel], {
    description: 'Bulk add pantry items (receipt scan)',
  })
  async bulkAddPantryItems(
    @Args('input') input: BulkAddPantryItemsInput,
  ): Promise<PantryItemModel[]> {
    return this.pantryService.bulkAddItems(input);
  }

  @Mutation(() => PantryItemModel, { description: 'Update a pantry item' })
  async updatePantryItem(
    @Args('id') id: string,
    @Args('userId') userId: string,
    @Args('input') input: UpdatePantryItemInput,
  ): Promise<PantryItemModel> {
    return this.pantryService.updateItem(id, userId, input);
  }

  @Mutation(() => PantryItemModel, { description: 'Soft delete a pantry item' })
  async deletePantryItem(
    @Args('id') id: string,
    @Args('userId') userId: string,
  ): Promise<PantryItemModel> {
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
