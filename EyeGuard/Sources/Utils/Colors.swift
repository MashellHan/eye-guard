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

    /// Primary label on the dark Notch panel. ~85 % opaque white reads as the high-contrast
    /// foreground without becoming a harsh pure-white against the blurred backdrop.
    static let notchPrimaryText = Color.white.opacity(0.85)

    /// Secondary label (e.g. the "Health Score" caption next to a value). Low enough to
    /// recede behind the primary value but still meets WCAG AA on the dark Notch.
    static let notchSecondaryText = Color.white.opacity(0.7)

    /// Tertiary / unit text (e.g. "/ 100"). Deliberately faint — context, not data.
    static let notchTertiaryText = Color.white.opacity(0.5)

    /// Hint copy (e.g. "hover any row …"). The dimmest readable tier; never used for data.
    static let notchHintText = Color.white.opacity(0.4)

    /// Empty/track portion of a progress bar on the Notch. 10 % keeps the track visible
    /// without competing with the filled portion's saturated colour.
    static let notchBarTrack = Color.white.opacity(0.1)

    /// Row background when hovered. 8 % is the lightest tint that still registers as
    /// "this row is active" against the Notch's blurred dark backdrop.
    static let notchHoverTint = Color.white.opacity(0.08)

    // MARK: - Menu-bar popover

    /// Menu-bar popover background. `windowBackgroundColor` follows light/dark
    /// automatically (cited verbatim by `swift-style.md#colors`).
    static let popoverBackground = Color(NSColor.windowBackgroundColor)
}
