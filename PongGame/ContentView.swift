//
//  ContentView.swift
//  PongGame
//
//  Created by Marcus Deuß on 25.02.26.
//

import SwiftUI
import SwiftData


struct ContentView: View {
    @State private var gameState = GameState()
    @State private var showLoadingScreen = true
    
    var body: some View {
        ZStack {
            if showLoadingScreen {
                // Loading screen
                LoadingScreenView {
                    showLoadingScreen = false
                }
                .transition(.opacity)
            } else {
                // Pong game
                PongGameView(gameState: gameState)
                    .transition(.opacity)
                
                // Restart and Pause button overlay
                VStack {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            // Restart button
                            Button {
                                gameState.reset()
                            } label: {
                                Label("Restart", systemImage: "arrow.counterclockwise")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                            
                            // Pause button
                            Button {
                                gameState.togglePause()
                            } label: {
                                Label(gameState.isPaused ? "Resume" : "Pause", 
                                      systemImage: gameState.isPaused ? "play.fill" : "pause.fill")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding()
                    }
                    Spacer()
                }
            }
        }
#if os(macOS)
        .frame(minWidth: 800, minHeight: 600)
#endif
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
