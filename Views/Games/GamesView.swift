//
//  Enhanced GamesView.swift
//  BettorOdds
//
//  Created by Claude on 6/13/25
//  Version: 2.1.0 - Fixed to use correct BetModal component
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
            if let game = selectedGame,
               let user = authViewModel.user {
                BetModal(
                    game: game,
                    user: user,
                    isPresented: $showBetModal
                )
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // App Title
            Text("BettorOdds")
                .font(AppTheme.Typography.appTitle)
                .foregroundColor(.white)
                .fontWeight(.bold)
            
            // Balance Cards
            HStack(spacing: AppTheme.Spacing.md) {
                BalanceCard(
                    emoji: "🟡",
                    amount: authViewModel.user?.yellowCoins ?? 0,
                    label: "Play Coins",
                    color: AppTheme.Colors.yellowCoin
                )
                
                BalanceCard(
                    emoji: "💚",
                    amount: authViewModel.user?.greenCoins ?? 0,
                    label: "Real Coins",
                    color: AppTheme.Colors.greenCoin
                )
            }
            
            // Daily Limit Progress (for green coins)
            if let user = authViewModel.user {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Daily Limit")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    ProgressView(
                        value: Double(user.dailyGreenCoinsUsed),
                        total: 100.0  // Daily limit
                    )
                    .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.Colors.greenCoin))
                    .frame(height: 4)
                    
                    Text("💚 \(user.dailyGreenCoinsUsed)/100")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // League Selector
            leagueSelector
        }
    }
    
    // MARK: - League Selector
    
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
                // Header Section
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
                    
                    // Status and time
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("UPCOMING")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.pending)
                            .fontWeight(.bold)
                        
                        Text(game.time.formatted(date: .omitted, time: .shortened))
                            .font(AppTheme.Typography.callout)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .fontWeight(.light)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, AppTheme.Spacing.lg)
                
                // Teams Section
                HStack {
                    // Away Team
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
                    
                    // VS Badge
                    Text("@")
                        .font(AppTheme.Typography.title1)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .fontWeight(.light)
                    
                    Spacer()
                    
                    // Home Team
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
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.bottom, AppTheme.Spacing.lg)
                
                // Total Bets Indicator
                if game.totalBets > 0 {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(AppTheme.Colors.primary)
                        Text("\(game.totalBets) active bets")
                            .font(AppTheme.Typography.callout)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    .padding(.bottom, AppTheme.Spacing.lg)
                }
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
                            .opacity(cardsAppeared ? 1.0 : 0)
                            .animation(AppTheme.Animation.spring.delay(0.3 + Double(index) * 0.1), value: cardsAppeared)
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
                // Game Info
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("\(game.awayTeam) @ \(game.homeTeam)")
                        .font(AppTheme.Typography.callout)
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                    
                    Text(game.time.formatted(date: .abbreviated, time: .shortened))
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Text("Spread: \(game.homeSpread)")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.primary)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                // Bet Count
                if game.totalBets > 0 {
                    VStack {
                        Text("\(game.totalBets)")
                            .font(AppTheme.Typography.amount)
                            .foregroundColor(AppTheme.Colors.primary)
                            .fontWeight(.bold)
                        Text("bets")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .font(.caption)
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
