// PongScene+Input.swift
//
// Handles platform-specific player input for PongScene.
// iOS uses direct touch tracking, including separate touches for each paddle in
// two-player mode, while macOS maps keyboard keys to paddle movement and pause.

import SpriteKit
#if os(iOS)
import UIKit
#endif

extension PongScene {
    #if os(iOS)
    /// Claims new touches for the appropriate paddle and immediately moves that
    /// paddle to the touch location.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameState?.gamePhase == .playing || gameState?.gamePhase == .paused else { return }
        for touch in touches {
            let location = touch.location(in: self)
            if gameState?.gameMode == .twoPlayers {
                // Each side keeps its own touch identity so two players can drag
                // both paddles at the same time without stealing control.
                if location.x >= frame.midX, playerTouch == nil {
                    playerTouch = touch
                    movePaddle(&playerPaddle.position.y, to: location.y, paddleHeight: playerPaddleHeight)
                } else if location.x < frame.midX, opponentTouch == nil {
                    opponentTouch = touch
                    movePaddle(&opponentPaddle.position.y, to: location.y, paddleHeight: opponentPaddleHeight)
                }
            } else if playerTouch == nil {
                playerTouch = touch
                movePaddle(&playerPaddle.position.y, to: location.y, paddleHeight: playerPaddleHeight)
            }
        }
    }

    /// Continues dragging whichever paddle previously claimed each touch.
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameState?.gamePhase == .playing else { return }
        for touch in touches {
            let location = touch.location(in: self)
            if touch === playerTouch {
                movePaddle(&playerPaddle.position.y, to: location.y, paddleHeight: playerPaddleHeight)
            } else if touch === opponentTouch {
                movePaddle(&opponentPaddle.position.y, to: location.y, paddleHeight: opponentPaddleHeight)
            }
        }
    }

    /// Releases any paddle assignment for touches that ended.
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if touch === playerTouch { playerTouch = nil }
            if touch === opponentTouch { opponentTouch = nil }
        }
    }

    /// Treats cancelled touches the same as ended touches to avoid leaving a
    /// paddle permanently bound to a stale touch reference.
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    /// Moves a paddle directly to a target y-position while keeping it on-screen.
    func movePaddle(_ y: inout CGFloat, to targetY: CGFloat, paddleHeight: CGFloat) {
        y = clamp(targetY, min: frame.minY + paddleHeight / 2, max: frame.maxY - paddleHeight / 2)
    }
    #endif

    #if os(macOS)
    /// Records pressed keys for continuous movement and lets Space/Escape toggle pause.
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 49 || event.keyCode == 53 {
            gameState?.togglePause()
            return
        }
        if let characters = event.charactersIgnoringModifiers {
            keysPressed.insert(characters)
        }
    }

    /// Removes released keys from the active key set.
    override func keyUp(with event: NSEvent) {
        if let characters = event.charactersIgnoringModifiers {
            keysPressed.remove(characters)
        }
    }

    /// Applies continuous keyboard movement for player one on macOS.
    func updatePlayerPaddleForKeyboard(deltaTime: CGFloat) {
        guard gameState?.gamePhase == .playing else { return }
        let speed = 520 * deltaTime
        if keysPressed.contains("w") || keysPressed.contains("W") {
            playerPaddle.position.y += speed
        }
        if keysPressed.contains("s") || keysPressed.contains("S") {
            playerPaddle.position.y -= speed
        }
        if keysPressed.contains(String(UnicodeScalar(NSUpArrowFunctionKey)!)) {
            playerPaddle.position.y += speed
        }
        if keysPressed.contains(String(UnicodeScalar(NSDownArrowFunctionKey)!)) {
            playerPaddle.position.y -= speed
        }
        clampPaddlesToBounds()
    }

    /// Applies continuous keyboard movement for player two in macOS two-player mode.
    func updateOpponentPaddleForKeyboard(deltaTime: CGFloat) {
        guard gameState?.gameMode == .twoPlayers, gameState?.gamePhase == .playing else { return }
        let speed = 520 * deltaTime
        if keysPressed.contains("i") || keysPressed.contains("I") {
            opponentPaddle.position.y += speed
        }
        if keysPressed.contains("k") || keysPressed.contains("K") {
            opponentPaddle.position.y -= speed
        }
        clampPaddlesToBounds()
    }
    #endif
}
