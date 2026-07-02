// AboutView.swift
//
// Informational sheet describing what PingPong Retro includes and how it is
// controlled. It also gives a quick overview of the app's technology stack and
// credits so the rest of the UI can stay focused on play.

import SwiftUI

/// Static about screen that explains the app's features, controls, technology,
/// and authorship in the same card-based style as the other sheets.
struct AboutView: View {
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    heroCard
                    highlightsCard
                    controlsCard
                    technologyCard
                    creditsCard
                }
                .padding(20)
                .frame(maxWidth: 760, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(backgroundGradient)
            .navigationTitle("About")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done", action: onDismiss)
                }
            }
        }
    }

    private var heroCard: some View {
        HStack(alignment: .center, spacing: 18) {
            Circle()
                .fill(RadialGradient(colors: [.white, .cyan.opacity(0.82)], center: .topLeading, startRadius: 5, endRadius: 42))
                .frame(width: 74, height: 74)
                .shadow(color: .cyan.opacity(0.45), radius: 16)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                Text("PingPong Retro")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(LinearGradient(colors: [.cyan, .purple], startPoint: .leading, endPoint: .trailing))

                Text("Retro arcade Pong rebuilt with SwiftUI, SpriteKit, replay highlights, power-ups, and long-term progression.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.78))

                HStack(spacing: 10) {
                    tag(text: "SwiftUI", symbol: "swift")
                    tag(text: "SpriteKit", symbol: "sparkles")
                    tag(text: "macOS + iOS", symbol: "laptopcomputer.and.iphone")
                }
            }
        }
        .padding(22)
        .background(cardBackground(colors: [.cyan.opacity(0.34), .purple.opacity(0.28)]))
    }

    private var highlightsCard: some View {
        infoSection(title: "Highlights") {
            VStack(alignment: .leading, spacing: 12) {
                featureRow(title: "Flexible matches", detail: "One-player and local two-player modes with score targets, timers, and optional speed boosts.", symbol: "gamecontroller.fill")
                featureRow(title: "Distinct opponents", detail: "Choose both AI difficulty and play style for more varied matches.", symbol: "brain")
                featureRow(title: "Moment-to-moment variety", detail: "Collect paddle boost, slow motion, and curve shot power-ups during rallies.", symbol: "bolt.fill")
                featureRow(title: "Progression", detail: "Track lifetime stats, unlock achievements, and build a local leaderboard history.", symbol: "chart.bar.fill")
            }
        }
    }

    private var controlsCard: some View {
        infoSection(title: "Controls") {
            VStack(alignment: .leading, spacing: 10) {
                // The sheet mirrors the active platform so players see the
                // control scheme that actually applies on this device.
                #if os(macOS)
                controlRow(title: "Player 1", detail: "W / S or Arrow Keys")
                controlRow(title: "Player 2", detail: "I / K in two-player mode")
                controlRow(title: "Pause", detail: "Space")
                #else
                controlRow(title: "Player 1", detail: "Drag on the right side")
                controlRow(title: "Player 2", detail: "Drag on the left side in two-player mode")
                controlRow(title: "Pause", detail: "Use the HUD button")
                #endif
            }
        }
    }

    private var technologyCard: some View {
        infoSection(title: "Technology") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Built with SwiftUI, SpriteKit, Observation, and AVFoundation.")
                Text("Player settings, stats, achievements, and leaderboard entries are stored locally and mirrored through Apple’s ubiquitous key-value store when available.")
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
    }

    private var creditsCard: some View {
        infoSection(title: "Credits") {
            VStack(alignment: .leading, spacing: 6) {
                Text("© 2026 Marcus Deuß")
                Text("All Rights Reserved")
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
    }

    /// Reusable builder helpers below give each informational section the same
    /// card framing while allowing the content rows to stay lightweight.
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

    private func featureRow(title: LocalizedStringKey, detail: LocalizedStringKey, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .frame(width: 24)
                .foregroundStyle(.cyan)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func controlRow(title: LocalizedStringKey, detail: LocalizedStringKey) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(detail)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }

    private func tag(text: LocalizedStringKey, symbol: String) -> some View {
        Label(text, systemImage: symbol)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.white.opacity(0.14), in: Capsule())
            .foregroundStyle(.white)
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
    AboutView { }
}
