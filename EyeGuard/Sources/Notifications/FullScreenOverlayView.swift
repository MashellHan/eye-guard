import SwiftUI

/// Pool of medical tips displayed during full-screen breaks.
private let medicalTips: [String] = [
    "Blink 20 times to refresh your tear film.",
    "Gently massage your temples to relieve eye strain.",
    "Place warm palms over closed eyes for 30 seconds.",
    "Focus on a distant object to relax your ciliary muscles.",
    "Roll your eyes slowly in a circle — 5 times each direction.",
    "Splash cold water on your face to reduce puffiness.",
    "Stretch your neck and shoulders to improve blood flow to your eyes.",
    "Practice the 20-20-20 rule: every 20 min, look 20 ft away for 20 sec.",
    "Stay hydrated — dehydration worsens dry eye symptoms.",
    "Adjust your screen brightness to match your surroundings.",
    "Position your monitor 20-26 inches from your eyes.",
    "Reduce screen glare with an anti-glare filter or repositioning.",
]

/// A full-screen overlay view for Tier 3 mandatory breaks.
///
/// Displayed when the user has been using the computer for 120+ minutes
/// continuously without a proper break. The overlay covers the entire screen
/// with a semi-transparent dark background and blur effect.
///
/// Features:
/// - Large eye icon and warning title
/// - 15-minute countdown with circular progress ring
/// - Health score display
/// - Random medical tip
/// - "Take 15-min Break" primary button (starts locked countdown)
/// - "I Need 5 More Minutes" extension button (max 2 uses)
struct FullScreenOverlayView: View {

    // MARK: - Properties

    /// Current eye health score (0-100).
    let healthScore: Int

    /// Called when the user completes the full break countdown.
    let onBreakTaken: @Sendable () -> Void

    // MARK: - State

    /// Whether the break countdown is actively running.
    @State private var isCountingDown: Bool = false

    /// Remaining seconds in the countdown.
    @State private var remainingSeconds: Int = 15 * 60

    /// Total countdown duration (for progress calculation).
    @State private var totalDuration: Int = 15 * 60

    /// Number of 5-minute extensions used (max 2).
    @State private var extensionsUsed: Int = 0

    /// Timer driving the countdown.
    @State private var timer: Timer?

    /// Controls fade-in appearance animation.
    @State private var appeared: Bool = false

    /// Pulsing animation state for the countdown number.
    @State private var isPulsing: Bool = false

    /// Randomly selected medical tip (stable across re-renders).
    @State private var currentTip: String = medicalTips.randomElement() ?? medicalTips[0]

    // MARK: - Constants

    /// Maximum number of 5-minute extensions allowed.
    private let maxExtensions = 2

    /// Extension duration in seconds.
    private let extensionSeconds = 5 * 60

    // MARK: - Computed

    /// Progress from 0.0 (full time remaining) to 1.0 (complete).
    private var progress: Double {
        guard totalDuration > 0 else { return 1.0 }
        return Double(totalDuration - remainingSeconds) / Double(totalDuration)
    }

    /// Formatted countdown string: "MM:SS".
    private var countdownText: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Health score color based on value.
    private var healthScoreColor: Color {
        if healthScore >= 80 {
            return .green
        } else if healthScore >= 50 {
            return .orange
        } else {
            return .red
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Semi-transparent dark background
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            // Blur effect
            VisualEffectBlur()
                .ignoresSafeArea()

            // Center content
            VStack(spacing: 24) {
                iconSection
                warningSection
                countdownSection
                healthSection
                tipSection
                buttonSection
            }
            .padding(48)
            .frame(maxWidth: 520)
        }
        .opacity(appeared ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) {
                appeared = true
            }
            isPulsing = true
        }
        .onDisappear {
            stopTimer()
        }
    }

    // MARK: - Sections

    private var iconSection: some View {
        Image(systemName: "eye.trianglebadge.exclamationmark")
            .font(.system(size: 80))
            .foregroundStyle(.yellow)
            .symbolEffect(.pulse, options: .repeating, isActive: true)
    }

    private var warningSection: some View {
        VStack(spacing: 8) {
            Text("⚠️ You've been using the screen for over 2 hours!")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("Your eyes need a longer break. Step away for 15 minutes.")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
    }

    private var countdownSection: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(.white.opacity(0.2), lineWidth: 8)
                .frame(width: 160, height: 160)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [.green, .blue, .green],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1.0), value: progress)

            // Countdown text
            Text(countdownText)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .scaleEffect(isPulsing && isCountingDown ? 1.05 : 1.0)
                .animation(
                    .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                    value: isPulsing && isCountingDown
                )
        }
    }

    private var healthSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "heart.fill")
                .foregroundStyle(healthScoreColor)
            Text("Current Eye Health: \(healthScore)/100")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var tipSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.yellow)
            Text(currentTip)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(maxWidth: 440)
        .background(.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var buttonSection: some View {
        VStack(spacing: 12) {
            if !isCountingDown {
                // Primary: Start break
                Button(action: startBreak) {
                    Label("Take 15-min Break", systemImage: "leaf.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: 280)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.large)

                // Secondary: Extension (limited)
                if extensionsUsed < maxExtensions {
                    Button(action: requestExtension) {
                        Text("I Need 5 More Minutes (\(maxExtensions - extensionsUsed) left)")
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.bordered)
                    .tint(.white.opacity(0.6))
                    .controlSize(.small)
                }
            } else {
                Text("Taking a break... your eyes thank you! 👁️")
                    .font(.system(size: 14))
                    .foregroundStyle(.green.opacity(0.9))
            }
        }
    }

    // MARK: - Actions

    private func startBreak() {
        isCountingDown = true
        totalDuration = remainingSeconds
        startCountdownTimer()
    }

    private func requestExtension() {
        guard extensionsUsed < maxExtensions else { return }
        extensionsUsed += 1

        // Dismiss overlay briefly, will be re-triggered by scheduler
        // For now: add 5 minutes to the countdown
        remainingSeconds += extensionSeconds
        totalDuration += extensionSeconds
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
                    completeBreak()
                }
            }
        }
    }

    private func completeBreak() {
        stopTimer()
        onBreakTaken()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Visual Effect Blur (NSVisualEffectView wrapper)

/// Wraps `NSVisualEffectView` for use in SwiftUI, providing a background blur effect.
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
