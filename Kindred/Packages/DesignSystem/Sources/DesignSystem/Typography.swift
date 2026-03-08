import SwiftUI

// MARK: - Typography System
// SF Pro font styles with Dynamic Type support
// Per locked decision: Medium weight for headings, Light weight for body text

// MARK: - @ScaledMetric Pattern
// For views that need Dynamic Type scaling at AX1-AX5 sizes, use the scaled variants:
//
// Usage in views:
// @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 18
// Text("...").font(.kindredBodyScaled(size: bodySize))
//
// relativeTo mapping guide:
// - .largeTitle -> kindredLargeTitle (34pt)
// - .title -> kindredHeading1 (28pt)
// - .title2 -> kindredHeading2 (22pt)
// - .headline -> kindredHeading3 (18pt), kindredBody (18pt)
// - .subheadline -> kindredBodyBold (18pt)
// - .caption -> kindredCaption (14pt), kindredSmall (14pt)

public extension Font {

    // MARK: Headings (Medium Weight)

    /// Large title style (34pt, medium)
    /// Use for: Main screen titles
    static func kindredLargeTitle() -> Font {
        .system(size: 34, weight: .medium, design: .default)
    }

    /// Heading 1 style (28pt, medium)
    /// Use for: Section headers, primary headings
    static func kindredHeading1() -> Font {
        .system(size: 28, weight: .medium, design: .default)
    }

    /// Heading 2 style (22pt, medium)
    /// Use for: Subsection headers, card titles
    static func kindredHeading2() -> Font {
        .system(size: 22, weight: .medium, design: .default)
    }

    /// Heading 3 style (18pt, medium)
    /// Use for: Minor headers, emphasized labels
    static func kindredHeading3() -> Font {
        .system(size: 18, weight: .medium, design: .default)
    }

    // MARK: Body Text (Light Weight)

    /// Body text style (18pt, light)
    /// WCAG AAA minimum: 18sp for light weight text
    /// Use for: Primary content, descriptions, recipe steps
    static func kindredBody() -> Font {
        .system(size: 18, weight: .light, design: .default)
    }

    /// Bold body text style (18pt, medium)
    /// Use for: Emphasized body text, ingredient names
    static func kindredBodyBold() -> Font {
        .system(size: 18, weight: .medium, design: .default)
    }

    // MARK: Supporting Text

    /// Caption text style (14pt, light)
    /// Use for: Metadata, timestamps, auxiliary information
    static func kindredCaption() -> Font {
        .system(size: 14, weight: .light, design: .default)
    }

    /// Small text style (14pt, light)
    /// UPDATED: Bumped from 12pt to 14pt minimum per accessibility requirements
    /// Use for: Fine print, legal text, minimal labels
    static func kindredSmall() -> Font {
        .system(size: 14, weight: .light, design: .default)
    }

    // MARK: - @ScaledMetric-Compatible Scaled Variants
    // These methods accept a CGFloat size parameter from @ScaledMetric in views

    /// Scaled large title style — accepts size from @ScaledMetric(relativeTo: .largeTitle)
    static func kindredLargeTitleScaled(size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    /// Scaled heading 1 style — accepts size from @ScaledMetric(relativeTo: .title)
    static func kindredHeading1Scaled(size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    /// Scaled heading 2 style — accepts size from @ScaledMetric(relativeTo: .title2)
    static func kindredHeading2Scaled(size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    /// Scaled heading 3 style — accepts size from @ScaledMetric(relativeTo: .headline)
    static func kindredHeading3Scaled(size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    /// Scaled body style — accepts size from @ScaledMetric(relativeTo: .body)
    static func kindredBodyScaled(size: CGFloat) -> Font {
        .system(size: size, weight: .light, design: .default)
    }

    /// Scaled bold body style — accepts size from @ScaledMetric(relativeTo: .subheadline)
    static func kindredBodyBoldScaled(size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    /// Scaled caption style — accepts size from @ScaledMetric(relativeTo: .caption)
    static func kindredCaptionScaled(size: CGFloat) -> Font {
        .system(size: size, weight: .light, design: .default)
    }

    /// Scaled small style — accepts size from @ScaledMetric(relativeTo: .caption)
    static func kindredSmallScaled(size: CGFloat) -> Font {
        .system(size: size, weight: .light, design: .default)
    }
}

// MARK: - Dynamic Type Support
// All Font methods return Font (not static sizes) to support automatic
// Dynamic Type scaling via SwiftUI's built-in .dynamicTypeSize() modifier

// MARK: - View Modifiers
// Convenience modifiers for applying typography styles to views

public extension View {
    /// Apply large title font style
    func kindredLargeTitle() -> some View {
        self.font(.kindredLargeTitle())
    }

    /// Apply heading 1 font style
    func kindredHeading1() -> some View {
        self.font(.kindredHeading1())
    }

    /// Apply heading 2 font style
    func kindredHeading2() -> some View {
        self.font(.kindredHeading2())
    }

    /// Apply heading 3 font style
    func kindredHeading3() -> some View {
        self.font(.kindredHeading3())
    }

    /// Apply body font style
    func kindredBody() -> some View {
        self.font(.kindredBody())
    }

    /// Apply bold body font style
    func kindredBodyBold() -> some View {
        self.font(.kindredBodyBold())
    }

    /// Apply caption font style
    func kindredCaption() -> some View {
        self.font(.kindredCaption())
    }

    /// Apply small font style
    func kindredSmall() -> some View {
        self.font(.kindredSmall())
    }
}
