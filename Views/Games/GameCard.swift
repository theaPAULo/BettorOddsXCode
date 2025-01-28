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
                game.awayTeamColors.primary.opacity(0.6),
                game.awayTeamColors.secondary.opacity(0.6),
                game.homeTeamColors.secondary.opacity(0.6),
                game.homeTeamColors.primary.opacity(0.6)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
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
            
            HStack(spacing: 0) {
                TeamButton(
                    teamName: game.awayTeam,
                    spread: game.awaySpread,
                    teamColor: game.awayTeamColors.primary,
                    isSelected: selectedTeam == .away
                ) {
                    globalSelectedTeam = (game.id, .away)
                    onSelect()
                }
                
                Text("@")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.1))
                    .clipShape(Circle())
                
                TeamButton(
                    teamName: game.homeTeam,
                    spread: game.homeSpread,
                    teamColor: game.homeTeamColors.primary,
                    isSelected: selectedTeam == .home
                ) {
                    globalSelectedTeam = (game.id, .home)
                    onSelect()
                }
            }
            .background(backgroundGradient)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 5)
    }
}

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
                    .foregroundColor(isSelected ? .white : teamColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                
                Text(spread)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(isSelected ? .white : teamColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? teamColor.opacity(0.3) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
