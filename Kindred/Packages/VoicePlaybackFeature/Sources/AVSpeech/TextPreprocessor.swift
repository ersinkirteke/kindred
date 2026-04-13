import Foundation

// MARK: - TextPreprocessor

/// Prepares recipe step text for TTS-friendly output.
///
/// Processing pipeline (in order):
/// 1. Strip HTML tags
/// 2. Strip markdown formatting
/// 3. Expand Unicode fractions
/// 4. Expand cooking abbreviations
/// 5. Normalize amounts
/// 6. Prefix with step number
public enum TextPreprocessor {

    // MARK: - Public API

    /// Runs the full preprocessing pipeline on a single recipe step.
    /// - Parameters:
    ///   - rawText: The raw step text (may contain HTML, markdown, abbreviations, etc.)
    ///   - stepNumber: 1-based step number to prefix the output with
    /// - Returns: TTS-friendly string
    public static func prepare(_ rawText: String, stepNumber: Int) -> String {
        var text = rawText

        // 1. Strip HTML tags
        text = stripHTML(text)

        // 2. Strip markdown formatting
        text = stripMarkdown(text)

        // 3. Expand Unicode fractions
        text = expandFractions(text)

        // 4. Expand cooking abbreviations
        text = expandAbbreviations(text)

        // 5. Normalize amounts
        text = normalizeAmounts(text)

        // 6. Prefix with step number
        text = "Step \(stepNumber): \(text)"

        return text
    }

    /// Runs the full preprocessing pipeline on an array of recipe steps.
    /// - Parameter steps: Raw step strings (0-indexed)
    /// - Returns: TTS-ready strings with 1-based step number prefixes
    public static func prepareSteps(_ steps: [String]) -> [String] {
        steps.enumerated().map { index, text in
            prepare(text, stepNumber: index + 1)
        }
    }

    // MARK: - Step 1: Strip HTML

    private static func stripHTML(_ text: String) -> String {
        // Fast-path: skip if no '<' in text
        guard text.contains("<") else { return text }
        return text.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: [.regularExpression]
        )
    }

    // MARK: - Step 2: Strip Markdown

    private static func stripMarkdown(_ text: String) -> String {
        var result = text

        // **bold** → bold
        result = result.replacingOccurrences(
            of: "\\*\\*(.+?)\\*\\*",
            with: "$1",
            options: [.regularExpression]
        )

        // *italic* → content
        result = result.replacingOccurrences(
            of: "\\*(.+?)\\*",
            with: "$1",
            options: [.regularExpression]
        )

        // # headers → content (strip leading # symbols and whitespace, using (?m) inline flag)
        result = result.replacingOccurrences(
            of: "(?m)^#{1,6}\\s+",
            with: "",
            options: [.regularExpression]
        )

        // - bullets → content (strip leading dash and whitespace, using (?m) inline flag)
        result = result.replacingOccurrences(
            of: "(?m)^-\\s+",
            with: "",
            options: [.regularExpression]
        )

        return result
    }

    // MARK: - Step 3: Expand Unicode Fractions

    private static let fractionMap: [String: String] = [
        "½": "one half",
        "¼": "one quarter",
        "¾": "three quarters",
        "⅓": "one third",
        "⅔": "two thirds",
        "⅛": "one eighth",
        "⅜": "three eighths",
        "⅝": "five eighths",
        "⅞": "seven eighths"
    ]

    private static func expandFractions(_ text: String) -> String {
        var result = text
        for (fraction, expansion) in fractionMap {
            result = result.replacingOccurrences(of: fraction, with: expansion)
        }
        return result
    }

    // MARK: - Step 4: Expand Cooking Abbreviations

    private static func expandAbbreviations(_ text: String) -> String {
        var result = text

        let replacements: [(pattern: String, replacement: String)] = [
            ("\\btbsp\\.?\\b", "tablespoon"),
            ("\\btsp\\.?\\b", "teaspoon"),
            ("\\boz\\.?\\b", "ounce"),
            ("\\blbs\\.?\\b", "pounds"),
            ("\\blb\\.?\\b", "pound"),
            ("\\bml\\.?\\b", "milliliter"),
            ("\\bkg\\.?\\b", "kilogram"),
            ("\\bg\\.?(?=\\s)", "gram"),
            ("\\bmin\\.?\\b", "minute"),
        ]

        for (pattern, replacement) in replacements {
            result = result.replacingOccurrences(
                of: pattern,
                with: replacement,
                options: [.regularExpression, .caseInsensitive]
            )
        }

        return result
    }

    // MARK: - Step 5: Normalize Amounts

    private static func normalizeAmounts(_ text: String) -> String {
        var result = text

        // "12-15" → "12 to 15"
        result = result.replacingOccurrences(
            of: "(\\d+)-(\\d+)",
            with: "$1 to $2",
            options: [.regularExpression]
        )

        // "~12" → "approximately 12"
        result = result.replacingOccurrences(
            of: "~(\\d+)",
            with: "approximately $1",
            options: [.regularExpression]
        )

        return result
    }
}
