# Kindred — UX Frameworks & Tools Research (2026)

> **Purpose:** Recommend the best design tools, frameworks, patterns, and accessibility standards for Kindred's dual-platform (iOS + Android) mobile app targeting users aged 75+.

---

## 1. Design Tools

### Primary: Figma (v2026)

**Why Figma remains the standard:**
- **Variables & Design Tokens (2025/2026):** Figma's variable system now supports expression tokens with conditional logic, math, and context-driven computation — enabling dynamic themes that adapt based on device, user preference, region, and accessibility needs. This is critical for Kindred's elderly-accessible mode.
- **Multi-platform component libraries:** Single source of truth for iOS and Android variants using component properties and variable modes.
- **Dev Mode:** Generates platform-specific specs (SwiftUI + Jetpack Compose snippets) directly from design files.
- **Official Apple iOS 26 UI Kit:** Apple releases official Figma kits post-WWDC, including the new Liquid Glass components.
- **Real-time collaboration:** Essential for a multi-disciplinary team (product, dev, UX).

**Recommended Figma setup:**
- Use Figma Variables for all color, spacing, and typography tokens
- Create two variable modes: `iOS` and `Android` for platform-specific values
- Create an accessibility variable mode: `Standard` and `High Accessibility` (larger text, higher contrast)
- Organize components by atomic design: Atoms → Molecules → Organisms → Templates → Pages

### Secondary Tools

| Tool | Purpose | Rationale |
|------|---------|-----------|
| **Figma + FigJam** | Design + whiteboarding | Unified ecosystem, shared libraries |
| **Stark (Figma plugin)** | Accessibility auditing | Real-time contrast checking, WCAG compliance scoring |
| **Able (Figma plugin)** | Color contrast checker | Fast AA/AAA contrast ratio validation |
| **LottieFiles** | Animation asset management | Cross-platform animation library, Figma integration |
| **Maze** | Unmoderated usability testing | Remote testing with elderly users, heatmaps, task analytics |
| **Useberry** | Prototype testing | Card sorting, tree testing for navigation validation |

---

## 2. Design System Approach: Cross-Platform Harmony

### Philosophy: "Native Feel, Shared Soul"

Kindred should feel native on each platform while sharing a unified brand identity. This means:

- **Shared:** Color palette, typography scale ratios, iconography style, brand voice, spacing grid, content hierarchy
- **Platform-specific:** Navigation patterns, system controls, animations, gestures, status bar treatment

### iOS: Apple Human Interface Guidelines (HIG) + Liquid Glass

**iOS 26 Liquid Glass** is Apple's most significant design evolution since iOS 7:
- Translucent, dynamic material system mimicking real glass
- Real-time light bending, specular highlights, adaptive shadows
- Applies to **navigation layer only** (tab bars, nav bars, toolbars) — never to content
- Kindred should adopt Liquid Glass for navigation chrome while keeping recipe content cards warm and opaque

**Key HIG principles for Kindred:**
- Clarity: Content is the star — recipe imagery must dominate
- Deference: UI defers to food photography
- Depth: Subtle layering via Liquid Glass navigation + card shadows

**SwiftUI Liquid Glass APIs:**
- `.glassEffect()` modifier for navigation elements
- Updated `TabView` and `NavigationStack` with automatic Liquid Glass adoption
- Custom glass materials available via `GlassBackgroundEffect`

### Android: Material Design 3 (Material You)

**Key M3 features for Kindred:**
- **Dynamic Color:** Material You generates color schemes from user wallpaper — Kindred should override with its own warm palette while respecting tonal relationships
- **Large touch targets:** M3 defaults align with accessibility needs (48dp minimum)
- **Typography:** M3 type scale with `Display`, `Headline`, `Title`, `Body`, `Label` roles maps cleanly to Kindred's hierarchy
- **Shape system:** Rounded corners (recipe cards) and full-round (action buttons)

### Cross-Platform Mapping

| Concept | iOS (HIG) | Android (M3) |
|---------|-----------|---------------|
| Navigation | Tab Bar (bottom, Liquid Glass) | Bottom Navigation Bar (M3) |
| Cards | Custom card with `.shadow()` | `ElevatedCard` / `OutlinedCard` |
| Primary action | SF Symbols + system tint | `FloatingActionButton` / `FilledButton` |
| Typography | SF Pro (system) | Roboto / custom via M3 type scale |
| Haptics | `UIImpactFeedbackGenerator` | `HapticFeedbackType` in Compose |
| Swipe gesture | `DragGesture` in SwiftUI | `SwipeToDismiss` in Compose |

---

## 3. Animation & Motion Design

### Primary: Lottie (Cross-Platform)

**Why Lottie:**
- Single animation file (JSON) works on both iOS (via `lottie-ios`) and Android (via `lottie-compose`)
- Designed in After Effects / LottieFiles → exported once → runs everywhere
- Small file sizes (JSON vs video)
- Programmatic control: play, pause, seek, loop segments

**Kindred animation use cases:**
| Animation | Type | Duration |
|-----------|------|----------|
| Recipe card entrance | Slide + fade in | 300ms |
| Heart/bookmark | Lottie burst | 600ms |
| Voice waveform | Lottie loop | Continuous |
| Loading/cooking timer | Lottie loop | Continuous |
| Onboarding illustrations | Lottie sequence | 2-3s per step |
| Success states (recipe saved) | Lottie confetti | 1s |
| Card swipe dismiss | Spring physics | 250ms |

**Platform-specific animation libraries:**

| Platform | Library | Use Case |
|----------|---------|----------|
| iOS | SwiftUI `.animation()` / `.matchedGeometryEffect()` | Native transitions, shared element |
| iOS | Lottie-ios (v4.x) | Complex branded animations |
| Android | Jetpack Compose `animateAsState` / `AnimatedVisibility` | Native transitions |
| Android | Lottie-compose | Complex branded animations |
| Android | Compottie (KMP alternative) | If targeting Compose Multiplatform |

**Performance guidelines:**
- Keep Lottie files under 30KB for micro-animations
- Cache compositions — never re-parse on every render
- Limit simultaneous animations to 2-3 per screen
- Use `reduceMotion` system setting to disable non-essential animations (critical for accessibility)
- Prefer native platform animations for simple transitions (fade, slide, scale)

### Motion Principles for Kindred

1. **Warmth:** Ease-in-out curves (never linear), slight bounce on interactive elements
2. **Clarity:** Motion guides attention, never distracts — no gratuitous parallax
3. **Performance:** 60fps minimum, reduce motion respected system-wide
4. **Accessibility:** All animations must have a static fallback when `reduceMotion` is enabled

---

## 4. Accessibility Testing Tools & Standards

### Standards Compliance Target

| Standard | Level | Requirement |
|----------|-------|-------------|
| **WCAG 2.2** | AA (minimum) | All screens must pass |
| **WCAG 2.2** | AAA (target) | Typography, contrast, touch targets |
| **iOS Accessibility** | Full support | VoiceOver, Dynamic Type, Reduce Motion |
| **Android Accessibility** | Full support | TalkBack, Font Scale, Reduce Animations |

### Specific Criteria for 75+ Users

| Criterion | WCAG Reference | Kindred Target |
|-----------|---------------|-------------------|
| Text contrast | 1.4.6 (AAA) | 7:1 minimum for body text |
| Touch targets | 2.5.5 (AAA) | 56dp minimum (exceeding 44dp AAA) |
| Text resizing | 1.4.4 (AA) | Support up to 200% without loss |
| Font size | Best practice | 18sp minimum body text |
| Focus indicators | 2.4.7 (AA) | Visible, high-contrast focus rings |
| Motion | 2.3.3 (AAA) | Respect `reduceMotion` setting |
| Cognitive load | 3.3.x (AA/AAA) | Max 3 actions per screen |

### Testing Tools

**Automated (Continuous Integration):**

| Tool | Platform | What It Tests |
|------|----------|---------------|
| **Accessibility Scanner** | Android | UI element labels, touch targets, contrast |
| **Accessibility Inspector** | iOS | VoiceOver readability, element labels, contrast |
| **Axe DevTools Mobile** | Both | WCAG compliance, real mobile issues only |
| **Stark** | Figma (design-time) | Contrast, vision simulation, WCAG scoring |

**Manual Testing Protocol:**

| Test | Tool | Frequency |
|------|------|-----------|
| VoiceOver walkthrough | iOS device | Every sprint |
| TalkBack walkthrough | Android device | Every sprint |
| Dynamic Type (max size) | iOS Settings | Every sprint |
| Font Scale (200%) | Android Settings | Every sprint |
| Reduce Motion enabled | Both platforms | Every sprint |
| High Contrast mode | Both platforms | Every sprint |
| One-handed operation test | Physical device | Major features |
| Color blindness simulation | Stark / Color Oracle | Design review |

**User Testing with Elderly Participants:**

| Method | Tool | When |
|--------|------|------|
| Moderated usability testing | Zoom + device camera | Monthly |
| Unmoderated task testing | Maze / Useberry | Bi-weekly |
| Think-aloud protocol | In-person sessions | Quarterly |
| A/B testing (font sizes, layouts) | Firebase A/B Testing | Feature launches |
| Participatory design sessions | FigJam workshops | Design phase |

---

## 5. Prototyping Tools for Elderly User Testing

### Recommended Stack

| Stage | Tool | Why |
|-------|------|-----|
| **Low-fidelity** | FigJam / Paper sketches | Fast iteration, non-intimidating for elderly test participants |
| **Mid-fidelity** | Figma prototypes (interactive) | Clickable flows, real device testing via Figma Mirror |
| **High-fidelity** | Figma + Lottie previews | Near-production feel with animations |
| **Production prototype** | SwiftUI Previews / Compose Previews | Real platform behavior, real accessibility features |
| **Usability testing** | Maze | Task-based analytics, heatmaps, completion rates |

### Prototyping Guidelines for Elderly Testing

1. **Always test on real devices** — elderly users struggle with desktop prototype simulations
2. **Use Figma Mirror** app for testing prototypes on actual phones/tablets
3. **Print key screens** for paper-based preference testing (eliminates tech barrier)
4. **Keep test sessions to 20-30 minutes** — cognitive fatigue is real for 75+ users
5. **Use familiar language** in test scripts — avoid jargon like "swipe" (say "slide your finger")
6. **Test in well-lit environments** — screen glare affects elderly users more
7. **Provide physical assistance** for device handling without guiding answers

---

## 6. Recommended Design Workflow

```
1. Research & Discovery
   └─ User interviews (elderly + general) → FigJam affinity maps

2. Information Architecture
   └─ FigJam → Card sorting (Useberry) → Sitemap

3. Wireframes
   └─ Figma (low-fi components) → Accessibility review (Stark)

4. Visual Design
   └─ Figma (high-fi) → Variable-driven theming → Contrast audit

5. Prototyping
   └─ Figma Interactive → Lottie animation previews

6. User Testing
   └─ Maze (unmoderated) + In-person elderly sessions

7. Design-to-Dev Handoff
   └─ Figma Dev Mode → Design tokens (JSON) → SwiftUI/Compose

8. Implementation Review
   └─ Accessibility Scanner + VoiceOver/TalkBack audit
```

---

## 7. Key Recommendations Summary

| Decision | Recommendation | Rationale |
|----------|---------------|-----------|
| Design tool | Figma (variables + dev mode) | Industry standard, cross-platform token support, Apple kit |
| Design system approach | Shared tokens + platform-native components | Native feel on each platform, single brand |
| iOS design language | HIG + Liquid Glass (nav only) | Modern, official, automatic system adoption |
| Android design language | Material Design 3 | Native feel, Dynamic Color, M3 type scale |
| Animation library | Lottie (cross-platform) + native transitions | One animation asset, two platforms |
| Accessibility standard | WCAG 2.2 AAA (target) | Non-negotiable for 75+ user demographic |
| Accessibility testing | Axe DevTools + VoiceOver/TalkBack manual | Automated + manual = comprehensive |
| Prototyping | Figma → Maze for testing | Real-device testing, analytics for elderly sessions |
| User testing | Participatory design with elderly users | Proven to increase satisfaction in 75+ demographic |

---

*Research compiled: February 2026*
*Sources: WCAG 2.2, Apple HIG (iOS 26), Material Design 3, Figma 2026, LottieFiles, PMC research on elderly mobile UX*
