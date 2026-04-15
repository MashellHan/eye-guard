import SwiftUI

/// A speech bubble with rounded corners and a downward-pointing triangle tail.
///
/// Displayed above the mascot to show tips, break reminders, and
/// encouragement messages.
///
/// Supports night mode (v1.4): warmer amber-tinted colors when active.
struct SpeechBubbleView: View {
    let text: String

    /// Whether to use night mode styling (amber tint).
    var isNightMode: Bool = false

    /// Background color adapts to night mode.
    private var bubbleBackground: Color {
        isNightMode ? Color(red: 0.98, green: 0.93, blue: 0.82) : .white
    }

    /// Text color adapts to night mode.
    private var textColor: Color {
        isNightMode ? Color(red: 0.55, green: 0.35, blue: 0.15) : .primary
    }

    /// Shadow color adapts to night mode.
    private var shadowColor: Color {
        isNightMode
            ? Color.orange.opacity(0.15)
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
                    RoundedRectangle(cornerRadius: 12)
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
