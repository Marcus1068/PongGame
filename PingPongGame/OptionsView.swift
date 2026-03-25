import SwiftUI

struct OptionsView: View {
    @Bindable var gameState: GameState
    let onDismiss: () -> Void

    private let summaryColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    heroCard

                    LazyVGrid(columns: summaryColumns, spacing: 12) {
                        summaryCard(title: "Target Score", value: "\(gameState.maxScore)", symbol: "target")
                        summaryCard(title: "Match Duration", value: gameState.matchDuration.title, symbol: "timer")
                        summaryCard(title: "Difficulty", value: gameState.difficulty.title, symbol: "dial.high")
                        summaryCard(title: "AI Style", value: gameState.aiStyle.title, symbol: "brain")
                    }

                    visualsCard
                    matchRulesCard
                    gameplayCard
                    powerUpsCard
                    audioCard
                }
                .padding(20)
                .frame(maxWidth: 760, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(backgroundGradient)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done", action: onDismiss)
                }
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Game Setup", systemImage: "slider.horizontal.3")
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text("Adjust visuals, rules, difficulty, power-ups, and audio without losing the retro dashboard feel.")
                .foregroundStyle(.white.opacity(0.78))

            HStack(spacing: 10) {
                tag(text: gameState.visualTheme.title, symbol: "paintpalette.fill")
                tag(text: gameState.isSpeedBoostEnabled ? String(localized: "Boosts On") : String(localized: "Boosts Off"), symbol: "bolt")
                tag(text: gameState.isSoundEnabled ? String(localized: "Sound On") : String(localized: "Muted"), symbol: "speaker.wave.2.fill")
            }
        }
        .padding(20)
        .background(cardBackground(colors: gameState.visualTheme.previewGradientColors))
    }

    private var visualsCard: some View {
        infoSection(title: "Visuals") {
            VStack(alignment: .leading, spacing: 14) {
                pickerRow(title: "Theme") {
                    Picker("Theme", selection: $gameState.visualTheme) {
                        ForEach(VisualTheme.allCases) { theme in
                            Text(theme.title).tag(theme)
                        }
                    }
                    .pickerStyle(.menu)

                    Text(gameState.visualTheme.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                settingsToggle(title: "Enable Haptics", subtitle: "Use tactile feedback on supported devices.", isOn: $gameState.isHapticsEnabled)
            }
        }
    }

    private var matchRulesCard: some View {
        infoSection(title: "Match Rules") {
            VStack(alignment: .leading, spacing: 16) {
                pickerRow(title: "End Score") {
                    Picker("End Score", selection: $gameState.maxScore) {
                        ForEach([3, 5, 7, 10, 15, 21], id: \.self) { score in
                            Text("\(score)").tag(score)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                pickerRow(title: "Match Duration") {
                    Picker("Match Duration", selection: $gameState.matchDuration) {
                        ForEach(MatchDuration.allCases) { duration in
                            Text(duration.title).tag(duration)
                        }
                    }
                }

                settingsToggle(title: "Rally Speed Boosts", subtitle: "Increase rally intensity every few alternating hits.", isOn: $gameState.isSpeedBoostEnabled)
            }
        }
    }

    private var gameplayCard: some View {
        infoSection(title: "Gameplay") {
            VStack(alignment: .leading, spacing: 16) {
                pickerRow(title: "Difficulty") {
                    Picker("Difficulty", selection: $gameState.difficulty) {
                        ForEach(Difficulty.allCases) { level in
                            Text(level.localizedTitle).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                pickerRow(title: "AI Style") {
                    Picker("AI Style", selection: $gameState.aiStyle) {
                        ForEach(AIStyle.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Base Ball Speed")
                        .font(.headline)

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

                    Text("Sets the baseline pace before boosts and power-ups kick in.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var powerUpsCard: some View {
        infoSection(title: "Power-Ups") {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(PowerUpType.allCases) { powerUp in
                    Toggle(isOn: binding(for: powerUp)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Label(powerUp.title, systemImage: powerUp.symbolName)
                                .font(.headline)
                            Text(powerUp.detail)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var audioCard: some View {
        infoSection(title: "Audio") {
            VStack(alignment: .leading, spacing: 14) {
                settingsToggle(title: "Sound Effects", subtitle: "Enable synthesized paddle hits, wall bounces, and celebration sounds.", isOn: $gameState.isSoundEnabled)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Volume")
                        .font(.headline)

                    Slider(value: $gameState.soundVolume, in: 0 ... 1)
                        .disabled(!gameState.isSoundEnabled)

                    Text(gameState.isSoundEnabled ? "\(Int((gameState.soundVolume * 100).rounded()))%" : String(localized: "Muted"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func summaryCard(title: LocalizedStringKey, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.78))

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.85)
                .lineLimit(2)
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

    private func settingsToggle(title: LocalizedStringKey, subtitle: LocalizedStringKey, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func pickerRow<Content: View>(title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            content()
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
