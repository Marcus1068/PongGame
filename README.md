# PingPong Retro

A retro-styled Pong game built with SwiftUI, SpriteKit, and AVFoundation for **macOS** and **iOS**.

## Features

- **1-player and 2-player modes** - play against the computer or locally with a second player
- **AI difficulty and behavior styles** - tune the opponent with `Easy`, `Medium`, or `Hard` difficulty plus `Balanced`, `Defensive`, `Aggressive`, or `Mirror` AI styles
- **Custom match rules** - choose score targets, timed matches, and whether rally speed boosts are enabled
- **Power-ups** - collect `Paddle Boost`, `Slow Ball`, and `Curve Shot` pickups during long rallies
- **Replay support** - replay the last point from an in-memory highlight buffer
- **Progression systems** - track lifetime stats, achievements, and a local leaderboard
- **Audio and haptics controls** - toggle sound effects, adjust volume, and enable haptics
- **Retro presentation** - neon visuals, particle effects, synthesized arcade sounds, and animated loading and winner screens

## Controls

| Platform | Controls |
|----------|----------|
| macOS | Player 1: **W / S** or **↑ / ↓**. Player 2: **I / K**. Press **Space** to pause. |
| iOS | Drag on the **right side** for Player 1. In 2-player mode, drag on the **left side** for Player 2. |

## Main Screens

- `ContentView.swift` - app root, loading flow, and sheet presentation
- `PongGameView.swift` - SpriteKit host view, HUD, score overlay, timer, and replay hook
- `PongScene.swift` - gameplay loop, AI, replay capture, power-ups, timer rules, input, effects, and audio
- `GameState.swift` - observable state, persistence, achievements, leaderboard, and match progression
- `GameSupport.swift` - shared enums, settings models, stats models, and gameplay configuration
- `OptionsView.swift` - settings for visuals, rules, AI, power-ups, and audio
- `StatsView.swift` - lifetime stats, achievements, and local leaderboard
- `AboutView.swift` - feature summary and controls overview

## Persistence

Player settings, statistics, achievements, and leaderboard entries are stored locally with `UserDefaults` and mirrored to `NSUbiquitousKeyValueStore` when available.

## Requirements

- Xcode 16+
- Swift 5.10+
- macOS 14+ / iOS 17+

## Building

Open `PingPongRetro.xcodeproj` in Xcode, choose a macOS or iOS destination, and press **Run**.

## Author

© 2026 Marcus Deuß - All Rights Reserved
