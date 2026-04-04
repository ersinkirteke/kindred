import { Test, TestingModule } from '@nestjs/testing';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { SpoonacularService } from './spoonacular.service';
import { PrismaService } from '../prisma/prisma.service';
import { of, throwError } from 'rxjs';
import { AxiosResponse } from 'axios';
import * as fixtures from '../../test/fixtures/spoonacular-responses.json';

describe('SpoonacularService', () => {
  let service: SpoonacularService;
  let httpService: HttpService;
  let prismaService: PrismaService;
  let configService: ConfigService;

  const mockHttpService = {
    get: jest.fn(),
  };

  const mockPrismaService = {
    apiQuotaUsage: {
      findUnique: jest.fn(),
      upsert: jest.fn(),
    },
  };

  const mockConfigService = {
    get: jest.fn((key: string) => {
      if (key === 'SPOONACULAR_API_KEY') return 'test-api-key';
      if (key === 'SPOONACULAR_DAILY_QUOTA') return 50;
      return undefined;
    }),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SpoonacularService,
        { provide: HttpService, useValue: mockHttpService },
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: ConfigService, useValue: mockConfigService },
      ],
    }).compile();

    service = module.get<SpoonacularService>(SpoonacularService);
    httpService = module.get<HttpService>(HttpService);
    prismaService = module.get<PrismaService>(PrismaService);
    configService = module.get<ConfigService>(ConfigService);

    // Reset mocks and service state between tests
    jest.clearAllMocks();
    (service as any).consecutiveFailures = 0;
    (service as any).circuitOpenUntil = null;
    (service as any).lastRequestTime = null;
  });

  describe('search', () => {
    it('should call complexSearch with correct query params', async () => {
      const mockResponse: AxiosResponse = {
        data: fixtures.complexSearchResponse,
        status: 200,
        statusText: 'OK',
        headers: {},
        config: {} as any,
      };

      mockHttpService.get.mockReturnValue(of(mockResponse));
      mockPrismaService.apiQuotaUsage.findUnique.mockResolvedValue({
        pointsUsed: 10,
      });
      mockPrismaService.apiQuotaUsage.upsert.mockResolvedValue({});

      const result = await service.search('pasta', {}, 10, 0);

      expect(httpService.get).toHaveBeenCalledWith(
        '/recipes/complexSearch',
        expect.objectContaining({
          params: expect.objectContaining({
            apiKey: 'test-api-key',
            query: 'pasta',
            addRecipeInformation: true,
            sort: 'popularity',
            number: 10,
            offset: 0,
          }),
        }),
      );
      expect(result).toHaveLength(2);
      expect(result[0].id).toBe(716429);
    });

    it('should apply cuisine filter correctly', async () => {
      const mockResponse: AxiosResponse = {
        data: fixtures.complexSearchResponse,
        status: 200,
        statusText: 'OK',
        headers: {},
        config: {} as any,
      };

      mockHttpService.get.mockReturnValue(of(mockResponse));
      mockPrismaService.apiQuotaUsage.findUnique.mockResolvedValue({
        pointsUsed: 10,
      });
      mockPrismaService.apiQuotaUsage.upsert.mockResolvedValue({});

      await service.search('pasta', { cuisines: ['italian', 'mediterranean'] }, 10, 0);

      expect(httpService.get).toHaveBeenCalledWith(
        '/recipes/complexSearch',
        expect.objectContaining({
          params: expect.objectContaining({
            cuisine: 'italian,mediterranean',
          }),
        }),
      );
    });

    it('should apply diet and intolerance filters', async () => {
      const mockResponse: AxiosResponse = {
        data: fixtures.complexSearchResponse,
        status: 200,
        statusText: 'OK',
        headers: {},
        config: {} as any,
      };

      mockHttpService.get.mockReturnValue(of(mockResponse));
      mockPrismaService.apiQuotaUsage.findUnique.mockResolvedValue({
        pointsUsed: 10,
      });
      mockPrismaService.apiQuotaUsage.upsert.mockResolvedValue({});

      await service.search(
        'chicken',
        {
          diets: ['vegetarian'],
          intolerances: ['dairy', 'gluten'],
        },
        10,
        0,
      );

      expect(httpService.get).toHaveBeenCalledWith(
        '/recipes/complexSearch',
        expect.objectContaining({
          params: expect.objectContaining({
            diet: 'vegetarian',
            intolerances: 'dairy,gluten',
          }),
        }),
      );
    });
  });

  describe('getRecipeInformationBulk', () => {
    it('should pass comma-joined IDs and return parsed recipe array', async () => {
      const mockResponse: AxiosResponse = {
        data: fixtures.bulkRecipeResponse,
        status: 200,
        statusText: 'OK',
        headers: {},
        config: {} as any,
      };

      mockHttpService.get.mockReturnValue(of(mockResponse));
      mockPrismaService.apiQuotaUsage.findUnique.mockResolvedValue({
        pointsUsed: 10,
      });
      mockPrismaService.apiQuotaUsage.upsert.mockResolvedValue({});

      const result = await service.getRecipeInformationBulk([716429, 715538]);

      expect(httpService.get).toHaveBeenCalledWith(
        '/recipes/informationBulk',
        expect.objectContaining({
          params: expect.objectContaining({
            apiKey: 'test-api-key',
            ids: '716429,715538',
            includeNutrition: true,
          }),
        }),
      );
      expect(result).toHaveLength(1);
      expect(result[0].id).toBe(716429);
    });
  });

  describe('quota tracking', () => {
    it('should increment points after successful API call', async () => {
      const mockResponse: AxiosResponse = {
        data: fixtures.complexSearchResponse,
        status: 200,
        statusText: 'OK',
        headers: {},
        config: {} as any,
      };

      mockHttpService.get.mockReturnValue(of(mockResponse));
      mockPrismaService.apiQuotaUsage.findUnique.mockResolvedValue({
        pointsUsed: 10,
      });
      mockPrismaService.apiQuotaUsage.upsert.mockResolvedValue({});

      await service.search('pasta', {}, 10, 0);

      // complexSearch with 2 results and addRecipeInformation costs: 1 + 0.01*2 + 0.025*2 = 1.07 points
      expect(prismaService.apiQuotaUsage.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { date: expect.any(String) },
          update: {
            pointsUsed: {
              increment: expect.any(Number),
            },
          },
          create: expect.objectContaining({
            date: expect.any(String),
            pointsUsed: expect.any(Number),
          }),
        }),
      );
    });

    it('should block API call when quota exhausted', async () => {
      mockPrismaService.apiQuotaUsage.findUnique.mockResolvedValue({
        pointsUsed: 50, // At quota limit
      });

      await expect(service.search('pasta', {}, 10, 0)).rejects.toThrow(
        'Daily API quota exhausted',
      );

      expect(httpService.get).not.toHaveBeenCalled();
    });

    it('should log warning at 80% quota threshold but not block', async () => {
      const mockResponse: AxiosResponse = {
        data: fixtures.complexSearchResponse,
        status: 200,
        statusText: 'OK',
        headers: {},
        config: {} as any,
      };

      mockHttpService.get.mockReturnValue(of(mockResponse));
      mockPrismaService.apiQuotaUsage.findUnique.mockResolvedValue({
        pointsUsed: 40, // 80% of 50
      });
      mockPrismaService.apiQuotaUsage.upsert.mockResolvedValue({});

      const logSpy = jest.spyOn((service as any).logger, 'warn');

      await service.search('pasta', {}, 10, 0);

      expect(logSpy).toHaveBeenCalledWith(
        expect.stringContaining('80% quota threshold'),
      );
      expect(httpService.get).toHaveBeenCalled();
    });
  });

  describe('circuit breaker', () => {
    it('should open after 5 consecutive failures', async () => {
      mockHttpService.get.mockReturnValue(
        throwError(() => new Error('Network error')),
      );
      mockPrismaService.apiQuotaUsage.findUnique.mockResolvedValue({
        pointsUsed: 10,
      });

      // Trigger 5 failures
      for (let i = 0; i < 5; i++) {
        try {
          await service.search('test', {}, 10, 0);
        } catch (e) {
          // Expected to fail
        }
      }

      // 6th call should be blocked by circuit breaker
      await expect(service.search('test', {}, 10, 0)).rejects.toThrow(
        'Circuit breaker is open',
      );

      // HTTP should only be called 5 times (not 6)
      expect(httpService.get).toHaveBeenCalledTimes(5);
    });

    it('should reset circuit breaker on successful call', async () => {
      mockPrismaService.apiQuotaUsage.findUnique.mockResolvedValue({
        pointsUsed: 10,
      });
      mockPrismaService.apiQuotaUsage.upsert.mockResolvedValue({});

      // Trigger failures
      mockHttpService.get.mockReturnValue(
        throwError(() => new Error('Network error')),
      );

      for (let i = 0; i < 3; i++) {
        try {
          await service.search('test', {}, 10, 0);
        } catch (e) {
          // Expected
        }
      }

      expect((service as any).consecutiveFailures).toBe(3);

      // Successful call
      const mockResponse: AxiosResponse = {
        data: fixtures.complexSearchResponse,
        status: 200,
        statusText: 'OK',
        headers: {},
        config: {} as any,
      };
      mockHttpService.get.mockReturnValue(of(mockResponse));

      await service.search('test', {}, 10, 0);

      expect((service as any).consecutiveFailures).toBe(0);
      expect((service as any).circuitOpenUntil).toBeNull();
    });
  });

  describe('rate limiting', () => {
    it('should enforce 1-second delay between consecutive calls', async () => {
      const mockResponse: AxiosResponse = {
        data: fixtures.complexSearchResponse,
        status: 200,
        statusText: 'OK',
        headers: {},
        config: {} as any,
      };

      mockHttpService.get.mockReturnValue(of(mockResponse));
      mockPrismaService.apiQuotaUsage.findUnique.mockResolvedValue({
        pointsUsed: 10,
      });
      mockPrismaService.apiQuotaUsage.upsert.mockResolvedValue({});

      const start = Date.now();

      // First call
      await service.search('test1', {}, 10, 0);
      const firstCallTime = Date.now();

      // Second call (should be delayed)
      await service.search('test2', {}, 10, 0);
      const secondCallTime = Date.now();

      const timeBetweenCalls = secondCallTime - firstCallTime;

      // Should be at least 1000ms between calls
      expect(timeBetweenCalls).toBeGreaterThanOrEqual(1000);
    });
  });
});
