//
//  EyeGuardDataBridge.swift
//  EyeGuard — Notch Module (Phase 2)
//
//  @Observable bridge between BreakScheduler and the Notch UI.
//  Exposes derived, presentation-ready values (formatted strings, color
//  tiers) so Notch views don't reach into the scheduler directly.
//

import Foundation
import Observation
import SwiftUI

/// Status tier for the continuous-use time indicator.
/// Controls the collapsed-state color dot + SF Symbol.
enum ContinuousUseTier: Sendable, Equatable {
    case fresh      // < 10 min  → green
    case warming    // 10–15     → yellow
    case stressed   // 15–20     → orange
    case overdue    // ≥ 20      → red
    case resting    // in break  → blue

    var color: Color {
        switch self {
        case .fresh:    return .green
        case .warming:  return .yellow
        case .stressed: return .orange
        case .overdue:  return .red
        case .resting:  return .blue
        }
    }

    var symbolName: String {
        switch self {
        case .overdue:  return "exclamationmark.circle.fill"
        case .resting:  return "eye.slash.fill"
        default:        return "circle.fill"
        }
    }

    /// Derive tier from scheduler state. Pure function — unit-testable.
    static func derive(
        elapsedContinuous: TimeInterval,
        isInBreak: Bool
    ) -> ContinuousUseTier {
        if isInBreak { return .resting }
        let minutes = elapsedContinuous / 60
        if minutes >= 20 { return .overdue }
        if minutes >= 15 { return .stressed }
        if minutes >= 10 { return .warming }
        return .fresh
    }
}

/// @Observable view-model that snapshots BreakScheduler state for Notch.
///
/// Consumers observe this type instead of the scheduler directly, so we
/// can reshape / format values without coupling the Notch UI to the
/// scheduler's internals.
@MainActor
@Observable
final class EyeGuardDataBridge {
    // MARK: - Inputs

    private let scheduler: BreakScheduler

    // MARK: - Derived Outputs

    /// Continuous time since last break, in seconds.
    var continuousTime: TimeInterval {
        scheduler.elapsedPerType[.micro] ?? 0
    }

    /// Time remaining until the next scheduled break.
    var nextBreakIn: TimeInterval {
        scheduler.timeUntilNextBreak
    }

    /// Today's health score, 0–100.
    var healthScore: Int {
        scheduler.currentHealthScore
    }

    /// Detailed breakdown of today's health score, including per-component
    /// explanations. `nil` until the scheduler has computed at least once.
    var healthScoreBreakdown: HealthScoreBreakdown? {
        scheduler.currentBreakdown
    }

    /// Whether a break is currently in progress.
    var isInBreak: Bool {
        scheduler.isBreakInProgress
    }

    /// Whether the timer is paused.
    var isPaused: Bool {
        scheduler.isPaused
    }

    /// The next scheduled break type.
    var nextBreakType: BreakType {
        scheduler.nextScheduledBreak ?? .micro
    }

    /// Color tier for collapsed-state display.
    var tier: ContinuousUseTier {
        ContinuousUseTier.derive(
            elapsedContinuous: continuousTime,
            isInBreak: isInBreak
        )
    }

    // MARK: - Formatted Strings

    /// Continuous time formatted as "MM:SS".
    var continuousTimeFormatted: String {
        Self.formatMMSS(continuousTime)
    }

    /// Next break in "MM:SS".
    var nextBreakInFormatted: String {
        Self.formatMMSS(max(0, nextBreakIn))
    }

    /// Progress fraction 0.0–1.0 toward the next micro break target.
    var continuousProgress: Double {
        let target = EyeGuardConstants.microBreakInterval
        guard target > 0 else { return 0 }
        return min(1.0, continuousTime / target)
    }

    // MARK: - Actions

    /// Immediately trigger a micro break.
    func triggerBreakNow() {
        scheduler.takeBreakNow(.micro)
    }

    // MARK: - Init

    init(scheduler: BreakScheduler) {
        self.scheduler = scheduler
    }

    // MARK: - Helpers

    /// Format a time interval as "MM:SS", saturating at zero.
    static func formatMMSS(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
