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
    @State private var showAbout = false
    
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
                
                // Start overlay — shown before the first serve
                if !gameState.hasStarted {
                    ZStack {
                        Color.black.opacity(0.55)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 32) {
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
                            
                            Button {
                                withAnimation(.easeIn(duration: 0.25)) {
                                    gameState.hasStarted = true
                                }
                            } label: {
                                Text("Start Game")
                                    .font(.title2.bold())
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 48)
                                    .padding(.vertical, 18)
                                    .background(
                                        LinearGradient(
                                            colors: [.cyan, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        in: Capsule()
                                    )
                                    .shadow(color: .cyan.opacity(0.6), radius: 12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .transition(.opacity)
                }
                
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
                            
                            // About button
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showAbout = true
                                }
                            } label: {
                                Label("About", systemImage: "info.circle")
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
                
                // About overlay
                if showAbout {
                    AboutView {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showAbout = false
                        }
                    }
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
