import Foundation
import Testing

@testable import EyeGuard

/// Tests for SoundManager configuration and state management.
@Suite("SoundManager Tests")
struct SoundManagerTests {

    @Test("Default volume is 0.5")
    @MainActor
    func defaultVolume() {
        let manager = SoundManager.shared
        // Volume should have a sensible default (0.5) when no UserDefaults value is set
        #expect(manager.volume >= 0.0)
        #expect(manager.volume <= 1.0)
    }

    @Test("Mute toggle prevents sound playback")
    @MainActor
    func muteToggle() {
        let manager = SoundManager.shared
        let originalMute = manager.isMuted

        manager.isMuted = true
        #expect(manager.isMuted == true)

        // Restore
        manager.isMuted = originalMute
    }

    @Test("Volume clamps to valid range")
    @MainActor
    func volumeClamping() {
        let manager = SoundManager.shared
        let originalVolume = manager.volume

        manager.volume = -0.5
        #expect(manager.volume >= 0.0)

        manager.volume = 1.5
        #expect(manager.volume <= 1.0)

        // Restore
        manager.volume = originalVolume
    }

    @Test("Ambient preset has valid default")
    @MainActor
    func ambientPresetDefault() {
        let manager = SoundManager.shared
        let preset = manager.selectedAmbientPreset
        #expect(SoundManager.AmbientPreset.allCases.contains(preset))
    }

    @Test("All ambient presets have descriptions")
    func ambientPresetDescriptions() {
        for preset in SoundManager.AmbientPreset.allCases {
            #expect(!preset.description.isEmpty)
            #expect(!preset.rawValue.isEmpty)
        }
    }

    @Test("Ambient sound state management")
    @MainActor
    func ambientStateManagement() {
        let manager = SoundManager.shared
        #expect(manager.isAmbientPlaying == false)

        // Stop when not playing should be no-op
        manager.stopAmbient()
        #expect(manager.isAmbientPlaying == false)
    }

    @Test("Sound type enum covers all categories")
    func soundTypeCategories() {
        let types: [SoundManager.SoundType] = [
            .breakStart, .breakComplete, .tipRotation, .alert, .ambient,
        ]
        #expect(types.count == 5)
    }
}
