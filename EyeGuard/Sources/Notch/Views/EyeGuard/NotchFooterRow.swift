//
//  NotchFooterRow.swift
//  EyeGuard — Notch Module (B11)
//
//  Tiny housekeeping row at the bottom of the expanded panel — Dashboard
//  / Settings / Quit. Icon-only with a 9pt caption underneath: keeps each
//  column ~32pt tall so we stay inside the 420pt panel-height budget set
//  by the plan.
//
//  Window controllers are all `@MainActor` singletons; this view runs in
//  MainActor context, so the calls are direct (no Task hop).
//
//  Note on `bridge.underlyingScheduler`: Dashboard genuinely needs a
//  `BreakScheduler` argument (it draws its own charts straight from the
//  scheduler). This is the *only* approved use of `underlyingScheduler`
//  in the notch module — see the doc comment on that property.
//

import SwiftUI
import AppKit

@MainActor
struct NotchFooterRow: View {
    @Bindable var bridge: EyeGuardDataBridge

    var body: some View {
        HStack(spacing: 6) {
            footerButton(
                icon: "chart.bar.fill",
                label: "Dashboard"
            ) {
                DashboardWindowController.shared.showDashboard(
                    scheduler: bridge.underlyingScheduler
                )
            }
            footerButton(
                icon: "gearshape.fill",
                label: "Settings"
            ) {
                PreferencesWindowController.shared.showPreferences()
            }
            footerButton(
                icon: "power",
                label: "Quit"
            ) {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    /// Icon over caption, equal-width column, hover tint via
    /// `AppColors.notchHoverTint`. Plain button style + custom background
    /// because `.bordered` on a dark surface looks washed out.
    @ViewBuilder
    private func footerButton(
        icon: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        HoverButton(action: action) { isHovering in
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.notchPrimaryText)
                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(AppColors.notchSecondaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovering ? AppColors.notchHoverTint : .clear)
            )
            .contentShape(Rectangle())
        }
    }
}

/// Lightweight wrapper that exposes a hover flag to its label closure
/// without each footer button needing its own `@State`. Defined locally
/// because no other notch view needs hover-state buttons today; promote
/// to `Notch/Views/Components/` if a second consumer appears.
@MainActor
private struct HoverButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: (Bool) -> Label

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            label(isHovering)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
