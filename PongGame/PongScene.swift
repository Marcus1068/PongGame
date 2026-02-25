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
    
    // Ball physics
    private var ballVelocity = CGVector(dx: 400, dy: 400)
    
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
        setupBall()
        setupPaddles()
        resetBall()
    }
    
    private func setupScene() {
        backgroundColor = .black
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsWorld.gravity = .zero
    }
    
    private func setupBall() {
        ball = SKShapeNode(circleOfRadius: 10)
        ball.fillColor = .white
        ball.strokeColor = .white
        ball.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(ball)
    }
    
    private func setupPaddles() {
        // Player paddle (right side)
        playerPaddle = SKShapeNode(rectOf: CGSize(width: paddleWidth, height: paddleHeight), cornerRadius: 5)
        playerPaddle.fillColor = .white
        playerPaddle.strokeColor = .white
        playerPaddle.position = CGPoint(x: frame.maxX - 40, y: frame.midY)
        addChild(playerPaddle)
        
        // Computer paddle (left side)
        computerPaddle = SKShapeNode(rectOf: CGSize(width: paddleWidth, height: paddleHeight), cornerRadius: 5)
        computerPaddle.fillColor = .white
        computerPaddle.strokeColor = .white
        computerPaddle.position = CGPoint(x: frame.minX + 40, y: frame.midY)
        addChild(computerPaddle)
    }
    
    private func resetBall() {
        ball.position = CGPoint(x: frame.midX, y: frame.midY)
        
        // Random direction
        let randomAngle = CGFloat.random(in: -CGFloat.pi/4...CGFloat.pi/4)
        let speed: CGFloat = 400
        let direction: CGFloat = Bool.random() ? 1 : -1
        
        ballVelocity = CGVector(
            dx: cos(randomAngle) * speed * direction,
            dy: sin(randomAngle) * speed
        )
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard let gameState = gameState, gameState.isGameActive else { return }
        
        updateBallPosition()
        updateComputerAI()
        checkCollisions()
        checkScore()
    }
    
    private func updateBallPosition() {
        let deltaTime: CGFloat = 1.0 / 60.0
        ball.position.x += ballVelocity.dx * deltaTime
        ball.position.y += ballVelocity.dy * deltaTime
        
        // Bounce off top and bottom
        if ball.position.y <= frame.minY + 10 || ball.position.y >= frame.maxY - 10 {
            ballVelocity.dy *= -1
            ball.position.y = max(frame.minY + 10, min(frame.maxY - 10, ball.position.y))
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
                
                // Add angle based on where ball hits paddle
                let hitPosition = (ball.position.y - playerPaddle.position.y) / paddleHalfHeight
                ballVelocity.dy += hitPosition * 200
            }
        }
        
        // Computer paddle collision
        if ball.position.x - ballRadius <= computerPaddle.position.x + paddleHalfWidth &&
           ball.position.x + ballRadius >= computerPaddle.position.x - paddleHalfWidth &&
           ball.position.y + ballRadius >= computerPaddle.position.y - paddleHalfHeight &&
           ball.position.y - ballRadius <= computerPaddle.position.y + paddleHalfHeight {
            
            if ballVelocity.dx < 0 {
                ballVelocity.dx *= -1.05
                
                let hitPosition = (ball.position.y - computerPaddle.position.y) / paddleHalfHeight
                ballVelocity.dy += hitPosition * 200
            }
        }
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
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        
        // Continuously update paddle position for smooth keyboard movement
        if !keysPressed.isEmpty {
            updatePlayerPaddleForKeyboard()
        }
    }
#else
    override func update(_ currentTime: TimeInterval) {
        guard let gameState = gameState, gameState.isGameActive else { return }
        
        updateBallPosition()
        updateComputerAI()
        checkCollisions()
        checkScore()
        
        // Update touch position for iOS
        updatePlayerPaddlePosition()
    }
#endif
}
