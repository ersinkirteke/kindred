# Phase 4: Foundation & Architecture - Context

**Gathered:** 2026-03-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish the iOS app skeleton: SwiftUI + TCA project structure, Apollo iOS GraphQL client with Clerk JWT auth, shared UI theme system (light + dark mode), and 2-tab navigation (Feed, Me). No user-facing features — this is the infrastructure all other phases build on.

</domain>

<decisions>
## Implementation Decisions

### Tab bar composition
- 2 tabs only: Feed and Me (Scan/Pantry deferred to v2.1, add tabs when features ship)
- Standard iOS tab bar with SF Symbols icons
- Tab bar always visible (never hides on scroll) — accessibility priority
- Feed tab shows badge count when new viral recipes arrive
- Guest users see full sign-in gate on Me tab (no settings access until authenticated)
- Me tab (authenticated): Profile + Voice profile management + Settings

### Dark mode support
- Light + dark mode from day one, system auto-following + manual override in settings
- Warm dark palette: dark browns, deep terracotta, warm grays — maintains cozy kitchen feeling
- Recipe card images: rounded corners with padding (dark card surface visible around image)
- Accent color: darken terracotta for text usage (WCAG AAA 7:1 contrast). Keep #E07849 for decorative elements only
- Use darker terracotta variant (~#C0553A or similar) wherever accent color appears as text on backgrounds

### App launch experience
- Animated logo splash screen (app icon with subtle animation — fade in, pulse, or warmth glow)
- First launch: splash → single dismissible welcome card ("Kindred discovers viral recipes near you. Swipe to explore.") → feed
- Location permission: asked contextually on first feed load (not upfront)
- Location denied fallback: default to popular city (e.g., Istanbul), user can change manually later
- Returning users: always fresh feed on launch (no scroll position restoration)
- Loading state: skeleton cards matching recipe card layout while GraphQL fetches

### Typography & fonts
- SF Pro (system font) throughout — native Dynamic Type support, optimal readability
- Font weight personality: medium headings, light body — softer, elegant, matches warm/cozy vibe
- Minimum 18sp body text (WCAG AAA requirement)

### Haptic feedback
- Haptics for key moments: swipe bookmark, voice play start, successful save
- Respect iOS system haptic setting (no separate in-app toggle)

### Error & empty states
- Warm and friendly error tone ("Hmm, we can't find recipes right now. Check your connection and try again.")
- Custom AI-generated illustrations for error/empty states (warm, hand-drawn style — empty plate, sad pot, etc.)
- Illustrations generated via Imagen, consistent with AI hero image aesthetic

### Claude's Discretion
- Exact dark mode color palette values (warm dark browns, deep terracotta specifics)
- Splash animation implementation (fade in vs pulse vs glow)
- Specific SF Symbol choices for tab icons
- Skeleton card animation details
- Exact haptic feedback types (UIImpactFeedbackGenerator styles)
- AI illustration prompts and generation approach
- SPM module organization and TCA feature decomposition

</decisions>

<specifics>
## Specific Ideas

- "Build for Grandpa George" — if a 75-year-old can use it, everyone can
- Tab bar always visible = no hidden navigation, no complex gestures required
- Welcome card on first launch keeps it to one interaction before feed (not a multi-screen onboarding)
- Dark mode should still feel like a warm kitchen, not a cold dark tech app
- Error messages should feel like a friend apologizing, not a computer reporting a failure

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- No iOS code exists — greenfield project
- Backend GraphQL schema provides all data models (Recipe, RecipeCard, User, VoiceProfile, NarrationMetadata, DeviceToken)
- Backend resolvers: feed (cursor-based RecipeConnection), recipes, voice, users, push, health

### Established Patterns
- Backend uses NestJS code-first GraphQL — schema introspection available for Apollo iOS codegen
- Clerk JWT auth with guard pattern — iOS needs matching JWT token injection in Apollo client
- Cloudflare R2 URLs for images and audio — iOS loads these directly via URL

### Integration Points
- Apollo iOS connects to NestJS GraphQL API (single endpoint)
- Clerk iOS SDK provides JWT tokens → injected into Apollo auth interceptor
- Firebase iOS SDK for push notification registration → sends APNs token to backend via `registerDeviceToken` mutation
- Image URLs from R2 CDN → Kingfisher image loading/caching
- No backend changes needed for Phase 4

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 04-foundation-architecture*
*Context gathered: 2026-03-01*
