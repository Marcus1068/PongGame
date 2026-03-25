import Foundation
import CoreGraphics
import SwiftUI

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
    var isBlackAndWhite: Bool = false
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
