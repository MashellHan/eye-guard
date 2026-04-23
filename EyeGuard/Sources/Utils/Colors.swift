//
//  Colors.swift
//  EyeGuard — Utilities
//
//  Centralised semantic colours. Convention rule (docs/conventions/swift-style.md#colors)
//  bans hard-coded `Color.white` / fixed RGB values: every UI surface must route through
//  either a system colour (`NSColor.windowBackgroundColor` &c.) or a named entry below.
//
//  Why grouped here rather than per-view:
//  - The Notch overlay is currently presented with a fixed dark backdrop, so today
//    `Color.white.opacity(...)` happens to render correctly. The wrapper colours below
//    document the *intent* (primary text, secondary text, track, hover tint) so a future
//    light-mode Notch — or simply removing `.preferredColorScheme(.dark)` — will not
//    require hunting through view files to fix contrast.
//  - Sharing the names across MenuBar (light) and Notch (dark) lets reviewers grep
//    for any new hard-coded colour as a hard rule violation.
//

import SwiftUI
import AppKit

enum AppColors {
    // MARK: - Notch overlay (dark backdrop)

    /// Primary label on the dark Notch panel. Pure white for max contrast —
    /// B8 (2026-04-23) bumped from 0.85 → 1.0 after user reported "字体是
    /// 浅色的 看不太清楚". On the solid black backdrop this passes WCAG AA
    /// at any size.
    static let notchPrimaryText = Color.white

    /// Secondary label (e.g. the "Health Score" caption next to a value).
    /// B8: 0.7 → 0.85 to clear WCAG AA 4.5:1 even at small caption sizes.
    static let notchSecondaryText = Color.white.opacity(0.85)

    /// Tertiary / unit text (e.g. "/ 100"). Context, not data — but still
    /// readable. B8: 0.5 → 0.7.
    static let notchTertiaryText = Color.white.opacity(0.7)

    /// Hint copy (e.g. "hover any row …"). The dimmest readable tier; never
    /// used for data. B8: 0.4 → 0.6 (still subordinate to tertiary).
    static let notchHintText = Color.white.opacity(0.6)

    /// Empty/track portion of a progress bar on the Notch. 15 % keeps the
    /// track visible without competing with the filled portion's saturated
    /// colour. B8: 0.10 → 0.15.
    static let notchBarTrack = Color.white.opacity(0.15)

    /// Row background when hovered. 12 % is the lightest tint that still
    /// registers as "this row is active" against the Notch's blurred dark
    /// backdrop. B8: 0.08 → 0.12.
    static let notchHoverTint = Color.white.opacity(0.12)

    // MARK: - Menu-bar popover

    /// Menu-bar popover background. `windowBackgroundColor` follows light/dark
    /// automatically (cited verbatim by `swift-style.md#colors`).
    static let popoverBackground = Color(NSColor.windowBackgroundColor)
}
