# Kindred

## What This Is

Kindred is a hyperlocal, AI-humanized culinary assistant mobile app (native iOS + Android). It discovers viral recipes trending in your neighborhood from Instagram and X, presents them with stunning AI-generated food imagery, and reads the instructions aloud in the cloned voice of someone you love — like your mom or grandma. It's not a recipe database; it's an emotional utility that turns cooking into a connection with loved ones while solving daily "what should I cook?" decision fatigue.

## Core Value

Hearing a loved one's voice guide you through a trending local recipe — that emotional moment is what makes Kindred irreplaceable. Everything else supports getting users to that moment.

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

(None yet — ship to validate)

### Active

- [ ] Hyperlocal viral recipe feed from Instagram/X (5-10 mile radius)
- [ ] AI-generated hero images for every recipe (cinematic food-porn aesthetic)
- [ ] Voice cloning from 30-60 second audio clip of a loved one (ElevenLabs)
- [ ] Listen to recipe instructions narrated in cloned voice
- [ ] Skip or bookmark recipes (swipe or button)
- [ ] Culinary DNA personalization (learns from skips/bookmarks, stops showing disliked ingredients)
- [ ] Fridge photo scanning to identify ingredients and suggest recipes (Gemini 3 Flash)
- [ ] Supermarket receipt scanning to populate digital pantry
- [ ] Food expiry tracking with proactive recipe suggestions before food expires
- [ ] Accessibility for elderly users (75+) — 56dp touch targets, 18sp+ text, max 2 taps to cook
- [ ] Free tier with 1 voice slot, ad-supported (local grocery coupons)
- [ ] Pro tier ($9.99/mo) with unlimited voice slots, ad-free, expiry alerts

### Out of Scope

- AI cooking video generation (Veo) — deferred to v2 due to $4.50-9.00/user/month cost, 30-120s latency, and cooking safety concerns with AI-generated technique videos
- Social features (sharing, following) — deferred to v1.5 as viral amplifier
- Instacart/UberEats "Order Ingredients" integration — deferred to v2, requires partnership deals
- Real-time chat or community features — high complexity, not core to value proposition
- Web app — mobile-first, native only for v1
- Cross-platform framework (Flutter/React Native) — native iOS + Android for best UX and accessibility

## Context

**Emotional positioning:** Kindred moves beyond "recipe database" into emotional utility. The voice cloning feature creates a connection to loved ones that no competitor offers. This is the viral loop — users share the experience, friends download and upload their own loved one's voice.

**Platform strategy:** iOS first launch, Android fast-follow (4-6 weeks). iOS has higher ARPU, better accessibility APIs, and more consistent testing environment. Backend/API/AI pipeline is 100% shared between platforms.

**Tech stack (from team research):**
- iOS: SwiftUI + TCA (The Composable Architecture), iOS 17.0 min, SwiftData, SPM modules
- Android: Jetpack Compose + MVVM/Clean Architecture + Hilt, min SDK 26, Room + Proto DataStore
- Voice: ElevenLabs API (custom REST + WebSocket streaming — native SDKs are immature)
- Vision: Gemini 3 Flash (fridge ~85-90% accuracy, receipt ~95%+ accuracy)
- Scraping: Apify/Browse AI for public trending data (build to work without it — scraping is fragile)
- Backend: TBD (Firebase or Supabase)

**Design direction:** Warm cream/terracotta palette (#FFF9F0 backgrounds, #E07849 accents), card-based swipeable feed, 4-tab bottom navigation (Feed, Scan, Pantry, Me), rounded friendly typography (SF Pro Rounded iOS, Nunito Android). "Build for Grandpa George" — if a 75-year-old can use it, everyone can.

**Market context:** TAM $8-9B (recipe + food waste + meal planning), growing to $18-20B by 2033. Competitors (Samsung Food, Yummly, Tasty, Paprika) have no emotional voice feature — this is Kindred's moat. Not because they can't technically add it, but because Kindred's entire brand and UX is built around it.

**Monetization:**
- Free: Hyperlocal feed, AI images, 1 voice slot, ad-supported (local grocery coupons)
- Pro ($9.99/mo): Unlimited voice slots, ad-free, expiry alerts
- v2: Partnership affiliate (Instacart/UberEats 3-5% commission)

## Constraints

- **Legal**: Voice cloning consent framework required before launch — Tennessee ELVIS Act, California AB 1836 (covers deceased persons' voices), New York digital replica laws. Budget $20-50K for AI/media legal counsel.
- **API Costs**: ElevenLabs ~$0.01-0.03/recipe for voice. Must implement hard budget caps per user.
- **Scraping**: Instagram/X ToS prohibit scraping. Build abstraction layer, diversify sources, ensure app works without scraping as fallback.
- **Accessibility**: WCAG AAA target. 56dp min touch targets, 18sp min body text, max 3 navigation levels, VoiceOver/TalkBack full support.
- **Simplicity**: Max 2 taps from feed to cooking with voice. No hamburger menus, no complex gestures without button fallbacks.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Native iOS + Android (not cross-platform) | Best UX, accessibility, and platform-specific capabilities for elderly users | — Pending |
| iOS first, Android fast-follow | Higher ARPU, better accessibility APIs, shared backend | — Pending |
| Defer Veo AI video to v2 | $4.50-9/user/month cost, 30-120s latency, cooking safety risk | — Pending |
| TCA for iOS, MVVM+Clean for Android | Platform-idiomatic architectures, both support modular feature structure | — Pending |
| ElevenLabs custom client (not SDK) | Native SDKs immature (Kotlin v0.1.0 agents-only, Swift v3 limited) | — Pending |
| Free voice slot in v1 | Don't paywall the viral hook — voice IS the retention and viral mechanic | — Pending |
| Build scraping abstraction layer | Instagram/X scraping is legally fragile, need fallback content sources | — Pending |

---
*Last updated: 2026-02-28 after initialization*
