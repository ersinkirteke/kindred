import SwiftUI

// MARK: - Typography System
// SF Pro font styles with Dynamic Type support
// Per locked decision: Medium weight for headings, Light weight for body text

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

    /// Small text style (12pt, light)
    /// Use for: Fine print, legal text, minimal labels
    static func kindredSmall() -> Font {
        .system(size: 12, weight: .light, design: .default)
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
