import SpriteKit
#if os(iOS)
import UIKit
#endif

extension PongScene {
    #if os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameState?.gamePhase == .playing || gameState?.gamePhase == .paused else { return }
        for touch in touches {
            let location = touch.location(in: self)
            if gameState?.gameMode == .twoPlayers {
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

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if touch === playerTouch { playerTouch = nil }
            if touch === opponentTouch { opponentTouch = nil }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    func movePaddle(_ y: inout CGFloat, to targetY: CGFloat, paddleHeight: CGFloat) {
        y = clamp(targetY, min: frame.minY + paddleHeight / 2, max: frame.maxY - paddleHeight / 2)
    }
    #endif

    #if os(macOS)
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 49 {
            gameState?.togglePause()
            return
        }
        if let characters = event.charactersIgnoringModifiers {
            keysPressed.insert(characters)
        }
    }

    override func keyUp(with event: NSEvent) {
        if let characters = event.charactersIgnoringModifiers {
            keysPressed.remove(characters)
        }
    }

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
