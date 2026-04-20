//
//  EyeGuardNotchMenu.swift
//  EyeGuard — Notch Module (Day 2.2)
//
//  Compact action menu surfaced inside the expanded notch panel.
//  Provides 5 first-class actions wired by the embedding view.
//
//  Decoupling rationale: this view is action-agnostic. Callers pass in a
//  fully-resolved `Actions` struct (closures + presentation state) so the
//  menu does not import or talk to `BreakScheduler` / `EyeGuardDataBridge`
//  directly. That keeps the surface trivially unit-testable and makes the
//  Day 3 visual polish pass risk-free (palette / font modifiers can be
//  applied to this file alone without dragging in scheduler concerns).
//
//  Action contract (per Day 2 plan in .merge_island/11-notch-mio-upgrade.md):
//    1. Take a break now
//    2. Skip next break
//    3. Pause / resume monitoring
//    4. Reset session
//    5. Open preferences
//

import SwiftUI

/// Notification posted when the user taps "Preferences…" in the notch menu.
/// `AppDelegate` (or any other coordinator) listens and brings the settings
/// window forward without coupling this view to AppKit window APIs.
extension Notification.Name {
    static let eyeGuardNotchMenuOpenPreferences =
        Notification.Name("com.eyeguard.notch.menu.openPreferences")
}

struct EyeGuardNotchMenu: View {

    /// Caller-provided action surface. All closures are `@MainActor` since
    /// the menu lives inside the notch panel which is main-actor isolated.
    struct Actions {
        var takeBreakNow:  @MainActor () -> Void
        var skipNextBreak: @MainActor () -> Void
        var togglePause:   @MainActor () -> Void
        var resetSession:  @MainActor () -> Void
        var openPreferences: @MainActor () -> Void = {
            NotificationCenter.default.post(
                name: .eyeGuardNotchMenuOpenPreferences,
                object: nil
            )
        }
    }

    /// Visual / label state derived by the caller from the bridge.
    struct State: Equatable {
        var isPaused: Bool
        var nextBreakLabel: String   // e.g. "micro break"
    }

    let state: State
    let actions: Actions

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            row(symbol: "cup.and.saucer.fill",
                title: "Take a break now",
                tint: .accentColor,
                action: actions.takeBreakNow)

            divider

            row(symbol: "forward.fill",
                title: "Skip next \(state.nextBreakLabel)",
                tint: .secondary,
                action: actions.skipNextBreak)

            divider

            row(symbol: state.isPaused ? "play.fill" : "pause.fill",
                title: state.isPaused ? "Resume monitoring" : "Pause monitoring",
                tint: state.isPaused ? .green : .orange,
                action: actions.togglePause)

            divider

            row(symbol: "arrow.counterclockwise",
                title: "Reset session",
                tint: .secondary,
                action: actions.resetSession)

            divider

            row(symbol: "gearshape.fill",
                title: "Preferences…",
                tint: .secondary,
                action: actions.openPreferences)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Row primitive

    @ViewBuilder
    private func row(symbol: String,
                     title: String,
                     tint: Color,
                     action: @escaping @MainActor () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .frame(width: 18)
                    .foregroundStyle(tint)
                Text(title)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var divider: some View {
        Divider()
            .background(Color.white.opacity(0.08))
            .padding(.horizontal, 12)
    }
}
