//
//  BreakdownRowView.swift
//  EyeGuard — Shared UI
//
//  Shared health-score breakdown row + click-popover. Extracted from MenuBarView
//  and HealthScoreSection (Notch) which had ~95% identical layout/behavior, only
//  diverging on font / color / width. The visual differences are encoded in
//  `BreakdownTheme` so business semantics (hover tint, click-to-popover, bar
//  ratio math) live in exactly one place.
//
//  R1 (architecture rule): this view reads `ScoreComponent` (a model). It does
//  NOT call into BreakScheduler / ActivityMonitor / business logic.
//

import SwiftUI

/// Visual theme for `BreakdownRowView` — selects the per-mode (menubar vs notch)
/// font / color / width tokens. Using `switch` ensures any new theme case forces
/// the compiler to flag missing token mappings.
@MainActor
enum BreakdownTheme {
    case menubar
    case notch

    var labelFont: Font {
        switch self {
        case .menubar: return .caption2
        case .notch:   return .system(size: 10, weight: .medium)
        }
    }

    var scoreFont: Font {
        switch self {
        case .menubar: return .system(.caption2, design: .monospaced).bold()
        case .notch:   return .system(size: 10, design: .monospaced).weight(.semibold)
        }
    }

    var primaryText: Color {
        switch self {
        case .menubar: return .primary
        case .notch:   return AppColors.notchPrimaryText
        }
    }

    var secondaryText: Color {
        switch self {
        case .menubar: return .secondary
        case .notch:   return AppColors.notchSecondaryText
        }
    }

    var hoverBackground: Color {
        switch self {
        case .menubar: return Color.primary.opacity(0.06)
        case .notch:   return AppColors.notchHoverTint
        }
    }

    var barTrack: Color {
        switch self {
        case .menubar: return Color(NSColor.quaternaryLabelColor)
        case .notch:   return AppColors.notchBarTrack
        }
    }

    var labelWidth: CGFloat {
        switch self {
        case .menubar: return 58
        case .notch:   return 64
        }
    }

    /// nil means "use intrinsic width" (menubar lets the score text size itself);
    /// notch wants a fixed trailing-aligned column for tidy alignment.
    var scoreWidth: CGFloat? {
        switch self {
        case .menubar: return nil
        case .notch:   return 36
        }
    }

    var hStackSpacing: CGFloat {
        switch self {
        case .menubar: return 4
        case .notch:   return 6
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .menubar: return 0
        case .notch:   return 4
        }
    }
}

/// Single row in the health-score breakdown: label, score/maxScore, progress bar.
/// Hover tints the background; tapping toggles a rich popover (see file header for
/// why click — not hover — is the popover trigger).
@MainActor
struct BreakdownRowView: View {
    let component: ScoreComponent
    let theme: BreakdownTheme

    /// Per-row hover/click state. Each row instance owns its own state — the old
    /// implementations stored a single shared "which row" String at the parent
    /// level, but since only one row can be hovered/tapped at a time the
    /// behavior is identical and the per-row state is simpler.
    @State private var hovered = false
    @State private var clicked = false

    private var ratio: Double {
        Double(component.score) / Double(max(component.maxScore, 1))
    }

    private var isPerfect: Bool {
        component.score >= component.maxScore
    }

    /// Detail = popover content. MenuBar synthesises placeholder rows before the
    /// first breakdown is computed; those use empty explanations and should NOT
    /// react to hover or open a popover (matches the pre-refactor `hasDetail`
    /// guard in MenuBarView.breakdownRow).
    private var hasDetail: Bool {
        !component.explanation.isEmpty
    }

    var body: some View {
        HStack(spacing: theme.hStackSpacing) {
            Text(component.name)
                .font(theme.labelFont)
                .foregroundStyle(theme.secondaryText)
                .frame(width: theme.labelWidth, alignment: .leading)

            scoreText

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.barTrack)
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor)
                        .frame(width: geometry.size.width * CGFloat(ratio), height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, theme.horizontalPadding)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(hovered ? theme.hoverBackground : .clear)
        )
        .onHover { inside in
            guard hasDetail else { return }
            hovered = inside
        }
        .onTapGesture {
            guard hasDetail else { return }
            clicked.toggle()
        }
        .popover(
            isPresented: Binding(
                get: { clicked && hasDetail },
                set: { if !$0 { clicked = false } }
            ),
            arrowEdge: .leading
        ) {
            BreakdownPopoverContent(component: component, theme: theme)
        }
    }

    @ViewBuilder
    private var scoreText: some View {
        let label = Text("\(component.score)/\(component.maxScore)")
            .font(theme.scoreFont)
            .foregroundStyle(theme.primaryText)
        if let width = theme.scoreWidth {
            label.frame(width: width, alignment: .trailing)
        } else {
            label
        }
    }

    private var barColor: Color {
        if ratio >= 0.8 { return .green }
        if ratio >= 0.5 { return .yellow }
        if ratio >= 0.3 { return .orange }
        return .red
    }
}

/// Rich popover body — SF Symbol header, name + score, multi-line explanation.
/// Width is fixed at 260 in both modes (the popover floats outside the host
/// window so menubar/notch sizing constraints don't apply).
@MainActor
struct BreakdownPopoverContent: View {
    let component: ScoreComponent
    let theme: BreakdownTheme

    private var isPerfect: Bool {
        component.score >= component.maxScore
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: isPerfect ? "checkmark.seal.fill" : "info.circle.fill")
                    .foregroundStyle(isPerfect ? .green : .blue)
                    .font(.system(size: 13))
                Text(component.name)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                Spacer()
                Text("\(component.score) / \(component.maxScore)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Divider()
            Text(isPerfect ? "满分 — 保持现状" : "还能拿满分")
                .font(.caption2)
                .foregroundStyle(isPerfect ? .green : .blue)
            Text(component.explanation)
                .font(.caption)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(width: 260)
    }
}
