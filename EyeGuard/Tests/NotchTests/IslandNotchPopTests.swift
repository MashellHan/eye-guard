//
//  IslandNotchPopTests.swift
//  EyeGuard — Day 4 carry-over coverage
//
//  Mirrors NotchPopTests against the mio-framework `IslandNotchViewModel`
//  so the Pop banner contract is verified on the new code path before the
//  legacy `NotchViewModel` is deleted in step 4.1.
//

import Testing
import Foundation
import CoreGraphics
@testable import EyeGuard

@Suite("IslandNotchPop")
@MainActor
struct IslandNotchPopTests {

    private func makeVM() -> IslandNotchViewModel {
        IslandNotchViewModel(
            deviceNotchRect: CGRect(x: 100, y: 0, width: 200, height: 38),
            screenRect: CGRect(x: 0, y: 0, width: 1400, height: 900),
            windowHeight: 400,
            hasPhysicalNotch: true,
            screenID: "test"
        )
    }

    @Test("notchPop() transitions closed → popping")
    func popFromClosed() {
        let vm = makeVM()
        #expect(vm.status == .closed)
        vm.notchPop()
        #expect(vm.status == .popping)
    }

    @Test("notchPop() is a no-op while opened")
    func popNoOpIfOpened() {
        let vm = makeVM()
        vm.notchOpen(reason: .click)
        #expect(vm.status == .opened)
        vm.notchPop()
        #expect(vm.status == .opened)
    }

    @Test("notchUnpop() returns popping → closed")
    func unpopReturnsToClosed() {
        let vm = makeVM()
        vm.notchPop()
        #expect(vm.status == .popping)
        vm.notchUnpop()
        #expect(vm.status == .closed)
    }

    @Test("notchUnpop() is a no-op while not popping")
    func unpopNoOpIfNotPopping() {
        let vm = makeVM()
        #expect(vm.status == .closed)
        vm.notchUnpop()
        #expect(vm.status == .closed)
    }

    @Test("pop(kind:message:duration:) accepts all three kinds without crashing")
    func popKindParity() {
        let vm = makeVM()
        let kinds: [IslandNotchViewModel.EyeGuardPopKind] = [.preBreak, .breakStarted, .breakCompleted]
        for kind in kinds {
            // Reset to closed between calls so each pop is allowed to enter .popping.
            vm.notchUnpop()
            vm.pop(kind: kind, message: "m", duration: 0.01)
            #expect(vm.status == .popping)
        }
    }
}
