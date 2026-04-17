import Foundation
import SwiftUI

/// Observable store that persists `NotchCustomization` via UserDefaults.
///
/// A single global default is used — per-screen persistence can be
/// added later by keying on `NSScreen.persistentID`. The store owns
/// the serialization format (JSON) and clamps the horizontal offset
/// on every write so the UI never has to guard against invalid state.
@MainActor
@Observable
public final class NotchCustomizationStore {

    /// Current customization. Writing this value persists immediately.
    public var customization: NotchCustomization {
        didSet {
            persist()
        }
    }

    private enum Keys {
        static let customization = "eyeguard.notch.customization"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Keys.customization),
           let decoded = try? JSONDecoder().decode(NotchCustomization.self, from: data) {
            self.customization = decoded
        } else {
            self.customization = .default
        }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(customization) else { return }
        defaults.set(data, forKey: Keys.customization)
    }

    // MARK: - Convenience mutators

    public func setHorizontalOffset(_ offset: CGFloat) {
        customization = customization.withOffset(offset)
    }

    public func setHoverSpeed(_ speed: NotchHoverSpeed) {
        var copy = customization
        copy.hoverSpeed = speed
        customization = copy
    }

    public func setShowOnExternalDisplays(_ flag: Bool) {
        var copy = customization
        copy.showOnExternalDisplays = flag
        customization = copy
    }

    /// Reset to default values. Used by the "Restore Defaults" button.
    public func resetToDefault() {
        customization = .default
    }
}
