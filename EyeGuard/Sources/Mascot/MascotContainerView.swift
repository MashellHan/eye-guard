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

/// Container view combining the mascot character with a speech bubble.
///
/// Manages the `MascotViewModel` lifecycle, applies breathing scale,
/// and hosts the speech bubble above the mascot.
/// Wires break events from the scheduler to mascot state transitions.
struct MascotContainerView: View {
    @State private var viewModel = MascotViewModel()

    /// External binding to the BreakScheduler for state synchronization.
    let scheduler: BreakScheduler

    /// Callback for "Take Break Now" from mascot menu.
    var onTakeBreak: (@MainActor () -> Void)?

    /// Callback for "Snooze 5 min" from mascot menu.
    var onSnooze: (@MainActor () -> Void)?

    /// Callback for "Generate Report" from mascot menu.
    var onGenerateReport: (@MainActor () -> Void)?

    /// Callback for "Start Eye Exercises" from mascot menu.
    var onStartExercises: (@MainActor () -> Void)?

    /// Callback for "Show Eye Tip" from mascot menu.
    var onShowTip: (@MainActor () -> Void)?

    var body: some View {
        VStack(spacing: 4) {
            if viewModel.showBubble {
                SpeechBubbleView(
                    text: viewModel.bubbleText,
                    isNightMode: NightModeManager.shared.isNightModeActive
                )
                    .transition(.scale.combined(with: .opacity))
                    .animation(
                        .easeInOut(duration: MascotAnimations.bubbleFadeDuration),
                        value: viewModel.showBubble
                    )
            }

            MascotView(
                state: viewModel.mascotState,
                isBlinking: viewModel.isBlinking,
                pupilOffset: viewModel.pupilOffset,
                bounceOffset: viewModel.bounceOffset,
                waveAngle: viewModel.waveAngle
            )
            .scaleEffect(viewModel.breathScale * viewModel.celebrateScale)
            .rotationEffect(.degrees(viewModel.celebrateRotation))
            .offset(x: viewModel.swayOffset)
        }
        .frame(width: 120, height: 130)
        .onTapGesture(count: 2) {
            // Double-click: toggle speech bubble
            viewModel.toggleBubble()
        }
        .onTapGesture(count: 1) {
            handleSingleClick()
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            viewModel.toggleBubble()
        }
        .contextMenu {
            mascotContextMenu
        }
        .onAppear {
            viewModel.startIdleAnimations()
            startStateSync()
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private var mascotContextMenu: some View {
        Button {
            onTakeBreak?()
        } label: {
            Label("Take Break Now", systemImage: "eye")
        }

        Button {
            onSnooze?()
        } label: {
            Label("Snooze 5 min", systemImage: "clock.badge.questionmark")
        }

        Button {
            onStartExercises?()
        } label: {
            Label("Eye Exercises 眼保健操", systemImage: "figure.run")
        }

        Button {
            onShowTip?()
        } label: {
            Label("Show Eye Tip 护眼贴士", systemImage: "lightbulb")
        }

        Divider()

        Button {
            onGenerateReport?()
        } label: {
            Label("Generate Report", systemImage: "doc.text")
        }

        Button {
            PreferencesWindowController.shared.showPreferences()
        } label: {
            Label("Settings", systemImage: "gear")
        }

        Divider()

        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Label("Quit EyeGuard", systemImage: "power")
        }
    }

    // MARK: - Click Handling

    private func handleSingleClick() {
        // Toggle speech bubble on single click
        viewModel.toggleBubble()
    }

    // MARK: - State Synchronization

    /// Periodically checks BreakScheduler state and updates mascot accordingly.
    /// Also monitors for break events (taken/skipped) to trigger celebrations/concerns.
    /// Rotates eye health tips every 30 minutes (v1.3).
    /// Integrates night mode for late-night guardian behavior (v1.4).
    private func startStateSync() {
        Task { @MainActor in
            // Initial greeting
            viewModel.showMessage("Hi! 我是护眼精灵 👋")

            // Track previous break event counts for change detection
            var lastBreaksTaken = scheduler.breaksTakenToday
            var lastBreaksSkipped = scheduler.breaksSkippedToday
            var celebrationEndTime: Date?
            var wasBreakInProgress = false

            // Tip rotation: show a tip every 30 minutes (900 ticks at 2-sec interval)
            var ticksSinceLastTip: Int = 0
            let tipRotationTicks: Int = 900  // 30 min × 60 sec / 2 sec per tick

            // Night mode: show night screen time every 15 minutes (450 ticks)
            var ticksSinceLastNightMessage: Int = 0
            let nightMessageTicks: Int = 450  // 15 min × 60 sec / 2 sec per tick

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }

                // Update night mode state (v1.4)
                NightModeManager.shared.updateNightModeState()

                // Night mode screen time display (v1.4)
                if NightModeManager.shared.isNightModeActive {
                    ticksSinceLastNightMessage += 1
                    if ticksSinceLastNightMessage >= nightMessageTicks {
                        ticksSinceLastNightMessage = 0
                        if viewModel.mascotState == .sleeping {
                            let msg = NightModeManager.shared.nightScreenTimeMessage()
                            viewModel.showMessage(msg, duration: 10)
                        }
                    }
                } else {
                    ticksSinceLastNightMessage = 0
                }

                // Tip rotation (v1.3)
                ticksSinceLastTip += 1
                if ticksSinceLastTip >= tipRotationTicks {
                    ticksSinceLastTip = 0
                    // Only show tip if mascot is in a calm state
                    if viewModel.mascotState == .idle || viewModel.mascotState == .happy {
                        let tip = TipDatabase.randomTip()
                        viewModel.showMessage(tip.shortBubbleText, duration: 15)
                        // Play tip rotation bell (v1.6)
                        SoundManager.shared.onTipRotation()
                    }
                }

                // Check for break-in-progress (exercising state)
                if scheduler.isBreakInProgress && !wasBreakInProgress {
                    wasBreakInProgress = true
                    viewModel.transition(to: .exercising)
                    if NightModeManager.shared.isNightModeActive {
                        viewModel.showMessage(
                            NightModeManager.shared.randomNightBreakMessage(),
                            duration: 20
                        )
                    } else {
                        viewModel.showMessage("👁️ 跟着做眼保健操吧…", duration: 20)
                    }
                    continue
                }

                if !scheduler.isBreakInProgress && wasBreakInProgress {
                    wasBreakInProgress = false
                    // Break just ended — celebrate and show color suggestion (v1.5)
                    viewModel.transition(to: .celebrating)
                    let colorSuggestion = ColorAnalyzer.shared.suggestionBubbleText()
                    viewModel.showMessage("👏 做得好！\(colorSuggestion)", duration: 10)
                    // Play celebration sound (v1.6)
                    SoundManager.shared.onBreakComplete()
                    celebrationEndTime = Date.now.addingTimeInterval(
                        MascotAnimations.celebrationDisplayDuration
                    )
                    lastBreaksTaken = scheduler.breaksTakenToday
                    continue
                }

                // Check if a new break was taken (counter changed without in-progress)
                if scheduler.breaksTakenToday > lastBreaksTaken {
                    lastBreaksTaken = scheduler.breaksTakenToday
                    viewModel.transition(to: .celebrating)
                    viewModel.showMessage("👏 做得好！眼睛感觉好多了吧")
                    celebrationEndTime = Date.now.addingTimeInterval(
                        MascotAnimations.celebrationDisplayDuration
                    )
                    continue
                }

                // Check if a break was skipped
                if scheduler.breaksSkippedToday > lastBreaksSkipped {
                    lastBreaksSkipped = scheduler.breaksSkippedToday
                    viewModel.transition(to: .concerned)
                    viewModel.showMessage("😢 跳过休息了...眼睛会累的")
                    continue
                }

                // If celebrating, wait until celebration period ends
                if let endTime = celebrationEndTime {
                    if Date.now < endTime {
                        continue
                    }
                    celebrationEndTime = nil
                    viewModel.transition(to: .happy)
                    continue
                }

                updateMascotState()
            }
        }
    }

    /// Maps BreakScheduler state to MascotState.
    /// Uses NightModeManager for night detection (v1.4).
    private func updateMascotState() {
        // Night mode check via NightModeManager (v1.4)
        if NightModeManager.shared.isNightModeActive {
            if viewModel.mascotState != .sleeping {
                viewModel.transition(to: .sleeping)
                viewModel.showMessage(NightModeManager.shared.randomNightMessage())
            }
            return
        }

        // Active break notification — mascot should alert
        if let nextBreak = scheduler.nextScheduledBreak {
            // Break is due (time ran out)
            if scheduler.timeUntilNextBreak <= 0 {
                if viewModel.mascotState != .alerting && viewModel.mascotState != .exercising {
                    viewModel.transition(to: .alerting)
                    let message = breakAlertMessage(for: nextBreak)
                    viewModel.showMessage(message, duration: 15)
                }
                return
            }

            // Break approaching — less than 2 minutes remaining
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

    /// Returns the appropriate break alert message based on break type.
    private func breakAlertMessage(for breakType: BreakType) -> String {
        switch breakType {
        case .micro:
            return "👁️ 该休息眼睛了！看看远处20秒"
        case .macro:
            return "☕ 休息一下吧！站起来活动5分钟"
        case .mandatory:
            return "🚶 该站起来活动了！休息15分钟"
        }
    }
}
