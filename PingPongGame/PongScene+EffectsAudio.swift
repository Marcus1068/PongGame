import SpriteKit
import AVFoundation
#if os(iOS)
import UIKit
#endif

extension PongScene {
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
        particles.emissionAngle = ballVelocity.dx > 0 ? .pi : 0
        particles.emissionAngleRange = .pi / 3
        particles.particleSpeed = 90
        particles.particleSpeedRange = 35
        particles.position = position
        particles.particleBlendMode = .add
        addChild(particles)
        particles.run(.sequence([.wait(forDuration: 0.4), .removeFromParent()]))
    }

    func pulsePaddle(_ paddle: SKShapeNode) {
        paddle.run(.sequence([.scale(to: 1.15, duration: 0.05), .scale(to: 1.0, duration: 0.05)]))
    }

    func flashBall() {
        ball.run(.sequence([.fadeAlpha(to: 0.55, duration: 0.04), .fadeAlpha(to: 1, duration: 0.04)]))
    }

    func setupAudio() {
        let sampleRate: Double = 44_100
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }

        let engine = AVAudioEngine()
        engine.attach(blipPlayerNode)
        engine.connect(blipPlayerNode, to: engine.mainMixerNode, format: format)

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
            let wave: Float = sin(2 * .pi * frequency * time) >= 0 ? 0.35 : -0.35
            var envelope: Float = 1
            if frameIndex < attackLength {
                envelope = Float(frameIndex) / Float(max(attackLength, 1))
            } else if frameIndex >= releaseStart {
                envelope = Float(Int(frameCount) - frameIndex) / Float(max(Int(frameCount) - releaseStart, 1))
            }
            data[frameIndex] = wave * max(0, envelope)
        }
        return buffer
    }

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
                let decayProgress = Double(frameIndex - attackLength) / Double(max(Int(frameCount) - attackLength, 1))
                envelope = Float(exp(-4 * decayProgress))
            }
            data[frameIndex] = wave * envelope
        }
        return buffer
    }

    func playBlipSound(for side: WinnerSide) {
        let isEnabled = gameState?.isSoundEnabled ?? true
        guard isEnabled else { return }
        let buffer = side == .playerOne ? playerBlipBuffer : opponentBlipBuffer
        guard let buffer else { return }
        blipPlayerNode.scheduleBuffer(buffer, at: nil, completionHandler: nil)
    }

    func playWallSound() {
        guard gameState?.isSoundEnabled == true, let wallBounceBuffer else { return }
        blipPlayerNode.scheduleBuffer(wallBounceBuffer, at: nil, completionHandler: nil)
    }

    #if os(iOS)
    func triggerPaddleHaptics() {
        guard gameState?.isHapticsEnabled == true else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func triggerBounceHaptics() {
        guard gameState?.isHapticsEnabled == true else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
    #else
    func triggerPaddleHaptics() {}
    func triggerBounceHaptics() {}
    #endif
}
