//
//  OptionsView.swift
//  PongGame
//
//  Created by Marcus Deuß on 25.02.26.
//

import SwiftUI

struct OptionsView: View {
    @Bindable var gameState: GameState
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Dimmed backdrop
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 28) {

                // MARK: Title
                Text("Options")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Divider()
                    .background(.white.opacity(0.2))

                // MARK: Color scheme picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("Color")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))

                    Picker("Color", selection: $gameState.isBlackAndWhite) {
                        Text("Color").tag(false)
                        Text("Black/White").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, 8)
                
                // MARK: Difficulty picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("Difficulty")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))

                    Picker("Difficulty", selection: $gameState.difficulty) {
                        ForEach(Difficulty.allCases, id: \.self) { level in
                            Text(LocalizedStringKey(level.rawValue)).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, 8)

                // MARK: Ball speed slider
                VStack(alignment: .leading, spacing: 10) {
                    Text("Ball Speed")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))

                    HStack(spacing: 8) {
                        Image(systemName: "tortoise.fill")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))

                        Slider(value: $gameState.ballSpeed, in: 0.5...2.0, step: 0.1)
                            .tint(.cyan)

                        Image(systemName: "hare.fill")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))

                        Text("\(gameState.ballSpeed, specifier: "%.1f")x")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(width: 35)
                    }
                }
                .padding(.horizontal, 8)

                Divider()
                    .background(.white.opacity(0.2))

                // MARK: Dismiss button
                Button(action: onDismiss) {
                    Text("Close")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [.cyan, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: Capsule()
                        )
                        .shadow(color: .cyan.opacity(0.5), radius: 8)
                }
                .buttonStyle(.plain)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                    )
            )
            .colorScheme(.dark)
            .padding(40)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}

#Preview {
    OptionsView(gameState: GameState()) { }
        .preferredColorScheme(.dark)
}
