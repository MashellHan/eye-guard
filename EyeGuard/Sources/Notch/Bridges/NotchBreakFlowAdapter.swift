//
//  NotchBreakFlowAdapter.swift
//  EyeGuard — Notch Module (Phase 4)
//
//  Observes the BreakScheduler and emits Notch pop banners at the
//  appropriate lifecycle points (pre-alert, break start, break end).
//  Only active when AppMode == .notch.
//

import Foundation
import Observation
import os

@MainActor
final class NotchBreakFlowAdapter {
    private let scheduler: BreakScheduler
    private let viewModel: NotchViewModel
    private let log = Logger(subsystem: "com.eyeguard.app", category: "NotchBreakFlow")

    private var pollTask: Task<Void, Never>?
    private var lastPreAlert: Bool = false
    private var lastInBreak: Bool = false

    init(scheduler: BreakScheduler, viewModel: NotchViewModel) {
        self.scheduler = scheduler
        self.viewModel = viewModel
    }

    /// Start observing scheduler transitions. Safe to call once.
    func start() {
        pollTask?.cancel()
        pollTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                self.tick()
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
        log.info("NotchBreakFlowAdapter started")
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
        log.info("NotchBreakFlowAdapter stopped")
    }

    private func tick() {
        let preAlertNow = scheduler.isPreAlertActive
        let inBreakNow = scheduler.isBreakInProgress

        // Rising edge: pre-alert activated
        if preAlertNow, !lastPreAlert {
            viewModel.pop(
                kind: .preBreak,
                message: "Time to rest your eyes 💛",
                duration: 3.5
            )
            log.info("Pop: pre-break alert")
        }

        // Rising edge: break started
        if inBreakNow, !lastInBreak {
            viewModel.pop(
                kind: .breakStarted,
                message: "Break started — look away",
                duration: 3.0
            )
            log.info("Pop: break started")
        }

        // Falling edge: break ended
        if !inBreakNow, lastInBreak {
            viewModel.pop(
                kind: .breakCompleted,
                message: "Nice! Keep going ✨",
                duration: 3.0
            )
            log.info("Pop: break completed")
        }

        lastPreAlert = preAlertNow
        lastInBreak = inBreakNow
    }
}
