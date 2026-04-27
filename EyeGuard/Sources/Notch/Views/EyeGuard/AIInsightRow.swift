//
//  AIInsightRow.swift
//  EyeGuard — Notch Module (B11)
//
//  One-line AI insight (brain icon + 2-line text) with an inline Report
//  button on the trailing edge. Mirrors `MenuBarView.insightAndReportSection`
//  visually but at 11pt instead of caption2 so the notch's compact panel
//  doesn't read as a wall of micro text.
//
//  Insight text + report generation both come from the bridge — the
//  compliance formula is centralised in `EyeGuardDataBridge.currentInsight`
//  so menubar and notch can never drift on what they tell the user.
//

import SwiftUI

@MainActor
struct AIInsightRow: View {
    @Bindable var bridge: EyeGuardDataBridge

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "brain")
                .font(.system(size: 10))
                .foregroundStyle(.purple)
                // Nudge icon down so it visually centres on the first line of
                // the insight text rather than floating above it.
                .padding(.top, 1)

            Text(bridge.currentInsight)
                .font(.system(size: 11))
                .foregroundStyle(AppColors.notchPrimaryText)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                Task { @MainActor in
                    await bridge.generateReport()
                }
            } label: {
                Image(systemName: "doc.text")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppColors.notchSecondaryText)
                    .padding(4)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("View today's report")
        }
    }
}
