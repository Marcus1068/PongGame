// FullScreenToggleRow.swift
//
// macOS-only settings row that toggles the main game window between windowed
// and full-screen mode, staying in sync when the user uses the green button.
//

#if os(macOS)
import AppKit
import SwiftUI

/// A toggle that enters or leaves full-screen mode for the main game window.
struct FullScreenToggleRow: View {
    @State private var isFullScreen = false

    var body: some View {
        Toggle(isOn: $isFullScreen) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Full Screen")
                Text("Play in a full-screen window.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear { isFullScreen = Self.gameWindow?.styleMask.contains(.fullScreen) ?? false }
        .onChange(of: isFullScreen) { _, newValue in
            guard let window = Self.gameWindow,
                  window.styleMask.contains(.fullScreen) != newValue else { return }
            window.toggleFullScreen(nil)
        }
        .task {
            // Keep the toggle in sync with the green button / keyboard shortcut.
            for await _ in NotificationCenter.default.notifications(named: NSWindow.didEnterFullScreenNotification)
                .map({ _ in () }) {
                isFullScreen = true
            }
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: NSWindow.didExitFullScreenNotification)
                .map({ _ in () }) {
                isFullScreen = false
            }
        }
    }

    /// The main game window (the sheet itself is a separate child window).
    private static var gameWindow: NSWindow? {
        NSApp.mainWindow ?? NSApp.windows.first { $0.styleMask.contains(.titled) }
    }
}
#endif
