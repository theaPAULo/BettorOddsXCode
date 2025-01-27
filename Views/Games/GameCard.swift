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
    private let defaultOpacity: Double = 0.08
    // Selected background opacity
    private let selectedOpacity: Double = 0.2
    
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
                // Away Team
                Button(action: { handleTeamSelection(.away) }) {
                    TeamView(
                        name: game.awayTeam,
                        spread: game.awaySpread,
                        teamColor: game.awayTeamColors.primary,
                        isSelected: selectedTeam == .away
                    )
                }
                .background(
                    LinearGradient(
                        colors: [
                            game.awayTeamColors.primary.opacity(selectedTeam == .away ? selectedOpacity : defaultOpacity),
                            game.awayTeamColors.primary.opacity(selectedTeam == .away ? selectedOpacity * 0.7 : defaultOpacity * 0.7)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                
                Text("@")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .frame(width: 40)
                    .background(Color(.systemBackground))
                
                // Home Team
                Button(action: { handleTeamSelection(.home) }) {
                    TeamView(
                        name: game.homeTeam,
                        spread: game.homeSpread,
                        teamColor: game.homeTeamColors.primary,
                        isSelected: selectedTeam == .home
                    )
                }
                .background(
                    LinearGradient(
                        colors: [
                            game.homeTeamColors.primary.opacity(selectedTeam == .home ? selectedOpacity * 0.7 : defaultOpacity * 0.7),
                            game.homeTeamColors.primary.opacity(selectedTeam == .home ? selectedOpacity : defaultOpacity)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.bottom, 12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isFeatured ? game.homeTeamColors.primary : Color.clear,
                    lineWidth: isFeatured ? 2 : 0
                )
                .opacity(0.3)
        )
        .shadow(
            color: Color.black.opacity(0.1),
            radius: 5,
            x: 0,
            y: 2
        )
    }
    
    // MARK: - Methods
    private func handleTeamSelection(_ team: TeamSelection) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        globalSelectedTeam = (game.id, team)
        onSelect()
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
