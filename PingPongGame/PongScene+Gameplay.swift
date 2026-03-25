import SpriteKit

extension PongScene {
    func updateBallPosition(deltaTime: CGFloat) {
        let slowMotionMultiplier: CGFloat = activePowerUpOwner != nil && gameState?.activePowerUp == .slowMotion ? GameConfig.slowMotionMultiplier : 1
        let speedMultiplier = currentSpeedMultiplier * slowMotionMultiplier
        ball.position.x += ballVelocity.dx * deltaTime * speedMultiplier
        ball.position.y += ballVelocity.dy * deltaTime * speedMultiplier

        if ball.position.y <= frame.minY + ballRadius || ball.position.y >= frame.maxY - ballRadius {
            ballVelocity.dy *= -1
            ball.position.y = max(frame.minY + ballRadius, min(frame.maxY - ballRadius, ball.position.y))
            playWallSound()
            flashBall()
            triggerBounceHaptics()
        }
    }

    func updateComputerAI(deltaTime: CGFloat) {
        guard let gameState else { return }

        let speed = gameState.difficulty.trackingSpeed * deltaTime
        let targetY: CGFloat

        switch gameState.aiStyle {
        case .balanced:
            targetY = ball.position.y
        case .defensive:
            targetY = frame.midY + (ball.position.y - frame.midY) * 0.6
        case .aggressive:
            let predictionWindow: CGFloat = ballVelocity.dx < 0 ? 0.22 : 0.08
            targetY = ball.position.y + ballVelocity.dy * predictionWindow
        case .mirror:
            targetY = frame.midY - (playerPaddle.position.y - frame.midY)
        }

        let adjustedTarget = targetY * gameState.difficulty.reactionBias + frame.midY * (1 - gameState.difficulty.reactionBias)
        if opponentPaddle.position.y < adjustedTarget - 4 {
            opponentPaddle.position.y += speed
        } else if opponentPaddle.position.y > adjustedTarget + 4 {
            opponentPaddle.position.y -= speed
        }

        clampPaddlesToBounds()
    }

    func checkCollisions(currentTime: TimeInterval) {
        let paddleHalfWidth = basePaddleWidth / 2

        if ballVelocity.dx > 0,
           currentTime - lastCollisionTime > GameConfig.paddleCollisionCooldown,
           intersects(ball: ball, paddle: playerPaddle, paddleHalfHeight: playerPaddleHeight / 2, paddleHalfWidth: paddleHalfWidth) {
            handlePaddleCollision(with: .playerOne, paddle: playerPaddle, paddleHeight: playerPaddleHeight, paddleColor: gameState?.isBlackAndWhite == true ? .white : .cyan)
            lastCollisionTime = currentTime
        }

        if ballVelocity.dx < 0,
           currentTime - lastCollisionTime > GameConfig.paddleCollisionCooldown,
           intersects(ball: ball, paddle: opponentPaddle, paddleHalfHeight: opponentPaddleHeight / 2, paddleHalfWidth: paddleHalfWidth) {
            handlePaddleCollision(with: .playerTwo, paddle: opponentPaddle, paddleHeight: opponentPaddleHeight, paddleColor: gameState?.isBlackAndWhite == true ? .white : .magenta)
            lastCollisionTime = currentTime
        }
    }

    func intersects(ball: SKShapeNode, paddle: SKShapeNode, paddleHalfHeight: CGFloat, paddleHalfWidth: CGFloat) -> Bool {
        ball.position.x + ballRadius >= paddle.position.x - paddleHalfWidth &&
        ball.position.x - ballRadius <= paddle.position.x + paddleHalfWidth &&
        ball.position.y + ballRadius >= paddle.position.y - paddleHalfHeight &&
        ball.position.y - ballRadius <= paddle.position.y + paddleHalfHeight
    }

    func handlePaddleCollision(with side: WinnerSide, paddle: SKShapeNode, paddleHeight: CGFloat, paddleColor: SKColor) {
        let paddleHalfHeight = paddleHeight / 2
        let hitPosition = max(-1, min(1, (ball.position.y - paddle.position.y) / paddleHalfHeight))
        let horizontalDirection: CGFloat = side == .playerOne ? -1 : 1
        let baseMagnitude = max(hypot(ballVelocity.dx, ballVelocity.dy), GameConfig.baseBallSpeed * CGFloat(gameState?.ballSpeed ?? 1))
        var verticalComponent = hitPosition * baseMagnitude * 0.82

        if pendingCurveOwner == side {
            verticalComponent += (side == .playerOne ? -1 : 1) * baseMagnitude * GameConfig.curveShotStrength
            pendingCurveOwner = nil
            gameState?.latestHighlightText = "Curve shot released"
        }

        ballVelocity.dx = abs(baseMagnitude) * horizontalDirection
        ballVelocity.dy = verticalComponent
        ball.position.x = paddle.position.x + (side == .playerOne ? -(basePaddleWidth / 2 + ballRadius) : (basePaddleWidth / 2 + ballRadius))

        rallyHitCount += 1
        lastHitter = side
        gameState?.registerHit()
        gameState?.registerRallyLength(rallyHitCount)

        if gameState?.isSpeedBoostEnabled == true,
           rallyHitCount % GameConfig.speedBoostEveryHits == 0 {
            currentSpeedMultiplier = min(GameConfig.maxRallySpeedMultiplier, currentSpeedMultiplier * GameConfig.speedBoostStep)
            gameState?.registerSpeedBoost()
            gameState?.latestHighlightText = String(format: "Speed boost x%.1f", currentSpeedMultiplier)
            showSpeedBoostEffect()
        }

        if spawnedPowerUp == nil,
           !(gameState?.enabledPowerUps.isEmpty ?? true),
           rallyHitCount % GameConfig.powerUpSpawnEveryHits == 0 {
            spawnPowerUp()
        }

        playBlipSound(for: side)
        createPaddleHitEffect(at: ball.position, color: paddleColor)
        pulsePaddle(paddle)
        triggerPaddleHaptics()
    }

    func showSpeedBoostEffect() {
        let label = SKLabelNode(text: "SPEED BOOST")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 30
        label.fontColor = gameState?.isBlackAndWhite == true ? .black : .white
        label.position = CGPoint(x: frame.midX, y: frame.midY + 120)
        label.zPosition = 999

        let background = SKShapeNode(rectOf: CGSize(width: 250, height: 52), cornerRadius: 18)
        background.fillColor = gameState?.isBlackAndWhite == true ? .white : .yellow
        background.strokeColor = .clear
        background.alpha = 0
        background.position = label.position
        background.zPosition = 998

        addChild(background)
        addChild(label)

        background.run(.sequence([.fadeAlpha(to: 0.9, duration: 0.1), .wait(forDuration: 0.5), .fadeOut(withDuration: 0.2), .removeFromParent()]))
        label.run(.sequence([.fadeIn(withDuration: 0.1), .wait(forDuration: 0.5), .fadeOut(withDuration: 0.2), .removeFromParent()]))
    }

    func checkScore() {
        if ball.position.x < frame.minX - ballRadius {
            finalizePoint(for: .playerOne)
        } else if ball.position.x > frame.maxX + ballRadius {
            finalizePoint(for: .playerTwo)
        }
    }

    func finalizePoint(for scorer: WinnerSide) {
        lastPointReplay = replayBuffer
        gameState?.storeReplayAvailability(!lastPointReplay.isEmpty)
        replayBuffer.removeAll(keepingCapacity: true)
        gameState?.registerPoint(for: scorer)

        if case .winner = gameState?.gamePhase {
            ballVelocity = .zero
        } else {
            resetBall()
        }
    }
}
