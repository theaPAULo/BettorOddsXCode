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
    
    private var gradientOverlay: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                game.awayTeamColors.primary.opacity(0.9),
                game.awayTeamColors.secondary.opacity(0.7),
                game.homeTeamColors.secondary.opacity(0.7),
                game.homeTeamColors.primary.opacity(0.9)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                LinearGradient(
                    colors: [
                        game.awayTeamColors.primary.opacity(0.4),
                        game.homeTeamColors.primary.opacity(0.4)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: 1
            )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main Card Content
            VStack(spacing: 0) {
                // Header with League and Time
                HStack {
                    // League Badge
                    Text(game.league)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    // Game Time with Icon
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                        Text(game.formattedTime)
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)
                
                // Teams and Scores
                HStack(spacing: 0) {
                    // Away Team
                    TeamButton(
                        teamName: game.awayTeam,
                        spread: game.awaySpread,
                        isSelected: selectedTeam == .away,
                        teamColors: game.awayTeamColors
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            globalSelectedTeam = (game.id, .away)
                        }
                        hapticFeedback()
                        onSelect()
                    }
                    
                    // VS Badge
                    Text("@")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.2))
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                        )
                    
                    // Home Team
                    TeamButton(
                        teamName: game.homeTeam,
                        spread: game.homeSpread,
                        isSelected: selectedTeam == .home,
                        teamColors: game.homeTeamColors
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            globalSelectedTeam = (game.id, .home)
                        }
                        hapticFeedback()
                        onSelect()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 16)
            }
            .background(gradientOverlay)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(cardBorder)
        .shadow(
            color: Color.backgroundPrimary.opacity(0.2),
            radius: 10,
            x: 0,
            y: 4
        )
        .overlay(
            game.isLocked ?
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.backgroundPrimary.opacity(0.7))
                .overlay(
                    Image(systemName: "lock.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                )
            : nil
        )
    }
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

struct TeamButton: View {
    let teamName: String
    let spread: String
    let isSelected: Bool
    let teamColors: TeamColors
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Team Name
                Text(teamName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2, reservesSpace: true)
                    .minimumScaleFactor(0.8)
                
                // Spread
                Text(spread)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isSelected {
                        Color.white.opacity(0.2)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.white.opacity(0.4) : Color.clear,
                        lineWidth: 2
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .pressEvents(
            onPress: { withAnimation(.easeInOut(duration: 0.2)) { isPressed = true }},
            onRelease: { withAnimation(.easeInOut(duration: 0.2)) { isPressed = false }}
        )
    }
}

// MARK: - View Modifier for Press Events
struct PressEventsModifier: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

#Preview {
    VStack(spacing: 20) {
        GameCard(
            game: Game.sampleGames[0],
            isFeatured: true,
            onSelect: {},
            globalSelectedTeam: .constant(nil)
        )
        
        // Preview with selected team
        GameCard(
            game: Game.sampleGames[1],
            isFeatured: false,
            onSelect: {},
            globalSelectedTeam: .constant((Game.sampleGames[1].id, .home))
        )
        
        // Preview locked state
        GameCard(
            game: {
                var game = Game.sampleGames[0]
                // Assuming we add isLocked property to Game model
                return game
            }(),
            isFeatured: false,
            onSelect: {},
            globalSelectedTeam: .constant(nil)
        )
    }
    .padding()
    .background(Color.backgroundPrimary)
}
