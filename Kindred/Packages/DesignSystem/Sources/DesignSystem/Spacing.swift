import Foundation

// MARK: - Spacing System
// Consistent spacing scale for padding, margins, and layout

public enum KindredSpacing {

    /// Extra small spacing: 4pt
    /// Use for: Tight gaps, chip spacing, icon-to-text spacing
    public static let xs: CGFloat = 4

    /// Small spacing: 8pt
    /// Use for: Component internal padding, list item gaps
    public static let sm: CGFloat = 8

    /// Medium spacing: 16pt
    /// Use for: Default padding, card internal spacing, section gaps
    public static let md: CGFloat = 16

    /// Large spacing: 24pt
    /// Use for: Section separators, card-to-card spacing
    public static let lg: CGFloat = 24

    /// Extra large spacing: 32pt
    /// Use for: Screen edge margins, major section breaks
    public static let xl: CGFloat = 32

    /// Extra extra large spacing: 48pt
    /// Use for: Top/bottom screen padding, hero spacing
    public static let xxl: CGFloat = 48
}
