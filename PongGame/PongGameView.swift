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
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Player score (right)
                        VStack {
                            Text("Player")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                            Text("\(gameState.playerScore)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
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
