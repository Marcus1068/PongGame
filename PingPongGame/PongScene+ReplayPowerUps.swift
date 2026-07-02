// PongScene+ReplayPowerUps.swift
//
// Contains the replay system and the neutral power-up lifecycle for PongScene.
// It records a rolling buffer of recent frames, replays the last scored point,
// spawns collectible power-ups, and applies their temporary gameplay effects.

import SpriteKit

extension PongScene {
    /// Plays back one recorded replay frame instead of advancing live gameplay.
    func updateReplayFrame() {
        guard replayIndex < lastPointReplay.count else {
            finishReplay()
            return
        }

        // Reuse the stored frame positions directly so the replay is a faithful
        // copy of what the player just saw during the live point.
        let frame = lastPointReplay[replayIndex]
        ball.position = frame.ballPosition
        playerPaddle.position.y = frame.playerPaddleY
        opponentPaddle.position.y = frame.opponentPaddleY
        replayIndex += 1
    }

    /// Ends replay mode, restores the saved live positions, and resumes the phase
    /// the match was in before the replay started.
    func finishReplay() {
        isReplayingLastPoint = false
        if let liveFrameBeforeReplay {
            ball.position = liveFrameBeforeReplay.ballPosition
            playerPaddle.position.y = liveFrameBeforeReplay.playerPaddleY
            opponentPaddle.position.y = liveFrameBeforeReplay.opponentPaddleY
        }
        gameState?.gamePhase = replayReturnPhase
        gameState?.latestHighlightText = nil
        captureReplayFrame()
    }

    /// Spawns one randomly chosen enabled power-up at mid-court and a random
    /// vertical position within the safe playable area.
    func spawnPowerUp() {
        guard let gameState else { return }
        let available = Array(gameState.enabledPowerUps)
        guard let type = available.randomElement() else { return }
        spawnedPowerUp = type

        let node = SKShapeNode(circleOfRadius: 20)
        node.fillColor = currentVisualTheme.scenePowerUpColor
        node.strokeColor = currentVisualTheme.sceneBallStrokeColor
        node.lineWidth = 2
        node.glowWidth = currentVisualTheme.showsGlow ? 6 : 0
        node.position = CGPoint(x: frame.midX, y: CGFloat.random(in: frame.minY + 80 ... frame.maxY - 80))
        node.zPosition = 3
        addChild(node)
        powerUpNode = node

        let label = SKLabelNode(text: type.title)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 13
        label.position = CGPoint(x: node.position.x, y: node.position.y - 38)
        label.fontColor = .white
        label.zPosition = 3
        addChild(label)
        powerUpLabel = label
    }

    /// Detects when the ball touches the spawned power-up and attributes the
    /// pickup to the side that last hit the ball.
    func checkPowerUpCollection(currentTime: TimeInterval) {
        guard let powerUpNode, let type = spawnedPowerUp else { return }
        let distance = hypot(ball.position.x - powerUpNode.position.x, ball.position.y - powerUpNode.position.y)
        // The power-up sits in neutral space, so `lastHitter` decides which side
        // earns the pickup when the ball makes contact with it.
        guard distance <= 28, let owner = lastHitter else { return }

        applyPowerUp(type, to: owner, currentTime: currentTime)
        gameState?.registerPowerUpCollected(type, collectedBy: owner)
        removePowerUpNode()
        spawnedPowerUp = nil
    }

    /// Activates the selected power-up for the owning side and applies any
    /// immediate scene changes needed for its effect.
    func applyPowerUp(_ powerUp: PowerUpType, to owner: WinnerSide, currentTime: TimeInterval) {
        activePowerUpOwner = owner
        activePowerUpUntil = currentTime + GameConfig.powerUpDuration
        gameState?.setActivePowerUp(powerUp)

        switch powerUp {
        case .paddleExpand:
            if owner == .playerOne {
                playerPaddleHeight = basePaddleHeight * GameConfig.expandedPaddleMultiplier
                updatePaddle(playerPaddle, height: playerPaddleHeight, color: currentVisualTheme.scenePlayerColor)
            } else {
                opponentPaddleHeight = basePaddleHeight * GameConfig.expandedPaddleMultiplier
                updatePaddle(opponentPaddle, height: opponentPaddleHeight, color: currentVisualTheme.sceneOpponentColor)
            }
            clampPaddlesToBounds()
        case .slowMotion:
            // Slow motion is read dynamically during ball movement, so the state
            // change above is enough to activate it.
            break
        case .curveShot:
            // Curve shot is consumed on the owner's next paddle hit.
            pendingCurveOwner = owner
        }
    }

    /// Expires active power-ups once their timer runs out.
    func updateActivePowerUpState(currentTime: TimeInterval) {
        guard let activePowerUpUntil, currentTime >= activePowerUpUntil else { return }
        clearActivePowerUpVisuals()
    }

    /// Clears any temporary paddle sizing and resets all active power-up state.
    func clearActivePowerUpVisuals() {
        playerPaddleHeight = basePaddleHeight
        opponentPaddleHeight = basePaddleHeight
        updatePaddle(playerPaddle, height: playerPaddleHeight, color: currentVisualTheme.scenePlayerColor)
        updatePaddle(opponentPaddle, height: opponentPaddleHeight, color: currentVisualTheme.sceneOpponentColor)
        activePowerUpOwner = nil
        activePowerUpUntil = nil
        pendingCurveOwner = nil
        gameState?.setActivePowerUp(nil)
    }

    /// Removes the currently spawned power-up node and label from the scene.
    func removePowerUpNode() {
        powerUpNode?.removeFromParent()
        powerUpLabel?.removeFromParent()
        powerUpNode = nil
        powerUpLabel = nil
    }

    /// Records the current scene state into a rolling replay buffer capped to the
    /// configured frame limit.
    func captureReplayFrame() {
        guard !isReplayingLastPoint else { return }
        replayBuffer.append(SceneReplayFrame(ballPosition: ball.position, playerPaddleY: playerPaddle.position.y, opponentPaddleY: opponentPaddle.position.y))
        if replayBuffer.count > GameConfig.replayFrameLimit {
            // Drop the oldest frames so the buffer behaves like a ring and always
            // keeps the most recent few seconds of gameplay.
            replayBuffer.removeFirst(replayBuffer.count - GameConfig.replayFrameLimit)
        }
    }
}
