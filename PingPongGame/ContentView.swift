import SwiftUI

private enum ActiveSheet: String, Identifiable {
    case about
    case options
    case stats

    var id: String { rawValue }
}

struct ContentView: View {
    @State private var gameState = GameState()
    @State private var activeSheet: ActiveSheet?
    @State private var resumeAfterSheet = false

    var body: some View {
        ZStack {
            if gameState.gamePhase == .loading {
                LoadingScreenView(soundEnabled: gameState.isSoundEnabled, soundVolume: gameState.soundVolume) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        gameState.completeLoading()
                    }
                }
                .transition(.opacity)
            } else {
                PongGameView(
                    gameState: gameState,
                    onShowAbout: { present(sheet: .about) },
                    onShowOptions: { present(sheet: .options) },
                    onShowStats: { present(sheet: .stats) }
                )
                .ignoresSafeArea()
                .transition(.opacity)

                if gameState.gamePhase == .modeSelection {
                    ModeSelectionOverlay(gameState: gameState, onShowOptions: { present(sheet: .options) })
                }
            }
        }
        .sheet(item: $activeSheet, onDismiss: dismissSheet) { sheet in
            switch sheet {
            case .about:
                AboutView(onDismiss: dismissSheet)
            case .options:
                OptionsView(gameState: gameState, onDismiss: dismissSheet)
            case .stats:
                StatsView(gameState: gameState, onDismiss: dismissSheet)
            }
        }
        #if os(macOS)
        .frame(minWidth: 900, minHeight: 640)
        #endif
    }

    private func present(sheet: ActiveSheet) {
        resumeAfterSheet = gameState.gamePhase == .playing
        if resumeAfterSheet {
            gameState.pauseGame()
        }
        activeSheet = sheet
    }

    private func dismissSheet() {
        activeSheet = nil
        if resumeAfterSheet {
            resumeAfterSheet = false
            gameState.resumeGame()
        }
    }
}

#Preview {
    ContentView()
}
