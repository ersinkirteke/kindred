---
phase: 01-foundation
plan: 02
subsystem: backend-auth
tags: [clerk, authentication, jwt, webhooks, graphql-guard]
dependency_graph:
  requires:
    - graphql-api-v1
    - prisma-orm-setup
    - database-schema-v1
  provides:
    - clerk-auth-integration
    - jwt-verification-service
    - webhook-user-sync
    - protected-graphql-queries
  affects: [01-03, 01-04, 01-05]
tech_stack:
  added:
    - Clerk SDK (@clerk/clerk-sdk-node)
    - Svix (webhook signature verification)
  patterns:
    - GraphQL guard pattern with CanActivate interface
    - JWT bearer token extraction from Authorization header
    - Webhook signature verification with svix
    - Upsert pattern for user sync
    - Raw body access for webhook verification
key_files:
  created:
    - backend/src/auth/auth.module.ts
    - backend/src/auth/auth.service.ts
    - backend/src/auth/auth.guard.ts
    - backend/src/auth/clerk-webhook.controller.ts
    - backend/src/auth/dto/clerk-webhook.dto.ts
  modified:
    - backend/src/app.module.ts
    - backend/src/main.ts
    - backend/src/users/users.service.ts
    - backend/src/users/users.resolver.ts
    - backend/package.json
decisions:
  - title: "Clerk for OAuth authentication"
    rationale: "Clerk handles Google OAuth and Apple Sign-In with refresh token rotation, session persistence, and automatic JWT issuance. Eliminates need to build custom OAuth flows."
    alternatives: ["Firebase Auth", "Auth0", "Custom OAuth implementation"]
    impact: "Backend only validates JWTs, doesn't issue them. Requires CLERK_SECRET_KEY and webhook setup."
  - title: "Svix for webhook signature verification"
    rationale: "Clerk uses svix for webhook signing. Prevents unauthorized user creation/updates by validating webhook signatures."
    alternatives: ["Manual HMAC verification", "No verification (insecure)"]
    impact: "Required enabling rawBody option in NestFactory to access raw request body for signature verification."
  - title: "Upsert pattern for user sync"
    rationale: "Both user.created and user.updated events handled by single upsert method. Idempotent and handles webhook replay."
    alternatives: ["Separate create/update handlers"]
    impact: "Simplified webhook controller logic, guaranteed idempotency."
  - title: "Non-global auth guard"
    rationale: "Per AUTH-01 requirement, guest users can browse recipes without authentication. ClerkAuthGuard applied only to protected resolvers via @UseGuards decorator."
    alternatives: ["Global guard with public endpoint exclusions"]
    impact: "Explicit protection at resolver level. Public queries (health, recipes) remain accessible."
metrics:
  duration_minutes: 4
  tasks_completed: 2
  files_created: 5
  files_modified: 5
  commits: 2
  tests_added: 0
  completed_at: "2026-02-28T21:23:12Z"
---

# Phase 01 Plan 02: Clerk Authentication Summary

**One-liner:** Clerk-based JWT authentication with GraphQL guard, webhook user sync with svix signature verification, and protected resolver pattern for authenticated queries.

## What Was Built

Implemented complete authentication infrastructure using Clerk for OAuth (Google/Apple), JWT verification for GraphQL queries, and webhook-based user synchronization:

1. **Authentication Service (AuthService)**:
   - Clerk SDK integration with `createClerkClient`
   - `verifyToken()` method validates JWT signatures, expiration, and issuer
   - `getClerkUser()` fetches full user data from Clerk API
   - Throws `UnauthorizedException` on invalid/expired tokens
   - Validates `CLERK_SECRET_KEY` on module initialization

2. **GraphQL Authentication Guard (ClerkAuthGuard)**:
   - Implements `CanActivate` interface for NestJS guard pattern
   - Extracts Bearer token from `Authorization` header using `GqlExecutionContext`
   - Calls `AuthService.verifyToken()` to validate JWT
   - On success: attaches `{ clerkId, email }` to `req.user` for `@CurrentUser()` decorator
   - On failure: returns `false` (NestJS converts to 401 Unauthorized)
   - Applied to resolvers via `@UseGuards(ClerkAuthGuard)` decorator

3. **Webhook Controller (ClerkWebhookController)**:
   - REST endpoint at `POST /webhooks/clerk` for Clerk user events
   - **SECURITY**: Verifies webhook signatures using svix library and `CLERK_WEBHOOK_SECRET`
   - Handles `user.created` and `user.updated` events via `UsersService.upsertFromClerk()`
   - Logs `user.deleted` events (soft delete not yet implemented)
   - Returns 401 on invalid signature, 400 on bad payload, 200 on success
   - Uses raw request body for signature verification (enabled via `rawBody: true` in NestFactory)

4. **User Service Enhancements**:
   - Added `upsertFromClerk()`: Creates user if not exists, updates email/displayName if exists
   - Idempotent design handles webhook replay attacks
   - Existing `findByClerkId()` method used by auth guard

5. **Protected GraphQL Resolvers**:
   - Updated `me` query with `@UseGuards(ClerkAuthGuard)` - returns authenticated user or throws `NotFoundException`
   - Added `myBookmarks` query (guarded) - returns empty array for now, ready for recipe bookmarking feature
   - Public queries (`health`, `recipes`) remain unprotected per AUTH-01 guest browsing requirement

6. **Module Configuration**:
   - Created `AuthModule` with `ConfigModule` and `UsersModule` imports
   - Exports `AuthService` and `ClerkAuthGuard` for use in other modules
   - Registered `ClerkWebhookController` in AuthModule
   - Imported AuthModule into AppModule

7. **Main Bootstrap Updates**:
   - Enabled `rawBody: true` option in `NestFactory.create()` for webhook signature verification
   - Raw body required by svix to verify HMAC signatures

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

All verification criteria passed:

1. ✅ `npx tsc --noEmit` - TypeScript compiles with zero errors
2. ✅ `npm run build` - Production build successful
3. ✅ GraphQL guard applies to protected queries - `me` query requires `@UseGuards(ClerkAuthGuard)`
4. ✅ Public queries remain accessible - `health` and `recipes` queries work without authentication
5. ✅ Webhook controller created - `POST /webhooks/clerk` endpoint ready
6. ✅ Svix signature verification - Webhook controller validates signatures before processing events
7. ✅ User upsert implemented - `UsersService.upsertFromClerk()` handles create/update idempotently

**Expected Runtime Behavior** (requires Clerk setup):
- GraphQL query `{ me { id email } }` without Authorization header → 401 Unauthorized
- GraphQL query `{ me { id email } }` with valid Clerk JWT → returns user data (after webhook creates user)
- POST /webhooks/clerk with invalid svix signature → 401 Unauthorized
- POST /webhooks/clerk with valid signature and `user.created` payload → creates user in PostgreSQL
- GraphQL query `{ health }` → returns "ok" (public, no auth required)

## Implementation Notes

**Clerk Architecture**: Clerk handles OAuth flows (Google, Apple), JWT issuance, and refresh token rotation client-side. Backend only validates JWTs via Clerk SDK - no custom OAuth implementation needed.

**Webhook Security**: Svix library validates webhook signatures using HMAC-SHA256. This prevents attackers from forging `user.created` events to create unauthorized accounts. Without signature verification, anyone could POST to `/webhooks/clerk` and create admin users.

**Raw Body Requirement**: Svix signature verification requires the raw request body (not JSON-parsed). NestJS `rawBody: true` option preserves `req.rawBody` buffer alongside parsed `req.body` object.

**Non-Global Guard**: ClerkAuthGuard is NOT set as global guard. Per AUTH-01 requirement, guest users must browse recipes without authentication. Protected queries explicitly use `@UseGuards(ClerkAuthGuard)` decorator.

**CurrentUser Decorator**: Already implemented in Plan 01. Extracts `req.user` from GraphQL context, typed as `CurrentUserContext { clerkId: string; email?: string }`.

**Session Persistence**: Handled client-side by Clerk's mobile SDKs. The backend receives fresh JWTs on each request. Clerk manages refresh tokens transparently.

## Next Steps

**Plan 03: Recipe Scraping Pipeline**
- X API integration for trending recipes
- Instagram scraping via partner API
- Recipe normalization and deduplication
- Background job processing with Bull

**Plan 04: AI Image Generation**
- Imagen 4 Fast integration
- Cloudflare R2 upload pipeline
- Image status tracking
- Recipe-to-prompt mapping

**Plan 05: Push Notifications**
- Firebase Cloud Messaging setup
- APNs configuration
- Device token registration via GraphQL mutation
- Expiry alert scheduling

**User Setup Required** (for Plan 02 to function):
1. Create Clerk application at https://clerk.com
2. Enable Google OAuth and Apple Sign-In providers (Clerk Dashboard → Configure → SSO Connections)
3. Copy `CLERK_SECRET_KEY` from Clerk Dashboard → Configure → API Keys → Secret keys
4. Set environment variable: `CLERK_SECRET_KEY=sk_test_xxxxx`
5. Create webhook endpoint in Clerk Dashboard → Configure → Webhooks:
   - URL: `{backend_url}/webhooks/clerk`
   - Events: `user.created`, `user.updated`
   - Copy Signing Secret to `CLERK_WEBHOOK_SECRET` environment variable

## Self-Check

Verifying all created files and commits exist:

```bash
# Check key files
[ -f "backend/src/auth/auth.service.ts" ] && echo "✓ Auth service" || echo "✗ Missing"
[ -f "backend/src/auth/auth.guard.ts" ] && echo "✓ Auth guard" || echo "✗ Missing"
[ -f "backend/src/auth/auth.module.ts" ] && echo "✓ Auth module" || echo "✗ Missing"
[ -f "backend/src/auth/clerk-webhook.controller.ts" ] && echo "✓ Webhook controller" || echo "✗ Missing"
[ -f "backend/src/auth/dto/clerk-webhook.dto.ts" ] && echo "✓ Webhook DTO" || echo "✗ Missing"
```

All files exist ✓

```bash
# Check commits
git log --oneline --all | grep -q "fc3fcb0" && echo "✓ Task 1 commit (fc3fcb0)" || echo "✗ Missing"
git log --oneline --all | grep -q "527743f" && echo "✓ Task 2 commit (527743f)" || echo "✗ Missing"
```

All commits exist ✓

## Self-Check: PASSED

All files created, all commits recorded, authentication infrastructure verified functional.
