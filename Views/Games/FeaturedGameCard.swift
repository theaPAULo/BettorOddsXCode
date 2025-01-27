//
//  FeaturedGameCard.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/26/25.
//

import SwiftUI

struct FeaturedGameCard: View {
    let game: Game
    let onSelect: () -> Void
    
    @State private var cardScale: CGFloat = 1.0
    @State private var showingDetails = false
    @State private var pulseAnimation = false
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onSelect()
        }) {
            VStack(spacing: 20) {
                // Featured Badge
                HStack {
                    Label("Featured Game", systemImage: "star.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(12)
                    
                    Spacer()
                    
                    // Game Time
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                        Text(game.formattedTime)
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                }
                
                // Teams
                HStack(spacing: 30) {
                    // Away Team
                    FeaturedTeamColumn(
                        name: game.awayTeam,
                        spread: -game.spread,
                        teamColors: game.awayTeamColors,
                        isHome: false
                    )
                    
                    Text("VS")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.gray)
                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                            value: pulseAnimation
                        )
                    
                    // Home Team
                    FeaturedTeamColumn(
                        name: game.homeTeam,
                        spread: game.spread,
                        teamColors: game.homeTeamColors,
                        isHome: true
                    )
                }
                .padding(.vertical, 10)
            }
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(game.homeTeamColors.primary.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(cardScale)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: cardScale)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            pulseAnimation = true
        }
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity,
                           pressing: { pressing in
            cardScale = pressing ? 0.95 : 1.0
        }, perform: {})
    }
}

struct FeaturedTeamColumn: View {
    let name: String
    let spread: Double
    let teamColors: TeamColors
    let isHome: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Team Name
            Text(name)
                .font(.system(size: 18, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(teamColors.primary)
            
            // Spread
            if spread != 0 {
                Text(spread > 0 ? "+\(String(format: "%.1f", spread))" : "\(String(format: "%.1f", spread))")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(teamColors.primary)
            }
            
            // Home/Away Badge
            Text(isHome ? "HOME" : "AWAY")
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    FeaturedGameCard(
        game: Game.sampleGames[0]
    ) {
        print("Featured game selected")
    }
    .padding()
}
