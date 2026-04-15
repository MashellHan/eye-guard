import SwiftUI

/// Displays color balance suggestions in the mascot's speech bubble during breaks.
///
/// Shows:
/// - A colored circle of the suggested complementary color
/// - A bilingual suggestion message based on the dominant screen color
/// - The detected dominant color family name
///
/// Used by the mascot container to display color suggestions during break time.
struct ColorSuggestionView: View {
    /// The dominant color family detected from screen analysis.
    let dominantFamily: ColorAnalyzer.ColorFamily

    /// The suggested complementary color family.
    let suggestedFamily: ColorAnalyzer.ColorFamily

    /// The suggestion message text.
    let message: String

    var body: some View {
        VStack(spacing: 6) {
            // Suggestion message
            Text(message)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(3)

            // Color indicator row
            HStack(spacing: 8) {
                // Dominant color indicator
                VStack(spacing: 2) {
                    Circle()
                        .fill(colorForFamily(dominantFamily))
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                        )
                    Text("当前")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }

                Image(systemName: "arrow.right")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)

                // Suggested color indicator
                VStack(spacing: 2) {
                    Circle()
                        .fill(colorForFamily(suggestedFamily))
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: colorForFamily(suggestedFamily).opacity(0.4), radius: 3)
                    Text("建议")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
                .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 1)
        )
    }

    /// Converts a ColorFamily to a SwiftUI Color.
    private func colorForFamily(_ family: ColorAnalyzer.ColorFamily) -> Color {
        let c = family.displayColor
        return Color(red: c.red, green: c.green, blue: c.blue)
    }
}

/// A simplified inline version for use within the speech bubble text area.
/// Shows just the suggestion text with a small colored dot.
struct InlineColorSuggestion: View {
    let suggestion: (message: String, emoji: String)
    let suggestedFamily: ColorAnalyzer.ColorFamily

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(colorForFamily(suggestedFamily))
                .frame(width: 10, height: 10)

            Text("\(suggestion.emoji) \(suggestion.message)")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
        }
    }

    private func colorForFamily(_ family: ColorAnalyzer.ColorFamily) -> Color {
        let c = family.displayColor
        return Color(red: c.red, green: c.green, blue: c.blue)
    }
}
