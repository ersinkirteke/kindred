import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { SpoonacularService } from './spoonacular.service';
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
  providers: [SpoonacularService],
  exports: [SpoonacularService],
})
export class SpoonacularModule {}
