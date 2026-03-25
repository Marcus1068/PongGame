import SpriteKit

extension PongScene {
    func updateReplayFrame() {
        guard replayIndex < lastPointReplay.count else {
            finishReplay()
            return
        }

        let frame = lastPointReplay[replayIndex]
        ball.position = frame.ballPosition
        playerPaddle.position.y = frame.playerPaddleY
        opponentPaddle.position.y = frame.opponentPaddleY
        replayIndex += 1
    }

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

    func checkPowerUpCollection(currentTime: TimeInterval) {
        guard let powerUpNode, let type = spawnedPowerUp else { return }
        let distance = hypot(ball.position.x - powerUpNode.position.x, ball.position.y - powerUpNode.position.y)
        guard distance <= 28, let owner = lastHitter else { return }

        applyPowerUp(type, to: owner, currentTime: currentTime)
        gameState?.registerPowerUpCollected(type)
        removePowerUpNode()
        spawnedPowerUp = nil
    }

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
            break
        case .curveShot:
            pendingCurveOwner = owner
        }
    }

    func updateActivePowerUpState(currentTime: TimeInterval) {
        guard let activePowerUpUntil, currentTime >= activePowerUpUntil else { return }
        clearActivePowerUpVisuals()
    }

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

    func removePowerUpNode() {
        powerUpNode?.removeFromParent()
        powerUpLabel?.removeFromParent()
        powerUpNode = nil
        powerUpLabel = nil
    }

    func captureReplayFrame() {
        guard !isReplayingLastPoint else { return }
        replayBuffer.append(SceneReplayFrame(ballPosition: ball.position, playerPaddleY: playerPaddle.position.y, opponentPaddleY: opponentPaddle.position.y))
        if replayBuffer.count > GameConfig.replayFrameLimit {
            replayBuffer.removeFirst(replayBuffer.count - GameConfig.replayFrameLimit)
        }
    }
}
