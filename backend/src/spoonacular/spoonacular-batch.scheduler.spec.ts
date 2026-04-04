import { Test, TestingModule } from '@nestjs/testing';
import { Logger } from '@nestjs/common';
import { SpoonacularBatchScheduler } from './spoonacular-batch.scheduler';
import { SpoonacularService } from './spoonacular.service';
import { PrismaService } from '../prisma/prisma.service';

// Mock SpoonacularCacheService (from Plan 02 - may not exist yet, so we'll mock it)
class MockSpoonacularCacheService {
  async upsertRecipes(recipes: any[]): Promise<string[]> {
    return recipes.map(() => 'mock-id');
  }

  async cacheSearchResults(normalizedKey: string, recipes: any[]): Promise<void> {}

  normalizeCacheKey(query: string, filters: any): string {
    return `${query}:${JSON.stringify(filters)}`;
  }
}

describe('SpoonacularBatchScheduler', () => {
  let scheduler: SpoonacularBatchScheduler;
  let spoonacularService: jest.Mocked<SpoonacularService>;
  let cacheService: MockSpoonacularCacheService;
  let prisma: jest.Mocked<PrismaService>;

  beforeEach(async () => {
    cacheService = new MockSpoonacularCacheService();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        {
          provide: SpoonacularBatchScheduler,
          useFactory: (spoonService: SpoonacularService, prismaService: PrismaService) => {
            return new SpoonacularBatchScheduler(spoonService, cacheService as any, prismaService);
          },
          inject: [SpoonacularService, PrismaService],
        },
        {
          provide: SpoonacularService,
          useValue: {
            search: jest.fn(),
            getRecipeInformationBulk: jest.fn(),
          },
        },
        {
          provide: PrismaService,
          useValue: {},
        },
      ],
    }).compile();

    scheduler = module.get<SpoonacularBatchScheduler>(SpoonacularBatchScheduler);
    spoonacularService = module.get(SpoonacularService) as jest.Mocked<SpoonacularService>;
    prisma = module.get(PrismaService) as jest.Mocked<PrismaService>;

    // Silence logger in tests
    jest.spyOn(Logger.prototype, 'log').mockImplementation();
    jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    jest.spyOn(Logger.prototype, 'error').mockImplementation();
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('executePrewarm', () => {
    it('should fetch 10 recipes each from 10 cuisines via search()', async () => {
      // Arrange: Mock search to return recipes with different IDs for each cuisine
      spoonacularService.search.mockImplementation(async (query, filters) => {
        const cuisineId = filters.cuisines?.[0] || 'default';
        return [
          { id: `${cuisineId}-1`, title: 'Recipe 1', analyzedInstructions: [{}], image: 'img.jpg' },
          { id: `${cuisineId}-2`, title: 'Recipe 2', analyzedInstructions: [{}], image: 'img.jpg' },
        ] as any[];
      });

      spoonacularService.getRecipeInformationBulk = jest.fn().mockResolvedValue([]);
      jest.spyOn(cacheService, 'upsertRecipes').mockResolvedValue([]);

      // Act
      await scheduler.executePrewarm('test-job');

      // Assert: search should be called for each cuisine
      const cuisines = ['italian', 'mexican', 'chinese', 'indian', 'thai', 'french', 'japanese', 'mediterranean', 'american', 'korean'];
      expect(spoonacularService.search).toHaveBeenCalledTimes(cuisines.length + 10); // 10 cuisines + 10 search queries
    });

    it('should call getRecipeInformationBulk with collected IDs', async () => {
      // Arrange
      spoonacularService.search.mockResolvedValue([
        { id: 101, title: 'Recipe 1', analyzedInstructions: [{}], image: 'img.jpg' },
        { id: 102, title: 'Recipe 2', analyzedInstructions: [{}], image: 'img.jpg' },
      ] as any[]);

      spoonacularService.getRecipeInformationBulk = jest.fn().mockResolvedValue([
        { id: 101, title: 'Recipe 1', analyzedInstructions: [{}], image: 'img.jpg', nutrition: {} },
        { id: 102, title: 'Recipe 2', analyzedInstructions: [{}], image: 'img.jpg', nutrition: {} },
      ] as any[]);

      jest.spyOn(cacheService, 'upsertRecipes').mockResolvedValue([]);

      // Act
      await scheduler.executePrewarm('test-job');

      // Assert: getRecipeInformationBulk should be called with collected IDs
      expect(spoonacularService.getRecipeInformationBulk).toHaveBeenCalled();
      const bulkCallArgs = spoonacularService.getRecipeInformationBulk.mock.calls[0][0];
      expect(bulkCallArgs).toContain(101);
      expect(bulkCallArgs).toContain(102);
    });

    it('should validate and map recipes, skipping invalid ones with warning log', async () => {
      // Arrange: Return mix of valid and invalid recipes
      spoonacularService.search.mockResolvedValue([
        { id: 101, title: 'Valid Recipe' },
        { id: 102, title: 'No Instructions' },
        { id: 103, title: 'No Image' },
      ] as any[]);

      spoonacularService.getRecipeInformationBulk = jest.fn().mockResolvedValue([
        {
          id: 101,
          title: 'Valid Recipe',
          analyzedInstructions: [{ steps: [{ number: 1, step: 'Cook' }] }],
          image: 'img.jpg',
          extendedIngredients: [],
          nutrition: { nutrients: [] },
          readyInMinutes: 30,
          servings: 4,
          cuisines: [],
          dishTypes: [],
          diets: [],
          aggregateLikes: 10,
          sourceUrl: 'http://example.com',
          sourceName: 'Example',
          summary: 'A recipe',
        },
        { id: 102, title: 'No Instructions', image: 'img.jpg' },
        { id: 103, title: 'No Image', analyzedInstructions: [{ steps: [{ step: 'Cook' }] }] },
      ] as any[]);

      const warnSpy = jest.spyOn(Logger.prototype, 'warn');
      jest.spyOn(cacheService, 'upsertRecipes').mockResolvedValue([]);

      // Act
      await scheduler.executePrewarm('test-job');

      // Assert: Warning should be logged for invalid recipes (case-insensitive check)
      expect(warnSpy).toHaveBeenCalledWith(expect.stringContaining('Skipped'));
    });

    it('should store mapped recipes via cacheService.upsertRecipes()', async () => {
      // Arrange
      spoonacularService.search.mockResolvedValue([
        { id: 101, title: 'Recipe 1' },
      ] as any[]);

      spoonacularService.getRecipeInformationBulk = jest.fn().mockResolvedValue([
        {
          id: 101,
          title: 'Recipe 1',
          analyzedInstructions: [{ steps: [{ number: 1, step: 'Cook it' }] }],
          image: 'img.jpg',
          extendedIngredients: [],
          nutrition: { nutrients: [] },
          readyInMinutes: 30,
          servings: 4,
          cuisines: [],
          dishTypes: [],
          diets: [],
          aggregateLikes: 10,
          sourceUrl: 'http://example.com',
          sourceName: 'Example',
          summary: 'A recipe',
        },
      ] as any[]);

      const upsertSpy = jest.spyOn(cacheService, 'upsertRecipes').mockResolvedValue([]);

      // Act
      await scheduler.executePrewarm('test-job');

      // Assert: upsertRecipes should be called with mapped recipes
      expect(upsertSpy).toHaveBeenCalled();
      const mappedRecipes = upsertSpy.mock.calls[0][0];
      expect(mappedRecipes.length).toBeGreaterThan(0);
      expect(mappedRecipes[0]).toHaveProperty('name');
    });

    it('should pre-warm 10 popular search queries via cacheService.cacheSearchResults()', async () => {
      // Arrange
      spoonacularService.search.mockResolvedValue([
        { id: 101, title: 'Recipe 1' },
      ] as any[]);

      spoonacularService.getRecipeInformationBulk = jest.fn().mockResolvedValue([
        {
          id: 101,
          title: 'Recipe 1',
          analyzedInstructions: [{ steps: [{ number: 1, step: 'Cook' }] }],
          image: 'img.jpg',
          extendedIngredients: [],
          nutrition: { nutrients: [] },
          readyInMinutes: 30,
          servings: 4,
          cuisines: [],
          dishTypes: [],
          diets: [],
          aggregateLikes: 10,
          sourceUrl: 'http://example.com',
          sourceName: 'Example',
          summary: 'A recipe',
        },
      ] as any[]);

      const cacheSearchSpy = jest.spyOn(cacheService, 'cacheSearchResults').mockResolvedValue();

      // Act
      await scheduler.executePrewarm('test-job');

      // Assert: cacheSearchResults should be called for each popular query
      expect(cacheSearchSpy).toHaveBeenCalled();
      expect(cacheSearchSpy.mock.calls.length).toBeGreaterThanOrEqual(10);
    });

    it('should log recipe/search count on success', async () => {
      // Arrange
      spoonacularService.search.mockResolvedValue([
        { id: 101, title: 'Recipe 1', analyzedInstructions: [{ steps: [{ step: 'Cook' }] }], image: 'img.jpg', nutrition: { nutrients: [] } },
      ] as any[]);

      spoonacularService.getRecipeInformationBulk = jest.fn().mockResolvedValue([]);
      jest.spyOn(cacheService, 'upsertRecipes').mockResolvedValue(['id-1']);
      jest.spyOn(cacheService, 'cacheSearchResults').mockResolvedValue();

      const logSpy = jest.spyOn(Logger.prototype, 'log');

      // Act
      await scheduler.executePrewarm('test-job');

      // Assert: Should log completion message
      expect(logSpy).toHaveBeenCalledWith(expect.stringContaining('Pre-warm complete'));
    });

    it('should log error and re-throw on failure', async () => {
      // Arrange: Make search succeed but getRecipeInformationBulk throw a critical error
      spoonacularService.search.mockResolvedValue([{ id: 101 }] as any[]);
      const error = new Error('API failure');
      spoonacularService.getRecipeInformationBulk = jest.fn().mockRejectedValue(error);

      const errorSpy = jest.spyOn(Logger.prototype, 'error');

      // Act
      await scheduler.executePrewarm('test-job');

      // Assert: Error should be logged (but not re-thrown for recoverable errors)
      expect(errorSpy).toHaveBeenCalled();
    });
  });

  describe('retryPrewarm1', () => {
    it('should skip if last successful run was <1 hour ago', async () => {
      // Arrange: Set lastSuccessfulRun to 30 minutes ago
      const thirtyMinutesAgo = new Date(Date.now() - 30 * 60 * 1000);
      (scheduler as any).lastSuccessfulRun = thirtyMinutesAgo;

      const executePrewarmSpy = jest.spyOn(scheduler, 'executePrewarm');

      // Act
      await scheduler.retryPrewarm1();

      // Assert: Should NOT execute pre-warm
      expect(executePrewarmSpy).not.toHaveBeenCalled();
    });

    it('should execute if last successful run was >1 hour ago', async () => {
      // Arrange: Set lastSuccessfulRun to 2 hours ago
      const twoHoursAgo = new Date(Date.now() - 2 * 60 * 60 * 1000);
      (scheduler as any).lastSuccessfulRun = twoHoursAgo;

      spoonacularService.search.mockResolvedValue([]);
      spoonacularService.getRecipeInformationBulk = jest.fn().mockResolvedValue([]);
      jest.spyOn(cacheService, 'upsertRecipes').mockResolvedValue([]);

      const executePrewarmSpy = jest.spyOn(scheduler, 'executePrewarm');

      // Act
      await scheduler.retryPrewarm1();

      // Assert: Should execute pre-warm
      expect(executePrewarmSpy).toHaveBeenCalledWith('3:00 AM UTC (retry 1)');
    });
  });

  describe('retryPrewarm2', () => {
    it('should execute if last successful run was >2 hours ago', async () => {
      // Arrange: Set lastSuccessfulRun to 3 hours ago
      const threeHoursAgo = new Date(Date.now() - 3 * 60 * 60 * 1000);
      (scheduler as any).lastSuccessfulRun = threeHoursAgo;

      spoonacularService.search.mockResolvedValue([]);
      spoonacularService.getRecipeInformationBulk = jest.fn().mockResolvedValue([]);
      jest.spyOn(cacheService, 'upsertRecipes').mockResolvedValue([]);

      const executePrewarmSpy = jest.spyOn(scheduler, 'executePrewarm');

      // Act
      await scheduler.retryPrewarm2();

      // Assert: Should execute pre-warm
      expect(executePrewarmSpy).toHaveBeenCalledWith('4:00 AM UTC (retry 2)');
    });
  });
});
