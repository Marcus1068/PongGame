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
//  ContentView.swift
//  PongGame
//
//  Created by Marcus Deuß on 25.02.26.
//

import SwiftUI

struct ContentView: View {
    @State private var gameState = GameState()
    @State private var showLoadingScreen = true
    @State private var showAbout = false
    @State private var showOptions = false

    var body: some View {
        ZStack {
            if showLoadingScreen {
                LoadingScreenView {
                    showLoadingScreen = false
                }
                .transition(.opacity)
            } else {
                PongGameView(gameState: gameState)
                    .transition(.opacity)

                if !gameState.hasStarted {
                    ModeSelectionOverlay(gameState: gameState)
                }

                GameHUDView(
                    gameState: gameState,
                    onShowAbout: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showAbout = true
                            gameState.isPaused = true
                        }
                    },
                    onShowOptions: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showOptions = true
                            gameState.isPaused = true
                        }
                    }
                )

                if showAbout {
                    AboutView(maxScore: gameState.maxScore) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showAbout = false
                        }
                    }
                }

                if showOptions {
                    OptionsView(gameState: gameState) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showOptions = false
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
#if os(macOS)
        .frame(minWidth: 800, minHeight: 600)
#endif
    }
}

#Preview {
    ContentView()
}
