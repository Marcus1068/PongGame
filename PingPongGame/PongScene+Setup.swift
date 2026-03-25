import SpriteKit
import AVFoundation

extension PongScene {
    func setupScene() {
        sceneBackground = SKShapeNode()
        sceneBackground.fillColor = SKColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1)
        sceneBackground.strokeColor = .clear
        sceneBackground.zPosition = -2
        addChild(sceneBackground)
        updateBackgroundPath()

        centerLineContainer.zPosition = -1
        addChild(centerLineContainer)

        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsWorld.gravity = .zero
    }

    func updateBackgroundPath() {
        sceneBackground.path = CGPath(rect: frame, transform: nil)
        sceneBackground.position = .zero
    }

    func setupCenterLine() {
        let dashLength: CGFloat = 20
        let gapLength: CGFloat = 15
        var yPosition = frame.minY
        while yPosition < frame.maxY {
            let dash = SKShapeNode(rectOf: CGSize(width: 3, height: dashLength), cornerRadius: 1.5)
            dash.fillColor = SKColor.white.withAlphaComponent(0.3)
            dash.strokeColor = .clear
            dash.position = CGPoint(x: frame.midX, y: yPosition + dashLength / 2)
            centerLineContainer.addChild(dash)
            yPosition += dashLength + gapLength
        }
    }

    func setupBall() {
        ball = SKShapeNode(circleOfRadius: ballRadius)
        ball.fillColor = .white
        ball.strokeColor = .cyan
        ball.lineWidth = 2
        ball.glowWidth = 3
        ball.position = CGPoint(x: frame.midX, y: frame.midY)

        ballTrail = SKEmitterNode()
        ballTrail.particleBirthRate = 50
        ballTrail.particleLifetime = 0.3
        ballTrail.particleSize = CGSize(width: 4, height: 4)
        ballTrail.particleScale = 1
        ballTrail.particleScaleSpeed = -0.5
        ballTrail.particleAlpha = 0.8
        ballTrail.particleAlphaSpeed = -2
        ballTrail.particleColor = .cyan
        ballTrail.particleColorBlendFactor = 1
        ballTrail.emissionAngleRange = .pi * 2
        ballTrail.particleSpeed = 10
        ballTrail.particleSpeedRange = 5
        ballTrail.zPosition = -0.1
        ballTrail.particleBlendMode = .add

        ball.addChild(ballTrail)
        addChild(ball)
    }

    func setupPaddles() {
        let paddleInset = paddleEdgeInset

        playerPaddle = makePaddle(color: .cyan, height: playerPaddleHeight)
        playerPaddle.position = CGPoint(x: frame.maxX - paddleInset, y: frame.midY)
        addChild(playerPaddle)

        opponentPaddle = makePaddle(color: .magenta, height: opponentPaddleHeight)
        opponentPaddle.position = CGPoint(x: frame.minX + paddleInset, y: frame.midY)
        addChild(opponentPaddle)
    }

    func makePaddle(color: SKColor, height: CGFloat) -> SKShapeNode {
        let paddle = SKShapeNode(rectOf: CGSize(width: basePaddleWidth, height: height), cornerRadius: 10)
        paddle.fillColor = color
        paddle.strokeColor = color.withAlphaComponent(0.8)
        paddle.lineWidth = 3
        paddle.glowWidth = 5
        return paddle
    }

    func updatePaddle(_ paddle: SKShapeNode, height: CGFloat, color: SKColor) {
        let rect = CGRect(x: -basePaddleWidth / 2, y: -height / 2, width: basePaddleWidth, height: height)
        paddle.path = CGPath(roundedRect: rect, cornerWidth: 10, cornerHeight: 10, transform: nil)
        paddle.fillColor = color
        paddle.strokeColor = color.withAlphaComponent(0.8)
        paddle.glowWidth = gameState?.isBlackAndWhite == true ? 0 : 5
    }

    func resetBall() {
        ball.position = CGPoint(x: frame.midX, y: frame.midY)
        rallyHitCount = 0
        lastHitter = nil
        currentSpeedMultiplier = 1
        spawnedPowerUp = nil
        removePowerUpNode()
        clearActivePowerUpVisuals()

        let randomAngle = CGFloat.random(in: -CGFloat.pi / 4 ... CGFloat.pi / 4)
        let baseSpeed = GameConfig.baseBallSpeed * CGFloat(gameState?.ballSpeed ?? 1)
        let direction: CGFloat = Bool.random() ? 1 : -1
        ballVelocity = CGVector(dx: cos(randomAngle) * baseSpeed * direction, dy: sin(randomAngle) * baseSpeed)
        lastBallSpeedSetting = gameState?.ballSpeed ?? 1

        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.5, duration: 0.08),
            SKAction.scale(to: 1.0, duration: 0.08)
        ])
        ball.run(pulse)
    }

    func applyColorSchemeIfNeeded() {
        let current = gameState?.isBlackAndWhite ?? false
        guard lastIsBlackAndWhite != current else { return }
        lastIsBlackAndWhite = current
        applyColorScheme(isBlackAndWhite: current)
    }

    func applyColorScheme(isBlackAndWhite: Bool) {
        if isBlackAndWhite {
            sceneBackground.fillColor = .black
            ball.strokeColor = .white
            ball.glowWidth = 0
            ballTrail.particleBirthRate = 0
            updatePaddle(playerPaddle, height: playerPaddleHeight, color: .white)
            updatePaddle(opponentPaddle, height: opponentPaddleHeight, color: .white)
        } else {
            sceneBackground.fillColor = SKColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1)
            ball.strokeColor = .cyan
            ball.glowWidth = 3
            ballTrail.particleBirthRate = 50
            ballTrail.particleColor = .cyan
            updatePaddle(playerPaddle, height: playerPaddleHeight, color: .cyan)
            updatePaddle(opponentPaddle, height: opponentPaddleHeight, color: .magenta)
        }

        centerLineContainer.children.compactMap { $0 as? SKShapeNode }.forEach {
            $0.fillColor = SKColor.white.withAlphaComponent(isBlackAndWhite ? 0.5 : 0.3)
        }
    }

    func handlePhaseTransitionIfNeeded() {
        guard let gameState else { return }
        guard lastObservedGamePhase != gameState.gamePhase else { return }
        let previousPhase = lastObservedGamePhase
        lastObservedGamePhase = gameState.gamePhase

        switch gameState.gamePhase {
        case .modeSelection:
            removePowerUpNode()
            replayBuffer.removeAll(keepingCapacity: true)
            lastPointReplay.removeAll(keepingCapacity: true)
            gameState.storeReplayAvailability(false)
            playerPaddle.position.y = frame.midY
            opponentPaddle.position.y = frame.midY
            resetBall()
        case .playing:
            if previousPhase == .modeSelection {
                playerPaddle.position.y = frame.midY
                opponentPaddle.position.y = frame.midY
                resetBall()
            }
        case .paused, .replaying, .winner, .loading:
            break
        }
    }

    func applyLiveSettingsIfNeeded() {
        guard let gameState else { return }

        if lastBallSpeedSetting != gameState.ballSpeed, lastBallSpeedSetting > 0 {
            let ratio = CGFloat(gameState.ballSpeed / lastBallSpeedSetting)
            ballVelocity.dx *= ratio
            ballVelocity.dy *= ratio
            lastBallSpeedSetting = gameState.ballSpeed
        }

        if lastSoundEnabled != gameState.isSoundEnabled || lastSoundVolume != gameState.soundVolume {
            lastSoundEnabled = gameState.isSoundEnabled
            lastSoundVolume = gameState.soundVolume
            let volume = gameState.isSoundEnabled ? Float(gameState.soundVolume) : 0
            blipPlayerNode.volume = volume
        }
    }

    var paddleEdgeInset: CGFloat {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            let horizontalSafeAreaInset = max(view?.safeAreaInsets.left ?? 0, view?.safeAreaInsets.right ?? 0)

            if frame.width > frame.height {
                let safeAreaDrivenInset = horizontalSafeAreaInset + basePaddleWidth / 2 + GameConfig.phoneSafeAreaPaddlePadding
                return max(GameConfig.compactPhonePaddleEdgeInset, safeAreaDrivenInset)
            }

            if frame.width <= 430 {
                return GameConfig.compactPhonePaddleEdgeInset
            }
        }
        #endif
        return GameConfig.defaultPaddleEdgeInset
    }

    func layoutPowerUpIfNeeded() {
        guard let node = powerUpNode, let label = powerUpLabel else { return }
        node.position.x = frame.midX
        label.position.x = node.position.x
    }

    func clampPaddlesToBounds() {
        playerPaddle.position.y = clamp(playerPaddle.position.y, min: frame.minY + playerPaddleHeight / 2, max: frame.maxY - playerPaddleHeight / 2)
        opponentPaddle.position.y = clamp(opponentPaddle.position.y, min: frame.minY + opponentPaddleHeight / 2, max: frame.maxY - opponentPaddleHeight / 2)
    }

    func clampBallToBounds() {
        ball.position.x = clamp(ball.position.x, min: frame.minX + ballRadius, max: frame.maxX - ballRadius)
        ball.position.y = clamp(ball.position.y, min: frame.minY + ballRadius, max: frame.maxY - ballRadius)
    }

    func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        Swift.max(minValue, Swift.min(maxValue, value))
    }
}
