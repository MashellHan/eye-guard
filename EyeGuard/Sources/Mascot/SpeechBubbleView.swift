import SwiftUI

/// A speech bubble with rounded corners and a downward-pointing triangle tail.
///
/// Displayed above the mascot to show tips, break reminders, and
/// encouragement messages.
///
/// Supports night mode (v1.4): warmer amber-tinted colors when active.
/// Supports dark mode (v2.0): adapts colors to system appearance.
struct SpeechBubbleView: View {
    let text: String

    /// Whether to use night mode styling (amber tint).
    var isNightMode: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    /// Background color adapts to night mode and dark mode.
    /// Warm tint added in v3.0 to match mascot palette.
    private var bubbleBackground: Color {
        if isNightMode {
            return Color(red: 0.98, green: 0.93, blue: 0.82)
        }
        return colorScheme == .dark
            ? Color(nsColor: .controlBackgroundColor)
            : Color(red: 0.99, green: 0.97, blue: 0.95)
    }

    /// Text color adapts to night mode and dark mode.
    private var textColor: Color {
        if isNightMode {
            return Color(red: 0.55, green: 0.35, blue: 0.15)
        }
        return .primary
    }

    /// Shadow color adapts to night mode and dark mode.
    private var shadowColor: Color {
        if isNightMode {
            return Color.orange.opacity(0.15)
        }
        return colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.12)
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(textColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(bubbleBackground)
                        .shadow(color: shadowColor, radius: 3, x: 0, y: 1)
                )

            // Triangle pointer
            Triangle()
                .fill(bubbleBackground)
                .frame(width: 12, height: 8)
                .shadow(color: shadowColor.opacity(0.5), radius: 1, x: 0, y: 1)
        }
    }
}
