import SwiftUI

struct ModeSelectionOverlay: View {
    var gameState: GameState

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
                    Text("Pick a mode and jump in")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.72))
                }

                VStack(spacing: 10) {
                    Label("First to \(gameState.maxScore)", systemImage: "target")
                    Label(gameState.matchDuration.title, systemImage: "timer")
                    Label("AI: \(gameState.aiStyle.title)", systemImage: "brain")
                    Label(gameState.isSpeedBoostEnabled ? "Speed boosts enabled" : "Speed boosts disabled", systemImage: "bolt")
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
