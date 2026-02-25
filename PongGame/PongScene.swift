//
//  PongScene.swift
//  PongGame
//
//  Created by Marcus Deuß on 25.02.26.
//

import SpriteKit

class PongScene: SKScene {
    // Game objects
    private var ball: SKShapeNode!
    private var playerPaddle: SKShapeNode!
    private var computerPaddle: SKShapeNode!
    private var centerLine: SKShapeNode!
    private var ballTrail: SKEmitterNode!
    
    // Ball physics
    private var ballVelocity = CGVector(dx: 400, dy: 400)
    private let baseSpeed: CGFloat = 400
    private var currentSpeedMultiplier: CGFloat = 1.0
    
    // Consecutive hits tracking
    private var consecutiveHits: Int = 0
    private var lastHitByPlayer: Bool? = nil
    
    // Paddle dimensions
    private let paddleWidth: CGFloat = 20
    private let paddleHeight: CGFloat = 100
    
    // Game state reference
    weak var gameState: GameState?
    
    // Input tracking
    private var touchY: CGFloat?
    private var keysPressed = Set<String>()
    
    override func didMove(to view: SKView) {
        setupScene()
        setupCenterLine()
        setupBall()
        setupPaddles()
        resetBall()
    }
    
    private func setupScene() {
        // Gradient background
        let background = SKShapeNode(rectOf: frame.size)
        background.fillColor = SKColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1.0)
        background.strokeColor = .clear
        background.position = CGPoint(x: frame.midX, y: frame.midY)
        background.zPosition = -1
        addChild(background)
        
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsWorld.gravity = .zero
    }
    
    private func setupCenterLine() {
        // Dashed center line
        let dashLength: CGFloat = 20
        let gapLength: CGFloat = 15
        let lineX = frame.midX
        
        var yPosition = frame.minY
        
        while yPosition < frame.maxY {
            let dash = SKShapeNode(rectOf: CGSize(width: 3, height: dashLength), cornerRadius: 1.5)
            dash.fillColor = SKColor.white.withAlphaComponent(0.3)
            dash.strokeColor = .clear
            dash.position = CGPoint(x: lineX, y: yPosition + dashLength / 2)
            dash.zPosition = -0.5
            addChild(dash)
            
            yPosition += dashLength + gapLength
        }
    }
    
    private func setupBall() {
        // Create glowing ball
        ball = SKShapeNode(circleOfRadius: 10)
        ball.fillColor = .white
        ball.strokeColor = SKColor.cyan
        ball.lineWidth = 2
        ball.position = CGPoint(x: frame.midX, y: frame.midY)
        
        // Add glow effect
        ball.glowWidth = 3.0
        
        // Add particle trail
        ballTrail = SKEmitterNode()
        ballTrail.particleBirthRate = 50
        ballTrail.particleLifetime = 0.3
        ballTrail.particleSize = CGSize(width: 4, height: 4)
        ballTrail.particleScale = 1.0
        ballTrail.particleScaleSpeed = -0.5
        ballTrail.particleAlpha = 0.8
        ballTrail.particleAlphaSpeed = -2.0
        ballTrail.particleColor = SKColor.cyan
        ballTrail.particleColorBlendFactor = 1.0
        ballTrail.emissionAngle = 0
        ballTrail.emissionAngleRange = CGFloat.pi * 2
        ballTrail.particleSpeed = 10
        ballTrail.particleSpeedRange = 5
        ballTrail.zPosition = -0.1
        ballTrail.particleBlendMode = .add
        
        ball.addChild(ballTrail)
        addChild(ball)
    }
    
    private func setupPaddles() {
        // Player paddle (right side) - cyan glow
        playerPaddle = SKShapeNode(rectOf: CGSize(width: paddleWidth, height: paddleHeight), cornerRadius: 10)
        playerPaddle.fillColor = SKColor.cyan
        playerPaddle.strokeColor = SKColor.cyan.withAlphaComponent(0.8)
        playerPaddle.lineWidth = 3
        playerPaddle.glowWidth = 5.0
        playerPaddle.position = CGPoint(x: frame.maxX - 40, y: frame.midY)
        addChild(playerPaddle)
        
        // Computer paddle (left side) - magenta glow
        computerPaddle = SKShapeNode(rectOf: CGSize(width: paddleWidth, height: paddleHeight), cornerRadius: 10)
        computerPaddle.fillColor = SKColor.magenta
        computerPaddle.strokeColor = SKColor.magenta.withAlphaComponent(0.8)
        computerPaddle.lineWidth = 3
        computerPaddle.glowWidth = 5.0
        computerPaddle.position = CGPoint(x: frame.minX + 40, y: frame.midY)
        addChild(computerPaddle)
    }
    
    private func resetBall() {
        ball.position = CGPoint(x: frame.midX, y: frame.midY)
        
        // Reset consecutive hits and speed multiplier
        consecutiveHits = 0
        lastHitByPlayer = nil
        currentSpeedMultiplier = 1.0
        
        // Random direction
        let randomAngle = CGFloat.random(in: -CGFloat.pi/4...CGFloat.pi/4)
        let speed: CGFloat = baseSpeed * CGFloat(gameState?.ballSpeed ?? 1.0)
        let direction: CGFloat = Bool.random() ? 1 : -1
        
        ballVelocity = CGVector(
            dx: cos(randomAngle) * speed * direction,
            dy: sin(randomAngle) * speed
        )
        
        // Flash effect on reset
        let flash = SKAction.sequence([
            SKAction.scale(to: 1.5, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        ball.run(flash)
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard let gameState = gameState else { return }
        
        // Control pause state for animations
        let shouldBePaused = gameState.isPaused || !gameState.isGameActive
        
        // Pause/unpause ball trail
        if let trail = ball.childNode(withName: "//ballTrail") as? SKEmitterNode ?? ballTrail {
            trail.isPaused = shouldBePaused
        }
        
        // Don't update game logic if paused or not active
        if shouldBePaused {
            return
        }
        
        updateBallPosition()
        updateComputerAI()
        checkCollisions()
        checkScore()
        
#if os(macOS)
        // Continuously update paddle position for smooth keyboard movement
        if !keysPressed.isEmpty {
            updatePlayerPaddleForKeyboard()
        }
#else
        // Update touch position for iOS
        updatePlayerPaddlePosition()
#endif
    }
    
    private func updateBallPosition() {
        let deltaTime: CGFloat = 1.0 / 60.0
        let speedMultiplier = CGFloat(gameState?.ballSpeed ?? 1.0) * currentSpeedMultiplier
        
        ball.position.x += ballVelocity.dx * deltaTime * speedMultiplier
        ball.position.y += ballVelocity.dy * deltaTime * speedMultiplier
        
        // Bounce off top and bottom with visual feedback
        if ball.position.y <= frame.minY + 10 || ball.position.y >= frame.maxY - 10 {
            ballVelocity.dy *= -1
            ball.position.y = max(frame.minY + 10, min(frame.maxY - 10, ball.position.y))
            
            // Bounce flash effect
            let flash = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.5, duration: 0.05),
                SKAction.fadeAlpha(to: 1.0, duration: 0.05)
            ])
            ball.run(flash)
        }
    }
    
    private func updateComputerAI() {
        // Simple AI: follow the ball with some delay for realism
        let aiSpeed: CGFloat = 5.0
        let targetY = ball.position.y
        
        if computerPaddle.position.y < targetY - 10 {
            computerPaddle.position.y += aiSpeed
        } else if computerPaddle.position.y > targetY + 10 {
            computerPaddle.position.y -= aiSpeed
        }
        
        // Keep paddle in bounds
        computerPaddle.position.y = max(frame.minY + paddleHeight / 2, 
                                       min(frame.maxY - paddleHeight / 2, computerPaddle.position.y))
    }
    
    private func checkCollisions() {
        let ballRadius: CGFloat = 10
        let paddleHalfHeight = paddleHeight / 2
        let paddleHalfWidth = paddleWidth / 2
        
        // Player paddle collision
        if ball.position.x + ballRadius >= playerPaddle.position.x - paddleHalfWidth &&
           ball.position.x - ballRadius <= playerPaddle.position.x + paddleHalfWidth &&
           ball.position.y + ballRadius >= playerPaddle.position.y - paddleHalfHeight &&
           ball.position.y - ballRadius <= playerPaddle.position.y + paddleHalfHeight {
            
            if ballVelocity.dx > 0 {
                ballVelocity.dx *= -1.05 // Increase speed slightly
                
                // Track consecutive hits
                trackConsecutiveHit(byPlayer: true)
                
                // Add angle based on where ball hits paddle
                let hitPosition = (ball.position.y - playerPaddle.position.y) / paddleHalfHeight
                ballVelocity.dy += hitPosition * 200
                
                // Visual feedback
                createPaddleHitEffect(at: ball.position, color: .cyan)
                let pulse = SKAction.sequence([
                    SKAction.scale(to: 1.2, duration: 0.05),
                    SKAction.scale(to: 1.0, duration: 0.05)
                ])
                playerPaddle.run(pulse)
            }
        }
        
        // Computer paddle collision
        if ball.position.x - ballRadius <= computerPaddle.position.x + paddleHalfWidth &&
           ball.position.x + ballRadius >= computerPaddle.position.x - paddleHalfWidth &&
           ball.position.y + ballRadius >= computerPaddle.position.y - paddleHalfHeight &&
           ball.position.y - ballRadius <= computerPaddle.position.y + paddleHalfHeight {
            
            if ballVelocity.dx < 0 {
                ballVelocity.dx *= -1.05
                
                // Track consecutive hits
                trackConsecutiveHit(byPlayer: false)
                
                let hitPosition = (ball.position.y - computerPaddle.position.y) / paddleHalfHeight
                ballVelocity.dy += hitPosition * 200
                
                // Visual feedback
                createPaddleHitEffect(at: ball.position, color: .magenta)
                let pulse = SKAction.sequence([
                    SKAction.scale(to: 1.2, duration: 0.05),
                    SKAction.scale(to: 1.0, duration: 0.05)
                ])
                computerPaddle.run(pulse)
            }
        }
    }
    
    private func trackConsecutiveHit(byPlayer: Bool) {
        // Check if this is a successful rally (ball alternating between players)
        if let lastPlayer = lastHitByPlayer {
            // If different player hit the ball, it's a successful rally continuation
            if lastPlayer != byPlayer {
                consecutiveHits += 1
                
                print("DEBUG: Rally count: \(consecutiveHits)")
                
                // Every 3 successful alternating hits, increase speed by 20%
                if consecutiveHits >= 3 && consecutiveHits % 3 == 0 {
                    currentSpeedMultiplier *= 1.2
                    
                    print("DEBUG: Speed boost triggered! New multiplier: \(currentSpeedMultiplier)")
                    
                    // Visual feedback for speed increase
                    let speedBoostLabel = SKLabelNode(text: "⚡ SPEED BOOST! ⚡")
                    speedBoostLabel.fontName = "AvenirNext-Bold"
                    speedBoostLabel.fontSize = 48
                    speedBoostLabel.fontColor = .white
                    speedBoostLabel.position = CGPoint(x: frame.midX, y: frame.midY + 100)
                    speedBoostLabel.zPosition = 1000
                    
                    // Add colorful background
                    let background = SKShapeNode(rectOf: CGSize(width: 450, height: 80), cornerRadius: 20)
                    background.fillColor = SKColor.yellow
                    background.strokeColor = .white
                    background.lineWidth = 4
                    background.alpha = 0
                    background.position = CGPoint(x: frame.midX, y: frame.midY + 100)
                    background.zPosition = 999
                    background.glowWidth = 10
                    
                    addChild(background)
                    addChild(speedBoostLabel)
                    
                    // Glow effect on label
                    speedBoostLabel.alpha = 0
                    
                    // Background animation
                    let bgFadeIn = SKAction.fadeAlpha(to: 0.95, duration: 0.15)
                    let bgWait = SKAction.wait(forDuration: 1.0)
                    let bgFadeOut = SKAction.fadeOut(withDuration: 0.3)
                    let bgRemove = SKAction.removeFromParent()
                    background.run(SKAction.sequence([bgFadeIn, bgWait, bgFadeOut, bgRemove]))
                    
                    // Label animation
                    let fadeIn = SKAction.fadeIn(withDuration: 0.15)
                    let scale1 = SKAction.scale(to: 1.2, duration: 0.1)
                    let scale2 = SKAction.scale(to: 1.0, duration: 0.1)
                    let wait = SKAction.wait(forDuration: 1.0)
                    let fadeOut = SKAction.fadeOut(withDuration: 0.3)
                    let remove = SKAction.removeFromParent()
                    let labelSequence = SKAction.sequence([fadeIn, scale1, scale2, wait, fadeOut, remove])
                    
                    speedBoostLabel.run(labelSequence)
                    
                    // Pulse animation for continuous visibility
                    let pulse = SKAction.sequence([
                        SKAction.scale(to: 1.05, duration: 0.2),
                        SKAction.scale(to: 1.0, duration: 0.2)
                    ])
                    let repeatPulse = SKAction.repeat(pulse, count: 3)
                    speedBoostLabel.run(repeatPulse)
                    
                    // Scale effect on ball
                    let scaleUp = SKAction.scale(to: 1.3, duration: 0.1)
                    let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
                    ball.run(SKAction.sequence([scaleUp, scaleDown]))
                    
                    // Screen flash effect
                    let flashNode = SKShapeNode(rectOf: frame.size)
                    flashNode.fillColor = SKColor.yellow
                    flashNode.strokeColor = .clear
                    flashNode.alpha = 0
                    flashNode.position = CGPoint(x: frame.midX, y: frame.midY)
                    flashNode.zPosition = 998
                    addChild(flashNode)
                    
                    let flashIn = SKAction.fadeAlpha(to: 0.3, duration: 0.1)
                    let flashOut = SKAction.fadeOut(withDuration: 0.2)
                    let flashRemove = SKAction.removeFromParent()
                    flashNode.run(SKAction.sequence([flashIn, flashOut, flashRemove]))
                }
            }
        } else {
            // First hit of the rally
            consecutiveHits = 0
            print("DEBUG: Starting new rally")
        }
        
        lastHitByPlayer = byPlayer
    }
    
    private func createPaddleHitEffect(at position: CGPoint, color: SKColor) {
        // Create particle burst on paddle hit
        let particles = SKEmitterNode()
        particles.particleBirthRate = 200
        particles.numParticlesToEmit = 15
        particles.particleLifetime = 0.3
        particles.particleSize = CGSize(width: 3, height: 3)
        particles.particleScale = 1.0
        particles.particleScaleSpeed = -0.5
        particles.particleAlpha = 1.0
        particles.particleAlphaSpeed = -3.0
        particles.particleColor = color
        particles.particleColorBlendFactor = 1.0
        particles.emissionAngle = ballVelocity.dx > 0 ? CGFloat.pi : 0
        particles.emissionAngleRange = CGFloat.pi / 3
        particles.particleSpeed = 100
        particles.particleSpeedRange = 50
        particles.position = position
        particles.particleBlendMode = .add
        
        addChild(particles)
        
        // Remove after animation
        let wait = SKAction.wait(forDuration: 0.5)
        let remove = SKAction.removeFromParent()
        particles.run(SKAction.sequence([wait, remove]))
    }
    
    private func checkScore() {
        // Player scores (ball goes past left edge)
        if ball.position.x < frame.minX {
            gameState?.playerScored()
            resetBall()
        }
        
        // Computer scores (ball goes past right edge)
        if ball.position.x > frame.maxX {
            gameState?.computerScored()
            resetBall()
        }
    }
    
    // MARK: - Touch Input (iOS)
    
#if os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        touchY = touch.location(in: self).y
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        touchY = touch.location(in: self).y
        updatePlayerPaddlePosition()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchY = nil
    }
    
    private func updatePlayerPaddlePosition() {
        guard let y = touchY else { return }
        playerPaddle.position.y = max(frame.minY + paddleHeight / 2,
                                     min(frame.maxY - paddleHeight / 2, y))
    }
#endif
    
    // MARK: - Keyboard Input (macOS)
    
#if os(macOS)
    override func keyDown(with event: NSEvent) {
        keysPressed.insert(event.charactersIgnoringModifiers ?? "")
        updatePlayerPaddleForKeyboard()
    }
    
    override func keyUp(with event: NSEvent) {
        keysPressed.remove(event.charactersIgnoringModifiers ?? "")
    }
    
    private func updatePlayerPaddleForKeyboard() {
        let speed: CGFloat = 10
        
        if keysPressed.contains("w") || keysPressed.contains("W") {
            playerPaddle.position.y += speed
        }
        if keysPressed.contains("s") || keysPressed.contains("S") {
            playerPaddle.position.y -= speed
        }
        
        // Arrow keys
        if keysPressed.contains(String(UnicodeScalar(NSUpArrowFunctionKey)!)) {
            playerPaddle.position.y += speed
        }
        if keysPressed.contains(String(UnicodeScalar(NSDownArrowFunctionKey)!)) {
            playerPaddle.position.y -= speed
        }
        
        playerPaddle.position.y = max(frame.minY + paddleHeight / 2,
                                     min(frame.maxY - paddleHeight / 2, playerPaddle.position.y))
    }
#endif
}
