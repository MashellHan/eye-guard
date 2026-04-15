import Foundation

/// Protocol for sound effect and ambient audio playback.
///
/// Abstracts the sound management layer for testability via dependency injection.
/// Production: `SoundManager` conforms to this protocol.
/// Tests: Inject a mock conforming to this protocol.
@MainActor
protocol SoundPlaying {
    /// Plays a sound effect of the given type.
    func play(_ type: SoundManager.SoundType)

    /// Starts ambient nature sound generation for the current preset.
    func startAmbient()

    /// Stops any playing ambient sound.
    func stopAmbient()

    /// Convenience: plays the break-start chime and starts ambient sound.
    func onBreakStart()

    /// Convenience: stops ambient sound and plays the completion celebration.
    func onBreakComplete()

    /// Convenience: plays the tip rotation bell.
    func onTipRotation()

    /// Whether ambient sound is currently playing.
    var isAmbientPlaying: Bool { get }

    /// Whether all sounds are muted.
    var isMuted: Bool { get set }
}
