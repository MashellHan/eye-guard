import Foundation

/// A single eye health tip sourced from ophthalmological guidelines.
///
/// Each tip is bilingual (English/Chinese) and cites its medical source
/// (e.g., AAO, WHO, OSHA). Used in the mascot speech bubble rotation,
/// daily reports, and on-demand tip display.
struct EyeHealthTip: Identifiable, Sendable {
    let id: Int
    let title: String
    let titleChinese: String
    let description: String
    let descriptionChinese: String
    let source: String
    let icon: String

    /// Returns the full bilingual display text for the speech bubble.
    var bubbleText: String {
        "\(title)\n\(titleChinese)"
    }

    /// Returns a compact single-line display for the speech bubble.
    var shortBubbleText: String {
        "💡 \(titleChinese)"
    }
}
