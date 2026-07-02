// GameHUDView.swift
//
// This file defines the compact floating toolbar that sits above the gameplay
// screen. It exposes match-level actions such as pausing, starting over,
// replaying the last point, and opening secondary sheets without owning any
// game logic itself.
import SwiftUI

/// Renders the row of high-level gameplay controls shown on top of `PongGameView`.
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

                    // Only live gameplay can be paused or resumed; other phases
                    // already own their own overlays and transitions.
                    hudButton(title: gameState.isPaused ? String(localized: "Resume") : String(localized: "Pause"), systemImage: gameState.isPaused ? "play.fill" : "pause.fill") {
                        gameState.togglePause()
                    }
                    .disabled(!(gameState.gamePhase == .playing || gameState.gamePhase == .paused))

                    // Replay becomes available only after the scene records the
                    // last scored point for playback.
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

    /// Lays the toolbar low enough to avoid colliding with macOS window chrome
    /// while keeping it tucked near the top on iPhone and iPad.
    private var topPadding: CGFloat {
        #if os(macOS)
        30
        #else
        8
        #endif
    }

    /// Creates a consistently styled icon button for the HUD, while leaving
    /// the action behavior to the caller.
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
