//
//  GameCard.swift
//  BettorOdds
//
//  Version: 4.2.1 - Enhanced with vibrant team colors, lock icons, and improved status indicators
//  Updated: June 2025
//

import SwiftUI
import UIKit

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
    
    // MARK: - ENHANCED: Status and Time with Lock Indicator
    
    private var statusAndTime: some View {
        HStack(spacing: 6) {
            if game.isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.red)
                
                Text("Locked")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.red)
            } else if game.status == .upcoming {
                Image(systemName: "clock.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(formattedDateTime)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            } else {
                Text(formattedDateTime)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
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
            // Only allow selection if game is not locked
            if !game.isLocked {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    globalSelectedTeam = (game.id, TeamSelection.away)
                }
                hapticFeedback()
                onSelect(game.awayTeam) // Pass selected team name
            } else {
                // Provide feedback that game is locked
                HapticManager.impact(.heavy)
            }
        }) {
            VStack(spacing: 12) {
                Text(game.awayTeam)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
                
                // Clean spread display
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
        .disabled(game.isLocked) // Disable interaction for locked games
    }
    
    private var enhancedHomeTeamSide: some View {
        Button(action: {
            // Only allow selection if game is not locked
            if !game.isLocked {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    globalSelectedTeam = (game.id, TeamSelection.home)
                }
                hapticFeedback()
                onSelect(game.homeTeam) // Pass selected team name
            } else {
                // Provide feedback that game is locked
                HapticManager.impact(.heavy)
            }
        }) {
            VStack(spacing: 12) {
                Text(game.homeTeam)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
                
                // Clean spread display
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
        .disabled(game.isLocked) // Disable interaction for locked games
    }
    
    // MARK: - ENHANCED: VS Indicator with Lock Icon Support
    
    private var vsIndicator: some View {
        Group {
            if game.isLocked {
                // Show lock icon for locked games
                Image(systemName: "lock.fill")
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(lockedIndicatorBackground)
            } else {
                // Show @ for active games
                Text("@")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(vsIndicatorBackground)
            }
        }
    }
    
    // MARK: - NEW: Locked Indicator Background
    
    private var lockedIndicatorBackground: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.red.opacity(0.8),
                        Color.red.opacity(0.6)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
            )
            .shadow(color: Color.red.opacity(0.4), radius: 6, x: 0, y: 3)
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
    
    // MARK: - ENHANCED: More Vibrant Team Gradient Background
    
    var enhancedTeamGradientBackground: some View {
        LinearGradient(
            colors: [
                // ENHANCED COLORS - More vibrant and exciting
                enhanceColor(game.awayTeamColors.primary, saturation: 1.3, brightness: 0.1).opacity(0.95),
                enhanceColor(game.awayTeamColors.primary, saturation: 1.2, brightness: 0.05).opacity(0.85),
                enhanceColor(game.awayTeamColors.secondary, saturation: 1.1, brightness: 0.05).opacity(0.3),
                Color.black.opacity(0.05),  // Lighter for better color visibility
                enhanceColor(game.homeTeamColors.secondary, saturation: 1.1, brightness: 0.05).opacity(0.3),
                enhanceColor(game.homeTeamColors.primary, saturation: 1.2, brightness: 0.05).opacity(0.85),
                enhanceColor(game.homeTeamColors.primary, saturation: 1.3, brightness: 0.1).opacity(0.95)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            // ADD: Subtle vibrant glow overlay for extra excitement
            LinearGradient(
                colors: [
                    enhanceColor(game.awayTeamColors.primary, saturation: 1.1).opacity(0.1),
                    Color.clear,
                    enhanceColor(game.homeTeamColors.primary, saturation: 1.1).opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.overlay)
        )
    }
    
    // MARK: - ENHANCED: More Vibrant Border Overlay
    
    private var enhancedBorderOverlay: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                LinearGradient(
                    colors: [
                        enhanceColor(game.awayTeamColors.primary, saturation: 1.4, brightness: 0.2).opacity(0.8),
                        Color.primary.opacity(isFeatured ? 0.9 : 0.6),
                        enhanceColor(game.homeTeamColors.primary, saturation: 1.4, brightness: 0.2).opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: isFeatured ? 2.5 : 1.5  // Slightly thicker borders for more presence
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
    
    /// Enhances a color by adjusting saturation and brightness
    /// Returns a proper Color object (not a View)
    private func enhanceColor(_ color: Color, saturation: Double = 1.0, brightness: Double = 0.0) -> Color {
        // Convert Color to RGB components
        let uiColor = UIColor(color)
        var hue: CGFloat = 0
        var saturationValue: CGFloat = 0
        var brightnessValue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturationValue, brightness: &brightnessValue, alpha: &alpha)
        
        // Apply enhancements
        let newSaturation = min(1.0, saturationValue * saturation)
        let newBrightness = min(1.0, brightnessValue + brightness)
        
        return Color(
            hue: Double(hue),
            saturation: Double(newSaturation),
            brightness: Double(newBrightness),
            opacity: Double(alpha)
        )
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
