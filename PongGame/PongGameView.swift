//
//  PongGameView.swift
//  PongGame
//
//  Created by Marcus Deuß on 25.02.26.
//

import SwiftUI
import SpriteKit

struct PongGameView: View {
    @Bindable var gameState: GameState
    @State private var scene: PongScene?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // SpriteKit Scene
                SpriteView(scene: createScene(size: geometry.size))
                    .ignoresSafeArea()
                
                // Scoreboard overlay
                VStack {
                    HStack {
                        // Computer score (left)
                        VStack {
                            Text("Computer")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                            Text("\(gameState.computerScore)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(.purple)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Speed control slider (centered)
                        HStack(spacing: 6) {
                            Image(systemName: "tortoise.fill")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.3))
                            
                            Slider(value: $gameState.ballSpeed, in: 0.5...2.0, step: 0.1) {
                                Text("Speed")
                            }
                            .tint(.cyan.opacity(0.6))
                            .frame(width: 120)
                            
                            Image(systemName: "hare.fill")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.3))
                            
                            Text("\(gameState.ballSpeed, specifier: "%.1f")x")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.4))
                                .frame(width: 35)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial.opacity(0.5), in: Capsule())
                        .frame(maxWidth: .infinity)
                        
                        // Player score (right)
                        VStack {
                            Text("Player")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                            Text("\(gameState.playerScore)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(.cyan)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Controls hint
                    VStack(spacing: 8) {
#if os(macOS)
                        Text("Use W/S or Arrow Keys to move")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
#else
                        Text("Touch and drag to move")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
#endif
                    }
                    .padding(.bottom)
                }
                
                // Winner overlay
                if let winner = gameState.winner {
                    ZStack {
                        // Semi-transparent background
                        Color.black.opacity(0.8)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 30) {
                            // Trophy icon
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(
                                    winner == "Player" ? 
                                        LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom) :
                                        LinearGradient(colors: [.purple, .pink], startPoint: .top, endPoint: .bottom)
                                )
                                .shadow(color: winner == "Player" ? .cyan.opacity(0.8) : .purple.opacity(0.8), radius: 20)
                            
                            // Winner text
                            VStack(spacing: 10) {
                                Text("\(winner) Wins!")
                                    .font(.system(size: 60, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: winner == "Player" ? [.cyan, .blue] : [.purple, .pink],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                
                                Text("Final Score: \(gameState.playerScore) - \(gameState.computerScore)")
                                    .font(.title2)
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                            
                            // Play Again button
                            Button {
                                withAnimation {
                                    gameState.reset()
                                }
                            } label: {
                                Text("Play Again")
                                    .font(.title3.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 40)
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
                        .padding()
                    }
                    .transition(.opacity.combined(with: .scale))
                }
                
                // Pause overlay
                if gameState.isPaused && gameState.winner == nil {
                    ZStack {
                        // Semi-transparent background
                        Color.black.opacity(0.6)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 20) {
                            Image(systemName: "pause.circle.fill")
                                .font(.system(size: 100))
                                .foregroundStyle(.white.opacity(0.9))
                                .shadow(color: .white.opacity(0.3), radius: 20)
                            
                            Text("Game Paused")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            
                            Text("Press Resume to continue")
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
    }
    
    private func createScene(size: CGSize) -> PongScene {
        if let existingScene = scene {
            return existingScene
        }
        
        let newScene = PongScene()
        newScene.size = size
        newScene.scaleMode = .aspectFill
        newScene.gameState = gameState
        
        self.scene = newScene
        return newScene
    }
}

#Preview {
    PongGameView(gameState: GameState())
}
