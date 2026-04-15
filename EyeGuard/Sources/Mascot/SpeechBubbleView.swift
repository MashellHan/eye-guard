import SwiftUI

/// A speech bubble with rounded corners and a downward-pointing triangle tail.
///
/// Displayed above the mascot to show tips, break reminders, and
/// encouragement messages.
struct SpeechBubbleView: View {
    let text: String

    var body: some View {
        VStack(spacing: 0) {
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 1)
                )

            // Triangle pointer
            Triangle()
                .fill(.white)
                .frame(width: 12, height: 8)
                .shadow(color: .black.opacity(0.06), radius: 1, x: 0, y: 1)
        }
    }
}
