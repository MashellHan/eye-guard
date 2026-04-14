import AppKit
import Foundation
import UserNotifications

/// Manages break notifications with a three-tier escalation system.
///
/// Tier 1 (Gentle): macOS UserNotification banner — dismissible.
/// Tier 2 (Firm): Custom semi-transparent overlay window — 30-sec countdown.
/// Tier 3 (Mandatory): Full-screen overlay — requires acknowledgment.
@MainActor
final class NotificationManager {

    // MARK: - Notification Tier

    enum Tier: Int, Sendable {
        case gentle = 1
        case firm = 2
        case mandatory = 3
    }

    // MARK: - State

    private var currentTier: Tier = .gentle
    private var escalationTask: Task<Void, Never>?
    private var isNotificationActive: Bool = false

    // MARK: - Singleton

    static let shared = NotificationManager()

    private init() {
        requestNotificationPermission()
    }

    // MARK: - Public API

    /// Sends a break notification starting at Tier 1, escalating if ignored.
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
            }
        }
    }

    /// Dismisses the current notification (user took the break).
    func acknowledgeBreak() {
        cancelEscalation()
        dismissAllOverlays()
        isNotificationActive = false
    }

    /// Snoozes the current notification for a short period.
    func snooze() {
        cancelEscalation()
        dismissAllOverlays()
        isNotificationActive = false
        // TODO: Re-schedule notification after snooze duration
    }

    // MARK: - Private: Notification Permission

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                print("[NotificationManager] Permission error: \(error.localizedDescription)")
            } else if granted {
                print("[NotificationManager] Notification permission granted.")
            } else {
                print("[NotificationManager] Notification permission denied.")
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
                print("[NotificationManager] Tier 1 error: \(error.localizedDescription)")
            }
        }

        print("[NotificationManager] Tier 1 notification sent: \(breakType.displayName)")
    }

    // MARK: - Private: Tier 2 — Overlay Window

    private func showTier2Overlay(breakType: BreakType) {
        // TODO: Implement custom NSWindow overlay
        // - Semi-transparent background
        // - 30-second countdown timer
        // - "Take Break" and "Snooze" buttons
        // - Floats above all windows
        print("[NotificationManager] Tier 2 overlay shown: \(breakType.displayName)")
    }

    // MARK: - Private: Tier 3 — Full-Screen

    private func showTier3Fullscreen(breakType: BreakType) {
        // TODO: Implement full-screen NSWindow
        // - Full-screen opaque overlay
        // - Large countdown timer
        // - "I took my break" acknowledgment button
        // - Cannot be dismissed without acknowledgment
        print("[NotificationManager] Tier 3 fullscreen shown: \(breakType.displayName)")
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
