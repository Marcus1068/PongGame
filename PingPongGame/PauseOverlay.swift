import SwiftUI

struct PauseOverlay: View {
    var gameState: GameState

    var body: some View {
        ZStack {
            Button {
                withAnimation(.easeIn(duration: 0.15)) {
                    gameState.resumeGame()
                }
            } label: {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
            }
            .buttonStyle(.plain)

            VStack(spacing: 24) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 96))
                    .foregroundStyle(.white.opacity(0.9))
                    .accessibilityHidden(true)

                Text("Game Paused")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                if let timer = gameState.formattedTimer {
                    Text(String(localized: "Clock: \(timer)"))
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.75))
                }

                Button {
                    withAnimation(.easeIn(duration: 0.15)) {
                        gameState.resumeGame()
                    }
                } label: {
                    Text("Resume")
                        .font(.title3.bold())
                        .foregroundStyle(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(LinearGradient(colors: [.cyan, .purple], startPoint: .leading, endPoint: .trailing), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .transition(.opacity)
    }
}
