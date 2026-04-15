import Foundation

// MARK: - Notification Tier

/// Notification display tier, extracted from NotificationManager for cross-module use.
enum NotificationTier: String, Codable, Sendable, CaseIterable, Comparable {
    /// Tier 1: macOS system notification banner (UNUserNotificationCenter).
    case system

    /// Tier 2: Floating overlay window (NSWindow, .floating level).
    case floating

    /// Tier 3: Full-screen overlay (NSWindow, .screenSaver level).
    case fullScreen

    static func < (lhs: NotificationTier, rhs: NotificationTier) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }

    private var sortOrder: Int {
        switch self {
        case .system:     return 0
        case .floating:   return 1
        case .fullScreen: return 2
        }
    }

    var displayName: String {
        switch self {
        case .system:     return "System Notification"
        case .floating:   return "Floating Popup"
        case .fullScreen: return "Full Screen"
        }
    }

    var displayNameChinese: String {
        switch self {
        case .system:     return "系统通知"
        case .floating:   return "浮动弹窗"
        case .fullScreen: return "全屏覆盖"
        }
    }
}

// MARK: - Dismiss Policy

/// Controls how a break notification can be dismissed.
enum DismissPolicy: Codable, Sendable, Equatable {
    /// User can freely skip or close the notification.
    case skippable

    /// User can postpone up to `maxCount` times, each for `delay` seconds. No skip.
    case postponeOnly(maxCount: Int)

    /// Cannot be dismissed. Must complete the break countdown.
    case mandatory

    var displayName: String {
        switch self {
        case .skippable:     return "Skippable"
        case .postponeOnly:  return "Postpone Only"
        case .mandatory:     return "Mandatory"
        }
    }

    var displayNameChinese: String {
        switch self {
        case .skippable:     return "可跳过"
        case .postponeOnly:  return "仅可延后"
        case .mandatory:     return "强制执行"
        }
    }
}

// MARK: - Escalation Strategy

/// How break notifications escalate through tiers.
enum EscalationStrategy: Codable, Sendable, Equatable {
    /// Classic escalation: start at entry tier, wait delays, then escalate up.
    case tiered(tier1Delay: TimeInterval, tier2Delay: TimeInterval)

    /// Skip escalation — go directly to the entry tier with no waiting.
    case direct
}

// MARK: - Break Behavior

/// Complete behavioral configuration for a single break type within a mode.
struct BreakBehavior: Codable, Sendable {
    /// Interval between breaks of this type (seconds).
    var interval: TimeInterval

    /// Duration of this break (seconds).
    var duration: TimeInterval

    /// Whether this break type is enabled.
    var isEnabled: Bool

    /// Which notification tier to start at (bypasses lower tiers).
    var entryTier: NotificationTier

    /// How the user can dismiss this notification.
    var dismissPolicy: DismissPolicy
}

// MARK: - Reminder Mode Profile

/// Complete behavioral configuration for all break types under a given mode.
struct ReminderModeProfile: Codable, Sendable {
    var microBreak: BreakBehavior
    var macroBreak: BreakBehavior
    var mandatoryBreak: BreakBehavior
    var escalationStrategy: EscalationStrategy

    /// Returns the behavior for a given break type.
    func behavior(for breakType: BreakType) -> BreakBehavior {
        switch breakType {
        case .micro:     return microBreak
        case .macro:     return macroBreak
        case .mandatory: return mandatoryBreak
        }
    }
}

// MARK: - Reminder Mode

/// Preset reminder intensity modes, like "typical/custom" in software installers.
///
/// Each mode defines a complete behavioral profile covering:
/// - Which notification tier is used for each break type
/// - Whether breaks can be skipped vs only postponed
/// - Escalation strategy (tiered wait vs direct popup)
///
/// Default: `.aggressive` — prominent floating popups for all breaks.
enum ReminderMode: String, Codable, Sendable, CaseIterable {
    /// Gentle reminders. System notifications for micro breaks,
    /// floating overlay for macro, full-screen for mandatory.
    /// All breaks are skippable.
    case gentle

    /// Prominent popups. Floating popup immediately for micro/macro breaks,
    /// full-screen for mandatory. Mandatory breaks can only be postponed (2x).
    /// This is the recommended default for most users.
    case aggressive

    /// Maximum enforcement. Full-screen overlays for all break types.
    /// Micro breaks cannot be skipped. Mandatory breaks cannot be dismissed.
    case strict

    /// User configures each break's notification level and dismiss policy manually.
    case custom

    // MARK: - Display Properties

    var displayName: String {
        switch self {
        case .gentle:     return "Gentle"
        case .aggressive: return "Aggressive"
        case .strict:     return "Strict"
        case .custom:     return "Custom"
        }
    }

    var displayNameChinese: String {
        switch self {
        case .gentle:     return "温和"
        case .aggressive: return "积极"
        case .strict:     return "严格"
        case .custom:     return "自定义"
        }
    }

    var description: String {
        switch self {
        case .gentle:
            return "Gentle notifications — easy to dismiss"
        case .aggressive:
            return "Prominent popups — hard to ignore"
        case .strict:
            return "Full-screen enforcement — must complete breaks"
        case .custom:
            return "Configure each break type manually"
        }
    }

    var descriptionChinese: String {
        switch self {
        case .gentle:
            return "温和提醒，容易关闭"
        case .aggressive:
            return "显眼弹窗，不易忽略"
        case .strict:
            return "全屏强制，必须完成休息"
        case .custom:
            return "手动配置每种休息的提醒方式"
        }
    }

    var iconName: String {
        switch self {
        case .gentle:     return "leaf"
        case .aggressive: return "flame"
        case .strict:     return "lock.shield"
        case .custom:     return "slider.horizontal.3"
        }
    }

    // MARK: - Profile Factory

    /// Returns the hardcoded behavioral profile for this preset mode.
    ///
    /// For `.custom`, returns the default (aggressive) profile as a base;
    /// the caller should build the profile from individual user preferences instead.
    func profile() -> ReminderModeProfile {
        switch self {
        case .gentle:
            return ReminderModeProfile(
                microBreak: BreakBehavior(
                    interval: EyeGuardConstants.microBreakInterval,
                    duration: EyeGuardConstants.microBreakDuration,
                    isEnabled: true,
                    entryTier: .system,
                    dismissPolicy: .skippable
                ),
                macroBreak: BreakBehavior(
                    interval: EyeGuardConstants.macroBreakInterval,
                    duration: EyeGuardConstants.macroBreakDuration,
                    isEnabled: true,
                    entryTier: .floating,
                    dismissPolicy: .skippable
                ),
                mandatoryBreak: BreakBehavior(
                    interval: EyeGuardConstants.mandatoryBreakInterval,
                    duration: EyeGuardConstants.mandatoryBreakDuration,
                    isEnabled: true,
                    entryTier: .fullScreen,
                    dismissPolicy: .skippable
                ),
                escalationStrategy: .tiered(
                    tier1Delay: EyeGuardConstants.tier1EscalationDelay,
                    tier2Delay: EyeGuardConstants.tier2EscalationDelay
                )
            )

        case .aggressive:
            return ReminderModeProfile(
                microBreak: BreakBehavior(
                    interval: EyeGuardConstants.microBreakInterval,
                    duration: EyeGuardConstants.microBreakDuration,
                    isEnabled: true,
                    entryTier: .fullScreen,
                    dismissPolicy: .skippable
                ),
                macroBreak: BreakBehavior(
                    interval: EyeGuardConstants.macroBreakInterval,
                    duration: EyeGuardConstants.macroBreakDuration,
                    isEnabled: true,
                    entryTier: .fullScreen,
                    dismissPolicy: .skippable
                ),
                mandatoryBreak: BreakBehavior(
                    interval: EyeGuardConstants.mandatoryBreakInterval,
                    duration: EyeGuardConstants.mandatoryBreakDuration,
                    isEnabled: true,
                    entryTier: .fullScreen,
                    dismissPolicy: .postponeOnly(maxCount: 2)
                ),
                escalationStrategy: .direct
            )

        case .strict:
            return ReminderModeProfile(
                microBreak: BreakBehavior(
                    interval: EyeGuardConstants.microBreakInterval,
                    duration: EyeGuardConstants.microBreakDuration,
                    isEnabled: true,
                    entryTier: .fullScreen,
                    dismissPolicy: .mandatory
                ),
                macroBreak: BreakBehavior(
                    interval: EyeGuardConstants.macroBreakInterval,
                    duration: EyeGuardConstants.macroBreakDuration,
                    isEnabled: true,
                    entryTier: .fullScreen,
                    dismissPolicy: .postponeOnly(maxCount: 2)
                ),
                mandatoryBreak: BreakBehavior(
                    interval: EyeGuardConstants.mandatoryBreakInterval,
                    duration: EyeGuardConstants.mandatoryBreakDuration,
                    isEnabled: true,
                    entryTier: .fullScreen,
                    dismissPolicy: .mandatory
                ),
                escalationStrategy: .direct
            )

        case .custom:
            // Custom mode returns aggressive defaults as a base.
            // The actual profile is built from individual UserDefaults keys.
            return ReminderMode.aggressive.profile()
        }
    }
}
