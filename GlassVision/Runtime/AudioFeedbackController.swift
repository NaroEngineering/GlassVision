//
//  AudioFeedbackController.swift
//  GlassVision
//
//  Created by Codex on 4/9/26.
//

import AVFoundation
import Foundation
import RealityKit

@MainActor
final class AudioFeedbackController {
    enum Cue: String {
        case glassPickup
        case portalActivation
        case invalidSelection
        case validSelection
        case extraction
        case completion

        var debugLabel: String {
            switch self {
            case .glassPickup:
                return "Glass Pickup"
            case .portalActivation:
                return "Portal Activation"
            case .invalidSelection:
                return "Invalid Selection"
            case .validSelection:
                return "Valid Selection"
            case .extraction:
                return "Extraction"
            case .completion:
                return "Completion"
            }
        }
    }

    private(set) var lastCue: Cue?
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)
    private var cachedBuffers: [Cue: AVAudioPCMBuffer] = [:]
    private var engineConfigured = false
    private var engineFailed = false

    func play(_ cue: Cue, on entity: Entity? = nil) {
        lastCue = cue
        _ = entity

        guard let format, configureEngineIfNeeded(format: format) else {
            return
        }

        let buffer = cachedBuffers[cue] ?? makeBuffer(for: cue, format: format)
        guard let buffer else {
            return
        }

        cachedBuffers[cue] = buffer
        if player.isPlaying {
            player.stop()
        }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        player.play()
    }

    private func configureEngineIfNeeded(format: AVAudioFormat) -> Bool {
        if engineConfigured {
            return true
        }

        if engineFailed {
            return false
        }

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.prepare()

        do {
            try engine.start()
            engineConfigured = true
            return true
        } catch {
            engineFailed = true
            return false
        }
    }

    private func makeBuffer(for cue: Cue, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let noteProfile: [(frequency: Double, duration: Double, amplitude: Float)] = {
            switch cue {
            case .glassPickup:
                return [(392, 0.08, 0.13), (466, 0.06, 0.11)]
            case .portalActivation:
                return [(440, 0.08, 0.12), (554, 0.09, 0.11), (659, 0.1, 0.1)]
            case .invalidSelection:
                return [(220, 0.09, 0.12), (196, 0.1, 0.1)]
            case .validSelection:
                return [(523, 0.08, 0.12), (659, 0.11, 0.11)]
            case .extraction:
                return [(659, 0.07, 0.11), (784, 0.08, 0.1), (988, 0.09, 0.08)]
            case .completion:
                return [(523, 0.1, 0.12), (659, 0.1, 0.11), (784, 0.12, 0.1), (1046, 0.18, 0.08)]
            }
        }()

        let pauseBetweenNotes = 0.018
        let totalDuration = noteProfile.reduce(0.0) { $0 + $1.duration } +
            (Double(max(noteProfile.count - 1, 0)) * pauseBetweenNotes)
        let frameCapacity = AVAudioFrameCount(totalDuration * format.sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity) else {
            return nil
        }

        buffer.frameLength = frameCapacity
        guard let channelData = buffer.floatChannelData?[0] else {
            return nil
        }

        let sampleRate = format.sampleRate
        var frameIndex: Int = 0

        for (noteIndex, note) in noteProfile.enumerated() {
            let noteFrameCount = Int(note.duration * sampleRate)
            for localFrame in 0..<noteFrameCount {
                let progress = Float(localFrame) / max(Float(noteFrameCount - 1), 1)
                let envelope = sin(progress * .pi)
                let time = Double(localFrame) / sampleRate
                let sample = sin(2 * .pi * note.frequency * time)
                channelData[frameIndex] = Float(sample) * note.amplitude * envelope
                frameIndex += 1
            }

            if noteIndex < noteProfile.count - 1 {
                let pauseFrames = Int(pauseBetweenNotes * sampleRate)
                for _ in 0..<pauseFrames {
                    channelData[frameIndex] = 0
                    frameIndex += 1
                }
            }
        }

        while frameIndex < Int(frameCapacity) {
            channelData[frameIndex] = 0
            frameIndex += 1
        }

        return buffer
    }
}
