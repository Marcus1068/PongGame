import SpriteKit
import AVFoundation
#if os(iOS)
import UIKit
#endif

struct SceneReplayFrame {
    let ballPosition: CGPoint
    let playerPaddleY: CGFloat
    let opponentPaddleY: CGFloat
}

@MainActor
final class PongScene: SKScene {
    weak var gameState: GameState?

    var ball: SKShapeNode!
    var playerPaddle: SKShapeNode!
    var opponentPaddle: SKShapeNode!
    var centerLineContainer = SKNode()
    var ballTrail: SKEmitterNode!
    var sceneBackground: SKShapeNode!
    var powerUpNode: SKShapeNode?
    var powerUpLabel: SKLabelNode?

    var ballVelocity = CGVector(dx: 0, dy: 0)
    var currentSpeedMultiplier: CGFloat = 1
    var lastBallSpeedSetting: Double = 1
    var rallyHitCount = 0
    var lastHitter: WinnerSide?
    var lastCollisionTime: TimeInterval = 0
    var lastUpdateTime: TimeInterval?
    var lastVisualTheme: VisualTheme?
    var lastSoundEnabled: Bool?
    var lastSoundVolume: Double?
    var lastObservedGamePhase: GamePhase?

    var replayBuffer: [SceneReplayFrame] = []
    var lastPointReplay: [SceneReplayFrame] = []
    var replayIndex = 0
    var isReplayingLastPoint = false
    var replayReturnPhase: GamePhase = .playing
    var liveFrameBeforeReplay: SceneReplayFrame?

    var spawnedPowerUp: PowerUpType?
    var activePowerUpUntil: TimeInterval?
    var activePowerUpOwner: WinnerSide?
    var pendingCurveOwner: WinnerSide?
    var playerPaddleHeight: CGFloat
    var opponentPaddleHeight: CGFloat

    let basePaddleWidth: CGFloat
    let basePaddleHeight: CGFloat
    let ballRadius = GameConfig.defaultBallRadius

    var blipEngine: AVAudioEngine?
    let blipPlayerNode = AVAudioPlayerNode()
    var playerBlipBuffer: AVAudioPCMBuffer?
    var opponentBlipBuffer: AVAudioPCMBuffer?
    var wallBounceBuffer: AVAudioPCMBuffer?

    var keysPressed = Set<String>()

    #if os(iOS)
    var playerTouch: UITouch?
    var opponentTouch: UITouch?
    #endif

    init(gameState: GameState) {
        self.gameState = gameState
        #if os(iOS)
        self.basePaddleWidth = UIDevice.current.userInterfaceIdiom == .phone ? 26 : 20
        self.basePaddleHeight = UIDevice.current.userInterfaceIdiom == .pad ? 130 : 100
        #else
        self.basePaddleWidth = 20
        self.basePaddleHeight = 100
        #endif
        self.playerPaddleHeight = self.basePaddleHeight
        self.opponentPaddleHeight = self.basePaddleHeight
        super.init(size: .zero)
    }

    required init?(coder aDecoder: NSCoder) {
        nil
    }

    override func willMove(from view: SKView) {
        blipPlayerNode.stop()
        blipEngine?.stop()
    }

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        setupScene()
        setupCenterLine()
        setupBall()
        setupPaddles()
        setupAudio()
        resetBall()
        applyVisualTheme(theme: gameState?.visualTheme ?? .synthwave)
        lastBallSpeedSetting = gameState?.ballSpeed ?? 1.0

        #if os(macOS)
        view.window?.makeFirstResponder(view)
        #endif
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard sceneBackground != nil else { return }
        updateBackgroundPath()
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)

        centerLineContainer.removeAllChildren()
        setupCenterLine()

        playerPaddle.position.x = frame.maxX - paddleEdgeInset
        opponentPaddle.position.x = frame.minX + paddleEdgeInset
        clampPaddlesToBounds()
        clampBallToBounds()
        layoutPowerUpIfNeeded()
    }

    override func update(_ currentTime: TimeInterval) {
        guard let gameState else { return }

        let deltaTime: TimeInterval
        if let lastUpdateTime {
            deltaTime = min(max(currentTime - lastUpdateTime, 0), 1.0 / 20.0)
        } else {
            lastUpdateTime = currentTime
            captureReplayFrame()
            return
        }
        lastUpdateTime = currentTime

        applyLiveSettingsIfNeeded()
        applyVisualThemeIfNeeded()
        handlePhaseTransitionIfNeeded()

        if isReplayingLastPoint {
            updateReplayFrame()
            return
        }

        ballTrail.isPaused = gameState.gamePhase != .playing

        guard case .playing = gameState.gamePhase else {
            return
        }

        gameState.updateRemainingMatchTime(elapsed: deltaTime)
        guard case .playing = gameState.gamePhase else { return }

        updateActivePowerUpState(currentTime: currentTime)
        updateBallPosition(deltaTime: CGFloat(deltaTime))

        if gameState.gameMode == .twoPlayers {
            #if os(macOS)
            updateOpponentPaddleForKeyboard(deltaTime: CGFloat(deltaTime))
            #endif
        } else {
            updateComputerAI(deltaTime: CGFloat(deltaTime))
        }

        #if os(macOS)
        updatePlayerPaddleForKeyboard(deltaTime: CGFloat(deltaTime))
        #endif

        checkPowerUpCollection(currentTime: currentTime)
        checkCollisions(currentTime: currentTime)
        checkScore()
        captureReplayFrame()
    }

    func startLastPointReplay() {
        guard !isReplayingLastPoint, !lastPointReplay.isEmpty, let gameState else { return }
        replayReturnPhase = gameState.gamePhase
        liveFrameBeforeReplay = SceneReplayFrame(
            ballPosition: ball.position,
            playerPaddleY: playerPaddle.position.y,
            opponentPaddleY: opponentPaddle.position.y
        )
        isReplayingLastPoint = true
        replayIndex = 0
        gameState.beginReplay()
        gameState.latestHighlightText = String(localized: "Replaying last point")
        ballTrail.isPaused = true
    }
}
