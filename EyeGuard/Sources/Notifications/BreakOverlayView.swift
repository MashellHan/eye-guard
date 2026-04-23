import SwiftUI
import os

/// A beautiful floating overlay view that prompts the user to take an eye break.
///
/// The view displays:
/// - An eye icon with the break type
/// - A title and instructional subtitle
/// - Current health score with motivational text
/// - A countdown timer with progress bar (once break starts)
/// - Buttons controlled by `DismissPolicy` (v2.4):
///   - `.skippable`: "Take Break" + "Skip"
///   - `.postponeOnly`: "Take Break" + "Postpone (N left)"
///   - `.mandatory`: "Take Break" only, auto-starts countdown
struct BreakOverlayView: View {

    // MARK: - Properties

    let breakType: BreakType
    let healthScore: Int
    let dismissPolicy: DismissPolicy
    let postponeCount: Int
    let onTaken: @Sendable () -> Void
    let onSkipped: @Sendable () -> Void
    let onPostponed: @Sendable () -> Void
    let onDismiss: @MainActor () -> Void

    @State private var countdown: Int = 0
    @State private var isBreaking: Bool = false
    @State private var showExercises: Bool = false
    @State private var timer: Timer?
    @State private var appeared: Bool = false
    @State private var shakeTrigger: Bool = false
    @State private var hasCompleted: Bool = false
    @State private var lastSpokenCountdown: Int = -1

    // MARK: - Computed

    /// Break duration as an integer number of seconds.
    private var breakDurationSeconds: Int {
        Int(breakType.duration)
    }

    /// Progress value from 0.0 (just started) to 1.0 (complete).
    private var progress: Double {
        guard breakDurationSeconds > 0 else { return 1.0 }
        return Double(breakDurationSeconds - countdown) / Double(breakDurationSeconds)
    }

    /// Maximum postpones allowed for .postponeOnly policy.
    private var maxPostpones: Int {
        if case .postponeOnly(let maxCount) = dismissPolicy {
            return maxCount
        }
        return 0
    }

    /// Remaining postpones available.
    private var postponesRemaining: Int {
        max(0, maxPostpones - postponeCount)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            iconSection
            titleSection
            healthScoreSection

            if showExercises {
                exerciseSessionSection
            } else if isBreaking {
                countdownSection
            }

            if !showExercises {
                buttonSection
            }
        }
        .padding(24)
        .frame(width: 320, height: 280)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        .scaleEffect(appeared ? 1.0 : 0.95)
        .mandatoryShake(trigger: $shakeTrigger)
        .onExitCommand {
            guard case .mandatory = dismissPolicy else {
                skipBreak()
                return
            }
            shakeTrigger = true
        }
        .onAppear {
            Log.notification.info("BreakOverlay appeared: \(breakType.displayName), policy=\(String(describing: dismissPolicy))")
            withAnimation(.spring(duration: 0.4)) {
                appeared = true
            }
            // Mandatory policy: auto-start countdown immediately
            if case .mandatory = dismissPolicy {
                startBreak()
            }
        }
        .onDisappear {
            Log.notification.info("BreakOverlay disappeared: \(breakType.displayName), countdown=\(countdown)s")
            stopTimer()
        }
    }

    // MARK: - Sections

    private var iconSection: some View {
        Image(systemName: breakType.iconName)
            .font(.system(size: 36))
            .foregroundStyle(.blue)
            .symbolEffect(.pulse, options: .repeating, isActive: isBreaking)
    }

    private var titleSection: some View {
        VStack(spacing: 4) {
            Text("Time for an eye break!")
                .font(.headline)
                .foregroundStyle(.primary)

            Text(instructionText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var healthScoreSection: some View {
        HStack(spacing: 6) {
            Image(systemName: "heart.fill")
                .foregroundStyle(healthScoreColor)
                .font(.caption)
            Text("Your eye health score: \(healthScore)/100")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("—")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(healthScoreMotivation)
                .font(.caption)
                .foregroundStyle(healthScoreColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    /// Health score color based on value.
    private var healthScoreColor: Color {
        switch healthScore {
        case 80...100: return .green
        case 50..<80:  return .yellow
        case 30..<50:  return .orange
        default:       return .red
        }
    }

    /// Motivational text based on health score.
    private var healthScoreMotivation: String {
        switch healthScore {
        case 80...100: return "Keep it up!"
        case 50..<80:  return "Take a break to improve it!"
        case 30..<50:  return "Your eyes need rest!"
        default:       return "Please take a break now!"
        }
    }

    private var countdownSection: some View {
        VStack(spacing: 8) {
            Text("\(countdown)s")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .contentTransition(.numericText())

            ProgressView(value: progress)
                .tint(progressColor)
                .animation(.linear(duration: 0.5), value: progress)
        }
    }

    private var buttonSection: some View {
        Group {
            if !isBreaking {
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Button(action: startBreak) {
                            Label("Take Break", systemImage: "eye")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                        // Dismiss action depends on policy (v2.4)
                        dismissButton
                    }

                    Button(action: startExercises) {
                        Label("Start Eye Exercises 眼保健操", systemImage: "figure.run")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
                    .controlSize(.regular)
                }
            }
        }
    }

    /// Dismiss/skip/postpone button based on dismiss policy (v2.4).
    @ViewBuilder
    private var dismissButton: some View {
        switch dismissPolicy {
        case .skippable:
            Button(action: skipBreak) {
                Text("Skip")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

        case .postponeOnly:
            if postponesRemaining > 0 {
                Button(action: postponeBreak) {
                    Text("Later (\(postponesRemaining) left)")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

        case .mandatory:
            // No dismiss button for mandatory breaks
            EmptyView()
        }
    }

    // MARK: - Exercise Session

    private var exerciseSessionSection: some View {
        ExerciseSessionView(
            onComplete: {
                completeBreak()
            },
            onSkip: {
                showExercises = false
            }
        )
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Helpers

    /// Instruction text varies by break type.
    private var instructionText: String {
        switch breakType {
        case .micro:
            return "Look at something 20 feet (6m) away"
        case .macro:
            return "Stand up, stretch, and rest your eyes"
        case .mandatory:
            return "Take a proper break away from the screen"
        }
    }

    /// Progress bar color changes as the break progresses.
    private var progressColor: Color {
        if progress > 0.75 {
            return .green
        } else if progress > 0.5 {
            return .blue
        } else {
            return .orange
        }
    }

    // MARK: - Actions

    private func startBreak() {
        isBreaking = true
        countdown = breakDurationSeconds
        startCountdownTimer()
    }

    private func startExercises() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showExercises = true
        }
    }

    private func skipBreak() {
        stopTimer()
        onSkipped()
        onDismiss()
    }

    private func postponeBreak() {
        stopTimer()
        onPostponed()
        onDismiss()
    }

    private func startCountdownTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                guard !hasCompleted else { return }
                if countdown > 0 {
                    withAnimation {
                        countdown -= 1
                    }
                    // Voice countdown for last 5 seconds (v3.2)
                    if countdown <= 5 && countdown > 0 && countdown != lastSpokenCountdown {
                        lastSpokenCountdown = countdown
                        SoundManager.shared.speakCountdown(countdown)
                    }
                }

                if countdown <= 0 && !hasCompleted {
                    hasCompleted = true
                    stopTimer()
                    SoundManager.shared.speakBreakComplete()
                    completeBreak()
                }
            }
        }
    }

    private func completeBreak() {
        stopTimer()
        onTaken()
        onDismiss()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
