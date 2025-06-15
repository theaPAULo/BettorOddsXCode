//
//  GameCard.swift
//  BettorOdds
//
//  Version: 2.8.0 - No rectangle overlays, vibrant team gradients
//  Updated: June 2025
//

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

    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            headerSection
                .padding(.horizontal, 16)
                .padding(.top, 16)
            
            // Teams Section - NO RECTANGLES, just gradients
            vibrantTeamsSection
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                .padding(.top, 12)
        }
        .background(vibrantTeamGradientBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(enhancedBorderOverlay)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
        .scaleEffect(isFeatured ? 1.02 : 1.0)
        .opacity(gameOpacity)
        .disabled(game.shouldBeLocked || game.isLocked)
        .onTapGesture {
            if !game.shouldBeLocked && !game.isLocked {
                onSelect()
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
            if isFeatured {
                featuredBadge
            }
            
            if game.status == .upcoming {
                upcomingTimeInfo
            }
        }
    }
    
    private var featuredBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 10))
                .foregroundColor(.yellow)
            Text("Featured")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(featuredBadgeBackground)
    }
    
    private var featuredBadgeBackground: some View {
        Capsule()
            .fill(Color.primary.opacity(0.8))
    }
    
    private var upcomingTimeInfo: some View {
        VStack(spacing: 2) {
            Text("UPCOMING")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color.primary)
                .tracking(1)
            
            Text(formattedDateTime)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
    }
    
    // MARK: - VIBRANT Teams Section (NO RECTANGLES)
    
    private var vibrantTeamsSection: some View {
        HStack(spacing: 0) {
            // Away Team Side - CLEAN, no rectangles
            awayTeamSideClean
            
            // VS Indicator in Center
            vsIndicator
                .zIndex(1)
            
            // Home Team Side - CLEAN, no rectangles
            homeTeamSideClean
        }
    }
    
    private var awayTeamSideClean: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                globalSelectedTeam = (game.id, TeamSelection.away)
            }
            hapticFeedback()
            onSelect()
        }) {
            VStack(spacing: 12) {
                // Team name - NO RECTANGLE BACKGROUND
                Text(game.awayTeam)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
                
                // Spread - CLEAN capsule design
                Text(game.awaySpread)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(vibrantSpreadBackground(for: TeamSelection.away))
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(selectedTeam == TeamSelection.away ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedTeam == TeamSelection.away)
    }
    
    private var homeTeamSideClean: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                globalSelectedTeam = (game.id, TeamSelection.home)
            }
            hapticFeedback()
            onSelect()
        }) {
            VStack(spacing: 12) {
                // Team name - NO RECTANGLE BACKGROUND
                Text(game.homeTeam)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
                
                // Spread - CLEAN capsule design
                Text(game.homeSpread)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(vibrantSpreadBackground(for: TeamSelection.home))
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
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
    
    // MARK: - VIBRANT Spread Background (Clean Capsules)
    
    private func vibrantSpreadBackground(for teamSide: TeamSelection) -> some View {
        let colors = teamSide == TeamSelection.away ? game.awayTeamColors : game.homeTeamColors
        let isSelected = selectedTeam == teamSide
        
        return Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        // MUCH MORE VIBRANT - increased opacity and saturation
                        colors.primary.opacity(isSelected ? 0.95 : 0.8),
                        colors.secondary.opacity(isSelected ? 0.85 : 0.7)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(isSelected ? 0.8 : 0.4), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(
                color: colors.primary.opacity(isSelected ? 0.6 : 0.3),
                radius: isSelected ? 6 : 3,
                x: 0,
                y: isSelected ? 3 : 2
            )
    }
    
    // MARK: - VIBRANT Background Gradients
    
    private var vibrantTeamGradientBackground: some View {
        ZStack {
            // Base card background - deeper, richer
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.4),
                            Color.black.opacity(0.3)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // VIBRANT team colors that flow across the entire card
            LinearGradient(
                colors: [
                    // MUCH MORE VIBRANT - increased opacity and saturation
                    game.awayTeamColors.primary.opacity(0.7),
                    game.awayTeamColors.secondary.opacity(0.5),
                    Color.clear,
                    game.homeTeamColors.secondary.opacity(0.5),
                    game.homeTeamColors.primary.opacity(0.7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Enhanced glass effect overlay
            LinearGradient(
                colors: [
                    Color.white.opacity(0.15),
                    Color.clear,
                    Color.white.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var enhancedBorderOverlay: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.primary.opacity(isFeatured ? 0.9 : 0.6),
                        game.awayTeamColors.primary.opacity(0.5),
                        Color.primary.opacity(isFeatured ? 0.7 : 0.4),
                        game.homeTeamColors.primary.opacity(0.5),
                        Color.primary.opacity(isFeatured ? 0.9 : 0.6)
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
            onSelect: {},
            globalSelectedTeam: .constant(nil)
        )
        
        GameCard(
            game: Game.sampleGames[1],
            isFeatured: false,
            onSelect: {},
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
