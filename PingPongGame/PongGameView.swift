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
    @ScaledMetric private var scoreFontSize: CGFloat = 48
    @Environment(\.horizontalSizeClass) private var sizeClass

    /// Scales the large score digits so they stay prominent on iPad while
    /// still fitting comfortably on smaller layouts.
    private var scoreFont: Font {
        #if os(iOS)
        .system(size: sizeClass == .regular ? scoreFontSize * 1.4 : scoreFontSize, weight: .bold, design: .rounded)
        #else
        .system(size: scoreFontSize, weight: .bold, design: .rounded)
        #endif
    }

    var body: some View {
        ZStack {
            if let scene {
                SpriteView(scene: scene)
                    .ignoresSafeArea()
            }

            VStack(spacing: 12) {
                headerOverlay
                Spacer()
                footerOverlay
            }
            .padding(.horizontal)
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
        .ignoresSafeArea()
        .onAppear(perform: setupScene)
    }

    /// Displays the live score, timer, and any currently active power-up above
    /// the SpriteKit scene.
    private var headerOverlay: some View {
        HStack {
            scoreCard(title: gameState.opponentDisplayName, score: gameState.opponentScore, color: gameState.visualTheme.opponentColor)
            Spacer()
            VStack(spacing: 6) {
                if let timer = gameState.formattedTimer {
                    Label(timer, systemImage: "timer")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.9))
                }
                if let activePowerUp = gameState.activePowerUp {
                    Label(activePowerUp.title, systemImage: activePowerUp.symbolName)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .foregroundStyle(.white)
                }
            }
            Spacer()
            scoreCard(title: gameState.playerDisplayName, score: gameState.playerScore, color: gameState.visualTheme.playerColor)
        }
        .padding(.top, headerTopPadding)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "Score \(gameState.opponentDisplayName) \(gameState.opponentScore), \(gameState.playerDisplayName) \(gameState.playerScore)"))
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

    /// Builds one side of the score header so both players use the same
    /// typography and alignment.
    private func scoreCard(title: String, score: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))
            Text("\(score)")
                .font(scoreFont)
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
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
