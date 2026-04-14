import AppKit
import Foundation
import UserNotifications
import os

/// Manages break notifications with a three-tier escalation system.
///
/// Tier 1 (Gentle): macOS UserNotification banner — dismissible.
/// Tier 2 (Firm): Custom semi-transparent overlay window — 30-sec countdown.
/// Tier 3 (Mandatory): Full-screen overlay — requires acknowledgment.
///
/// Conforms to `NotificationSending` for testability.
@MainActor
final class NotificationManager: NotificationSending {

    // MARK: - Notification Tier

    enum Tier: Int, Sendable {
        case gentle = 1
        case firm = 2
        case mandatory = 3
    }

    // MARK: - State

    private var currentTier: Tier = .gentle
    private var escalationTask: Task<Void, Never>?
    private var snoozeTask: Task<Void, Never>?
    private(set) var isNotificationActive: Bool = false

    /// Stored callbacks for the current notification cycle (H4).
    private var onTakenCallback: (@Sendable () -> Void)?
    private var onSkippedCallback: (@Sendable () -> Void)?

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

    /// Sends a break notification starting at Tier 1, escalating if ignored.
    ///
    /// Stores `onTaken` and `onSkipped` callbacks for later invocation (H4).
    ///
    /// - Parameters:
    ///   - breakType: The type of break to notify about.
    ///   - onTaken: Callback when user acknowledges the break.
    ///   - onSkipped: Callback when user dismisses/skips the break.
    func notify(
        breakType: BreakType,
        onTaken: @escaping @Sendable () -> Void,
        onSkipped: @escaping @Sendable () -> Void
    ) {
        guard !isNotificationActive else { return }
        isNotificationActive = true
        currentTier = .gentle

        // Store callbacks (H4)
        self.onTakenCallback = onTaken
        self.onSkippedCallback = onSkipped

        sendTier1Notification(breakType: breakType)

        // Start escalation chain
        escalationTask = Task {
            // Wait for Tier 1 → Tier 2 escalation
            try? await Task.sleep(for: .seconds(EyeGuardConstants.tier1EscalationDelay))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                self.currentTier = .firm
                self.showTier2Overlay(breakType: breakType)
            }

            // Wait for Tier 2 → Tier 3 escalation (only for mandatory breaks)
            if breakType == .mandatory {
                try? await Task.sleep(for: .seconds(EyeGuardConstants.tier2EscalationDelay))
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.currentTier = .mandatory
                    self.showTier3Fullscreen(breakType: breakType)
                }

                // After Tier 3 timeout, invoke onSkipped if still not acknowledged (H4)
                try? await Task.sleep(for: .seconds(EyeGuardConstants.tier2EscalationDelay))
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.handleEscalationTimeout()
                }
            } else {
                // Non-mandatory: after Tier 2 timeout, invoke onSkipped (H4)
                try? await Task.sleep(for: .seconds(EyeGuardConstants.tier2EscalationDelay))
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.handleEscalationTimeout()
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
        isNotificationActive = false
        clearCallbacks()

        callback?()
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

        Log.notification.info("Snoozed \(breakType.displayName) for \(Int(EyeGuardConstants.maxSnoozeDuration))s.")

        // Reschedule after snooze duration (BUG-006)
        snoozeTask?.cancel()
        snoozeTask = Task {
            try? await Task.sleep(for: .seconds(EyeGuardConstants.maxSnoozeDuration))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                Log.notification.info("Snooze expired for \(breakType.displayName), re-notifying.")
                onDue()
            }
        }
    }

    // MARK: - Private: Escalation Timeout (H4)

    /// Called when escalation chain times out without user acknowledgment.
    /// Invokes the stored `onSkipped` callback.
    private func handleEscalationTimeout() {
        let callback = onSkippedCallback
        dismissAllOverlays()
        isNotificationActive = false
        clearCallbacks()

        Log.notification.info("Escalation timed out, break skipped.")
        callback?()
    }

    /// Clears stored callbacks after they've been invoked or are no longer needed.
    private func clearCallbacks() {
        onTakenCallback = nil
        onSkippedCallback = nil
    }

    // MARK: - Private: Notification Permission

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
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

    // MARK: - Private: Tier 2 — Overlay Window

    private func showTier2Overlay(breakType: BreakType) {
        // TODO: Implement custom NSWindow overlay
        // - Semi-transparent background
        // - 30-second countdown timer
        // - "Take Break" and "Snooze" buttons
        // - Floats above all windows
        Log.notification.info("Tier 2 overlay shown: \(breakType.displayName)")
    }

    // MARK: - Private: Tier 3 — Full-Screen

    private func showTier3Fullscreen(breakType: BreakType) {
        // TODO: Implement full-screen NSWindow
        // - Full-screen opaque overlay
        // - Large countdown timer
        // - "I took my break" acknowledgment button
        // - Cannot be dismissed without acknowledgment
        Log.notification.info("Tier 3 fullscreen shown: \(breakType.displayName)")
    }

    // MARK: - Private: Cleanup

    private func cancelEscalation() {
        escalationTask?.cancel()
        escalationTask = nil
    }

    private func dismissAllOverlays() {
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: BreakType.allCases.map { "eyeguard.break.\($0.rawValue)" }
        )
        // TODO: Close Tier 2/3 overlay windows
    }
}
