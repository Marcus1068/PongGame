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

    @Environment(\.screenReservations) private var reservations

    var body: some View {
        ZStack {
            Color.black.opacity(0.82)
                .ignoresSafeArea()

            Group {
                if reservations.fold != nil {
                    // The fold would cut a centered stack in two, so put the
                    // title and rules on one half and the cards on the other.
                    content(.sideBySide)
                } else {
                    // Prefer the roomy layout, falling back to two columns and
                    // finally scrolling on short displays.
                    ViewThatFits(in: .vertical) {
                        content(.stacked)
                        content(.sideBySide)
                        ScrollView { content(.sideBySide) }
                    }
                }
            }
            .centeredOnDisplay(minimumMargin: reservations.fold == nil ? 24 : 40)
            .padding(.vertical, 24)
        }
        .transition(.opacity)
    }

    private func content(_ arrangement: ModeSelectionContent.Arrangement) -> ModeSelectionContent {
        ModeSelectionContent(gameState: gameState, arrangement: arrangement, onShowOptions: onShowOptions)
    }
}

#Preview("Landscape", traits: .landscapeLeft) {
    ModeSelectionOverlay(gameState: GameState(), onShowOptions: { })
}
