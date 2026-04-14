import Foundation

/// Categories of breaks based on medical guidelines.
enum BreakType: String, Codable, Sendable, CaseIterable {

    /// 20-20-20 rule: every 20 minutes, look at something 20 feet away for 20 seconds.
    /// Source: American Academy of Ophthalmology.
    case micro

    /// Hourly break: every 60 minutes, take a 5-10 minute break.
    /// Source: OSHA recommendations.
    case macro

    /// Mandatory break: every 120 minutes, take a 15 minute break.
    /// Source: EU Screen Equipment Directive.
    case mandatory

    /// The recommended interval between breaks of this type.
    var interval: TimeInterval {
        switch self {
        case .micro:     return EyeGuardConstants.microBreakInterval
        case .macro:     return EyeGuardConstants.macroBreakInterval
        case .mandatory: return EyeGuardConstants.mandatoryBreakInterval
        }
    }

    /// The recommended duration for this break type.
    var duration: TimeInterval {
        switch self {
        case .micro:     return EyeGuardConstants.microBreakDuration
        case .macro:     return EyeGuardConstants.macroBreakDuration
        case .mandatory: return EyeGuardConstants.mandatoryBreakDuration
        }
    }

    /// Human-readable description of the break rule.
    var ruleDescription: String {
        switch self {
        case .micro:
            return "20-20-20 Rule: Every 20 min, look 20 ft away for 20 sec"
        case .macro:
            return "Hourly Break: Every 60 min, take a 5 min break"
        case .mandatory:
            return "Mandatory Break: Every 2 hr, take a 15 min break"
        }
    }

    /// Short display name.
    var displayName: String {
        switch self {
        case .micro:     return "Micro Break"
        case .macro:     return "Macro Break"
        case .mandatory: return "Mandatory Break"
        }
    }

    /// SF Symbol icon name for this break type.
    var iconName: String {
        switch self {
        case .micro:     return "eye"
        case .macro:     return "cup.and.saucer"
        case .mandatory: return "figure.walk"
        }
    }
}
