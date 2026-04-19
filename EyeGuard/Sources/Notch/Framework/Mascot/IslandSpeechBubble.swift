import SwiftUI

/// A speech bubble displayed above the mascot in the notch.
///
/// Adapted for the notch dark theme — uses semi-transparent white
/// instead of the light-mode colors from the original EyeGuard version.
/// Supports night mode (amber tint) for eye guard reminders.
/// Optionally shows action buttons for pre-break alerts.
struct IslandSpeechBubbleView: View {
    let text: String

    /// Whether to use night mode styling (amber tint).
    var isNightMode: Bool = false

    /// Auto-dismiss after this many seconds (nil = persistent).
    var autoDismissAfter: TimeInterval? = nil

    var onDismiss: (() -> Void)? = nil

    // MARK: - Action Buttons (for pre-break alerts)

    /// Primary action button (e.g. "Take Break Now").
    var primaryLabel: String? = nil
    var primaryAction: (() -> Void)? = nil

    /// Secondary action button (e.g. "Postpone 5 min").
    var secondaryLabel: String? = nil
    var secondaryAction: (() -> Void)? = nil

    @State private var appeared = false

    private var bubbleBackground: Color {
        isNightMode
            ? Color(red: 0.45, green: 0.35, blue: 0.15).opacity(0.9)
            : Color.white.opacity(0.12)
    }

    private var textColor: Color {
        isNightMode
            ? Color(red: 1.0, green: 0.9, blue: 0.7)
            : .white.opacity(0.85)
    }

    private var hasActions: Bool {
        primaryAction != nil || secondaryAction != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: hasActions ? 6 : 0) {
                HStack(spacing: 4) {
                    Text(text)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(textColor)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    if onDismiss != nil && !hasActions {
                        Button {
                            onDismiss?()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                    }
                }

                if hasActions {
                    HStack(spacing: 6) {
                        if let action = primaryAction, let label = primaryLabel {
                            Button(action: {
                                action()
                                onDismiss?()
                            }) {
                                Text(label)
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.teal.opacity(0.8))
                                    )
                            }
                            .buttonStyle(.plain)
                        }

                        if let action = secondaryAction, let label = secondaryLabel {
                            Button(action: {
                                action()
                                onDismiss?()
                            }) {
                                Text(label)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.white.opacity(0.6))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(.white.opacity(0.08))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, hasActions ? 6 : 5)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(bubbleBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(.white.opacity(0.08), lineWidth: 0.5)
                    )
            )

            // Triangle pointer
            TipTriangle()
                .fill(bubbleBackground)
                .frame(width: 8, height: 5)
        }
        .scaleEffect(appeared ? 1.0 : 0.8)
        .opacity(appeared ? 1.0 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                appeared = true
            }
            if let delay = autoDismissAfter {
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(delay))
                    withAnimation(.easeOut(duration: 0.2)) {
                        appeared = false
                    }
                    try? await Task.sleep(for: .seconds(0.25))
                    onDismiss?()
                }
            }
        }
    }
}
