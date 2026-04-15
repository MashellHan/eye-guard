import SwiftUI
import Observation

/// Observable state controller for the mascot, driving animations and
/// state transitions from a single source of truth.
///
/// Redesigned in v3.0: removed arm waving, added eyelid closedness
/// (continuous 0-1), pupil dilation, resting mode, alert glow,
/// and spring-based animations throughout.
@Observable
@MainActor
final class MascotViewModel {
    var mascotState: MascotState = .idle
    var restingMode: RestingMode = .sleeping
    var showBubble: Bool = false
    var bubbleText: String = ""
    var eyelidClosedness: CGFloat = 0
    var breathScale: CGFloat = 1.0
    var bounceOffset: CGFloat = 0
    var pupilOffset: CGSize = .zero
    /// Eye size multiplier (1.0 = normal, alerting = larger).
    var eyeScale: CGFloat = 1.0
    var isHighScore: Bool = false
    var alertGlowOpacity: Double = 0

    /// Current hand gesture being performed.
    var handGesture: HandGesture = .none

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
    private var pupilTask: Task<Void, Never>?
    private var bubbleTask: Task<Void, Never>?
    private var swayTask: Task<Void, Never>?
    private var celebrateTask: Task<Void, Never>?
    private var alertGlowTask: Task<Void, Never>?
    private var gestureTask: Task<Void, Never>?

    /// Starts all idle animations (breathing + blinking + look-around + gestures).
    func startIdleAnimations() {
        startBreathing()
        startBlinking()
        startIdleLookAround()
        startPeriodicGestures()
    }

    /// Transitions to a new mascot state, updating animations.
    func transition(to newState: MascotState) {
        guard newState != mascotState else { return }
        mascotState = newState

        // Cancel state-specific animations
        bounceTask?.cancel()
        pupilTask?.cancel()
        swayTask?.cancel()
        celebrateTask?.cancel()
        alertGlowTask?.cancel()
        gestureTask?.cancel()

        bounceOffset = 0
        pupilOffset = .zero
        swayOffset = 0
        celebrateScale = 1.0
        celebrateRotation = 0
        alertGlowOpacity = 0
        handGesture = .none

        // Update eye scale for new state
        updateEyeScale(for: newState)

        switch newState {
        case .idle:
            startIdleLookAround()
            startPeriodicGestures()
            withAnimation(MascotAnimations.gentleSpring) {
                eyelidClosedness = 0
            }

        case .concerned:
            withAnimation(MascotAnimations.defaultSpring) {
                eyelidClosedness = 0
            }

        case .alerting:
            startAlertBouncing()
            startAlertGlow()
            withAnimation(MascotAnimations.defaultSpring) {
                eyelidClosedness = 0
            }

        case .resting:
            switch restingMode {
            case .sleeping:
                withAnimation(MascotAnimations.gentleSpring) {
                    eyelidClosedness = 1.0
                }
                pupilOffset = .zero
                startSleepingSway()
            case .exercising:
                withAnimation(MascotAnimations.defaultSpring) {
                    eyelidClosedness = 0
                }
                startExercisePattern()
            }

        case .celebrating:
            startCelebrating()
            withAnimation(MascotAnimations.bouncySpring) {
                eyelidClosedness = 0
            }
        }
    }

    // MARK: - Eye Scale

    private func updateEyeScale(for state: MascotState) {
        let target: CGFloat
        switch state {
        case .idle:         target = 1.0
        case .concerned:    target = 0.9
        case .alerting:     target = 1.3  // Surprised big eyes
        case .resting:      target = 1.0
        case .celebrating:  target = 1.0
        }
        withAnimation(MascotAnimations.defaultSpring) {
            eyeScale = target
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

    /// Triggers a one-time pop-bounce animation when the mascot is revealed from peek mode.
    /// Does not change mascotState — just a visual "pop" effect.
    func triggerPopBounce() {
        withAnimation(MascotAnimations.bouncySpring) {
            bounceOffset = -10
        }
        Task {
            try? await Task.sleep(for: .seconds(0.2))
            guard !Task.isCancelled else { return }
            withAnimation(MascotAnimations.defaultSpring) {
                bounceOffset = 0
            }
        }
    }

    /// Updates pupil position to look toward a mouse position relative to mascot center.
    func updateHoverPupil(mousePosition: CGPoint, mascotCenter: CGPoint) {
        // Only track in states that allow it
        guard mascotState == .idle || mascotState == .concerned else {
            return
        }

        let maxOffset: CGFloat = 3.0
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
                withAnimation(MascotAnimations.gentleSpring) {
                    breathScale = MascotAnimations.breathingScaleMin
                }
                try? await Task.sleep(for: .seconds(MascotAnimations.breathingDuration / 2))
                guard !Task.isCancelled else { return }

                withAnimation(MascotAnimations.gentleSpring) {
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

                // Don't blink while resting in sleep mode (already has closed eyes)
                guard !(mascotState == .resting && restingMode == .sleeping) else { continue }

                // Quick blink: close and open eyelids
                withAnimation(.easeIn(duration: MascotAnimations.blinkDuration / 2)) {
                    eyelidClosedness = 1.0
                }
                try? await Task.sleep(for: .seconds(MascotAnimations.blinkDuration / 2))

                withAnimation(.easeOut(duration: MascotAnimations.blinkDuration / 2)) {
                    eyelidClosedness = 0
                }
                try? await Task.sleep(for: .seconds(MascotAnimations.blinkDuration / 2))
            }
        }
    }

    // MARK: - Bouncing (default)

    private func startBouncing() {
        bounceTask = Task {
            while !Task.isCancelled {
                withAnimation(MascotAnimations.bouncySpring) {
                    bounceOffset = -MascotAnimations.bounceAmplitude
                }
                try? await Task.sleep(for: .seconds(MascotAnimations.bounceDuration / 2))
                guard !Task.isCancelled else { return }

                withAnimation(MascotAnimations.bouncySpring) {
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
                withAnimation(MascotAnimations.bouncySpring) {
                    bounceOffset = -MascotAnimations.alertBounceAmplitude
                }
                try? await Task.sleep(for: .seconds(MascotAnimations.alertBounceDuration / 2))
                guard !Task.isCancelled else { return }

                withAnimation(MascotAnimations.bouncySpring) {
                    bounceOffset = 0
                }
                try? await Task.sleep(for: .seconds(MascotAnimations.alertBounceDuration / 2))
            }
        }
    }

    // MARK: - Alert Glow Pulse

    private func startAlertGlow() {
        alertGlowTask = Task {
            while !Task.isCancelled {
                withAnimation(.easeInOut(duration: MascotAnimations.alertGlowDuration / 2)) {
                    alertGlowOpacity = 0.6
                }
                try? await Task.sleep(for: .seconds(MascotAnimations.alertGlowDuration / 2))
                guard !Task.isCancelled else { return }

                withAnimation(.easeInOut(duration: MascotAnimations.alertGlowDuration / 2)) {
                    alertGlowOpacity = 0.15
                }
                try? await Task.sleep(for: .seconds(MascotAnimations.alertGlowDuration / 2))
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

                withAnimation(MascotAnimations.defaultSpring) {
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

                withAnimation(MascotAnimations.gentleSpring) {
                    pupilOffset = CGSize(width: dx, height: dy)
                }
            }
        }
    }

    // MARK: - Sleeping Sway

    private func startSleepingSway() {
        swayTask = Task {
            while !Task.isCancelled {
                withAnimation(MascotAnimations.gentleSpring) {
                    swayOffset = MascotAnimations.sleepSwayAmplitude
                }
                try? await Task.sleep(for: .seconds(MascotAnimations.sleepSwayDuration / 2))
                guard !Task.isCancelled else { return }

                withAnimation(MascotAnimations.gentleSpring) {
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
                withAnimation(MascotAnimations.bouncySpring) {
                    celebrateScale = MascotAnimations.celebrateScaleMax
                    celebrateRotation = MascotAnimations.celebrateRotation
                }
                try? await Task.sleep(for: .seconds(MascotAnimations.celebratePulseDuration / 2))
                guard !Task.isCancelled else { return }

                withAnimation(MascotAnimations.bouncySpring) {
                    celebrateScale = MascotAnimations.celebrateScaleMin
                    celebrateRotation = -MascotAnimations.celebrateRotation
                }
                try? await Task.sleep(for: .seconds(MascotAnimations.celebratePulseDuration / 2))
            }
        }
    }

    /// Wiggle angle for gesture hand animation.
    var gestureWiggle: Double = 0

    // MARK: - Periodic Eye-Care Gestures

    /// Every 8-15 seconds in idle, perform a random eye-care gesture for 3.5s.
    private func startPeriodicGestures() {
        gestureTask?.cancel()
        gestureTask = Task {
            let gestures: [HandGesture] = [.rubEyes, .lookFar, .eyeExercise]

            // First gesture comes sooner (3-5s) so user sees it quickly
            let firstWait = Double.random(in: 3...5)
            try? await Task.sleep(for: .seconds(firstWait))
            guard !Task.isCancelled else { return }

            while !Task.isCancelled {
                guard mascotState == .idle else {
                    try? await Task.sleep(for: .seconds(2))
                    continue
                }

                let gesture = gestures.randomElement() ?? .rubEyes
                withAnimation(MascotAnimations.bouncySpring) {
                    handGesture = gesture
                }

                // Wiggle animation loop during gesture (3.5 seconds total)
                for _ in 0..<7 {
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeInOut(duration: 0.25)) {
                        gestureWiggle = 12
                    }
                    try? await Task.sleep(for: .seconds(0.25))
                    withAnimation(.easeInOut(duration: 0.25)) {
                        gestureWiggle = -12
                    }
                    try? await Task.sleep(for: .seconds(0.25))
                }

                withAnimation(MascotAnimations.defaultSpring) {
                    handGesture = .none
                    gestureWiggle = 0
                }

                let wait = Double.random(in: 8...15)
                try? await Task.sleep(for: .seconds(wait))
            }
        }
    }
}
