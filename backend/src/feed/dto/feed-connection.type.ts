import { ObjectType, Field, Int } from '@nestjs/graphql';
import { RecipeCard } from './recipe-card.type';

/**
 * Relay-style cursor pagination types for feed
 */

@ObjectType()
export class PageInfo {
  @Field(() => Boolean)
  hasNextPage: boolean;

  @Field(() => Boolean)
  hasPreviousPage: boolean;

  @Field(() => String, { nullable: true })
  startCursor?: string | null;

  @Field(() => String, { nullable: true })
  endCursor?: string | null;
}

@ObjectType()
export class RecipeCardEdge {
  @Field(() => RecipeCard)
  node: RecipeCard;

  @Field()
  cursor: string;
}

@ObjectType()
export class RecipeConnection {
  @Field(() => [RecipeCardEdge])
  edges: RecipeCardEdge[];

  @Field(() => PageInfo)
  pageInfo: PageInfo;

  @Field(() => Int)
  totalCount: number;

  @Field()
  lastRefreshed: string; // ISO timestamp

  @Field(() => String, { nullable: true })
  expandedFrom?: string | null; // 'city' | null

  @Field(() => String, { nullable: true })
  expandedTo?: string | null; // 'country' | 'global' | null

  @Field(() => Int, { nullable: true })
  newSinceLastFetch?: number | null;

  @Field(() => Boolean, { nullable: true })
  partialMatch?: boolean | null;

  @Field(() => [String], { nullable: true })
  filtersRelaxed?: string[] | null;
}
