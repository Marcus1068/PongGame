// Copyright 2026 Marcus Deuß
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

//
//  WinnerOverlay.swift
//  PongGame
//
//  Created by Marcus Deuß on 25.02.26.
//

import SwiftUI
import AVFoundation

struct WinnerOverlay: View {
    let winner: String
    var gameState: GameState
    @State private var cheerEngine: AVAudioEngine?

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 80))
                    .accessibilityHidden(true)
                    .foregroundStyle(
                        winner == "Player" ?
                            LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom) :
                            LinearGradient(colors: [.purple, .pink], startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: winner == "Player" ? .cyan.opacity(0.8) : .purple.opacity(0.8), radius: 20)

                VStack(spacing: 10) {
                    Text(winner == "Player"
                         ? (gameState.gameMode == .twoPlayers ? "Player 1 Wins!" : "Player Wins!")
                         : (gameState.gameMode == .twoPlayers ? "Player 2 Wins!" : "Computer Wins!"))
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: winner == "Player" ? [.cyan, .blue] : [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Final Score: \(gameState.playerScore) - \(gameState.computerScore)")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.9))
                }

                Button {
                    withAnimation {
                        gameState.reset()
                    }
                } label: {
                    Text("Play Again")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.cyan, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: Capsule()
                        )
                        .shadow(color: .cyan.opacity(0.5), radius: 10)
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .transition(.opacity.combined(with: .scale))
        .onAppear { playCrowdCheer() }
    }

    // MARK: - Audio

    /// Synthesises a retro crowd-cheer: pink-noise swell (crowd roar) blended
    /// with a short square-wave victory fanfare on top.
    private func playCrowdCheer() {
        let sampleRate: Double = 44100
        let duration: Double = 2.8
        let frameCount = AVAudioFrameCount(duration * sampleRate)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        let data = buffer.floatChannelData![0]

        // Pink-noise state (Paul Kellett algorithm)
        var b0: Float = 0, b1: Float = 0, b2: Float = 0
        var b3: Float = 0, b4: Float = 0, b5: Float = 0, b6: Float = 0

        // Victory fanfare: ascending square-wave notes
        let fanfare: [(freq: Double, start: Double, dur: Double)] = [
            (523.25, 0.05, 0.08),   // C5
            (659.25, 0.15, 0.08),   // E5
            (783.99, 0.25, 0.08),   // G5
            (1046.5, 0.35, 0.18),   // C6
            (1318.5, 0.55, 0.40),   // E6 – held finish
        ]

        for f in 0..<Int(frameCount) {
            let t = Double(f) / sampleRate

            // Pink noise (crowd roar)
            let white = Float.random(in: -1...1)
            b0 = 0.99886 * b0 + white * 0.0555179
            b1 = 0.99332 * b1 + white * 0.0750759
            b2 = 0.96900 * b2 + white * 0.1538520
            b3 = 0.86650 * b3 + white * 0.3104856
            b4 = 0.55000 * b4 + white * 0.5329522
            b5 = -0.7616 * b5 - white * 0.0168980
            b6 = white * 0.115926
            let pink = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362) * 0.11

            // Crowd envelope: 0.3 s attack → sustain → 0.8 s fade
            let attack  = Float(min(1.0, t / 0.3))
            let release = t > 2.0 ? Float(max(0.0, 1.0 - (t - 2.0) / 0.8)) : Float(1.0)
            let wobble  = Float(0.65 + 0.35 * sin(2.0 * .pi * 3.0 * t))
            let crowd   = pink * attack * release * wobble * 0.55

            // Victory fanfare (square waves, lower volume so crowd sits above)
            var melody: Float = 0.0
            for note in fanfare {
                if t >= note.start && t < note.start + note.dur {
                    let nt = t - note.start
                    let wave: Float = sin(2.0 * .pi * note.freq * t) >= 0 ? 0.20 : -0.20
                    let attackLen = 0.005
                    let releaseStart = note.dur * 0.65
                    var env: Float = 1.0
                    if nt < attackLen {
                        env = Float(nt / attackLen)
                    } else if nt > releaseStart {
                        env = Float(max(0.0, 1.0 - (nt - releaseStart) / (note.dur - releaseStart)))
                    }
                    melody += wave * env
                }
            }

            data[f] = crowd + melody
        }

        let engine = AVAudioEngine()
        let playerNode = AVAudioPlayerNode()
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        do {
            try engine.start()
            playerNode.play()
            playerNode.scheduleBuffer(buffer, at: nil, completionHandler: nil)
            cheerEngine = engine
        } catch { /* audio is non-critical */ }
    }
}
