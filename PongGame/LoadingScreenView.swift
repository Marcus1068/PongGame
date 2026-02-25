//
//  LoadingScreenView.swift
//  PongGame
//
//  Created by Marcus Deuß on 25.02.26.
//

import SwiftUI

struct LoadingScreenView: View {
    @State private var isAnimating = false
    @State private var ballOffset: CGFloat = 0
    @State private var showContent = false
    
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [.black, .purple.opacity(0.3), .cyan.opacity(0.3), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App title with animated ball
                VStack(spacing: 20) {
                    // Animated ping pong ball
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white, .cyan.opacity(0.8)],
                                center: .topLeading,
                                startRadius: 5,
                                endRadius: 40
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: .cyan.opacity(0.6), radius: 20)
                        .offset(x: ballOffset)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: ballOffset)
                    
                    // App name
                    Text("PingPong Sample")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .cyan.opacity(0.5), radius: 10)
                    
                    // Loading indicator
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(.white.opacity(0.8))
                                .frame(width: 10, height: 10)
                                .scaleEffect(showContent ? 1 : 0.5)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.2),
                                    value: showContent
                                )
                        }
                    }
                    .padding(.top, 20)
                }
                
                Spacer()
                Spacer()
                
                // Copyright info
                VStack(spacing: 8) {
                    Text("© 2026 Marcus Deuß")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                    
                    Text("All Rights Reserved")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.bottom, 40)
            }
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            // Start animations
            withAnimation(.easeIn(duration: 0.5)) {
                showContent = true
            }
            
            // Start ball animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                ballOffset = 50
            }
            
            // Dismiss loading screen after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    onComplete()
                }
            }
        }
    }
}

#Preview {
    LoadingScreenView {
        print("Loading complete")
    }
}
