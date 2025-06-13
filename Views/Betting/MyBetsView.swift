//
//  Enhanced My Bets and Profile Screen Updates
//  BettorOdds
//
//  Created by Claude on 6/13/25
//  Version: 1.0.0 - Quick fixes for title alignment and profile cleanup
//

import SwiftUI

// MARK: - Enhanced My Bets View

struct EnhancedMyBetsView: View {
    @StateObject private var viewModel = MyBetsViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Fixed header with proper title positioning
                    VStack(spacing: AppTheme.Spacing.lg) {
                        // Title (properly positioned)
                        HStack {
                            Text("My Bets")
                                .font(AppTheme.Typography.largeTitle)
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                            Spacer()
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.top, AppTheme.Spacing.md)
                        
                        // Segmented Control
                        Picker("Bet Filter", selection: $selectedTab) {
                            Text("Active").tag(0)
                            Text("Completed").tag(1)
                            Text("All").tag(2)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal, AppTheme.Spacing.md)
                    }
                    .background(AppTheme.Colors.background)
                    
                    // Content
                    ScrollView {
                        LazyVStack(spacing: AppTheme.Spacing.md) {
                            ForEach(filteredBets) { bet in
                                EnhancedBetCard(bet: bet)
                                    .cardStyle()
                            }
                        }
                        .padding(AppTheme.Spacing.md)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private var filteredBets: [Bet] {
        // TODO: Filter based on selectedTab
        return viewModel.bets
    }
}

// MARK: - Enhanced Bet Card

struct EnhancedBetCard: View {
    let bet: Bet
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Header with status and date
            HStack {
                // Status badge
                Text(bet.status.rawValue)
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(bet.status.color)
                    .cornerRadius(AppTheme.CornerRadius.small)
                
                Spacer()
                
                Text(bet.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            // Team and spread
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(bet.team)
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                
                Text("Spread: \(bet.initialSpread > 0 ? "+" : "")\(bet.initialSpread, specifier: "%.1f")")
                    .font(AppTheme.Typography.callout)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            // Bet details
            HStack {
                VStack(alignment: .leading) {
                    Text("Bet Amount")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Text(bet.coinType.emoji)
                        Text("\(bet.amount)")
                            .font(AppTheme.Typography.amount)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Potential Win")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Text("\(bet.potentialWinnings)")
                        .font(AppTheme.Typography.amount)
                        .foregroundColor(AppTheme.Colors.success)
                        .fontWeight(.bold)
                }
            }
            
            // Cancel button for pending bets
            if bet.canBeCancelled {
                Button(action: {
                    // TODO: Implement cancel bet
                    HapticManager.impact(.light)
                }) {
                    Text("Cancel Bet")
                        .font(AppTheme.Typography.callout)
                        .foregroundColor(AppTheme.Colors.error)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(AppTheme.Colors.error.opacity(0.1))
                        .cornerRadius(AppTheme.CornerRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                .stroke(AppTheme.Colors.error.opacity(0.3), lineWidth: 1)
                        )
                }
                .hapticFeedback(.light)
            }
        }
        .padding(AppTheme.Spacing.md)
    }
}

// MARK: - Enhanced Profile View

struct EnhancedProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.xl) {
                        // Profile Header (removed overlapping text)
                        profileHeader
                        
                        // Balance Cards
                        balanceSection
                        
                        // Menu Items
                        menuSection
                    }
                    .padding(AppTheme.Spacing.md)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Profile Header (Clean, no overlapping text)
    
    private var profileHeader: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Profile Avatar (no overlapping text!)
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.primary)
                    .frame(width: 80, height: 80)
                
                if let user = authViewModel.user {
                    Text(String(user.displayName?.prefix(1) ?? "U"))
                        .font(AppTheme.Typography.largeTitle)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                } else {
                    Image(systemName: "person.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                }
            }
            
            // User Info
            VStack(spacing: AppTheme.Spacing.xs) {
                if let user = authViewModel.user {
                    Text(user.displayName ?? "User")
                        .font(AppTheme.Typography.title2)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: user.authProvider == "google.com" ? "globe" : "applelogo")
                            .foregroundColor(AppTheme.Colors.primary)
                        Text("\(user.authProvider == "google.com" ? "Google" : "Apple") Account")
                            .font(AppTheme.Typography.callout)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Text("Member since \(user.dateJoined.formatted(date: .abbreviated, time: .omitted))")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }
            
            // Win/Loss Streak (bigger on profile)
            if let user = authViewModel.user {
                StreakIndicator(wins: 8, losses: 3) // TODO: Get real data
                    .scaleEffect(1.1)
            }
        }
    }
    
    // MARK: - Balance Section
    
    private var balanceSection: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Play Coins
            VStack(spacing: AppTheme.Spacing.sm) {
                HStack {
                    Text("💛")
                        .font(.title)
                    Text("\(authViewModel.user?.yellowCoins ?? 0)")
                        .font(AppTheme.Typography.amountLarge)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                }
                Text("Play Coins")
                    .font(AppTheme.Typography.callout)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(AppTheme.Spacing.lg)
            .cardStyle()
            
            // Real Coins
            VStack(spacing: AppTheme.Spacing.sm) {
                HStack {
                    Text("💚")
                        .font(.title)
                    Text("\(authViewModel.user?.greenCoins ?? 0)")
                        .font(AppTheme.Typography.amountLarge)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                }
                Text("Real Coins")
                    .font(AppTheme.Typography.callout)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(AppTheme.Spacing.lg)
            .cardStyle()
        }
    }
    
    // MARK: - Menu Section
    
    private var menuSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Buy Coins
            ProfileMenuItem(
                icon: "dollarsign.circle.fill",
                title: "Buy Coins",
                iconColor: AppTheme.Colors.yellowCoin
            ) {
                // TODO: Navigate to purchase
            }
            
            // Transaction History
            ProfileMenuItem(
                icon: "clock.fill",
                title: "Transaction History",
                iconColor: AppTheme.Colors.primary
            ) {
                // TODO: Navigate to history
            }
            
            // Settings
            ProfileMenuItem(
                icon: "gearshape.fill",
                title: "Settings",
                iconColor: AppTheme.Colors.textSecondary
            ) {
                // TODO: Navigate to settings
            }
            
            // Sign Out
            ProfileMenuItem(
                icon: "rectangle.portrait.and.arrow.right.fill",
                title: "Sign Out",
                iconColor: AppTheme.Colors.error,
                isDestructive: true
            ) {
                authViewModel.signOut()
            }
        }
    }
}

// MARK: - Profile Menu Item

struct ProfileMenuItem: View {
    let icon: String
    let title: String
    let iconColor: Color
    let isDestructive: Bool
    let action: () -> Void
    
    init(icon: String, title: String, iconColor: Color, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.iconColor = iconColor
        self.isDestructive = isDestructive
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            HapticManager.impact(.light)
            action()
        }) {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 24)
                
                Text(title)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(isDestructive ? AppTheme.Colors.error : .white)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            .padding(AppTheme.Spacing.lg)
        }
        .cardStyle()
    }
}

// MARK: - Placeholder MyBetsViewModel

class MyBetsViewModel: ObservableObject {
    @Published var bets: [Bet] = []
    
    // TODO: Implement real bet fetching
}
