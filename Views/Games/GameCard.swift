//
//  GameCard.swift
//  BettorOdds
//
//  Version: 2.7.0 - Enhanced team color gradients (No conflicts)
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
            
            // Teams Section with Integrated Gradients
            enhancedTeamsSection
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                .padding(.top, 12)
        }
        .background(integratedTeamGradientBackground)
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
    
    // MARK: - Enhanced Teams Section with Integrated Colors
    
    private var enhancedTeamsSection: some View {
        HStack(spacing: 0) {
            // Away Team Side with Blended Gradient
            awayTeamSide
            
            // VS Indicator in Center
            vsIndicator
                .zIndex(1)
            
            // Home Team Side with Blended Gradient
            homeTeamSide
        }
    }
    
    private var awayTeamSide: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                globalSelectedTeam = (game.id, TeamSelection.away)
            }
            hapticFeedback()
            onSelect()
        }) {
            VStack(spacing: 10) {
                teamNameText(game.awayTeam)
                spreadDisplay(game.awaySpread, teamSide: TeamSelection.away)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(awayTeamGradientBackground)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 12,
                    bottomLeadingRadius: 12,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(selectedTeam == TeamSelection.away ? 1.03 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedTeam == TeamSelection.away)
    }
    
    private var homeTeamSide: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                globalSelectedTeam = (game.id, TeamSelection.home)
            }
            hapticFeedback()
            onSelect()
        }) {
            VStack(spacing: 10) {
                teamNameText(game.homeTeam)
                spreadDisplay(game.homeSpread, teamSide: TeamSelection.home)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(homeTeamGradientBackground)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 12,
                    topTrailingRadius: 12
                )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(selectedTeam == TeamSelection.home ? 1.03 : 1.0)
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
                        Color.black.opacity(0.6),
                        Color.black.opacity(0.4)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Helper Views
    
    private func teamNameText(_ name: String) -> some View {
        Text(name)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
            .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
    }
    
    private func spreadDisplay(_ spread: String, teamSide: TeamSelection) -> some View {
        Text(spread)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(spreadDisplayBackground(for: teamSide))
    }
    
    private func spreadDisplayBackground(for teamSide: TeamSelection) -> some View {
        let colors = teamSide == TeamSelection.away ? game.awayTeamColors : game.homeTeamColors
        let isSelected = selectedTeam == teamSide
        
        return Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        colors.primary.opacity(isSelected ? 0.8 : 0.4),
                        colors.secondary.opacity(isSelected ? 0.6 : 0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(isSelected ? 0.6 : 0.2), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(
                color: colors.primary.opacity(isSelected ? 0.4 : 0.1),
                radius: isSelected ? 4 : 2,
                x: 0,
                y: isSelected ? 2 : 1
            )
    }
    
    // MARK: - Enhanced Background Gradients (INTEGRATED TEAM COLORS)
    
    private var integratedTeamGradientBackground: some View {
        ZStack {
            // Base card background
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.3),
                            Color.black.opacity(0.2)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // Integrated team colors that blend naturally into the card
            LinearGradient(
                colors: [
                    game.awayTeamColors.primary.opacity(0.4),
                    game.awayTeamColors.secondary.opacity(0.3),
                    Color.clear,
                    game.homeTeamColors.secondary.opacity(0.3),
                    game.homeTeamColors.primary.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Glass effect overlay
            LinearGradient(
                colors: [
                    Color.white.opacity(0.1),
                    Color.clear,
                    Color.white.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var awayTeamGradientBackground: some View {
        LinearGradient(
            colors: [
                game.awayTeamColors.primary.opacity(selectedTeam == TeamSelection.away ? 0.8 : 0.5),
                game.awayTeamColors.secondary.opacity(selectedTeam == TeamSelection.away ? 0.6 : 0.3),
                game.awayTeamColors.primary.opacity(selectedTeam == TeamSelection.away ? 0.4 : 0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            // Selection indicator
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    selectedTeam == TeamSelection.away ? Color.white.opacity(0.6) : Color.clear,
                    lineWidth: 2
                )
        )
    }
    
    private var homeTeamGradientBackground: some View {
        LinearGradient(
            colors: [
                game.homeTeamColors.primary.opacity(selectedTeam == TeamSelection.home ? 0.8 : 0.5),
                game.homeTeamColors.secondary.opacity(selectedTeam == TeamSelection.home ? 0.6 : 0.3),
                game.homeTeamColors.primary.opacity(selectedTeam == TeamSelection.home ? 0.4 : 0.2)
            ],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
        .overlay(
            // Selection indicator
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    selectedTeam == TeamSelection.home ? Color.white.opacity(0.6) : Color.clear,
                    lineWidth: 2
                )
        )
    }
    
    private var enhancedBorderOverlay: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.primary.opacity(isFeatured ? 0.8 : 0.4),
                        game.awayTeamColors.primary.opacity(0.3),
                        Color.primary.opacity(isFeatured ? 0.6 : 0.3),
                        game.homeTeamColors.primary.opacity(0.3),
                        Color.primary.opacity(isFeatured ? 0.8 : 0.4)
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
            return Color.primary.opacity(0.3)
        } else {
            return Color.black.opacity(0.2)
        }
    }
    
    private var shadowRadius: CGFloat {
        isFeatured ? 12 : 8
    }
    
    private var shadowY: CGFloat {
        isFeatured ? 6 : 4
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
