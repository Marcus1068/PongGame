//
//  GameStateTests.swift
//  PingPongRetroTests
//
//  Unit tests for match flow, scoring, overtime, statistics, achievements,
//  and persistence in `GameState`.
//

import Foundation
import Testing
@testable import PingPongRetro

@MainActor
struct GameStateTests {
    // MARK: - Helpers

    /// Creates a state backed by an isolated `UserDefaults` suite and no iCloud sync,
    /// so tests never touch the developer's real settings or progress.
    private func makeState(suite: String = UUID().uuidString) -> (state: GameState, defaults: UserDefaults) {
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return (GameState(defaults: defaults, syncsToCloud: false), defaults)
    }

    private func makeMatch(
        mode: GameMode = .onePlayer,
        maxScore: Int = 3,
        duration: MatchDuration = .scoreOnly
    ) -> GameState {
        let (state, _) = makeState()
        state.maxScore = maxScore
        state.matchDuration = duration
        state.startMatch(mode: mode)
        return state
    }

    // MARK: - Match flow

    @Test func startsInLoadingAndMovesToModeSelection() {
        let (state, _) = makeState()
        #expect(state.gamePhase == .loading)
        #expect(!state.hasStarted)

        state.completeLoading()
        #expect(state.gamePhase == .modeSelection)
        #expect(!state.hasStarted)
    }

    @Test func startMatchResetsTransientState() {
        let state = makeMatch()
        state.registerPoint(for: .playerOne)
        state.registerHit()
        state.setActivePowerUp(.slowMotion)

        state.startMatch(mode: .twoPlayers)

        #expect(state.gameMode == .twoPlayers)
        #expect(state.playerScore == 0)
        #expect(state.opponentScore == 0)
        #expect(state.winningSide == nil)
        #expect(state.activePowerUp == nil)
        #expect(state.currentMatchStats.totalHits == 0)
        #expect(state.gamePhase == .playing)
        #expect(state.isGameActive)
    }

    @Test func resetToMenuClearsMatchAndReturnsToModeSelection() {
        let state = makeMatch()
        state.registerPoint(for: .playerTwo)

        state.resetToMenu()

        #expect(state.gamePhase == .modeSelection)
        #expect(state.playerScore == 0)
        #expect(state.opponentScore == 0)
        #expect(!state.canReplayLastPoint)
    }

    @Test func pauseAndResumeOnlyAffectTheRightPhases() {
        let state = makeMatch()

        state.pauseGame()
        #expect(state.isPaused)
        state.pauseGame()
        #expect(state.isPaused)

        state.resumeGame()
        #expect(state.gamePhase == .playing)
        state.resumeGame()
        #expect(state.gamePhase == .playing)

        state.togglePause()
        #expect(state.isPaused)
        state.togglePause()
        #expect(state.gamePhase == .playing)
    }

    @Test func pauseIsIgnoredOutsideActivePlay() {
        let (state, _) = makeState()
        state.completeLoading()

        state.pauseGame()
        state.togglePause()

        #expect(state.gamePhase == .modeSelection)
    }

    // MARK: - Scoring

    @Test func pointsAccumulateWithoutEndingTheMatchBelowTarget() {
        let state = makeMatch(maxScore: 3)
        state.registerPoint(for: .playerOne)
        state.registerPoint(for: .playerTwo)
        state.registerPoint(for: .playerOne)

        #expect(state.playerScore == 2)
        #expect(state.opponentScore == 1)
        #expect(state.gamePhase == .playing)
    }

    @Test func playerOneWinsAtTargetScore() {
        let state = makeMatch(maxScore: 2)
        state.registerPoint(for: .playerOne)
        state.registerPoint(for: .playerOne)

        #expect(state.gamePhase == .winner(.playerOne))
        #expect(state.winningSide == .playerOne)
        #expect(state.winnerText == GameMode.onePlayer.displayName(for: .playerOne))
        #expect(!state.isGameActive)
    }

    @Test func playerTwoWinsAtTargetScore() {
        let state = makeMatch(mode: .twoPlayers, maxScore: 2)
        state.registerPoint(for: .playerTwo)
        state.registerPoint(for: .playerTwo)

        #expect(state.gamePhase == .winner(.playerTwo))
        #expect(state.winnerText == GameMode.twoPlayers.displayName(for: .playerTwo))
    }

    // MARK: - Timer and overtime

    @Test func timerFormatsMinutesAndSeconds() {
        let state = makeMatch(duration: .oneMinute)
        #expect(state.formattedTimer == "1:00")

        state.updateRemainingMatchTime(elapsed: 14.5)
        #expect(state.formattedTimer == "0:45")
    }

    @Test func scoreOnlyMatchesHaveNoTimer() {
        let state = makeMatch(duration: .scoreOnly)
        #expect(state.remainingMatchTime == nil)
        #expect(state.formattedTimer == nil)
    }

    @Test func timerDoesNotAdvanceWhilePaused() {
        let state = makeMatch(duration: .oneMinute)
        state.pauseGame()

        state.updateRemainingMatchTime(elapsed: 10)

        #expect(state.remainingMatchTime == 60)
    }

    @Test func expiredTimeAwardsTheLeader() {
        let state = makeMatch(maxScore: 10, duration: .oneMinute)
        state.registerPoint(for: .playerTwo)

        state.updateRemainingMatchTime(elapsed: 60)

        #expect(state.gamePhase == .winner(.playerTwo))
    }

    @Test func expiredTimeWhileTiedStartsSuddenDeath() {
        let state = makeMatch(maxScore: 10, duration: .oneMinute)
        state.registerPoint(for: .playerOne)
        state.registerPoint(for: .playerTwo)

        state.updateRemainingMatchTime(elapsed: 60)

        #expect(state.gamePhase == .playing)
        #expect(state.currentMatchStats.reachedOvertime)
        #expect(state.formattedTimer == "OT")
    }

    @Test func nextPointEndsMatchInOvertime() {
        let state = makeMatch(maxScore: 10, duration: .oneMinute)
        state.updateRemainingMatchTime(elapsed: 60)
        #expect(state.currentMatchStats.reachedOvertime)

        state.registerPoint(for: .playerTwo)

        #expect(state.gamePhase == .winner(.playerTwo))
    }

    @Test func playTimeAccumulatesOnlyWhilePlaying() {
        let state = makeMatch()
        state.registerPlayTime(1.5)
        state.pauseGame()
        state.registerPlayTime(30)
        state.resumeGame()
        state.registerPlayTime(0.5)

        #expect(state.currentMatchStats.matchDurationPlayed == 2)
    }

    // MARK: - Replay

    @Test func replayRequiresAvailability() {
        let state = makeMatch()

        state.beginReplay()
        #expect(state.gamePhase == .playing)

        state.storeReplayAvailability(true)
        state.beginReplay()
        #expect(state.gamePhase == .replaying)
        #expect(state.currentMatchStats.replayCount == 1)
        #expect(state.lifetimeStats.totalReplaysViewed == 1)
    }

    @Test func endReplayRestoresRequestedPhase() {
        let state = makeMatch()
        state.storeReplayAvailability(true)
        state.beginReplay()

        state.endReplay(returningToPaused: true)
        #expect(state.isPaused)

        state.beginReplay()
        state.endReplay(returningToPaused: false)
        #expect(state.gamePhase == .playing)
    }

    // MARK: - Match statistics

    @Test func longestRallyKeepsTheMaximum() {
        let state = makeMatch()
        state.registerRallyLength(4)
        state.registerRallyLength(9)
        state.registerRallyLength(6)

        #expect(state.currentMatchStats.longestRally == 9)
    }

    @Test func hitsAndSpeedBoostsAreCounted() {
        let state = makeMatch()
        state.registerHit()
        state.registerHit()
        state.registerSpeedBoost()

        #expect(state.currentMatchStats.totalHits == 2)
        #expect(state.currentMatchStats.speedBoostsTriggered == 1)
    }

    @Test func onlyPlayerOnePowerUpPickupsAreCredited() {
        let state = makeMatch()

        state.registerPowerUpCollected(.slowMotion, collectedBy: .playerTwo)
        #expect(state.currentMatchStats.powerUpsCollected == 0)
        #expect(state.lifetimeStats.totalPowerUpsCollected == 0)

        state.registerPowerUpCollected(.slowMotion, collectedBy: .playerOne)
        #expect(state.currentMatchStats.powerUpsCollected == 1)
        #expect(state.lifetimeStats.totalPowerUpsCollected == 1)
    }

    // MARK: - Lifetime stats and achievements

    @Test func winningAgainstTheComputerRecordsWinAndAchievement() {
        let state = makeMatch(maxScore: 1)
        state.registerPoint(for: .playerOne)

        #expect(state.lifetimeStats.gamesPlayed == 1)
        #expect(state.lifetimeStats.wins == 1)
        #expect(state.lifetimeStats.losses == 0)
        #expect(state.achievements.contains(.firstVictory))
    }

    @Test func losingAgainstTheComputerRecordsLoss() {
        let state = makeMatch(maxScore: 1)
        state.registerPoint(for: .playerTwo)

        #expect(state.lifetimeStats.wins == 0)
        #expect(state.lifetimeStats.losses == 1)
        #expect(!state.achievements.contains(.firstVictory))
    }

    @Test func localMultiplayerDoesNotCountWinsLossesOrVictoryAchievements() {
        let state = makeMatch(mode: .twoPlayers, maxScore: 1)
        state.registerPoint(for: .playerOne)
        state.startMatch(mode: .twoPlayers)
        state.registerPoint(for: .playerTwo)

        #expect(state.lifetimeStats.gamesPlayed == 2)
        #expect(state.lifetimeStats.wins == 0)
        #expect(state.lifetimeStats.losses == 0)
        #expect(!state.achievements.contains(.firstVictory))
        #expect(!state.achievements.contains(.tactician))
    }

    @Test func tacticianRequiresNoBoostsAndNoPowerUps() {
        let (plain, _) = makeState()
        plain.maxScore = 1
        plain.isSpeedBoostEnabled = false
        plain.enabledPowerUps = []
        plain.startMatch(mode: .onePlayer)
        plain.registerPoint(for: .playerOne)
        #expect(plain.achievements.contains(.tactician))

        let (boosted, _) = makeState()
        boosted.maxScore = 1
        boosted.isSpeedBoostEnabled = true
        boosted.enabledPowerUps = []
        boosted.startMatch(mode: .onePlayer)
        boosted.registerPoint(for: .playerOne)
        #expect(!boosted.achievements.contains(.tactician))
    }

    @Test func rallySpeedAndOvertimeAchievementsUnlockAtTheirThresholds() {
        let below = makeMatch(maxScore: 1)
        below.registerRallyLength(11)
        below.registerSpeedBoost()
        below.registerSpeedBoost()
        below.registerPoint(for: .playerOne)
        #expect(!below.achievements.contains(.rallyMaster))
        #expect(!below.achievements.contains(.speedJunkie))

        let reached = makeMatch(maxScore: 1)
        reached.registerRallyLength(12)
        (0..<3).forEach { _ in reached.registerSpeedBoost() }
        reached.registerPoint(for: .playerOne)
        #expect(reached.achievements.contains(.rallyMaster))
        #expect(reached.achievements.contains(.speedJunkie))

        let overtime = makeMatch(maxScore: 10, duration: .oneMinute)
        overtime.updateRemainingMatchTime(elapsed: 60)
        overtime.registerPoint(for: .playerOne)
        #expect(overtime.achievements.contains(.marathon))
    }

    @Test func collectorUnlocksAfterEveryPowerUpTypeInOneMatch() {
        let state = makeMatch()
        for powerUp in PowerUpType.allCases.dropLast() {
            state.registerPowerUpCollected(powerUp, collectedBy: .playerOne)
        }
        #expect(!state.achievements.contains(.collector))

        state.registerPowerUpCollected(PowerUpType.allCases.last!, collectedBy: .playerOne)
        #expect(state.achievements.contains(.collector))
    }

    @Test func lifetimeTotalsAccumulateAcrossMatches() {
        let state = makeMatch(maxScore: 1)
        state.registerHit()
        state.registerHit()
        state.registerRallyLength(7)
        state.registerPoint(for: .playerOne)

        state.startMatch(mode: .onePlayer)
        state.registerHit()
        state.registerRallyLength(3)
        state.registerPoint(for: .playerTwo)

        #expect(state.lifetimeStats.totalHits == 3)
        #expect(state.lifetimeStats.longestRally == 7)
        #expect(state.lifetimeStats.gamesPlayed == 2)
    }

    @Test func favoriteModeIsTheMostPlayedMode() {
        let state = makeMatch(maxScore: 1)
        #expect(state.lifetimeStats.favoriteMode == .onePlayer)

        for _ in 0..<2 {
            state.startMatch(mode: .twoPlayers)
            state.registerPoint(for: .playerOne)
        }
        state.startMatch(mode: .onePlayer)
        state.registerPoint(for: .playerOne)

        #expect(state.lifetimeStats.favoriteMode == .twoPlayers)

        state.startMatch(mode: .onePlayer)
        state.registerPoint(for: .playerOne)
        state.startMatch(mode: .onePlayer)
        state.registerPoint(for: .playerOne)

        #expect(state.lifetimeStats.favoriteMode == .onePlayer)
    }

    // MARK: - Leaderboard

    @Test func leaderboardRecordsNewestFirstWithScoreLine() {
        let state = makeMatch(maxScore: 2)
        state.registerPoint(for: .playerTwo)
        state.registerPoint(for: .playerOne)
        state.registerPoint(for: .playerOne)

        let entry = state.leaderboard.first
        #expect(entry?.scoreLine == "2-1")
        #expect(entry?.winner == .playerOne)
        #expect(entry?.mode == .onePlayer)
    }

    @Test func leaderboardIsCappedAtItsLimit() {
        let state = makeMatch(maxScore: 1)
        for _ in 0..<(GameConfig.leaderboardLimit + 3) {
            state.startMatch(mode: .onePlayer)
            state.registerPoint(for: .playerOne)
        }

        #expect(state.leaderboard.count == GameConfig.leaderboardLimit)
    }

    // MARK: - Persistence

    @Test func progressSurvivesRecreatingTheState() {
        let suite = UUID().uuidString
        let (first, defaults) = makeState(suite: suite)
        first.maxScore = 1
        first.startMatch(mode: .onePlayer)
        first.registerPoint(for: .playerOne)

        let second = GameState(defaults: defaults, syncsToCloud: false)

        #expect(second.lifetimeStats.wins == 1)
        #expect(second.achievements.contains(.firstVictory))
        #expect(second.leaderboard.count == 1)
        defaults.removePersistentDomain(forName: suite)
    }

    @Test func preferencesPersistAfterTheDebounce() async throws {
        let suite = UUID().uuidString
        let (first, defaults) = makeState(suite: suite)
        first.visualTheme = .minimalMono
        first.difficulty = .hard
        first.maxScore = 9
        first.soundVolume = 0.25

        try await Task.sleep(for: .milliseconds(700))
        let second = GameState(defaults: defaults, syncsToCloud: false)

        #expect(second.visualTheme == .minimalMono)
        #expect(second.difficulty == .hard)
        #expect(second.maxScore == 9)
        #expect(second.soundVolume == 0.25)
        defaults.removePersistentDomain(forName: suite)
    }

    @Test func legacyEndScoreIsUsedWhenNoPreferencesExist() {
        let suite = UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defaults.set(7, forKey: "endScore")

        let state = GameState(defaults: defaults, syncsToCloud: false)

        #expect(state.maxScore == 7)
        defaults.removePersistentDomain(forName: suite)
    }

    @Test func lifetimeStatisticsFromAnOlderVersionStillDecode() throws {
        // Saved by a version that stored `favoriteMode` and had no per-mode counts.
        let legacy = Data("""
        {"gamesPlayed":4,"wins":3,"losses":1,"longestRally":9,"totalHits":50,\
        "totalPowerUpsCollected":2,"totalReplaysViewed":1,"favoriteMode":"twoPlayers"}
        """.utf8)

        let stats = try JSONDecoder().decode(LifetimeStatistics.self, from: legacy)

        #expect(stats.gamesPlayed == 4)
        #expect(stats.wins == 3)
        #expect(stats.longestRally == 9)
        #expect(stats.gamesPlayedByMode.isEmpty)
        #expect(stats.favoriteMode == .onePlayer)
    }

    @Test func lifetimeStatisticsRoundTrip() throws {
        var stats = LifetimeStatistics()
        stats.gamesPlayed = 2
        stats.gamesPlayedByMode = [GameMode.twoPlayers.rawValue: 2]

        let decoded = try JSONDecoder().decode(LifetimeStatistics.self, from: JSONEncoder().encode(stats))

        #expect(decoded == stats)
        #expect(decoded.favoriteMode == .twoPlayers)
    }
}
