import { Module } from '@nestjs/common';
import { RecipesService } from './recipes.service';
import { RecipesResolver } from './recipes.resolver';
import { SpoonacularModule } from '../spoonacular/spoonacular.module';

@Module({
  imports: [SpoonacularModule],
  providers: [RecipesService, RecipesResolver],
  exports: [RecipesService],
})
export class RecipesModule {}
