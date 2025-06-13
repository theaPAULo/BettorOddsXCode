//
//  GameCard.swift
//  BettorOdds
//
//  Version: 2.3.0 - Fixed formattedDateTime and complex expression issues
//  Updated: June 2025

import SwiftUI

struct GameCard: View {
    // MARK: - Properties
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
    
    // MARK: - Computed Properties
    private var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: game.time)
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
    
    // MARK: - Lock Status Components
    private var lockOverlay: some View {
        Group {
            if game.shouldBeLocked || game.isLocked {
                // Show lock overlay for locked games
                Rectangle()
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        VStack {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding(.top, 40)
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    private var cardBorder: some View {
        let awayPrimaryColor = game.awayTeamColors.primary.opacity(0.4)
        let homePrimaryColor = game.homeTeamColors.primary.opacity(0.4)
        
        return RoundedRectangle(cornerRadius: 16)
            .stroke(
                LinearGradient(
                    colors: [awayPrimaryColor, homePrimaryColor],
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
                    
                    // Game Status Badge
                    GameStatusBadge(status: game.status)
                    
                    // Game Time
                    if game.status == .upcoming {
                        HStack(spacing: 4) {
                            Text(formattedDateTime)
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)
                
                // Teams and Scores
                HStack(spacing: 0) {
                    // Away Team
                    TeamButton(
                        game: game,
                        teamName: game.awayTeam,
                        spread: game.awaySpread,
                        isSelected: selectedTeam == .away,
                        teamColors: game.awayTeamColors,
                        score: game.score,
                        isHomeTeam: false,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                globalSelectedTeam = (game.id, .away)
                            }
                            hapticFeedback()
                            onSelect()
                        }
                    )
                    
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
                        game: game,
                        teamName: game.homeTeam,
                        spread: game.homeSpread,
                        isSelected: selectedTeam == .home,
                        teamColors: game.homeTeamColors,
                        score: game.score,
                        isHomeTeam: true,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                globalSelectedTeam = (game.id, .home)
                            }
                            hapticFeedback()
                            onSelect()
                        }
                    )
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 16)
            }
            .background(gradientOverlay)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(cardBorder)
        .shadow(
            color: Color.black.opacity(0.2),
            radius: 10,
            x: 0,
            y: 4
        )
        .lockWarning(for: game)
        .overlay(lockOverlay)
        .opacity(game.shouldBeLocked || game.isLocked ? 0.7 : 1.0)
        .disabled(game.shouldBeLocked || game.isLocked)
        .onTapGesture {
            if !game.shouldBeLocked && !game.isLocked {
                onSelect()
            }
        }
    }
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

// MARK: - Team Button Component
struct TeamButton: View {
    // MARK: - Properties
    let game: Game
    let teamName: String
    let spread: String
    let isSelected: Bool
    let teamColors: TeamColors
    let score: GameScore?
    let isHomeTeam: Bool
    let action: () -> Void
    
    private var displayScore: String? {
        guard let score = score else { return nil }
        return isHomeTeam ? "\(score.homeScore)" : "\(score.awayScore)"
    }
    
    private var isWinningTeam: Bool {
        guard let score = score else { return false }
        if isHomeTeam {
            return score.homeScore > score.awayScore
        } else {
            return score.awayScore > score.homeScore
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Team Name
                Text(teamName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Score or Spread
                if let displayScore = displayScore {
                    // Show actual score
                    HStack(spacing: 4) {
                        Text(displayScore)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(isWinningTeam ? .green : .white)
                        
                        if isWinningTeam {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.yellow)
                        }
                    }
                } else {
                    // Show spread
                    Text(spread)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                createTeamButtonBackground()
            )
            .cornerRadius(12)
            .overlay(
                createTeamButtonBorder()
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func createTeamButtonBackground() -> some View {
        let primaryColor = teamColors.primary
        let secondaryColor = teamColors.secondary
        
        return LinearGradient(
            colors: [
                primaryColor.opacity(isSelected ? 0.8 : 0.6),
                secondaryColor.opacity(isSelected ? 0.6 : 0.4)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func createTeamButtonBorder() -> some View {
        let borderColor = isSelected ? Color.white.opacity(0.4) : Color.clear
        
        return RoundedRectangle(cornerRadius: 12)
            .stroke(borderColor, lineWidth: 2)
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

// MARK: - Preview Provider
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
                return game
            }(),
            isFeatured: false,
            onSelect: {},
            globalSelectedTeam: .constant(nil)
        )
    }
    .padding()
    .background(Color.black)
}
