//
//  GameCard.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/26/25.
//

import SwiftUI

struct GameCard: View {
    let game: Game
    let isFeatured: Bool
    let onSelect: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onSelect()
        }) {
            VStack(spacing: 12) {
                // Header with league and time
                HStack {
                    Text(game.league)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isPressed ? .white : .primary)
                    
                    Spacer()
                    
                    Text(game.formattedTime)
                        .font(.system(size: 14))
                        .foregroundColor(isPressed ? .white : .gray)
                }
                
                // Teams and spreads
                HStack {
                    // Away Team
                    VStack(alignment: .leading, spacing: 4) {
                        Text(game.awayTeam)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isPressed ? .white : game.awayTeamColors.primary)
                        
                        Text("\(game.spread > 0 ? "+" : "")\(String(format: "%.1f", -game.spread))")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(isPressed ? .white : game.awayTeamColors.primary)
                    }
                    
                    Spacer()
                    
                    Text("@")
                        .font(.system(size: 16))
                        .foregroundColor(isPressed ? .white : .gray)
                    
                    Spacer()
                    
                    // Home Team
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(game.homeTeam)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isPressed ? .white : game.homeTeamColors.primary)
                        
                        Text("\(game.spread < 0 ? "" : "+")\(String(format: "%.1f", game.spread))")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(isPressed ? .white : game.homeTeamColors.primary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isPressed ? game.homeTeamColors.primary : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFeatured ? game.homeTeamColors.primary : Color.clear, lineWidth: isFeatured ? 2 : 0)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity,
                           pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.2)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

#Preview {
    GameCard(
        game: Game.sampleGames[0],
        isFeatured: true
    ) {
        print("Game selected")
    }
    .padding()
}
