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
