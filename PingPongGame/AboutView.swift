import SwiftUI

struct AboutView: View {
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 12) {
                        Circle()
                            .fill(RadialGradient(colors: [.white, .cyan.opacity(0.8)], center: .topLeading, startRadius: 5, endRadius: 40))
                            .frame(width: 68, height: 68)
                            .shadow(color: .cyan.opacity(0.5), radius: 14)
                            .accessibilityHidden(true)

                        Text("PingPong Retro")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(LinearGradient(colors: [.cyan, .purple], startPoint: .leading, endPoint: .trailing))

                        Text("Retro arcade Pong rebuilt with SwiftUI, SpriteKit, local progression, power-ups, replay support, and configurable match rules.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                Section("Highlights") {
                    Label("One-player and local two-player matches", systemImage: "person.2.fill")
                    Label("AI difficulty and behavior styles", systemImage: "brain")
                    Label("Timed matches, score targets, and optional rally speed boosts", systemImage: "timer")
                    Label("Power-ups for paddle boosts, slow motion, and curve shots", systemImage: "sparkles")
                    Label("Replay the last point and track long-term stats", systemImage: "gobackward")
                    Label("Local achievements and leaderboard history", systemImage: "list.number")
                }

                Section("Controls") {
                    #if os(macOS)
                    Text("Player 1 uses W/S or the arrow keys. In two-player mode, Player 2 uses I/K. Press Space to pause.")
                    #else
                    Text("Drag on the right side of the screen for Player 1. In two-player mode, the left side controls Player 2.")
                    #endif
                }

                Section("Technology") {
                    Text("Built with SwiftUI, SpriteKit, Observation, and AVFoundation.")
                    Text("Progress is stored locally and mirrored through Apple’s ubiquitous key-value store when available.")
                }

                Section("Credits") {
                    Text("© 2026 Marcus Deuß")
                    Text("All Rights Reserved")
                }
            }
            .navigationTitle("About")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: onDismiss)
                }
            }
        }
    }
}

#Preview {
    AboutView { }
}
