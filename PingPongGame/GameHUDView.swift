import SwiftUI

struct GameHUDView: View {
    var gameState: GameState
    let onReplay: () -> Void
    let onShowStats: () -> Void
    let onShowAbout: () -> Void
    let onShowOptions: () -> Void

    var body: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    hudButton(title: String(localized: "New Match"), systemImage: "arrow.counterclockwise") {
                        gameState.resetToMenu()
                    }

                    hudButton(title: gameState.isPaused ? String(localized: "Resume") : String(localized: "Pause"), systemImage: gameState.isPaused ? "play.fill" : "pause.fill") {
                        gameState.togglePause()
                    }
                    .disabled(!(gameState.gamePhase == .playing || gameState.gamePhase == .paused))

                    hudButton(title: String(localized: "Replay"), systemImage: "gobackward") {
                        onReplay()
                    }
                    .disabled(!gameState.canReplayLastPoint)

                    hudButton(title: String(localized: "Stats"), systemImage: "chart.bar.fill", action: onShowStats)
                    hudButton(title: String(localized: "About"), systemImage: "info.circle", action: onShowAbout)
                    hudButton(title: String(localized: "Settings"), systemImage: "gearshape", action: onShowOptions)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .background(.ultraThinMaterial.opacity(0.45), in: Capsule())
            .padding(.top, topPadding)

            Spacer()
        }
        .padding(.horizontal, 16)
    }

    private var topPadding: CGFloat {
        #if os(macOS)
        30
        #else
        8
        #endif
    }

    private func hudButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .labelStyle(.iconOnly)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.75))
        .accessibilityLabel(title)
    }
}
