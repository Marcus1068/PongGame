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
                // Loading screen
                LoadingScreenView {
                    showLoadingScreen = false
                }
                .transition(.opacity)
            } else {
                // Pong game
                PongGameView(gameState: gameState)
                    .transition(.opacity)
                
                // Mode-selection popup — shown before each match
                if !gameState.hasStarted {
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
                                    .foregroundStyle(.white.opacity(0.25))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(.ultraThinMaterial.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                            
                            // Pause button
                            Button {
                                gameState.togglePause()
                            } label: {
                                Label(gameState.isPaused ? "Resume" : "Pause", 
                                      systemImage: gameState.isPaused ? "play.fill" : "pause.fill")
                                    .foregroundStyle(.white.opacity(0.25))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(.ultraThinMaterial.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                            
                            // About button
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showAbout = true
                                    gameState.isPaused = true
                                }
                            } label: {
                                Label("About", systemImage: "info.circle")
                                    .foregroundStyle(.white.opacity(0.25))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(.ultraThinMaterial.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                            
                            // Options button
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showOptions = true
                                    gameState.isPaused = true
                                }
                            } label: {
                                Label("Options", systemImage: "gearshape")
                                    .foregroundStyle(.white.opacity(0.25))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(.ultraThinMaterial.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
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
                            gameState.isPaused = false
                        }
                    }
                }
                
                // Options overlay
                if showOptions {
                    OptionsView(gameState: gameState) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showOptions = false
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

// MARK: - Game Mode Card

private struct GameModeCard: View {
    let icon: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let accentColors: [Color]
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: accentColors,
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: accentColors.first?.opacity(0.6) ?? .clear, radius: 10)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(colors: accentColors.map { $0.opacity(0.6) },
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1.5
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(.plain)
        ._onButtonGesture(pressing: { isPressed = $0 }, perform: {})
    }
}

#Preview {
    ContentView()
}

