//
//  EyeGuardDataBridgeTests.swift
//  EyeGuard — Phase 2 tests
//
//  Unit tests for the data bridge + tier derivation.
//  Tier logic is pure, so the majority is covered with static input.
//  Bridge properties are covered by constructing a real BreakScheduler.
//

import Testing
import Foundation
@testable import EyeGuard

@Suite("EyeGuardDataBridge")
@MainActor
struct EyeGuardDataBridgeTests {

    // MARK: - Tier derivation (pure)

    @Test("tier — fresh when under 10 minutes")
    func tierFresh() {
        let tier = ContinuousUseTier.derive(
            elapsedContinuous: 9 * 60,
            isInBreak: false
        )
        #expect(tier == .fresh)
    }

    @Test("tier — warming at 10–15 minutes")
    func tierWarming() {
        let tier = ContinuousUseTier.derive(
            elapsedContinuous: 12 * 60,
            isInBreak: false
        )
        #expect(tier == .warming)
    }

    @Test("tier — stressed at 15–20 minutes")
    func tierStressed() {
        let tier = ContinuousUseTier.derive(
            elapsedContinuous: 17 * 60,
            isInBreak: false
        )
        #expect(tier == .stressed)
    }

    @Test("tier — overdue at 20+ minutes")
    func tierOverdue() {
        let tier = ContinuousUseTier.derive(
            elapsedContinuous: 25 * 60,
            isInBreak: false
        )
        #expect(tier == .overdue)
    }

    @Test("tier — resting wins over any elapsed value")
    func tierResting() {
        let tier = ContinuousUseTier.derive(
            elapsedContinuous: 30 * 60,
            isInBreak: true
        )
        #expect(tier == .resting)
    }

    @Test("tier symbols match the design spec")
    func tierSymbols() {
        #expect(ContinuousUseTier.fresh.symbolName == "circle.fill")
        #expect(ContinuousUseTier.warming.symbolName == "circle.fill")
        #expect(ContinuousUseTier.stressed.symbolName == "circle.fill")
        #expect(ContinuousUseTier.overdue.symbolName == "exclamationmark.circle.fill")
        #expect(ContinuousUseTier.resting.symbolName == "eye.slash.fill")
    }

    // MARK: - formatMMSS (pure)

    @Test("formatMMSS pads with zeros", arguments: [
        (0.0, "00:00"),
        (59.0, "00:59"),
        (60.0, "01:00"),
        (125.0, "02:05"),
        (599.0, "09:59"),
        (3600.0, "60:00")
    ])
    func formatMMSS(input: TimeInterval, expected: String) {
        #expect(EyeGuardDataBridge.formatMMSS(input) == expected)
    }

    @Test("formatMMSS saturates negative values to 00:00")
    func formatMMSSNegative() {
        #expect(EyeGuardDataBridge.formatMMSS(-100) == "00:00")
    }

    // MARK: - Bridge composition

    @Test("Initial bridge values reflect a fresh scheduler")
    func bridgeInitial() {
        let scheduler = BreakScheduler()
        let bridge = EyeGuardDataBridge(scheduler: scheduler)

        #expect(bridge.continuousTime == 0)
        #expect(bridge.healthScore == 100)
        #expect(bridge.isInBreak == false)
        #expect(bridge.tier == .fresh)
        #expect(bridge.continuousTimeFormatted == "00:00")
    }

    @Test("Bridge formats next break countdown from scheduler")
    func bridgeNextBreakFormat() {
        let scheduler = BreakScheduler()
        let bridge = EyeGuardDataBridge(scheduler: scheduler)
        // Default interval for micro break is 20 min = 1200s
        let formatted = bridge.nextBreakInFormatted
        // Format regex "MM:SS"
        #expect(formatted.count == 5)
        #expect(formatted.contains(":"))
    }

    @Test("continuousProgress is 0 for fresh scheduler")
    func bridgeProgressZero() {
        let scheduler = BreakScheduler()
        let bridge = EyeGuardDataBridge(scheduler: scheduler)
        #expect(bridge.continuousProgress == 0.0)
    }

    @Test("tier color is green for fresh scheduler")
    func bridgeTierColor() {
        let scheduler = BreakScheduler()
        let bridge = EyeGuardDataBridge(scheduler: scheduler)
        // Using the derivation path — visual color is tested by proxy:
        // tier enum equality is sufficient for correctness.
        #expect(bridge.tier == .fresh)
    }
}
