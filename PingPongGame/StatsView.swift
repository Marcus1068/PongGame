import SwiftUI

struct StatsView: View {
    var gameState: GameState
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("Lifetime Stats") {
                    statRow(title: "Games Played", value: "\(gameState.lifetimeStats.gamesPlayed)")
                    statRow(title: "Wins", value: "\(gameState.lifetimeStats.wins)")
                    statRow(title: "Losses", value: "\(gameState.lifetimeStats.losses)")
                    statRow(title: "Longest Rally", value: "\(gameState.lifetimeStats.longestRally)")
                    statRow(title: "Total Hits", value: "\(gameState.lifetimeStats.totalHits)")
                    statRow(title: "Power-Ups Collected", value: "\(gameState.lifetimeStats.totalPowerUpsCollected)")
                    statRow(title: "Replays Viewed", value: "\(gameState.lifetimeStats.totalReplaysViewed)")
                    statRow(title: "Favorite Mode", value: gameState.lifetimeStats.favoriteMode.title)
                }

                if gameState.hasStarted || gameState.winningSide != nil {
                    Section("Current Match") {
                        statRow(title: "Score", value: "\(gameState.playerScore)-\(gameState.opponentScore)")
                        statRow(title: "Longest Rally", value: "\(gameState.currentMatchStats.longestRally)")
                        statRow(title: "Speed Boosts", value: "\(gameState.currentMatchStats.speedBoostsTriggered)")
                        statRow(title: "Power-Ups", value: "\(gameState.currentMatchStats.powerUpsCollected)")
                        if let timer = gameState.formattedTimer {
                            statRow(title: "Clock", value: timer)
                        }
                    }
                }

                Section("Achievements") {
                    ForEach(AchievementID.allCases) { achievement in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: gameState.achievements.contains(achievement) ? "checkmark.seal.fill" : "seal")
                                .foregroundStyle(gameState.achievements.contains(achievement) ? .cyan : .secondary)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(achievement.title)
                                    .font(.headline)
                                Text(achievement.detail)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Local Leaderboard") {
                    if gameState.leaderboard.isEmpty {
                        Text("Play a few matches to populate the leaderboard.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(gameState.leaderboard.enumerated()), id: \.element.id) { index, entry in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("#\(index + 1)")
                                        .font(.headline.monospacedDigit())
                                    Spacer()
                                    Text(entry.mode.title)
                                        .foregroundStyle(.secondary)
                                }
                                Text("Winner: \(entry.mode.displayName(for: entry.winner))")
                                    .font(.subheadline.weight(.medium))
                                Text("Score \(entry.scoreLine)  •  Longest Rally \(entry.longestRally)  •  Boosts \(entry.speedBoosts)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Stats & Progress")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: onDismiss)
                }
            }
        }
    }

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .font(.body.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    StatsView(gameState: GameState()) { }
}
