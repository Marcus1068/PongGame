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
