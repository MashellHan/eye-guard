//
//  IslandNotchBreakFlowAdapter.swift
//  EyeGuard — Notch Module (Day 2.5b)
//
//  Variant of `NotchBreakFlowAdapter` that targets `IslandNotchViewModel`
//  (the mio framework view model) instead of the legacy `NotchViewModel`.
//  The pop semantics match: pre-break / break-started / break-ended
//  trigger `viewModel.pop(kind:message:duration:)`, which Day 2.5a
//  implemented as a parity surface over `notchPop`/`notchUnpop`.
//

import Foundation
import os

@MainActor
final class IslandNotchBreakFlowAdapter {
    private let scheduler: BreakScheduler
    private let viewModel: IslandNotchViewModel
    private let log = Logger(subsystem: "com.eyeguard.app", category: "IslandNotchBreakFlow")

    private var pollTask: Task<Void, Never>?
    private var lastPreAlert: Bool = false
    private var lastInBreak: Bool = false

    init(scheduler: BreakScheduler, viewModel: IslandNotchViewModel) {
        self.scheduler = scheduler
        self.viewModel = viewModel
    }

    func start() {
        pollTask?.cancel()
        pollTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                self.tick()
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
        log.info("IslandNotchBreakFlowAdapter started")
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
        log.info("IslandNotchBreakFlowAdapter stopped")
    }

    private func tick() {
        let preAlertNow = scheduler.isPreAlertActive
        let inBreakNow = scheduler.isBreakInProgress

        if preAlertNow, !lastPreAlert {
            viewModel.pop(kind: .preBreak,
                          message: "Time to rest your eyes 💛",
                          duration: 3.5)
            log.info("Pop: pre-break alert")
        }
        if inBreakNow, !lastInBreak {
            viewModel.pop(kind: .breakStarted,
                          message: "Break started — look away",
                          duration: 3.0)
            log.info("Pop: break started")
        }
        if !inBreakNow, lastInBreak {
            viewModel.pop(kind: .breakCompleted,
                          message: "Nice! Keep going ✨",
                          duration: 3.0)
            log.info("Pop: break completed")
        }

        lastPreAlert = preAlertNow
        lastInBreak = inBreakNow
    }
}
