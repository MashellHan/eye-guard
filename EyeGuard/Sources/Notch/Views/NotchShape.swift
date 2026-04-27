//
//  NotchShape.swift
//  EyeGuard — Notch Module (Phase 1)
//
//  Rounded-notch SwiftUI Shape used to mask the collapsed pill.
//

import SwiftUI

/// A notch-shaped rounded rectangle. Top edges are sharp (flush with
/// the screen bezel), bottom edges are rounded. The corner radius is
/// proportional to the shape height.
struct NotchShape: Shape {
    var cornerRadius: CGFloat = 14

    /// Expose `cornerRadius` to SwiftUI's animation system so spring/ease
    /// drivers can interpolate the radius continuously (B12). Without this
    /// the shape re-paints with a stepped radius and the morph looks janky.
    var animatableData: CGFloat {
        get { cornerRadius }
        set { cornerRadius = newValue }
    }

    init(cornerRadius: CGFloat = 14) {
        self.cornerRadius = cornerRadius
    }

    func path(in rect: CGRect) -> Path {
        let radius = cornerRadius
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - radius),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}
