# PingPong Retro

A retro-styled Pong game built with SwiftUI and SpriteKit, targeting both **macOS** and **iOS**.

## Features

- **Player vs Computer** – compete against an AI opponent
- **First to 10 wins** – match ends when either side reaches 10 points
- **Adjustable ball speed** – slider from 0.5× to 2.0×
- **Pause / Resume** – pause the game at any time
- **Restart** – reset scores and start a new match
- **Visual effects** – neon glow, cyan particle trail on the ball, burst effects on paddle hits, rally flash after 3 consecutive hits
- **Animated loading screen** – splash screen branded "PingPong Retro" with animated ball and loading dots

## Controls

| Platform | Move paddle |
|----------|-------------|
| macOS    | **W / S** or **↑ / ↓** arrow keys |
| iOS      | Touch and drag |

## Project Structure

| File | Description |
|------|-------------|
| `PongGameApp.swift` | App entry point; sets up the SwiftData `ModelContainer` |
| `ContentView.swift` | Root view; manages the loading → game transition and the Restart / Pause buttons |
| `GameState.swift` | `@Observable` class holding scores, pause state, winner, and ball speed |
| `PongGameView.swift` | SwiftUI wrapper around the SpriteKit scene; renders the scoreboard, speed slider, winner overlay, and pause overlay |
| `PongScene.swift` | `SKScene` subclass with all game physics, ball movement, AI paddle logic, collision detection, particle effects, and platform-specific input handling |
| `LoadingScreenView.swift` | Animated splash / loading screen shown on first launch |
| `Item.swift` | Default SwiftData model (generated with the project template) |

## Requirements

- Xcode 16+
- Swift 5.10+
- macOS 14+ / iOS 17+

## Building

Open `PongGame.xcodeproj` in Xcode, select your target (Mac or iPhone/iPad simulator), and press **⌘R**.

## Author

© 2026 Marcus Deuß – All Rights Reserved
