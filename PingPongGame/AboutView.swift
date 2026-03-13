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
//  AboutView.swift
//  PongGame
//
//  Created by Marcus Deuß on 25.02.26.
//

import SwiftUI

struct AboutView: View {
    let maxScore: Int
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Dimmed backdrop
            Button(action: onDismiss) {
                Color.black.opacity(0.75)
                    .ignoresSafeArea()
            }
            .buttonStyle(.plain)

            ScrollView {
                VStack(spacing: 20) {

                    // MARK: Icon / title
                    VStack(spacing: 10) {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.white, .cyan.opacity(0.8)],
                                    center: .topLeading,
                                    startRadius: 5,
                                    endRadius: 40
                                )
                            )
                            .frame(width: 56, height: 56)
                            .shadow(color: .cyan.opacity(0.6), radius: 20)

                        Text("PingPong Retro")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.cyan, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .cyan.opacity(0.4), radius: 8)

                        Text("Version 1.0")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    Divider()
                        .background(.white.opacity(0.2))

                    // MARK: About text
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Classic Pong reimagined with a retro-neon look, synthesised arcade sounds, and a speed-boost rally system.", systemImage: "gamecontroller.fill")
                            .font(.callout)
                            .foregroundStyle(.white.opacity(0.85))

                        Label("Use W / S or the Arrow Keys to move your paddle on macOS. Drag on screen to play on iOS.", systemImage: "keyboard.fill")
                            .font(.callout)
                            .foregroundStyle(.white.opacity(0.85))

                        Label("First player to reach \(maxScore) points wins. Every 3 alternating rally hits triggers a speed boost!", systemImage: "bolt.fill")
                            .font(.callout)
                            .foregroundStyle(.cyan.opacity(0.9))
                    }
                    .padding(.horizontal, 8)

                    Divider()
                        .background(.white.opacity(0.2))

                    // MARK: Credits
                    VStack(spacing: 6) {
                        Text("© 2026 Marcus Deuß")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))

                        Text("All Rights Reserved")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.45))

                        Text("Built with SwiftUI · SpriteKit · AVFoundation")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.3))
                            .padding(.top, 2)
                    }

                    // MARK: Dismiss button
                    Button(action: onDismiss) {
                        Text("Close")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [.cyan, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: Capsule()
                            )
                            .shadow(color: .cyan.opacity(0.5), radius: 8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(24)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                    )
            )
            .padding(20)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}

#Preview {
    AboutView(maxScore: 5) { }
        .preferredColorScheme(.dark)
}
