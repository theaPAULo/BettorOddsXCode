import SwiftUI

struct GameCard: View {
    let game: Game
    let isFeatured: Bool
    let onSelect: () -> Void
    @Binding var globalSelectedTeam: (gameId: String, team: TeamSelection)?
    
    private var isTeamSelected: Bool {
        globalSelectedTeam?.gameId == game.id
    }
    
    private var selectedTeam: TeamSelection? {
        isTeamSelected ? globalSelectedTeam?.team : nil
    }
    
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                game.awayTeamColors.primary.opacity(0.8),
                game.awayTeamColors.secondary.opacity(0.8),
                game.homeTeamColors.secondary.opacity(0.8),
                game.homeTeamColors.primary.opacity(0.8)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                LinearGradient(
                    colors: [
                        game.awayTeamColors.primary.opacity(0.6),
                        game.homeTeamColors.primary.opacity(0.6)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: 2
            )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Card Content
            VStack(spacing: 0) {
                // Header with League and Time
                HStack {
                    Text(game.league)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(game.formattedTime)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                // Teams and Scores
                HStack(spacing: 0) {
                    TeamButton(
                        teamName: game.awayTeam,
                        spread: game.awaySpread,
                        teamColor: .white,
                        isSelected: selectedTeam == .away
                    ) {
                        globalSelectedTeam = (game.id, .away)
                        onSelect()
                    }
                    
                    Text("@")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.black.opacity(0.1))
                        .clipShape(Circle())
                    
                    TeamButton(
                        teamName: game.homeTeam,
                        spread: game.homeSpread,
                        teamColor: .white,
                        isSelected: selectedTeam == .home
                    ) {
                        globalSelectedTeam = (game.id, .home)
                        onSelect()
                    }
                }
                .padding(.bottom, 12)
            }
            .background(backgroundGradient)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(cardBorder)
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
    }
}

// TeamButton remains the same but with updated colors
struct TeamButton: View {
    let teamName: String
    let spread: String
    let teamColor: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(teamName)
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
            .background(isSelected ? Color.white.opacity(0.2) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
