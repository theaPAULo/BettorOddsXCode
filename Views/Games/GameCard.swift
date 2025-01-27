//
//  GameCard.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Version: 2.3.0

import SwiftUI

struct GameCard: View {
    // MARK: - Properties
    let game: Game
    let isFeatured: Bool
    let onSelect: () -> Void
    @Binding var globalSelectedTeam: (gameId: String, team: TeamSelection)?
    
    // Default background opacity
    private let defaultOpacity: Double = 0.1
    // Selected background opacity
    private let selectedOpacity: Double = 0.25
    
    // MARK: - Computed Properties
    private var isTeamSelected: Bool {
        globalSelectedTeam?.gameId == game.id
    }
    
    private var selectedTeam: TeamSelection? {
        isTeamSelected ? globalSelectedTeam?.team : nil
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 8) {
            // Header with league and time
            HStack {
                Text(game.league)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(game.formattedTime)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            // Teams and spreads
            HStack(spacing: 0) {
                // Away Team Side
                VStack {
                    TeamView(
                        name: game.awayTeam,
                        spread: game.awaySpread,
                        teamColor: game.awayTeamColors.primary,
                        isSelected: selectedTeam == .away
                    )
                }
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [
                            game.awayTeamColors.primary.opacity(selectedTeam == .away ? selectedOpacity : defaultOpacity),
                            game.awayTeamColors.primary.opacity(selectedTeam == .away ? selectedOpacity * 0.8 : defaultOpacity * 0.8)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .onTapGesture {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    globalSelectedTeam = (game.id, .away)
                    onSelect()
                }
                
                // Center Divider
                Text("@")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .frame(width: 30)
                    .background(Color(.systemBackground))
                
                // Home Team Side
                VStack {
                    TeamView(
                        name: game.homeTeam,
                        spread: game.homeSpread,
                        teamColor: game.homeTeamColors.primary,
                        isSelected: selectedTeam == .home
                    )
                }
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [
                            game.homeTeamColors.primary.opacity(selectedTeam == .home ? selectedOpacity * 0.8 : defaultOpacity * 0.8),
                            game.homeTeamColors.primary.opacity(selectedTeam == .home ? selectedOpacity : defaultOpacity)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .onTapGesture {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    globalSelectedTeam = (game.id, .home)
                    onSelect()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        selectedTeam == .home ? game.homeTeamColors.primary :
                        selectedTeam == .away ? game.awayTeamColors.primary :
                        isFeatured ? game.homeTeamColors.primary : Color.clear,
                        lineWidth: 2
                    )
                    .opacity(0.3)
            )
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(
            color: (selectedTeam != nil || isFeatured) ?
                (selectedTeam == .home ? game.homeTeamColors.primary :
                 selectedTeam == .away ? game.awayTeamColors.primary :
                    game.homeTeamColors.primary).opacity(0.2) : Color.black.opacity(0.1),
            radius: 5,
            x: 0,
            y: 2
        )
        .scaleEffect(isFeatured ? 1.02 : 1.0)
    }
}

// MARK: - Supporting Views

struct TeamView: View {
    let name: String
    let spread: String
    let teamColor: Color
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(teamColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            
            Text(spread)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(teamColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    GameCard(
        game: Game.sampleGames[0],
        isFeatured: true,
        onSelect: {},
        globalSelectedTeam: .constant(nil)
    )
    .padding()
}
