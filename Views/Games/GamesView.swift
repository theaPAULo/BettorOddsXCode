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
    
    //
    //  Enhanced GamesView.swift Header Section
    //  Add this to replace the headerSection in your GamesView.swift
    //

    //
    //  Fixed GamesView.swift Header Section
    //  Replace the headerSection in your GamesView.swift with this
    //

    // MARK: - Enhanced Header Section (WITH GOLD GRADIENT - FIXED TYPOGRAPHY)

    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // App Title with STUNNING GOLD GRADIENT
            HStack(spacing: 8) {
                Text("BettorOdds")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.84, blue: 0.0),    // Pure Gold #FFD700
                                Color(red: 1.0, green: 0.65, blue: 0.0),    // Orange-Gold #FFA500
                                Color(red: 1.0, green: 0.55, blue: 0.0),    // Darker Orange #FF8C00
                                Color(red: 0.85, green: 0.47, blue: 0.0)    // Bronze accent
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3), radius: 2, x: 0, y: 1)
                
                // BRIGHT TEAL DOT - Enhanced visibility
                Circle()
                    .fill(tealColor)
                    .frame(width: 12, height: 12)
                    .shadow(color: tealColor.opacity(0.6), radius: 4, x: 0, y: 0)
            }
            
            // Balance Cards Row
            HStack(spacing: AppTheme.Spacing.md) {
                // Play Coins (Yellow)
                BalanceCard(
                    emoji: "🟡",
                    amount: authViewModel.user?.yellowCoins ?? 0,
                    label: "Play Coins",
                    color: Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
                )
                
                // Real Coins (Teal) - ENHANCED VISIBILITY
                BalanceCard(
                    emoji: "💚",
                    amount: authViewModel.user?.greenCoins ?? 0,
                    label: "Real Coins",
                    color: tealColor // Bright teal
                )
            }
            
            // Daily Limit Display - Enhanced
            HStack {
                Text("Daily Limit")
                    .font(AppTheme.Typography.title3) // FIXED: Use correct typography
                    .foregroundColor(.white)
                
                Spacer()
                
                // Enhanced daily limit with teal accent
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundColor(tealColor)
                    
                    Text("$\(authViewModel.user?.dailyGreenCoinsUsed ?? 0)/100")
                        .font(AppTheme.Typography.title3) // FIXED: Use correct typography
                        .foregroundColor(tealColor)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .stroke(tealColor, lineWidth: 2)
                        .background(
                            Capsule()
                                .fill(tealColor.opacity(0.1))
                        )
                )
            }
            
            // League Selection - Enhanced with better animations
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(["NBA", "NFL"], id: \.self) { league in
                    Button(action: {
                        Task {
                            selectedLeague = league
                            await viewModel.changeLeague(to: league)
                            HapticManager.impact(.medium)
                        }
                    }) {
                        Text(league)
                            .font(AppTheme.Typography.callout) // FIXED: Use correct typography
                            .fontWeight(.bold)
                            .foregroundColor(selectedLeague == league ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(leagueButtonBackground(isSelected: selectedLeague == league))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                    }
                    .scaleEffect(selectedLeague == league ? 1.02 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedLeague)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    // Enhanced league button background
    private func leagueButtonBackground(isSelected: Bool) -> some View {
        Group {
            if isSelected {
                // BRIGHT TEAL for selected
                LinearGradient(
                    colors: [
                        tealColor,
                        tealColor.opacity(0.8)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                // Subtle outline for unselected
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(tealColor.opacity(0.5), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .fill(Color.clear)
                    )
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
