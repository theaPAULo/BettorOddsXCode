//
//  LockWarningModifier.swift
//  BettorOdds
//
//  Created by Paul Soni on 2/1/25.
//  Version: 2.0.0 - Fixed to work with actual Game model properties
//

import SwiftUI

// Custom view modifier for lock warning animations
struct LockWarningModifier: ViewModifier {
    let game: Game
    @State private var isPulsing = false
    
    // Computed properties based on actual Game model
    private var needsVisualIndicator: Bool {
        // Show warning if game is locked or should be locked
        return game.isLocked || game.shouldBeLocked
    }
    
    private var visualIntensity: Double {
        // Calculate intensity based on how close to lock time
        if game.isLocked {
            return 1.0 // Full intensity for locked games
        }
        
        if game.shouldBeLocked {
            return 0.8 // High intensity for games that should be locked
        }
        
        // Calculate time-based intensity for approaching lock time
        let lockTime = game.time.addingTimeInterval(-15 * 60) // 15 minutes before
        let timeToLock = lockTime.timeIntervalSinceNow
        
        if timeToLock <= 0 {
            return 0.8 // Should be locked
        } else if timeToLock <= 300 { // 5 minutes warning
            return 0.6
        } else if timeToLock <= 900 { // 15 minutes warning
            return 0.4
        }
        
        return 0.0 // No warning needed
    }
    
    private var warningColors: [Color] {
        if game.isLocked {
            return [.red, .red.opacity(0.7)]
        } else if game.shouldBeLocked {
            return [.orange, .yellow]
        } else {
            return [.yellow, .orange]
        }
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if needsVisualIndicator {
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                            .stroke(
                                LinearGradient(
                                    colors: warningColors.map { $0.opacity(0.3 * visualIntensity) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .scaleEffect(isPulsing ? 1.02 : 1.0)
                            .animation(
                                .easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: true),
                                value: isPulsing
                            )
                    }
                }
            )
            .onChange(of: needsVisualIndicator) { _, needsIndicator in
                if needsIndicator {
                    startPulsing()
                } else {
                    stopPulsing()
                }
            }
            .onAppear {
                if needsVisualIndicator {
                    startPulsing()
                }
            }
    }
    
    private func startPulsing() {
        withAnimation(
            .easeInOut(duration: 1.0)
            .repeatForever(autoreverses: true)
        ) {
            isPulsing = true
        }
    }
    
    private func stopPulsing() {
        withAnimation(.easeOut(duration: 0.3)) {
            isPulsing = false
        }
    }
}

// Extend View to make the modifier easier to use
extension View {
    func lockWarning(for game: Game) -> some View {
        modifier(LockWarningModifier(game: game))
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        // Normal game
        RoundedRectangle(cornerRadius: 16)
            .fill(AppTheme.Colors.cardBackground)
            .frame(height: 100)
            .lockWarning(for: Game.sampleGames[0])
        
        // Locked game (if we had one in sample data)
        RoundedRectangle(cornerRadius: 16)
            .fill(AppTheme.Colors.cardBackground)
            .frame(height: 100)
            .lockWarning(for: {
                let game = Game.sampleGames[0]
                // Note: Since Game is a struct, we'd need a mutable copy
                // This is just for preview purposes
                return game
            }())
    }
    .padding()
    .background(AppTheme.Colors.background)
}
