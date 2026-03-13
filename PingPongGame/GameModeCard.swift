//
//  GameModeCard.swift
//  PongGame
//
//  Created by Marcus Deuß on 25.02.26.
//

import SwiftUI

// MARK: - Button Style

struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Game Mode Card

struct GameModeCard: View {
    let icon: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let accentColors: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: accentColors,
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: accentColors.first?.opacity(0.6) ?? .clear, radius: 10)
                    .accessibilityHidden(true)

                VStack(spacing: 4) {
                    Text(title)
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(colors: accentColors.map { $0.opacity(0.6) },
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1.5
                            )
                    )
            )
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}
