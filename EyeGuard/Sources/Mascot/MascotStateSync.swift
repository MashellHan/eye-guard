import SwiftUI

/// Manages the synchronization between BreakScheduler state and MascotViewModel.
///
/// Extracted from MascotContainerView in v2.1 for better separation of concerns.
/// Redesigned in v3.0: 5-state model with RestingMode sub-states.
/// Handles:
/// - Break event detection (taken/skipped)
/// - Night mode state transitions
/// - Tip rotation (every 30 minutes)
/// - AI insight display (every 2 hours)
/// - Health-score-based mascot expressions
enum MascotStateSync {

    /// Starts the periodic state synchronization loop.
    ///
    /// Runs every 2 seconds, checking scheduler state and updating
    /// the mascot view model accordingly.
    @MainActor
    static func start(viewModel: MascotViewModel, scheduler: BreakScheduler) {
        Task { @MainActor in
            // Initial greeting
            viewModel.showMessage("Hi! 我是阿普 👋")

            // Track previous break event counts for change detection
            var lastBreaksTaken = scheduler.breaksTakenToday
            var lastBreaksSkipped = scheduler.breaksSkippedToday
            var celebrationEndTime: Date?
            var wasBreakInProgress = false

            // Tip rotation: show a tip every 60 minutes (1800 ticks at 2-sec interval)
            var ticksSinceLastTip: Int = 0
            let tipRotationTicks: Int = 1800  // 60 min x 60 sec / 2 sec per tick

            // Night mode: show night screen time every 15 minutes (450 ticks)
            var ticksSinceLastNightMessage: Int = 0
            let nightMessageTicks: Int = 450  // 15 min x 60 sec / 2 sec per tick

            // AI insight: show an AI insight every 2 hours (3600 ticks at 2-sec interval)
            var ticksSinceLastInsight: Int = 0
            let insightTicks: Int = 3600  // 2 hr x 60 min x 60 sec / 2 sec per tick
            let insightGenerator = InsightGenerator()

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
                        if viewModel.mascotState == .resting && viewModel.restingMode == .sleeping {
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
                    if viewModel.mascotState == .idle {
                        let tip = TipDatabase.randomTip()
                        viewModel.showMessage(tip.shortBubbleText, duration: 15)
                        // Play tip rotation bell (v1.6)
                        SoundManager.shared.onTipRotation()
                    }
                }

                // AI insight rotation (v1.8) — every 2 hours
                ticksSinceLastInsight += 1
                if ticksSinceLastInsight >= insightTicks {
                    ticksSinceLastInsight = 0
                    if viewModel.mascotState == .idle {
                        let hour = Calendar.current.component(.hour, from: .now)
                        let insight = insightGenerator.generateMascotInsight(
                            screenTime: scheduler.totalScreenTimeToday,
                            breaksTaken: scheduler.breaksTakenToday,
                            breaksScheduled: scheduler.breaksTakenToday + scheduler.breaksSkippedToday,
                            healthScore: scheduler.currentHealthScore,
                            hour: hour
                        )
                        viewModel.showMessage(insight, duration: 20)
                    }
                }

                // Check for break-in-progress (resting/exercising state)
                if scheduler.isBreakInProgress && !wasBreakInProgress {
                    wasBreakInProgress = true
                    viewModel.restingMode = .exercising
                    viewModel.transition(to: .resting)
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
                    // After celebration, go to idle with high score flag
                    viewModel.isHighScore = scheduler.currentHealthScore >= 80
                    viewModel.transition(to: .idle)
                    continue
                }

                updateMascotState(viewModel: viewModel, scheduler: scheduler)
            }
        }
    }

    // MARK: - State Mapping

    /// Maps BreakScheduler state to MascotState.
    /// Uses NightModeManager for night detection (v1.4).
    @MainActor
    private static func updateMascotState(viewModel: MascotViewModel, scheduler: BreakScheduler) {
        // Night mode check via NightModeManager (v1.4)
        if NightModeManager.shared.isNightModeActive {
            if viewModel.mascotState != .resting || viewModel.restingMode != .sleeping {
                viewModel.restingMode = .sleeping
                viewModel.transition(to: .resting)
                viewModel.showMessage(NightModeManager.shared.randomNightMessage())
            }
            return
        }

        // Active break notification — mascot should alert
        if let nextBreak = scheduler.nextScheduledBreak {
            // Break is due (time ran out)
            if scheduler.timeUntilNextBreak <= 0 {
                let isExercising = viewModel.mascotState == .resting && viewModel.restingMode == .exercising
                if viewModel.mascotState != .alerting && !isExercising {
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
        viewModel.isHighScore = score >= 80

        if score >= 80 {
            if viewModel.mascotState != .idle {
                viewModel.transition(to: .idle)
            } else {
                // Occasionally show encouragement when score is good
                if Int.random(in: 0..<450) == 0 {
                    viewModel.showMessage("做得好！继续保持 💪")
                }
            }
        } else if score < 65 {
            // Score 50-64: mascot shows concern (was < 50, raised for better UX feedback)
            if viewModel.mascotState != .concerned {
                viewModel.transition(to: .concerned)
                viewModel.showMessage("记得休息哦 👀")
            }
        } else {
            // Score 65-79: idle but without sparkle — subdued appearance
            if viewModel.mascotState != .idle {
                viewModel.isHighScore = false
                viewModel.transition(to: .idle)
            }
        }
    }

    /// Returns the appropriate break alert message based on break type.
    private static func breakAlertMessage(for breakType: BreakType) -> String {
        switch breakType {
        case .micro:
            return "👁️ 阿普说：该休息眼睛了！看看远处20秒"
        case .macro:
            return "☕ 阿普说：休息一下吧！站起来活动5分钟"
        case .mandatory:
            return "🚶 阿普说：该站起来活动了！休息15分钟"
        }
    }
}
