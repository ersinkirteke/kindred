import { Module, Logger } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { SpoonacularService } from './spoonacular.service';
import { SpoonacularCacheService } from './spoonacular-cache.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [
    HttpModule.register({
      baseURL: 'https://api.spoonacular.com',
      timeout: 5000,
      maxRedirects: 0,
    }),
    PrismaModule,
  ],
  providers: [SpoonacularService, SpoonacularCacheService, Logger],
  exports: [SpoonacularService, SpoonacularCacheService],
})
export class SpoonacularModule {}
