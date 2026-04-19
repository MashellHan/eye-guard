//
//  IslandMascotProtocol.swift
//  MioGuard
//
//  Unified protocol for mascot rendering. Both Apu (Eye Guard) and
//  Pixel Cat (Island) conform to this protocol, enabling the MascotContainer
//  to render either mascot in Notch, floating, or overlay contexts.
//

import SwiftUI

// MARK: - Expression

/// Unified mascot expressions shared across all mascot types.
enum MascotExpression: String, CaseIterable, Sendable {
    // Shared
    case idle
    case happy
    case concerned
    case sleeping
    case celebrating

    // Eye Guard specific
    case tired
    case exercising
    case encouraging

    // Island specific
    case thinking
    case waiting
    case alert
}

// MARK: - Display Mode

/// Context in which the mascot is displayed.
enum MascotDisplayMode: Sendable {
    /// Inside the Notch bar (~30pt).
    case notch
    /// Floating window (~120pt for Apu, ~80pt for cat).
    case floating
    /// On a fullscreen overlay (~80pt).
    case overlay
}

// MARK: - Protocol

/// A renderable mascot character.
protocol MascotRenderable: View {
    /// Unique identifier for this mascot type.
    var mascotId: String { get }

    /// The current expression/state.
    var expression: MascotExpression { get }

    /// Preferred size at full resolution.
    var preferredSize: CGSize { get }

    /// Whether this mascot supports rendering at Notch size (~30pt).
    var supportsNotchMode: Bool { get }
}

// MARK: - Container

/// Universal container that sizes any mascot for its display context.
struct MascotContainer<M: MascotRenderable>: View {
    let mascot: M
    let mode: MascotDisplayMode

    var body: some View {
        mascot
            .frame(width: size.width, height: size.height)
    }

    private var size: CGSize {
        switch mode {
        case .notch:
            CGSize(width: 30, height: 30)
        case .floating:
            mascot.preferredSize
        case .overlay:
            CGSize(width: 80, height: 80)
        }
    }
}

// MARK: - Voice

/// Voice style for TTS. Apu speaks Chinese; Pixel Cat uses SFX only.
enum MascotVoice: Sendable {
    case apu
    case cat
}

/// A mascot that can speak or play sound effects.
protocol MascotSpeaker {
    func speak(_ text: String, voice: MascotVoice)
}
