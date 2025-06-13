//
//  Enhanced GamesView.swift
//  BettorOdds
//
//  Created by Claude on 6/13/25
//  Version: 2.0.0 - Modern UI with vibrant design and animations
//

import SwiftUI

struct EnhancedGamesView: View {
    @StateObject private var viewModel = GamesViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var selectedLeague = "NBA"
    @State private var showBetModal = false
    @State private var selectedGame: Game?
    
    // Animation states
    @State private var headerOffset: CGFloat = 0
    @State private var cardsAppeared = false
    
    var body: some View {
        ZStack {
            // Background gradient
            AppTheme.Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.lg) {
                    // Header Section
                    headerSection
                        .offset(y: headerOffset)
                    
                    // Featured Game Card
                    if let featuredGame = viewModel.featuredGame {
                        featuredGameCard(featuredGame)
                            .scaleEffect(cardsAppeared ? 1.0 : 0.95)
                            .opacity(cardsAppeared ? 1.0 : 0.0)
                            .animation(AppTheme.Animation.spring.delay(0.1), value: cardsAppeared)
                    }
                    
                    // Upcoming Games Section
                    upcomingGamesSection
                        .scaleEffect(cardsAppeared ? 1.0 : 0.95)
                        .opacity(cardsAppeared ? 1.0 : 0.0)
                        .animation(AppTheme.Animation.spring.delay(0.2), value: cardsAppeared)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.xl)
            }
            .refreshable {
                await viewModel.refreshGames()
                HapticManager.impact(.light)
            }
        }
        .onAppear {
            withAnimation(AppTheme.Animation.spring) {
                cardsAppeared = true
            }
        }
        .errorHandling(viewModel: viewModel)
        .fullScreenCover(isPresented: $showBetModal) {
            if let game = selectedGame {
                EnhancedBetModalView(
                    game: game,
                    user: authViewModel.user ?? User(id: "", authProvider: ""),
                    isPresented: $showBetModal
                )
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // App Title with modern font
            HStack {
                Text("BettorOdds")
                    .font(AppTheme.Typography.appTitle)
                    .foregroundColor(AppTheme.Colors.primary)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Win/Loss Streak Indicator
                if let user = authViewModel.user {
                    StreakIndicator(wins: 5, losses: 2) // TODO: Get real data from user
                        .scaleEffect(cardsAppeared ? 1.0 : 0.8)
                        .opacity(cardsAppeared ? 1.0 : 0.0)
                        .animation(AppTheme.Animation.spring.delay(0.3), value: cardsAppeared)
                }
            }
            
            // Balance Display
            balanceSection
            
            // League Selector (Fixed glow issue)
            leagueSelector
        }
    }
    
    // MARK: - Balance Section
    
    private var balanceSection: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Yellow Coins
            BalanceCard(
                emoji: "💛",
                amount: authViewModel.user?.yellowCoins ?? 0,
                label: "Play Coins",
                color: AppTheme.Colors.yellowCoin
            )
            
            // Green Coins
            BalanceCard(
                emoji: "💚",
                amount: authViewModel.user?.greenCoins ?? 0,
                label: "Real Coins",
                color: AppTheme.Colors.greenCoin
            )
            
            // Daily Limit Progress
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("Daily Limit")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                ProgressView(
                    value: Double(authViewModel.user?.dailyGreenCoinsUsed ?? 0),
                    total: Double(Configuration.Settings.dailyGreenCoinLimit)
                )
                .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.Colors.greenCoin))
                .frame(height: 4)
                
                Text("💚 \(authViewModel.user?.dailyGreenCoinsUsed ?? 0)/\(Configuration.Settings.dailyGreenCoinLimit)")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - League Selector (Fixed Glow)
    
    private var leagueSelector: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ForEach(["NBA", "NFL"], id: \.self) { league in
                Button(action: {
                    HapticManager.selection()
                    withAnimation(AppTheme.Animation.springQuick) {
                        selectedLeague = league
                    }
                }) {
                    Text(league)
                        .font(AppTheme.Typography.button)
                        .foregroundColor(selectedLeague == league ? .white : AppTheme.Colors.textSecondary)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.pill)
                                .fill(selectedLeague == league ?
                                      AppTheme.Colors.leagueSelected :
                                      AppTheme.Colors.leagueUnselected)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.pill)
                                .stroke(
                                    selectedLeague == league ?
                                    AppTheme.Colors.primary.opacity(0.6) :
                                    Color.clear,
                                    lineWidth: 1
                                )
                        )
                }
                .scaleEffect(selectedLeague == league ? 1.05 : 1.0)
                .animation(AppTheme.Animation.springQuick, value: selectedLeague)
            }
            Spacer()
        }
    }
    
    // MARK: - Featured Game Card
    
    private func featuredGameCard(_ game: Game) -> some View {
        Button(action: {
            HapticManager.impact(.medium)
            selectedGame = game
            showBetModal = true
        }) {
            VStack(spacing: 0) {
                // Unified Header Section (Fixed clunky overlays)
                HStack {
                    // Featured badge
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text("Featured")
                            .font(AppTheme.Typography.caption)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(AppTheme.CornerRadius.small)
                    
                    Spacer()
                    
                    // Status and time in unified design
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("UPCOMING")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.pending)
                            .fontWeight(.bold)
                        
                        Text(game.time.formatted(date: .abbreviated, time: .shortened))
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(AppTheme.Colors.cardBackgroundElevated)
                    .cornerRadius(AppTheme.CornerRadius.small)
                }
                .padding(AppTheme.Spacing.md)
                
                // Game Content
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Team vs Team
                    HStack {
                        VStack {
                            Text(game.awayTeam)
                                .font(AppTheme.Typography.title2)
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            
                            Text(game.awaySpread)
                                .font(AppTheme.Typography.amount)
                                .foregroundColor(AppTheme.Colors.primary)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        // VS indicator
                        VStack(spacing: 4) {
                            Text("@")
                                .font(AppTheme.Typography.title1)
                                .foregroundColor(AppTheme.Colors.textTertiary)
                                .fontWeight(.light)
                        }
                        
                        Spacer()
                        
                        VStack {
                            Text(game.homeTeam)
                                .font(AppTheme.Typography.title2)
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            
                            Text(game.homeSpread)
                                .font(AppTheme.Typography.amount)
                                .foregroundColor(AppTheme.Colors.primary)
                                .fontWeight(.bold)
                        }
                    }
                    
                    // Total Bets Indicator
                    if game.totalBets > 0 {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(AppTheme.Colors.primary)
                            Text("\(game.totalBets) active bets")
                                .font(AppTheme.Typography.callout)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.bottom, AppTheme.Spacing.lg)
            }
        }
        .elevatedCardStyle()
        .scaleEffect(selectedGame?.id == game.id ? 0.98 : 1.0)
        .animation(AppTheme.Animation.springQuick, value: selectedGame?.id)
    }
    
    // MARK: - Upcoming Games Section
    
    private var upcomingGamesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Upcoming Games")
                .font(AppTheme.Typography.title2)
                .foregroundColor(.white)
                .fontWeight(.bold)
            
            LazyVStack(spacing: AppTheme.Spacing.md) {
                ForEach(Array(viewModel.games.prefix(5).enumerated()), id: \.element.id) { index, game in
                    if game.id != viewModel.featuredGame?.id {
                        upcomingGameCard(game)
                            .scaleEffect(cardsAppeared ? 1.0 : 0.9)
                            .opacity(cardsAppeared ? 1.0 : 0.0)
                            .animation(
                                AppTheme.Animation.spring.delay(Double(index) * 0.1 + 0.4),
                                value: cardsAppeared
                            )
                    }
                }
            }
        }
    }
    
    // MARK: - Upcoming Game Card
    
    private func upcomingGameCard(_ game: Game) -> some View {
        Button(action: {
            HapticManager.impact(.light)
            selectedGame = game
            showBetModal = true
        }) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("\(game.awayTeam) @ \(game.homeTeam)")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                    
                    Text(game.time.formatted(date: .omitted, time: .shortened))
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                HStack(spacing: AppTheme.Spacing.md) {
                    VStack {
                        Text(game.awaySpread)
                            .font(AppTheme.Typography.callout)
                            .foregroundColor(AppTheme.Colors.primary)
                            .fontWeight(.bold)
                    }
                    
                    VStack {
                        Text(game.homeSpread)
                            .font(AppTheme.Typography.callout)
                            .foregroundColor(AppTheme.Colors.primary)
                            .fontWeight(.bold)
                    }
                }
            }
            .padding(AppTheme.Spacing.md)
        }
        .cardStyle()
        .scaleEffect(selectedGame?.id == game.id ? 0.98 : 1.0)
        .animation(AppTheme.Animation.springQuick, value: selectedGame?.id)
    }
}

// MARK: - Balance Card Component

struct BalanceCard: View {
    let emoji: String
    let amount: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            HStack(spacing: AppTheme.Spacing.xs) {
                Text(emoji)
                    .font(.title2)
                Text("\(amount)")
                    .font(AppTheme.Typography.amount)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
            }
            
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(.vertical, AppTheme.Spacing.sm)
        .padding(.horizontal, AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}
