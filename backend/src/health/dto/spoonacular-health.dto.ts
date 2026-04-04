import { ObjectType, Field, Float, Int } from '@nestjs/graphql';

@ObjectType({ description: 'Spoonacular API health and quota status' })
export class SpoonacularHealthStatus {
  @Field(() => Float, { description: 'API points used today' })
  quotaUsed: number;

  @Field(() => Float, { description: 'Daily quota limit' })
  quotaLimit: number;

  @Field(() => Float, { description: 'Remaining API points for today' })
  quotaRemaining: number;

  @Field({ description: 'ISO timestamp when quota resets (next midnight UTC)' })
  quotaResetAt: string;

  @Field(() => Int, { description: 'Total recipes cached from Spoonacular' })
  cachedRecipeCount: number;

  @Field(() => Int, { description: 'Total cached search results' })
  cachedSearchCount: number;
}
