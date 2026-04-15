import SwiftUI
import Observation

/// Observable state controller for the mascot, driving animations and
/// state transitions from a single source of truth.
///
/// Extracted from MascotContainerView in v2.1 for better code organization.
/// Manages all mascot animation tasks (breathing, blinking, bouncing, etc.)
/// and exposes state for the view layer.
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

    /// Horizontal sway offset for sleeping state.
    var swayOffset: CGFloat = 0

    /// Extra scale pulse for celebrating state.
    var celebrateScale: CGFloat = 1.0

    /// Rotation angle for celebrating state.
    var celebrateRotation: Double = 0

    /// Whether mouse hover tracking is overriding pupil position.
    var isHoverTracking: Bool = false

    /// Pupil offset from hover tracking (overrides idle look-around).
    var hoverPupilOffset: CGSize = .zero

    /// Internal animation tasks — cancelled on state change.
    private var blinkTask: Task<Void, Never>?
    private var breathTask: Task<Void, Never>?
    private var bounceTask: Task<Void, Never>?
    private var waveTask: Task<Void, Never>?
    private var pupilTask: Task<Void, Never>?
    private var bubbleTask: Task<Void, Never>?
    private var swayTask: Task<Void, Never>?
    private var celebrateTask: Task<Void, Never>?

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
        swayTask?.cancel()
        celebrateTask?.cancel()

        bounceOffset = 0
        waveAngle = 0
        pupilOffset = .zero
        swayOffset = 0
        celebrateScale = 1.0
        celebrateRotation = 0

        switch newState {
        case .idle:
            startIdleLookAround()

        case .happy:
            break // Just expression, breathing continues

        case .concerned:
            break // Just expression change

        case .alerting:
            startAlertBouncing()
            startWaving()

        case .sleeping:
            pupilOffset = .zero
            startSleepingSway()

        case .exercising:
            startExercisePattern()

        case .celebrating:
            startCelebrating()
        }
    }

    // MARK: - Speech Bubble

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

    /// Toggles speech bubble visibility.
    func toggleBubble() {
        if showBubble {
            hideBubble()
        } else if !bubbleText.isEmpty {
            showBubble = true
        }
    }

    // MARK: - Mouse Tracking

    /// Updates pupil position to look toward a mouse position relative to mascot center.
    ///
    /// - Parameters:
    ///   - mousePosition: The mouse position in screen coordinates.
    ///   - mascotCenter: The mascot center in screen coordinates.
    func updateHoverPupil(mousePosition: CGPoint, mascotCenter: CGPoint) {
        // Only track in states that allow it
        guard mascotState == .idle || mascotState == .happy || mascotState == .concerned else {
            return
        }

        let maxOffset: CGFloat = 4.0 // Max pupil displacement from hover
        let dx = mousePosition.x - mascotCenter.x
        let dy = mousePosition.y - mascotCenter.y
        let distance = sqrt(dx * dx + dy * dy)

        // Only track if mouse is within reasonable range (200pt)
        guard distance < 200 else {
            if isHoverTracking {
                isHoverTracking = false
            }
            return
        }

        isHoverTracking = true

        // Normalize and clamp to max offset
        let scale = min(distance / 100, 1.0) * maxOffset
        let angle = atan2(dy, dx)
        let offsetX = cos(angle) * scale
        // Invert Y because screen Y goes down but SwiftUI Y goes up
        let offsetY = -sin(angle) * scale

        withAnimation(.easeOut(duration: 0.15)) {
            pupilOffset = CGSize(width: offsetX, height: offsetY)
        }
    }

    /// Stops hover tracking and returns to idle pupil behavior.
    func stopHoverTracking() {
        isHoverTracking = false
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

    // MARK: - Bouncing (default)

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

    // MARK: - Alert Bouncing (larger amplitude)

    private func startAlertBouncing() {
        bounceTask = Task {
            while !Task.isCancelled {
                withAnimation(.easeInOut(duration: MascotAnimations.alertBounceDuration / 2)) {
                    bounceOffset = -MascotAnimations.alertBounceAmplitude
                }
                try? await Task.sleep(for: .seconds(MascotAnimations.alertBounceDuration / 2))
                guard !Task.isCancelled else { return }

                withAnimation(.easeInOut(duration: MascotAnimations.alertBounceDuration / 2)) {
                    bounceOffset = 0
                }
                try? await Task.sleep(for: .seconds(MascotAnimations.alertBounceDuration / 2))
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

                // Skip random movement when hover tracking is active
                guard !isHoverTracking else { continue }

                let dx = CGFloat.random(in: -range...range)
                let dy = CGFloat.random(in: -range...range)

                withAnimation(.easeInOut(duration: 0.6)) {
                    pupilOffset = CGSize(width: dx, height: dy)
                }
            }
        }
    }

    // MARK: - Sleeping Sway

    private func startSleepingSway() {
        swayTask = Task {
            while !Task.isCancelled {
                withAnimation(.easeInOut(duration: MascotAnimations.sleepSwayDuration / 2)) {
                    swayOffset = MascotAnimations.sleepSwayAmplitude
                }
                try? await Task.sleep(for: .seconds(MascotAnimations.sleepSwayDuration / 2))
                guard !Task.isCancelled else { return }

                withAnimation(.easeInOut(duration: MascotAnimations.sleepSwayDuration / 2)) {
                    swayOffset = -MascotAnimations.sleepSwayAmplitude
                }
                try? await Task.sleep(for: .seconds(MascotAnimations.sleepSwayDuration / 2))
            }
        }
    }

    // MARK: - Celebrating

    private func startCelebrating() {
        startBouncing()
        celebrateTask = Task {
            while !Task.isCancelled {
                withAnimation(.easeInOut(duration: MascotAnimations.celebratePulseDuration / 2)) {
                    celebrateScale = MascotAnimations.celebrateScaleMax
                    celebrateRotation = MascotAnimations.celebrateRotation
                }
                try? await Task.sleep(for: .seconds(MascotAnimations.celebratePulseDuration / 2))
                guard !Task.isCancelled else { return }

                withAnimation(.easeInOut(duration: MascotAnimations.celebratePulseDuration / 2)) {
                    celebrateScale = MascotAnimations.celebrateScaleMin
                    celebrateRotation = -MascotAnimations.celebrateRotation
                }
                try? await Task.sleep(for: .seconds(MascotAnimations.celebratePulseDuration / 2))
            }
        }
    }
}
