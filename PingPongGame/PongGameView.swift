// PongGameView.swift
//
// This view is the main gameplay screen for PingPong Retro. It owns the
// SpriteKit bridge that displays the live `PongScene`, then layers SwiftUI HUD
// elements and phase-specific overlays on top of it. `GameState` drives the
// visible scores, hints, and modal states shown here.
import SwiftUI
import SpriteKit

/// Hosts the active `PongScene` and all SwiftUI overlays that surround live play.
struct PongGameView: View {
    var gameState: GameState
    let onShowAbout: () -> Void
    let onShowOptions: () -> Void
    let onShowStats: () -> Void

    @State private var scene: PongScene?

    var body: some View {
        ZStack {
            if let scene {
                SpriteView(scene: scene)
                    .ignoresSafeArea()
            }

            VStack(spacing: 12) {
                ScoreHeaderView(gameState: gameState)
                    .padding(.top, headerTopPadding)
                Spacer()
                footerOverlay
                    .inPrimaryArea()
            }
            .padding(.bottom)

            GameHUDView(
                gameState: gameState,
                onReplay: replayLastPoint,
                onShowStats: onShowStats,
                onShowAbout: onShowAbout,
                onShowOptions: onShowOptions
            )

            if case let .winner(winner) = gameState.gamePhase {
                WinnerOverlay(winner: winner, gameState: gameState, onReplay: replayLastPoint, onShowStats: onShowStats)
            }

            if gameState.gamePhase == .paused {
                PauseOverlay(gameState: gameState)
            }
        }
        .onAppear(perform: setupScene)
    }

    /// Shows contextual status text near the bottom, including rally
    /// highlights and platform-specific control hints.
    private var footerOverlay: some View {
        VStack(spacing: 10) {
            if let highlight = gameState.latestHighlightText {
                Text(highlight)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial.opacity(0.75), in: Capsule())
            }

            #if os(macOS)
            Text(gameState.gameMode == .twoPlayers ? String(localized: "Player 1: W/S or ↑↓   •   Player 2: I/K   •   Space pauses") : String(localized: "Use W/S or Arrow Keys to move   •   Space pauses"))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
            #else
            Text(gameState.gameMode == .twoPlayers ? String(localized: "Left side controls Player 2   •   Right side controls Player 1") : String(localized: "Touch and drag to move"))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
            #endif
        }
    }

    /// Offsets the score header far enough from the top edge to clear the HUD
    /// buttons and system safe areas on each platform.
    private var headerTopPadding: CGFloat {
        #if os(macOS)
        92
        #else
        76
        #endif
    }

    /// Lazily creates the SpriteKit scene once so game simulation and replay
    /// state survive ordinary SwiftUI view refreshes.
    private func setupScene() {
        // Reusing the same scene avoids resetting the match whenever SwiftUI
        // recomputes this view hierarchy.
        guard scene == nil else { return }
        let newScene = PongScene(gameState: gameState)
        newScene.scaleMode = .resizeFill
        scene = newScene
    }

    /// Asks the existing SpriteKit scene to replay the saved last point.
    private func replayLastPoint() {
        scene?.startLastPointReplay()
    }
}

#Preview {
    PongGameView(gameState: GameState(), onShowAbout: { }, onShowOptions: { }, onShowStats: { })
}
