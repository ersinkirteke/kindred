# Kindred

A social cooking app where AI-cloned voices narrate recipes from loved ones. Built with SwiftUI + TCA for iOS and NestJS + GraphQL for the backend.

## Architecture

### System Overview

```mermaid
graph TB
    subgraph iOS["iOS App (SwiftUI + TCA)"]
        Feed[Feed]
        Pantry[Pantry]
        Profile[Profile]
        VoicePlayer[Voice Player]
        Apollo[Apollo GraphQL Client]
    end

    subgraph Backend["NestJS Backend"]
        GQL[GraphQL API<br/>/v1/graphql]
        REST[REST Endpoints<br/>/voice/upload, /voice/narrate]
        Auth[Auth Guard<br/>Clerk JWT]
        subgraph Modules["Feature Modules"]
            FeedMod[Feed]
            RecipesMod[Recipes]
            VoiceMod[Voice]
            ScanMod[Scan]
            PantryMod[Pantry]
            SubMod[Subscription]
            PushMod[Push]
            ScrapeMod[Scraping]
        end
    end

    subgraph Data["Data Layer"]
        PG[(PostgreSQL 15<br/>+ PostGIS)]
        R2[(Cloudflare R2<br/>Storage)]
    end

    subgraph External["External Services"]
        Clerk[Clerk Auth]
        ElevenLabs[ElevenLabs<br/>Voice Cloning]
        Gemini[Google Gemini<br/>AI Processing]
        Mapbox[Mapbox<br/>Geocoding]
        Firebase[Firebase<br/>Push Notifications]
        AppStore[App Store<br/>StoreKit 2]
    end

    iOS -->|GraphQL| GQL
    iOS -->|Multipart / Stream| REST
    GQL --> Auth
    REST --> Auth
    Auth --> Modules

    VoiceMod --> ElevenLabs
    VoiceMod --> R2
    ScanMod --> Gemini
    ScanMod --> R2
    RecipesMod --> PG
    PantryMod --> PG
    FeedMod --> PG
    ScrapeMod --> PG
    PushMod --> Firebase
    SubMod --> AppStore

    iOS --> Clerk
    Auth --> Clerk
    FeedMod --> Mapbox
```

### Backend Architecture

```mermaid
graph LR
    subgraph Client["iOS Client"]
        ApolloClient[Apollo GraphQL]
        AVPlayer[AVPlayer]
    end

    subgraph API["API Layer"]
        GraphQL["/v1/graphql<br/>Apollo Server"]
        VoiceREST["/voice/upload<br/>/voice/narrate"]
        Webhooks["/webhooks<br/>Clerk + App Store"]
    end

    subgraph Guards["Middleware"]
        ClerkGuard[Clerk Auth Guard]
        Throttle[Rate Limiter<br/>100/min default<br/>10/min expensive]
    end

    subgraph Services["Service Layer"]
        FeedSvc[FeedService<br/>Geospatial queries]
        RecipeSvc[RecipeService<br/>CRUD + engagement]
        VoiceSvc[VoiceService<br/>Clone + narrate]
        ScanSvc[ScanService<br/>Fridge + receipt AI]
        PantrySvc[PantryService<br/>Inventory mgmt]
        SubSvc[SubscriptionService<br/>StoreKit 2 verify]
        PushSvc[PushService<br/>FCM delivery]
        ScrapeSvc[ScrapingService<br/>Instagram/X parser]
        ImageSvc[ImageService<br/>Hero generation]
        GeoSvc[GeocodingService<br/>City lookup]
    end

    subgraph Storage["Storage"]
        Prisma[Prisma ORM]
        PG[(PostgreSQL<br/>+ PostGIS)]
        R2[(Cloudflare R2)]
    end

    ApolloClient --> GraphQL
    AVPlayer --> VoiceREST
    GraphQL --> Guards
    VoiceREST --> Guards
    Webhooks --> Guards
    Guards --> Services
    Services --> Prisma
    Prisma --> PG
    VoiceSvc --> R2
    ScanSvc --> R2
    ImageSvc --> R2
```

### iOS App Architecture

```mermaid
graph TB
    subgraph App["KindredApp"]
        AppDelegate[AppDelegate<br/>Clerk + Audio + Firebase]
        AppReducer[AppReducer]
    end

    subgraph Features["Feature Packages (TCA)"]
        AuthFeature[AuthFeature<br/>Sign-in + Onboarding]
        FeedFeature[FeedFeature<br/>Recipe Discovery]
        PantryFeature[PantryFeature<br/>Inventory + Scanning]
        ProfileFeature[ProfileFeature<br/>Settings + Voice Profiles]
        VoicePlayback[VoicePlaybackFeature<br/>Audio Narration]
        Monetization[MonetizationFeature<br/>Ads + Subscriptions]
    end

    subgraph Core["Core Packages"]
        NetworkClient[NetworkClient<br/>Apollo GraphQL]
        KindredAPI[KindredAPI<br/>Generated Schema]
        AuthClient[AuthClient<br/>Clerk Session]
        DesignSystem[DesignSystem<br/>UI Components]
    end

    subgraph Navigation["Tab Navigation"]
        FeedTab[Feed Tab]
        PantryTab[Pantry Tab]
        ProfileTab[Profile Tab]
        MiniPlayer[Mini Player Overlay]
    end

    AppReducer --> AuthFeature
    AppReducer --> Navigation

    FeedTab --> FeedFeature
    PantryTab --> PantryFeature
    ProfileTab --> ProfileFeature
    MiniPlayer --> VoicePlayback

    FeedFeature --> NetworkClient
    PantryFeature --> NetworkClient
    ProfileFeature --> NetworkClient
    VoicePlayback --> NetworkClient
    Monetization --> NetworkClient

    AuthFeature --> AuthClient
    NetworkClient --> KindredAPI
    Features --> DesignSystem
```

### iOS App (`Kindred/`)

Built with **SwiftUI**, **The Composable Architecture (TCA)**, and a modular **Swift Package Manager** structure targeting **iOS 17.0+**.

| Package | Description |
|---------|-------------|
| **AuthFeature** | Sign-in with Apple via Clerk, onboarding flow (dietary prefs, location) |
| **AuthClient** | Clerk authentication client with session management |
| **FeedFeature** | Recipe feed with location-based filtering, dietary chips, engagement metrics |
| **PantryFeature** | Pantry inventory management, barcode/fridge scanning, expiry tracking |
| **ProfileFeature** | User profile, dietary preferences, subscription status, voice profiles |
| **VoicePlaybackFeature** | Audio playback engine for AI-cloned voice narration with AVPlayer |
| **MonetizationFeature** | Google Mobile Ads integration, UMP consent, StoreKit 2 subscriptions |
| **NetworkClient** | Apollo GraphQL client with caching and dependency injection |
| **KindredAPI** | Apollo-generated GraphQL schema types |
| **DesignSystem** | Shared UI components, typography, colors, haptics |

### Backend (`backend/`)

**NestJS 11** with **Apollo GraphQL**, **Prisma ORM**, and **PostgreSQL 15 + PostGIS**.

| Module | Description |
|--------|-------------|
| **auth** | Clerk webhook integration, JWT guards |
| **users** | User profile management |
| **recipes** | Recipe CRUD, search, engagement (likes, bookmarks) |
| **feed** | Feed algorithm with geospatial queries, dietary filtering |
| **pantry** | Pantry items, expiry tracking, storage locations |
| **voice** | AI voice cloning (ElevenLabs), narration generation/caching |
| **scan** | OCR for receipts/fridge scans, AI item detection (Gemini) |
| **images** | Hero image generation via Gemini, Cloudflare R2 storage |
| **subscription** | StoreKit 2 validation, App Store Server Notifications |
| **scraping** | Instagram/X recipe scraping and parsing |
| **geocoding** | Mapbox integration, city-level caching |
| **push** | Firebase push notifications with rate limiting |
| **privacy** | GDPR compliance, data export |

### Database Models

- **User & Auth** — User, DeviceToken
- **Recipes** — Recipe (with geospatial lat/lon), Ingredient, RecipeStep, Bookmark
- **Pantry** — PantryItem, ScanJob, IngredientCatalog
- **Voice** — VoiceProfile, NarrationScript, NarrationAudio
- **Subscriptions** — Subscription, TransactionHistory
- **Notifications** — NotificationPreferences, NotificationLog
- **Geo** — CityLocation (geocoding cache)

## Tech Stack

| Layer | Technology |
|-------|-----------|
| iOS | SwiftUI, TCA, Swift 5.10 |
| Backend | NestJS 11, Apollo GraphQL, TypeScript |
| Database | PostgreSQL 15 + PostGIS |
| ORM | Prisma 7 |
| Auth | Clerk (iOS SDK + Backend SDK) |
| AI | Google Gemini (recipe parsing, narration rewriting) |
| Voice | ElevenLabs (voice cloning + TTS) |
| Storage | Cloudflare R2 |
| Push | Firebase Cloud Messaging |
| Geocoding | Mapbox |
| Monetization | Google Mobile Ads, StoreKit 2 |
| CI/CD | GitHub Actions → Hetzner (Docker) |

## Development

### Prerequisites

- Xcode 16+ (iOS 17.0 target)
- Node.js 20+
- Docker & Docker Compose
- PostgreSQL 15 with PostGIS

### Backend Setup

```bash
cd backend
npm install
npx prisma generate
npx prisma migrate dev

# Start with Docker
docker compose up -d

# Or run directly
npm run start:dev
```

### iOS Setup

Open `Kindred/Kindred.xcodeproj` in Xcode. Swift packages resolve automatically.

### Environment Variables

Backend requires a `.env` file with:

```
DATABASE_URL=postgresql://...
CLERK_SECRET_KEY=...
CLERK_PUBLISHABLE_KEY=...
CLERK_WEBHOOK_SECRET=...
ELEVENLABS_API_KEY=...
GEMINI_API_KEY=...
CLOUDFLARE_R2_ACCESS_KEY=...
CLOUDFLARE_R2_SECRET_KEY=...
CLOUDFLARE_R2_BUCKET=...
CLOUDFLARE_R2_ENDPOINT=...
MAPBOX_ACCESS_TOKEN=...
FIREBASE_PROJECT_ID=...
APPLE_BUNDLE_ID=...
APPLE_APP_ID=...
APPLE_ALLOWED_PRODUCT_IDS=...
```

## CI/CD

GitHub Actions pipeline with two workflows:

- **CI** (`ci.yml`) — Runs on all pushes: lint, typecheck, build, Docker image verification
- **Deploy** (`deploy.yml`) — Runs on push to `main`: SSH to Hetzner server, pull, build, migrate, restart, health check

Deployment target: `api.kindredcook.app`

## API

GraphQL endpoint: `POST /v1/graphql`

Health check:
```bash
curl -X POST https://api.kindredcook.app/v1/graphql \
  -H 'Content-Type: application/json' \
  -d '{"query":"{ health }"}'
```

Voice upload (REST): `POST /voice/upload` (multipart form-data)

Narration streaming (REST): `GET /voice/narrate/:recipeId/:voiceProfileId`

## License

Private — All rights reserved.
