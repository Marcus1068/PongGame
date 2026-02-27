//
//  GameState.swift
//  PongGame
//
//  Created by Marcus Deuß on 25.02.26.
//

import Foundation
import Observation

@MainActor
@Observable
class GameState {
    var playerScore: Int = 0
    var computerScore: Int = 0
    var isGameActive: Bool = true
    var isPaused: Bool = false
    var ballSpeed: Double = 1.0 // Speed multiplier (0.5 to 2.0)
    var winner: String? = nil
    let maxScore = 10
    
    func reset() {
        playerScore = 0
        computerScore = 0
        isGameActive = true
        isPaused = false
        winner = nil
    }
    
    func togglePause() {
        isPaused.toggle()
    }
    
    func playerScored() {
        playerScore += 1
        checkForWinner()
    }
    
    func computerScored() {
        computerScore += 1
        checkForWinner()
    }
    
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
