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
               if game.status == .upcoming {
                   upcomingTimeInfo
               }
           }
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
       
       // MARK: - ENHANCED Teams Section with Stronger Colors
       
       private var enhancedTeamsSection: some View {
           HStack(spacing: 0) {
               // Away Team Side - ENHANCED COLORS
               enhancedAwayTeamSide
               
               // VS Indicator in Center
               vsIndicator
                   .zIndex(1)
               
               // Home Team Side - ENHANCED COLORS
               enhancedHomeTeamSide
           }
       }
       
       private var enhancedAwayTeamSide: some View {
           Button(action: {
               withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                   globalSelectedTeam = (game.id, TeamSelection.away)
               }
               hapticFeedback()
               onSelect()
           }) {
               VStack(spacing: 12) {
                   Text(game.awayTeam)
                       .font(.system(size: 15, weight: .bold))
                       .foregroundColor(.white)
                       .multilineTextAlignment(.center)
                       .lineLimit(2)
                       .minimumScaleFactor(0.8)
                       .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
                   
                   Text(game.awaySpread)
                       .font(.system(size: 18, weight: .bold))
                       .foregroundColor(.white)
                       .padding(.horizontal, 16)
                       .padding(.vertical, 8)
                       .background(enhancedSpreadBackground(for: TeamSelection.away))
                       .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
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
               onSelect()
           }) {
               VStack(spacing: 12) {
                   Text(game.homeTeam)
                       .font(.system(size: 15, weight: .bold))
                       .foregroundColor(.white)
                       .multilineTextAlignment(.center)
                       .lineLimit(2)
                       .minimumScaleFactor(0.8)
                       .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
                   
                   Text(game.homeSpread)
                       .font(.system(size: 18, weight: .bold))
                       .foregroundColor(.white)
                       .padding(.horizontal, 16)
                       .padding(.vertical, 8)
                       .background(enhancedSpreadBackground(for: TeamSelection.home))
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
       
       // MARK: - ENHANCED Spread Background with Team Colors
       
       private func enhancedSpreadBackground(for teamSide: TeamSelection) -> some View {
           let colors = teamSide == TeamSelection.away ? game.awayTeamColors : game.homeTeamColors
           
           return Capsule()
               .fill(
                   LinearGradient(
                       colors: [
                           colors.primary.opacity(0.8),
                           colors.secondary.opacity(0.6)
                       ],
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing
                   )
               )
               .overlay(
                   Capsule()
                       .stroke(Color.white.opacity(0.4), lineWidth: 1)
               )
       }
       
       // MARK: - ENHANCED Team Gradient Background (STRONGER COLORS
       
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
