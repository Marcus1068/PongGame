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
//  ModeSelectionOverlay.swift
//  PongGame
//
//  Created by Marcus Deuß on 25.02.26.
//

import SwiftUI

struct ModeSelectionOverlay: View {
    var gameState: GameState

    var body: some View {
        ZStack {
            Color.black.opacity(0.82)
                .ignoresSafeArea()

            VStack(spacing: 44) {
                // Title
                VStack(spacing: 6) {
                    Text("PingPong Retro")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .cyan.opacity(0.5), radius: 10)

                    Text("Select Game Mode")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.65))
                }

                // Mode buttons
                HStack(spacing: 20) {
                    GameModeCard(
                        icon: "person.fill",
                        title: "1 Player",
                        subtitle: "vs Computer",
                        accentColors: [.cyan, .blue]
                    ) {
                        withAnimation(.easeIn(duration: 0.25)) {
                            gameState.gameMode = .onePlayer
                            gameState.hasStarted = true
                        }
                    }

                    GameModeCard(
                        icon: "person.2.fill",
                        title: "2 Players",
                        subtitle: "Local Multiplayer",
                        accentColors: [.purple, .pink]
                    ) {
                        withAnimation(.easeIn(duration: 0.25)) {
                            gameState.gameMode = .twoPlayers
                            gameState.hasStarted = true
                        }
                    }
                }
            }
            .padding(40)
        }
        .transition(.opacity)
    }
}
