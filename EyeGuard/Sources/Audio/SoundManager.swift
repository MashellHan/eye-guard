import AppKit
import AVFoundation
import Foundation
import os

/// Manages sound effects and ambient audio for EyeGuard.
///
/// Provides:
/// - Notification chimes when breaks start (gentle tone)
/// - Celebration sounds when breaks complete (ascending chime)
/// - Soft bell for tip rotation events
/// - Ambient nature sound generation during breaks (AVAudioEngine)
/// - Volume control and mute toggle via UserDefaults
///
/// Uses NSSound for system sound playback and AVAudioEngine for
/// procedurally generated ambient tones (no external audio files needed).
@MainActor
final class SoundManager: SoundPlaying {

    // MARK: - Singleton

    static let shared = SoundManager()

    // MARK: - Sound Types

    /// Categories of sounds played by EyeGuard.
    enum SoundType: String, Sendable {
        /// Gentle chime when a break notification appears.
        case breakStart
        /// Celebration tone when a break is completed.
        case breakComplete
        /// Soft bell when a new tip is shown.
        case tipRotation
        /// Alert tone for escalated notifications.
        case alert
        /// Ambient nature sound during breaks.
        case ambient
    }

    /// Ambient sound presets available during breaks.
    enum AmbientPreset: String, CaseIterable, Sendable {
        case rain = "Rain 🌧️"
        case ocean = "Ocean Waves 🌊"
        case forest = "Forest Birds 🌲"
        case wind = "Gentle Wind 🍃"
        case silence = "Silence 🔇"

        /// Description for the preference UI.
        var description: String {
            switch self {
            case .rain:    return "Soft rainfall pattern"
            case .ocean:   return "Rolling ocean waves"
            case .forest:  return "Forest atmosphere with bird calls"
            case .wind:    return "Gentle breeze rustling leaves"
            case .silence: return "No ambient sound"
            }
        }
    }

    // MARK: - State

    /// The AVAudioEngine for procedural sound generation.
    private var audioEngine: AVAudioEngine?

    /// Tone generator nodes for ambient sounds.
    private var toneNodes: [AVAudioSourceNode] = []

    /// Whether ambient sound is currently playing.
    private(set) var isAmbientPlaying: Bool = false

    /// Task managing the ambient sound lifecycle.
    private var ambientTask: Task<Void, Never>?

    /// Current volume level (0.0 – 1.0).
    var volume: Float {
        get {
            let stored = UserDefaults.standard.float(forKey: "soundVolume")
            return stored > 0 ? stored : 0.5
        }
        set {
            UserDefaults.standard.set(max(0, min(1, newValue)), forKey: "soundVolume")
        }
    }

    /// Whether all sounds are muted.
    var isMuted: Bool {
        get { UserDefaults.standard.bool(forKey: "soundMuted") }
        set { UserDefaults.standard.set(newValue, forKey: "soundMuted") }
    }

    /// The selected ambient preset for break periods.
    var selectedAmbientPreset: AmbientPreset {
        get {
            let raw = UserDefaults.standard.string(forKey: "ambientPreset") ?? ""
            return AmbientPreset(rawValue: raw) ?? .rain
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "ambientPreset")
        }
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Public API

    /// Plays a sound effect of the given type.
    ///
    /// Respects mute and volume settings. No-op if muted or volume is zero.
    ///
    /// - Parameter type: The sound effect category to play.
    func play(_ type: SoundType) {
        guard !isMuted, volume > 0 else { return }

        switch type {
        case .breakStart:
            playSystemSound(named: "Tink")
            Log.sound.info("Sound: break start chime")

        case .breakComplete:
            playSystemSound(named: "Hero")
            Log.sound.info("Sound: break complete celebration")

        case .tipRotation:
            playSystemSound(named: "Pop")
            Log.sound.info("Sound: tip rotation bell")

        case .alert:
            playSystemSound(named: "Sosumi")
            Log.sound.info("Sound: alert tone")

        case .ambient:
            // Ambient is handled by startAmbient/stopAmbient
            break
        }
    }

    /// Starts ambient nature sound generation for the current preset.
    ///
    /// The ambient sound plays continuously until `stopAmbient()` is called.
    /// Uses AVAudioEngine to generate tones procedurally.
    func startAmbient() {
        guard !isMuted, volume > 0 else { return }
        guard selectedAmbientPreset != .silence else { return }
        guard !isAmbientPlaying else { return }

        isAmbientPlaying = true
        startAmbientEngine()
        Log.sound.info("Ambient sound started: \(self.selectedAmbientPreset.rawValue)")
    }

    /// Stops any playing ambient sound.
    func stopAmbient() {
        guard isAmbientPlaying else { return }
        isAmbientPlaying = false
        stopAmbientEngine()
        Log.sound.info("Ambient sound stopped.")
    }

    /// Convenience: plays the break-start chime and starts ambient sound.
    func onBreakStart() {
        play(.breakStart)
        // Delay ambient start slightly so the chime is heard clearly
        ambientTask = Task {
            try? await Task.sleep(for: .seconds(1.0))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.startAmbient()
            }
        }
    }

    /// Convenience: stops ambient sound and plays the completion celebration.
    func onBreakComplete() {
        stopAmbient()
        play(.breakComplete)
    }

    /// Convenience: plays the tip rotation bell.
    func onTipRotation() {
        play(.tipRotation)
    }

    // MARK: - System Sound Playback

    /// Plays a named macOS system sound.
    ///
    /// Falls back to NSSound.beep() if the named sound is unavailable.
    ///
    /// - Parameter name: The system sound file name (without extension).
    private func playSystemSound(named name: String) {
        if let sound = NSSound(named: NSSound.Name(name)) {
            sound.volume = volume
            sound.play()
        } else {
            // Fallback to system beep
            NSSound.beep()
            Log.sound.warning("System sound '\(name)' not found, using beep fallback.")
        }
    }

    // MARK: - Ambient Sound Engine

    /// Starts the AVAudioEngine with a procedurally generated ambient tone.
    ///
    /// Each preset generates a different frequency/modulation pattern:
    /// - Rain: filtered noise at low frequencies
    /// - Ocean: slowly modulated low-frequency oscillation
    /// - Forest: higher frequency chirps with random timing
    /// - Wind: band-pass filtered noise with slow modulation
    private func startAmbientEngine() {
        let engine = AVAudioEngine()
        self.audioEngine = engine

        let mainMixer = engine.mainMixerNode
        let outputFormat = mainMixer.outputFormat(forBus: 0)
        let sampleRate = outputFormat.sampleRate

        guard sampleRate > 0 else {
            Log.sound.error("Invalid sample rate, cannot start ambient engine.")
            isAmbientPlaying = false
            return
        }

        let preset = selectedAmbientPreset
        let currentVolume = volume

        // Create a source node that generates audio samples
        var phase: Double = 0.0
        var modPhase: Double = 0.0

        let sourceNode = AVAudioSourceNode(format: outputFormat) {
            _, _, frameCount, bufferList -> OSStatus in

            let ablPointer = UnsafeMutableAudioBufferListPointer(bufferList)

            for frame in 0..<Int(frameCount) {
                let sample: Float

                switch preset {
                case .rain:
                    // Rain: low-pass filtered white noise
                    let noise = Float.random(in: -1.0...1.0)
                    // Simple low-pass approximation via mixing with previous
                    let lpf = noise * 0.15 * currentVolume * 0.3
                    sample = lpf

                case .ocean:
                    // Ocean: slow sine wave modulation of noise
                    let modFreq = 0.08 // Very slow modulation
                    modPhase += modFreq / sampleRate
                    let modulation = Float(sin(modPhase * 2.0 * .pi))
                    let envelope = (modulation + 1.0) / 2.0 // 0..1
                    let noise = Float.random(in: -1.0...1.0)
                    sample = noise * envelope * 0.12 * currentVolume * 0.3

                case .forest:
                    // Forest: gentle sine tone with random chirps
                    let baseFreq = 1200.0 + sin(modPhase * 0.5) * 400.0
                    phase += baseFreq / sampleRate
                    modPhase += 0.3 / sampleRate
                    let chirp = Float(sin(phase * 2.0 * .pi))
                    // Chirp envelope: mostly silent, occasional short bursts
                    let chirpEnvelope = Float(max(0, sin(modPhase * 2.0 * .pi)))
                    let thresholdedEnvelope = chirpEnvelope > 0.95 ? chirpEnvelope : 0.0
                    sample = chirp * thresholdedEnvelope * 0.08 * currentVolume * 0.3

                case .wind:
                    // Wind: band-filtered noise with slow volume modulation
                    modPhase += 0.15 / sampleRate
                    let modulation = Float(sin(modPhase * 2.0 * .pi))
                    let envelope = (modulation + 1.0) / 2.0 * 0.7 + 0.3
                    let noise = Float.random(in: -1.0...1.0)
                    sample = noise * envelope * 0.1 * currentVolume * 0.3

                case .silence:
                    sample = 0
                }

                for buffer in ablPointer {
                    let buf = buffer.mData?.assumingMemoryBound(to: Float.self)
                    buf?[frame] = sample
                }
            }

            return noErr
        }

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: mainMixer, format: outputFormat)
        toneNodes = [sourceNode]

        do {
            try engine.start()
            Log.sound.info("Ambient audio engine started for preset: \(preset.rawValue)")
        } catch {
            Log.sound.error("Failed to start ambient engine: \(error.localizedDescription)")
            isAmbientPlaying = false
        }
    }

    /// Stops the AVAudioEngine and cleans up nodes.
    private func stopAmbientEngine() {
        ambientTask?.cancel()
        ambientTask = nil

        guard let engine = audioEngine else { return }

        engine.stop()
        for node in toneNodes {
            engine.detach(node)
        }
        toneNodes = []
        audioEngine = nil
    }
}
