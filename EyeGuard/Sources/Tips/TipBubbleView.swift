import SwiftUI

/// A speech bubble view that displays a random eye health tip.
///
/// Features:
/// - Shows a tip from `TipDatabase` with bilingual title
/// - Rotates tips every 30 minutes via a background timer
/// - Can be dismissed; next tip shows on the next rotation
/// - Source citation displayed in footer
struct TipBubbleView: View {

    let tip: EyeHealthTip

    /// Callback when user wants to see the next tip.
    var onNextTip: (() -> Void)?

    /// Callback when user dismisses the tip.
    var onDismiss: (() -> Void)?

    @State private var appeared: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                // Header with icon
                HStack(spacing: 6) {
                    Image(systemName: tip.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(.teal)

                    Text("Eye Health Tip 护眼贴士")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.teal)

                    Spacer()

                    // Dismiss button
                    if let onDismiss {
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Tip title (bilingual)
                VStack(alignment: .leading, spacing: 2) {
                    Text(tip.title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text(tip.titleChinese)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                // Source citation
                HStack(spacing: 4) {
                    Text("Source: \(tip.source)")
                        .font(.system(size: 8))
                        .foregroundStyle(.tertiary)

                    Spacer()

                    // Next tip button
                    if let onNextTip {
                        Button(action: onNextTip) {
                            HStack(spacing: 2) {
                                Text("Next")
                                    .font(.system(size: 9))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 8))
                            }
                            .foregroundStyle(.teal)
                        }
                        .buttonStyle(.plain)
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

            // Triangle pointer
            Triangle()
                .fill(.white)
                .frame(width: 12, height: 8)
                .shadow(color: .black.opacity(0.06), radius: 1, x: 0, y: 1)
        }
        .frame(maxWidth: 200)
        .scaleEffect(appeared ? 1.0 : 0.9)
        .opacity(appeared ? 1.0 : 0)
        .onAppear {
            withAnimation(.spring(duration: 0.3)) {
                appeared = true
            }
        }
    }
}
