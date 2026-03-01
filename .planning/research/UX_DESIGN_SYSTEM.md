# Kindred — UX/UI Design System

> **Purpose:** Complete design system specification for Kindred — a hyperlocal, AI-humanized culinary assistant. Accessibility-first for users aged 75+ while maintaining a premium, modern aesthetic.

---

## 1. Design Principles

| # | Principle | Description |
|---|-----------|-------------|
| 1 | **Warmth First** | Every pixel should feel like a warm kitchen — inviting, familiar, comforting. The UI is a hug, not a dashboard. |
| 2 | **Effortless for Everyone** | If a 78-year-old grandmother can use it without help, the design is right. If she can't, it's wrong. No exceptions. |
| 3 | **Food is the Hero** | UI chrome recedes; food photography and recipe content dominate. The app is a window into cooking, not a software interface. |
| 4 | **One Thing at a Time** | Each screen has one primary purpose. Reduce cognitive load to near-zero. Progressive disclosure for advanced features. |
| 5 | **Voice as Companion** | Voice is not a feature — it's an emotional connection. The "Mom's voice" experience must feel intimate, not robotic. |

---

## 2. Color Palette

### 2.1 Primary Colors (Warm Food Tones)

Derived from the founder's mockups — cream backgrounds, terracotta accents, warm browns.

| Token Name | Hex | RGB | Usage |
|------------|-----|-----|-------|
| `cream-50` | `#FFF9F0` | 255, 249, 240 | Page background (light) |
| `cream-100` | `#FFF3E0` | 255, 243, 224 | Card background |
| `cream-200` | `#FFE8CC` | 255, 232, 204 | Elevated surface |
| `terracotta-400` | `#E07849` | 224, 120, 73 | Primary accent, CTAs |
| `terracotta-500` | `#C9623A` | 201, 98, 58 | Primary accent (pressed) |
| `terracotta-600` | `#A84E2D` | 168, 78, 45 | Primary accent (dark mode) |
| `warm-brown-700` | `#5D3A1A` | 93, 58, 26 | Primary text |
| `warm-brown-800` | `#3E2712` | 62, 39, 18 | Heading text |
| `warm-brown-900` | `#2A1A0C` | 42, 26, 12 | High-emphasis text |

### 2.2 Semantic Colors

| Token Name | Light Mode | Dark Mode | Usage |
|------------|-----------|-----------|-------|
| `surface-primary` | `cream-50` | `#1C1410` | Main background |
| `surface-card` | `#FFFFFF` | `#2A1E16` | Card backgrounds |
| `surface-elevated` | `cream-100` | `#3A2E26` | Modals, sheets |
| `text-primary` | `warm-brown-800` | `#F5E6D3` | Body text |
| `text-secondary` | `#8B7355` | `#BFA88A` | Captions, metadata |
| `text-on-primary` | `#FFFFFF` | `#FFFFFF` | Text on terracotta buttons |
| `accent-primary` | `terracotta-400` | `terracotta-600` | Buttons, links, active states |
| `accent-secondary` | `#7BAE4E` | `#8BC45E` | Success, "fresh" indicator |
| `semantic-error` | `#D32F2F` | `#EF5350` | Errors, expired items |
| `semantic-warning` | `#F9A825` | `#FFD54F` | Expiring soon (pantry) |
| `semantic-success` | `#388E3C` | `#66BB6A` | Saved, completed |
| `viral-badge` | `#FF5722` | `#FF7043` | "VIRAL" trending badge |

### 2.3 Contrast Ratios (WCAG AAA Targets)

| Pair | Ratio | WCAG Level |
|------|-------|------------|
| `warm-brown-800` on `cream-50` | 12.4:1 | AAA |
| `warm-brown-700` on `#FFFFFF` | 9.2:1 | AAA |
| `terracotta-400` on `#FFFFFF` | 4.6:1 | AA Large |
| `terracotta-500` on `#FFFFFF` | 5.8:1 | AA |
| `#FFFFFF` on `terracotta-400` | 4.6:1 | AA Large |
| `text-secondary` on `cream-50` | 4.8:1 | AA |

> **Rule:** All body text must achieve 7:1 minimum. Interactive elements must achieve 4.5:1 minimum. Large text (24sp+) must achieve 3:1 minimum.

### 2.4 Dark Mode Strategy

Dark mode uses deep warm browns (`#1C1410` base) rather than pure black — maintaining the warm, kitchen-like ambiance. Card surfaces use `#2A1E16` for subtle elevation without harsh contrast.

---

## 3. Typography

### 3.1 Type Scale (Accessibility-First)

**Minimum body text: 18sp** (exceeds WCAG AAA recommendation). All sizes support Dynamic Type (iOS) and Font Scale (Android) up to 200%.

| Role | Size (sp) | Weight | Line Height | Letter Spacing | Usage |
|------|-----------|--------|-------------|----------------|-------|
| `display-large` | 40 | Bold (700) | 48 | -0.5 | Splash screen title |
| `display-medium` | 34 | Bold (700) | 42 | -0.25 | Section headers (Feed) |
| `headline-large` | 28 | SemiBold (600) | 36 | 0 | Recipe name (card) |
| `headline-medium` | 24 | SemiBold (600) | 32 | 0 | Screen titles |
| `title-large` | 22 | Medium (500) | 28 | 0 | Subsection titles |
| `title-medium` | 20 | Medium (500) | 26 | 0.15 | Card subtitles |
| `body-large` | 18 | Regular (400) | 28 | 0.5 | Primary body text |
| `body-medium` | 16 | Regular (400) | 24 | 0.25 | Secondary body text |
| `label-large` | 16 | SemiBold (600) | 22 | 0.1 | Button labels |
| `label-medium` | 14 | Medium (500) | 20 | 0.5 | Badges, metadata |
| `label-small` | 12 | Medium (500) | 16 | 0.5 | Timestamps only (never primary) |

> **Rule:** `label-small` (12sp) is the absolute minimum and used ONLY for non-critical metadata. No user-facing actionable text may be smaller than 16sp.

### 3.2 Platform Font Mapping

| Platform | Primary Font | Fallback |
|----------|-------------|----------|
| iOS | **SF Pro Rounded** | SF Pro |
| Android | **Google Sans** (if licensed) or **Nunito** | Roboto |

**Why SF Pro Rounded / Nunito?** Rounded terminals feel warmer and friendlier than geometric sans-serifs — aligning with the "kitchen warmth" brand. Both fonts have excellent legibility at large sizes and strong weight variety.

### 3.3 Dynamic Type / Font Scaling

| System Setting | Kindred Response |
|---------------|---------------------|
| Default | Use defined type scale above |
| Large / xLarge | Scale proportionally, reflow layouts |
| xxLarge / xxxLarge | Scale proportionally, hide decorative elements, expand touch targets |
| Accessibility sizes | Full support, single-column layout, maximum contrast |

**Implementation:**
- iOS: Use `@ScaledMetric` property wrapper in SwiftUI, `UIFontMetrics` for custom fonts
- Android: Use `sp` units for all text, test at 200% font scale in Compose previews

---

## 4. Spacing & Layout Grid

### 4.1 Base Unit: 8dp

All spacing derives from an 8dp base grid.

| Token | Value | Usage |
|-------|-------|-------|
| `space-xs` | 4dp | Inline icon-to-text gap |
| `space-sm` | 8dp | Tight element spacing |
| `space-md` | 16dp | Standard padding, component gaps |
| `space-lg` | 24dp | Section spacing |
| `space-xl` | 32dp | Major section dividers |
| `space-2xl` | 48dp | Screen-level padding top/bottom |
| `space-3xl` | 64dp | Hero content spacing |

### 4.2 Layout Grid

| Property | Phone (375-428dp) | Tablet (768dp+) |
|----------|-------------------|-----------------|
| Columns | 4 | 8 |
| Margins | 20dp | 32dp |
| Gutter | 16dp | 24dp |
| Max content width | Full | 600dp (centered) |

### 4.3 Safe Areas

| Area | Minimum |
|------|---------|
| Top (below status bar) | 16dp |
| Bottom (above home indicator) | 34dp (iPhone) / 16dp (Android gesture nav) |
| Horizontal edges | 20dp |

---

## 5. Component Library

### 5.1 Recipe Card (Hero Component)

The recipe card is the atomic unit of Kindred. It must be perfect.

```
┌─────────────────────────────────────┐
│  [VIRAL Badge]           [City Tag] │  ← Overlay on image
│                                     │
│         ┌─────────────────┐         │
│         │                 │         │
│         │   AI-Generated  │         │
│         │   Food Hero     │         │
│         │   Image         │         │
│         │   (16:10 ratio) │         │
│         │                 │         │
│         └─────────────────┘         │
│                                     │
│  Recipe Name (headline-large)       │  ← Max 2 lines
│  "Loved 2.4K this week"            │  ← Social proof (label-medium)
│                                     │
│  ⏱ 25 min  ·  🔥 380 cal          │  ← Metadata row (body-large)
│                                     │
│  ┌─────────┬─────────┬──────────┐  │
│  │ 🎧Listen│ ▶ Watch │ ⏭ Skip  │  │  ← Action bar (56dp tall)
│  └─────────┴─────────┴──────────┘  │
│                                     │
│         ● ○ ○ ○ ○                   │  ← Dot pagination
└─────────────────────────────────────┘
```

**Specifications:**
| Property | Value |
|----------|-------|
| Card width | Full screen width - 40dp (20dp margins) |
| Card corner radius | 24dp |
| Image aspect ratio | 16:10 |
| Card elevation | 4dp shadow (light), 8dp shadow (dark) |
| Card background | `surface-card` |
| Swipe direction | Horizontal (left = skip, right = bookmark) |
| Swipe threshold | 40% of card width |
| Swipe animation | Spring physics, 250ms settle |
| Action button height | 56dp minimum |
| Action button touch target | 56dp x 56dp minimum |

### 5.2 Buttons

#### Primary Button (Terracotta)
| Property | Value |
|----------|-------|
| Height | 56dp |
| Min width | 120dp |
| Corner radius | 28dp (full round) |
| Background | `accent-primary` |
| Text | `text-on-primary`, `label-large` |
| Touch target | 56dp x full width |
| Pressed state | Darken 10%, scale 0.97 |
| Disabled | 40% opacity |

#### Secondary Button (Outlined)
| Property | Value |
|----------|-------|
| Height | 56dp |
| Border | 2dp `accent-primary` |
| Background | Transparent |
| Text | `accent-primary`, `label-large` |

#### Ghost Button (Text Only)
| Property | Value |
|----------|-------|
| Height | 48dp |
| Text | `accent-primary`, `label-large` |
| Underline | On hover/focus |

#### Icon Button
| Property | Value |
|----------|-------|
| Size | 56dp x 56dp |
| Icon size | 24dp |
| Touch target | 56dp x 56dp (never less than 48dp) |
| Background | `surface-card` or transparent |
| Corner radius | 28dp (circle) |

### 5.3 Navigation Bar (Bottom Tab)

**Pattern: Bottom Tab Bar** (Recommended — see Section 9 for rationale)

```
┌─────────────────────────────────────┐
│  🏠 Feed  │ 📷 Scan │ 🍳 Pantry │ 👤 Me  │
│  (active)  │         │           │        │
└─────────────────────────────────────┘
```

| Property | Value |
|----------|-------|
| Height | 64dp (extra tall for elderly) |
| Icon size | 28dp |
| Label | `label-medium` (14sp) — always visible |
| Active indicator | Terracotta pill background (M3 style) |
| Touch target per tab | 25% screen width x 64dp |
| iOS treatment | Liquid Glass material |
| Android treatment | M3 NavigationBar with elevation |

**Tab definitions:**

| Tab | Icon | Label | Destination |
|-----|------|-------|-------------|
| Feed | House | Feed | Hyperlocal viral recipe feed |
| Scan | Camera | Scan | Fridge scanner / Receipt scanner chooser |
| Pantry | Pot | Pantry | Digital pantry (ingredient list) |
| Me | Person | Me | Profile, preferences, voice management, bookmarks |

> **Why 4 tabs?** Fewer tabs = larger touch targets. 4 tabs at ~94dp width each (on 375dp screen) provides generous touch areas. 5+ tabs compress targets below 75dp — problematic for elderly users.

### 5.4 Top Bar / App Bar

```
┌─────────────────────────────────────┐
│ 📍 Istanbul          [🔔]  [🔍]    │
│                                     │
└─────────────────────────────────────┘
```

| Property | Value |
|----------|-------|
| Height | 56dp |
| Location badge | `label-large`, `accent-primary` icon |
| Action icons | 28dp, 56dp touch target |
| iOS | Liquid Glass, large title mode |
| Android | M3 TopAppBar, scroll behavior |

### 5.5 Modal / Bottom Sheet

| Property | Value |
|----------|-------|
| Corner radius (top) | 24dp |
| Handle bar | 40dp x 4dp, centered, `text-secondary` |
| Max height | 85% screen height |
| Scrim | `#000000` at 40% opacity |
| Content padding | 24dp horizontal, 16dp vertical |
| Close button | Explicit "X" button (don't rely solely on swipe-to-dismiss for elderly) |

### 5.6 Voice Player (Inline)

The voice narration player for "Mom's voice reading recipes."

```
┌─────────────────────────────────────┐
│  👩‍🍳 Mom · Step 3 of 8             │
│                                     │
│  ═══════════●─────────  2:34/5:10  │  ← Progress bar
│                                     │
│  ┌────┐  ┌────────┐  ┌────┐       │
│  │ ⏮ │  │ ⏸ Pause│  │ ⏭ │       │
│  └────┘  └────────┘  └────┘       │
│                                     │
│  🔊 ──────●──────  Speed: 0.75x   │  ← Volume + speed
└─────────────────────────────────────┘
```

| Property | Value |
|----------|-------|
| Height | ~180dp |
| Play/Pause button | 64dp x 64dp (extra large — primary action) |
| Skip buttons | 56dp x 56dp |
| Progress bar height | 8dp (thick for easy touch seeking) |
| Speed control | 0.5x, 0.75x, 1.0x, 1.25x presets |
| Volume slider | Always visible (never hidden in menu) |

**Emotional design note:** The voice player should feel like a cozy conversation — warm background tint, speaker's name prominently displayed, gentle waveform animation while playing.

### 5.7 Badges

| Badge Type | Background | Text | Size |
|------------|-----------|------|------|
| VIRAL | `viral-badge` | White, `label-medium`, bold | Auto-width, 28dp height |
| NEW | `accent-primary` | White | Auto-width, 28dp height |
| Expiring Soon | `semantic-warning` | `warm-brown-800` | Auto-width, 28dp height |
| Expired | `semantic-error` | White | Auto-width, 28dp height |

---

## 6. Icon System

### Style: Rounded, Filled (Active) + Outlined (Inactive)

| Property | Value |
|----------|-------|
| Style | Rounded terminals, 2dp stroke |
| Sizes | 20dp (tight), 24dp (standard), 28dp (navigation), 32dp (feature) |
| Touch target | Always 48dp minimum, 56dp preferred |
| Active state | Filled variant |
| Inactive state | Outlined variant |

### Platform Mapping

| Platform | Icon Source | Rationale |
|----------|------------|-----------|
| iOS | SF Symbols (rounded weight) | Native, Dynamic Type scaling, 6000+ icons |
| Android | Material Symbols (rounded, filled) | M3 native, optical size variants |

### Custom Icons Needed

| Icon | Description | Context |
|------|-------------|---------|
| Fridge Scanner | Fridge outline with scan lines | Scan tab |
| Receipt Scanner | Receipt with scan lines | Scan tab |
| Voice Waveform | Audio waveform (warm style) | Voice player |
| Pantry | Cooking pot or jar | Tab bar |
| Mom's Voice | Warm headphones/heart combo | Voice feature |
| Taste Profile | Flavor wheel | Preferences |
| Fresh Indicator | Leaf / green dot | Pantry items |

---

## 7. Motion & Animation Principles

### 7.1 Core Motion Values

| Property | Value | Rationale |
|----------|-------|-----------|
| Default duration | 250-300ms | Perceptible but not slow |
| Ease curve | Ease-in-out (cubic-bezier 0.4, 0, 0.2, 1) | Natural, warm feel |
| Spring (interactive) | Damping 0.7, stiffness 300 | Responsive swipe-and-settle |
| Entrance | Fade + slide up (16dp) | Content "rising" like warmth |
| Exit | Fade + slide down (8dp) | Gentle departure |
| Swipe dismiss | Spring physics to edge | Card "flies" off naturally |

### 7.2 Animation Rules

1. **Every animation must serve a purpose** — guide attention, confirm action, or show state change
2. **Respect `reduceMotion`** — if enabled, replace all animations with instant cuts (opacity 0→1)
3. **Never auto-play video** — always require explicit tap (critical for elderly users on metered data)
4. **Voice waveform** — gentle, low-frequency pulse; not fast/jarring
5. **Loading states** — use skeleton screens (warm cream shimmer), never spinners
6. **Max 3 simultaneous animations** per screen for performance

### 7.3 Skeleton Loading

Instead of spinners, Kindred uses warm-toned skeleton placeholders:

| Element | Skeleton |
|---------|----------|
| Recipe card | Cream rectangle (image) + 2 warm lines (text) |
| Pantry item | Circle (icon) + 2 lines |
| Profile | Large circle + 3 lines |

Skeleton shimmer: Left-to-right gradient sweep, `cream-100` → `cream-200` → `cream-100`, 1.5s loop.

---

## 8. Screen-by-Screen UX Flows

### 8.1 Onboarding (First Launch)

**Flow:** Welcome → Voice Upload → Location → Dietary Preferences → Ready

**Screen 1: Welcome**
- Warm hero illustration (Lottie): kitchen scene with floating food elements
- Headline: "Cooking Feels Better Together"
- Body: "Kindred brings your family's recipes to life — with the voices you love."
- Primary CTA: "Let's Get Started" (56dp button)
- Skip option: subtle text link at bottom

**Screen 2: Voice Upload**
- Headline: "Add a Loved One's Voice"
- Body: "Record or upload a voice memo. We'll bring it into your kitchen."
- Large microphone button (80dp circle, terracotta)
- "Upload existing recording" secondary option
- Voice waveform visualization during recording
- Skip option available (can add later)
- Emotional warmth: soft background illustration of family cooking

**Screen 3: Location Permission**
- Headline: "What's Cooking Near You?"
- Map illustration showing local food markers
- Body: "We'll show you what's trending in your neighborhood."
- "Allow Location" primary CTA
- "Enter Manually" secondary option
- Privacy note: "We never share your exact location"

**Screen 4: Dietary Preferences**
- Headline: "Tell Us Your Taste"
- Large, tappable chips (56dp height): Vegetarian, Vegan, Gluten-Free, Dairy-Free, Halal, Kosher, Low Sodium, Nut-Free
- Multi-select allowed
- "Any allergies?" text input field
- "Skip for Now" option

**Screen 5: Ready**
- Celebration Lottie animation (confetti)
- Headline: "Your Kitchen Awaits"
- Primary CTA: "See What's Cooking" → navigates to Feed

### 8.2 Hyperlocal Viral Recipe Feed (Main Screen)

**The primary screen. Users spend most time here.**

```
┌─────────────────────────────────────┐
│ 📍 Istanbul             🔔   🔍    │  ← Top bar
│─────────────────────────────────────│
│                                     │
│  ┌─────────────────────────────┐   │
│  │     [VIRAL]                 │   │
│  │                             │   │
│  │     AI Food Hero Image      │   │
│  │     (cinematic quality)     │   │
│  │                             │   │
│  │  Recipe Name                │   │
│  │  ❤️ 2.4K loves · ⏱ 25min   │   │
│  │  🔥 380 cal                 │   │
│  │                             │   │
│  │  🎧Listen  ▶ Watch  ⏭ Skip │   │
│  │                             │   │
│  │         ● ○ ○ ○ ○          │   │
│  └─────────────────────────────┘   │
│                                     │
│  ─── Trending in Istanbul ────────  │  ← Optional section below
│                                     │
├─────────────────────────────────────┤
│ 🏠Feed  📷Scan  🍳Pantry  👤Me   │  ← Bottom tab bar
└─────────────────────────────────────┘
```

**Interactions:**
| Gesture | Action | Feedback |
|---------|--------|----------|
| Swipe left | Skip recipe | Card slides out left, next card springs in from right |
| Swipe right | Bookmark recipe | Heart animation + haptic, card settles back |
| Tap card | Open recipe detail | Shared element transition (image expands) |
| Tap "Listen" | Start voice narration | Voice player slides up from bottom |
| Tap "Watch" | Open video player | Full-screen video with large controls |
| Tap "Skip" | Same as swipe left | Card animates out |
| Pull down | Refresh feed | Warm loading shimmer |

**Feed algorithm signals:** Location, dietary preferences, trending velocity (loves/time), ingredient overlap with pantry, seasonal relevance.

### 8.3 Recipe Detail

**Accessed by tapping a recipe card. Shared element transition for hero image.**

```
┌─────────────────────────────────────┐
│ ← Back              ♡ Save  ⋮ More │
│─────────────────────────────────────│
│                                     │
│  ┌─────────────────────────────┐   │
│  │     Full-width Hero Image   │   │
│  │     (parallax on scroll)    │   │
│  └─────────────────────────────┘   │
│                                     │
│  Recipe Name (display-medium)       │
│  by Chef Maria · Istanbul           │
│  ❤️ 2.4K · ⏱ 25min · 🔥 380 cal   │
│                                     │
│  ┌──────────┬──────────┐           │
│  │🎧 Listen │ ▶ Watch  │           │  ← Primary actions
│  └──────────┴──────────┘           │
│                                     │
│  ── Ingredients (8) ──────────     │
│  ☑ 2 cups flour         [In pantry]│
│  ☐ 3 eggs               [Need]     │
│  ☑ 1 cup sugar          [In pantry]│
│  ... Show all                       │
│                                     │
│  ── Steps ────────────────────     │
│  Step 1 of 6                        │
│  "Preheat oven to 180°C..."       │
│  [Large step text, body-large]      │
│                                     │
│  ┌────┐  ┌──────┐  ┌────┐         │
│  │ ← │  │ ⏸   │  │ → │         │  ← Step nav
│  │Prev│  │Pause │  │Next│         │
│  └────┘  └──────┘  └────┘         │
│                                     │
└─────────────────────────────────────┘
```

**Key UX decisions:**
- **Ingredient pantry match:** Green check = you have it, red = you need it. Instant shopping list generation.
- **Step-by-step mode:** Large text, one step at a time. Voice narration syncs with current step.
- **Step navigation buttons:** 56dp, clearly labeled (not just arrows).
- **No horizontal scrolling** — all content flows vertically.

### 8.4 Fridge Scanner

```
┌─────────────────────────────────────┐
│ ← Back        Fridge Scanner        │
│─────────────────────────────────────│
│                                     │
│  ┌─────────────────────────────┐   │
│  │                             │   │
│  │     Camera Viewfinder       │   │
│  │     (full width)            │   │
│  │                             │   │
│  │   [ Scanning frame overlay ]│   │
│  │                             │   │
│  └─────────────────────────────┘   │
│                                     │
│  "Point camera at your fridge"     │  ← Instruction text (body-large)
│  "We'll identify ingredients"      │
│                                     │
│  ── Found So Far ──────────────    │
│  🥕 Carrots  🥚 Eggs  🧀 Cheese  │  ← Live-detected items (chips)
│                                     │
│  ┌─────────────────────────────┐   │
│  │    📸 Capture & Analyze     │   │  ← 64dp primary button
│  └─────────────────────────────┘   │
│                                     │
│  💡 Tip: Good lighting helps!      │
│                                     │
└─────────────────────────────────────┘
```

**UX considerations:**
- Camera permission requested with clear explanation before opening
- Large capture button (64dp) — easy target for shaky hands
- Real-time ingredient detection shown as growing chip list
- "Tip" text helps users optimize scanning conditions
- Haptic feedback on each detected ingredient
- Manual "Add ingredient" fallback for items camera misses

### 8.5 Receipt Scanner

```
┌─────────────────────────────────────┐
│ ← Back        Receipt Scanner       │
│─────────────────────────────────────│
│                                     │
│  ┌─────────────────────────────┐   │
│  │                             │   │
│  │     Camera Viewfinder       │   │
│  │     (receipt alignment      │   │
│  │      guide overlay)         │   │
│  │                             │   │
│  └─────────────────────────────┘   │
│                                     │
│  "Lay receipt flat and capture"    │
│                                     │
│  ┌─────────────────────────────┐   │
│  │    📸 Scan Receipt          │   │  ← 64dp primary button
│  └─────────────────────────────┘   │
│                                     │
│  📂 Choose from photos             │  ← Gallery option
│                                     │
└─────────────────────────────────────┘
```

**After capture:**
- Show parsed items list with editable quantities
- "Add to Pantry" bulk action
- Option to set purchase date (auto-filled) and estimated expiry

### 8.6 Digital Pantry

```
┌─────────────────────────────────────┐
│ My Pantry            + Add  🔍     │
│─────────────────────────────────────│
│                                     │
│  ── Expiring Soon (3) ──────────   │  ← Warning section first
│  ┌─────────────────────────────┐   │
│  │ 🥛 Milk     Exp: Tomorrow  ⚠│   │  ← Warning badge
│  │ 🍅 Tomatoes Exp: 2 days    ⚠│   │
│  │ 🧀 Cheese   Exp: 3 days    ⚠│   │
│  └─────────────────────────────┘   │
│                                     │
│  "3 recipes use these →"           │  ← Actionable suggestion
│                                     │
│  ── All Items (24) ────────────    │
│  ┌─────────────────────────────┐   │
│  │ 🥕 Carrots    Fresh  5 days│   │
│  │ 🥚 Eggs (6)   Fresh  7 days│   │
│  │ 🍚 Rice       Good   30days│   │
│  │ ...                         │   │
│  └─────────────────────────────┘   │
│                                     │
│  ── Shopping Suggestions ────────  │
│  "You're low on: Eggs, Butter"     │
│                                     │
├─────────────────────────────────────┤
│ 🏠Feed  📷Scan  🍳Pantry  👤Me   │
└─────────────────────────────────────┘
```

**Key features:**
- **Expiring soon** always at top — drives urgency and reduces food waste
- "Recipes using these" link converts waste-risk into cooking motivation
- Color-coded freshness: Green (fresh), Yellow (use soon), Red (expired)
- Swipe-to-delete individual items
- Manual add with autocomplete ingredient search
- Sort by: Expiry date (default), Category, Recently added

### 8.7 Preferences & Taste Profile

```
┌─────────────────────────────────────┐
│ ← Back         My Taste Profile     │
│─────────────────────────────────────│
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 👤  Username                │   │
│  │     Istanbul, Turkey        │   │
│  │     Member since 2026       │   │
│  └─────────────────────────────┘   │
│                                     │
│  ── Dietary Preferences ────────   │
│  [Vegetarian] [Gluten-Free]        │  ← Tappable chips
│  + Add preference                   │
│                                     │
│  ── Allergies ──────────────────   │
│  [Nuts] [Shellfish]                │
│  + Add allergy                      │
│                                     │
│  ── Cuisine Preferences ────────   │
│  ❤️ Turkish ████████ 85%           │
│  ❤️ Italian ██████── 60%           │
│  ❤️ Mexican █████─── 50%           │
│  (learned from your activity)       │
│                                     │
│  ── Cooking Skill Level ────────   │
│  [Beginner] [Home Cook✓] [Chef]   │
│                                     │
│  ── Linked Accounts ────────────   │
│  🛒 Migros Loyalty  ✓ Connected   │
│                                     │
└─────────────────────────────────────┘
```

### 8.8 Voice Management

```
┌─────────────────────────────────────┐
│ ← Back          My Voices           │
│─────────────────────────────────────│
│                                     │
│  "Hear your loved ones read         │
│   your recipes"                     │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 👩‍🍳 Mom                     │   │
│  │ "Added Jan 15, 2026"       │   │
│  │ ▶ Preview  ✏ Edit  🗑 Del  │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 👨‍🍳 Grandma Ayşe            │   │
│  │ "Added Feb 1, 2026"        │   │
│  │ ▶ Preview  ✏ Edit  🗑 Del  │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │     + Add a New Voice       │   │  ← 56dp button
│  │     (Record or Upload)      │   │
│  └─────────────────────────────┘   │
│                                     │
│  ── How It Works ───────────────   │
│  1. Record 30 seconds of speech    │
│  2. Our AI learns the voice        │
│  3. Hear recipes in their voice    │
│                                     │
│  🔒 Voice data is private and      │
│     never shared with third parties│
│                                     │
└─────────────────────────────────────┘
```

**Emotional design:**
- Warm, personal language ("your loved ones")
- Privacy reassurance prominently displayed
- Preview button is large and primary — users want to hear the voice
- Delete has confirmation dialog ("Are you sure? This cannot be undone.")
- Each voice card has a warm avatar/icon

### 8.9 Bookmarks / Saved Recipes

```
┌─────────────────────────────────────┐
│ Saved Recipes          🔍 Search   │
│─────────────────────────────────────│
│                                     │
│  ── Collections ────────────────   │
│  [All (12)] [Weeknight] [Desserts] │
│  + New Collection                   │
│                                     │
│  ┌──────────┐ ┌──────────┐        │
│  │ 📷       │ │ 📷       │        │  ← 2-column grid
│  │ Recipe A │ │ Recipe B │        │
│  │ ⏱15min   │ │ ⏱30min   │        │
│  └──────────┘ └──────────┘        │
│  ┌──────────┐ ┌──────────┐        │
│  │ 📷       │ │ 📷       │        │
│  │ Recipe C │ │ Recipe D │        │
│  │ ⏱20min   │ │ ⏱45min   │        │
│  └──────────┘ └──────────┘        │
│                                     │
└─────────────────────────────────────┘
```

---

## 9. Navigation Pattern: Bottom Tab Bar (Recommendation)

### Evaluated Options

| Pattern | Pros | Cons | Elderly Suitability |
|---------|------|------|---------------------|
| **Bottom Tab Bar** | Thumb-reachable, always visible, familiar | Limited to 4-5 tabs | Excellent |
| Hamburger Menu (Drawer) | Unlimited items | Hidden navigation, extra tap | Poor |
| Top Tab Bar | Visible, swipeable | Thumb-unreachable on large phones | Moderate |
| Hub & Spoke | Simple per-screen | Back navigation confusion | Moderate |

### Decision: Bottom Tab Bar

**Rationale:**
1. **Thumb reachability:** Bottom of screen is the easiest zone for one-handed use
2. **Always visible:** No hidden navigation = no memory burden for elderly users
3. **Familiar pattern:** Both iOS and Android users understand tab bars
4. **Platform native:** Tab bars are THE standard on both iOS (UITabBar) and Android (M3 NavigationBar)
5. **4 tabs = large targets:** Each tab gets ~94dp width — excellent for 75+ users
6. **iOS 26 Liquid Glass:** Tab bar automatically gets the new Liquid Glass treatment for free

**Navigation hierarchy:**
```
Bottom Tab Bar
├── Feed (home)
│   ├── Recipe Detail
│   │   ├── Voice Player (inline)
│   │   └── Video Player (full-screen)
│   └── Search / Filter
├── Scan
│   ├── Fridge Scanner
│   └── Receipt Scanner
├── Pantry
│   ├── Add Item (manual)
│   └── Expiring → Recipe Suggestions
└── Me
    ├── Taste Profile / Preferences
    ├── Voice Management
    ├── Bookmarks / Saved Recipes
    ├── Settings
    └── Help / Tutorial
```

---

## 10. Accessibility Checklist & Standards

### 10.1 Visual Accessibility

| Requirement | Standard | Kindred Target |
|-------------|----------|-------------------|
| Body text contrast | WCAG AA: 4.5:1 | 7:1 (AAA) |
| Large text contrast | WCAG AA: 3:1 | 4.5:1 (AA) |
| Interactive element contrast | WCAG AA: 3:1 | 4.5:1 |
| Min body text size | None specified | 18sp |
| Min interactive text | None specified | 16sp |
| Dynamic Type support | Platform best practice | Full (up to 200%) |
| Color not sole indicator | WCAG 1.4.1 | Icons + text + color |
| Focus indicators | WCAG 2.4.7 | 3dp terracotta ring |

### 10.2 Motor Accessibility

| Requirement | Standard | Kindred Target |
|-------------|----------|-------------------|
| Touch target minimum | WCAG AAA: 44x44px | 56x56dp |
| Touch target spacing | WCAG 2.5.8: 24px | 8dp minimum gap |
| Gesture alternatives | WCAG 2.5.1 | All gestures have button alternatives |
| No time-dependent actions | WCAG 2.2.1 | No timed interactions |
| Single-pointer operation | WCAG 2.5.1 | No multi-touch required |

### 10.3 Cognitive Accessibility

| Requirement | Target |
|-------------|--------|
| Max actions per screen | 3 primary actions |
| Navigation depth | Max 3 levels from any tab |
| Consistent layout | Same header/footer on all screens |
| Clear labeling | No icon-only buttons (always label) |
| Error prevention | Confirmation dialogs for destructive actions |
| Undo support | Undo snackbar for bookmark/delete (5 seconds) |
| Plain language | Reading level: Grade 6 or below |

### 10.4 Assistive Technology

| Feature | iOS | Android |
|---------|-----|---------|
| Screen reader | VoiceOver full support | TalkBack full support |
| Element labels | `accessibilityLabel` on all | `contentDescription` on all |
| Element roles | `accessibilityAddTraits` | `semantics { role }` |
| Headings | `accessibilityAddTraits(.isHeader)` | `semantics { heading() }` |
| Live regions | `accessibilityValue` updates | `liveRegion` for counters |
| Reduce Motion | Respect `UIAccessibility.isReduceMotionEnabled` | Respect `ANIMATOR_DURATION_SCALE` |
| Bold Text | Respect `UIAccessibility.isBoldTextEnabled` | Respect system bold |
| Custom actions | `accessibilityCustomAction` for swipe | `customActions` in semantics |

---

## 11. Platform-Specific Adaptations

### 11.1 iOS-Specific

| Element | iOS Treatment |
|---------|--------------|
| Navigation bar | Liquid Glass + large titles |
| Tab bar | Liquid Glass material |
| Typography | SF Pro Rounded |
| Back navigation | Swipe from left edge (system default) |
| Haptics | `UIImpactFeedbackGenerator` — light for scroll, medium for actions |
| Dynamic Type | Full `@ScaledMetric` support |
| Safe areas | Respect Dynamic Island + home indicator |
| Widget | Recipe of the day widget (Liquid Glass style) |
| Live Activities | Cooking timer on Lock Screen |

### 11.2 Android-Specific

| Element | Android Treatment |
|---------|------------------|
| Navigation bar | M3 NavigationBar with indicator pill |
| Top bar | M3 TopAppBar, collapse on scroll |
| Typography | Google Sans or Nunito |
| Back navigation | Predictive back gesture (Android 14+) |
| Haptics | `HapticFeedbackType.LongPress`, `TextHandleMove` |
| Font scaling | Full `sp` unit support, test at 200% |
| Edge-to-edge | Full edge-to-edge with inset handling |
| Dynamic Color | Disabled — use Kindred's own warm palette |
| Widget | Glance widget with recipe suggestion |
| Notifications | M3 notification style, grouped by type |

### 11.3 Cross-Platform Parity

| Feature | Must Match | May Differ |
|---------|------------|------------|
| Color palette | Yes | — |
| Typography scale | Yes (ratios) | Font family |
| Touch targets | Yes | — |
| Screen flows | Yes | — |
| Navigation structure | Yes | — |
| Tab bar | — | Material vs Liquid Glass |
| Transitions | — | Platform-native animations |
| System integration | — | Widgets, Live Activities |
| Haptics | — | Platform-native patterns |

---

## 12. Design Token Export Format

All design decisions should be exported as platform-agnostic JSON tokens for engineering consumption:

```json
{
  "color": {
    "surface": {
      "primary": { "light": "#FFF9F0", "dark": "#1C1410" },
      "card": { "light": "#FFFFFF", "dark": "#2A1E16" }
    },
    "accent": {
      "primary": { "light": "#E07849", "dark": "#A84E2D" }
    },
    "text": {
      "primary": { "light": "#3E2712", "dark": "#F5E6D3" }
    }
  },
  "typography": {
    "body-large": { "size": 18, "weight": 400, "lineHeight": 28 },
    "headline-large": { "size": 28, "weight": 600, "lineHeight": 36 }
  },
  "spacing": {
    "sm": 8, "md": 16, "lg": 24, "xl": 32
  },
  "radius": {
    "card": 24, "button": 28, "badge": 14
  },
  "target": {
    "minimum": 48, "preferred": 56, "large": 64
  }
}
```

---

## 13. Key Design Decisions Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Navigation | Bottom Tab Bar (4 tabs) | Thumb reach, large targets, elderly-friendly, platform-native |
| Typography minimum | 18sp body | WCAG AAA, elderly readability |
| Touch targets | 56dp standard | Exceeds WCAG AAA 44px, comfortable for elderly |
| Color temperature | Warm (cream + terracotta) | Food-appropriate, inviting, brand identity |
| Dark mode base | Warm dark (#1C1410) | Maintains warmth, not cold pure-black |
| Card interaction | Swipe left/right + button fallbacks | TikTok simplicity + accessibility alternative |
| Voice player | Inline, always-visible controls | Elderly users need persistent, large controls |
| Loading pattern | Skeleton screens | Less anxiety than spinners for elderly |
| Icons | Always labeled | No icon-only interaction (cognitive accessibility) |
| Font | SF Pro Rounded (iOS) / Nunito (Android) | Warm, friendly, excellent legibility |
| Tab count | 4 | Large targets, simple mental model |
| Max navigation depth | 3 | Prevents "lost" feeling for elderly users |
| Error pattern | Inline + undo snackbar | Forgiving, never punishing |

---

*Design system compiled: February 2026*
*Designed for Kindred v1.0 — accessibility-first, premium, warm*
