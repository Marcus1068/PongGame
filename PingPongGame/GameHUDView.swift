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
//  GameHUDView.swift
//  PongGame
//
//  Created by Marcus Deuß on 25.02.26.
//

import SwiftUI

struct GameHUDView: View {
    var gameState: GameState
    let onShowAbout: () -> Void
    let onShowOptions: () -> Void

    var body: some View {
        VStack {
            HStack(spacing: 0) {
                Button("New Game", systemImage: "arrow.counterclockwise") {
                    gameState.reset()
                }
                .labelStyle(.iconOnly)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())

                Button(
                    gameState.isPaused ? "Resume" : "Pause",
                    systemImage: gameState.isPaused ? "play.fill" : "pause.fill"
                ) {
                    gameState.togglePause()
                }
                .labelStyle(.iconOnly)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())

                Button("About", systemImage: "info.circle", action: onShowAbout)
                    .labelStyle(.iconOnly)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())

                Button("Settings", systemImage: "gearshape", action: onShowOptions)
                    .labelStyle(.iconOnly)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .font(.body)
            .foregroundStyle(.white.opacity(0.3))
            .padding(.horizontal, 8)
            .background(.ultraThinMaterial.opacity(0.35), in: Capsule())
            .padding(.top, 8)
            .buttonStyle(.plain)

            Spacer()
        }
    }
}
