# App Store Screenshot Capture Guide

**Purpose:** Step-by-step instructions for creating all 5 App Store screenshots for Kindred.

**Output:** Manual screenshot creation using iPhone 16 Pro Max Simulator + Figma/Photoshop for marketing overlays.

---

## Setup

### Required Tools
- Xcode with iPhone 16 Pro Max simulator (iOS 17.0+)
- Figma or Adobe Photoshop for marketing overlays
- Demo data prepared in the app

### Canvas Size
- **Device:** 6.9" iPhone (iPhone 16 Pro Max)
- **Resolution:** 1320x2868 pixels
- **Orientation:** Portrait only

### Demo Data Preparation

Before capturing screenshots:

1. **Curate Recipe Feed:**
   - Ensure feed shows 5+ recipes with high-quality, appetizing hero images
   - Recipes should have diverse cuisines and clear titles
   - Location badges should be visible ("Near You" or city name)
   - If pantry has items, ensure match % badges appear

2. **Configure Voice Profile:**
   - Have a demo voice profile active and ready to play
   - Select a recipe with great narration audio for voice screenshot
   - Ensure voice profile name is visible and user-friendly ("Mom's Voice" not a generic ID)

3. **Set Up Pantry Items:**
   - Add 8-10 common pantry ingredients (chicken, rice, tomatoes, etc.)
   - Ensure some ingredients match recipes in feed for match % badges
   - For pantry scan screenshot, have camera access enabled (or prepare for permission screen)

4. **Configure Dietary Preferences:**
   - Select 2-3 dietary filters (e.g., Vegetarian, Gluten-Free, Low-Carb)
   - Ensure filter chips are visible in feed or onboarding

### Simulator Setup

1. Launch Xcode
2. Select **iPhone 16 Pro Max** simulator (iOS 17.0 or later)
3. Run the Kindred app in Debug mode
4. Ensure device is in portrait orientation
5. Set appearance to Light Mode (default) for consistency
6. Disable status bar time/battery indicators if desired (Xcode > Features > Simulate Location > Custom Location)

---

## Screenshot Specifications

Create 5 screenshots in the following order. Each screenshot highlights one killer feature.

### Screenshot 1: Voice Narration
**File:** `01-voice-narration.png`

**Feature:** Voice playback with loved one's cloned voice

**Navigation Path:**
1. From main feed, tap on a recipe card with great hero photo
2. Scroll to recipe detail view
3. Tap the voice playback play button to start narration
4. Ensure mini player is visible at bottom of screen
5. Recipe content should be visible above the mini player

**What to Show:**
- Recipe detail view with appetizing recipe content
- Mini player at bottom showing voice profile name + play/pause controls
- Progress bar indicating playback is active
- Clear visual that audio is playing (playing state, not paused)

**Demo Data Notes:**
- Pick a recipe with excellent hero image and clear ingredient list
- Voice profile name should be warm/personal ("Grandma's Voice", "Mom", etc.)
- Have narration actually playing so UI shows correct state

**Headline Overlay Text (English):**
```
Cook with Your Loved One's Voice
```

**Capture:**
- Press `Cmd+S` in Simulator to save screenshot
- Verify image is 1320x2868px

---

### Screenshot 2: Recipe Feed
**File:** `02-recipe-feed.png`

**Feature:** Trending local recipes with location-based discovery

**Navigation Path:**
1. Launch app to main feed (or navigate to Feed tab)
2. Ensure feed shows 2-3 recipe cards with hero images visible
3. Verify location badges are visible ("Trending in [City]" or "Near You")
4. If pantry items exist, ensure match % badges appear on relevant cards

**What to Show:**
- Main feed with 2-3 recipe cards prominently displayed
- Hero images for each recipe (appetizing food photos)
- Location badge on at least one card
- Optional: Match % badge if pantry integration is visible
- Pull-to-refresh indicator NOT visible (static feed state)

**Demo Data Notes:**
- Curate feed with diverse recipes (Italian, Asian, comfort food mix)
- Ensure location is set to Vilnius or a recognizable city
- Recipe titles should be concise and appetizing

**Headline Overlay Text (English):**
```
Trending Recipes Near You
```

**Capture:**
- Press `Cmd+S` in Simulator
- Verify 2-3 full recipe cards are visible in frame

---

### Screenshot 3: Pantry Scan
**File:** `03-pantry-scan.png`

**Feature:** AI-powered pantry ingredient scanning

**Navigation Path:**
1. Navigate to Pantry tab
2. Tap "Scan with Camera" or camera icon
3. Show camera viewfinder with ingredient detection overlay
   - **Note:** Camera does NOT work in Simulator
   - **Option A:** Capture on physical iPhone 16 Pro Max device
   - **Option B:** Use a static mock screen showing camera permission prompt
   - **Option C:** Show the camera access prompt with "Allow Camera Access" button

**What to Show:**
- Camera viewfinder with ingredient detection overlay (if using physical device)
- OR: Camera permission screen with clear messaging about pantry scanning
- Clear indication this is AI-powered scanning feature
- If permission screen: Show app icon, permission title, explanation text

**Demo Data Notes:**
- If using physical device, have actual fridge/pantry items in frame
- If using permission screen, ensure messaging is clear and benefit-focused

**Headline Overlay Text (English):**
```
Scan Your Pantry with AI
```

**Capture:**
- If physical device: Use screenshot button combo (Volume Up + Power)
- If Simulator: Press `Cmd+S` to capture permission screen
- Transfer to Mac if using physical device

---

### Screenshot 4: Dietary Filters
**File:** `04-dietary-filters.png`

**Feature:** Personalized dietary preference filtering

**Navigation Path:**
1. **Option A:** Show main feed with dietary filter chips visible at top
2. **Option B:** Navigate to onboarding dietary selection screen
3. Ensure 2-3 dietary filters are selected (highlighted/active state)

**What to Show:**
- Dietary filter chips: Vegan, Gluten-Free, Low-Carb, Keto, etc.
- 2-3 filters in selected/active state (filled background, checkmark, or highlighted)
- Clean, organized layout showing personalization options
- If using feed: Show filters affecting recipe results below

**Demo Data Notes:**
- Select visually distinct filters (e.g., Vegan + Gluten-Free + Low-Carb)
- Ensure UI clearly shows which filters are active
- If using onboarding screen, show progress indicator if available

**Headline Overlay Text (English):**
```
Personalized to Your Diet
```

**Capture:**
- Press `Cmd+S` in Simulator
- Verify filter chips are clearly visible and readable

---

### Screenshot 5: Recipe Detail
**File:** `05-recipe-detail.png`

**Feature:** Step-by-step recipe guidance with ingredients and instructions

**Navigation Path:**
1. From main feed, tap on a recipe card with excellent presentation
2. Scroll to show both hero image and ingredient list
3. Ensure recipe title, ingredients, and at least 1-2 cooking steps are visible

**What to Show:**
- Recipe hero image at top (full-bleed, appetizing food photo)
- Recipe title and metadata (servings, time, difficulty if available)
- Ingredient list with quantities and units
- First 1-2 cooking steps visible
- Clean, readable typography and spacing

**Demo Data Notes:**
- Pick a recipe with clear, well-formatted ingredient list
- Recipe should have appetizing hero photo (professional food photography preferred)
- Steps should be concise and actionable ("Chop onions", "Heat oil in pan")

**Headline Overlay Text (English):**
```
Step-by-Step Guidance
```

**Capture:**
- Press `Cmd+S` in Simulator
- Verify both hero image and content are visible in frame

---

## Design Overlay Specifications

After capturing raw screenshots, add marketing overlays in Figma or Photoshop.

### Canvas Setup
- **Dimensions:** 1320x2868px (exact device size)
- **Color mode:** RGB
- **Resolution:** 72 DPI (screen resolution)

### Layout Structure

**Top Section (Headline Area):**
- Height: ~600-700px from top
- Background: Gradient overlay
- Content: Headline text centered

**Bottom Section (Screenshot Area):**
- Height: Remaining space (~2100-2200px)
- Content: Device screenshot with styling

### Gradient Background

**Color Palette (Warm Cooking Theme):**
- **Primary gradient:** `#FF6B35` (orange) to `#FF8A5C` (light orange)
- **Alternative gradient:** `#E85D3A` (red-orange) to `#FF7F56` (coral)
- **Direction:** Top to bottom or diagonal (45°)

**Application:**
- Apply gradient to top 600-700px of canvas
- Subtle fade to transparent at bottom to blend with screenshot

### Headline Text

**Typography:**
- **Font:** SF Pro Display Bold (or similar bold sans-serif)
- **Size:** 70-90pt (adjust for readability)
- **Color:** White (#FFFFFF)
- **Alignment:** Centered horizontally
- **Position:** Vertically centered in gradient area (300-350px from top)
- **Shadow:** Optional subtle drop shadow for depth (2-4px blur, 20% opacity)

### Screenshot Placement

**Styling:**
- **Position:** Below gradient area, 20px padding from left/right edges
- **Size:** Scale to fit width minus 40px (total padding)
- **Rounded corners:** 40px border radius for modern look
- **Shadow:** Subtle drop shadow (0px 10px 30px rgba(0, 0, 0, 0.15))
- **Background:** If screenshot has transparency, use white or light gray background

**Alignment:**
- Top of screenshot should align ~650-700px from top of canvas
- Ensure screenshot doesn't extend beyond canvas height

### Export Settings

**Format:** PNG
- **Compression:** High quality (80-90%)
- **Transparency:** None (flatten all layers)
- **Color profile:** sRGB

**File Size:**
- Target: Under 10MB per file (App Store limit)
- Typical: 2-5MB per screenshot with good compression

**Verification:**
- Double-check dimensions: Exactly 1320x2868px
- Check file size: Under 10MB
- Visual QA: No pixelation, clean edges, readable text

---

## Naming Convention

Follow fastlane deliver format for automated upload.

### English Screenshots
**Directory:** `fastlane/screenshots/en-US/`

```
01-voice-narration.png
02-recipe-feed.png
03-pantry-scan.png
04-dietary-filters.png
05-recipe-detail.png
```

### Turkish Screenshots
**Directory:** `fastlane/screenshots/tr/`

```
01-voice-narration.png
02-recipe-feed.png
03-pantry-scan.png
04-dietary-filters.png
05-recipe-detail.png
```

**Note:** Turkish screenshots use the same app captures but with Turkish headline overlay text (see translations below).

---

## Turkish Headline Translations

Use these Turkish translations for headline overlay text:

| # | English | Turkish |
|---|---------|---------|
| 01 | Cook with Your Loved One's Voice | Sevdiğinizin Sesiyle Pişirin |
| 02 | Trending Recipes Near You | Yakınınızdaki Trend Tarifler |
| 03 | Scan Your Pantry with AI | Mutfağınızı AI ile Tarayın |
| 04 | Personalized to Your Diet | Diyetinize Özel |
| 05 | Step-by-Step Guidance | Adım Adım Rehberlik |

**Typography Notes:**
- Turkish uses dotted İ (İ, i) and dotless I (I, ı) — ensure correct capitalization
- Verify character encoding (UTF-8) to preserve Turkish characters

---

## Upload to App Store Connect

After all screenshots are created, use fastlane to upload.

### Upload Command

```bash
cd Kindred
fastlane deliver --skip_metadata --skip_binary_upload
```

**What this does:**
- Uploads screenshots from `fastlane/screenshots/` directory
- Skips metadata upload (text descriptions, keywords, etc.)
- Skips binary upload (app build)
- Automatically organizes screenshots by locale (en-US, tr)

### Verification

After upload, verify in App Store Connect:
1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to your app > App Store tab
3. Scroll to "App Previews and Screenshots"
4. Verify all 5 screenshots appear in correct order for both English and Turkish
5. Check that screenshots render correctly on 6.9" device preview

---

## Quality Checklist

Before finalizing screenshots:

- [ ] All 5 screenshots created for English (en-US)
- [ ] All 5 screenshots created for Turkish (tr)
- [ ] Each screenshot is exactly 1320x2868px
- [ ] Each screenshot is under 10MB file size
- [ ] Gradient colors match brand palette (warm oranges/reds)
- [ ] Headline text is readable and centered
- [ ] Turkish translations are accurate with correct İ/I characters
- [ ] Screenshots follow feature order: Voice → Feed → Pantry → Dietary → Recipe Detail
- [ ] No UI bugs visible (misaligned elements, loading states, placeholder content)
- [ ] Demo data looks production-ready (real recipe names, appetizing photos)
- [ ] File naming matches fastlane deliver convention exactly

---

**Next Steps:**
1. Follow this guide to capture all 10 screenshots (5 English + 5 Turkish)
2. Review with stakeholders for approval
3. Upload to App Store Connect via fastlane deliver command
4. Verify screenshots appear correctly in App Store Connect dashboard

---

*Screenshot guide created: 2026-04-03*
*Target device: iPhone 16 Pro Max (1320x2868px)*
