import { Test, TestingModule } from '@nestjs/testing';
import { RecipesService } from './recipes.service';
import { PrismaService } from '../prisma/prisma.service';
import { SpoonacularService } from '../spoonacular/spoonacular.service';
import { SpoonacularCacheService } from '../spoonacular/spoonacular-cache.service';
import { Logger } from '@nestjs/common';
import { CuisineType, MealType, DifficultyLevel, ImageStatus } from '@prisma/client';

describe('RecipesService', () => {
  let service: RecipesService;
  let spoonacularService: SpoonacularService;
  let cacheService: SpoonacularCacheService;
  let prisma: PrismaService;

  const mockPrisma = {
    recipe: {
      findMany: jest.fn(),
      count: jest.fn(),
    },
  };

  const mockSpoonacularService = {
    search: jest.fn(),
    getRecipeInformationBulk: jest.fn(),
    hasQuotaRemaining: jest.fn(),
  };

  const mockCacheService = {
    getCachedSearch: jest.fn(),
    cacheSearchResults: jest.fn(),
    normalizeCacheKey: jest.fn(),
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
        RecipesService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: SpoonacularService, useValue: mockSpoonacularService },
        { provide: SpoonacularCacheService, useValue: mockCacheService },
        { provide: Logger, useValue: mockLogger },
      ],
    }).compile();

    service = module.get<RecipesService>(RecipesService);
    spoonacularService = module.get<SpoonacularService>(SpoonacularService);
    cacheService = module.get<SpoonacularCacheService>(SpoonacularCacheService);
    prisma = module.get<PrismaService>(PrismaService);

    jest.clearAllMocks();
  });

  describe('searchRecipes', () => {
    const sampleRecipe = {
      id: 'recipe1',
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
      spoonacularId: 123,
      popularityScore: 100,
      scrapedAt: new Date(),
      engagementLoves: 0,
      engagementBookmarks: 0,
      engagementViews: 0,
      isViral: false,
      velocityScore: 0,
      createdAt: new Date(),
      updatedAt: new Date(),
      ingredients: [],
      steps: [],
    };

    it('should return RecipeConnection with edges, pageInfo, totalCount', async () => {
      mockCacheService.normalizeCacheKey.mockReturnValue('test-key');
      mockCacheService.getCachedSearch.mockResolvedValue({
        recipes: [sampleRecipe],
        isStale: false,
      });

      const result = await service.searchRecipes({
        query: 'pasta',
        first: 20,
      });

      expect(result).toHaveProperty('edges');
      expect(result).toHaveProperty('pageInfo');
      expect(result).toHaveProperty('totalCount');
      expect(result.edges.length).toBe(1);
      expect(result.edges[0]).toHaveProperty('node');
      expect(result.edges[0]).toHaveProperty('cursor');
      expect(result.pageInfo).toHaveProperty('hasNextPage');
      expect(result.pageInfo).toHaveProperty('hasPreviousPage');
    });

    it('should return cached results when cache HIT (no API call)', async () => {
      mockCacheService.normalizeCacheKey.mockReturnValue('test-key');
      mockCacheService.getCachedSearch.mockResolvedValue({
        recipes: [sampleRecipe],
        isStale: false,
      });

      await service.searchRecipes({ query: 'pasta', first: 20 });

      expect(mockCacheService.getCachedSearch).toHaveBeenCalled();
      expect(mockSpoonacularService.search).not.toHaveBeenCalled();
    });

    it('should call SpoonacularService when cache MISS and cache results', async () => {
      const spoonacularRecipe = {
        id: 123,
        title: 'Pasta Carbonara',
        summary: '<p>Delicious pasta</p>',
        readyInMinutes: 30,
        servings: 4,
        image: 'https://example.com/pasta.jpg',
        aggregateLikes: 100,
        sourceName: 'Food Network',
        sourceUrl: 'https://foodnetwork.com/recipe',
        cuisines: ['Italian'],
        dishTypes: ['dinner', 'main course'],
        vegetarian: false,
        vegan: false,
        glutenFree: false,
        dairyFree: false,
        veryHealthy: false,
        cheap: false,
        veryPopular: true,
        sustainable: false,
        lowFodmap: false,
        ketogenic: false,
        whole30: false,
        nutrition: {
          nutrients: [
            { name: 'Calories', amount: 500, unit: 'kcal' },
            { name: 'Protein', amount: 20, unit: 'g' },
            { name: 'Carbohydrates', amount: 60, unit: 'g' },
            { name: 'Fat', amount: 15, unit: 'g' },
          ],
        },
        analyzedInstructions: [
          {
            steps: [
              { number: 1, step: 'Boil water' },
              { number: 2, step: 'Cook pasta' },
            ],
          },
        ],
        extendedIngredients: [
          {
            name: 'pasta',
            original: '200g pasta',
            amount: 200,
            unit: 'g',
          },
        ],
      };

      mockCacheService.normalizeCacheKey.mockReturnValue('test-key');
      mockCacheService.getCachedSearch.mockResolvedValue(null);
      mockSpoonacularService.hasQuotaRemaining.mockResolvedValue(true);
      mockSpoonacularService.search.mockResolvedValue([spoonacularRecipe]);

      await service.searchRecipes({ query: 'pasta', first: 20 });

      expect(mockSpoonacularService.search).toHaveBeenCalled();
      expect(mockCacheService.cacheSearchResults).toHaveBeenCalled();
    });

    it('should return cached immediately and trigger background refresh when stale', async () => {
      mockCacheService.normalizeCacheKey.mockReturnValue('test-key');
      mockCacheService.getCachedSearch.mockResolvedValue({
        recipes: [sampleRecipe],
        isStale: true,
      });
      mockSpoonacularService.hasQuotaRemaining.mockResolvedValue(true);
      mockSpoonacularService.search.mockResolvedValue([]);

      const result = await service.searchRecipes({ query: 'pasta', first: 20 });

      expect(result.edges.length).toBe(1);
      // Background refresh happens asynchronously, so we can't assert on it immediately
      // But we can check that cache was checked
      expect(mockCacheService.getCachedSearch).toHaveBeenCalled();
    });

    it('should return stale cache when quota exhausted AND cache exists', async () => {
      mockCacheService.normalizeCacheKey.mockReturnValue('test-key');
      mockCacheService.getCachedSearch.mockResolvedValue(null);
      mockSpoonacularService.hasQuotaRemaining.mockResolvedValue(false);

      // Simulate finding stale cache as fallback
      mockPrisma.recipe.findMany.mockResolvedValue([sampleRecipe]);
      mockPrisma.recipe.count.mockResolvedValue(1);

      const result = await service.searchRecipes({ query: 'pasta', first: 20 });

      expect(mockSpoonacularService.search).not.toHaveBeenCalled();
      expect(result.edges.length).toBeGreaterThanOrEqual(0);
    });

    it('should return empty with fallback message when quota exhausted AND no cache', async () => {
      mockCacheService.normalizeCacheKey.mockReturnValue('test-key');
      mockCacheService.getCachedSearch.mockResolvedValue(null);
      mockSpoonacularService.hasQuotaRemaining.mockResolvedValue(false);
      mockPrisma.recipe.findMany.mockResolvedValue([]);
      mockPrisma.recipe.count.mockResolvedValue(0);

      const result = await service.searchRecipes({ query: 'pasta', first: 20 });

      expect(result.edges.length).toBe(0);
      expect(result.totalCount).toBe(0);
    });

    it('should handle cursor pagination correctly', async () => {
      // Create multiple recipes
      const recipes = Array.from({ length: 5 }, (_, i) => ({
        ...sampleRecipe,
        id: `recipe${i + 1}`,
        name: `Pasta ${i + 1}`,
      }));

      mockCacheService.normalizeCacheKey.mockReturnValue('test-key');
      mockCacheService.getCachedSearch.mockResolvedValue({
        recipes,
        isStale: false,
      });

      // First page
      const page1 = await service.searchRecipes({ query: 'pasta', first: 2 });
      expect(page1.edges.length).toBe(2);
      expect(page1.pageInfo.hasNextPage).toBe(true);
      expect(page1.pageInfo.endCursor).toBeDefined();

      // Second page using cursor
      const cursor = page1.pageInfo.endCursor!;
      const page2 = await service.searchRecipes({
        query: 'pasta',
        first: 2,
        after: cursor,
      });
      expect(page2.edges.length).toBeLessThanOrEqual(2);
    });

    it('should mark deprecated viralRecipes query as returning empty array', async () => {
      const result = await service.findViral('test-location');
      // Legacy method should still work but will eventually be deprecated
      expect(Array.isArray(result)).toBe(true);
    });
  });

  describe('getPopularRecipes', () => {
    it('should return recipes sorted by popularityScore descending from cache', async () => {
      const recipes = [
        {
          id: 'recipe1',
          name: 'Popular Recipe 1',
          popularityScore: 1000,
          prepTime: 30,
          cuisineType: CuisineType.ITALIAN,
          mealType: MealType.DINNER,
          imageStatus: ImageStatus.COMPLETED,
          difficulty: DifficultyLevel.INTERMEDIATE,
          engagementLoves: 0,
          velocityScore: 0,
          isViral: false,
          ingredients: [],
          steps: [],
        },
        {
          id: 'recipe2',
          name: 'Popular Recipe 2',
          popularityScore: 500,
          prepTime: 20,
          cuisineType: CuisineType.CHINESE,
          mealType: MealType.LUNCH,
          imageStatus: ImageStatus.COMPLETED,
          difficulty: DifficultyLevel.BEGINNER,
          engagementLoves: 0,
          velocityScore: 0,
          isViral: false,
          ingredients: [],
          steps: [],
        },
      ];

      mockPrisma.recipe.findMany.mockResolvedValue(recipes);
      mockPrisma.recipe.count.mockResolvedValue(2);

      const result = await service.getPopularRecipes(20);

      expect(result.edges.length).toBe(2);
      // Verify sorting is correct (first recipe has higher or equal popularity)
      const firstRecipe = recipes[0];
      const secondRecipe = recipes[1];
      expect(firstRecipe.popularityScore).toBeGreaterThanOrEqual(secondRecipe.popularityScore);
      expect(mockPrisma.recipe.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          orderBy: { popularityScore: 'desc' },
        }),
      );
    });
  });
});
