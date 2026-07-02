// PongScene+EffectsAudio.swift
//
// Adds moment-to-moment feedback helpers for PongScene.
// This file creates simple hit/bounce effects, synthesizes short procedural
// sound buffers for the AVAudioEngine graph, and triggers optional iOS haptics.

import SpriteKit
import AVFoundation
#if os(iOS)
import UIKit
#endif

extension PongScene {
    /// Emits a short burst of particles from the contact point when the ball hits a paddle.
    func createPaddleHitEffect(at position: CGPoint, color: SKColor) {
        let particles = SKEmitterNode()
        particles.particleBirthRate = 180
        particles.numParticlesToEmit = 12
        particles.particleLifetime = 0.28
        particles.particleSize = CGSize(width: 3, height: 3)
        particles.particleScaleSpeed = -0.45
        particles.particleAlphaSpeed = -2.8
        particles.particleColor = color
        particles.particleColorBlendFactor = 1
        // Throw particles back along the ball's incoming direction so the hit
        // reads as an impact rather than a radial explosion.
        particles.emissionAngle = ballVelocity.dx > 0 ? .pi : 0
        particles.emissionAngleRange = .pi / 3
        particles.particleSpeed = 90
        particles.particleSpeedRange = 35
        particles.position = position
        particles.particleBlendMode = .add
        addChild(particles)
        particles.run(.sequence([.wait(forDuration: 0.4), .removeFromParent()]))
    }

    /// Briefly scales a paddle up and back down to emphasize contact.
    func pulsePaddle(_ paddle: SKShapeNode) {
        paddle.run(.sequence([.scale(to: 1.15, duration: 0.05), .scale(to: 1.0, duration: 0.05)]))
    }

    /// Flashes the ball's alpha for a single bounce frame.
    func flashBall() {
        ball.run(.sequence([.fadeAlpha(to: 0.55, duration: 0.04), .fadeAlpha(to: 1, duration: 0.04)]))
    }

    /// Builds the audio engine once and precomputes the short synthesized buffers
    /// used for paddle-hit and wall-bounce sound effects.
    func setupAudio() {
        let sampleRate: Double = 44_100
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }

        let engine = AVAudioEngine()
        engine.attach(blipPlayerNode)
        engine.connect(blipPlayerNode, to: engine.mainMixerNode, format: format)

        // Generate tiny in-memory PCM clips once up front; gameplay can then
        // schedule them with almost no runtime work.
        playerBlipBuffer = makeBlipBuffer(frequency: 480, sampleRate: sampleRate, format: format)
        opponentBlipBuffer = makeBlipBuffer(frequency: 320, sampleRate: sampleRate, format: format)
        wallBounceBuffer = makeWallBounceBuffer(sampleRate: sampleRate, format: format)

        do {
            try engine.start()
            blipPlayerNode.play()
            blipEngine = engine
            let volume = gameState?.isSoundEnabled == true ? Float(gameState?.soundVolume ?? 0.8) : 0
            blipPlayerNode.volume = volume
        } catch {
            blipEngine = nil
        }
    }

    /// Synthesizes a short square-wave-like "blip" with a quick attack/release
    /// envelope so the start and end do not click.
    func makeBlipBuffer(frequency: Double, sampleRate: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let duration: Double = 0.055
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        guard let data = buffer.floatChannelData?[0] else { return nil }

        let attackLength = Int(0.003 * sampleRate)
        let releaseStart = Int(Double(frameCount) * 0.6)
        for frameIndex in 0 ..< Int(frameCount) {
            let time = Double(frameIndex) / sampleRate
            // Using the sign of the sine wave produces a compact square-wave-like
            // tone that feels more arcade-like than a pure sine.
            let wave: Float = sin(2 * .pi * frequency * time) >= 0 ? 0.35 : -0.35
            var envelope: Float = 1
            if frameIndex < attackLength {
                envelope = Float(frameIndex) / Float(max(attackLength, 1))
            } else if frameIndex >= releaseStart {
                // Fade out the tail to avoid a harsh stop at the buffer boundary.
                envelope = Float(Int(frameCount) - frameIndex) / Float(max(Int(frameCount) - releaseStart, 1))
            }
            data[frameIndex] = wave * max(0, envelope)
        }
        return buffer
    }

    /// Synthesizes a very short damped sine hit for top/bottom wall bounces.
    func makeWallBounceBuffer(sampleRate: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let duration: Double = 0.035
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        guard let data = buffer.floatChannelData?[0] else { return nil }

        let attackLength = Int(0.001 * sampleRate)
        for frameIndex in 0 ..< Int(frameCount) {
            let time = Double(frameIndex) / sampleRate
            let wave = Float(sin(2 * .pi * 200 * time)) * 0.3
            let envelope: Float
            if frameIndex < attackLength {
                envelope = Float(frameIndex) / Float(max(attackLength, 1))
            } else {
                // Exponential decay makes the bounce sound like a quick, muted tap
                // instead of a steady tone.
                let decayProgress = Double(frameIndex - attackLength) / Double(max(Int(frameCount) - attackLength, 1))
                envelope = Float(exp(-4 * decayProgress))
            }
            data[frameIndex] = wave * envelope
        }
        return buffer
    }

    /// Plays the precomputed paddle-hit sound for the specified side.
    func playBlipSound(for side: WinnerSide) {
        let isEnabled = gameState?.isSoundEnabled ?? true
        guard isEnabled else { return }
        let buffer = side == .playerOne ? playerBlipBuffer : opponentBlipBuffer
        guard let buffer else { return }
        blipPlayerNode.scheduleBuffer(buffer, at: nil, completionHandler: nil)
    }

    /// Plays the precomputed wall-bounce sound if sound effects are enabled.
    func playWallSound() {
        guard gameState?.isSoundEnabled == true, let wallBounceBuffer else { return }
        blipPlayerNode.scheduleBuffer(wallBounceBuffer, at: nil, completionHandler: nil)
    }

    #if os(iOS)
    /// Triggers a light impact when the ball hits a paddle.
    func triggerPaddleHaptics() {
        guard gameState?.isHapticsEnabled == true else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Triggers a softer impact for top/bottom wall bounces.
    func triggerBounceHaptics() {
        guard gameState?.isHapticsEnabled == true else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
    #else
    /// No-op on platforms that do not provide impact haptics.
    func triggerPaddleHaptics() {}
    /// No-op on platforms that do not provide impact haptics.
    func triggerBounceHaptics() {}
    #endif
}
