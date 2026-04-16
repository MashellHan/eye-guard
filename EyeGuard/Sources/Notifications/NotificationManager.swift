import AppKit
import Foundation
import UserNotifications
import os

/// Manages break notifications with mode-aware behavior (v2.4).
///
/// Notification delivery is driven by `BreakBehavior` and `EscalationStrategy`
/// from the active `ReminderModeProfile`, rather than hardcoded tier logic.
///
/// - `.direct` escalation: jump straight to the `entryTier` (no waiting).
/// - `.tiered` escalation: start at system notification, wait, then escalate.
///
/// `DismissPolicy` controls what buttons appear on overlays:
/// - `.skippable`: Skip + Take Break
/// - `.postponeOnly(maxCount:)`: Postpone (limited) + Take Break
/// - `.mandatory`: Take Break only (countdown auto-starts)
///
/// Conforms to `NotificationSending` for testability.
@MainActor
final class NotificationManager: NotificationSending {

    // MARK: - State

    private var escalationTask: Task<Void, Never>?
    private var snoozeTask: Task<Void, Never>?
    private(set) var isNotificationActive: Bool = false

    /// Stored callbacks for the current notification cycle (H4).
    private var onTakenCallback: (@Sendable () -> Void)?
    private var onSkippedCallback: (@Sendable () -> Void)?
    private var onPostponedCallback: (@Sendable (TimeInterval) -> Void)?

    /// Current health score for display in overlays.
    private var currentHealthScore: Int = 100

    /// Active break behavior for the current notification.
    private var activeBehavior: BreakBehavior?

    /// Active break type for the current notification.
    private var activeBreakType: BreakType?

    /// Exercise context for full-screen overlay display (v2.5).
    private var exerciseSessionsToday: Int = 0
    private var recommendedExerciseSessions: Int = 1
    private var onStartExercisesCallback: (@Sendable () -> Void)?

    /// Postpone count per break type (reset when break is taken or skipped).
    private var postponeCountByBreakType: [BreakType: Int] = [:]

    /// Tier 2 floating overlay window controller.
    private let overlayController = OverlayWindowController()

    // MARK: - Singleton

    static let shared = NotificationManager()

    /// Use `setup()` to request notification permissions instead of doing it in init.
    private init() {}

    // MARK: - Public API

    /// Requests notification permission from the user.
    /// Called explicitly during app setup, not in init.
    func setup() {
        requestNotificationPermission()
    }

    /// Sends a break notification using mode-aware behavior (v2.4).
    ///
    /// For `.direct` escalation: jumps straight to the configured `entryTier`.
    /// For `.tiered` escalation: starts at Tier 1 (system), escalates after delays.
    ///
    /// - Parameters:
    ///   - breakType: The type of break to notify about.
    ///   - behavior: Behavioral configuration from the active profile.
    ///   - escalation: Escalation strategy from the active profile.
    ///   - healthScore: Current eye health score (0-100) for overlay display.
    ///   - onTaken: Callback when user acknowledges the break.
    ///   - onSkipped: Callback when user dismisses/skips the break.
    ///   - onPostponed: Callback when user postpones the break.
    func notify(
        breakType: BreakType,
        behavior: BreakBehavior,
        escalation: EscalationStrategy,
        healthScore: Int,
        onTaken: @escaping @Sendable () -> Void,
        onSkipped: @escaping @Sendable () -> Void,
        onPostponed: @escaping @Sendable (TimeInterval) -> Void,
        exerciseSessionsToday: Int = 0,
        recommendedExerciseSessions: Int = 1,
        onStartExercises: (@Sendable () -> Void)? = nil
    ) {
        guard !isNotificationActive else { return }
        isNotificationActive = true
        currentHealthScore = healthScore
        activeBehavior = behavior
        activeBreakType = breakType

        // Store callbacks (H4)
        self.onTakenCallback = onTaken
        self.onSkippedCallback = onSkipped
        self.onPostponedCallback = onPostponed
        self.exerciseSessionsToday = exerciseSessionsToday
        self.recommendedExerciseSessions = recommendedExerciseSessions
        self.onStartExercisesCallback = onStartExercises

        // Play break start sound (v1.6)
        SoundManager.shared.onBreakStart()

        switch escalation {
        case .direct:
            // Jump straight to the configured entry tier
            showTier(behavior.entryTier, breakType: breakType, behavior: behavior)

        case .tiered(let tier1Delay, let tier2Delay):
            // Start at system notification, then escalate
            sendTier1Notification(breakType: breakType)

            escalationTask = Task {
                // Wait for Tier 1 → Tier 2
                try? await Task.sleep(for: .seconds(tier1Delay))
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.showTier(.floating, breakType: breakType, behavior: behavior)
                }

                // Tier 2 → Tier 3 (only for mandatory breaks)
                if breakType == .mandatory {
                    try? await Task.sleep(for: .seconds(tier2Delay))
                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.showTier(.fullScreen, breakType: breakType, behavior: behavior)
                    }

                    // After Tier 3 timeout, invoke onSkipped if still active (H4)
                    try? await Task.sleep(for: .seconds(tier2Delay))
                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.handleEscalationTimeout()
                    }
                } else {
                    // Non-mandatory: after Tier 2 timeout, invoke onSkipped (H4)
                    try? await Task.sleep(for: .seconds(tier2Delay))
                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.handleEscalationTimeout()
                    }
                }
            }
        }
    }

    /// Dismisses the current notification (user took the break).
    /// Invokes the stored `onTaken` callback (H4).
    func acknowledgeBreak() {
        let callback = onTakenCallback
        cancelEscalation()
        dismissAllOverlays()
        clearCallbacks()

        // Play break complete sound (v1.6)
        SoundManager.shared.onBreakComplete()

        // Reset postpone count for this break type
        if let breakType = activeBreakType {
            postponeCountByBreakType[breakType] = 0
        }
        activeBreakType = nil
        activeBehavior = nil

        // Execute callback BEFORE releasing guard to prevent race condition (BUG-POPUP-001 v4)
        callback?()
        isNotificationActive = false
    }

    /// Postpones the current break by the configured delay (v2.4).
    ///
    /// - Parameter breakType: The break type being postponed.
    func postponeBreak(breakType: BreakType) {
        let currentCount = postponeCountByBreakType[breakType, default: 0]
        postponeCountByBreakType[breakType] = currentCount + 1

        let callback = onPostponedCallback
        cancelEscalation()
        dismissAllOverlays()

        Log.notification.info(
            "Postponed \(breakType.displayName) (\(currentCount + 1) times)."
        )

        clearCallbacks()
        activeBreakType = nil
        activeBehavior = nil

        // Execute callback BEFORE releasing guard (BUG-POPUP-001 v4)
        callback?(EyeGuardConstants.postponeDelay)
        isNotificationActive = false
    }

    /// Snoozes the current notification and reschedules after snooze duration (BUG-006).
    ///
    /// - Parameters:
    ///   - breakType: The break type being snoozed.
    ///   - onDue: Callback when snooze expires and break is due again.
    func snooze(breakType: BreakType, onDue: @escaping @Sendable () -> Void) {
        cancelEscalation()
        dismissAllOverlays()
        isNotificationActive = false
        clearCallbacks()

        Log.notification.info(
            "Snoozed \(breakType.displayName) for \(Int(EyeGuardConstants.maxSnoozeDuration))s."
        )

        // Reschedule after snooze duration (BUG-006)
        snoozeTask?.cancel()
        snoozeTask = Task {
            try? await Task.sleep(for: .seconds(EyeGuardConstants.maxSnoozeDuration))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                Log.notification.info(
                    "Snooze expired for \(breakType.displayName), re-notifying."
                )
                onDue()
            }
        }
    }

    // MARK: - Private: Tier Dispatch (v2.4)

    /// Dispatches notification to the correct tier based on the configured entry tier.
    private func showTier(
        _ tier: NotificationTier,
        breakType: BreakType,
        behavior: BreakBehavior
    ) {
        let postponeCount = postponeCountByBreakType[breakType, default: 0]

        switch tier {
        case .system:
            sendTier1Notification(breakType: breakType)

        case .floating:
            overlayController.showBreakOverlay(
                breakType: breakType,
                healthScore: currentHealthScore,
                dismissPolicy: behavior.dismissPolicy,
                postponeCount: postponeCount,
                onTaken: { [weak self] in
                    Task { @MainActor in
                        self?.acknowledgeBreak()
                    }
                },
                onSkipped: { [weak self] in
                    Task { @MainActor in
                        let callback = self?.onSkippedCallback
                        self?.cancelEscalation()
                        self?.dismissAllOverlays()
                        self?.clearCallbacks()
                        self?.activeBreakType = nil
                        self?.activeBehavior = nil
                        // Execute callback BEFORE releasing guard (BUG-POPUP-001 v4)
                        callback?()
                        self?.isNotificationActive = false
                    }
                },
                onPostponed: { [weak self] in
                    Task { @MainActor in
                        guard let self, let bt = self.activeBreakType else { return }
                        self.postponeBreak(breakType: bt)
                    }
                }
            )

            Log.notification.info("Floating overlay shown: \(breakType.displayName)")

        case .fullScreen:
            overlayController.dismiss()

            let exerciseAction: (@Sendable () -> Void)? = onStartExercisesCallback.map { callback in
                { @Sendable [weak self] in
                    Task { @MainActor in
                        self?.cancelEscalation()
                        self?.dismissAllOverlays()
                        self?.clearCallbacks()
                        self?.activeBreakType = nil
                        self?.activeBehavior = nil
                        callback()
                        self?.isNotificationActive = false
                    }
                }
            }

            overlayController.showFullScreenOverlay(
                breakType: breakType,
                healthScore: currentHealthScore,
                dismissPolicy: behavior.dismissPolicy,
                postponeCount: postponeCount,
                exerciseSessionsToday: exerciseSessionsToday,
                recommendedExerciseSessions: recommendedExerciseSessions,
                onTaken: { [weak self] in
                    Task { @MainActor in
                        self?.acknowledgeBreak()
                    }
                },
                onPostponed: { [weak self] in
                    Task { @MainActor in
                        guard let self, let bt = self.activeBreakType else { return }
                        self.postponeBreak(breakType: bt)
                    }
                },
                onStartExercises: exerciseAction
            )

            Log.notification.info("Full-screen overlay shown: \(breakType.displayName)")
        }
    }

    // MARK: - Private: Escalation Timeout (H4)

    /// Called when escalation chain times out without user acknowledgment.
    /// Invokes the stored `onSkipped` callback.
    private func handleEscalationTimeout() {
        let callback = onSkippedCallback
        dismissAllOverlays()
        clearCallbacks()
        activeBreakType = nil
        activeBehavior = nil

        Log.notification.info("Escalation timed out, break skipped.")
        // Execute callback BEFORE releasing guard (BUG-POPUP-001 v4)
        callback?()
        isNotificationActive = false
    }

    /// Clears stored callbacks after they've been invoked or are no longer needed.
    private func clearCallbacks() {
        onTakenCallback = nil
        onSkippedCallback = nil
        onPostponedCallback = nil
        onStartExercisesCallback = nil
    }

    // MARK: - Private: Notification Permission

    private func requestNotificationPermission() {
        guard Bundle.main.bundleIdentifier != nil else {
            Log.notification.warning("Not running in an app bundle. Notifications disabled.")
            return
        }
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound]
        ) { granted, error in
            if let error {
                Log.notification.error("Permission error: \(error.localizedDescription)")
            } else if granted {
                Log.notification.info("Notification permission granted.")
            } else {
                Log.notification.warning("Notification permission denied.")
            }
        }
    }

    // MARK: - Private: Tier 1 — System Notification

    private func sendTier1Notification(breakType: BreakType) {
        guard Bundle.main.bundleIdentifier != nil else {
            Log.notification.warning("No bundle identifier — skipping Tier 1 notification.")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Time for a \(breakType.displayName)"
        content.body = breakType.ruleDescription
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "eyeguard.break.\(breakType.rawValue)",
            content: content,
            trigger: nil // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                Log.notification.error("Tier 1 error: \(error.localizedDescription)")
            }
        }

        Log.notification.info("Tier 1 notification sent: \(breakType.displayName)")
    }

    // MARK: - Private: Cleanup

    private func cancelEscalation() {
        escalationTask?.cancel()
        escalationTask = nil
    }

    private func dismissAllOverlays() {
        if Bundle.main.bundleIdentifier != nil {
            UNUserNotificationCenter.current().removeDeliveredNotifications(
                withIdentifiers: BreakType.allCases.map { "eyeguard.break.\($0.rawValue)" }
            )
        }
        // Dismiss Tier 2 overlay window
        overlayController.dismiss()
        // Dismiss Tier 3 full-screen overlay windows
        overlayController.dismissFullScreen()
    }
}
