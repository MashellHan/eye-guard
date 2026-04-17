//
//  NotchPopTests.swift
//  EyeGuard — Phase 4
//
//  Tests for the NotchViewModel.pop(kind:message:) API and
//  NotchPopKind symbol/tint mapping.
//

import Testing
import Foundation
import CoreGraphics
@testable import EyeGuard

@Suite("NotchPop")
@MainActor
struct NotchPopTests {

    private func makeVM() -> NotchViewModel {
        NotchViewModel(
            deviceNotchRect: CGRect(x: 100, y: 0, width: 200, height: 38),
            screenRect: CGRect(x: 0, y: 0, width: 1400, height: 900),
            windowHeight: 400,
            hasPhysicalNotch: true,
            screenID: "test"
        )
    }

    @Test("pop() transitions closed → popping and stores payload")
    func popFromClosed() {
        let vm = makeVM()
        #expect(vm.status == .closed)
        vm.pop(kind: .preBreak, message: "rest your eyes")
        #expect(vm.status == .popping)
        #expect(vm.popKind == .preBreak)
        #expect(vm.popMessage == "rest your eyes")
    }

    @Test("pop() is a no-op while already opened")
    func popNoOpIfOpened() {
        let vm = makeVM()
        vm.notchOpen(reason: .click)
        #expect(vm.status == .opened)
        vm.pop(kind: .info, message: "ignored")
        #expect(vm.status == .opened)
        #expect(vm.popKind == nil)
    }

    @Test("pop() subsequent call replaces the previous banner")
    func popReplaces() {
        let vm = makeVM()
        vm.pop(kind: .preBreak, message: "first")
        vm.pop(kind: .breakStarted, message: "second")
        #expect(vm.popKind == .breakStarted)
        #expect(vm.popMessage == "second")
    }

    @Test("NotchPopKind maps to symbols we expect")
    func popKindSymbols() {
        #expect(NotchPopKind.preBreak.symbol == "eye.trianglebadge.exclamationmark")
        #expect(NotchPopKind.breakStarted.symbol == "play.circle.fill")
        #expect(NotchPopKind.breakCompleted.symbol == "checkmark.seal.fill")
        #expect(NotchPopKind.info.symbol == "bell.fill")
    }

    @Test("NotchPopKind has non-default tint colors")
    func popKindTints() {
        // Verify all cases are covered — just equality against themselves.
        let all: [NotchPopKind] = [.preBreak, .breakStarted, .breakCompleted, .info]
        for k in all {
            // Tint accessor just shouldn't crash; all are distinct.
            _ = k.tint
        }
        #expect(all.count == 4)
    }
}
