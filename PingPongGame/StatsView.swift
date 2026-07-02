// StatsView.swift
//
// Stats and progression sheet for PingPong Retro. It summarizes lifetime
// performance, surfaces the current match when relevant, and shows achievements
// plus the local leaderboard stored in `GameState`.

import SwiftUI

/// Progress dashboard that presents match history, achievements, and leaderboard
/// data in a single retro-styled sheet.
struct StatsView: View {
    var gameState: GameState
    let onDismiss: () -> Void

    private let summaryColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    /// Indicates whether enough persistent progress exists to show history-based
    /// sections instead of the first-match empty state.
    private var hasHistory: Bool {
        gameState.lifetimeStats.gamesPlayed > 0 || !gameState.leaderboard.isEmpty || !gameState.achievements.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerCard

                    LazyVGrid(columns: summaryColumns, spacing: 12) {
                        summaryCard(title: "Games Played", value: "\(gameState.lifetimeStats.gamesPlayed)", symbol: "gamecontroller.fill")
                        summaryCard(title: "Wins", value: "\(gameState.lifetimeStats.wins)", symbol: "trophy.fill")
                        summaryCard(title: "Longest Rally", value: "\(gameState.lifetimeStats.longestRally)", symbol: "bolt.fill")
                        summaryCard(title: "Replays Viewed", value: "\(gameState.lifetimeStats.totalReplaysViewed)", symbol: "gobackward")
                    }

                    if hasHistory {
                        if gameState.hasStarted || gameState.winningSide != nil {
                            currentMatchCard
                        }

                        lifetimeBreakdownCard
                        achievementsCard
                        leaderboardCard
                    } else {
                        emptyStateCard
                        currentSetupCard
                    }
                }
                .padding(20)
                .frame(maxWidth: 760, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(backgroundGradient)
            .navigationTitle("Stats & Progress")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done", action: onDismiss)
                }
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Retro Progress", systemImage: "chart.bar.xaxis")
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text(hasHistory ? "Your recent matches, achievements, and milestone progress all live here." : "Play your first match to unlock achievements, populate the leaderboard, and build a stat history.")
                .foregroundStyle(.white.opacity(0.78))

            HStack(spacing: 10) {
                tag(text: gameState.gameMode.title, symbol: "person.2.fill")
                tag(text: gameState.matchDuration.title, symbol: "timer")
                tag(text: gameState.aiStyle.title, symbol: "brain")
            }
        }
        .padding(20)
        .background(cardBackground(colors: [.cyan.opacity(0.35), .purple.opacity(0.3)]))
    }

    private var currentMatchCard: some View {
        infoSection(title: "Current Match") {
            VStack(alignment: .leading, spacing: 12) {
                statRow(title: "Score", value: "\(gameState.playerScore)-\(gameState.opponentScore)")
                statRow(title: "Longest Rally", value: "\(gameState.currentMatchStats.longestRally)")
                statRow(title: "Speed Boosts", value: "\(gameState.currentMatchStats.speedBoostsTriggered)")
                statRow(title: "Power-Ups", value: "\(gameState.currentMatchStats.powerUpsCollected)")
                if let timer = gameState.formattedTimer {
                    statRow(title: "Clock", value: timer)
                }
            }
        }
    }

    private var lifetimeBreakdownCard: some View {
        infoSection(title: "Lifetime Stats") {
            VStack(alignment: .leading, spacing: 12) {
                statRow(title: "Wins", value: "\(gameState.lifetimeStats.wins)")
                statRow(title: "Losses", value: "\(gameState.lifetimeStats.losses)")
                statRow(title: "Total Hits", value: "\(gameState.lifetimeStats.totalHits)")
                statRow(title: "Power-Ups Collected", value: "\(gameState.lifetimeStats.totalPowerUpsCollected)")
                statRow(title: "Favorite Mode", value: gameState.lifetimeStats.favoriteMode.title)
            }
        }
    }

    private var achievementsCard: some View {
        infoSection(title: "Achievements") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(AchievementID.allCases) { achievement in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: gameState.achievements.contains(achievement) ? "checkmark.seal.fill" : "seal")
                            .foregroundStyle(gameState.achievements.contains(achievement) ? .cyan : .secondary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(achievement.title)
                                .font(.headline)
                            Text(achievement.detail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var leaderboardCard: some View {
        infoSection(title: "Local Leaderboard") {
            VStack(alignment: .leading, spacing: 12) {
                // Enumerating the trimmed slice gives the UI a simple 1-based
                // rank label without changing the underlying leaderboard data.
                ForEach(Array(gameState.leaderboard.prefix(5).enumerated()), id: \.element.id) { index, entry in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("#\(index + 1)")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(.cyan)
                            Text(entry.mode.displayName(for: entry.winner))
                                .font(.headline)
                            Spacer()
                            Text(entry.mode.title)
                                .foregroundStyle(.secondary)
                        }

                        Text(String(localized: "Score \(entry.scoreLine)  •  Longest Rally \(entry.longestRally)  •  Boosts \(entry.speedBoosts)"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    if index < min(gameState.leaderboard.count, 5) - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    private var emptyStateCard: some View {
        infoSection(title: "No Match History Yet") {
            VStack(alignment: .leading, spacing: 10) {
                Text("The stats screen will start filling up after your first finished match.")
                    .foregroundStyle(.secondary)

                Label("Complete a match to save it to the local leaderboard", systemImage: "list.number")
                Label("Unlock achievements by reaching longer rallies and different rule combinations", systemImage: "sparkles")
                Label("Use the replay button after a point to review highlights", systemImage: "gobackward")
            }
            .font(.subheadline)
        }
    }

    private var currentSetupCard: some View {
        infoSection(title: "Current Setup") {
            VStack(alignment: .leading, spacing: 12) {
                statRow(title: "Theme", value: gameState.visualTheme.title)
                statRow(title: "Target Score", value: "\(gameState.maxScore)")
                statRow(title: "Match Duration", value: gameState.matchDuration.title)
                statRow(title: "Difficulty", value: gameState.difficulty.title)
                statRow(title: "AI Style", value: gameState.aiStyle.title)
                statRow(title: "Speed Boosts", value: gameState.isSpeedBoostEnabled ? String(localized: "On") : String(localized: "Off"))
                statRow(title: "Power-Ups", value: gameState.enabledPowerUps.isEmpty ? String(localized: "Off") : String(localized: "\(gameState.enabledPowerUps.count) active"))
            }
        }
    }

    /// Reusable builder helpers below keep the stats dashboard's cards, rows,
    /// and tags styled consistently across very different data sections.
    private func summaryCard(title: LocalizedStringKey, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.78))

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(cardBackground(colors: [.white.opacity(0.12), .white.opacity(0.04)]))
    }

    private func infoSection<Content: View>(title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(.white)

            content()
        }
        .padding(18)
        .background(cardBackground(colors: [.white.opacity(0.1), .black.opacity(0.18)]))
    }

    private func statRow(title: LocalizedStringKey, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.primary)
            Spacer()
            Text(value)
                .font(.body.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private func tag(text: String, symbol: String) -> some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: symbol)
        }
        .font(.caption.weight(.medium))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.white.opacity(0.14), in: Capsule())
        .foregroundStyle(.white)
    }

    private var backgroundGradient: some View {
        LinearGradient(colors: [.black, .purple.opacity(0.16), .cyan.opacity(0.14), .black], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }

    private func cardBackground(colors: [Color]) -> some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            )
    }
}

#Preview {
    StatsView(gameState: GameState()) { }
}
