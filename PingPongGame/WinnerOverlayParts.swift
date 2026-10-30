// WinnerOverlayParts.swift
//
// Building blocks of the end-of-match screen. `WinnerOverlay` stacks them in
// one column when there is room, and places them side by side on short
// displays or when a dual-screen iPhone is folded.
import SwiftUI

/// Trophy and "<name> Wins!" headline.
struct WinnerHeadline: View {
    let winner: WinnerSide
    var gameState: GameState

    @ScaledMetric private var winnerFontSize: CGFloat = 56

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 74))
                .foregroundStyle(LinearGradient(colors: winner == .playerOne ? [.cyan, .blue] : [.purple, .pink], startPoint: .top, endPoint: .bottom))
                .accessibilityHidden(true)

            Text(String(localized: "\(gameState.gameMode.displayName(for: winner)) Wins!"))
                .font(.system(size: winnerFontSize, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(LinearGradient(colors: winner == .playerOne ? [.cyan, .blue] : [.purple, .pink], startPoint: .leading, endPoint: .trailing))
        }
    }
}

/// Final score, match highlights, and the next-step buttons.
struct WinnerActions: View {
    var gameState: GameState
    let onReplay: () -> Void
    let onShowStats: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text(String(localized: "Final Score: \(gameState.playerScore) - \(gameState.opponentScore)"))
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.95))
                Text(String(localized: "Longest Rally: \(gameState.currentMatchStats.longestRally)   •   Boosts: \(gameState.currentMatchStats.speedBoostsTriggered)"))
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.72))
            }

            HStack(spacing: 12) {
                Button("Play Again") {
                    withAnimation {
                        gameState.resetToMenu()
                    }
                }
                .buttonStyle(WinnerCapsuleButtonStyle(colors: [.cyan, .purple], foreground: .white))

                Button("Stats", action: onShowStats)
                    .buttonStyle(WinnerCapsuleButtonStyle(colors: [.white.opacity(0.16), .white.opacity(0.08)], foreground: .white))
            }

            if gameState.canReplayLastPoint {
                Button("Replay Last Point", action: onReplay)
                    .buttonStyle(WinnerCapsuleButtonStyle(colors: [.orange, .pink], foreground: .white))
            }
        }
    }
}

/// Arranges the winner parts either in one column or in two.
struct WinnerContent: View {
    /// How the parts are arranged.
    enum Arrangement {
        /// Headline above the actions, for tall displays.
        case stacked
        /// Headline on the leading side, actions on the trailing side.
        case sideBySide
    }

    let winner: WinnerSide
    var gameState: GameState
    let arrangement: Arrangement
    let onReplay: () -> Void
    let onShowStats: () -> Void

    @Environment(\.screenReservations) private var reservations

    var body: some View {
        switch arrangement {
        case .stacked:
            VStack(spacing: 24) {
                WinnerHeadline(winner: winner, gameState: gameState)
                WinnerActions(gameState: gameState, onReplay: onReplay, onShowStats: onShowStats)
            }
        case .sideBySide:
            HStack(spacing: max(32, reservations.foldWidth)) {
                WinnerHeadline(winner: winner, gameState: gameState)
                    .frame(maxWidth: .infinity)
                WinnerActions(gameState: gameState, onReplay: onReplay, onShowStats: onShowStats)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}
