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
//  PongGameView.swift
//  PongGame
//
//  Created by Marcus Deuß on 25.02.26.
//

import SwiftUI
import SpriteKit

struct PongGameView: View {
    var gameState: GameState
    @State private var scene: PongScene?

    private var scoreFont: Font {
#if os(iOS)
        .system(size: UIDevice.current.userInterfaceIdiom == .pad ? 72 : 48, weight: .bold, design: .rounded)
#else
        .system(size: 48, weight: .bold, design: .rounded)
#endif
    }

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
                                .font(scoreFont)
                                .foregroundStyle(gameState.isBlackAndWhite ? .white : .purple)
                        }
                        .frame(maxWidth: .infinity)

                        // Right paddle score
                        VStack {
                            Text(gameState.gameMode == .twoPlayers ? "Player 1" : "Player")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                            Text("\(gameState.playerScore)")
                                .font(scoreFont)
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
                    WinnerOverlay(winner: winner, gameState: gameState)
                }

                // Pause overlay
                if gameState.isPaused && gameState.winner == nil {
                    PauseOverlay(gameState: gameState)
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
}

#Preview {
    PongGameView(gameState: GameState())
}
