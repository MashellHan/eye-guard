import Foundation
import Observation
import os

/// Manages the Late Night Guardian mode (深夜提醒).
///
/// Activates a special night mode after a configurable time (default 10 PM),
/// providing warmer, gentler reminders and tracking late-night usage statistics.
///
/// Night mode behaviors:
/// - Mascot transitions to `.sleeping` state
/// - Speech bubbles use warmer, amber-tinted colors
/// - Night-themed bilingual messages
/// - More aggressive break reminders (shorter intervals)
/// - Late-night screen time tracking
@Observable
@MainActor
final class NightModeManager {

    /// Shared singleton instance.
    static let shared = NightModeManager()

    // MARK: - Published State

    /// Whether night mode is currently active.
    private(set) var isNightModeActive: Bool = false

    /// Total screen time accumulated during night mode today (seconds).
    private(set) var nightScreenTime: TimeInterval = 0

    /// Number of night mode activations today.
    private(set) var nightActivationCount: Int = 0

    /// Timestamp when current night session started, if active.
    private(set) var currentNightSessionStart: Date?

    // MARK: - Configuration

    /// Hour at which night mode activates (24h format, default 22 = 10 PM).
    var nightStartHour: Int {
        let stored = UserDefaults.standard.integer(forKey: "nightModeStartHour")
        return stored > 0 ? stored : 22
    }

    /// Hour at which night mode deactivates (24h format, default 6 = 6 AM).
    var nightEndHour: Int {
        let stored = UserDefaults.standard.integer(forKey: "nightModeEndHour")
        return stored > 0 ? stored : 6
    }

    /// Break interval multiplier during night mode (shorter = more aggressive).
    /// Default: 0.5 (breaks come twice as often at night).
    let nightBreakMultiplier: Double = 0.5

    // MARK: - Night Messages

    /// Night-themed reminder messages shown in the mascot speech bubble.
    nonisolated static let nightMessages: [(emoji: String, zh: String, en: String)] = [
        ("🌙", "已经很晚了，该休息了", "It's late, time to rest"),
        ("⭐", "眼睛需要好好睡一觉", "Your eyes need good sleep"),
        ("🌜", "屏幕时间太长了，早点休息吧", "Too much screen time, rest early"),
        ("😴", "深夜工作伤眼睛，注意休息", "Late-night work hurts your eyes, take a break"),
        ("🛌", "今天辛苦了，该关电脑了", "Hard day's work, time to shut down"),
        ("🌛", "月亮都出来了，你也该休息了", "The moon is out, you should rest too"),
        ("💤", "熬夜对眼睛伤害很大哦", "Staying up late is very bad for your eyes"),
        ("🌃", "夜深了，让眼睛休息一下吧", "It's late at night, let your eyes rest"),
    ]

    /// Break reminder messages specific to night mode (more urgent).
    nonisolated static let nightBreakMessages: [(emoji: String, zh: String, en: String)] = [
        ("🌙", "深夜了还在用眼，赶紧休息20秒", "Late night screen time — rest 20 seconds now"),
        ("⭐", "夜里眼睛更容易疲劳，快休息", "Eyes tire faster at night — take a break"),
        ("🌜", "深夜护眼更重要，看看远处吧", "Eye care is more important at night — look far away"),
    ]

    // MARK: - Initialization

    private init() {
        updateNightModeState()
    }

    // MARK: - Public Methods

    /// Checks the current time and updates night mode state.
    /// Call this periodically (e.g., every tick in the scheduler).
    func updateNightModeState() {
        let hour = Calendar.current.component(.hour, from: .now)
        let shouldBeActive = isNightHour(hour)

        if shouldBeActive && !isNightModeActive {
            activateNightMode()
        } else if !shouldBeActive && isNightModeActive {
            deactivateNightMode()
        }

        // Accumulate night screen time if active
        if isNightModeActive, let start = currentNightSessionStart {
            let elapsed = Date.now.timeIntervalSince(start)
            if elapsed > 0 {
                nightScreenTime += 1 // Called each tick (1 second)
            }
        }
    }

    /// Returns a random night-themed message for the mascot speech bubble.
    func randomNightMessage() -> String {
        let msg = Self.nightMessages.randomElement()!
        return "\(msg.emoji) \(msg.zh)"
    }

    /// Returns a night-specific break reminder message.
    func randomNightBreakMessage() -> String {
        let msg = Self.nightBreakMessages.randomElement()!
        return "\(msg.emoji) \(msg.zh)"
    }

    /// Returns a formatted string of tonight's late-night screen time.
    func formattedNightScreenTime() -> String {
        let minutes = Int(nightScreenTime) / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 {
            return "\(hours)小时\(remainingMinutes)分钟"
        }
        return "\(remainingMinutes)分钟"
    }

    /// Returns the night screen time message for the speech bubble.
    func nightScreenTimeMessage() -> String {
        let timeStr = formattedNightScreenTime()
        return "🌙 今晚屏幕时间: \(timeStr)"
    }

    /// Resets daily night mode statistics.
    func resetDaily() {
        nightScreenTime = 0
        nightActivationCount = 0
        currentNightSessionStart = nil
        isNightModeActive = false
        Log.nightMode.info("Night mode daily stats reset.")
    }

    /// Menu bar indicator text for night mode.
    var menuBarIndicator: String {
        isNightModeActive ? "🌙" : ""
    }

    // MARK: - Private Methods

    /// Determines if the given hour falls within the night period.
    private func isNightHour(_ hour: Int) -> Bool {
        if nightStartHour > nightEndHour {
            // Crosses midnight (e.g., 22:00 - 06:00)
            return hour >= nightStartHour || hour < nightEndHour
        } else {
            // Same day range (e.g., 23:00 - 05:00 unlikely but supported)
            return hour >= nightStartHour && hour < nightEndHour
        }
    }

    /// Activates night mode.
    private func activateNightMode() {
        isNightModeActive = true
        nightActivationCount += 1
        currentNightSessionStart = .now
        Log.nightMode.info("Night mode activated. Activation #\(self.nightActivationCount) today.")
    }

    /// Deactivates night mode.
    private func deactivateNightMode() {
        isNightModeActive = false
        currentNightSessionStart = nil
        Log.nightMode.info(
            "Night mode deactivated. Total night screen time: \(self.formattedNightScreenTime())."
        )
    }
}
