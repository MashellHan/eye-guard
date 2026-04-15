import SwiftUI

/// A beautiful floating overlay view that prompts the user to take an eye break.
///
/// The view displays:
/// - An eye icon with the break type
/// - A title and instructional subtitle
/// - A countdown timer with progress bar (once break starts)
/// - "Take Break" and "Skip" buttons
///
/// Behavior flow:
/// 1. User sees the prompt with two buttons
/// 2. Tapping "Take Break" starts the countdown timer
/// 3. Timer counts down from the break duration to 0
/// 4. On completion, `onTaken` is called and the overlay dismisses
/// 5. Tapping "Skip" calls `onSkipped` and dismisses immediately
struct BreakOverlayView: View {

    // MARK: - Properties

    let breakType: BreakType
    let onTaken: @Sendable () -> Void
    let onSkipped: @Sendable () -> Void
    let onDismiss: @MainActor () -> Void

    @State private var countdown: Int = 0
    @State private var isBreaking: Bool = false
    @State private var timer: Timer?
    @State private var appeared: Bool = false

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

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            iconSection
            titleSection

            if isBreaking {
                countdownSection
            }

            buttonSection
        }
        .padding(24)
        .frame(width: 300, height: 220)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        .scaleEffect(appeared ? 1.0 : 0.95)
        .onAppear {
            withAnimation(.spring(duration: 0.4)) {
                appeared = true
            }
        }
        .onDisappear {
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
                HStack(spacing: 12) {
                    Button(action: startBreak) {
                        Label("Take Break", systemImage: "eye")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button(action: skipBreak) {
                        Text("Skip")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
        }
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

    private func skipBreak() {
        stopTimer()
        onSkipped()
        onDismiss()
    }

    private func startCountdownTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                if countdown > 0 {
                    withAnimation {
                        countdown -= 1
                    }
                }

                if countdown <= 0 {
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
