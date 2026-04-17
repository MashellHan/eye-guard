//
//  NotchPopBanner.swift
//  EyeGuard — Notch Module (Phase 4)
//
//  Pop-style banner content shown inside the Notch panel while in
//  `.popping` state. Displays an icon + typewriter message and
//  auto-dismisses after a configured duration.
//

import SwiftUI

/// Reason tag for the pop banner, mapped to an icon + color hint.
enum NotchPopKind: Sendable, Equatable {
    case preBreak
    case breakStarted
    case breakCompleted
    case info

    var symbol: String {
        switch self {
        case .preBreak:       return "eye.trianglebadge.exclamationmark"
        case .breakStarted:   return "play.circle.fill"
        case .breakCompleted: return "checkmark.seal.fill"
        case .info:           return "bell.fill"
        }
    }

    var tint: Color {
        switch self {
        case .preBreak:       return .yellow
        case .breakStarted:   return .blue
        case .breakCompleted: return .green
        case .info:           return .cyan
        }
    }
}

struct NotchPopBanner: View {
    let kind: NotchPopKind
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: kind.symbol)
                .foregroundStyle(kind.tint)
                .font(.system(size: 13, weight: .semibold))

            TypewriterText(text: message)

            Spacer(minLength: 4)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
