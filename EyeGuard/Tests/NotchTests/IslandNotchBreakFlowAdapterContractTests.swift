//
//  IslandNotchBreakFlowAdapterContractTests.swift
//  EyeGuard — Notch Module (Day 3 — autonomous testing pass)
//
//  Smoke tests that the adapter-relevant view-model surface
//  (IslandNotchViewModel.pop(kind:message:duration:) — added Day 2.5a)
//  exists and is callable on the main actor. The adapter itself is a
//  500ms-poll struct around BreakScheduler; we don't drive it through
//  real time here (that would be flaky), but we verify the contract
//  surface it depends on.
//
//  Coverage target: ensure that if pop() is renamed or its enum cases
//  drift, CI catches it before the adapter starts emitting silent no-ops.
//

import Testing
import Foundation
import CoreGraphics
@testable import EyeGuard

@Suite("IslandNotchBreakFlowAdapter contract")
@MainActor
struct IslandNotchBreakFlowAdapterContractTests {

    private func makeVM() -> IslandNotchViewModel {
        IslandNotchViewModel(
            deviceNotchRect: CGRect(x: 100, y: 0, width: 200, height: 38),
            screenRect: CGRect(x: 0, y: 0, width: 1400, height: 900),
            windowHeight: 400,
            hasPhysicalNotch: true,
            screenID: "test"
        )
    }

    @Test("pop(kind:.preBreak) is callable")
    func popPreBreakCallable() {
        let vm = makeVM()
        vm.pop(kind: .preBreak, message: "Time to rest", duration: 0.01)
        // No throw, no crash. The adapter's edge-trigger code path exercises
        // exactly this call pattern on `scheduler.isPreAlertActive` rising
        // edge.
        #expect(Bool(true))
    }

    @Test("pop(kind:.breakStarted) is callable")
    func popBreakStartedCallable() {
        let vm = makeVM()
        vm.pop(kind: .breakStarted, message: "Break started", duration: 0.01)
        #expect(Bool(true))
    }

    @Test("pop(kind:.breakCompleted) is callable")
    func popBreakCompletedCallable() {
        let vm = makeVM()
        vm.pop(kind: .breakCompleted, message: "Nice", duration: 0.01)
        #expect(Bool(true))
    }

    @Test("EyeGuardPopKind has exactly the 3 cases the adapter depends on")
    func popKindCasesStable() {
        // Exhaustive switch verifies that no case has been removed.
        // If a case is added, the adapter contract test would compile-fail
        // here — flagging that the adapter needs a new edge trigger.
        let kinds: [IslandNotchViewModel.EyeGuardPopKind] = [.preBreak, .breakStarted, .breakCompleted]
        for k in kinds {
            switch k {
            case .preBreak, .breakStarted, .breakCompleted:
                #expect(Bool(true))
            }
        }
    }
}
