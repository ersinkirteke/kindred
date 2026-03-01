# Phase 1: Foundation - Research

**Researched:** 2026-02-28
**Domain:** Backend API (NestJS, GraphQL, PostgreSQL, Prisma, Authentication, Push Notifications, Recipe Scraping, AI Image Generation)
**Confidence:** HIGH

## Summary

Phase 1 establishes the backend foundation for a mobile-first recipe discovery app serving iOS and Android platforms. The architecture centers on NestJS with GraphQL API, PostgreSQL database via Prisma ORM, external authentication (Auth0/Clerk), recipe scraping from social platforms (X API + Instagram), AI-generated hero images (Google Imagen 4 Fast), Cloudflare R2 for image storage, and Firebase Cloud Messaging/APNs for push notifications. This greenfield implementation requires Docker containerization and GitHub Actions CI/CD for staging and production environments.

The stack is production-proven for mobile API backends: NestJS (currently v10+) with @nestjs/graphql (v13.2.4) provides TypeScript-first development with strong DI and modular architecture. Prisma ORM (now v7) offers type-safe database access with zero-overhead migrations. GraphQL enables mobile clients to request exactly the data needed, reducing over-fetching. Clerk emerged as the optimal authentication choice for mobile-first apps with superior React Native integration compared to Auth0's webview approach.

Critical implementation considerations include: handling X API's pay-per-use pricing ($200-5000/month tiers), navigating Instagram's scraping restrictions (legal only for public data, use authorized partners), managing AI image costs (Imagen 4 Fast at $0.02/image), implementing multi-stage Docker builds for minimal production images (150-200MB target), and establishing comprehensive testing with Jest/Testcontainers before deployment.

**Primary recommendation:** Start with NestJS CLI template, implement code-first GraphQL schema with feature-based module organization, use Clerk for mobile authentication, establish Prisma migrations early, containerize with multi-stage Docker, and set up Jest with Testcontainers for database integration testing from day one.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
**Backend Platform:**
- Custom NestJS (TypeScript) backend — not Firebase or Supabase
- PostgreSQL database with Prisma ORM
- Auth0 or Clerk for authentication (Claude's discretion on which)
- Google/Apple OAuth support required for mobile sign-in

**API Design:**
- GraphQL API (not REST)
- URL versioning (/v1/) for the GraphQL endpoint
- WebSockets for real-time push (expiry alerts, feed updates)
- OpenAPI/Swagger for API contract documentation shared between iOS and Android teams

**Scraping Approach:**
- API-first strategy: use official APIs where available (X API paid tier), scrape only as supplement/fallback
- City-level location granularity for trending detection (not neighborhood-level)
- Refresh frequency: 4-6 times per day
- Fallback on no data: expand radius (city → country → global trending)

**AI Image Pipeline:**
- Imagen 4 Fast for hero image generation (~$0.02/image)
- Pre-generate images when recipe is scraped (not on-demand)
- Flat lay editorial style: top-down, ingredients arranged artistically, Instagram-friendly, clean
- Cloudflare R2 + CDN for storage and serving (zero egress fees)

**Recipe Data Model:**
- Hybrid step storage: AI parses scraped freeform text into structured steps (order, text, duration, technique tag)
- Normalized ingredients: separate fields for name, quantity, unit — enables pantry matching
- AI-estimated nutritional info (calories, protein, carbs, fat) via Gemini
- Metadata tracked: engagement metrics (loves, bookmarks, views), AI-estimated difficulty level, auto-detected dietary tags (vegan, gluten-free, keto, halal, etc.)
- No source attribution stored (scraping is supplement, not content pipeline)

**Caching Strategy:**
- Offline-first architecture: cache feed + images + voice locally
- Cache last 50 recipes with images (~50MB)
- Cache all played voice narrations locally for offline replay
- Image TTL: 30 days with LRU eviction for oldest

**DevOps & CI/CD:**
- GitHub Actions for CI/CD pipeline
- Docker containerized deployment
- Two environments: Staging + Production

### Claude's Discretion
- Clerk vs Auth0 final selection (optimize for mobile-first, cost, DX)
- Hosting platform choice (Cloud Run, Railway, Fly.io, etc.)
- Push notification implementation (FCM for Android, APNs for iOS)
- GraphQL schema design and query structure
- WebSocket implementation details
- Docker base images and multi-stage build strategy
- Monitoring and error tracking tooling (Sentry, New Relic, etc.)
- Database migration strategy
- Rate limiting and security middleware

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| INFR-01 | Backend API serves both iOS and Android with shared data models | GraphQL code-first schema with NestJS provides type-safe shared models, mobile-optimized query flexibility |
| INFR-02 | Recipe scraping pipeline discovers trending recipes from Instagram/X by location | X API v2 paid tiers ($200-5000/mo), Instagram partner APIs (SociaVault/Phyllo) for legal compliance, city-level geolocation filtering |
| INFR-03 | AI image generation pipeline creates hero images for each scraped recipe | Imagen 4 Fast API ($0.02/image), pre-generation on scrape event, Cloudflare R2 storage with CDN delivery |
| INFR-04 | App functions with degraded experience when scraping sources are unavailable | Cached fallback strategy, radius expansion (city→country→global), NestJS exception filters for graceful degradation |
| INFR-06 | Push notification infrastructure for expiry alerts and engagement nudges | Firebase Cloud Messaging (Android) + APNs (iOS) integrated via NestJS, WebSocket subscriptions for real-time, device token management |
| AUTH-05 | User session persists across app restarts | Clerk/Auth0 refresh token strategy, mobile SDK session management, Redis session store for backend |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| NestJS | 10+ | Backend framework | TypeScript-first, modular DI architecture, production-proven for GraphQL APIs, extensive middleware ecosystem |
| @nestjs/graphql | 13.2.4 | GraphQL integration | Official NestJS package, code-first approach with decorators, supports subscriptions via WebSocket |
| Prisma | 7.x | ORM | Type-safe queries, zero-overhead migrations, schema-first with client generation, PostgreSQL optimized |
| PostgreSQL | 15+ | Database | ACID compliant, JSON support for flexible metadata, performant for recipe/user relational data |
| TypeScript | 5.x | Language | Type safety across schema/DB/API, catches errors at compile time, required by NestJS ecosystem |
| Jest | 29+ | Testing framework | Built into NestJS CLI, mocking support, Testcontainers integration for DB tests |
| Docker | Latest | Containerization | Multi-stage builds for 150-200MB production images, environment parity, standard for deployment |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Clerk | Latest | Authentication | Mobile-first auth with React Native components, Google/Apple OAuth, simpler than Auth0 for this use case |
| @nestjs/throttler | Latest | Rate limiting | Prevent DDoS/brute-force, configurable per-route limits, Redis backing for distributed systems |
| graphql-subscriptions | Latest | Real-time updates | WebSocket subscriptions for push notifications, feed updates, expiry alerts |
| class-validator | Latest | Input validation | Decorator-based validation on GraphQL inputs/DTOs, prevents injection attacks |
| class-transformer | Latest | Data transformation | Serialize/deserialize objects, sanitize responses, required for validation pipeline |
| @testcontainers/postgresql | Latest | Integration testing | Spin up real PostgreSQL in tests, avoid mocking database, catch migration issues early |
| winston | Latest | Logging | Structured logging, log levels, production observability |
| firebase-admin | Latest | Push notifications | FCM for Android, APNs via Firebase, device token management |
| @google-cloud/aiplatform | Latest | AI image generation | Imagen 4 Fast API client for hero image generation |
| @google-ai/generativelanguage | Latest | Recipe parsing | Gemini 3 Flash for ingredient normalization, nutritional estimation, dietary tag detection |
| aws-sdk (S3-compatible) | Latest | Object storage | Cloudflare R2 client (S3-compatible API), image upload/retrieval |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Clerk | Auth0 | Auth0 has enterprise SSO/compliance (SOC2, HIPAA) but uses webviews in React Native (worse UX), costs more at scale |
| Prisma | TypeORM | TypeORM is more flexible but lacks type generation, migrations are manual, higher bug surface |
| GraphQL | REST | REST simpler initially but mobile clients over-fetch, versioning harder, no real-time subscriptions built-in |
| PostgreSQL | MongoDB | MongoDB faster for unstructured data but recipe model is relational (user→bookmarks→recipes), no JOIN support |
| NestJS | Express | Express lighter but no DI, manual module wiring, no GraphQL/WebSocket conventions, slower development |

**Installation:**
```bash
# Core dependencies
npm install @nestjs/core @nestjs/common @nestjs/platform-express @nestjs/graphql @apollo/server graphql
npm install @prisma/client prisma
npm install class-validator class-transformer

# Authentication & Security
npm install @clerk/clerk-sdk-node @nestjs/throttler

# Real-time & Push
npm install graphql-subscriptions firebase-admin

# AI & Storage
npm install @google-cloud/aiplatform @google-ai/generativelanguage aws-sdk

# Logging
npm install winston nest-winston

# Dev dependencies
npm install -D @nestjs/cli @nestjs/testing @types/node typescript ts-node
npm install -D jest @types/jest ts-jest supertest @testcontainers/postgresql
```

## Architecture Patterns

### Recommended Project Structure
```
backend/
├── prisma/
│   ├── schema.prisma          # Prisma schema (source of truth)
│   └── migrations/            # SQL migration history
├── src/
│   ├── main.ts               # App bootstrap
│   ├── app.module.ts         # Root module
│   ├── config/               # Environment config, validation
│   ├── common/               # Shared utilities, decorators, guards
│   │   ├── guards/           # Auth, rate-limiting guards
│   │   ├── decorators/       # Custom GraphQL decorators
│   │   └── filters/          # Global exception filters
│   ├── auth/                 # Authentication module (Clerk integration)
│   ├── users/                # User management
│   ├── recipes/              # Recipe CRUD, scraping orchestration
│   ├── scraping/             # X API + Instagram scraping logic
│   ├── images/               # Imagen 4 integration, R2 upload
│   ├── push/                 # FCM/APNs notification service
│   └── graphql/              # GraphQL schema (code-first)
├── test/
│   ├── integration/          # Testcontainers-based DB tests
│   └── e2e/                  # End-to-end GraphQL tests
├── Dockerfile                # Multi-stage build
├── docker-compose.yml        # Local dev (Postgres, Redis)
└── .github/workflows/        # CI/CD pipelines
```

### Pattern 1: Code-First GraphQL Schema
**What:** Define GraphQL schema using TypeScript decorators on classes, auto-generate `.graphql` schema file.
**When to use:** Mobile APIs where type safety across frontend/backend is critical, rapid iteration on schema.
**Example:**
```typescript
// Source: https://docs.nestjs.com/graphql/quick-start
import { ObjectType, Field, ID, Int } from '@nestjs/graphql';

@ObjectType()
export class Recipe {
  @Field(() => ID)
  id: string;

  @Field()
  name: string;

  @Field(() => Int)
  prepTime: number; // minutes

  @Field(() => [Ingredient])
  ingredients: Ingredient[];

  @Field(() => [String])
  dietaryTags: string[]; // ['vegan', 'gluten-free']

  @Field({ nullable: true })
  imageUrl?: string; // Cloudflare R2 URL
}

@ObjectType()
export class Ingredient {
  @Field()
  name: string; // normalized (e.g., "chicken breast")

  @Field()
  quantity: string; // "2"

  @Field()
  unit: string; // "cups"
}
```

### Pattern 2: Prisma Schema-First Modeling
**What:** Define database schema in `schema.prisma`, generate type-safe Prisma Client, sync with DB via migrations.
**When to use:** All database interactions — migrations tracked in git, type errors caught at compile time.
**Example:**
```prisma
// Source: https://www.prisma.io/docs/orm/prisma-migrate
model User {
  id        String   @id @default(cuid())
  clerkId   String   @unique // Clerk user ID
  email     String   @unique
  createdAt DateTime @default(now())
  bookmarks Recipe[]
}

model Recipe {
  id            String   @id @default(cuid())
  name          String
  prepTime      Int
  ingredients   Json     // Normalized ingredient array
  dietaryTags   String[] // AI-detected tags
  imageUrl      String?  // R2 CDN URL
  scrapedFrom   String   // 'x' | 'instagram'
  scrapedAt     DateTime @default(now())
  location      String   // City-level
  bookmarkedBy  User[]
}
```

### Pattern 3: Multi-Stage Docker Build
**What:** Separate build stage (compile TS, install deps) from runtime stage (only production deps, dist/ folder).
**When to use:** All production deployments — reduces image size by 60-80%, faster cold starts, smaller attack surface.
**Example:**
```dockerfile
# Source: https://oneuptime.com/blog/post/2026-02-08-how-to-containerize-a-nestjs-application-with-docker/view
# Stage 1: Build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
COPY prisma ./prisma/
RUN npm ci
COPY . .
RUN npx prisma generate
RUN npm run build

# Stage 2: Production
FROM node:20-alpine
WORKDIR /app
RUN addgroup -g 1001 -S nodejs && adduser -S nestjs -u 1001
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./
USER nestjs
EXPOSE 3000
CMD ["node", "dist/main"]
```

### Pattern 4: GraphQL Subscriptions for Real-Time Push
**What:** Use WebSocket-based subscriptions for push notifications (expiry alerts, feed updates) instead of polling.
**When to use:** Real-time features where mobile clients need instant updates without battery-draining polling.
**Example:**
```typescript
// Source: https://docs.nestjs.com/graphql/subscriptions
import { Resolver, Subscription } from '@nestjs/graphql';
import { PubSub } from 'graphql-subscriptions';

const pubSub = new PubSub();

@Resolver()
export class NotificationResolver {
  @Subscription(() => Notification, {
    filter: (payload, variables) => payload.userId === variables.userId,
  })
  expiryAlert(@Args('userId') userId: string) {
    return pubSub.asyncIterator('expiryAlert');
  }
}

// Trigger from service:
pubSub.publish('expiryAlert', { userId: '123', message: 'Heavy cream expires in 2 days' });
```

### Pattern 5: Testcontainers Integration Testing
**What:** Spin up real PostgreSQL container during tests, run migrations, seed data, test against actual DB.
**When to use:** Integration tests for repositories, GraphQL resolvers with DB queries — catches migration bugs, data integrity issues.
**Example:**
```typescript
// Source: https://dev.to/medaymentn/improving-intergratione2e-testing-using-nestjs-and-testcontainers-3eh0
import { PostgreSqlContainer } from '@testcontainers/postgresql';
import { PrismaClient } from '@prisma/client';

let container: PostgreSqlContainer;
let prisma: PrismaClient;

beforeAll(async () => {
  jest.setTimeout(30000); // Container startup time
  container = await new PostgreSqlContainer().start();
  process.env.DATABASE_URL = container.getConnectionUri();
  prisma = new PrismaClient();
  await prisma.$executeRaw`-- run migrations`;
});

afterAll(async () => {
  await prisma.$disconnect();
  await container.stop();
});

test('recipe creation with normalized ingredients', async () => {
  const recipe = await prisma.recipe.create({
    data: {
      name: 'Tuscan Chicken',
      ingredients: [{ name: 'chicken breast', quantity: '2', unit: 'lbs' }],
    },
  });
  expect(recipe.ingredients[0].name).toBe('chicken breast');
});
```

### Anti-Patterns to Avoid
- **Circular module dependencies:** Use `forwardRef()` sparingly, refactor to shared module instead — slows DI resolution, causes runtime errors
- **Skipping Prisma migrations in dev:** Using `prisma db push` for production — loses migration history, causes schema drift
- **Large payload defaults:** NestJS body-parser limits 100kb — file uploads/base64 images fail silently, increase limit in `main.ts`
- **No timeout on HTTP calls:** Axios in HttpModule blocks forever on hanging dependencies — always set `timeout: 5000` in config
- **Global exception swallowing:** Catch-all error handlers hiding bugs — use typed exception filters per module
- **Synchronous Imagen calls in resolver:** 2-5 second image generation blocks GraphQL response — use queue (Bull) + pre-generation

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Authentication | Custom JWT signing, refresh token rotation, OAuth flows | Clerk or Auth0 | Mobile SDKs handle token refresh, biometric auth, Google/Apple OAuth ceremony — custom solutions miss edge cases (token theft, revocation, multi-device) |
| Rate limiting | Custom in-memory counters, IP tracking | @nestjs/throttler + Redis | Distributed rate limiting across instances, per-user/IP/route limits, prevents memory leaks from unbounded Maps |
| Recipe ingredient parsing | Regex-based extraction of quantity/unit | Gemini 3 Flash or Zestful API | "1 cup butter, melted" has 45+ preparation phrases, plural exceptions (hummus→hummu), unit normalization (tbsp vs tablespoon) — AI handles edge cases |
| Image optimization/resizing | Sharp or Jimp pipelines | Cloudflare Image Resizing | On-the-fly transforms via URL params, CDN caching, no server CPU burn — custom pipelines miss progressive JPEG, WebP, AVIF support |
| Push notification delivery | Direct FCM/APNs HTTP calls | firebase-admin SDK | Handles token refresh, batching, retry logic, platform-specific payload formats — raw HTTP misses error codes (InvalidRegistration, NotRegistered) |
| Database connection pooling | Custom pool management | Prisma Client | Connection limits per instance, query timeout handling, prepared statement caching — manual pools leak connections under load |
| GraphQL schema stitching | Manual resolver delegation across services | Apollo Federation (future) | Schema composition, resolver chaining, distributed tracing — hand-rolled stitching breaks introspection |

**Key insight:** Backend infrastructure (auth, rate limiting, push, DB pooling) has hidden complexity that surfaces under load or edge cases (token revocation, connection leaks, platform-specific push errors). Use battle-tested libraries that abstract these problems.

## Common Pitfalls

### Pitfall 1: X API Cost Explosion
**What goes wrong:** X API charges per read (15K reads = $200/month on Basic tier), scraping trending recipes 4-6x/day can quickly hit Pro tier ($5K/month) if not cached.
**Why it happens:** Each "trending in city" query reads multiple tweets, rapid refresh multiplies costs, no response caching strategy.
**How to avoid:** Implement aggressive caching (Redis, 1-hour TTL for trending queries), use X API's "recent search" endpoint with geo filter (cheaper than timeline), fallback to curated/cached data if quota exceeded, monitor usage via X API dashboard.
**Warning signs:** Unexpected $5000 invoice, API quota errors in logs, trending feed showing stale data due to emergency rate limiting.

### Pitfall 2: Instagram Scraping Legal Risk
**What goes wrong:** Direct Instagram scraping (bypassing login, automated browsing) violates Terms of Service, can trigger cease-and-desist, account bans, IP blocks.
**Why it happens:** Instagram's official API deprecated in 2020, no public recipe API exists, scraping seems like only option.
**How to avoid:** Use Instagram Partner Program approved services (SociaVault, Phyllo) that have legal data access, scrape only public posts, don't bypass login walls, include cease-and-desist handling in legal plan.
**Warning signs:** Instagram sends C&D letter, API proxy returns 429/403 errors, IP range gets blocked, scraping job success rate drops below 50%.

### Pitfall 3: Imagen 4 Latency Blocking Scrape Pipeline
**What goes wrong:** Imagen 4 Fast takes 2-5 seconds per image, synchronous generation during scraping blocks pipeline, reduces scrape throughput.
**Why it happens:** Scraping code calls Imagen API inline, waits for image before saving recipe, no async queue.
**How to avoid:** Decouple scraping from image generation via queue (BullMQ + Redis), save recipe immediately with placeholder image, process Imagen jobs in background workers, set worker concurrency limit (10-20 images/min).
**Warning signs:** Scraping jobs timeout after 30s, recipe ingestion rate < 10/min, Imagen API costs spike without proportional recipe increase.

### Pitfall 4: Prisma Circular Migration Dependencies
**What goes wrong:** Adding foreign key constraint that references future migration (e.g., User.recipeId before Recipe table exists), Prisma fails to apply migrations in production.
**Why it happens:** Development schema evolves non-linearly (add User, add Recipe, backfill User.recipeId), migrations created in wrong order.
**How to avoid:** Always run `prisma migrate dev` locally before pushing, review generated `.sql` files for FK order, use nullable FKs initially, backfill later migration, never edit old migrations.
**Warning signs:** `prisma migrate deploy` fails in CI/CD with "relation does not exist", production DB out of sync with schema.prisma, manual SQL fixes required.

### Pitfall 5: Clerk Webhook Signature Verification Skipped
**What goes wrong:** Skipping Clerk webhook signature verification allows attackers to forge user creation/deletion events, create unauthorized accounts, delete real users.
**Why it happens:** Webhook endpoint works without verification in dev, signature check seems optional, documentation missed.
**How to avoid:** Always verify `svix-signature` header using Clerk's webhook secret (environment variable), reject unsigned requests with 401, log verification failures for monitoring.
**Warning signs:** Unauthorized user accounts in DB, user deletion events not triggered by Clerk dashboard, webhook replay attacks in logs.

### Pitfall 6: GraphQL N+1 Query Problem
**What goes wrong:** Fetching recipe list with ingredients causes 1 query for recipes + N queries for ingredients (one per recipe), destroys performance at scale.
**Why it happens:** Prisma/TypeORM resolvers don't auto-batch, each ingredient field resolver triggers separate DB query.
**How to avoid:** Use Prisma's `include` to eagerly load relations in single query, implement DataLoader for batching (NestJS GraphQL supports this), monitor query counts in dev.
**Warning signs:** Recipe list endpoint takes 5+ seconds, DB query count = number of recipes * 2, Prisma logs show hundreds of SELECT queries.

### Pitfall 7: Docker Multi-Stage Build Not Pruning Dev Dependencies
**What goes wrong:** Production Docker image includes TypeScript, Jest, @nestjs/cli (200MB+ of dev deps), image size balloons to 800MB+.
**Why it happens:** `npm install` in production stage instead of `npm ci --production`, COPY node_modules from builder stage without pruning.
**How to avoid:** Run `npm ci --production` in runtime stage (skips devDependencies), only COPY dist/ and production node_modules, verify image size < 250MB before deploy.
**Warning signs:** Docker image > 500MB, `node_modules/@types/*` folders in production container, slow cold starts on Cloud Run/Fly.io.

### Pitfall 8: WebSocket Subscriptions Memory Leak
**What goes wrong:** GraphQL subscriptions don't clean up PubSub listeners when mobile client disconnects, memory grows unbounded, server OOMs after 24-48 hours.
**Why it happens:** PubSub.asyncIterator() registers listener but `onDisconnect` hook not implemented, listeners accumulate.
**How to avoid:** Implement `GraphQLModule` connection lifecycle hooks, call `subscription.return()` on disconnect, use Redis PubSub for multi-instance deployments (in-memory leaks across restarts).
**Warning signs:** Node heap size grows 10MB/hour, subscription count in metrics never decreases, server crashes with "JavaScript heap out of memory".

## Code Examples

Verified patterns from official sources:

### NestJS GraphQL Module Setup (Code-First)
```typescript
// Source: https://docs.nestjs.com/graphql/quick-start
import { Module } from '@nestjs/common';
import { GraphQLModule } from '@nestjs/graphql';
import { ApolloDriver, ApolloDriverConfig } from '@nestjs/apollo';

@Module({
  imports: [
    GraphQLModule.forRoot<ApolloDriverConfig>({
      driver: ApolloDriver,
      autoSchemaFile: 'schema.gql', // Auto-generate schema
      playground: true, // Enable GraphQL Playground in dev
      subscriptions: {
        'graphql-ws': true, // Enable WebSocket subscriptions
      },
      context: ({ req }) => ({ req }), // Pass request to resolvers for auth
    }),
  ],
})
export class AppModule {}
```

### Prisma Client Initialization with PostgreSQL
```typescript
// Source: https://www.prisma.io/docs/getting-started/prisma-orm/quickstart/postgresql
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient({
  log: ['query', 'error', 'warn'], // Enable query logging in dev
  errorFormat: 'pretty',
});

// Graceful shutdown
process.on('beforeExit', async () => {
  await prisma.$disconnect();
});

export default prisma;
```

### Clerk Authentication Guard
```typescript
// Source: https://clerk.com/docs (conceptual example)
import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { GqlExecutionContext } from '@nestjs/graphql';
import { ClerkClient } from '@clerk/clerk-sdk-node';

@Injectable()
export class ClerkAuthGuard implements CanActivate {
  constructor(private clerkClient: ClerkClient) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const ctx = GqlExecutionContext.create(context);
    const { req } = ctx.getContext();
    const token = req.headers.authorization?.split(' ')[1];

    if (!token) return false;

    try {
      const session = await this.clerkClient.verifyToken(token);
      req.user = { clerkId: session.sub };
      return true;
    } catch {
      return false;
    }
  }
}
```

### Rate Limiting Configuration
```typescript
// Source: https://docs.nestjs.com/security/rate-limiting
import { Module } from '@nestjs/common';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';

@Module({
  imports: [
    ThrottlerModule.forRoot([{
      ttl: 60000, // 1 minute
      limit: 10, // 10 requests per minute
    }]),
  ],
  providers: [
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard, // Apply globally
    },
  ],
})
export class AppModule {}
```

### Cloudflare R2 Upload (S3-Compatible)
```typescript
// Source: https://developers.cloudflare.com/r2/ (S3-compatible API)
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';

const r2Client = new S3Client({
  region: 'auto',
  endpoint: `https://${process.env.CLOUDFLARE_ACCOUNT_ID}.r2.cloudflarestorage.com`,
  credentials: {
    accessKeyId: process.env.R2_ACCESS_KEY_ID,
    secretAccessKey: process.env.R2_SECRET_ACCESS_KEY,
  },
});

async function uploadImage(imageBuffer: Buffer, recipeId: string): Promise<string> {
  const key = `recipes/${recipeId}/hero.jpg`;
  await r2Client.send(new PutObjectCommand({
    Bucket: 'kindred-images',
    Key: key,
    Body: imageBuffer,
    ContentType: 'image/jpeg',
  }));

  return `https://images.kindred.app/${key}`; // R2 public URL
}
```

### Imagen 4 Fast Image Generation
```typescript
// Source: https://developers.googleblog.com/announcing-imagen-4-fast-and-imagen-4-family-generally-available-in-the-gemini-api/
import { ImageGenerationServiceClient } from '@google-cloud/aiplatform';

const client = new ImageGenerationServiceClient({
  apiEndpoint: 'us-central1-aiplatform.googleapis.com',
});

async function generateRecipeImage(recipeName: string): Promise<Buffer> {
  const prompt = `Flat lay top-down photograph of ${recipeName}, ingredients arranged artistically, Instagram-friendly, clean white background, natural lighting`;

  const [response] = await client.generateImages({
    model: 'imagen-4-fast', // $0.02/image
    prompt,
    numberOfImages: 1,
    aspectRatio: '1:1',
  });

  return response.images[0].bytesBase64Encoded; // Buffer to upload to R2
}
```

### Firebase Cloud Messaging Push Notification
```typescript
// Source: https://firebase.google.com/docs/cloud-messaging
import * as admin from 'firebase-admin';

admin.initializeApp({
  credential: admin.credential.cert(process.env.FIREBASE_SERVICE_ACCOUNT),
});

async function sendExpiryAlert(deviceToken: string, ingredient: string) {
  await admin.messaging().send({
    token: deviceToken,
    notification: {
      title: 'Ingredient Expiring Soon',
      body: `Your ${ingredient} expires in 2 days`,
    },
    apns: {
      headers: {
        'apns-priority': '10', // High priority
      },
      payload: {
        aps: {
          sound: 'default',
          contentAvailable: true,
        },
      },
    },
  });
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Schema-first GraphQL (SDL files) | Code-first (TypeScript decorators) | NestJS v7+ (2020) | Type safety across API/DB, auto-schema generation, faster iteration |
| Prisma 2.x (Rust engine required) | Prisma 7.x (TypeScript-only) | January 2025 | No Rust binary in node_modules, faster installs, smaller Docker images |
| Auth0 for mobile | Clerk for mobile-first apps | 2023-2024 | Native React Native components vs webviews, better UX, lower cost for startups |
| X API Free tier | Pay-per-use pricing ($200-5000/mo) | February 2026 | Requires budgeting for scraping, caching critical, free tier write-only |
| Instagram Basic Display API | Partner Program only | April 2020 | Legal scraping requires approved partners (Phyllo, SociaVault), no direct API |
| Imagen 2 | Imagen 4 Fast | February 2025 | 50% cost reduction ($0.04 → $0.02), faster generation, better quality |
| Manual Docker layer optimization | Multi-stage builds standard | Docker 17.05+ (2017) | 150-200MB images vs 800MB+, industry standard now |

**Deprecated/outdated:**
- **Instagram Basic Display API:** Deprecated April 2020, replaced with Instagram Graph API (requires business account + Facebook page) or Partner Program — use partners for recipe scraping
- **Prisma 1.x:** Replaced by Prisma 2+ in 2020, incompatible migration path, no longer maintained
- **NestJS schema-first GraphQL:** Still supported but code-first is recommended for TypeScript projects (better DX, type safety)
- **X API v1.1:** Deprecated, v2 required (different endpoints, authentication, pricing model)
- **@nestjs/jwt with PassportJS:** Still works but Clerk/Auth0 SDKs handle more edge cases (refresh tokens, MFA, OAuth flows)

## Open Questions

1. **Hosting Platform: Cloud Run vs Railway vs Fly.io**
   - What we know: Cloud Run is serverless (auto-scale to zero, pay-per-request), Railway is simplest DX ($30/month fixed), Fly.io is edge (35 data centers, $10.70/month for 1vCPU)
   - What's unclear: Which best fits recipe scraping workload (4-6x/day batch jobs vs continuous traffic), cold start impact on GraphQL API latency
   - Recommendation: Start with Railway for simplicity during development, evaluate Fly.io for production if global latency matters (multi-region recipe sources), avoid Cloud Run initially (WebSocket subscriptions harder to configure)

2. **Redis for Caching/PubSub: When to Introduce**
   - What we know: GraphQL subscriptions use in-memory PubSub (doesn't scale across instances), X API caching needs TTL store, rate limiting benefits from distributed state
   - What's unclear: Single-instance deployment initially or multi-instance from day one, Redis adds complexity/cost
   - Recommendation: Start without Redis (single instance, in-memory PubSub), add Redis when scaling to 2+ instances or X API costs exceed $500/month (caching ROI clear)

3. **Scraping Cadence Optimization**
   - What we know: 4-6 refreshes/day specified, X API costs scale with read volume, city-level trending
   - What's unclear: Optimal refresh times (mealtimes? evening browsing?), per-city vs global refresh strategy, cost vs freshness tradeoff
   - Recommendation: Start with 4x/day at fixed times (8am, 12pm, 6pm, 9pm local time per city), monitor X API costs for 1 week, A/B test freshness impact on user engagement, adjust cadence per cost/engagement ratio

4. **Database Migration Strategy: Staging → Production**
   - What we know: Prisma Migrate generates SQL files, `prisma migrate deploy` for production, should be in CI/CD
   - What's unclear: Zero-downtime migration strategy for breaking changes (rename column, change type), rollback procedure
   - Recommendation: Use expand-and-contract pattern for breaking changes (add new column, migrate data, deprecate old column in separate migrations), test migrations on staging DB clone, keep manual rollback scripts in `prisma/rollback/` directory

5. **OpenAPI/Swagger for GraphQL: Tooling Choice**
   - What we know: User requires API contract documentation for iOS/Android teams, GraphQL has introspection (self-documenting)
   - What's unclear: OpenAPI typically for REST, how to generate from GraphQL schema, what tool to use
   - Recommendation: Use GraphQL schema introspection as primary documentation (Apollo Studio or GraphQL Playground), export schema.gql to git, consider graphql-to-openapi converter if teams require OpenAPI format (rare for GraphQL)

## Validation Architecture

> Note: workflow.nyquist_validation not found in config.json — assuming enabled by default

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Jest 29+ with @nestjs/testing |
| Config file | Auto-generated by NestJS CLI in `package.json` |
| Quick run command | `npm run test -- --testPathPattern=recipes` |
| Full suite command | `npm run test:cov` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INFR-01 | GraphQL API serves iOS/Android with shared schema | integration | `npm run test -- src/graphql/schema.spec.ts -x` | ❌ Wave 0 |
| INFR-02 | Recipe scraping pipeline fetches from X/Instagram by location | integration | `npm run test -- src/scraping/pipeline.spec.ts -x` | ❌ Wave 0 |
| INFR-03 | AI image generation creates hero images for recipes | integration | `npm run test -- src/images/generation.spec.ts -x` | ❌ Wave 0 |
| INFR-04 | Degraded mode serves cached recipes when scraping fails | unit | `npm run test -- src/recipes/fallback.spec.ts -x` | ❌ Wave 0 |
| INFR-06 | Push notifications send to FCM/APNs registered devices | integration | `npm run test -- src/push/fcm.spec.ts -x` | ❌ Wave 0 |
| AUTH-05 | User session persists via Clerk refresh tokens | integration | `npm run test -- src/auth/session.spec.ts -x` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `npm run test -- --testPathPattern={module}` (affected module tests only, < 30s)
- **Per wave merge:** `npm run test:cov` (full suite with coverage report, < 5min target)
- **Phase gate:** Full suite green + integration tests with Testcontainers before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/integration/setup.ts` — Testcontainers PostgreSQL setup, shared across integration tests
- [ ] `src/graphql/schema.spec.ts` — Validates GraphQL schema generation, resolver type safety
- [ ] `src/scraping/pipeline.spec.ts` — Mocks X API/Instagram responses, tests location filtering
- [ ] `src/images/generation.spec.ts` — Mocks Imagen 4 API, tests R2 upload flow
- [ ] `src/recipes/fallback.spec.ts` — Tests cached recipe retrieval when scraping fails
- [ ] `src/push/fcm.spec.ts` — Mocks firebase-admin, tests device token management
- [ ] `src/auth/session.spec.ts` — Mocks Clerk SDK, tests refresh token flow
- [ ] `jest.config.js` — Extends NestJS default, adds Testcontainers timeout (30s)
- [ ] Framework install: `npm install -D jest @nestjs/testing @types/jest ts-jest supertest @testcontainers/postgresql` — if not in package.json

## Sources

### Primary (HIGH confidence)
- [NestJS GraphQL Releases](https://github.com/nestjs/graphql/releases) - Version verification (13.2.4 current)
- [Prisma ORM Changelog](https://www.prisma.io/changelog) - Prisma 7 features, TypeScript migration
- [Cloudflare R2 Documentation](https://developers.cloudflare.com/r2/) - Storage limits, S3 compatibility
- [Imagen 4 Fast Announcement](https://developers.googleblog.com/announcing-imagen-4-fast-and-imagen-4-family-generally-available-in-the-gemini-api/) - Pricing ($0.02/image), performance
- [NestJS Official Documentation - GraphQL](https://docs.nestjs.com/graphql/quick-start) - Code-first setup, subscriptions
- [NestJS Official Documentation - Testing](https://docs.nestjs.com/fundamentals/testing) - Jest integration, testing module
- [NestJS Official Documentation - Rate Limiting](https://docs.nestjs.com/security/rate-limiting) - @nestjs/throttler configuration
- [Prisma Migrate Documentation](https://www.prisma.io/docs/orm/prisma-migrate) - Production workflow, migration strategy

### Secondary (MEDIUM confidence)
- [Auth0 vs Clerk Comparison (SuperTokens)](https://supertokens.com/blog/auth0-vs-clerk) - Feature comparison, mobile support (2025)
- [Auth0 vs Clerk Comparison (Clerk)](https://clerk.com/articles/user-management-platform-comparison-react-clerk-auth0-firebase) - React Native integration differences
- [X API Pricing Guide 2026](https://twitterapi.io/blog/twitter-api-pricing-2025) - Pay-per-use model, tier comparison
- [Instagram Scraping Legal Guide 2026](https://www.datadwip.com/blog/how-to-scrape-instagram/) - hiQ v. LinkedIn precedent, Partner Program
- [Cloudflare R2 Beginner's Guide 2025](https://dev.to/leonwong282/the-complete-beginners-guide-to-cloudflare-r2-image-hosting-2025-2g4k) - Setup steps, free tier
- [Railway vs Fly.io Comparison 2026](https://thesoftwarescout.com/fly-io-vs-railway-2026-which-developer-platform-should-you-deploy-on/) - Pricing, global distribution
- [NestJS Docker Production Guide 2026](https://oneuptime.com/blog/post/2026-02-08-how-to-containerize-a-nestjs-application-with-docker/view) - Multi-stage builds
- [NestJS Common Mistakes](https://medium.com/@enguerrandpp/10-common-mistakes-to-avoid-when-using-nest-js-ea96f5f460b0) - Circular dependencies, DI pitfalls
- [NestJS Project Structure Best Practices](https://arnab-k.medium.com/best-practices-for-structuring-a-nestjs-application-b3f627548220) - Module organization
- [Recipe Ingredient Parsing AI 2026](https://rob-blinsinger-blog.pages.dev/posts/2026-02-22-parsing-recipe-ingredients) - Normalization pipeline, L1/L2 caching

### Tertiary (LOW confidence)
- [GraphQL API Development 2026](https://miracl.in/blog/graphql-api-development-2026/) - General best practices (not NestJS-specific)
- [NestJS Testing Guide](https://oneuptime.com/blog/post/2026-02-02-nestjs-testing/view) - Testcontainers setup (unverified with official docs)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - NestJS, Prisma, GraphQL versions verified from official sources, current as of Feb 2026
- Architecture: HIGH - Patterns sourced from official NestJS docs, Prisma documentation, recent production guides (2025-2026)
- Pitfalls: MEDIUM - Derived from community experience (Medium articles, DEV posts), cross-verified with multiple sources, some context-specific (X API pricing, Instagram legal)
- AI services: HIGH - Imagen 4 pricing/features from official Google blog, FCM from Firebase docs
- Hosting comparison: MEDIUM - Railway/Fly.io pricing from platform docs, reliability concerns from recent community feedback (Railway 44% Next.js success rate needs validation)

**Research date:** 2026-02-28
**Valid until:** 2026-03-31 (30 days for stable stack), 2026-03-07 (7 days for fast-moving: X API pricing, Imagen features)
