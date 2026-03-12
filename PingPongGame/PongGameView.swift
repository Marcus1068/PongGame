//
//  PongGameView.swift
//  PongGame
//
//  Created by Marcus Deuß on 25.02.26.
//

import SwiftUI
import SpriteKit
import AVFoundation

struct PongGameView: View {
    @Bindable var gameState: GameState
    @State private var scene: PongScene?
    @State private var cheerEngine: AVAudioEngine?
    
    var body: some View {
        GeometryReader { _ in
            ZStack {
                // SpriteKit Scene
                if let scene {
                    SpriteView(scene: scene)
                        .ignoresSafeArea()
                }

                
                // Scoreboard overlay
                VStack {
                    HStack {
                        // Left paddle score
                        VStack {
                            Text(gameState.gameMode == .twoPlayers ? "Player 2" : "Computer")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                            Text("\(gameState.computerScore)")
                                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 72 : 48, weight: .bold, design: .rounded))
                                .foregroundStyle(gameState.isBlackAndWhite ? .white : .purple)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Right paddle score
                        VStack {
                            Text(gameState.gameMode == .twoPlayers ? "Player 1" : "Player")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                            Text("\(gameState.playerScore)")
                                .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 72 : 48, weight: .bold, design: .rounded))
                                .foregroundStyle(gameState.isBlackAndWhite ? .white : .cyan)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Controls hint
                    VStack(spacing: 8) {
#if os(macOS)
                        if gameState.gameMode == .twoPlayers {
                            Text("Player 1: W/S or ↑↓  •  Player 2: I/K")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        } else {
                            Text("Use W/S or Arrow Keys to move")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }
#else
                        if gameState.gameMode == .twoPlayers {
                            Text("Left side: Player 2  •  Right side: Player 1")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        } else {
                            Text("Touch and drag to move")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }
#endif
                    }
                    .padding(.bottom)
                }
                
                // Winner overlay
                if let winner = gameState.winner {
                    ZStack {
                        // Semi-transparent background
                        Color.black.opacity(0.8)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 30) {
                            // Trophy icon
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(
                                    winner == "Player" ? 
                                        LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom) :
                                        LinearGradient(colors: [.purple, .pink], startPoint: .top, endPoint: .bottom)
                                )
                                .shadow(color: winner == "Player" ? .cyan.opacity(0.8) : .purple.opacity(0.8), radius: 20)
                            
                            // Winner text
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
                            
                            // Play Again button
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
                
                // Pause overlay
                if gameState.isPaused && gameState.winner == nil {
                    ZStack {
                        // Tappable backdrop — tap anywhere to resume
                        Color.black.opacity(0.6)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.easeIn(duration: 0.15)) {
                                    gameState.isPaused = false
                                }
                            }
                        
                        VStack(spacing: 28) {
                            Image(systemName: "pause.circle.fill")
                                .font(.system(size: 100))
                                .foregroundStyle(.white.opacity(0.9))
                                .shadow(color: .white.opacity(0.3), radius: 20)
                            
                            Text("Game Paused")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            
                            Button {
                                withAnimation(.easeIn(duration: 0.15)) {
                                    gameState.isPaused = false
                                }
                            } label: {
                                Text("Resume")
                                    .font(.title2.bold())
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 48)
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
                    }
                    .transition(.opacity)
                }
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .onAppear {
            guard scene == nil else { return }
            let newScene = PongScene()
            newScene.scaleMode = .resizeFill
            newScene.gameState = gameState
            scene = newScene
        }
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
            // 3 Hz wobble gives the "waaaa" oscillation of a crowd
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

#Preview {
    PongGameView(gameState: GameState())
}
