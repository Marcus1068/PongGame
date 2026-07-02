// PongScene.swift
//
// Defines the SpriteKit scene that runs a live Pong match.
// PongScene owns the gameplay nodes, per-frame mutable state, replay data,
// active power-up timers, and audio hooks while syncing with GameState.

import SpriteKit
import AVFoundation
#if os(iOS)
import UIKit
#endif

/// Snapshot of one rendered gameplay frame.
/// The replay system stores these lightweight samples and replays them verbatim
/// to show the previous point without re-running live game logic.
struct SceneReplayFrame {
    let ballPosition: CGPoint
    let playerPaddleY: CGFloat
    let opponentPaddleY: CGFloat
}

/// Main SpriteKit scene for PingPong Retro.
/// SpriteKit calls `update(_:)` every frame, and this scene delegates that work
/// to focused setup, gameplay, input, replay, and effects extensions.
@MainActor
final class PongScene: SKScene {
    // MARK: - External State

    weak var gameState: GameState?

    // MARK: - Scene Nodes

    var ball: SKShapeNode!
    var playerPaddle: SKShapeNode!
    var opponentPaddle: SKShapeNode!
    var centerLineContainer = SKNode()
    var ballTrail: SKEmitterNode!
    var sceneBackground: SKShapeNode!
    var powerUpNode: SKShapeNode?
    var powerUpLabel: SKLabelNode?

    // MARK: - Ball & Match State

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

    // MARK: - Replay State

    var replayBuffer: [SceneReplayFrame] = []
    var lastPointReplay: [SceneReplayFrame] = []
    var replayIndex = 0
    var isReplayingLastPoint = false
    var replayReturnPhase: GamePhase = .playing
    var liveFrameBeforeReplay: SceneReplayFrame?

    // MARK: - Power-Up State

    var spawnedPowerUp: PowerUpType?
    var activePowerUpUntil: TimeInterval?
    var activePowerUpOwner: WinnerSide?
    var pendingCurveOwner: WinnerSide?
    var playerPaddleHeight: CGFloat
    var opponentPaddleHeight: CGFloat

    // MARK: - Geometry

    let basePaddleWidth: CGFloat
    let basePaddleHeight: CGFloat
    let ballRadius = GameConfig.defaultBallRadius

    // MARK: - Audio

    var blipEngine: AVAudioEngine?
    let blipPlayerNode = AVAudioPlayerNode()
    var playerBlipBuffer: AVAudioPCMBuffer?
    var opponentBlipBuffer: AVAudioPCMBuffer?
    var wallBounceBuffer: AVAudioPCMBuffer?

    // MARK: - Input State

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

    /// Builds the scene graph and applies the current settings the first time the
    /// SpriteKit view presents this scene.
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

    /// Rebuilds geometry that depends on the scene frame whenever the hosting
    /// window or device size changes.
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

    /// Main frame loop. It keeps settings in sync, advances gameplay while the
    /// match is live, and records frames for the replay system.
    override func update(_ currentTime: TimeInterval) {
        guard let gameState else { return }

        let deltaTime: TimeInterval
        if let lastUpdateTime {
            // Clamp unusually large frame gaps so a pause or hitch does not make
            // the ball jump across the court in a single update.
            deltaTime = min(max(currentTime - lastUpdateTime, 0), 1.0 / 20.0)
        } else {
            // Seed timing and replay state on the first callback; there is no
            // previous frame to simulate against yet.
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

    /// Starts playback of the recorded frames from the most recent point while
    /// preserving enough live state to resume the current match afterward.
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
