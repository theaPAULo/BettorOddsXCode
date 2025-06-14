//
//  GamesView.swift - Minimal Teal Enhancement
//  BettorOdds
//
//  Version: 2.3.0 - Adding ONLY teal accents to working version
//

import SwiftUI

struct GamesView: View {
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
            // Background gradient (keep original)
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
    
    // MARK: - Header Section (with minimal teal accents)
    
    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // App Title with TEAL accent
            HStack(spacing: 8) {
                Text("BettorOdds")
                    .font(AppTheme.Typography.appTitle)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                
                // TEAL accent dot
                Circle()
                    .fill(Color.primary)
                    .frame(width: 8, height: 8)
                    .shadow(color: Color.primary, radius: 4)
            }
            
            // Balance Cards (with TEAL accent on green coins)
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
                    color: Color.primary // TEAL accent here
                )
            }
            
            // Daily Limit with TEAL accent
            HStack {
                Text("Daily Limit")
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 4) {
                    // TEAL heart icon
                    Image(systemName: "heart.fill")
                        .foregroundColor(Color.primary)
                        .font(.system(size: 12))
                        .shadow(color: Color.primary, radius: 2)
                    
                    Text("$0/100")
                        .font(AppTheme.Typography.callout)
                        .foregroundColor(Color.primary) // TEAL text
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.primary.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            // League Selection with TEAL accent
            HStack(spacing: AppTheme.Spacing.md) {
                leagueButton("NBA", isSelected: selectedLeague == "NBA")
                leagueButton("NFL", isSelected: selectedLeague == "NFL")
            }
        }
    }
    
    // League button with TEAL when selected
    private func leagueButton(_ league: String, isSelected: Bool) -> some View {
        Button(action: {
            selectedLeague = league
            // Add league switching logic here
        }) {
            Text(league)
                .font(AppTheme.Typography.title3)
                .foregroundColor(isSelected ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .fill(isSelected ? Color.primary : Color.clear) // TEAL when selected
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                .stroke(Color.primary.opacity(0.5), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Featured Game Section (keep original)
    
    private var featuredGameSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            if let featuredGame = viewModel.featuredGame {
                featuredGameCard(featuredGame)
            }
        }
        .scaleEffect(cardsAppeared ? 1.0 : 0.95)
        .opacity(cardsAppeared ? 1.0 : 0.0)
        .animation(AppTheme.Animation.spring.delay(0.1), value: cardsAppeared)
    }
    
    // MARK: - Featured Game Card (keep original)
    
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
    
    // MARK: - Upcoming Games Section (with TEAL accent line)
    
    private var upcomingGamesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Section header with TEAL accent line
            HStack {
                Text("Upcoming Games")
                    .font(AppTheme.Typography.title2)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                
                Spacer()
                
                // TEAL accent line
                Rectangle()
                    .fill(Color.primary)
                    .frame(width: 40, height: 3)
                    .cornerRadius(1.5)
                    .shadow(color: Color.primary, radius: 2)
            }
            
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
    
    // MARK: - Upcoming Game Card (keep original)
    
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

// MARK: - Balance Card Component (with TEAL support)

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
                .stroke(color.opacity(0.3), lineWidth: 1) // This will show TEAL for green coins
        )
    }
}

#Preview {
    GamesView()
        .environmentObject(AuthenticationViewModel())
}
