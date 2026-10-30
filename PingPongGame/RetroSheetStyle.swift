// RetroSheetStyle.swift
//
// Shared look for the secondary sheets (stats, settings, about). Every sheet is
// designed as light text on a dark retro background, so the background is fully
// opaque and the sheets opt into the dark color scheme. Without that, the
// translucent gradient lets a light system sheet show through and the white
// text becomes hard to read.
import SwiftUI

/// Opaque dark background with a faint purple-to-cyan wash.
struct RetroSheetBackground: View {
    var body: some View {
        ZStack {
            // Solid base so the gradient's translucent stops never reveal the
            // sheet's own (possibly light) background.
            Color.black

            LinearGradient(
                colors: [.black, .purple.opacity(0.16), .cyan.opacity(0.14), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }
}

/// Rounded card fill with a hairline border, used behind each sheet section.
struct RetroCardBackground: View {
    let colors: [Color]

    var body: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(.white.opacity(0.14), lineWidth: 1)
            )
    }
}

extension ShapeStyle where Self == Color {
    /// Body and label text on the dark sheet background; brighter than the
    /// previous 78% white so it stands out more on the translucent cards.
    static var retroBodyText: Color { .white.opacity(0.9) }
}
