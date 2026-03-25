import SwiftUI
import SpriteKit

struct PongGameView: View {
    var gameState: GameState
    let onShowAbout: () -> Void
    let onShowOptions: () -> Void
    let onShowStats: () -> Void

    @State private var scene: PongScene?
    @ScaledMetric private var scoreFontSize: CGFloat = 48
    @Environment(\.horizontalSizeClass) private var sizeClass

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

    private var headerOverlay: some View {
        HStack {
            scoreCard(title: gameState.opponentDisplayName, score: gameState.opponentScore, color: gameState.isBlackAndWhite ? .white : .purple)
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
            scoreCard(title: gameState.playerDisplayName, score: gameState.playerScore, color: gameState.isBlackAndWhite ? .white : .cyan)
        }
        .padding(.top, headerTopPadding)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "Score \(gameState.opponentDisplayName) \(gameState.opponentScore), \(gameState.playerDisplayName) \(gameState.playerScore)"))
    }

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

    private var headerTopPadding: CGFloat {
        #if os(macOS)
        92
        #else
        56
        #endif
    }

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

    private func setupScene() {
        guard scene == nil else { return }
        let newScene = PongScene(gameState: gameState)
        newScene.scaleMode = .resizeFill
        scene = newScene
    }

    private func replayLastPoint() {
        scene?.startLastPointReplay()
    }
}

#Preview {
    PongGameView(gameState: GameState(), onShowAbout: { }, onShowOptions: { }, onShowStats: { })
}
