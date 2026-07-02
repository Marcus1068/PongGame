// ModeSelectionOverlay.swift
//
// This overlay is the game's start screen that appears before a match begins.
// It summarizes the currently selected rules and preferences, then lets the
// player choose between solo and local multiplayer by calling
// `gameState.startMatch(mode:)`.
import SwiftUI

/// Presents the pre-game mode picker and a quick summary of the current match settings.
struct ModeSelectionOverlay: View {
    var gameState: GameState
    let onShowOptions: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.82)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Text("PingPong Retro")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
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
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(spacing: 10) {
                    // This snapshot reflects the current rules so players can
                    // confirm their setup before committing to a new match.
                    Label(String(localized: "First to \(gameState.maxScore)"), systemImage: "target")
                    Label(gameState.matchDuration.title, systemImage: "timer")
                    Label(String(localized: "AI: \(gameState.aiStyle.title)"), systemImage: "brain")
                    Label(gameState.isSpeedBoostEnabled ? String(localized: "Speed boosts enabled") : String(localized: "Speed boosts disabled"), systemImage: "bolt")
                }
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))

                HStack(spacing: 20) {
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
            .padding(40)
        }
        .transition(.opacity)
    }
}

#Preview {
    ModeSelectionOverlay(gameState: GameState(), onShowOptions: { })
}
