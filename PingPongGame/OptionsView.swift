import SwiftUI

struct OptionsView: View {
    @Bindable var gameState: GameState
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Visuals") {
                    Toggle("Black & White Mode", isOn: $gameState.isBlackAndWhite)
                    Toggle("Enable Haptics", isOn: $gameState.isHapticsEnabled)
                }

                Section("Match Rules") {
                    Picker("End Score", selection: $gameState.maxScore) {
                        ForEach([3, 5, 7, 10, 15, 21], id: \.self) { score in
                            Text("\(score)").tag(score)
                        }
                    }

                    Picker("Match Duration", selection: $gameState.matchDuration) {
                        ForEach(MatchDuration.allCases) { duration in
                            Text(duration.title).tag(duration)
                        }
                    }

                    Toggle("Rally Speed Boosts", isOn: $gameState.isSpeedBoostEnabled)
                }

                Section("Gameplay") {
                    Picker("Difficulty", selection: $gameState.difficulty) {
                        ForEach(Difficulty.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }

                    Picker("AI Style", selection: $gameState.aiStyle) {
                        ForEach(AIStyle.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Base Ball Speed")
                        HStack(spacing: 10) {
                            Image(systemName: "tortoise.fill")
                                .foregroundStyle(.secondary)
                            Slider(value: $gameState.ballSpeed, in: 0.5 ... 2.0, step: 0.1)
                                .accessibilityLabel("Base Ball Speed")
                            Image(systemName: "hare.fill")
                                .foregroundStyle(.secondary)
                            Text("\(gameState.ballSpeed, format: .number.precision(.fractionLength(1)))x")
                                .font(.body.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(width: 44)
                        }
                    }
                }

                Section("Power-Ups") {
                    ForEach(PowerUpType.allCases) { powerUp in
                        Toggle(isOn: binding(for: powerUp)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Label(powerUp.title, systemImage: powerUp.symbolName)
                                Text(powerUp.detail)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Audio") {
                    Toggle("Sound Effects", isOn: $gameState.isSoundEnabled)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Volume")
                        Slider(value: $gameState.soundVolume, in: 0 ... 1)
                            .disabled(!gameState.isSoundEnabled)
                        Text(gameState.isSoundEnabled ? "\(Int((gameState.soundVolume * 100).rounded()))%" : "Muted")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: onDismiss)
                }
            }
        }
    }

    private func binding(for powerUp: PowerUpType) -> Binding<Bool> {
        Binding(
            get: { gameState.enabledPowerUps.contains(powerUp) },
            set: { isEnabled in
                if isEnabled {
                    gameState.enabledPowerUps.insert(powerUp)
                } else {
                    gameState.enabledPowerUps.remove(powerUp)
                }
            }
        )
    }
}

#Preview {
    OptionsView(gameState: GameState()) { }
}
