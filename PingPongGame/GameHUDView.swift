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
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(.white.opacity(0.3))
            .padding(.horizontal, 8)
            .background(.ultraThinMaterial.opacity(0.35), in: Capsule())
            .padding(.top, 8)
            .buttonStyle(.plain)

            Spacer()
        }
    }
}
