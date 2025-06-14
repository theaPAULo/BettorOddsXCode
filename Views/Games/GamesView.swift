//
//  EnhancedGamesView.swift
//  BettorOdds
//
//  Created by Claude on 6/13/25
//  Version: 2.2.0 - Fixed compiler issues and missing colors
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
                    featuredGameSection
                    
                    // Upcoming Games Section
                    upcomingGamesSection
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
            
            // Daily Limit Progress
            dailyLimitSection
            
            // League Selection
            leagueSelectionSection
        }
    }
    
    // MARK: - Featured Game Section (Broken down to fix compiler issue)
    
    private var featuredGameSection: some View {
        Group {
            if let featuredGame = viewModel.featuredGame {
                featuredGameCard(featuredGame)
                    .scaleEffect(cardsAppeared ? 1.0 : 0.95)
                    .opacity(cardsAppeared ? 1.0 : 0.0)
                    .animation(AppTheme.Animation.spring.delay(0.1), value: cardsAppeared)
            }
        }
    }
    
    // MARK: - Daily Limit Section
    
    private var dailyLimitSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("Daily Limit")
                .font(AppTheme.Typography.callout)
                .foregroundColor(.white.opacity(0.8))
            
            HStack {
                Text("💚")
                    .font(.caption)
                
                Text("0/100")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
            }
            
            // Progress Bar
            ProgressView(value: 0.0, total: 100.0)
                .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.Colors.greenCoin))
                .scaleEffect(x: 1, y: 0.5)
        }
    }
    
    // MARK: - League Selection Section
    
    private var leagueSelectionSection: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            leagueButton("NBA", isSelected: selectedLeague == "NBA")
            leagueButton("NFL", isSelected: selectedLeague == "NFL")
            Spacer()
        }
    }
    
    private func leagueButton(_ league: String, isSelected: Bool) -> some View {
        Button(action: {
            selectedLeague = league
            HapticManager.selection()
        }) {
            Text(league)
                .font(AppTheme.Typography.callout)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .fill(isSelected ? AppTheme.Colors.primary.opacity(0.8) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                .stroke(AppTheme.Colors.primary.opacity(0.5), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Featured Game Card
    
    private func featuredGameCard(_ game: Game) -> some View {
        GameCard(
            game: game,
            isFeatured: true,
            onSelect: {
                selectedGame = game
                showBetModal = true
            },
            globalSelectedTeam: .constant(nil)
        )
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
                                AppTheme.Animation.spring.delay(Double(index) * 0.1),
                                value: cardsAppeared
                            )
                    }
                }
            }
        }
        .scaleEffect(cardsAppeared ? 1.0 : 0.95)
        .opacity(cardsAppeared ? 1.0 : 0.0)
        .animation(AppTheme.Animation.spring.delay(0.2), value: cardsAppeared)
    }
    
    // MARK: - Upcoming Game Card
    
    private func upcomingGameCard(_ game: Game) -> some View {
        GameCard(
            game: game,
            isFeatured: false,
            onSelect: {
                selectedGame = game
                showBetModal = true
            },
            globalSelectedTeam: .constant(nil)
        )
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

#Preview {
    EnhancedGamesView()
        .environmentObject(AuthenticationViewModel())
}
