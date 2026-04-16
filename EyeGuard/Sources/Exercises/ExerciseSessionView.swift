import SwiftUI

/// A full exercise session view that guides the user through a sequence
/// of eye exercises during break time.
///
/// Session flow:
/// 1. Intro screen with mascot greeting
/// 2. Sequential exercises with animated instructions
/// 3. Progress bar showing overall session progress
/// 4. Completion celebration with mascot
///
/// Total session duration: 3–5 minutes depending on exercises.
struct ExerciseSessionView: View {

    /// Callback when the session completes or is dismissed.
    let onComplete: @MainActor () -> Void

    /// Callback when the user skips the entire session.
    let onSkip: @MainActor () -> Void

    // MARK: - State

    @State private var sessionPhase: SessionPhase = .intro
    @State private var currentExerciseIndex: Int = 0
    @State private var currentStep: Int = -1
    @State private var remainingSeconds: Int = 0
    @State private var totalSessionSeconds: Int = 0
    @State private var elapsedSessionSeconds: Int = 0
    @State private var countdownTimer: Timer?
    @State private var appeared: Bool = false
    @State private var mascotPupilOffset: CGSize = .zero

    /// Whether TTS audio guidance is enabled (v2.4).
    @State private var isAudioGuidanceEnabled: Bool = true

    /// The exercises to perform in this session.
    private let exercises = EyeExercise.allCases

    // MARK: - Session Phase

    private enum SessionPhase {
        case intro
        case exercising
        case completed
    }

    // MARK: - Computed

    /// Overall session progress (0.0–1.0).
    private var sessionProgress: Double {
        guard totalSessionSeconds > 0 else { return 0 }
        return Double(elapsedSessionSeconds) / Double(totalSessionSeconds)
    }

    /// The current exercise being performed.
    private var currentExercise: EyeExercise {
        exercises[min(currentExerciseIndex, exercises.count - 1)]
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            switch sessionPhase {
            case .intro:
                introView

            case .exercising:
                exercisingView

            case .completed:
                completedView
            }
        }
        .frame(maxWidth: 460)  // Content width limit for fullscreen mode (feature-005)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.thickMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            // Close button always visible
            Button(action: onSkip) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .buttonStyle(.plain)
            .padding(12)
        }
        .scaleEffect(appeared ? 1.0 : 0.95)
        .opacity(appeared ? 1.0 : 0)
        .colorScheme(.dark)  // Force dark mode for consistent text on dark overlay
        .onExitCommand {
            onSkip()
        }
        .onAppear {
            calculateTotalDuration()
            withAnimation(.spring(duration: 0.4)) {
                appeared = true
            }
        }
        .onDisappear {
            stopCountdown()
            SoundManager.shared.stopSpeaking()
        }
    }

    // MARK: - Intro View

    private var introView: some View {
        VStack(spacing: 16) {
            // Mascot with greeting
            VStack(spacing: 6) {
                MascotView(
                    state: .idle,
                    restingMode: .sleeping,
                    pupilOffset: .zero,
                    bounceOffset: -4,
                    isHighScore: true
                )
                .scaleEffect(1.3)
                .frame(height: 80)

                Text("👋 眼保健操时间到！")
                    .font(.title3.bold())
                    .foregroundStyle(.primary)

                Text("Eye Exercise Time!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 16)

            // Session info
            VStack(spacing: 6) {
                Text("共 \(exercises.count) 组练习")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("预计时间：约 \(totalSessionSeconds / 60) 分 \(totalSessionSeconds % 60) 秒")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                // Exercise list preview
                exerciseListPreview
            }

            Spacer(minLength: 16)
                .frame(maxHeight: 40)  // Limit whitespace between list and buttons (BUG-005)

            // Buttons
            VStack(spacing: 10) {
                // Audio guidance toggle (v2.4)
                Toggle(isOn: $isAudioGuidanceEnabled) {
                    Label("语音指导", systemImage: "speaker.wave.2")
                        .font(.subheadline)
                }
                .toggleStyle(.switch)
                .padding(.horizontal, 24)

                Button(action: startSession) {
                    Label("开始练习", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
                .controlSize(.large)

                Button(action: onSkip) {
                    Text("跳过")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Exercise List Preview

    private var exerciseListPreview: some View {
        VStack(spacing: 4) {
            ForEach(Array(exercises.enumerated()), id: \.element) { index, exercise in
                HStack(spacing: 8) {
                    Image(systemName: exercise.iconName)
                        .font(.caption)
                        .frame(width: 20)
                        .foregroundStyle(.teal)

                    Text(exercise.name)
                        .font(.caption)
                        .foregroundStyle(.primary)

                    Text(exercise.chineseName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(exercise.duration)s")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 8)
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 24)
    }

    // MARK: - Exercising View

    private var exercisingView: some View {
        VStack(spacing: 12) {
            // Top bar with progress
            sessionProgressBar
                .padding(.horizontal, 20)
                .padding(.top, 16)

            // Mascot following exercise
            mascotExerciseView
                .frame(height: 80)

            // Exercise content
            ExerciseView(
                exercise: currentExercise,
                currentStep: $currentStep,
                remainingSeconds: $remainingSeconds
            )

            // Exercise navigation
            exerciseNavigation
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
    }

    // MARK: - Session Progress Bar

    private var sessionProgressBar: some View {
        VStack(spacing: 6) {
            // Exercise indicators
            HStack(spacing: 4) {
                ForEach(Array(exercises.enumerated()), id: \.element) { index, exercise in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(exerciseIndicatorColor(for: index))
                        .frame(height: 4)
                }
            }

            // Progress text
            HStack {
                Text("第 \(currentExerciseIndex + 1)/\(exercises.count) 组")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(Int(sessionProgress * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.teal)
            }
        }
    }

    private func exerciseIndicatorColor(for index: Int) -> Color {
        if index < currentExerciseIndex {
            return .teal
        } else if index == currentExerciseIndex {
            return .teal.opacity(0.5)
        } else {
            return .gray.opacity(0.3)
        }
    }

    // MARK: - Mascot Exercise View

    private var mascotExerciseView: some View {
        MascotView(
            state: .resting,
            restingMode: .exercising,
            pupilOffset: mascotPupilOffset
        )
        .scaleEffect(0.9)
        .onChange(of: remainingSeconds) {
            updateMascotPupil()
        }
    }

    // MARK: - Exercise Navigation

    private var exerciseNavigation: some View {
        HStack(spacing: 12) {
            // Skip exercise
            Button(action: skipCurrentExercise) {
                Text("跳过")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)

            // Next exercise (or finish)
            if currentExerciseIndex < exercises.count - 1 {
                Button(action: nextExercise) {
                    Label("下一个", systemImage: "forward.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
                .controlSize(.regular)
            } else {
                Button(action: completeSession) {
                    Label("完成", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.regular)
            }
        }
    }

    // MARK: - Completed View

    private var completedView: some View {
        VStack(spacing: 20) {
            Spacer()

            // Celebrating mascot
            MascotView(
                state: .celebrating,
                restingMode: .sleeping,
                bounceOffset: -6
            )
            .scaleEffect(1.3)
            .frame(height: 80)

            VStack(spacing: 8) {
                Text("🎉 太棒了！")
                    .font(.title.bold())
                    .foregroundStyle(.primary)

                Text("眼保健操完成！")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Text("你的眼睛已经得到了充分的放松！")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }

            // Stats
            VStack(spacing: 4) {
                HStack {
                    Text("完成练习：")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(exercises.count) 组")
                        .font(.caption.bold())
                        .foregroundStyle(.teal)
                }
                HStack {
                    Text("用时：")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(elapsedSessionSeconds / 60) 分 \(elapsedSessionSeconds % 60) 秒")
                        .font(.caption.bold())
                        .foregroundStyle(.teal)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(.quaternary.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Spacer()

            Button(action: onComplete) {
                Label("关闭", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Session Control

    private func calculateTotalDuration() {
        totalSessionSeconds = exercises.reduce(0) { $0 + $1.duration }
    }

    private func startSession() {
        withAnimation(.easeInOut(duration: 0.3)) {
            sessionPhase = .exercising
        }
        currentExerciseIndex = 0
        currentStep = 0
        elapsedSessionSeconds = 0
        remainingSeconds = currentExercise.duration
        startCountdown()

        // TTS: announce session start (v2.4, BUG-006: removed manual step speak to avoid double play)
        if isAudioGuidanceEnabled {
            SoundManager.shared.speakExerciseIntro()
            // First step will be spoken by speakStepIfNeeded() on timer tick
        }
    }

    private func nextExercise() {
        stopCountdown()

        guard currentExerciseIndex < exercises.count - 1 else {
            completeSession()
            return
        }

        // Add remaining time as elapsed
        let exerciseDuration = currentExercise.duration
        let timeSpent = exerciseDuration - remainingSeconds
        elapsedSessionSeconds += timeSpent

        withAnimation(.easeInOut(duration: 0.3)) {
            currentExerciseIndex += 1
            currentStep = -1  // Reset to -1 so speakStepIfNeeded triggers step 0 (BUG-006)
        }
        remainingSeconds = currentExercise.duration
        startCountdown()

        // TTS: transition sound + encouragement (BUG-006: removed manual step speak)
        if isAudioGuidanceEnabled {
            SoundManager.shared.onExerciseStepTransition()
            // Encouragement at ~60% through the session
            let encouragementIndex = max(1, exercises.count * 3 / 5)
            if currentExerciseIndex == encouragementIndex {
                SoundManager.shared.speakEncouragement()
            }
            // First step will be spoken by speakStepIfNeeded() on timer tick
        }
    }

    private func skipCurrentExercise() {
        // Clear any queued TTS from the skipped exercise
        SoundManager.shared.stopSpeaking()

        // Count skipped exercise time as elapsed
        let exerciseDuration = currentExercise.duration
        let timeSpent = exerciseDuration - remainingSeconds
        elapsedSessionSeconds += timeSpent

        nextExercise()
    }

    private func completeSession() {
        stopCountdown()
        SoundManager.shared.stopSpeaking()
        let exerciseDuration = currentExercise.duration
        let timeSpent = exerciseDuration - remainingSeconds
        elapsedSessionSeconds += timeSpent

        withAnimation(.easeInOut(duration: 0.3)) {
            sessionPhase = .completed
        }

        // TTS: celebration (v2.4)
        if isAudioGuidanceEnabled {
            SoundManager.shared.onExerciseComplete()
        } else {
            SoundManager.shared.play(.breakComplete)
        }
    }

    // MARK: - Countdown Timer

    private func startCountdown() {
        stopCountdown()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                if remainingSeconds > 0 {
                    withAnimation {
                        remainingSeconds -= 1
                    }
                    elapsedSessionSeconds += 1

                    // TTS: speak step instructions at transition points (v2.4)
                    if isAudioGuidanceEnabled {
                        speakStepIfNeeded()
                    }
                }

                if remainingSeconds <= 0 {
                    // Auto-advance to next exercise
                    if currentExerciseIndex < exercises.count - 1 {
                        nextExercise()
                    } else {
                        completeSession()
                    }
                }
            }
        }
    }

    private func stopCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    // MARK: - TTS Step Guidance (v2.4)

    /// Speaks the current exercise step instruction at transition boundaries.
    /// Maps elapsed time to instruction steps and speaks when entering a new step.
    /// TTS utterances are queued by AVSpeechSynthesizer when overlapping.
    private func speakStepIfNeeded() {
        let exercise = currentExercise
        let instructions = exercise.instructionsChinese
        guard !instructions.isEmpty else { return }

        let exerciseDuration = exercise.duration
        let elapsed = exerciseDuration - remainingSeconds

        // Minimum 8s per step to ensure TTS can finish Chinese speech + chime (BUG-006)
        let stepDuration = max(8, exerciseDuration / instructions.count)
        let stepIndex = min(elapsed / stepDuration, instructions.count - 1)

        // Speak when step index changes, but only if TTS isn't still playing (BUG-006)
        if stepIndex != currentStep && stepIndex < instructions.count
            && !SoundManager.shared.isSpeaking
        {
            currentStep = stepIndex
            SoundManager.shared.onExerciseStepTransition()
            // Small delay to let chime play before speech
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                await MainActor.run {
                    SoundManager.shared.speakInstruction(instructions[stepIndex])
                }
            }
        }
    }

    // MARK: - Mascot Pupil Tracking

    /// Updates the mascot pupil position to follow the current exercise pattern.
    private func updateMascotPupil() {
        let pattern = currentExercise.mascotPupilPattern
        guard !pattern.isEmpty else {
            mascotPupilOffset = .zero
            return
        }

        let exerciseDuration = currentExercise.duration
        let elapsed = exerciseDuration - remainingSeconds
        let pupilRange: CGFloat = 8.0

        // Calculate which pattern step we're on
        var accumulatedTime: Double = 0
        var targetOffset: (Double, Double) = (0, 0)

        for step in pattern {
            accumulatedTime += step.holdSeconds
            if Double(elapsed) < accumulatedTime {
                targetOffset = step.offset
                break
            }
        }

        // If past all steps, use last
        if Double(elapsed) >= accumulatedTime {
            targetOffset = pattern.last?.offset ?? (0, 0)
        }

        withAnimation(.easeInOut(duration: 0.5)) {
            mascotPupilOffset = CGSize(
                width: targetOffset.0 * Double(pupilRange),
                height: targetOffset.1 * Double(pupilRange)
            )
        }
    }
}
