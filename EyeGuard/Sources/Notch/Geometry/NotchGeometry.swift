//
//  NotchGeometry.swift
//  EyeGuard — Notch Module (Phase 1)
//
//  Pure geometry calculations for the Dynamic Notch panel.
//  Rewritten from mio-guard/ClaudeIsland/Core/NotchGeometry.swift
//  with Swift 6 Sendable semantics and no Combine dependency.
//

import CoreGraphics
import Foundation

/// Pure-function geometry for notch hit-testing and panel framing.
///
/// All coordinates are in **global screen space** (origin = bottom-left
/// of the primary screen) to match AppKit's `NSEvent.mouseLocation`.
struct NotchGeometry: Sendable, Equatable {
    let deviceNotchRect: CGRect
    let screenRect: CGRect
    let windowHeight: CGFloat
    var expansionWidth: CGFloat = 240

    // MARK: - Notch Rect

    /// The notch rect in screen coordinates, shifted by `horizontalOffset`.
    func notchScreenRect(horizontalOffset: CGFloat = 0) -> CGRect {
        CGRect(
            x: screenRect.midX - deviceNotchRect.width / 2 + horizontalOffset,
            y: screenRect.maxY - deviceNotchRect.height,
            width: deviceNotchRect.width,
            height: deviceNotchRect.height
        )
    }

    /// The opened panel rect in screen coordinates.
    /// Adds 10px padding for comfortable click targets.
    func openedScreenRect(for size: CGSize, horizontalOffset: CGFloat = 0) -> CGRect {
        let width = size.width + 10
        let height = size.height + 10
        return CGRect(
            x: screenRect.midX - width / 2 + horizontalOffset,
            y: screenRect.maxY - height,
            width: width,
            height: height
        )
    }

    /// The collapsed content rect, including dynamic-island wings.
    func collapsedScreenRect(
        expansionWidth: CGFloat? = nil,
        horizontalOffset: CGFloat = 0
    ) -> CGRect {
        let width = expansionWidth ?? self.expansionWidth
        let totalWidth = deviceNotchRect.width + width
        return CGRect(
            x: screenRect.midX - totalWidth / 2 + horizontalOffset,
            y: screenRect.maxY - deviceNotchRect.height,
            width: totalWidth,
            height: deviceNotchRect.height
        )
    }

    // MARK: - Hit Testing

    /// Returns true if `point` is inside the clickable notch zone
    /// (including expanded wings + slight padding for forgiveness).
    func isPointInNotch(
        _ point: CGPoint,
        expansionWidth: CGFloat? = nil,
        horizontalOffset: CGFloat = 0
    ) -> Bool {
        collapsedScreenRect(
            expansionWidth: expansionWidth,
            horizontalOffset: horizontalOffset
        )
        .insetBy(dx: -10, dy: -5)
        .contains(point)
    }

    /// Returns true if `point` is inside the opened panel rect.
    func isPointInOpenedPanel(
        _ point: CGPoint,
        size: CGSize,
        horizontalOffset: CGFloat = 0
    ) -> Bool {
        openedScreenRect(for: size, horizontalOffset: horizontalOffset).contains(point)
    }

    /// Returns true if `point` is OUTSIDE the opened panel (used to close).
    func isPointOutsidePanel(
        _ point: CGPoint,
        size: CGSize,
        horizontalOffset: CGFloat = 0
    ) -> Bool {
        !isPointInOpenedPanel(point, size: size, horizontalOffset: horizontalOffset)
    }
}
