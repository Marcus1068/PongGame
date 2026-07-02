// ContentView.swift
//
// Root SwiftUI container for PingPong Retro.
// It owns the single shared `GameState`, swaps between the loading screen and
// live game, and coordinates overlays plus modal sheets for secondary screens.

import SwiftUI

/// Identifies which secondary screen is currently being presented as a sheet.
private enum ActiveSheet: String, Identifiable {
    case about
    case options
    case stats

    var id: String { rawValue }
}

/// Root view that wires the shared game state into the main game scene and supporting UI.
struct ContentView: View {
    @State private var gameState = GameState()
    @State private var activeSheet: ActiveSheet?
    @State private var resumeAfterSheet = false

    /// Builds the top-level loading flow, game scene, overlays, and modal sheets.
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
                    // Keep the mode picker above the initialized game scene so the
                    // background visuals are already visible while choosing a match.
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

    /// Presents a sheet and pauses live gameplay so background simulation does not continue off-screen.
    private func present(sheet: ActiveSheet) {
        // Remember whether the sheet interrupted active play so dismissal only
        // resumes matches that were actually running before presentation.
        resumeAfterSheet = gameState.gamePhase == .playing
        if resumeAfterSheet {
            gameState.pauseGame()
        }
        activeSheet = sheet
    }

    /// Dismisses the active sheet and resumes the match if it was paused for presentation.
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
