import { Module } from '@nestjs/common';
import { RecipesService } from './recipes.service';
import { RecipesResolver } from './recipes.resolver';
import { RecipeTranslationService } from './recipe-translation.service';
import { SpoonacularModule } from '../spoonacular/spoonacular.module';

@Module({
  imports: [SpoonacularModule],
  providers: [RecipesService, RecipesResolver, RecipeTranslationService],
  exports: [RecipesService],
})
export class RecipesModule {}
