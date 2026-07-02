// LoadingScreenView.swift
//
// Launch splash screen for PingPong Retro. It animates a simple arcade-style
// intro, synthesizes a short startup jingle in code, and hands off to the main
// game flow after a brief timed presentation.

import SwiftUI
import AVFoundation

/// Animated startup screen that plays the app's retro audio sting before
/// transitioning into mode selection and gameplay.
struct LoadingScreenView: View {
    @State private var ballOffset: CGFloat = 0
    @State private var showContent = false
    @State private var audioEngine: AVAudioEngine?
    @State private var audioPlayer = AVAudioPlayerNode()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let soundEnabled: Bool
    let soundVolume: Double
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, .purple.opacity(0.3), .cyan.opacity(0.3), .black], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 20) {
                    Circle()
                        .fill(RadialGradient(colors: [.white, .cyan.opacity(0.8)], center: .topLeading, startRadius: 5, endRadius: 40))
                        .frame(width: 60, height: 60)
                        .shadow(color: .cyan.opacity(0.6), radius: 20)
                        .offset(x: ballOffset)
                        .animation(reduceMotion ? nil : .easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: ballOffset)

                    Text("PingPong Retro")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(LinearGradient(colors: [.cyan, .purple], startPoint: .leading, endPoint: .trailing))
                        .shadow(color: .cyan.opacity(0.5), radius: 10)

                    HStack(spacing: 8) {
                        ForEach(0 ..< 3, id: \.self) { index in
                            Circle()
                                .fill(.white.opacity(0.8))
                                .frame(width: 10, height: 10)
                                .scaleEffect(showContent ? 1 : 0.5)
                                .animation(reduceMotion ? nil : .easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(Double(index) * 0.2), value: showContent)
                        }
                    }
                    .padding(.top, 20)
                }

                Spacer()
                Spacer()

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
            withAnimation(.easeIn(duration: 0.45)) {
                showContent = true
            }
            playRetroArcadeSound()
        }
        .onDisappear(perform: stopRetroArcadeSound)
        .task {
            // Delay the bounce slightly so it starts after the initial fade-in,
            // which makes the splash feel staged instead of instantaneous.
            try? await Task.sleep(for: .seconds(0.25))
            if !Task.isCancelled {
                ballOffset = 50
            }
        }
        .task {
            // Keep the splash visible long enough for the jingle and motion to
            // read before handing control to the main app flow.
            try? await Task.sleep(for: .seconds(2.2))
            if !Task.isCancelled {
                onComplete()
            }
        }
    }

    /// Procedurally renders and plays a short monophonic chiptune by writing
    /// square-wave samples into a PCM buffer and feeding it to `AVAudioEngine`.
    private func playRetroArcadeSound() {
        guard soundEnabled else { return }

        let sampleRate: Double = 44_100
        // A hand-authored ascending phrase gives the splash a quick "arcade
        // boot-up" identity without needing bundled audio assets.
        let notes: [(freq: Double, dur: Double)] = [
            (261.63, 0.07),
            (329.63, 0.07),
            (392.0, 0.07),
            (523.25, 0.07),
            (659.25, 0.07),
            (783.99, 0.07),
            (1046.5, 0.18),
            (783.99, 0.07),
            (1046.5, 0.24)
        ]

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        let totalFrames = AVAudioFrameCount(notes.reduce(0.0) { $0 + $1.dur } * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames), let data = buffer.floatChannelData?[0] else { return }
        buffer.frameLength = totalFrames

        var frameOffset = 0
        for note in notes {
            let count = Int(note.dur * sampleRate)
            let attack = max(1, Int(0.005 * sampleRate))
            let release = max(1, Int(0.025 * sampleRate))

            // Render each note as a square wave, then taper its start and end
            // with a tiny linear envelope to avoid audible clicks.
            for frame in 0 ..< count {
                let time = Double(frame) / sampleRate
                let wave: Float = sin(2 * .pi * note.freq * time) >= 0 ? 0.28 : -0.28
                var envelope: Float = 1
                if frame < attack {
                    envelope = Float(frame) / Float(attack)
                } else if frame >= count - release {
                    envelope = Float(count - frame) / Float(release)
                }
                data[frameOffset + frame] = wave * envelope * Float(soundVolume)
            }
            frameOffset += count
        }

        let engine = AVAudioEngine()
        engine.attach(audioPlayer)
        engine.connect(audioPlayer, to: engine.mainMixerNode, format: format)

        do {
            try engine.start()
            audioPlayer.play()
            audioPlayer.scheduleBuffer(buffer, at: nil, completionHandler: nil)
            audioEngine = engine
        } catch {
            stopRetroArcadeSound()
        }
    }

    /// Stops and tears down the one-shot splash audio engine when the screen
    /// disappears or playback setup fails.
    private func stopRetroArcadeSound() {
        audioPlayer.stop()
        audioEngine?.stop()
        audioEngine = nil
    }
}

#Preview {
    LoadingScreenView(soundEnabled: true, soundVolume: 0.8) { }
}
