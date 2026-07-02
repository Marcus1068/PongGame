// Copyright 2026 Marcus Deuß
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

//
//  PongGameApp.swift
//  PongGame
//
//  Created by Marcus Deuß on 25.02.26.
//  App entry point for PingPong Retro.
//  This file only creates the main app scene and hands off all UI and state
//  coordination to `ContentView`.
//

import SwiftUI

/// The `@main` app type that installs `ContentView` as the root window content.
@main
struct PongGameApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
