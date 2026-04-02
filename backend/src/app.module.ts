import { Module } from '@nestjs/common';
import { GraphQLModule } from '@nestjs/graphql';
import { ApolloDriver, ApolloDriverConfig } from '@nestjs/apollo';
import { ThrottlerModule } from '@nestjs/throttler';
import { ScheduleModule } from '@nestjs/schedule';
import { APP_INTERCEPTOR } from '@nestjs/core';
import { join } from 'path';

import { RequestIdInterceptor } from './common/interceptors/request-id.interceptor';

import { ConfigModule } from './config/config.module';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { RecipesModule } from './recipes/recipes.module';
import { UsersModule } from './users/users.module';
import { HealthModule } from './health/health.module';
import { ScrapingModule } from './scraping/scraping.module';
import { ImagesModule } from './images/images.module';
import { PushModule } from './push/push.module';
import { GeocodingModule } from './geocoding/geocoding.module';
import { FeedModule } from './feed/feed.module';
import { VoiceModule } from './voice/voice.module';
import { PantryModule } from './pantry/pantry.module';
import { ScanModule } from './scan/scan.module';
import { PrivacyModule } from './privacy/privacy.module';

@Module({
  imports: [
    // Global configuration with environment validation
    ConfigModule,

    // GraphQL API with code-first schema
    GraphQLModule.forRoot<ApolloDriverConfig>({
      driver: ApolloDriver,
      autoSchemaFile: join(process.cwd(), 'schema.gql'),
      playground: process.env.NODE_ENV !== 'production',
      introspection: process.env.NODE_ENV !== 'production',
      sortSchema: true,
      path: '/v1/graphql', // Versioned endpoint
      subscriptions: {
        'graphql-ws': true, // Enable WebSocket subscriptions for real-time features
      },
      context: ({ req, res }) => ({ req, res }), // Pass request and response to resolvers
    }),

    // Scheduled tasks
    ScheduleModule.forRoot(),

    // Rate limiting with named contexts
    ThrottlerModule.forRoot([
      { name: 'default', ttl: 60000, limit: 100 },     // 100 req/min standard
      { name: 'expensive', ttl: 60000, limit: 10 },     // 10 req/min for narration/subscription
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
    ImagesModule,
    PushModule,
    GeocodingModule,
    FeedModule,
    VoiceModule,
    PantryModule,
    ScanModule,
    PrivacyModule,
  ],
  providers: [
    {
      provide: APP_INTERCEPTOR,
      useClass: RequestIdInterceptor,
    },
  ],
})
export class AppModule {}
