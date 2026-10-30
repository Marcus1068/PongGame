// ModeSelectionParts.swift
//
// Building blocks of the mode-selection screen. `ModeSelectionOverlay` arranges
// them vertically when there is room, and side by side on short displays such
// as a landscape iPhone or the outer display of a dual-screen iPhone.
import SwiftUI

/// Game title with the tagline and a shortcut to the settings.
struct ModeSelectionHeader: View {
    let onShowOptions: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text("PingPong Retro")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(
                    LinearGradient(colors: [.cyan, .purple], startPoint: .leading, endPoint: .trailing)
                )

            HStack(spacing: 12) {
                Text("Pick a mode and jump in")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.72))

                Button(action: onShowOptions) {
                    Label("Settings", systemImage: "gearshape.fill")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .fixedSize()
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: .capsule)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// A snapshot of the current rules so players can confirm their setup before
/// committing to a new match.
struct MatchRulesSummary: View {
    var gameState: GameState

    var body: some View {
        VStack(spacing: 10) {
            Label(String(localized: "First to \(gameState.maxScore)"), systemImage: "target")
            Label(gameState.matchDuration.title, systemImage: "timer")
            Label(String(localized: "AI: \(gameState.aiStyle.title)"), systemImage: "brain")
            Label(gameState.isSpeedBoostEnabled ? String(localized: "Speed boosts enabled") : String(localized: "Speed boosts disabled"), systemImage: "bolt")
        }
        .font(.subheadline)
        .foregroundStyle(.white.opacity(0.75))
    }
}

/// The one-player and two-player cards, with room for the fold between them.
struct ModeCardRow: View {
    var gameState: GameState

    @Environment(\.screenReservations) private var reservations

    var body: some View {
        HStack(spacing: max(20, reservations.foldWidth)) {
            GameModeCard(
                icon: "person.fill",
                title: "1 Player",
                subtitle: "vs Computer",
                accentColors: [.cyan, .blue]
            ) {
                withAnimation(.easeIn(duration: 0.25)) {
                    gameState.startMatch(mode: .onePlayer)
                }
            }

            GameModeCard(
                icon: "person.2.fill",
                title: "2 Players",
                subtitle: "Local Multiplayer",
                accentColors: [.purple, .pink]
            ) {
                withAnimation(.easeIn(duration: 0.25)) {
                    gameState.startMatch(mode: .twoPlayers)
                }
            }
        }
    }
}

/// Arranges the mode-selection parts either in one column or in two.
struct ModeSelectionContent: View {
    /// How the parts are arranged.
    enum Arrangement {
        /// Everything in one centered column, for tall displays.
        case stacked
        /// Title and rules on the leading side, cards on the trailing side.
        case sideBySide
    }

    var gameState: GameState
    let arrangement: Arrangement
    let onShowOptions: () -> Void

    @Environment(\.screenReservations) private var reservations

    var body: some View {
        switch arrangement {
        case .stacked:
            VStack(spacing: 28) {
                ModeSelectionHeader(onShowOptions: onShowOptions)
                MatchRulesSummary(gameState: gameState)
                ModeCardRow(gameState: gameState)
            }
        case .sideBySide:
            HStack(spacing: max(40, reservations.foldWidth)) {
                VStack(spacing: 24) {
                    ModeSelectionHeader(onShowOptions: onShowOptions)
                    MatchRulesSummary(gameState: gameState)
                }
                .frame(maxWidth: .infinity)

                ModeCardRow(gameState: gameState)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}
