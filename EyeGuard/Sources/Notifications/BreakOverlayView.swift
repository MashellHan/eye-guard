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
    /// Whether this instance owns audio + completion side-effects (B9).
    /// Tier 2 is single-window today, but mandatory escalations briefly run
    /// Tier 2 + Tier 3 in parallel during the 0.3 s dismiss fade — without
    /// this gate both tiers fire `speakCountdown` / `speakBreakComplete`,
    /// producing double TTS. Mirrors the same flag on `FullScreenOverlayView`.
    var isPrimary: Bool = true

    @State private var countdown: Int = 0
    @State private var isBreaking: Bool = false
    @State private var timer: Timer?
    @State private var appeared: Bool = false
    @State private var shakeTrigger: Bool = false
    @State private var hasCompleted: Bool = false
    @State private var lastSpokenCountdown: Int = -1
    /// Set when `.screenDidLock` fires while this overlay is on screen (B10).
    /// Causes the timer loop to bail out and triggers `onDismiss`.
    @State private var dismissedByScreenLock: Bool = false
    /// Stable identifier for this view instance — used in B6 diagnostic
    /// logging to detect repeated `onAppear` / Timer scheduling.
    @State private var instanceID: UUID = UUID()

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

            if isBreaking {
                countdownSection
            }

            buttonSection
        }
        .padding(24)
        .frame(width: 320, height: 280)
        // B1 follow-up: prior fix used opacity 0.35 on top of ultraThinMaterial,
        // which still let bright wallpapers bleed through and white-on-white
        // text. Drop the material entirely — solid dark fill gives WCAG AA
        // contrast on every background.
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.12).opacity(0.92))
        }
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
            Log.notification.info("BreakOverlay appeared id=\(instanceID.uuidString) breakType=\(breakType.displayName) duration=\(breakDurationSeconds)s policy=\(String(describing: dismissPolicy)) isPrimary=\(isPrimary)")
            // B10: if the screen locked between this overlay being scheduled
            // and SwiftUI mounting it, dismiss immediately so we don't leave
            // a Timer running while the user is away.
            if BreakScheduler.isScreenCurrentlyLocked() {
                Log.notification.info("BreakOverlay onAppear aborted — screen already locked id=\(instanceID.uuidString)")
                dismissedByScreenLock = true
                onDismiss()
                return
            }
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
        // B10: react to screen lock anywhere in the lifetime — not just at
        // onAppear. NotificationCenter posts on the main queue so this stays
        // MainActor-safe.
        .onReceive(NotificationCenter.default.publisher(for: .screenDidLock)) { _ in
            guard !dismissedByScreenLock else { return }
            Log.notification.info("BreakOverlay dismiss on .screenDidLock id=\(instanceID.uuidString)")
            dismissedByScreenLock = true
            stopTimer()
            onDismiss()
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
                // B1: scrim guarantees a dark substrate; force white instead
                // of `.primary` so text stays readable on any wallpaper.
                .foregroundStyle(.white)

            Text(instructionText)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
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
                .foregroundStyle(.white.opacity(0.75))
            Text("—")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.75))
            Text(healthScoreMotivation)
                .font(.caption)
                .foregroundStyle(healthScoreColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        // B1: `.quaternary` was nearly invisible on the new dark scrim and
        // still didn't help on light wallpapers without it; a translucent
        // black pill keeps the chip legible in both contexts.
        .background(.black.opacity(0.25))
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
                .foregroundStyle(.white)
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

    /// Tier 2 "Start Eye Exercises" — route through the shared notification
    /// path so all entry points (Tier 2/3 overlays, mascot menu, menu bar
    /// quick action) trigger the same full-screen `ExercisePresenter` window.
    /// Previously this only flipped a local `showExercises` flag, which tried
    /// to render the exercise UI inside the 320pt floating overlay (B4).
    private func startExercises() {
        stopTimer()
        NotificationCenter.default.post(
            name: .startExercisesFromBreak,
            object: nil
        )
        // Treat starting exercises as taking the break — clears the
        // notification and lets the scheduler advance like the Tier 3 path
        // does (BreakScheduler triggers `takeBreakNow` before posting).
        onTaken()
        onDismiss()
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
        // B6: defensively invalidate any prior Timer before scheduling a new
        // one. Both code paths into `startCountdownTimer` (mandatory
        // `.onAppear` auto-start and the manual "Take Break" button) can
        // re-fire if SwiftUI rebuilds the subtree, leaving multiple Timers
        // ticking on the run loop and draining `countdown` N×/sec. The
        // entry-side guard lives here (not in `.onAppear`) so the user-
        // initiated button path also benefits.
        timer?.invalidate()
        timer = nil
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                guard !hasCompleted else { return }
                if countdown > 0 {
                    withAnimation {
                        countdown -= 1
                    }
                    // Voice countdown for last 5 seconds (v3.2).
                    // B9: only the primary instance speaks — silences the
                    // duplicate utterance during Tier 2 → Tier 3 escalation
                    // overlap.
                    if isPrimary && countdown <= 5 && countdown > 0 && countdown != lastSpokenCountdown {
                        lastSpokenCountdown = countdown
                        SoundManager.shared.speakCountdown(countdown)
                    }
                }

                if countdown <= 0 && !hasCompleted {
                    Log.notification.info("BreakOverlay countdown reached 0 id=\(instanceID.uuidString) isPrimary=\(isPrimary)")
                    hasCompleted = true
                    stopTimer()
                    // B9: same primary gate as the countdown branch — without
                    // it Tier 2 + Tier 3 both fire "休息结束" when their
                    // timers cross zero on the same tick.
                    if isPrimary {
                        SoundManager.shared.speakBreakComplete()
                    }
                    completeBreak()
                }
            }
        }
        Log.notification.debug("BreakOverlay timer started id=\(instanceID.uuidString); will tick every 1.0s for \(countdown)s")
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
