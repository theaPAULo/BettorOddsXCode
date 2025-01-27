//
//  GameCard.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Version: 2.0.0

import SwiftUI

struct GameCard: View {
    let game: Game
    let isFeatured: Bool
    let onSelect: () -> Void
    
    @State private var isPressed = false
    @State private var selectedTeam: TeamSelection?
    
    enum TeamSelection {
        case home
        case away
    }
    
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
                        
                        let awaySpread = abs(game.spread)
                        Text(game.spread > 0 ? "-\(String(format: "%.1f", awaySpread))" : "+\(String(format: "%.1f", awaySpread))")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(isPressed ? .white : game.awayTeamColors.primary)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedTeam == .away ? game.awayTeamColors.primary.opacity(0.05) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selectedTeam == .away ? game.awayTeamColors.primary.opacity(0.1) : Color.clear, lineWidth: 1)
                    )
                    .onTapGesture {
                        withAnimation {
                            selectedTeam = .away
                        }
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
                        
                        let homeSpread = abs(game.spread)
                        Text(game.spread < 0 ? "+\(String(format: "%.1f", homeSpread))" : "-\(String(format: "%.1f", homeSpread))")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(isPressed ? .white : game.homeTeamColors.primary)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedTeam == .home ? game.homeTeamColors.primary.opacity(0.05) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selectedTeam == .home ? game.homeTeamColors.primary.opacity(0.1) : Color.clear, lineWidth: 1)
                    )
                    .onTapGesture {
                        withAnimation {
                            selectedTeam = .home
                        }
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
    }
}
