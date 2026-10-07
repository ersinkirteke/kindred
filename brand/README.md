# Kindred brand assets

| File | Use |
|---|---|
| `kindred_logo_web.png` | Master logo, 2048×2048 (source for every icon) |
| `kindred_logo.png` | Earlier 2816×1536 version |
| `AppIcon.appiconset/` | iOS app icon, ready for Xcode |

The website icons in `website/assets/` are generated from `kindred_logo_web.png`
by copying only the glyph box (x 408–1640, y 500–1574), which keeps the
Gemini watermark in the bottom-right corner out of every asset.

## Installing the app icon

`Kindred/Sources/Resources/Assets.xcassets/` is git-ignored, so the icon set
lives here and is copied into the asset catalog on the Mac:

1. In Finder, copy `brand/AppIcon.appiconset` into
   `Kindred/Sources/Resources/Assets.xcassets/` (replace an existing
   `AppIcon.appiconset` if there is one).
2. In Xcode, open `Assets.xcassets` → `AppIcon` and check the 1024×1024 slot.
3. Build and run; the target already uses `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`.

`AppIcon.png` is 1024×1024, opaque RGB (no alpha) with square corners — iOS
applies the rounded mask itself — and the glyph sits 128px+ from every edge.
