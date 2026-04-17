//
//  NSScreen+Notch.swift
//  EyeGuard — Notch Module (Phase 1)
//
//  NSScreen extensions for detecting the hardware notch and
//  built-in display. Rewritten from mio-guard's `Ext+NSScreen.swift`.
//

import AppKit
import CoreGraphics

extension NSScreen {
    /// Size of the notch on this screen, pixel-perfect from macOS APIs.
    /// Falls back to a typical MacBook notch size on non-notch displays
    /// so the panel still has a valid drag/hit rect.
    var notchSize: CGSize {
        guard safeAreaInsets.top > 0 else {
            return CGSize(width: 224, height: 38)
        }

        let notchHeight = safeAreaInsets.top
        let fullWidth = frame.width
        let leftPadding = auxiliaryTopLeftArea?.width ?? 0
        let rightPadding = auxiliaryTopRightArea?.width ?? 0

        guard leftPadding > 0, rightPadding > 0 else {
            return CGSize(width: 180, height: notchHeight)
        }

        // +4 matches boring.notch's measurement for visual alignment.
        let notchWidth = fullWidth - leftPadding - rightPadding + 4
        return CGSize(width: notchWidth, height: notchHeight)
    }

    /// Whether this is the built-in display (typically the MacBook screen).
    var isBuiltinDisplay: Bool {
        guard let screenNumber = deviceDescription[
            NSDeviceDescriptionKey("NSScreenNumber")
        ] as? CGDirectDisplayID else {
            return false
        }
        return CGDisplayIsBuiltin(screenNumber) != 0
    }

    /// The built-in display if present, otherwise `NSScreen.main`.
    static var builtin: NSScreen? {
        if let builtin = screens.first(where: { $0.isBuiltinDisplay }) {
            return builtin
        }
        return NSScreen.main
    }

    /// Whether this screen has a physical camera-housing notch.
    var hasPhysicalNotch: Bool {
        safeAreaInsets.top > 0
    }

    /// Stable per-screen identifier for settings persistence.
    /// Prefers vendor+model+serial (survives reboots), falls back
    /// to CGDirectDisplayID for displays without EDID data.
    var persistentID: String {
        guard let displayID = deviceDescription[
            NSDeviceDescriptionKey("NSScreenNumber")
        ] as? CGDirectDisplayID else {
            return "0"
        }
        let vendor = CGDisplayVendorNumber(displayID)
        let model = CGDisplayModelNumber(displayID)
        let serial = CGDisplaySerialNumber(displayID)
        if vendor == 0, model == 0, serial == 0 {
            return String(displayID)
        }
        return "\(vendor)-\(model)-\(serial)"
    }
}
