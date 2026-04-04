import { Test, TestingModule } from '@nestjs/testing';
import { SpoonacularCacheService } from './spoonacular-cache.service';
import { PrismaService } from '../prisma/prisma.service';
import { Logger } from '@nestjs/common';
import { CuisineType, MealType, DifficultyLevel, ImageStatus } from '@prisma/client';

describe('SpoonacularCacheService', () => {
  let service: SpoonacularCacheService;
  let prisma: PrismaService;

  const mockPrisma = {
    searchCache: {
      findUnique: jest.fn(),
      upsert: jest.fn(),
      deleteMany: jest.fn(),
    },
    recipe: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      upsert: jest.fn(),
    },
    ingredient: {
      deleteMany: jest.fn(),
    },
    recipeStep: {
      deleteMany: jest.fn(),
    },
    $transaction: jest.fn((fn) => {
      // Create a transaction context that has the same structure as mockPrisma
      const tx = {
        recipe: {
          findUnique: mockPrisma.recipe.findUnique,
          upsert: mockPrisma.recipe.upsert,
        },
        ingredient: {
          deleteMany: mockPrisma.ingredient.deleteMany,
        },
        recipeStep: {
          deleteMany: mockPrisma.recipeStep.deleteMany,
        },
      };
      return fn(tx);
    }),
  };

  const mockLogger = {
    log: jest.fn(),
    error: jest.fn(),
    warn: jest.fn(),
    debug: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SpoonacularCacheService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: Logger, useValue: mockLogger },
      ],
    }).compile();

    service = module.get<SpoonacularCacheService>(SpoonacularCacheService);
    prisma = module.get<PrismaService>(PrismaService);

    jest.clearAllMocks();
  });

  describe('getCachedSearch', () => {
    it('should return cached recipes when cache is fresh (within 6h TTL)', async () => {
      const normalizedKey = 'test-key';
      const freshCache = {
        id: 'cache1',
        normalizedKey,
        recipeIds: ['recipe1', 'recipe2'],
        cachedAt: new Date(Date.now() - 3 * 60 * 60 * 1000), // 3 hours ago
      };
      const recipes = [
        { id: 'recipe1', name: 'Pasta', ingredients: [], steps: [] },
        { id: 'recipe2', name: 'Pizza', ingredients: [], steps: [] },
      ];

      mockPrisma.searchCache.findUnique.mockResolvedValue(freshCache);
      mockPrisma.recipe.findMany.mockResolvedValue(recipes);

      const result = await service.getCachedSearch(normalizedKey);

      expect(result).toEqual({ recipes, isStale: false });
      expect(mockPrisma.searchCache.findUnique).toHaveBeenCalledWith({
        where: { normalizedKey },
      });
      expect(mockPrisma.recipe.findMany).toHaveBeenCalledWith({
        where: { id: { in: ['recipe1', 'recipe2'] } },
        include: {
          ingredients: { orderBy: { orderIndex: 'asc' } },
          steps: { orderBy: { orderIndex: 'asc' } },
        },
      });
    });

    it('should return cached recipes when cache is stale (stale-while-revalidate)', async () => {
      const normalizedKey = 'test-key';
      const staleCache = {
        id: 'cache1',
        normalizedKey,
        recipeIds: ['recipe1'],
        cachedAt: new Date(Date.now() - 8 * 60 * 60 * 1000), // 8 hours ago (stale)
      };
      const recipes = [{ id: 'recipe1', name: 'Pasta', ingredients: [], steps: [] }];

      mockPrisma.searchCache.findUnique.mockResolvedValue(staleCache);
      mockPrisma.recipe.findMany.mockResolvedValue(recipes);

      const result = await service.getCachedSearch(normalizedKey);

      expect(result).toEqual({ recipes, isStale: true });
    });

    it('should return null when no cache exists (cache miss)', async () => {
      mockPrisma.searchCache.findUnique.mockResolvedValue(null);

      const result = await service.getCachedSearch('nonexistent-key');

      expect(result).toBeNull();
      expect(mockPrisma.recipe.findMany).not.toHaveBeenCalled();
    });
  });

  describe('cacheSearchResults', () => {
    it('should store normalized key + recipe IDs in SearchCache', async () => {
      const normalizedKey = 'test-key';
      const recipeData = [
        {
          spoonacularId: 123,
          name: 'Pasta',
          description: 'Delicious pasta',
          prepTime: 30,
          cookTime: null,
          servings: 4,
          calories: 500,
          protein: 20,
          carbs: 60,
          fat: 15,
          difficulty: DifficultyLevel.INTERMEDIATE,
          dietaryTags: ['vegetarian'],
          cuisineType: CuisineType.ITALIAN,
          mealType: MealType.DINNER,
          imageUrl: 'https://example.com/pasta.jpg',
          imageStatus: ImageStatus.COMPLETED,
          scrapedFrom: 'spoonacular',
          sourceId: '123',
          sourceUrl: 'https://spoonacular.com/recipe/123',
          sourceName: 'Spoonacular',
          plainText: 'Pasta recipe',
          location: null,
          latitude: null,
          longitude: null,
          popularityScore: 100,
          engagementLoves: 0,
          engagementBookmarks: 0,
          engagementViews: 0,
          isViral: false,
          velocityScore: 0,
          ingredients: [
            {
              name: 'Pasta',
              quantity: '200',
              unit: 'grams',
              orderIndex: 0,
            },
          ],
          steps: [
            {
              text: 'Boil water',
              orderIndex: 0,
              duration: null,
            },
          ],
        },
      ];

      mockPrisma.recipe.findUnique.mockResolvedValue(null); // New recipe, not existing
      mockPrisma.recipe.upsert.mockResolvedValue({ id: 'recipe1' });
      mockPrisma.searchCache.upsert.mockResolvedValue({
        id: 'cache1',
        normalizedKey,
        recipeIds: ['recipe1'],
        cachedAt: new Date(),
      });

      await service.cacheSearchResults(normalizedKey, recipeData);

      expect(mockPrisma.searchCache.upsert).toHaveBeenCalledWith({
        where: { normalizedKey },
        update: {
          recipeIds: ['recipe1'],
          cachedAt: expect.any(Date),
        },
        create: {
          normalizedKey,
          recipeIds: ['recipe1'],
          cachedAt: expect.any(Date),
        },
      });
    });
  });

  describe('normalizeCacheKey', () => {
    it('should produce same key for different filter orders', () => {
      const key1 = service.normalizeCacheKey('chicken', {
        diet: 'vegan',
        cuisine: 'italian',
      });
      const key2 = service.normalizeCacheKey('chicken', {
        cuisine: 'italian',
        diet: 'vegan',
      });

      expect(key1).toBe(key2);
    });

    it('should lowercase query and trim whitespace', () => {
      const key1 = service.normalizeCacheKey(' Chicken ', {});
      const key2 = service.normalizeCacheKey('chicken', {});

      expect(key1).toBe(key2);
    });
  });

  describe('getCachedRecipes', () => {
    it('should return recipes by IDs from Recipe table', async () => {
      const recipeIds = ['recipe1', 'recipe2'];
      const recipes = [
        { id: 'recipe1', name: 'Pasta', ingredients: [], steps: [] },
        { id: 'recipe2', name: 'Pizza', ingredients: [], steps: [] },
      ];

      mockPrisma.recipe.findMany.mockResolvedValue(recipes);

      const result = await service.getCachedRecipes(recipeIds);

      expect(result).toEqual(recipes);
      expect(mockPrisma.recipe.findMany).toHaveBeenCalledWith({
        where: { id: { in: recipeIds } },
        include: {
          ingredients: { orderBy: { orderIndex: 'asc' } },
          steps: { orderBy: { orderIndex: 'asc' } },
        },
      });
    });
  });

  describe('upsertRecipes', () => {
    it('should insert new recipes and skip existing (deduplicated by spoonacularId)', async () => {
      const recipeData = [
        {
          spoonacularId: 123,
          name: 'Pasta',
          description: 'Delicious pasta',
          prepTime: 30,
          cookTime: null,
          servings: 4,
          calories: 500,
          protein: 20,
          carbs: 60,
          fat: 15,
          difficulty: DifficultyLevel.INTERMEDIATE,
          dietaryTags: ['vegetarian'],
          cuisineType: CuisineType.ITALIAN,
          mealType: MealType.DINNER,
          imageUrl: 'https://example.com/pasta.jpg',
          imageStatus: ImageStatus.COMPLETED,
          scrapedFrom: 'spoonacular',
          sourceId: '123',
          sourceUrl: 'https://spoonacular.com/recipe/123',
          sourceName: 'Spoonacular',
          plainText: 'Pasta recipe',
          location: null,
          latitude: null,
          longitude: null,
          popularityScore: 100,
          engagementLoves: 0,
          engagementBookmarks: 0,
          engagementViews: 0,
          isViral: false,
          velocityScore: 0,
          ingredients: [
            {
              name: 'Pasta',
              quantity: '200',
              unit: 'grams',
              orderIndex: 0,
            },
          ],
          steps: [
            {
              text: 'Boil water',
              orderIndex: 0,
              duration: null,
            },
          ],
        },
      ];

      mockPrisma.recipe.findUnique.mockResolvedValue(null); // New recipe, not existing
      mockPrisma.recipe.upsert.mockResolvedValue({ id: 'recipe1' });

      const recipeIds = await service.upsertRecipes(recipeData);

      expect(recipeIds).toEqual(['recipe1']);
      expect(mockPrisma.$transaction).toHaveBeenCalled();
      expect(mockPrisma.recipe.upsert).toHaveBeenCalledWith({
        where: { spoonacularId: 123 },
        update: expect.objectContaining({
          name: 'Pasta',
          description: 'Delicious pasta',
        }),
        create: expect.objectContaining({
          name: 'Pasta',
          description: 'Delicious pasta',
        }),
      });
    });
  });

  describe('isStale', () => {
    it('should return true for cache entries older than 6 hours', () => {
      const oldDate = new Date(Date.now() - 7 * 60 * 60 * 1000); // 7 hours ago
      expect(service.isStale(oldDate)).toBe(true);
    });

    it('should return false for cache entries within 6 hours', () => {
      const recentDate = new Date(Date.now() - 3 * 60 * 60 * 1000); // 3 hours ago
      expect(service.isStale(recentDate)).toBe(false);
    });
  });

  describe('cleanExpiredCache', () => {
    it('should remove SearchCache entries older than 24 hours', async () => {
      const cutoffDate = new Date(Date.now() - 24 * 60 * 60 * 1000);
      mockPrisma.searchCache.deleteMany.mockResolvedValue({ count: 5 });

      const count = await service.cleanExpiredCache();

      expect(count).toBe(5);
      expect(mockPrisma.searchCache.deleteMany).toHaveBeenCalledWith({
        where: {
          cachedAt: { lt: expect.any(Date) },
        },
      });
    });
  });
});
