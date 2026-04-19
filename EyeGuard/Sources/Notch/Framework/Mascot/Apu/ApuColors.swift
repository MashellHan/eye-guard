//
//  IslandApuColors.swift
//  MioGuard
//
//  Color palette for the Apu mascot, extracted from EyeGuard's MascotColors.
//  Shared between ApuMiniView and the full ApuView.
//

import SwiftUI

/// Color constants for the Apu mascot.
enum IslandApuColors {
    // MARK: - Body
    static let body = Color(red: 0.72, green: 0.90, blue: 0.82)
    static let bodyEdge = Color(red: 0.56, green: 0.83, blue: 0.71)

    // Body variants by expression
    static let concernedBody = Color(red: 0.82, green: 0.85, blue: 0.80)
    static let concernedEdge = Color(red: 0.70, green: 0.73, blue: 0.68)
    static let alertBody = Color(red: 0.96, green: 0.85, blue: 0.80)
    static let celebratingBody = Color(red: 0.78, green: 0.93, blue: 0.82)
    static let celebratingEdge = Color(red: 0.60, green: 0.85, blue: 0.68)
    static let sleepingBody = Color(red: 0.78, green: 0.85, blue: 0.90)

    // MARK: - Eyes
    static let eye = Color(red: 0.17, green: 0.17, blue: 0.17)
    static let eyeClosed = Color(red: 0.25, green: 0.25, blue: 0.25)
    static let eyeHighlight = Color.white.opacity(0.85)

    // MARK: - Mouth
    static let mouth = Color(red: 0.42, green: 0.61, blue: 0.50)
}
