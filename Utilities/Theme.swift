//
//  EnhancedTheme.swift
//  BettorOdds
//
//  Created by Claude on 6/13/25
//  Version: 1.0.0 - Modern UI theme with vibrant teal branding
//

import SwiftUI

// MARK: - Enhanced App Theme

struct AppTheme {
    
    // MARK: - Colors
    
    struct Colors {
        // Primary brand colors
        static let primary = Color(red: 0.0, green: 0.84, blue: 0.84) // Vibrant teal
        static let primaryDark = Color(red: 0.0, green: 0.7, blue: 0.7)
        static let primaryLight = Color(red: 0.2, green: 0.9, blue: 0.9)
        
        // Background colors
        static let background = Color(red: 0.067, green: 0.133, blue: 0.133) // Dark teal
        static let backgroundSecondary = Color(red: 0.1, green: 0.2, blue: 0.2)
        static let backgroundTertiary = Color(red: 0.15, green: 0.25, blue: 0.25)
        
        // Card and surface colors
        static let cardBackground = Color(red: 0.12, green: 0.22, blue: 0.22)
        static let cardBackgroundElevated = Color(red: 0.15, green: 0.25, blue: 0.25)
        
        // Text colors
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.7)
        static let textTertiary = Color.white.opacity(0.5)
        
        // Coin colors
        static let yellowCoin = Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
        static let greenCoin = Color(red: 0.2, green: 0.9, blue: 0.4) // Bright green
        
        // Status colors
        static let success = Color(red: 0.2, green: 0.9, blue: 0.4)
        static let warning = Color(red: 1.0, green: 0.6, blue: 0.0)
        static let error = Color(red: 1.0, green: 0.3, blue: 0.3)
        static let pending = Color(red: 1.0, green: 0.8, blue: 0.0)
        
        // Interactive states
        static let buttonBackground = Color(red: 0.0, green: 0.84, blue: 0.84)
        static let buttonBackgroundPressed = Color(red: 0.0, green: 0.7, blue: 0.7)
        static let buttonBackgroundDisabled = Color.gray.opacity(0.3)
        
        // League selection (reduced glow)
        static let leagueSelected = Color(red: 0.0, green: 0.84, blue: 0.84).opacity(0.6)
        static let leagueUnselected = Color.gray.opacity(0.3)
    }
    
    // MARK: - Typography
    
    struct Typography {
        // App title (modern, playful)
        static let appTitle = Font.custom("Avenir Next", size: 32)
            .weight(.bold)
        
        // Headers
        static let largeTitle = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title1 = Font.system(size: 24, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 18, weight: .medium, design: .rounded)
        
        // Body text
        static let body = Font.system(size: 16, weight: .regular, design: .default)
        static let bodyEmphasized = Font.system(size: 16, weight: .semibold, design: .default)
        static let callout = Font.system(size: 15, weight: .medium, design: .default)
        
        // Small text
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
        static let footnote = Font.system(size: 11, weight: .regular, design: .default)
        
        // Interactive elements
        static let button = Font.system(size: 16, weight: .semibold, design: .rounded)
        static let buttonLarge = Font.system(size: 18, weight: .bold, design: .rounded)
        
        // Numbers and amounts
        static let amount = Font.system(size: 20, weight: .bold, design: .monospaced)
        static let amountLarge = Font.system(size: 28, weight: .bold, design: .monospaced)
    }
    
    // MARK: - Spacing
    
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 24
        static let pill: CGFloat = 999 // For pill-shaped buttons
    }
    
    // MARK: - Shadows
    
    struct Shadow {
        static let small = (
            color: Color.black.opacity(0.1),
            radius: CGFloat(4),
            x: CGFloat(0),
            y: CGFloat(2)
        )
        
        static let medium = (
            color: Color.black.opacity(0.15),
            radius: CGFloat(8),
            x: CGFloat(0),
            y: CGFloat(4)
        )
        
        static let large = (
            color: Color.black.opacity(0.2),
            radius: CGFloat(16),
            x: CGFloat(0),
            y: CGFloat(8)
        )
    }
    
    // MARK: - Animation
    
    struct Animation {
        // Performance-optimized animations
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        
        // Spring animations for interactive elements
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let springQuick = SwiftUI.Animation.spring(response: 0.2, dampingFraction: 0.9)
        
        // Bounce for success states
        static let bounce = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.6)
    }
}

// MARK: - View Extensions for Easy Theme Access

extension View {
    func primaryButtonStyle() -> some View {
        self
            .font(AppTheme.Typography.button)
            .foregroundColor(.white)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(AppTheme.Colors.buttonBackground)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .shadow(
                color: AppTheme.Shadow.medium.color,
                radius: AppTheme.Shadow.medium.radius,
                x: AppTheme.Shadow.medium.x,
                y: AppTheme.Shadow.medium.y
            )
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .font(AppTheme.Typography.button)
            .foregroundColor(AppTheme.Colors.primary)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(AppTheme.Colors.primary, lineWidth: 1)
            )
    }
    
    func cardStyle() -> some View {
        self
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.large)
            .shadow(
                color: AppTheme.Shadow.medium.color,
                radius: AppTheme.Shadow.medium.radius,
                x: AppTheme.Shadow.medium.x,
                y: AppTheme.Shadow.medium.y
            )
    }
    
    func elevatedCardStyle() -> some View {
        self
            .background(AppTheme.Colors.cardBackgroundElevated)
            .cornerRadius(AppTheme.CornerRadius.large)
            .shadow(
                color: AppTheme.Shadow.large.color,
                radius: AppTheme.Shadow.large.radius,
                x: AppTheme.Shadow.large.x,
                y: AppTheme.Shadow.large.y
            )
    }
    
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: style)
            impactFeedback.impactOccurred()
        }
    }
}

// MARK: - Haptic Feedback Helper

struct HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
    
    static func selection() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(type)
    }
}

// MARK: - Win/Loss Streak Display Component

struct StreakIndicator: View {
    let wins: Int
    let losses: Int
    let isCompact: Bool
    
    init(wins: Int, losses: Int, isCompact: Bool = false) {
        self.wins = wins
        self.losses = losses
        self.isCompact = isCompact
    }
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            if !isCompact {
                Text("🔥")
                    .font(.caption)
            }
            
            Text("\(wins)W")
                .font(isCompact ? AppTheme.Typography.caption : AppTheme.Typography.callout)
                .foregroundColor(AppTheme.Colors.success)
                .fontWeight(.semibold)
            
            Text("•")
                .font(.caption)
                .foregroundColor(AppTheme.Colors.textTertiary)
            
            Text("\(losses)L")
                .font(isCompact ? AppTheme.Typography.caption : AppTheme.Typography.callout)
                .foregroundColor(AppTheme.Colors.error)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(AppTheme.Colors.cardBackground.opacity(0.6))
        .cornerRadius(AppTheme.CornerRadius.pill)
    }
}
