import Foundation
import CoreGraphics
import SwiftUI
import SpriteKit

enum GameMode: String, CaseIterable, Codable, Identifiable {
    case onePlayer
    case twoPlayers

    var id: String { rawValue }

    var title: String {
        switch self {
        case .onePlayer: String(localized: "1 Player")
        case .twoPlayers: String(localized: "2 Players")
        }
    }

    var subtitle: String {
        switch self {
        case .onePlayer: String(localized: "vs Computer")
        case .twoPlayers: String(localized: "Local Multiplayer")
        }
    }

    func displayName(for side: WinnerSide) -> String {
        switch (self, side) {
        case (.onePlayer, .playerOne): String(localized: "Player")
        case (.onePlayer, .playerTwo): String(localized: "Computer")
        case (.twoPlayers, .playerOne): String(localized: "Player 1")
        case (.twoPlayers, .playerTwo): String(localized: "Player 2")
        }
    }
}

enum Difficulty: String, CaseIterable, Codable, Identifiable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .easy: String(localized: "Easy")
        case .medium: String(localized: "Medium")
        case .hard: String(localized: "Hard")
        }
    }

    var localizedTitle: LocalizedStringKey {
        LocalizedStringKey(rawValue)
    }

    var trackingSpeed: CGFloat {
        switch self {
        case .easy: 220
        case .medium: 310
        case .hard: 430
        }
    }

    var reactionBias: CGFloat {
        switch self {
        case .easy: 0.78
        case .medium: 0.9
        case .hard: 1.02
        }
    }
}

enum AIStyle: String, CaseIterable, Codable, Identifiable {
    case balanced
    case defensive
    case aggressive
    case mirror

    var id: String { rawValue }

    var title: String {
        switch self {
        case .balanced: String(localized: "Balanced")
        case .defensive: String(localized: "Defensive")
        case .aggressive: String(localized: "Aggressive")
        case .mirror: String(localized: "Mirror")
        }
    }
}

enum MatchDuration: String, CaseIterable, Codable, Identifiable {
    case scoreOnly
    case oneMinute
    case threeMinutes
    case fiveMinutes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .scoreOnly: String(localized: "Score Only")
        case .oneMinute: String(localized: "1 Minute")
        case .threeMinutes: String(localized: "3 Minutes")
        case .fiveMinutes: String(localized: "5 Minutes")
        }
    }

    var seconds: TimeInterval? {
        switch self {
        case .scoreOnly: nil
        case .oneMinute: 60
        case .threeMinutes: 180
        case .fiveMinutes: 300
        }
    }
}

enum VisualTheme: String, CaseIterable, Codable, Identifiable {
    case synthwave
    case retroGreenCRT
    case amberMonitor
    case minimalMono

    var id: String { rawValue }

    var title: String {
        switch self {
        case .synthwave: String(localized: "Synthwave")
        case .retroGreenCRT: String(localized: "Retro Green CRT")
        case .amberMonitor: String(localized: "Amber Monitor")
        case .minimalMono: String(localized: "Minimal Mono")
        }
    }

    var detail: String {
        switch self {
        case .synthwave: String(localized: "Classic neon blues and magentas with bright arcade highlights.")
        case .retroGreenCRT: String(localized: "Phosphor greens, strong contrast, and a terminal-style glow.")
        case .amberMonitor: String(localized: "Warm amber tones inspired by vintage monochrome monitors.")
        case .minimalMono: String(localized: "Clean black-and-white visuals with glow and trails stripped back.")
        }
    }

    var previewGradientColors: [Color] {
        switch self {
        case .synthwave:
            [.cyan.opacity(0.35), .purple.opacity(0.3)]
        case .retroGreenCRT:
            [Color(red: 0.08, green: 0.35, blue: 0.18), Color(red: 0.32, green: 0.86, blue: 0.45).opacity(0.28)]
        case .amberMonitor:
            [Color(red: 0.44, green: 0.24, blue: 0.08), Color(red: 0.95, green: 0.68, blue: 0.28).opacity(0.28)]
        case .minimalMono:
            [.white.opacity(0.18), .black.opacity(0.22)]
        }
    }

    var playerColor: Color {
        switch self {
        case .synthwave: .cyan
        case .retroGreenCRT: Color(red: 0.45, green: 1.0, blue: 0.58)
        case .amberMonitor: Color(red: 1.0, green: 0.72, blue: 0.28)
        case .minimalMono: .white
        }
    }

    var opponentColor: Color {
        switch self {
        case .synthwave: .purple
        case .retroGreenCRT: Color(red: 0.78, green: 1.0, blue: 0.48)
        case .amberMonitor: Color(red: 1.0, green: 0.84, blue: 0.52)
        case .minimalMono: .white
        }
    }

    var sceneBackgroundColor: SKColor {
        switch self {
        case .synthwave:
            SKColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1)
        case .retroGreenCRT:
            SKColor(red: 0.03, green: 0.09, blue: 0.05, alpha: 1)
        case .amberMonitor:
            SKColor(red: 0.11, green: 0.07, blue: 0.02, alpha: 1)
        case .minimalMono:
            .black
        }
    }

    var scenePlayerColor: SKColor {
        switch self {
        case .synthwave: .cyan
        case .retroGreenCRT: SKColor(red: 0.45, green: 1.0, blue: 0.58, alpha: 1)
        case .amberMonitor: SKColor(red: 1.0, green: 0.72, blue: 0.28, alpha: 1)
        case .minimalMono: .white
        }
    }

    var sceneOpponentColor: SKColor {
        switch self {
        case .synthwave: .magenta
        case .retroGreenCRT: SKColor(red: 0.78, green: 1.0, blue: 0.48, alpha: 1)
        case .amberMonitor: SKColor(red: 1.0, green: 0.84, blue: 0.52, alpha: 1)
        case .minimalMono: .white
        }
    }

    var sceneBallStrokeColor: SKColor {
        switch self {
        case .synthwave: .cyan
        case .retroGreenCRT: SKColor(red: 0.74, green: 1.0, blue: 0.82, alpha: 1)
        case .amberMonitor: SKColor(red: 1.0, green: 0.86, blue: 0.58, alpha: 1)
        case .minimalMono: .white
        }
    }

    var sceneBallTrailColor: SKColor {
        switch self {
        case .synthwave: .cyan
        case .retroGreenCRT: SKColor(red: 0.45, green: 1.0, blue: 0.58, alpha: 1)
        case .amberMonitor: SKColor(red: 1.0, green: 0.74, blue: 0.32, alpha: 1)
        case .minimalMono: .white
        }
    }

    var sceneCenterLineColor: SKColor {
        switch self {
        case .synthwave, .minimalMono:
            .white
        case .retroGreenCRT:
            SKColor(red: 0.76, green: 1.0, blue: 0.76, alpha: 1)
        case .amberMonitor:
            SKColor(red: 1.0, green: 0.88, blue: 0.62, alpha: 1)
        }
    }

    var centerLineOpacity: CGFloat {
        switch self {
        case .minimalMono: 0.5
        case .retroGreenCRT, .amberMonitor: 0.38
        case .synthwave: 0.3
        }
    }

    var scenePowerUpColor: SKColor {
        switch self {
        case .synthwave: .orange
        case .retroGreenCRT: SKColor(red: 0.8, green: 1.0, blue: 0.52, alpha: 1)
        case .amberMonitor: SKColor(red: 1.0, green: 0.78, blue: 0.34, alpha: 1)
        case .minimalMono: .white
        }
    }

    var speedBoostTextColor: SKColor {
        switch self {
        case .minimalMono, .retroGreenCRT, .amberMonitor:
            .black
        case .synthwave:
            .white
        }
    }

    var speedBoostBackgroundColor: SKColor {
        switch self {
        case .synthwave:
            .yellow
        case .retroGreenCRT:
            SKColor(red: 0.76, green: 1.0, blue: 0.56, alpha: 1)
        case .amberMonitor:
            SKColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 1)
        case .minimalMono:
            .white
        }
    }

    var showsGlow: Bool {
        self != .minimalMono
    }

    var showsBallTrail: Bool {
        self != .minimalMono
    }
}

enum WinnerSide: String, Codable, Identifiable {
    case playerOne
    case playerTwo

    var id: String { rawValue }
}

enum GamePhase: Equatable {
    case loading
    case modeSelection
    case playing
    case paused
    case replaying
    case winner(WinnerSide)
}

enum PowerUpType: String, CaseIterable, Codable, Identifiable {
    case paddleExpand
    case slowMotion
    case curveShot

    var id: String { rawValue }

    var title: String {
        switch self {
        case .paddleExpand: String(localized: "Paddle Boost")
        case .slowMotion: String(localized: "Slow Ball")
        case .curveShot: String(localized: "Curve Shot")
        }
    }

    var symbolName: String {
        switch self {
        case .paddleExpand: "rectangle.expand.vertical"
        case .slowMotion: "tortoise.fill"
        case .curveShot: "arrow.trianglehead.2.clockwise.rotate.90"
        }
    }

    var detail: String {
        switch self {
        case .paddleExpand: String(localized: "Temporarily increases the collector's paddle height.")
        case .slowMotion: String(localized: "Temporarily slows the ball so rallies reset their pace.")
        case .curveShot: String(localized: "Adds extra spin to the next paddle deflection.")
        }
    }
}

enum AchievementID: String, CaseIterable, Codable, Identifiable {
    case firstVictory
    case rallyMaster
    case speedJunkie
    case tactician
    case marathon
    case collector

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstVictory: String(localized: "First Victory")
        case .rallyMaster: String(localized: "Rally Master")
        case .speedJunkie: String(localized: "Speed Junkie")
        case .tactician: String(localized: "Tactician")
        case .marathon: String(localized: "Marathon Match")
        case .collector: String(localized: "Collector")
        }
    }

    var detail: String {
        switch self {
        case .firstVictory: String(localized: "Win your first match.")
        case .rallyMaster: String(localized: "Reach a 12-hit rally.")
        case .speedJunkie: String(localized: "Trigger three speed boosts in one match.")
        case .tactician: String(localized: "Win with power-ups disabled.")
        case .marathon: String(localized: "Finish a timed match that reaches overtime.")
        case .collector: String(localized: "Collect all power-up types.")
        }
    }
}

struct LeaderboardEntry: Codable, Identifiable, Hashable {
    let id: UUID
    let date: Date
    let mode: GameMode
    let winner: WinnerSide
    let scoreLine: String
    let longestRally: Int
    let speedBoosts: Int

    init(id: UUID = UUID(), date: Date = .now, mode: GameMode, winner: WinnerSide, scoreLine: String, longestRally: Int, speedBoosts: Int) {
        self.id = id
        self.date = date
        self.mode = mode
        self.winner = winner
        self.scoreLine = scoreLine
        self.longestRally = longestRally
        self.speedBoosts = speedBoosts
    }
}

struct MatchStatistics: Codable, Hashable {
    var longestRally: Int = 0
    var totalHits: Int = 0
    var speedBoostsTriggered: Int = 0
    var powerUpsCollected: Int = 0
    var lastPowerUpsCollected: Set<PowerUpType> = []
    var replayCount: Int = 0
    var matchStartDate: Date = .now
    var matchDurationPlayed: TimeInterval = 0
    var reachedOvertime: Bool = false
}

struct LifetimeStatistics: Codable, Hashable {
    var gamesPlayed: Int = 0
    var wins: Int = 0
    var losses: Int = 0
    var longestRally: Int = 0
    var totalHits: Int = 0
    var totalPowerUpsCollected: Int = 0
    var totalReplaysViewed: Int = 0
    var favoriteMode: GameMode = .onePlayer
}

struct GamePreferences: Codable, Hashable {
    var visualTheme: VisualTheme = .synthwave
    var baseBallSpeed: Double = 1.0
    var difficulty: Difficulty = .medium
    var aiStyle: AIStyle = .balanced
    var maxScore: Int = 5
    var matchDuration: MatchDuration = .scoreOnly
    var speedBoostEnabled: Bool = true
    var soundEnabled: Bool = true
    var soundVolume: Double = 0.8
    var hapticsEnabled: Bool = true
    var enabledPowerUps: Set<PowerUpType> = Set(PowerUpType.allCases)

    init(
        visualTheme: VisualTheme = .synthwave,
        baseBallSpeed: Double = 1.0,
        difficulty: Difficulty = .medium,
        aiStyle: AIStyle = .balanced,
        maxScore: Int = 5,
        matchDuration: MatchDuration = .scoreOnly,
        speedBoostEnabled: Bool = true,
        soundEnabled: Bool = true,
        soundVolume: Double = 0.8,
        hapticsEnabled: Bool = true,
        enabledPowerUps: Set<PowerUpType> = Set(PowerUpType.allCases)
    ) {
        self.visualTheme = visualTheme
        self.baseBallSpeed = baseBallSpeed
        self.difficulty = difficulty
        self.aiStyle = aiStyle
        self.maxScore = maxScore
        self.matchDuration = matchDuration
        self.speedBoostEnabled = speedBoostEnabled
        self.soundEnabled = soundEnabled
        self.soundVolume = soundVolume
        self.hapticsEnabled = hapticsEnabled
        self.enabledPowerUps = enabledPowerUps
    }

    private enum CodingKeys: String, CodingKey {
        case visualTheme
        case isBlackAndWhite
        case baseBallSpeed
        case difficulty
        case aiStyle
        case maxScore
        case matchDuration
        case speedBoostEnabled
        case soundEnabled
        case soundVolume
        case hapticsEnabled
        case enabledPowerUps
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let legacyMonoMode = try container.decodeIfPresent(Bool.self, forKey: .isBlackAndWhite) ?? false

        visualTheme = try container.decodeIfPresent(VisualTheme.self, forKey: .visualTheme) ?? (legacyMonoMode ? .minimalMono : .synthwave)
        baseBallSpeed = try container.decodeIfPresent(Double.self, forKey: .baseBallSpeed) ?? 1.0
        difficulty = try container.decodeIfPresent(Difficulty.self, forKey: .difficulty) ?? .medium
        aiStyle = try container.decodeIfPresent(AIStyle.self, forKey: .aiStyle) ?? .balanced
        maxScore = try container.decodeIfPresent(Int.self, forKey: .maxScore) ?? 5
        matchDuration = try container.decodeIfPresent(MatchDuration.self, forKey: .matchDuration) ?? .scoreOnly
        speedBoostEnabled = try container.decodeIfPresent(Bool.self, forKey: .speedBoostEnabled) ?? true
        soundEnabled = try container.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? true
        soundVolume = try container.decodeIfPresent(Double.self, forKey: .soundVolume) ?? 0.8
        hapticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? true
        enabledPowerUps = try container.decodeIfPresent(Set<PowerUpType>.self, forKey: .enabledPowerUps) ?? Set(PowerUpType.allCases)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(visualTheme, forKey: .visualTheme)
        try container.encode(baseBallSpeed, forKey: .baseBallSpeed)
        try container.encode(difficulty, forKey: .difficulty)
        try container.encode(aiStyle, forKey: .aiStyle)
        try container.encode(maxScore, forKey: .maxScore)
        try container.encode(matchDuration, forKey: .matchDuration)
        try container.encode(speedBoostEnabled, forKey: .speedBoostEnabled)
        try container.encode(soundEnabled, forKey: .soundEnabled)
        try container.encode(soundVolume, forKey: .soundVolume)
        try container.encode(hapticsEnabled, forKey: .hapticsEnabled)
        try container.encode(enabledPowerUps, forKey: .enabledPowerUps)
    }
}

struct PlayerProgress: Codable, Hashable {
    var lifetimeStats: LifetimeStatistics = LifetimeStatistics()
    var leaderboard: [LeaderboardEntry] = []
    var achievements: Set<AchievementID> = []
}

enum GameConfig {
    static let defaultBallRadius: CGFloat = 10
    static let baseBallSpeed: CGFloat = 420
    static let maxRallySpeedMultiplier: CGFloat = 2.35
    static let speedBoostStep: CGFloat = 1.10
    static let speedBoostEveryHits = 3
    static let replayFrameLimit = 480
    static let replayPlaybackFramesPerSecond: Double = 60
    static let paddleCollisionCooldown: TimeInterval = 0.08
    static let powerUpSpawnEveryHits = 6
    static let powerUpDuration: TimeInterval = 6
    static let expandedPaddleMultiplier: CGFloat = 1.35
    static let slowMotionMultiplier: CGFloat = 0.82
    static let curveShotStrength: CGFloat = 0.22
    static let leaderboardLimit = 10
    static let defaultPaddleEdgeInset: CGFloat = 40
    static let compactPhonePaddleEdgeInset: CGFloat = 56
    static let phoneSafeAreaPaddlePadding: CGFloat = 16
}
