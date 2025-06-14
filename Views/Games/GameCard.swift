//
//  GameCard.swift
//  BettorOdds
//
//  Version: 2.5.0 - Simplified to fix compiler timeout issues
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

    var body: some View {
        VStack(spacing: 0) {
            // Main Card Content
            cardContent
        }
        .background(teamGradientBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(borderOverlay)
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
    
    // MARK: - Card Content (Broken down to avoid complex expressions)
    
    private var cardContent: some View {
        VStack(spacing: 0) {
            headerSection
            teamsSection
        }
    }
    
    private var headerSection: some View {
        HStack {
            leagueBadge
            Spacer()
            statusAndTime
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
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
    
    private var teamsSection: some View {
        HStack(spacing: 12) {
            awayTeamButton
            vsIndicator
            homeTeamButton
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
        .padding(.top, 12)
    }
    
    private var awayTeamButton: some View {
        teamButton(
            name: game.awayTeam,
            spread: game.awaySpread,
            colors: game.awayTeamColors,
            isSelected: selectedTeam == .away,
            isHome: false
        )
    }
    
    private var homeTeamButton: some View {
        teamButton(
            name: game.homeTeam,
            spread: game.homeSpread,
            colors: game.homeTeamColors,
            isSelected: selectedTeam == .home,
            isHome: true
        )
    }
    
    private var vsIndicator: some View {
        Text("@")
            .font(.system(size: 20, weight: .black))
            .foregroundColor(.white)
            .frame(width: 32, height: 32)
            .background(vsIndicatorBackground)
    }
    
    private var vsIndicatorBackground: some View {
        Circle()
            .fill(Color.black.opacity(0.3))
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
    }
    
    // MARK: - Team Button
    
    private func teamButton(name: String, spread: String, colors: TeamColors, isSelected: Bool, isHome: Bool) -> some View {
        Button(action: {
            let selection: TeamSelection = isHome ? .home : .away
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                globalSelectedTeam = (game.id, selection)
            }
            hapticFeedback()
            onSelect()
        }) {
            VStack(spacing: 10) {
                teamNameText(name)
                spreadDisplay(spread, colors: colors)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(teamButtonBackground(colors: colors, isSelected: isSelected))
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
    
    private func teamNameText(_ name: String) -> some View {
        Text(name)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
    }
    
    private func spreadDisplay(_ spread: String, colors: TeamColors) -> some View {
        Text(spread)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(spreadDisplayBackground)
    }
    
    private var spreadDisplayBackground: some View {
        Capsule()
            .fill(Color.white.opacity(0.1))
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
    
    private func teamButtonBackground(colors: TeamColors, isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(teamButtonGradient(colors: colors, isSelected: isSelected))
            .overlay(teamButtonBorder(isSelected: isSelected))
            .shadow(
                color: colors.primary.opacity(isSelected ? 0.3 : 0.1),
                radius: isSelected ? 6 : 2,
                x: 0,
                y: isSelected ? 3 : 1
            )
    }
    
    private func teamButtonGradient(colors: TeamColors, isSelected: Bool) -> LinearGradient {
        LinearGradient(
            colors: [
                colors.primary.opacity(isSelected ? 0.9 : 0.6),
                colors.secondary.opacity(isSelected ? 0.7 : 0.4)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func teamButtonBorder(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                isSelected ? Color.white.opacity(0.6) : Color.white.opacity(0.1),
                lineWidth: isSelected ? 2 : 1
            )
    }
    
    // MARK: - Background and Styling (Simplified)
    
    private var teamGradientBackground: LinearGradient {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: game.awayTeamColors.primary.opacity(0.95), location: 0.0),
                .init(color: game.awayTeamColors.secondary.opacity(0.8), location: 0.3),
                .init(color: game.homeTeamColors.secondary.opacity(0.8), location: 0.7),
                .init(color: game.homeTeamColors.primary.opacity(0.95), location: 1.0)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 18)
            .stroke(borderGradient, lineWidth: 2)
    }
    
    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.primary.opacity(0.8),
                game.awayTeamColors.primary.opacity(0.4),
                Color.primary.opacity(0.6),
                game.homeTeamColors.primary.opacity(0.4),
                Color.primary.opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var shadowColor: Color {
        Color.black.opacity(isFeatured ? 0.3 : 0.2)
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
            globalSelectedTeam: .constant((Game.sampleGames[1].id, .home))
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
