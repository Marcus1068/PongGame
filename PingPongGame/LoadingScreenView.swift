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
//  LoadingScreenView.swift
//  PongGame
//
//  Created by Marcus Deuß on 25.02.26.
//

import SwiftUI
import AVFoundation

struct LoadingScreenView: View {
    @State private var isAnimating = false
    @State private var ballOffset: CGFloat = 0
    @State private var showContent = false
    @State private var audioEngine: AVAudioEngine?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [.black, .purple.opacity(0.3), .cyan.opacity(0.3), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App title with animated ball
                VStack(spacing: 20) {
                    // Animated ping pong ball
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white, .cyan.opacity(0.8)],
                                center: .topLeading,
                                startRadius: 5,
                                endRadius: 40
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: .cyan.opacity(0.6), radius: 20)
                        .offset(x: ballOffset)
                        .animation(reduceMotion ? nil : .easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: ballOffset)
                    
                    // App name
                    Text("PingPong Retro")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .cyan.opacity(0.5), radius: 10)
                    
                    // Loading indicator
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(.white.opacity(0.8))
                                .frame(width: 10, height: 10)
                                .scaleEffect(showContent ? 1 : 0.5)
                                .animation(
                                    reduceMotion ? nil : .easeInOut(duration: 0.6)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.2),
                                    value: showContent
                                )
                        }
                    }
                    .padding(.top, 20)
                }
                
                Spacer()
                Spacer()
                
                // Copyright info
                VStack(spacing: 8) {
                    Text("© 2026 Marcus Deuß")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                    
                    Text("All Rights Reserved")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.bottom, 40)
            }
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) {
                showContent = true
            }
            playRetroArcadeSound()
        }
        .task {
            try? await Task.sleep(for: .seconds(0.3))
            ballOffset = 50
        }
        .task {
            try? await Task.sleep(for: .seconds(3.0))
            withAnimation(.easeOut(duration: 0.5)) {
                onComplete()
            }
        }
    }
    
    // Synthesized retro arcade melody using square waves
    private func playRetroArcadeSound() {
        let engine = AVAudioEngine()
        let playerNode = AVAudioPlayerNode()
        engine.attach(playerNode)
        
        let sampleRate: Double = 44100
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        
        // Classic ascending arcade jingle (coin / level-start style)
        let notes: [(freq: Double, dur: Double)] = [
            (261.63, 0.07),  // C4
            (329.63, 0.07),  // E4
            (392.00, 0.07),  // G4
            (523.25, 0.07),  // C5
            (659.25, 0.07),  // E5
            (783.99, 0.07),  // G5
            (1046.5, 0.18),  // C6 – hold
            (783.99, 0.07),  // G5
            (1046.5, 0.30),  // C6 – long finish
        ]
        
        let totalFrames = AVAudioFrameCount(notes.reduce(0.0) { $0 + $1.dur } * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames) else { return }
        buffer.frameLength = totalFrames
        
        guard let data = buffer.floatChannelData?[0] else { return }
        var frameOffset = 0
        
        for note in notes {
            let count = Int(note.dur * sampleRate)
            let attackLen = max(1, Int(0.005 * sampleRate))
            let releaseStart = max(0, count - Int(0.025 * sampleRate))
            
            for f in 0..<count {
                // Square wave for authentic retro timbre
                let t = Double(f) / sampleRate
                let wave: Float = sin(2.0 * .pi * note.freq * t) >= 0 ? 0.28 : -0.28
                
                // Attack / release envelope
                var env: Float = 1.0
                if f < attackLen {
                    env = Float(f) / Float(attackLen)
                } else if f >= releaseStart {
                    env = Float(count - f) / Float(count - releaseStart)
                }
                data[frameOffset + f] = wave * env
            }
            frameOffset += count
        }
        
        do {
            try engine.start()
            playerNode.play()
            playerNode.scheduleBuffer(buffer, at: nil, completionHandler: nil)
            audioEngine = engine  // retain so it stays alive
        } catch {
            // Sound is non-critical; silently ignore failures
        }
    }
}

#Preview {
    LoadingScreenView {
        print("Loading complete")
    }
}
