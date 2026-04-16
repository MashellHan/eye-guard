import SwiftUI

/// A view modifier that adds shake animation and a hint toast when triggered.
///
/// Used on mandatory break overlays to provide visual feedback when the user
/// presses ESC but the break cannot be dismissed.
struct MandatoryShakeModifier: ViewModifier {

    @State private var shakeOffset: CGFloat = 0
    @State private var showHint: Bool = false

    /// Binding that triggers the shake when set to true. Resets automatically.
    @Binding var trigger: Bool

    /// Vertical padding from the bottom for the hint label.
    var hintBottomPadding: CGFloat = 30

    func body(content: Content) -> some View {
        content
            .offset(x: shakeOffset)
            .overlay(alignment: .bottom) {
                if showHint {
                    Text("⚠️ 强制休息期间无法关闭")
                        .font(hintBottomPadding > 40 ? .subheadline : .caption)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, -hintBottomPadding)
                }
            }
            .onChange(of: trigger) { _, shouldShake in
                guard shouldShake else { return }
                performShake()
                trigger = false
            }
    }

    private func performShake() {
        withAnimation(.default) { shakeOffset = 12 }
        withAnimation(.default.delay(0.08)) { shakeOffset = -10 }
        withAnimation(.default.delay(0.16)) { shakeOffset = 6 }
        withAnimation(.default.delay(0.24)) { shakeOffset = -4 }
        withAnimation(.default.delay(0.32)) { shakeOffset = 0 }
        withAnimation(.easeInOut(duration: 0.2)) { showHint = true }
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) { showHint = false }
            }
        }
    }
}

extension View {
    /// Applies mandatory break shake feedback when `trigger` becomes true.
    func mandatoryShake(trigger: Binding<Bool>, hintBottomPadding: CGFloat = 30) -> some View {
        modifier(MandatoryShakeModifier(trigger: trigger, hintBottomPadding: hintBottomPadding))
    }
}
