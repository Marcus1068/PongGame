//
//  GameState.swift
//  PongGame
//
//  Created by Marcus Deuß on 25.02.26.
//

import Foundation
import Observation

@Observable
class GameState {
    var playerScore: Int = 0
    var computerScore: Int = 0
    var isGameActive: Bool = true
    
    func reset() {
        playerScore = 0
        computerScore = 0
        isGameActive = true
    }
    
    func playerScored() {
        playerScore += 1
    }
    
    func computerScored() {
        computerScore += 1
    }
}
