//
//  GameState.swift
//  PongGame
//
//  Created by Marcus Deuß on 25.02.26.
//

import Foundation
import Observation

enum Difficulty: String, CaseIterable {
    case easy   = "Easy"
    case medium = "Medium"
    case hard   = "Hard"
}

enum GameMode {
    case onePlayer
    case twoPlayers
}

/// Shared observable game state passed between the SwiftUI layer and the SpriteKit scene.
/// Marked `@MainActor` so all mutations happen on the main thread, keeping SwiftUI bindings safe.
@MainActor
@Observable
class GameState {
    // MARK: - Scores

    var playerScore: Int = 0
    var computerScore: Int = 0

    // MARK: - Match Status

    /// Whether the match is currently in progress (false once a winner is set).
    var isGameActive: Bool = true

    /// Pauses/resumes the SpriteKit scene update loop without ending the match.
    var isPaused: Bool = false

    /// False until the player presses Start; keeps the ball frozen on the title screen.
    var hasStarted: Bool = false

    /// When true the scene renders in retro black-and-white style.
    var isBlackAndWhite: Bool = false

    /// Current ball-speed multiplier; increases as rallies build up (0.5 – 2.0).
    var ballSpeed: Double = 1.0

    var difficulty: Difficulty = .medium
    var gameMode: GameMode = .onePlayer

    /// Set to "Player" or "Computer" when someone reaches `maxScore`; nil during play.
    var winner: String? = nil

    /// First player to reach this score wins the match. Persisted across launches.
    var maxScore: Int = UserDefaults.standard.object(forKey: "endScore") as? Int ?? 5 {
        didSet { UserDefaults.standard.set(maxScore, forKey: "endScore") }
    }

    // MARK: - Actions

    /// Resets all state back to the start of a new match.
    func reset() {
        playerScore = 0
        computerScore = 0
        isGameActive = true
        isPaused = false
        hasStarted = false
        winner = nil
    }

    /// Toggles between paused and running.
    func togglePause() {
        isPaused.toggle()
    }

    /// Call when the human player's ball passes the computer's edge.
    func playerScored() {
        playerScore += 1
        checkForWinner()
    }

    /// Call when the computer's ball passes the player's edge.
    func computerScored() {
        computerScore += 1
        checkForWinner()
    }

    // MARK: - Private Helpers

    /// Ends the game if either side has reached `maxScore`.
    private func checkForWinner() {
        if playerScore >= maxScore {
            winner = "Player"
            isGameActive = false
        } else if computerScore >= maxScore {
            winner = "Computer"
            isGameActive = false
        }
    }
}
