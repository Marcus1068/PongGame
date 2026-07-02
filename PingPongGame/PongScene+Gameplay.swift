// PongScene+Gameplay.swift
//
// Implements the frame-by-frame gameplay rules for PongScene.
// This file advances the ball, moves the AI paddle, resolves paddle bounces,
// awards points, and triggers rally-based effects such as speed boosts.

import SpriteKit

extension PongScene {
    /// Advances the ball for one frame and reflects it off the top/bottom walls.
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

    /// Moves the computer paddle toward a style-dependent target, then blends
    /// that target with the center line to simulate imperfect reactions.
    func updateComputerAI(deltaTime: CGFloat) {
        guard let gameState else { return }

        let speed = gameState.difficulty.trackingSpeed * deltaTime
        let targetY: CGFloat

        switch gameState.aiStyle {
        case .balanced:
            // Simply track the live ball position for a straightforward rally.
            targetY = ball.position.y
        case .defensive:
            // Stay closer to center so the AI overcommits less on steep angles.
            targetY = frame.midY + (ball.position.y - frame.midY) * 0.6
        case .aggressive:
            // Look slightly ahead in the ball's path, especially when the ball
            // is already traveling toward the AI paddle.
            let predictionWindow: CGFloat = ballVelocity.dx < 0 ? 0.22 : 0.08
            targetY = ball.position.y + ballVelocity.dy * predictionWindow
        case .mirror:
            // Mirror the human player's offset from center for a less "tracking"
            // feeling and a more stylistic opponent.
            targetY = frame.midY - (playerPaddle.position.y - frame.midY)
        }

        // Reaction bias lets lower difficulties drift partway back toward center
        // instead of perfectly chasing the computed target.
        let adjustedTarget = targetY * gameState.difficulty.reactionBias + frame.midY * (1 - gameState.difficulty.reactionBias)
        if opponentPaddle.position.y < adjustedTarget - 4 {
            opponentPaddle.position.y += speed
        } else if opponentPaddle.position.y > adjustedTarget + 4 {
            opponentPaddle.position.y -= speed
        }

        clampPaddlesToBounds()
    }

    /// Checks for ball/paddle overlap on the side the ball is currently moving
    /// toward, with a short cooldown to avoid double-counting one impact.
    func checkCollisions(currentTime: TimeInterval) {
        let paddleHalfWidth = basePaddleWidth / 2

        if ballVelocity.dx > 0,
           currentTime - lastCollisionTime > GameConfig.paddleCollisionCooldown,
           intersects(ball: ball, paddle: playerPaddle, paddleHalfHeight: playerPaddleHeight / 2, paddleHalfWidth: paddleHalfWidth) {
            handlePaddleCollision(with: .playerOne, paddle: playerPaddle, paddleHeight: playerPaddleHeight, paddleColor: currentVisualTheme.scenePlayerColor)
            lastCollisionTime = currentTime
        }

        if ballVelocity.dx < 0,
           currentTime - lastCollisionTime > GameConfig.paddleCollisionCooldown,
           intersects(ball: ball, paddle: opponentPaddle, paddleHalfHeight: opponentPaddleHeight / 2, paddleHalfWidth: paddleHalfWidth) {
            handlePaddleCollision(with: .playerTwo, paddle: opponentPaddle, paddleHeight: opponentPaddleHeight, paddleColor: currentVisualTheme.sceneOpponentColor)
            lastCollisionTime = currentTime
        }
    }

    /// Fast axis-aligned bounding-box test between the circular ball's bounds
    /// and a rectangular paddle.
    func intersects(ball: SKShapeNode, paddle: SKShapeNode, paddleHalfHeight: CGFloat, paddleHalfWidth: CGFloat) -> Bool {
        // Treat the ball as its enclosing box here; the approximation is simple
        // and stable enough for this arcade-style collision response.
        ball.position.x + ballRadius >= paddle.position.x - paddleHalfWidth &&
        ball.position.x - ballRadius <= paddle.position.x + paddleHalfWidth &&
        ball.position.y + ballRadius >= paddle.position.y - paddleHalfHeight &&
        ball.position.y - ballRadius <= paddle.position.y + paddleHalfHeight
    }

    /// Reflects the ball off a paddle, choosing a new vertical component from the
    /// hit offset and applying any pending curve-shot or rally-speed effects.
    func handlePaddleCollision(with side: WinnerSide, paddle: SKShapeNode, paddleHeight: CGFloat, paddleColor: SKColor) {
        let paddleHalfHeight = paddleHeight / 2
        // Map the contact point to -1...1 so hits near the paddle tips launch at
        // steeper angles than hits near the center.
        let hitPosition = max(-1, min(1, (ball.position.y - paddle.position.y) / paddleHalfHeight))
        let horizontalDirection: CGFloat = side == .playerOne ? -1 : 1
        // Preserve at least the configured base speed so a shallow bounce never
        // slows the rally below the intended pace.
        let baseMagnitude = max(hypot(ballVelocity.dx, ballVelocity.dy), GameConfig.baseBallSpeed * CGFloat(gameState?.ballSpeed ?? 1))
        var verticalComponent = hitPosition * baseMagnitude * 0.82

        if pendingCurveOwner == side {
            // Curve shot adds an extra vertical kick on the owner's next return,
            // then immediately consumes the stored effect.
            verticalComponent += (side == .playerOne ? -1 : 1) * baseMagnitude * GameConfig.curveShotStrength
            pendingCurveOwner = nil
            gameState?.latestHighlightText = String(localized: "Curve shot released")
        }

        ballVelocity.dx = abs(baseMagnitude) * horizontalDirection
        ballVelocity.dy = verticalComponent
        // Snap the ball just outside the paddle face so the next frame does not
        // start with the ball still intersecting the same paddle.
        ball.position.x = paddle.position.x + (side == .playerOne ? -(basePaddleWidth / 2 + ballRadius) : (basePaddleWidth / 2 + ballRadius))

        rallyHitCount += 1
        lastHitter = side
        gameState?.registerHit()
        gameState?.registerRallyLength(rallyHitCount)

        if gameState?.isSpeedBoostEnabled == true,
           rallyHitCount % GameConfig.speedBoostEveryHits == 0 {
            currentSpeedMultiplier = min(GameConfig.maxRallySpeedMultiplier, currentSpeedMultiplier * GameConfig.speedBoostStep)
            gameState?.registerSpeedBoost()
            gameState?.latestHighlightText = String(localized: "Speed boost x\(currentSpeedMultiplier, format: .number.precision(.fractionLength(1)))")
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

    /// Displays a short center-screen banner when a rally speed boost activates.
    func showSpeedBoostEffect() {
        let label = SKLabelNode(text: String(localized: "SPEED BOOST"))
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 30
        label.fontColor = currentVisualTheme.speedBoostTextColor
        label.position = CGPoint(x: frame.midX, y: frame.midY + 120)
        label.zPosition = 999

        let background = SKShapeNode(rectOf: CGSize(width: 250, height: 52), cornerRadius: 18)
        background.fillColor = currentVisualTheme.speedBoostBackgroundColor
        background.strokeColor = .clear
        background.alpha = 0
        background.position = label.position
        background.zPosition = 998

        addChild(background)
        addChild(label)

        background.run(.sequence([.fadeAlpha(to: 0.9, duration: 0.1), .wait(forDuration: 0.5), .fadeOut(withDuration: 0.2), .removeFromParent()]))
        label.run(.sequence([.fadeIn(withDuration: 0.1), .wait(forDuration: 0.5), .fadeOut(withDuration: 0.2), .removeFromParent()]))
    }

    /// Detects when the ball has fully crossed either goal line.
    func checkScore() {
        if ball.position.x < frame.minX - ballRadius {
            finalizePoint(for: .playerOne)
        } else if ball.position.x > frame.maxX + ballRadius {
            finalizePoint(for: .playerTwo)
        }
    }

    /// Commits a scored point by saving the just-finished replay frames, updating
    /// `GameState`, and either resetting the serve or freezing on match end.
    func finalizePoint(for scorer: WinnerSide) {
        // Capture the rally before GameState advances, so the replay always shows
        // the exact sequence that produced the point.
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
