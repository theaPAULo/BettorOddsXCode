//
//  GamesView.swift - Complete Working Version with Visible Teal
//  BettorOdds
//
//  Version: 2.4.0 - Complete implementation with guaranteed teal visibility
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
    
    // TEAL COLOR DEFINITION - This is what was missing!
    private let tealColor = Color(red: 0.0, green: 0.9, blue: 0.79)
    
    var body: some View {
        ZStack {
            // Background gradient (keep original)
            AppTheme.Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.lg) {
                    // Header Section with TEAL
                    headerSection
                        .offset(y: headerOffset)
                    
                    // Featured Game Card
                    featuredGameSection
                    
                    // Upcoming Games Section with TEAL
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
    
    // MARK: - Header Section (WITH VISIBLE TEAL)
    
    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // App Title with BRIGHT TEAL DOT
            HStack(spacing: 8) {
                Text("BettorOdds")
                    .font(AppTheme.Typography.appTitle)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                
                // BRIGHT TEAL DOT - You should see this!
                Circle()
                    .fill(tealColor)
                    .frame(width: 12, height: 12) // Made bigger so it's more visible
                    .shadow(color: tealColor, radius: 6)
                    .shadow(color: tealColor, radius: 3)
            }
            
            // Balance Cards with TEAL border on green coins
            HStack(spacing: AppTheme.Spacing.md) {
                // Yellow Coins (original)
                BalanceCard(
                    emoji: "🟡",
                    amount: authViewModel.user?.yellowCoins ?? 0,
                    label: "Play Coins",
                    color: AppTheme.Colors.yellowCoin
                )
                
                // Green Coins with BRIGHT TEAL BORDER
                BalanceCard(
                    emoji: "💚",
                    amount: authViewModel.user?.greenCoins ?? 0,
                    label: "Real Coins",
                    color: tealColor // This should show TEAL border
                )
            }
            
            // Daily Limit with BRIGHT TEAL ACCENTS
            HStack {
                Text("Daily Limit")
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 6) {
                    // BRIGHT TEAL HEART - You should see this!
                    Image(systemName: "heart.fill")
                        .foregroundColor(tealColor)
                        .font(.system(size: 16, weight: .bold))
                        .shadow(color: tealColor, radius: 4)
                    
                    Text("$0/100")
                        .font(AppTheme.Typography.callout)
                        .foregroundColor(tealColor) // TEAL TEXT
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(tealColor.opacity(0.2)) // TEAL BACKGROUND
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(tealColor, lineWidth: 2) // BRIGHT TEAL BORDER
                        )
                )
            }
            
            // League Selection with BRIGHT TEAL when selected
            HStack(spacing: AppTheme.Spacing.md) {
                leagueButton("NBA", isSelected: selectedLeague == "NBA")
                leagueButton("NFL", isSelected: selectedLeague == "NFL")
            }
        }
    }
    
    // League button with BRIGHT TEAL when selected
    private func leagueButton(_ league: String, isSelected: Bool) -> some View {
        Button(action: {
            selectedLeague = league
            Task {
                await viewModel.changeLeague(to: league)
            }
        }) {
            Text(league)
                .font(AppTheme.Typography.title3)
                .foregroundColor(isSelected ? .black : .white)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .fill(isSelected ? tealColor : Color.clear) // BRIGHT TEAL FILL when selected
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                .stroke(tealColor, lineWidth: isSelected ? 3 : 1) // BRIGHT TEAL BORDER
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Featured Game Section (original)
    
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
    
    // MARK: - Upcoming Games Section (WITH BRIGHT TEAL LINE)
    
    private var upcomingGamesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Section header with BRIGHT TEAL ACCENT LINE
            HStack {
                Text("Upcoming Games")
                    .font(AppTheme.Typography.title2)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                
                Spacer()
                
                // BRIGHT TEAL ACCENT LINE - You should see this!
                Rectangle()
                    .fill(tealColor)
                    .frame(width: 50, height: 4) // Made bigger and thicker
                    .cornerRadius(2)
                    .shadow(color: tealColor, radius: 4)
                    .shadow(color: tealColor, radius: 2)
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

// MARK: - Enhanced Balance Card (WITH TEAL SUPPORT)

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
                .stroke(color, lineWidth: 2) // This will show BRIGHT TEAL for green coins
        )
    }
}

#Preview {
    GamesView()
        .environmentObject(AuthenticationViewModel())
}
