import SwiftUI

/// Container view combining the mascot character with a speech bubble.
///
/// Manages the `MascotViewModel` lifecycle, applies breathing scale,
/// and hosts the speech bubble above the mascot.
/// Wires break events from the scheduler to mascot state transitions.
///
/// State synchronization logic extracted to `MascotStateSync` in v2.1.
struct MascotContainerView: View {
    @State private var viewModel = MascotViewModel()

    /// External binding to the BreakScheduler for state synchronization.
    let scheduler: BreakScheduler

    /// Callback for tap on the mascot.
    var onTap: (@MainActor () -> Void)?

    /// Callback for hover state changes.
    var onHoverChanged: (@MainActor (Bool) -> Void)?

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

    /// Callback for "Dashboard" from mascot menu.
    var onDashboard: (@MainActor () -> Void)?

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
                restingMode: viewModel.restingMode,
                eyelidClosedness: viewModel.eyelidClosedness,
                pupilOffset: viewModel.pupilOffset,
                bounceOffset: viewModel.bounceOffset,
                eyeScale: viewModel.eyeScale,
                isHighScore: viewModel.isHighScore,
                alertGlowOpacity: viewModel.alertGlowOpacity,
                handGesture: viewModel.handGesture,
                gestureWiggle: viewModel.gestureWiggle
            )
            .scaleEffect(viewModel.breathScale * viewModel.celebrateScale)
            .rotationEffect(.degrees(viewModel.celebrateRotation))
            .offset(x: viewModel.swayOffset)
        }
        .frame(width: 120, height: 130)
        .onHover { isHovering in
            onHoverChanged?(isHovering)
        }
        .onTapGesture(count: 1) {
            onTap?()
        }
        .contextMenu {
            mascotContextMenu
        }
        .onAppear {
            viewModel.startIdleAnimations()
            MascotStateSync.start(viewModel: viewModel, scheduler: scheduler)
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
            onDashboard?()
        } label: {
            Label("Dashboard 数据面板", systemImage: "chart.bar")
        }

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
}
