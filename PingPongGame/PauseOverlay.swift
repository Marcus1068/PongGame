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
//  PauseOverlay.swift
//  PongGame
//
//  Created by Marcus Deuß on 25.02.26.
//

import SwiftUI

struct PauseOverlay: View {
    var gameState: GameState

    var body: some View {
        ZStack {
            // Tappable backdrop — tap anywhere to resume
            Button {
                withAnimation(.easeIn(duration: 0.15)) {
                    gameState.isPaused = false
                }
            } label: {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
            }
            .buttonStyle(.plain)

            VStack(spacing: 28) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .white.opacity(0.3), radius: 20)
                    .accessibilityHidden(true)

                Text("Game Paused")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
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
