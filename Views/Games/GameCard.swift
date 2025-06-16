//
//  GameCard.swift
//  BettorOdds
//
//  Version: 3.0.0 - Fixed spread capsules, diagonal gradients, and team preselection
//  Updated: June 2025
//

import SwiftUI

struct GameCard: View {
    // MARK: - Properties
    let game: Game
    let isFeatured: Bool
    let onSelect: (String?) -> Void  // Updated to pass selected team
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

    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            headerSection
                .padding(.horizontal, 16)
                .padding(.top, 16)
            
            // Teams Section with ENHANCED GRADIENTS
            enhancedTeamsSection
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                .padding(.top, 12)
        }
        .background(enhancedTeamGradientBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(enhancedBorderOverlay)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
        .scaleEffect(isFeatured ? 1.02 : 1.0)
        .opacity(gameOpacity)
        .disabled(game.shouldBeLocked || game.isLocked)
        .onTapGesture {
            if !game.shouldBeLocked && !game.isLocked {
                onSelect(nil) // No specific team selected
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            leagueBadge
            Spacer()
            statusAndTime
        }
    }
    
    private var leagueBadge: some View {
        Text(game.league)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(leagueBadgeBackground)
    }
    
    private var leagueBadgeBackground: some View {
        Capsule()
            .fill(Color.white.opacity(0.15))
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
    }
    
    private var statusAndTime: some View {
        HStack(spacing: 6) {
            if game.status == .upcoming {
                Image(systemName: "clock.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Text(formattedDateTime)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
    }
    
    // MARK: - Enhanced Teams Section
    
    private var enhancedTeamsSection: some View {
        HStack(spacing: 16) {
            enhancedAwayTeamSide
            vsIndicator
            enhancedHomeTeamSide
        }
    }
    
    private var enhancedAwayTeamSide: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                globalSelectedTeam = (game.id, TeamSelection.away)
            }
            hapticFeedback()
            onSelect(game.awayTeam) // Pass selected team name
        }) {
            VStack(spacing: 12) {
                Text(game.awayTeam)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
                
                // FIXED: No capsule background - just clean text
                Text(game.awaySpread)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(selectedTeam == TeamSelection.away ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedTeam == TeamSelection.away)
    }
    
    private var enhancedHomeTeamSide: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                globalSelectedTeam = (game.id, TeamSelection.home)
            }
            hapticFeedback()
            onSelect(game.homeTeam) // Pass selected team name
        }) {
            VStack(spacing: 12) {
                Text(game.homeTeam)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
                
                // FIXED: No capsule background - just clean text
                Text(game.homeSpread)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(selectedTeam == TeamSelection.home ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedTeam == TeamSelection.home)
    }
    
    private var vsIndicator: some View {
        Text("@")
            .font(.system(size: 18, weight: .black))
            .foregroundColor(.white)
            .frame(width: 36, height: 36)
            .background(vsIndicatorBackground)
    }
    
    private var vsIndicatorBackground: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.7),
                        Color.black.opacity(0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 3)
    }
    
    // MARK: - FIXED: Enhanced Team Gradient Background (DIAGONAL)
    
    var enhancedTeamGradientBackground: some View {
        LinearGradient(
            colors: [
                // DIAGONAL gradient from top-left to bottom-right
                game.awayTeamColors.primary.opacity(0.95),
                game.awayTeamColors.primary.opacity(0.85),
                game.awayTeamColors.secondary.opacity(0.3),
                Color.black.opacity(0.1),
                game.homeTeamColors.secondary.opacity(0.3),
                game.homeTeamColors.primary.opacity(0.85),
                game.homeTeamColors.primary.opacity(0.95)
            ],
            startPoint: .topLeading,  // FIXED: Diagonal gradient
            endPoint: .bottomTrailing // FIXED: Diagonal gradient
        )
    }
    
    // MARK: - Enhanced Border Overlay
    
    private var enhancedBorderOverlay: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                LinearGradient(
                    colors: [
                        game.awayTeamColors.primary.opacity(0.6),
                        Color.primary.opacity(isFeatured ? 0.7 : 0.4),
                        game.homeTeamColors.primary.opacity(0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: isFeatured ? 2 : 1
            )
    }
    
    // MARK: - Styling Properties
    
    private var shadowColor: Color {
        if isFeatured {
            return Color.primary.opacity(0.4)
        } else {
            return Color.black.opacity(0.3)
        }
    }
    
    private var shadowRadius: CGFloat {
        isFeatured ? 15 : 10
    }
    
    private var shadowY: CGFloat {
        isFeatured ? 8 : 5
    }
    
    private var gameOpacity: Double {
        game.shouldBeLocked || game.isLocked ? 0.7 : 1.0
    }
    
    // MARK: - Helper Methods
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        GameCard(
            game: Game.sampleGames[0],
            isFeatured: true,
            onSelect: { selectedTeam in
                print("Selected team: \(selectedTeam ?? "none")")
            },
            globalSelectedTeam: .constant(nil)
        )
        
        GameCard(
            game: Game.sampleGames[1],
            isFeatured: false,
            onSelect: { selectedTeam in
                print("Selected team: \(selectedTeam ?? "none")")
            },
            globalSelectedTeam: .constant((Game.sampleGames[1].id, TeamSelection.home))
        )
    }
    .padding()
    .background(
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.13, blue: 0.15),
                Color(red: 0.13, green: 0.23, blue: 0.26),
                Color(red: 0.17, green: 0.33, blue: 0.39)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
