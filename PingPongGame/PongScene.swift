//
//  PongScene.swift
//  PongGame
//
//  Created by Marcus Deuß on 25.02.26.
//

import SpriteKit
import AVFoundation

class PongScene: SKScene {
    // Game objects
    private var ball: SKShapeNode!
    private var playerPaddle: SKShapeNode!
    private var computerPaddle: SKShapeNode!
    private var centerLine: SKShapeNode!
    private var ballTrail: SKEmitterNode!
    private var sceneBg: SKShapeNode!
    
    // Color scheme tracking
    private var lastIsBlackAndWhite: Bool?
    
    // Ball physics
    private var ballVelocity = CGVector(dx: 400, dy: 400)
    private let baseSpeed: CGFloat = 400
    private var currentSpeedMultiplier: CGFloat = 1.0
    
    // Consecutive hits tracking
    private var consecutiveHits: Int = 0
    private var lastHitByPlayer: Bool? = nil
    
    // Paddle dimensions — 30 % thicker on iPhone (Dynamic Island); 30 % taller on iPad
    #if os(iOS)
    private let paddleWidth: CGFloat  = UIDevice.current.userInterfaceIdiom == .phone ? 26 : 20
    private let paddleHeight: CGFloat = UIDevice.current.userInterfaceIdiom == .pad  ? 130 : 100
    #else
    private let paddleWidth: CGFloat  = 20
    private let paddleHeight: CGFloat = 100
    #endif
    
    // Audio
    private var blipEngine: AVAudioEngine?
    private var blipPlayerNode = AVAudioPlayerNode()
    private var playerBlipBuffer: AVAudioPCMBuffer?
    private var computerBlipBuffer: AVAudioPCMBuffer?
    private var wallBounceBuffer: AVAudioPCMBuffer?
    
    // Game state reference
    weak var gameState: GameState?
    
    // Input tracking
    private var keysPressed = Set<String>()
#if os(iOS)
    private var playerTouch: UITouch?   // right paddle
    private var player2Touch: UITouch?  // left paddle (two-player mode)
#endif
    
    override func didMove(to view: SKView) {
        setupScene()
        setupCenterLine()
        setupBall()
        setupPaddles()
        resetBall()
        setupAudio()
    }
    
    private func setupScene() {
        // Gradient background
        sceneBg = SKShapeNode(rectOf: frame.size)
        sceneBg.fillColor = SKColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1.0)
        sceneBg.strokeColor = .clear
        sceneBg.position = CGPoint(x: frame.midX, y: frame.midY)
        sceneBg.zPosition = -1
        addChild(sceneBg)
        
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
            dash.name = "centerLineDash"
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
    
    // MARK: - Orientation / Resize

    override func didChangeSize(_ oldSize: CGSize) {
        guard sceneBg != nil else { return }   // not yet set up

        // Background
        sceneBg.path = CGPath(
            rect: CGRect(x: -frame.width / 2, y: -frame.height / 2,
                         width: frame.width, height: frame.height),
            transform: nil
        )
        sceneBg.position = CGPoint(x: frame.midX, y: frame.midY)

        // Physics boundary
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)

        // Center-line dashes — remove old, draw new
        enumerateChildNodes(withName: "centerLineDash") { node, _ in node.removeFromParent() }
        setupCenterLine()

        // Paddles — keep Y but clamp to new bounds, update X edges
        playerPaddle.position.x  = frame.maxX - 40
        computerPaddle.position.x = frame.minX + 40
        playerPaddle.position.y  = max(frame.minY + paddleHeight / 2,
                                       min(frame.maxY - paddleHeight / 2, playerPaddle.position.y))
        computerPaddle.position.y = max(frame.minY + paddleHeight / 2,
                                        min(frame.maxY - paddleHeight / 2, computerPaddle.position.y))

        // Ball — clamp into new bounds
        ball.position.x = max(frame.minX + 10, min(frame.maxX - 10, ball.position.x))
        ball.position.y = max(frame.minY + 10, min(frame.maxY - 10, ball.position.y))
    }

    // MARK: - Color Scheme
    
    private func applyColorScheme(isBlackAndWhite: Bool) {
        if isBlackAndWhite {
            sceneBg.fillColor = .black
            ball.strokeColor = .white
            ball.glowWidth = 0
            ballTrail.particleBirthRate = 0
            playerPaddle.fillColor = .white
            playerPaddle.strokeColor = .white
            playerPaddle.glowWidth = 0
            computerPaddle.fillColor = .white
            computerPaddle.strokeColor = .white
            computerPaddle.glowWidth = 0
        } else {
            sceneBg.fillColor = SKColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1.0)
            ball.strokeColor = .cyan
            ball.glowWidth = 3.0
            ballTrail.particleBirthRate = 50
            ballTrail.particleColor = .cyan
            playerPaddle.fillColor = .cyan
            playerPaddle.strokeColor = SKColor.cyan.withAlphaComponent(0.8)
            playerPaddle.glowWidth = 5.0
            computerPaddle.fillColor = .magenta
            computerPaddle.strokeColor = SKColor.magenta.withAlphaComponent(0.8)
            computerPaddle.glowWidth = 5.0
        }
        enumerateChildNodes(withName: "centerLineDash") { node, _ in
            (node as? SKShapeNode)?.fillColor = SKColor.white.withAlphaComponent(isBlackAndWhite ? 0.5 : 0.3)
        }
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
        
        // Apply color scheme if it changed
        let isBlackAndWhite = gameState.isBlackAndWhite
        if lastIsBlackAndWhite != isBlackAndWhite {
            lastIsBlackAndWhite = isBlackAndWhite
            applyColorScheme(isBlackAndWhite: isBlackAndWhite)
        }
        
        // Don't update game logic if paused, not active, or waiting for player to start
        let shouldBePaused = gameState.isPaused || !gameState.isGameActive || !gameState.hasStarted
        
        // Pause/unpause ball trail
        if let trail = ball.childNode(withName: "//ballTrail") as? SKEmitterNode ?? ballTrail {
            trail.isPaused = shouldBePaused
        }
        
        // Don't update game logic if paused or not active
        if shouldBePaused {
            return
        }
        
        updateBallPosition()

        if gameState.gameMode == .twoPlayers {
#if os(macOS)
            updatePlayer2PaddleForKeyboard()
#endif
            // iOS player 2 is handled directly in touch callbacks
        } else {
            updateComputerAI()
        }

        checkCollisions()
        checkScore()

#if os(macOS)
        if !keysPressed.isEmpty {
            updatePlayerPaddleForKeyboard()
        }
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
            
            playWallSound()
            
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
        let aiSpeed: CGFloat
        switch gameState?.difficulty {
        case .easy:   aiSpeed = 3.0
        case .medium: aiSpeed = 5.0
        case .hard:   aiSpeed = 8.0
        case nil:     aiSpeed = 5.0
        }
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
                
                // Set angle based on where ball hits paddle (not additive — prevents unbounded dy)
                let hitPosition = (ball.position.y - playerPaddle.position.y) / paddleHalfHeight
                ballVelocity.dy = hitPosition * abs(ballVelocity.dx)
                
                // Visual feedback
                createPaddleHitEffect(at: ball.position, color: gameState?.isBlackAndWhite == true ? .white : .cyan)
                playBlipSound(frequency: 480)
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
                
                // Set angle based on where ball hits paddle (not additive — prevents unbounded dy)
                let hitPosition = (ball.position.y - computerPaddle.position.y) / paddleHalfHeight
                ballVelocity.dy = hitPosition * abs(ballVelocity.dx)
                
                // Visual feedback
                createPaddleHitEffect(at: ball.position, color: gameState?.isBlackAndWhite == true ? .white : .magenta)
                playBlipSound(frequency: 320)
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
                
                
                // Every 3 successful alternating hits, increase speed by 20%
                if consecutiveHits >= 3 && consecutiveHits % 3 == 0 {
                    currentSpeedMultiplier *= 1.2
                    
                    // Visual feedback for speed increase
                    let bwMode = gameState?.isBlackAndWhite ?? false
                    let speedBoostLabel = SKLabelNode(text: String(localized: "⚡ SPEED BOOST! ⚡"))
                    speedBoostLabel.fontName = "AvenirNext-Bold"
                    speedBoostLabel.fontSize = 48
                    speedBoostLabel.fontColor = bwMode ? .black : .white
                    speedBoostLabel.position = CGPoint(x: frame.midX, y: frame.midY + 100)
                    speedBoostLabel.zPosition = 1000
                    
                    // Add colorful background
                    let background = SKShapeNode(rectOf: CGSize(width: 450, height: 80), cornerRadius: 20)
                    background.fillColor = bwMode ? .white : SKColor.yellow
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
                    flashNode.fillColor = bwMode ? .white : SKColor.yellow
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
    
    // MARK: - Audio

    private func setupAudio() {
        let sampleRate: Double = 44100
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        
        let engine = AVAudioEngine()
        engine.attach(blipPlayerNode)
        engine.connect(blipPlayerNode, to: engine.mainMixerNode, format: format)
        
        playerBlipBuffer   = makeBlipBuffer(frequency: 480, sampleRate: sampleRate, format: format)
        computerBlipBuffer = makeBlipBuffer(frequency: 320, sampleRate: sampleRate, format: format)
        wallBounceBuffer   = makeWallBounceBuffer(sampleRate: sampleRate, format: format)
        
        do {
            try engine.start()
            blipPlayerNode.play()
            blipEngine = engine
        } catch { /* audio is non-critical */ }
    }
    
    private func makeBlipBuffer(frequency: Double, sampleRate: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let duration: Double = 0.055
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        
        let data = buffer.floatChannelData![0]
        let attackLen = Int(0.003 * sampleRate)
        let releaseStart = Int(Double(frameCount) * 0.6)
        
        for f in 0..<Int(frameCount) {
            let t = Double(f) / sampleRate
            let wave: Float = sin(2.0 * .pi * frequency * t) >= 0 ? 0.35 : -0.35
            var env: Float = 1.0
            if f < attackLen {
                env = Float(f) / Float(attackLen)
            } else if f >= releaseStart {
                env = Float(Int(frameCount) - f) / Float(Int(frameCount) - releaseStart)
            }
            data[f] = wave * max(0, env)
        }
        return buffer
    }
    
    private func playBlipSound(frequency: Double = 480.0) {
        let buffer = frequency > 400 ? playerBlipBuffer : computerBlipBuffer
        guard let buffer else { return }
        blipPlayerNode.scheduleBuffer(buffer, at: nil, completionHandler: nil)
    }
    
    /// Shorter sine-wave "thock" — lower pitch and faster decay than the square-wave paddle blips.
    private func makeWallBounceBuffer(sampleRate: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let duration: Double = 0.035
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        
        let data = buffer.floatChannelData![0]
        let attackLen = Int(0.001 * sampleRate)  // 1 ms attack (snappier than blip)
        
        for f in 0..<Int(frameCount) {
            let t = Double(f) / sampleRate
            // Sine wave at 200 Hz — smooth timbre, distinct from square-wave blips
            let wave = Float(sin(2.0 * .pi * 200.0 * t)) * 0.30
            // Exponential decay after attack
            var env: Float = 1.0
            if f < attackLen {
                env = Float(f) / Float(attackLen)
            } else {
                let decayProgress = Double(f - attackLen) / Double(Int(frameCount) - attackLen)
                env = Float(exp(-4.0 * decayProgress))
            }
            data[f] = wave * env
        }
        return buffer
    }
    
    private func playWallSound() {
        guard let buffer = wallBounceBuffer else { return }
        blipPlayerNode.scheduleBuffer(buffer, at: nil, completionHandler: nil)
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
        for touch in touches {
            let loc = touch.location(in: self)
            if gameState?.gameMode == .twoPlayers {
                if loc.x >= frame.midX && playerTouch == nil {
                    playerTouch = touch
                    movePaddle(&playerPaddle.position.y, to: loc.y)
                } else if loc.x < frame.midX && player2Touch == nil {
                    player2Touch = touch
                    movePaddle(&computerPaddle.position.y, to: loc.y)
                }
            } else {
                if playerTouch == nil {
                    playerTouch = touch
                    movePaddle(&playerPaddle.position.y, to: loc.y)
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let y = touch.location(in: self).y
            if touch === playerTouch {
                movePaddle(&playerPaddle.position.y, to: y)
            } else if touch === player2Touch {
                movePaddle(&computerPaddle.position.y, to: y)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if touch === playerTouch  { playerTouch = nil }
            if touch === player2Touch { player2Touch = nil }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
    
    private func movePaddle(_ y: inout CGFloat, to targetY: CGFloat) {
        y = max(frame.minY + paddleHeight / 2,
                min(frame.maxY - paddleHeight / 2, targetY))
    }
#endif
    
    // MARK: - Keyboard Input (macOS)
    
#if os(macOS)
    override func keyDown(with event: NSEvent) {
        // Space bar toggles pause
        if event.keyCode == 49 {
            Task { @MainActor in gameState?.togglePause() }
            return
        }
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
    
    private func updatePlayer2PaddleForKeyboard() {
        let speed: CGFloat = 10
        
        // Player 2 uses I/K keys
        if keysPressed.contains("i") || keysPressed.contains("I") {
            computerPaddle.position.y += speed
        }
        if keysPressed.contains("k") || keysPressed.contains("K") {
            computerPaddle.position.y -= speed
        }
        
        computerPaddle.position.y = max(frame.minY + paddleHeight / 2,
                                       min(frame.maxY - paddleHeight / 2, computerPaddle.position.y))
    }
#endif
}
