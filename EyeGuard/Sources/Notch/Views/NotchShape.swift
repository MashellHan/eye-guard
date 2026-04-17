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
    var cornerRadius: CGFloat?

    init(cornerRadius: CGFloat? = nil) {
        self.cornerRadius = cornerRadius
    }

    func path(in rect: CGRect) -> Path {
        let radius = cornerRadius ?? min(rect.height, 14)
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
