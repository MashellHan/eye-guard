import SwiftUI
import os

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
    let exerciseSessionsToday: Int
    let recommendedExerciseSessions: Int
    let onBreakTaken: @Sendable () -> Void
    let onSkipped: @Sendable () -> Void
    let onPostponed: @Sendable () -> Void
    let onStartExercises: (@Sendable () -> Void)?
    /// Whether this instance owns audio + completion callbacks.
    /// In multi-monitor setups only the primary screen's view should speak and fire `onBreakTaken`;
    /// secondary screens render the same countdown silently and dismiss when primary triggers.
    var isPrimary: Bool = true

    @State private var remainingSeconds: Int = 0
    @State private var totalDuration: Int = 0
    @State private var timer: Timer?
    @State private var appeared: Bool = false
    @State private var currentTip: String = eyeCareTips.randomElement() ?? eyeCareTips[0]
    @State private var shakeTrigger: Bool = false
    /// Guard against duplicate completion when timer dispatches multiple <=0 ticks.
    /// Mirrors the same pattern in `BreakOverlayView` (Tier 2).
    @State private var hasCompleted: Bool = false
    /// Set when `.screenDidLock` fires while this overlay is on screen (B10).
    /// Causes the timer loop to stop and dismisses the window in lockstep with
    /// the scheduler's `cancelActiveBreak()`.
    @State private var dismissedByScreenLock: Bool = false
    /// Stable identifier for this view instance — surfaces in logs so we can
    /// correlate `onAppear` re-fires with rogue Timer ticks (B6 diagnosis).
    @State private var instanceID: UUID = UUID()

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

    /// Whether to show the exercise button (macro/mandatory breaks only).
    private var showExerciseOption: Bool {
        (breakType == .macro || breakType == .mandatory) && onStartExercises != nil
    }

    /// Formatted total duration label (e.g. "共 5:00").
    private var totalDurationText: String {
        let minutes = totalDuration / 60
        let seconds = totalDuration % 60
        if minutes > 0 {
            return String(format: "共 %d:%02d", minutes, seconds)
        }
        return "共 \(seconds) 秒"
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
            // B1 follow-up: blur must render BELOW the dark scrim. ZStack
            // stacks bottom→top, so VisualEffectBlur first, then a heavy
            // black scrim on top guarantees dark substrate even on a white
            // wallpaper. Previous order let `.fullScreenUI` material wash
            // the scrim back to near-transparent → white text on white bg.
            VisualEffectBlur()
                .ignoresSafeArea()

            Color.black.opacity(0.85)
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

                    VStack(spacing: 2) {
                        Text(countdownText)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())

                        Text(totalDurationText)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                    }
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

                // Exercise section (macro/mandatory breaks only)
                if showExerciseOption {
                    exerciseSection
                }

                Spacer()

                // Skip button at bottom
                Button {
                    stopTimer()
                    onSkipped()
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
        .mandatoryShake(trigger: $shakeTrigger, hintBottomPadding: 60, useLargeFont: true)
        .onExitCommand {
            // Mandatory breaks cannot be dismissed with ESC
            guard case .mandatory = dismissPolicy else {
                stopTimer()
                onSkipped()
                return
            }
            shakeTrigger = true
        }
        .onAppear {
            let duration = Int(breakType.duration)
            Log.notification.info("FullScreenOverlay appeared id=\(instanceID.uuidString) breakType=\(breakType.displayName) duration=\(duration)s isPrimary=\(isPrimary)")
            // B10: if screen locked before SwiftUI mounted us, bail immediately
            // so the per-window Timer never starts (macOS does not suspend
            // user-space Timers during lock screen).
            if BreakScheduler.isScreenCurrentlyLocked() {
                Log.notification.info("FullScreenOverlay onAppear aborted — screen already locked id=\(instanceID.uuidString)")
                dismissedByScreenLock = true
                if isPrimary {
                    onSkipped()
                }
                return
            }
            // B6: NSHostingView can re-fire `.onAppear` during a layout pass
            // or when SwiftUI rebuilds a parent subtree. Without this guard
            // we'd reset `remainingSeconds` and (worse) call
            // `startCountdownTimer` again — leaving multiple Timers ticking
            // on the run loop and decrementing N×/sec → ~3s drain for a 20s
            // micro break. The Timer-side `invalidate()` is the real fix;
            // this guard keeps `instanceID`/`hasCompleted` state stable too.
            guard timer == nil else {
                Log.notification.debug("FullScreenOverlay.onAppear re-fired id=\(instanceID.uuidString); timer already running, skipping re-init")
                return
            }
            remainingSeconds = duration
            totalDuration = duration
            withAnimation(.easeIn(duration: 0.4)) {
                appeared = true
            }
            // Auto-start countdown immediately
            startCountdownTimer()
        }
        .onDisappear {
            Log.notification.info("FullScreenOverlay disappeared: \(breakType.displayName), remaining=\(remainingSeconds)s")
            stopTimer()
        }
        // B10: dismiss on screen lock so the overlay vanishes when the user
        // walks away (the scheduler also cancels the active break + stops TTS).
        .onReceive(NotificationCenter.default.publisher(for: .screenDidLock)) { _ in
            guard !dismissedByScreenLock else { return }
            Log.notification.info("FullScreenOverlay dismiss on .screenDidLock id=\(instanceID.uuidString) isPrimary=\(isPrimary)")
            dismissedByScreenLock = true
            stopTimer()
            // Only the primary view fires the user-facing callback; secondary
            // screens just tear down their local Timer and let the controller
            // dismiss every window in unison.
            if isPrimary {
                onSkipped()
            }
        }
    }

    // MARK: - Exercise Section

    /// Inline exercise recommendation with badge and start button.
    private var exerciseSection: some View {
        VStack(spacing: 8) {
            // Progress badge
            HStack(spacing: 6) {
                Image(systemName: "figure.cooldown")
                    .font(.caption)
                    .foregroundStyle(.teal)
                Text("今日眼保健操: \(exerciseSessionsToday)/\(recommendedExerciseSessions)")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Button {
                stopTimer()
                onStartExercises?()
            } label: {
                Label("开始眼保健操", systemImage: "eye.trianglebadge.exclamationmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [.teal, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }

    private func startCountdownTimer() {
        // B6: defensively tear down any existing Timer before scheduling a
        // new one. If `onAppear` ever slips past the entry guard (e.g. test
        // harness, future refactor), the old Timer would otherwise stay on
        // the run loop and double the decrement rate.
        timer?.invalidate()
        timer = nil
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                if remainingSeconds > 0 {
                    withAnimation {
                        remainingSeconds -= 1
                    }
                    // Voice countdown for last 5 seconds (v3.2).
                    // Only primary screen speaks — otherwise N monitors → N speech overlaps.
                    if isPrimary && remainingSeconds <= 5 && remainingSeconds > 0 {
                        SoundManager.shared.speakCountdown(remainingSeconds)
                    }
                }
                if remainingSeconds <= 0 {
                    Log.notification.info("FullScreenOverlay countdown reached 0 id=\(instanceID.uuidString) isPrimary=\(isPrimary) hasCompleted=\(hasCompleted)")
                    // Gate completion side-effects on primary + first-fire.
                    // Without this guard, double monitors caused 2x "休息结束" speech (B2).
                    if isPrimary && !hasCompleted {
                        hasCompleted = true
                        SoundManager.shared.speakBreakComplete()
                        stopTimer()
                        onBreakTaken()
                    } else {
                        // Secondary screens just stop their local timer; primary's
                        // onBreakTaken → dismissFullScreen will tear down all windows.
                        stopTimer()
                    }
                }
            }
        }
        Log.notification.debug("FullScreenOverlay timer started id=\(instanceID.uuidString); will tick every 1.0s for \(remainingSeconds)s")
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
