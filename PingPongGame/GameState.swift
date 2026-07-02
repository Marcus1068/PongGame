// GameState.swift
//
// Main observable state container for PingPong Retro.
// This file centralizes match flow, player-facing settings, saved progress, and
// persistence to local storage plus iCloud key-value sync.

import Foundation
import Observation

/// Single source of truth for gameplay state, preferences, match stats, and persisted progress.
@MainActor
@Observable
final class GameState {
    var playerScore: Int = 0
    var opponentScore: Int = 0
    var gameMode: GameMode = .onePlayer
    var gamePhase: GamePhase = .loading
    var winningSide: WinnerSide?

    var visualTheme: VisualTheme {
        didSet { persistPreferences() }
    }

    var ballSpeed: Double {
        didSet { persistPreferences() }
    }

    var difficulty: Difficulty {
        didSet { persistPreferences() }
    }

    var aiStyle: AIStyle {
        didSet { persistPreferences() }
    }

    var maxScore: Int {
        didSet { persistPreferences() }
    }

    var matchDuration: MatchDuration {
        didSet {
            persistPreferences()
            if !hasStarted {
                remainingMatchTime = matchDuration.seconds
            }
        }
    }

    var isSpeedBoostEnabled: Bool {
        didSet { persistPreferences() }
    }

    var isSoundEnabled: Bool {
        didSet { persistPreferences() }
    }

    var soundVolume: Double {
        didSet { persistPreferences() }
    }

    var isHapticsEnabled: Bool {
        didSet { persistPreferences() }
    }

    var enabledPowerUps: Set<PowerUpType> {
        didSet { persistPreferences() }
    }

    var currentMatchStats = MatchStatistics()
    var lifetimeStats: LifetimeStatistics
    var leaderboard: [LeaderboardEntry]
    var achievements: Set<AchievementID>
    var remainingMatchTime: TimeInterval?
    var canReplayLastPoint = false
    var activePowerUp: PowerUpType?
    var powerUpStatusText: String?
    var latestHighlightText: String?

    @ObservationIgnored private let preferencesKey = "PingPongRetro.preferences"
    @ObservationIgnored private let progressKey = "PingPongRetro.progress"
    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private var preferencesSaveTask: Task<Void, Never>?

    /// Loads saved preferences and progress, then seeds the initial menu state.
    init() {
        // Prefer the current Codable preferences payload when available, but keep
        // supporting the older standalone `endScore` value as a migration fallback.
        let preferences = Self.load(GamePreferences.self, key: "PingPongRetro.preferences") ?? GamePreferences(
            maxScore: UserDefaults.standard.object(forKey: "endScore") as? Int ?? 5
        )
        let progress = Self.load(PlayerProgress.self, key: "PingPongRetro.progress") ?? PlayerProgress()

        visualTheme = preferences.visualTheme
        ballSpeed = preferences.baseBallSpeed
        difficulty = preferences.difficulty
        aiStyle = preferences.aiStyle
        maxScore = preferences.maxScore
        matchDuration = preferences.matchDuration
        isSpeedBoostEnabled = preferences.speedBoostEnabled
        isSoundEnabled = preferences.soundEnabled
        soundVolume = preferences.soundVolume
        isHapticsEnabled = preferences.hapticsEnabled
        enabledPowerUps = preferences.enabledPowerUps
        lifetimeStats = progress.lifetimeStats
        leaderboard = progress.leaderboard
        achievements = progress.achievements
        remainingMatchTime = preferences.matchDuration.seconds
    }

    var isPaused: Bool {
        gamePhase == .paused
    }

    /// Convenience flag for code that still needs a simple mono-vs-color theme check.
    var isBlackAndWhite: Bool {
        visualTheme == .minimalMono
    }

    /// Indicates whether the app has moved beyond loading and mode selection into a match flow.
    var hasStarted: Bool {
        switch gamePhase {
        case .loading, .modeSelection:
            false
        default:
            true
        }
    }

    /// True while a match exists in a state that can be played, paused, or replayed.
    var isGameActive: Bool {
        switch gamePhase {
        case .playing, .paused, .replaying:
            true
        case .loading, .modeSelection, .winner:
            false
        }
    }

    var opponentDisplayName: String {
        gameMode.displayName(for: .playerTwo)
    }

    var playerDisplayName: String {
        gameMode.displayName(for: .playerOne)
    }

    /// Localized winner label derived from the active mode and winning side.
    var winnerText: String? {
        guard let winningSide else { return nil }
        return gameMode.displayName(for: winningSide)
    }

    /// Formats the match clock and switches to `OT` once a tied timed match enters sudden death.
    var formattedTimer: String? {
        guard let remainingMatchTime else { return nil }
        if remainingMatchTime <= 0, currentMatchStats.reachedOvertime {
            return "OT"
        }

        let totalSeconds = max(Int(remainingMatchTime.rounded(.down)), 0)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Advances from the loading screen to the mode-selection menu.
    func completeLoading() {
        gamePhase = .modeSelection
    }

    /// Resets per-match state and starts a fresh game in the selected mode.
    func startMatch(mode: GameMode) {
        gameMode = mode
        playerScore = 0
        opponentScore = 0
        winningSide = nil
        activePowerUp = nil
        powerUpStatusText = nil
        latestHighlightText = nil
        canReplayLastPoint = false
        currentMatchStats = MatchStatistics(matchStartDate: .now)
        remainingMatchTime = matchDuration.seconds
        gamePhase = .playing
    }

    /// Clears transient match state and returns to the mode-selection menu.
    func resetToMenu() {
        playerScore = 0
        opponentScore = 0
        winningSide = nil
        activePowerUp = nil
        powerUpStatusText = nil
        latestHighlightText = nil
        canReplayLastPoint = false
        remainingMatchTime = matchDuration.seconds
        gamePhase = .modeSelection
    }

    /// Pauses an in-progress match without affecting other phases.
    func pauseGame() {
        guard case .playing = gamePhase else { return }
        gamePhase = .paused
    }

    /// Resumes a match that was previously paused.
    func resumeGame() {
        guard case .paused = gamePhase else { return }
        gamePhase = .playing
    }

    /// Toggles between playing and paused when a live match is active.
    func togglePause() {
        switch gamePhase {
        case .playing:
            gamePhase = .paused
        case .paused:
            gamePhase = .playing
        default:
            break
        }
    }

    /// Enters replay mode for the most recent point and records the replay view in stats.
    func beginReplay() {
        guard canReplayLastPoint else { return }
        gamePhase = .replaying
        currentMatchStats.replayCount += 1
        lifetimeStats.totalReplaysViewed += 1
        persistProgress()
    }

    /// Leaves replay mode, restoring either paused or active gameplay.
    func endReplay(returningToPaused paused: Bool) {
        gamePhase = paused ? .paused : .playing
    }

    /// Applies a scored point, including sudden-death overtime and normal win checks.
    func registerPoint(for side: WinnerSide) {
        switch side {
        case .playerOne:
            playerScore += 1
        case .playerTwo:
            opponentScore += 1
        }

        // Once overtime starts, the clock has already expired; the very next point
        // ends the match immediately instead of checking the normal score target.
        if currentMatchStats.reachedOvertime {
            completeMatch(winner: side)
            return
        }

        if playerScore >= maxScore {
            completeMatch(winner: .playerOne)
        } else if opponentScore >= maxScore {
            completeMatch(winner: .playerTwo)
        }
    }

    func registerHit() {
        currentMatchStats.totalHits += 1
    }

    func registerRallyLength(_ rally: Int) {
        currentMatchStats.longestRally = max(currentMatchStats.longestRally, rally)
    }

    func registerSpeedBoost() {
        currentMatchStats.speedBoostsTriggered += 1
    }

    /// Records a collected power-up and updates stats/achievements from player one's perspective.
    func registerPowerUpCollected(_ powerUp: PowerUpType, collectedBy owner: WinnerSide) {
        latestHighlightText = String(localized: "Collected \(powerUp.title)")
        // Only credit the tracked player's (playerOne's) stats/achievements. Lifetime
        // stats and achievements are always from playerOne's perspective (see
        // finalizeProgress), so a power-up grabbed by the AI/Player 2 must not count.
        guard owner == .playerOne else { return }
        currentMatchStats.powerUpsCollected += 1
        currentMatchStats.lastPowerUpsCollected.insert(powerUp)
        lifetimeStats.totalPowerUpsCollected += 1
        if currentMatchStats.lastPowerUpsCollected.count == PowerUpType.allCases.count {
            unlock(.collector)
        }
        persistProgress()
    }

    func storeReplayAvailability(_ available: Bool) {
        canReplayLastPoint = available
    }

    /// Decrements the match clock and decides whether time expiration causes overtime or a winner.
    func updateRemainingMatchTime(elapsed deltaTime: TimeInterval) {
        guard let remainingMatchTime, case .playing = gamePhase else { return }
        if currentMatchStats.reachedOvertime { return }

        let updated = max(remainingMatchTime - deltaTime, 0)
        self.remainingMatchTime = updated

        guard updated == 0 else { return }

        // A tied timed match becomes sudden death; otherwise the leader wins as
        // soon as regulation time expires.
        if playerScore == opponentScore {
            currentMatchStats.reachedOvertime = true
            latestHighlightText = String(localized: "Overtime: next point wins")
        } else if playerScore > opponentScore {
            completeMatch(winner: .playerOne)
        } else {
            completeMatch(winner: .playerTwo)
        }
    }

    func setActivePowerUp(_ powerUp: PowerUpType?) {
        activePowerUp = powerUp
        powerUpStatusText = powerUp?.title
    }

    func clearTransientStatus() {
        latestHighlightText = nil
    }

    /// Moves the state machine into the winner phase and triggers persistence for the finished match.
    private func completeMatch(winner: WinnerSide) {
        winningSide = winner
        gamePhase = .winner(winner)
        latestHighlightText = String(localized: "\(gameMode.displayName(for: winner)) Wins!")
        finalizeProgress(winner: winner)
    }

    /// Folds the completed match into lifetime stats, achievements, and the local leaderboard.
    private func finalizeProgress(winner: WinnerSide) {
        currentMatchStats.matchDurationPlayed = Date().timeIntervalSince(currentMatchStats.matchStartDate)
        lifetimeStats.gamesPlayed += 1
        lifetimeStats.totalHits += currentMatchStats.totalHits
        lifetimeStats.longestRally = max(lifetimeStats.longestRally, currentMatchStats.longestRally)
        lifetimeStats.favoriteMode = gameMode

        // Lifetime progress is tracked from player one's perspective, so only that
        // side can earn wins and the related victory-based achievements.
        if winner == .playerOne {
            lifetimeStats.wins += 1
            unlock(.firstVictory)
            if !isSpeedBoostEnabled && enabledPowerUps.isEmpty {
                unlock(.tactician)
            }
        } else {
            lifetimeStats.losses += 1
        }

        if currentMatchStats.longestRally >= 12 {
            unlock(.rallyMaster)
        }
        if currentMatchStats.speedBoostsTriggered >= 3 {
            unlock(.speedJunkie)
        }
        if currentMatchStats.reachedOvertime {
            unlock(.marathon)
        }

        let entry = LeaderboardEntry(
            mode: gameMode,
            winner: winner,
            scoreLine: "\(playerScore)-\(opponentScore)",
            longestRally: currentMatchStats.longestRally,
            speedBoosts: currentMatchStats.speedBoostsTriggered
        )
        leaderboard.insert(entry, at: 0)
        // Keep only the most recent/highest-priority local history entries.
        leaderboard = Array(leaderboard.prefix(GameConfig.leaderboardLimit))
        persistProgress()
    }

    private func unlock(_ achievement: AchievementID) {
        achievements.insert(achievement)
    }

    /// Persists user-adjustable settings, debouncing rapid slider updates into a single write.
    private func persistPreferences() {
        // Slider-backed properties (ballSpeed, soundVolume) can fire this on every
        // drag tick. Debounce so we only hit disk/iCloud once the value settles,
        // instead of encoding + writing on every intermediate frame.
        let preferences = GamePreferences(
            visualTheme: visualTheme,
            baseBallSpeed: ballSpeed,
            difficulty: difficulty,
            aiStyle: aiStyle,
            maxScore: maxScore,
            matchDuration: matchDuration,
            speedBoostEnabled: isSpeedBoostEnabled,
            soundEnabled: isSoundEnabled,
            soundVolume: soundVolume,
            hapticsEnabled: isHapticsEnabled,
            enabledPowerUps: enabledPowerUps
        )
        let scoreToPersist = maxScore

        preferencesSaveTask?.cancel()
        preferencesSaveTask = Task { [preferencesKey, defaults] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            Self.save(preferences, key: preferencesKey)
            defaults.set(scoreToPersist, forKey: "endScore")
        }
    }

    /// Persists long-lived player progress such as stats, leaderboard entries, and achievements.
    private func persistProgress() {
        let progress = PlayerProgress(
            lifetimeStats: lifetimeStats,
            leaderboard: leaderboard,
            achievements: achievements
        )
        Self.save(progress, key: progressKey)
    }

    /// Loads a Codable value from iCloud key-value storage, falling back to local defaults when needed.
    private static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        let defaults = UserDefaults.standard
        let cloudStore = NSUbiquitousKeyValueStore.default
        // Prefer the cloud copy when one exists so settings/progress can roam
        // across devices, while still working offline from local storage.
        let data = cloudStore.data(forKey: key) ?? defaults.data(forKey: key)
        guard let data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    /// Encodes and writes a Codable value to both local defaults and iCloud key-value storage.
    private static func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
        // NSUbiquitousKeyValueStore syncs to iCloud on its own schedule. Calling
        // `synchronize()` here is redundant (Apple's docs call it unnecessary) and
        // forces an expensive synchronous flush on the calling thread/actor.
        NSUbiquitousKeyValueStore.default.set(data, forKey: key)
    }
}
