//
//  IslandPixelCatMascot.swift
//  MioGuard
//
//  Adapter that wraps the existing IslandPixelCharacterView to conform
//  to MascotRenderable, enabling it to be used in the unified
//  MascotContainer alongside Apu.
//

import SwiftUI

/// Wraps IslandPixelCharacterView as a MascotRenderable.
struct IslandPixelCatMascot: View, MascotRenderable {

    let mascotId = "pixel_cat"
    let expression: MascotExpression

    var preferredSize: CGSize { CGSize(width: 80, height: 80) }
    var supportsNotchMode: Bool { true }

    var body: some View {
        IslandPixelCharacterView(state: mapExpression(expression))
            .frame(width: IslandPixelCharacterView.canvasW, height: IslandPixelCharacterView.canvasH)
    }

    /// Maps unified MascotExpression to IslandPixelCharacterView's AnimationState.
    private func mapExpression(_ expr: MascotExpression) -> AnimationState {
        switch expr {
        case .idle, .sleeping, .happy:
            .idle
        case .thinking, .exercising:
            .thinking
        case .alert, .encouraging:
            .needsYou
        case .concerned, .tired:
            .error
        case .celebrating:
            .done
        case .waiting:
            .idle
        }
    }
}
