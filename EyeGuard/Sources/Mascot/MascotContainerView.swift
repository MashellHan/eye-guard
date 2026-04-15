import SwiftUI
import Observation

/// Observable state controller for the mascot, driving animations and
/// state transitions from a single source of truth.
@Observable
@MainActor
final class MascotViewModel {
    var mascotState: MascotState = .idle
    var showBubble: Bool = false
    var bubbleText: String = ""
    var isBlinking: Bool = false
    var breathScale: CGFloat = 1.0
    var bounceOffset: CGFloat = 0
    var waveAngle: Double = 0
    var pupilOffset: CGSize = .zero

    /// Internal animation tasks — cancelled on state change.
    private var blinkTask: Task<Void, Never>?
    private var breathTask: Task<Void, Never>?
    private var bounceTask: Task<Void, Never>?
    private var waveTask: Task<Void, Never>?
    private var pupilTask: Task<Void, Never>?
    private var bubbleTask: Task<Void, Never>?

    /// Starts all idle animations (breathing + blinking + look-around).
    func startIdleAnimations() {
        startBreathing()
        startBlinking()
        startIdleLookAround()
    }

    /// Transitions to a new mascot state, updating animations.
    func transition(to newState: MascotState) {
        guard newState != mascotState else { return }
        mascotState = newState

        // Cancel state-specific animations
        bounceTask?.cancel()
        waveTask?.cancel()
        pupilTask?.cancel()

        bounceOffset = 0
        waveAngle = 0
        pupilOffset = .zero

        switch newState {
        case .idle:
            startIdleLookAround()

        case .happy:
            break // Just expression, breathing continues

        case .concerned:
            break // Just expression change

        case .alerting:
            startBouncing()
            startWaving()

        case .sleeping:
            pupilOffset = .zero

        case .exercising:
            startExercisePattern()

        case .celebrating:
            startBouncing()
        }
    }

    /// Shows the speech bubble with a message for a set duration.
    func showMessage(_ text: String, duration: Double = MascotAnimations.bubbleDisplayDuration) {
        bubbleTask?.cancel()
        bubbleText = text
        showBubble = true

        bubbleTask = Task {
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            showBubble = false
        }
    }

    /// Hides the speech bubble immediately.
    func hideBubble() {
        bubbleTask?.cancel()
        showBubble = false
    }

    // MARK: - Breathing

    private func startBreathing() {
        breathTask?.cancel()
        breathTask = Task {
            while !Task.isCancelled {
                withAnimation(.easeInOut(duration: MascotAnimations.breathingDuration / 2)) {
                    breathScale = MascotAnimations.breathingScaleMin
                }
                try? await Task.sleep(for: .seconds(MascotAnimations.breathingDuration / 2))
                guard !Task.isCancelled else { return }

                withAnimation(.easeInOut(duration: MascotAnimations.breathingDuration / 2)) {
                    breathScale = MascotAnimations.breathingScaleMax
                }
                try? await Task.sleep(for: .seconds(MascotAnimations.breathingDuration / 2))
            }
        }
    }

    // MARK: - Blinking

    private func startBlinking() {
        blinkTask?.cancel()
        blinkTask = Task {
            while !Task.isCancelled {
                let interval = MascotAnimations.blinkInterval
                    + Double.random(in: -MascotAnimations.blinkVariance...MascotAnimations.blinkVariance)
                try? await Task.sleep(for: .seconds(max(interval, 1.0)))
                guard !Task.isCancelled else { return }

                // Don't blink while sleeping (already has closed eyes)
                guard mascotState != .sleeping else { continue }

                isBlinking = true
                try? await Task.sleep(for: .seconds(MascotAnimations.blinkDuration))
                isBlinking = false
            }
        }
    }

    // MARK: - Bouncing

    private func startBouncing() {
        bounceTask = Task {
            while !Task.isCancelled {
                withAnimation(.easeInOut(duration: MascotAnimations.bounceDuration / 2)) {
                    bounceOffset = -MascotAnimations.bounceAmplitude
                }
                try? await Task.sleep(for: .seconds(MascotAnimations.bounceDuration / 2))
                guard !Task.isCancelled else { return }

                withAnimation(.easeInOut(duration: MascotAnimations.bounceDuration / 2)) {
                    bounceOffset = 0
                }
                try? await Task.sleep(for: .seconds(MascotAnimations.bounceDuration / 2))
            }
        }
    }

    // MARK: - Arm Waving

    private func startWaving() {
        waveTask = Task {
            while !Task.isCancelled {
                withAnimation(.easeInOut(duration: MascotAnimations.waveDuration / 2)) {
                    waveAngle = MascotAnimations.waveAmplitude
                }
                try? await Task.sleep(for: .seconds(MascotAnimations.waveDuration / 2))
                guard !Task.isCancelled else { return }

                withAnimation(.easeInOut(duration: MascotAnimations.waveDuration / 2)) {
                    waveAngle = -MascotAnimations.waveAmplitude
                }
                try? await Task.sleep(for: .seconds(MascotAnimations.waveDuration / 2))
            }
        }
    }

    // MARK: - Eye Exercise Pattern

    private func startExercisePattern() {
        pupilTask = Task {
            let pattern = MascotAnimations.exercisePattern
            let range = MascotAnimations.pupilRange
            var index = 0

            while !Task.isCancelled {
                let target = pattern[index % pattern.count]
                let offset = CGSize(
                    width: target.width * range,
                    height: target.height * range
                )

                withAnimation(.easeInOut(duration: MascotAnimations.exerciseStepDuration)) {
                    pupilOffset = offset
                }
                try? await Task.sleep(for: .seconds(MascotAnimations.exerciseStepDuration))
                index += 1
            }
        }
    }

    // MARK: - Idle Look-Around

    private func startIdleLookAround() {
        pupilTask?.cancel()
        pupilTask = Task {
            let range = MascotAnimations.idlePupilRange
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(MascotAnimations.idleLookInterval))
                guard !Task.isCancelled else { return }

                let dx = CGFloat.random(in: -range...range)
                let dy = CGFloat.random(in: -range...range)

                withAnimation(.easeInOut(duration: 0.6)) {
                    pupilOffset = CGSize(width: dx, height: dy)
                }
            }
        }
    }
}

/// Container view combining the mascot character with a speech bubble.
///
/// Manages the `MascotViewModel` lifecycle, applies breathing scale,
/// and hosts the speech bubble above the mascot.
struct MascotContainerView: View {
    @State private var viewModel = MascotViewModel()

    /// External binding to the BreakScheduler for state synchronization.
    let scheduler: BreakScheduler

    var body: some View {
        VStack(spacing: 4) {
            if viewModel.showBubble {
                SpeechBubbleView(text: viewModel.bubbleText)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.easeInOut(duration: MascotAnimations.bubbleFadeDuration), value: viewModel.showBubble)
            }

            MascotView(
                state: viewModel.mascotState,
                isBlinking: viewModel.isBlinking,
                pupilOffset: viewModel.pupilOffset,
                bounceOffset: viewModel.bounceOffset,
                waveAngle: viewModel.waveAngle
            )
            .scaleEffect(viewModel.breathScale)
        }
        .frame(width: 120, height: 130)
        .onAppear {
            viewModel.startIdleAnimations()
            startStateSync()
        }
    }

    // MARK: - State Synchronization

    /// Periodically checks BreakScheduler state and updates mascot accordingly.
    private func startStateSync() {
        Task { @MainActor in
            // Initial greeting
            viewModel.showMessage("Hi! 我是护眼精灵 👋")

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                updateMascotState()
            }
        }
    }

    /// Maps BreakScheduler state to MascotState.
    private func updateMascotState() {
        // Late night check (after 10 PM or before 6 AM)
        let hour = Calendar.current.component(.hour, from: .now)
        if hour >= 22 || hour < 6 {
            viewModel.transition(to: .sleeping)
            return
        }

        // Break approaching — less than 2 minutes remaining
        if let nextBreak = scheduler.nextScheduledBreak {
            if scheduler.timeUntilNextBreak <= 120 && scheduler.timeUntilNextBreak > 0 {
                if viewModel.mascotState != .concerned {
                    viewModel.transition(to: .concerned)
                    let breakName = nextBreak.displayName
                    viewModel.showMessage("快要到\(breakName)了…")
                }
                return
            }
        }

        // Health score based states
        let score = scheduler.currentHealthScore

        if score >= 80 {
            if viewModel.mascotState != .happy && viewModel.mascotState != .idle {
                viewModel.transition(to: .happy)
            } else if viewModel.mascotState == .idle {
                // Occasionally switch to happy when score is good
                if Int.random(in: 0..<30) == 0 {
                    viewModel.transition(to: .happy)
                    viewModel.showMessage("做得好！继续保持 💪")
                }
            }
        } else if score < 50 {
            if viewModel.mascotState != .concerned {
                viewModel.transition(to: .concerned)
                viewModel.showMessage("记得休息哦 👀")
            }
        } else {
            if viewModel.mascotState != .idle {
                viewModel.transition(to: .idle)
            }
        }
    }
}
