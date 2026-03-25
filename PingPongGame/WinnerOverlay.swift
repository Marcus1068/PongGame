import SwiftUI
import AVFoundation

struct WinnerOverlay: View {
    let winner: WinnerSide
    var gameState: GameState
    let onReplay: () -> Void
    let onShowStats: () -> Void

    @State private var cheerEngine: AVAudioEngine?
    @State private var cheerPlayer = AVAudioPlayerNode()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric private var winnerFontSize: CGFloat = 56

    var body: some View {
        ZStack {
            Color.black.opacity(0.82)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 74))
                    .foregroundStyle(LinearGradient(colors: winner == .playerOne ? [.cyan, .blue] : [.purple, .pink], startPoint: .top, endPoint: .bottom))
                    .accessibilityHidden(true)

                Text(String(localized: "\(gameState.gameMode.displayName(for: winner)) Wins!"))
                    .font(.system(size: winnerFontSize, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(LinearGradient(colors: winner == .playerOne ? [.cyan, .blue] : [.purple, .pink], startPoint: .leading, endPoint: .trailing))

                VStack(spacing: 8) {
                    Text(String(localized: "Final Score: \(gameState.playerScore) - \(gameState.opponentScore)"))
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.95))
                    Text(String(localized: "Longest Rally: \(gameState.currentMatchStats.longestRally)   •   Boosts: \(gameState.currentMatchStats.speedBoostsTriggered)"))
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.72))
                }

                HStack(spacing: 12) {
                    Button("Play Again") {
                        withAnimation {
                            gameState.resetToMenu()
                        }
                    }
                    .buttonStyle(WinnerCapsuleButtonStyle(colors: [.cyan, .purple], foreground: .white))

                    Button("Stats", action: onShowStats)
                        .buttonStyle(WinnerCapsuleButtonStyle(colors: [.white.opacity(0.16), .white.opacity(0.08)], foreground: .white))
                }

                if gameState.canReplayLastPoint {
                    Button("Replay Last Point", action: onReplay)
                        .buttonStyle(WinnerCapsuleButtonStyle(colors: [.orange, .pink], foreground: .white))
                }
            }
            .padding(32)
        }
        .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale))
        .onAppear { playCrowdCheer() }
        .onDisappear(perform: stopCrowdCheer)
    }

    private func playCrowdCheer() {
        guard gameState.isSoundEnabled else { return }

        let sampleRate: Double = 44_100
        let duration: Double = 2.3
        let frameCount = AVAudioFrameCount(duration * sampleRate)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let data = buffer.floatChannelData?[0] else { return }
        buffer.frameLength = frameCount

        var b0: Float = 0
        var b1: Float = 0
        var b2: Float = 0
        var b3: Float = 0
        var b4: Float = 0
        var b5: Float = 0
        var b6: Float = 0

        let fanfare: [(freq: Double, start: Double, dur: Double)] = [
            (523.25, 0.05, 0.08),
            (659.25, 0.15, 0.08),
            (783.99, 0.25, 0.08),
            (1046.5, 0.35, 0.18),
            (1318.5, 0.55, 0.34)
        ]

        for frame in 0 ..< Int(frameCount) {
            let time = Double(frame) / sampleRate
            let white = Float.random(in: -1 ... 1)
            b0 = 0.99886 * b0 + white * 0.0555179
            b1 = 0.99332 * b1 + white * 0.0750759
            b2 = 0.96900 * b2 + white * 0.1538520
            b3 = 0.86650 * b3 + white * 0.3104856
            b4 = 0.55 * b4 + white * 0.5329522
            b5 = -0.7616 * b5 - white * 0.016898
            b6 = white * 0.115926
            let pink = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362) * 0.11

            let attack = Float(min(1, time / 0.3))
            let release = time > 1.7 ? Float(max(0, 1 - (time - 1.7) / 0.6)) : 1
            let crowd = pink * attack * release * 0.48

            var melody: Float = 0
            for note in fanfare where time >= note.start && time < note.start + note.dur {
                let localTime = time - note.start
                let wave: Float = sin(2 * .pi * note.freq * time) >= 0 ? 0.16 : -0.16
                let attackTime = 0.005
                let releaseStart = note.dur * 0.65
                var envelope: Float = 1
                if localTime < attackTime {
                    envelope = Float(localTime / attackTime)
                } else if localTime > releaseStart {
                    envelope = Float(max(0, 1 - (localTime - releaseStart) / (note.dur - releaseStart)))
                }
                melody += wave * envelope
            }

            data[frame] = (crowd + melody) * Float(gameState.soundVolume)
        }

        let engine = AVAudioEngine()
        engine.attach(cheerPlayer)
        engine.connect(cheerPlayer, to: engine.mainMixerNode, format: format)

        do {
            try engine.start()
            cheerPlayer.play()
            cheerPlayer.scheduleBuffer(buffer, at: nil, completionHandler: nil)
            cheerEngine = engine
        } catch {
            stopCrowdCheer()
        }
    }

    private func stopCrowdCheer() {
        cheerPlayer.stop()
        cheerEngine?.stop()
        cheerEngine = nil
    }
}

private struct WinnerCapsuleButtonStyle: PrimitiveButtonStyle {
    let colors: [Color]
    let foreground: Color

    func makeBody(configuration: Configuration) -> some View {
        Button(action: configuration.trigger) {
            configuration.label
                .font(.headline)
                .foregroundStyle(foreground)
                .padding(.horizontal, 26)
                .padding(.vertical, 14)
                .background(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
