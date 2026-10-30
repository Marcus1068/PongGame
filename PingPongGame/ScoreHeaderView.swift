// ScoreHeaderView.swift
//
// The live score, timer, and active power-up shown above the SpriteKit court.
// On a flat display the timer and power-up chip sit between the two scores.
// When a dual-screen iPhone is partially open, the fold acts as the net: each
// score is centered in its own half and the center stays clear.
import SwiftUI

/// Displays both scores plus the match timer and active power-up.
struct ScoreHeaderView: View {
    var gameState: GameState

    @Environment(\.screenReservations) private var reservations
    @Environment(\.horizontalSizeClass) private var sizeClass
    @ScaledMetric private var scoreFontSize: CGFloat = 48

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
        Group {
            if let leadingWidth = reservations.leadingHalfWidth,
               let trailingWidth = reservations.trailingHalfWidth {
                foldedLayout(leadingWidth: leadingWidth, trailingWidth: trailingWidth)
            } else {
                flatLayout
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "Score \(gameState.opponentDisplayName) \(gameState.opponentScore), \(gameState.playerDisplayName) \(gameState.playerScore)"))
    }

    /// Scores at the edges with the timer and power-up chip in the middle.
    private var flatLayout: some View {
        HStack {
            ScoreCardView(title: gameState.opponentDisplayName, score: gameState.opponentScore, color: gameState.visualTheme.opponentColor, font: scoreFont)
            Spacer()
            VStack(spacing: 6) {
                TimerLabel(text: gameState.formattedTimer)
                PowerUpChip(powerUp: gameState.activePowerUp)
            }
            Spacer()
            ScoreCardView(title: gameState.playerDisplayName, score: gameState.playerScore, color: gameState.visualTheme.playerColor, font: scoreFont)
        }
        .centeredOnDisplay()
    }

    /// One score per half, with the center left to the fold.
    private func foldedLayout(leadingWidth: CGFloat, trailingWidth: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(spacing: 6) {
                ScoreCardView(title: gameState.opponentDisplayName, score: gameState.opponentScore, color: gameState.visualTheme.opponentColor, font: scoreFont)
                TimerLabel(text: gameState.formattedTimer)
            }
            .frame(width: leadingWidth)

            Spacer(minLength: 0)

            VStack(spacing: 6) {
                ScoreCardView(title: gameState.playerDisplayName, score: gameState.playerScore, color: gameState.visualTheme.playerColor, font: scoreFont)
                PowerUpChip(powerUp: gameState.activePowerUp)
            }
            .frame(width: trailingWidth)
        }
        .padding(.leading, reservations.leadingMargin)
        .padding(.trailing, reservations.trailingMargin)
    }
}

/// One player's name and score.
private struct ScoreCardView: View {
    let title: String
    let score: Int
    let color: Color
    let font: Font

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))
            Text("\(score)")
                .font(font)
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }
}

/// The remaining match time, shown only for timed matches.
private struct TimerLabel: View {
    let text: String?

    var body: some View {
        if let text {
            Label(text, systemImage: "timer")
                .font(.headline.monospacedDigit())
                .foregroundStyle(.white.opacity(0.9))
        }
    }
}

/// A capsule naming the power-up that is currently active.
private struct PowerUpChip: View {
    let powerUp: PowerUpType?

    var body: some View {
        if let powerUp {
            Label(powerUp.title, systemImage: powerUp.symbolName)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: .capsule)
                .foregroundStyle(.white)
        }
    }
}
