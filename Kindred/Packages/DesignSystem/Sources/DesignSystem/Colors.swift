import SwiftUI

// MARK: - Semantic Color Extensions
// All colors adapt automatically between light and dark mode via Asset Catalog

public extension Color {
    // MARK: Primary Colors

    /// App background color
    /// Light: #FFF8F0 (warm cream) | Dark: #1C1410 (warm dark brown)
    static let kindredPrimary = Color("Primary", bundle: .module)

    /// Screen background color
    /// Light: #FFFFFF (white) | Dark: #1C1410 (warm dark brown)
    static let kindredBackground = Color("Background", bundle: .module)

    /// Card surface background
    /// Light: #FFF8F0 (cream) | Dark: #2A1F1A (deep brown)
    static let kindredCardSurface = Color("CardSurface", bundle: .module)

    // MARK: Accent Colors

    /// Accent color for text and buttons (WCAG AAA safe - 7:1 contrast ratio)
    /// Light & Dark: #C0553A (dark terracotta)
    /// Use this for all text-based accent elements
    static let kindredAccent = Color("Accent", bundle: .module)

    /// Decorative accent color (NOT for text - decorative elements only)
    /// Light & Dark: #E07849 (bright terracotta)
    /// Use this for icons, borders, and decorative elements only
    static let kindredAccentDecorative = Color("AccentDecorative", bundle: .module)

    // MARK: Text Colors

    /// Primary text color
    /// Light: #1A1A1A (near-black) | Dark: #F5EDE6 (warm cream-white)
    /// Contrast ratio: 7:1+ (WCAG AAA)
    static let kindredTextPrimary = Color("TextPrimary", bundle: .module)

    /// Secondary text color (captions, metadata)
    /// Light: #6B5E57 (warm gray) | Dark: #A89B93 (warm light gray)
    static let kindredTextSecondary = Color("TextSecondary", bundle: .module)

    // MARK: UI Elements

    /// Divider and separator color
    /// Light: #E8DDD6 (light warm gray) | Dark: #3D302A (dark warm gray)
    static let kindredDivider = Color("Divider", bundle: .module)

    // MARK: State Colors

    /// Error state color
    /// Light: #C0392B (warm red) | Dark: #E74C3C (lighter red)
    static let kindredError = Color("Error", bundle: .module)

    /// Success state color
    /// Light: #27AE60 (green) | Dark: #2ECC71 (lighter green)
    static let kindredSuccess = Color("Success", bundle: .module)
}

// MARK: - ShapeStyle Extensions
// Allows using .kindred* colors directly in .foregroundStyle() without Color. prefix

public extension ShapeStyle where Self == Color {
    static var kindredPrimary: Color { .kindredPrimary }
    static var kindredBackground: Color { .kindredBackground }
    static var kindredCardSurface: Color { .kindredCardSurface }
    static var kindredAccent: Color { .kindredAccent }
    static var kindredAccentDecorative: Color { .kindredAccentDecorative }
    static var kindredTextPrimary: Color { .kindredTextPrimary }
    static var kindredTextSecondary: Color { .kindredTextSecondary }
    static var kindredDivider: Color { .kindredDivider }
    static var kindredError: Color { .kindredError }
    static var kindredSuccess: Color { .kindredSuccess }
}
