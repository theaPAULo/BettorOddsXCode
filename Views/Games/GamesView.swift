//
//  GamesView.swift
//  BettorOdds
//
//  Version: 3.5.0 - UI Polish fixes
//  - Removed spread button backgrounds completely
//  - Changed Daily Limit to subtle line style (like old UI)
//  - Fixed border glow animation
//

import SwiftUI

struct GamesView: View {
    @StateObject private var viewModel = GamesViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var selectedLeague = "NBA"
    @State private var showBetModal = false
    @State private var selectedGame: Game?
    @State private var scrollOffset: CGFloat = 0
    
    // Animation states
    @State private var cardsAppeared = false
    @State private var borderGlow = false
    
    // TEAL COLOR DEFINITION
    private let tealColor = Color(red: 0.0, green: 0.9, blue: 0.79)
    
    var body: some View {
        NavigationView {
            ZStack {
                // MATCHING PROFILE BACKGROUND - Animated gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.primary.opacity(0.2),
                        Color.white.opacity(0.1),
                        Color.primary.opacity(0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .hueRotation(.degrees(scrollOffset / 2))
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        headerSection
                            .modifier(ScrollOffsetModifier(coordinateSpace: "scroll", offset: $scrollOffset))
                        
                        // Featured Game Card with Animated Border (NO "Featured Game" text)
                        if let featuredGame = viewModel.featuredGame {
                            featuredGameWithAnimatedBorder(game: featuredGame)
                        }
                        
                        // Upcoming Games Section - FIXED: Exclude featured game
                        upcomingGamesSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
                .coordinateSpace(name: "scroll")
                .refreshable {
                    await viewModel.refreshGames()
                    HapticManager.impact(.light)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1)) {
                cardsAppeared = true
            }
            // FIXED: Start border animation immediately when view appears
            borderGlow = true
        }
        // FIXED: Modal presentation working!
        .sheet(item: Binding<IdentifiableGame?>(
            get: { selectedGame.map(IdentifiableGame.init) },
            set: { _ in selectedGame = nil }
        )) { gameWrapper in
            BetModal(
                game: gameWrapper.game,
                user: authViewModel.user ?? User.preview,
                isPresented: $showBetModal
            )
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 24) {
            // App Title
            HStack(spacing: 8) {
                Text("BettorOdds")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color.white,
                                Color.white.opacity(0.95),
                                Color(red: 1.0, green: 0.98, blue: 0.9),
                                Color(red: 1.0, green: 0.92, blue: 0.8)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                
                Circle()
                    .fill(tealColor)
                    .frame(width: 12, height: 12)
                    .shadow(color: tealColor.opacity(0.6), radius: 4, x: 0, y: 0)
            }
            
            // Balance Cards Row - USING ProfileView STYLE
            HStack(spacing: 16) {
                CoinBalanceCard(type: .yellow, balance: authViewModel.user?.yellowCoins ?? 0)
                CoinBalanceCard(type: .green, balance: authViewModel.user?.greenCoins ?? 0)
            }
            
            // FIXED: Daily Limit - OLD UI STYLE (Subtle Line)
            oldUIStyleDailyLimit
            
            // League Selection
            HStack(spacing: 12) {
                ForEach(["NBA", "NFL"], id: \.self) { league in
                    Button(action: {
                        Task {
                            selectedLeague = league
                            await viewModel.changeLeague(to: league)
                            HapticManager.impact(.medium)
                        }
                    }) {
                        Text(league)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(selectedLeague == league ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(leagueButtonBackground(isSelected: selectedLeague == league))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .scaleEffect(selectedLeague == league ? 1.02 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedLeague)
                }
            }
        }
        .scaleEffect(cardsAppeared ? 1.0 : 0.8)
        .opacity(cardsAppeared ? 1.0 : 0.0)
        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: cardsAppeared)
    }
    
    // MARK: - OLD UI STYLE: Daily Limit (Subtle Line)
    
    private var oldUIStyleDailyLimit: some View {
        HStack {
            Text("Daily Limit")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 12))
                    .foregroundColor(tealColor)
                
                Text("$\(authViewModel.user?.dailyGreenCoinsUsed ?? 0)/100")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(tealColor)
            }
        }
        .padding(.vertical, 12)
        .overlay(
            // OLD UI STYLE: Subtle line instead of full card
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Featured Game with Animated Teal Border
    
    private func featuredGameWithAnimatedBorder(game: Game) -> some View {
        EnhancedGameCard(
            game: game,
            isFeatured: true,
            onSelect: {
                presentBetModal(for: game, type: "Featured")
            },
            globalSelectedTeam: .constant(nil)
        )
        .overlay(animatedTealBorder)
        .scaleEffect(cardsAppeared ? 1.0 : 0.9)
        .opacity(cardsAppeared ? 1.0 : 0.0)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2), value: cardsAppeared)
    }
    
    // MARK: - FIXED: Animated Teal Border for Featured Game
    
    private var animatedTealBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                LinearGradient(
                    colors: [
                        tealColor.opacity(borderGlow ? 0.9 : 0.4),
                        tealColor.opacity(borderGlow ? 1.0 : 0.6),
                        tealColor.opacity(borderGlow ? 0.9 : 0.4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: borderGlow ? 3 : 2
            )
            .shadow(
                color: tealColor.opacity(borderGlow ? 0.8 : 0.3),
                radius: borderGlow ? 15 : 6,
                x: 0,
                y: 0
            )
            .scaleEffect(borderGlow ? 1.01 : 1.0)
            .animation(
                // FIXED: Ensure animation is always running
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true),
                value: borderGlow
            )
            .onAppear {
                // FIXED: Force animation start
                withAnimation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
                ) {
                    borderGlow.toggle()
                }
            }
    }
    
    // MARK: - Upcoming Games Section (FIXED - Excludes Featured)
    
    private var upcomingGamesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Upcoming Games")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Rectangle()
                    .fill(tealColor)
                    .frame(width: 40, height: 3)
                    .cornerRadius(2)
            }
            
            LazyVStack(spacing: 16) {
                // Proper filtering to exclude featured game
                ForEach(Array(nonFeaturedGames.enumerated()), id: \.element.id) { index, game in
                    EnhancedGameCard(
                        game: game,
                        isFeatured: false,
                        onSelect: {
                            presentBetModal(for: game, type: "Upcoming")
                        },
                        globalSelectedTeam: .constant(nil)
                    )
                    .scaleEffect(cardsAppeared ? 1.0 : 0.9)
                    .opacity(cardsAppeared ? 1.0 : 0.0)
                    .animation(
                        .spring(response: 0.8, dampingFraction: 0.8).delay(Double(index) * 0.1),
                        value: cardsAppeared
                    )
                }
            }
        }
    }
    
    // MARK: - Computed Property for Non-Featured Games
    
    private var nonFeaturedGames: [Game] {
        let featuredGameId = viewModel.featuredGame?.id
        return viewModel.games.filter { game in
            game.id != featuredGameId
        }
    }
    
    // MARK: - Modal Presentation Helper
    
    private func presentBetModal(for game: Game, type: String) {
        print("🎯 \(type) game selected: \(game.homeTeam) vs \(game.awayTeam)")
        selectedGame = game
        print("✅ Modal data set - game: \(game.id)")
    }
    
    // MARK: - Helper Views
    
    private func leagueButtonBackground(isSelected: Bool) -> some View {
        Group {
            if isSelected {
                LinearGradient(
                    colors: [tealColor, tealColor.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.1),
                        Color.white.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - IdentifiableGame Wrapper

struct IdentifiableGame: Identifiable {
    let id = UUID()
    let game: Game
}

// MARK: - Enhanced GameCard with OLD UI Style (NO SPREAD BACKGROUNDS)

struct EnhancedGameCard: View {
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
            
            // Teams Section with OLD UI DIAGONAL GRADIENTS
            diagonalTeamsSection
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                .padding(.top, 12)
        }
        .background(oldUIStyleDiagonalBackground)
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
    
    // MARK: - OLD UI Style Diagonal Teams Section
    
    private var diagonalTeamsSection: some View {
        HStack(spacing: 0) {
            // Away Team Side
            diagonalAwayTeamSide
            
            // VS Indicator in Center
            vsIndicator
                .zIndex(1)
            
            // Home Team Side
            diagonalHomeTeamSide
        }
    }
    
    private var diagonalAwayTeamSide: some View {
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
                
                // FIXED: OLD UI STYLE - NO BACKGROUND AT ALL
                Text(game.awaySpread)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 3, x: 0, y: 2)
                // NO .background() - completely removed!
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(selectedTeam == TeamSelection.away ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedTeam == TeamSelection.away)
    }
    
    private var diagonalHomeTeamSide: some View {
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
                
                // FIXED: OLD UI STYLE - NO BACKGROUND AT ALL
                Text(game.homeSpread)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 3, x: 0, y: 2)
                // NO .background() - completely removed!
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
    
    // MARK: - OLD UI STYLE: Diagonal Background
    
    private var oldUIStyleDiagonalBackground: some View {
        LinearGradient(
            colors: [
                // OLD UI STYLE: Strong diagonal gradient from top-left to bottom-right
                game.awayTeamColors.primary.opacity(0.9),      // Strong away color top-left
                game.awayTeamColors.primary.opacity(0.7),      // Fade away color
                game.awayTeamColors.secondary.opacity(0.4),    // Away secondary blend
                Color.black.opacity(0.15),                     // Dark center blend
                game.homeTeamColors.secondary.opacity(0.4),    // Home secondary blend
                game.homeTeamColors.primary.opacity(0.7),      // Fade home color
                game.homeTeamColors.primary.opacity(0.9)       // Strong home color bottom-right
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing  // OLD UI STYLE: Diagonal instead of horizontal
        )
    }
    
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

// MARK: - ScrollOffset Modifier

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct ScrollOffsetModifier: ViewModifier {
    let coordinateSpace: String
    @Binding var offset: CGFloat
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { proxy in
                    Color.clear
                        .preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: proxy.frame(in: .named(coordinateSpace)).minY
                        )
                }
            )
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                offset = value
            }
    }
}

#Preview {
    GamesView()
        .environmentObject(AuthenticationViewModel())
}
