import SwiftUI

/// Pool of eye care tips displayed during breaks.
/// Sourced from ophthalmologist-recommended exercises (AAO, WHO).
private let eyeCareTips: [String] = [
    "有意识地连续眨眼 20 次，让泪膜重新覆盖角膜",
    "闭眼，双手搓热后轻覆眼睛 20 秒（掌心热敷法）",
    "看向窗外最远的物体，保持 20 秒，放松睫状肌",
    "眼球画 ∞ 字：缓慢追踪一个 8 字形，正反各 5 次",
    "近远交替对焦：看手指 5 秒 → 看远处 5 秒，重复 4 次",
    "闭眼缓慢转动眼球画圆，顺时针 5 圈再逆时针 5 圈",
    "轻柔按压睛明穴（鼻梁两侧）10 秒，缓解酸胀",
    "双手拇指按揉太阳穴，同时闭眼深呼吸 3 次",
    "站起来活动一下，远眺窗外绿植或天空",
    "用力闭眼 3 秒再睁开，重复 5 次，刺激泪腺分泌",
    "上下左右各看 3 秒，锻炼眼外肌群",
    "喝一杯水吧！充足的水分有助于缓解干眼",
]

/// A full-screen overlay for break notifications.
///
/// Covers all screens with a semi-transparent dark background.
/// Features a cute mascot, auto-starting countdown, health tip, and skip button.
struct FullScreenOverlayView: View {

    let breakType: BreakType
    let healthScore: Int
    let dismissPolicy: DismissPolicy
    let postponeCount: Int
    let onBreakTaken: @Sendable () -> Void
    let onPostponed: @Sendable () -> Void

    @State private var remainingSeconds: Int = 0
    @State private var totalDuration: Int = 0
    @State private var timer: Timer?
    @State private var appeared: Bool = false
    @State private var currentTip: String = eyeCareTips.randomElement() ?? eyeCareTips[0]

    private var progress: Double {
        guard totalDuration > 0 else { return 1.0 }
        return Double(totalDuration - remainingSeconds) / Double(totalDuration)
    }

    private var countdownText: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        }
        return "\(seconds)"
    }

    /// Break-type-specific title message.
    private var titleMessage: String {
        switch breakType {
        case .micro:
            return "阿普提醒你：休息 20 秒 👀"
        case .macro:
            return "阿普提醒你：站起来活动 5 分钟 ☕"
        case .mandatory:
            return "阿普提醒你：该好好休息了 🚶"
        }
    }

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            // Blur effect
            VisualEffectBlur()
                .ignoresSafeArea()

            // Center content
            VStack(spacing: 20) {
                Spacer()

                // Mascot character
                MascotView(
                    state: .resting,
                    restingMode: .sleeping,
                    isHighScore: healthScore >= 80
                )
                .scaleEffect(1.8)
                .padding(.bottom, 12)

                // Simple message
                Text(titleMessage)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(currentTip)
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)

                // Countdown ring
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.15), lineWidth: 6)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [.green, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0), value: progress)

                    Text(countdownText)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                }
                .padding(.top, 8)

                // Health score badge
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(healthScore >= 80 ? .green : healthScore >= 50 ? .yellow : .red)
                        .font(.caption)
                    Text("眼睛健康分: \(healthScore)/100")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(.white.opacity(0.08))
                .clipShape(Capsule())

                Spacer()

                // Skip button at bottom
                Button {
                    stopTimer()
                    onPostponed()
                } label: {
                    Text("跳过休息")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.08))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.bottom, 40)
            }
        }
        .opacity(appeared ? 1.0 : 0.0)
        .onAppear {
            let duration = Int(breakType.duration)
            remainingSeconds = duration
            totalDuration = duration
            withAnimation(.easeIn(duration: 0.4)) {
                appeared = true
            }
            // Auto-start countdown immediately
            startCountdownTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    private func startCountdownTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                if remainingSeconds > 0 {
                    withAnimation {
                        remainingSeconds -= 1
                    }
                }
                if remainingSeconds <= 0 {
                    stopTimer()
                    onBreakTaken()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Visual Effect Blur (NSVisualEffectView wrapper)

struct VisualEffectBlur: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .fullScreenUI
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
