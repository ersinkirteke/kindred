import { Module } from '@nestjs/common';
import { GraphQLModule } from '@nestjs/graphql';
import { ApolloDriver, ApolloDriverConfig } from '@nestjs/apollo';
import { ThrottlerModule } from '@nestjs/throttler';
import { ScheduleModule } from '@nestjs/schedule';
import { join } from 'path';

import { ConfigModule } from './config/config.module';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { RecipesModule } from './recipes/recipes.module';
import { UsersModule } from './users/users.module';
import { HealthModule } from './health/health.module';
import { ScrapingModule } from './scraping/scraping.module';

@Module({
  imports: [
    // Global configuration with environment validation
    ConfigModule,

    // GraphQL API with code-first schema
    GraphQLModule.forRoot<ApolloDriverConfig>({
      driver: ApolloDriver,
      autoSchemaFile: join(process.cwd(), 'schema.gql'),
      playground: true, // Enable GraphQL Playground in development
      sortSchema: true,
      path: '/v1/graphql', // Versioned endpoint
      subscriptions: {
        'graphql-ws': true, // Enable WebSocket subscriptions for real-time features
      },
      context: ({ req }) => ({ req }), // Pass request to resolvers for auth
    }),

    // Scheduled tasks
    ScheduleModule.forRoot(),

    // Rate limiting (60 requests per minute by default)
    ThrottlerModule.forRoot([
      {
        ttl: 60000, // 60 seconds
        limit: 100, // 100 requests
      },
    ]),

    // Global Prisma module
    PrismaModule,

    // Authentication module
    AuthModule,

    // Feature modules
    RecipesModule,
    UsersModule,
    HealthModule,
    ScrapingModule,
  ],
})
export class AppModule {}
