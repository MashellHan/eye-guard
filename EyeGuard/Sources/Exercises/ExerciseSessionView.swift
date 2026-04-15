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
    @State private var currentStep: Int = 0
    @State private var remainingSeconds: Int = 0
    @State private var totalSessionSeconds: Int = 0
    @State private var elapsedSessionSeconds: Int = 0
    @State private var countdownTimer: Timer?
    @State private var appeared: Bool = false
    @State private var mascotPupilOffset: CGSize = .zero

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
        .frame(width: 400, height: 520)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        .scaleEffect(appeared ? 1.0 : 0.95)
        .opacity(appeared ? 1.0 : 0)
        .onAppear {
            calculateTotalDuration()
            withAnimation(.spring(duration: 0.4)) {
                appeared = true
            }
        }
        .onDisappear {
            stopCountdown()
        }
    }

    // MARK: - Intro View

    private var introView: some View {
        VStack(spacing: 20) {
            Spacer()

            // Mascot with greeting
            VStack(spacing: 8) {
                MascotView(
                    state: .happy,
                    pupilOffset: .zero,
                    bounceOffset: -4
                )
                .scaleEffect(1.5)
                .frame(height: 100)

                Text("👋 眼保健操时间到！")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)

                Text("Eye Exercise Time!")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            // Session info
            VStack(spacing: 8) {
                Text("We'll guide you through \(exercises.count) exercises")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Total time: ~\(totalSessionSeconds / 60) min \(totalSessionSeconds % 60) sec")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                // Exercise list preview
                exerciseListPreview
            }

            Spacer()

            // Buttons
            VStack(spacing: 10) {
                Button(action: startSession) {
                    Label("Start Exercises 开始", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
                .controlSize(.large)

                Button(action: onSkip) {
                    Text("Skip 跳过")
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

            Spacer()

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
                Text("Exercise \(currentExerciseIndex + 1)/\(exercises.count)")
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
            state: .exercising,
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
                Text("Skip 跳过")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)

            // Next exercise (or finish)
            if currentExerciseIndex < exercises.count - 1 {
                Button(action: nextExercise) {
                    Label("Next 下一个", systemImage: "forward.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
                .controlSize(.regular)
            } else {
                Button(action: completeSession) {
                    Label("Finish 完成", systemImage: "checkmark.circle.fill")
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
                bounceOffset: -6
            )
            .scaleEffect(1.5)
            .frame(height: 100)

            VStack(spacing: 8) {
                Text("🎉 太棒了！")
                    .font(.title.bold())
                    .foregroundStyle(.primary)

                Text("Exercise Complete!")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                Text("Your eyes feel refreshed and ready!")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)

                Text("你的眼睛已经得到了充分的放松！")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }

            // Stats
            VStack(spacing: 4) {
                HStack {
                    Text("Exercises completed:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(exercises.count)")
                        .font(.caption.bold())
                        .foregroundStyle(.teal)
                }
                HStack {
                    Text("Total time:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(elapsedSessionSeconds / 60)m \(elapsedSessionSeconds % 60)s")
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
                Label("Done 完成", systemImage: "checkmark.circle.fill")
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
            currentStep = 0
        }
        remainingSeconds = currentExercise.duration
        startCountdown()
    }

    private func skipCurrentExercise() {
        // Count skipped exercise time as elapsed
        let exerciseDuration = currentExercise.duration
        let timeSpent = exerciseDuration - remainingSeconds
        elapsedSessionSeconds += timeSpent

        nextExercise()
    }

    private func completeSession() {
        stopCountdown()
        let exerciseDuration = currentExercise.duration
        let timeSpent = exerciseDuration - remainingSeconds
        elapsedSessionSeconds += timeSpent

        withAnimation(.easeInOut(duration: 0.3)) {
            sessionPhase = .completed
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
