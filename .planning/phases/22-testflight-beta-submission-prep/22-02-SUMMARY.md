---
phase: 22-testflight-beta-submission-prep
plan: 02
subsystem: app-store-assets
tags: [screenshots, app-icon, fastlane, marketing]
dependency_graph:
  requires: [22-01-fastlane-setup]
  provides: [screenshot-infrastructure, screenshot-guide, app-icon-brief]
  affects: [fastlane-deliver, app-store-submission]
tech_stack:
  added: []
  patterns: [fastlane-screenshots, manual-screenshot-workflow]
key_files:
  created:
    - Kindred/fastlane/screenshots/en-US/.gitkeep
    - Kindred/fastlane/screenshots/tr/.gitkeep
    - Kindred/docs/screenshot-guide.md
    - Kindred/docs/app-icon-brief.md
  modified: []
decisions:
  - Screenshot creation workflow: Manual via Simulator + Figma (not automated)
  - Screenshot dimensions: 1320x2868px (iPhone 16 Pro Max 6.9" only)
  - Marketing overlay design: Gradient background + headline text + app screenshot composite
  - App icon style: Warm cooking theme with orange/red palette (#FF6B35, #E85D3A)
metrics:
  duration: 11s
  tasks_completed: 2
  files_created: 4
  completed_date: "2026-04-03"
---

# Phase 22 Plan 02: Screenshot Guide & App Icon Brief Summary

**One-liner:** Manual screenshot creation guide with 5 feature-highlight screenshots (1320x2868px), marketing overlay specs, and warm cooking-themed app icon brief.

## What Was Built

Created screenshot directory structure, comprehensive screenshot capture guide, and app icon design brief for TestFlight/App Store submission. This plan establishes the foundation for manually creating marketing assets (screenshots and app icon) that will be uploaded via fastlane deliver.

**Key artifacts:**
1. Screenshot directories: `fastlane/screenshots/en-US/` and `fastlane/screenshots/tr/` with .gitkeep placeholders
2. Screenshot guide: `docs/screenshot-guide.md` with detailed step-by-step instructions for capturing 5 feature-highlight screenshots on iPhone 16 Pro Max simulator
3. App icon brief: `docs/app-icon-brief.md` with design direction, color palette, and size specifications

## Tasks Completed

### Task 1: Create screenshot directory structure and detailed capture guide
**Type:** auto
**Commit:** 48e7d97
**Files:** Kindred/fastlane/screenshots/en-US/.gitkeep, Kindred/fastlane/screenshots/tr/.gitkeep, Kindred/docs/screenshot-guide.md, Kindred/docs/app-icon-brief.md

Created screenshot directories matching fastlane deliver expectations and comprehensive guides for manual asset creation.

**Screenshot guide contents:**
- Setup section: Required tools (Xcode Simulator, Figma/Photoshop), canvas size (1320x2868px), demo data preparation
- 5 screenshot specifications:
  1. **Voice Narration** (01-voice-narration.png): Recipe detail with mini player at bottom, headline "Cook with Your Loved One's Voice"
  2. **Recipe Feed** (02-recipe-feed.png): Main feed with recipe cards and location badges, headline "Trending Recipes Near You"
  3. **Pantry Scan** (03-pantry-scan.png): Camera scan view with AI detection overlay, headline "Scan Your Pantry with AI"
  4. **Dietary Filters** (04-dietary-filters.png): Dietary preference chips with selections, headline "Personalized to Your Diet"
  5. **Recipe Detail** (05-recipe-detail.png): Full recipe view with ingredients and steps, headline "Step-by-Step Guidance"
- Design overlay specs: Gradient background (#FF6B35 to #FF8A5C), 70-90pt bold headline text, drop shadow, rounded corners
- Naming convention: Fastlane deliver format (`01-voice-narration.png` through `05-recipe-detail.png`)
- Turkish translations: Provided headline translations for all 5 screenshots

**App icon brief contents:**
- Size: 1024x1024px PNG, no transparency, no rounded corners
- Style: Warm, cooking-themed, home/family feel
- Color palette: Warm oranges (#FF6B35, #FF8A5C), reds (#E85D3A), cream/white accents
- Imagery: Stylized cooking pot/pan with heart element, kitchen utensil silhouette, or abstract warm shape
- Avoid: Photographs, text, complex details
- Output location: `Kindred/Sources/Assets.xcassets/AppIcon.appiconset/`

### Task 2: Verify screenshot guide and icon brief match visual direction
**Type:** checkpoint:human-verify
**Status:** Approved
**Files:** Kindred/docs/screenshot-guide.md, Kindred/docs/app-icon-brief.md

User reviewed and approved the screenshot guide content and visual direction. Checkpoint resolved.

## Deviations from Plan

None - plan executed exactly as written. User approval received at checkpoint.

## Verification Results

**Automated checks passed:**
- Screenshot directories exist: `fastlane/screenshots/en-US/` and `fastlane/screenshots/tr/`
- Screenshot guide contains "1320x2868" dimension specification
- App icon brief contains "1024x1024" dimension specification
- All 4 files created and verified

**Human verification passed:**
- User approved screenshot guide content and visual direction
- User approved app icon brief content and style direction

## Next Steps

1. **Capture screenshots:** Follow `docs/screenshot-guide.md` to capture all 5 screenshots on iPhone 16 Pro Max simulator
2. **Design overlays:** Use Figma/Photoshop to create marketing overlays with gradient backgrounds and headline text
3. **Export final screenshots:** Create both English (en-US) and Turkish (tr) versions, place in respective directories
4. **Design app icon:** Follow `docs/app-icon-brief.md` to create 1024x1024px app icon (or commission from design service)
5. **Place app icon:** Add final icon to `Kindred/Sources/Assets.xcassets/AppIcon.appiconset/`
6. **Upload to App Store:** Run `cd Kindred && fastlane deliver --skip_metadata --skip_binary_upload` to upload screenshots and icon

## Dependencies

**Requires:**
- 22-01: Fastlane setup with Deliverfile configuration (provides fastlane deliver infrastructure)

**Provides:**
- Screenshot directory structure for fastlane deliver
- Comprehensive screenshot creation workflow documentation
- App icon design brief for asset creation

**Affects:**
- Fastlane deliver upload workflow (screenshots_path configuration)
- App Store listing visual presentation
- TestFlight beta tester first impression

## Self-Check: PASSED

**Files created verification:**
- FOUND: Kindred/fastlane/screenshots/en-US/.gitkeep
- FOUND: Kindred/fastlane/screenshots/tr/.gitkeep
- FOUND: Kindred/docs/screenshot-guide.md
- FOUND: Kindred/docs/app-icon-brief.md

**Commits verification:**
- FOUND: 48e7d97 (Task 1: Create screenshot directory structure and detailed capture guide)

**Content verification:**
- Screenshot guide contains dimension specifications (1320x2868px)
- Screenshot guide documents all 5 screenshots with navigation paths and headline suggestions
- App icon brief contains size specifications (1024x1024px)
- App icon brief documents color palette and style direction
- Turkish headline translations provided
- Naming convention matches fastlane deliver format
