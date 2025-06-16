//
//  GamesView.swift
//  BettorOdds
//
//  Version: 3.6.0 - Fixed BetModal integration and team preselection
//  Updated: June 2025
//

import SwiftUI

struct GamesView: View {
    @StateObject private var viewModel = GamesViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var selectedLeague = "NBA"
    @State private var showBetModal = false
    @State private var selectedGame: Game?
    @State private var preselectedTeam: String?
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
        // FIXED: Modal presentation with proper BetModal integration
        .sheet(item: Binding<IdentifiableGame?>(
            get: { selectedGame.map(IdentifiableGame.init) },
            set: { _ in
                selectedGame = nil
                showBetModal = false
                preselectedTeam = nil
            }
        )) { gameWrapper in
            BetModal(
                game: gameWrapper.game,
                user: authViewModel.user ?? User.preview,
                isPresented: Binding(
                    get: { showBetModal },
                    set: { newValue in
                        showBetModal = newValue
                        if !newValue {
                            selectedGame = nil
                            preselectedTeam = nil
                        }
                    }
                ),
                preselectedTeam: preselectedTeam
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
                    .scaleEffect(selectedLeague == league ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedLeague == league)
                }
            }
        }
    }
    
    // MARK: - Old UI Style Daily Limit
    
    private var oldUIStyleDailyLimit: some View {
        HStack {
            Text("Daily Limit")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 12))
                    .foregroundColor(tealColor)
                
                Text("$\(authViewModel.user?.dailyGreenCoinsUsed ?? 0)/100")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(tealColor)
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Featured Game with Animated Border
    
    private func featuredGameWithAnimatedBorder(game: Game) -> some View {
        GameCard(
            game: game,
            isFeatured: true,
            onSelect: { selectedTeam in
                presentBetModal(for: game, type: "Featured", selectedTeam: selectedTeam)
            },
            globalSelectedTeam: .constant(nil)
        )
        .overlay(animatedBorderGlow)
        .scaleEffect(cardsAppeared ? 1.0 : 0.9)
        .opacity(cardsAppeared ? 1.0 : 0.0)
        .animation(
            .spring(response: 0.8, dampingFraction: 0.8).delay(0.3),
            value: cardsAppeared
        )
    }
    
    // MARK: - Animated Border Glow for Featured Game
    
    private var animatedBorderGlow: some View {
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
                    GameCard(
                        game: game,
                        isFeatured: false,
                        onSelect: { selectedTeam in
                            presentBetModal(for: game, type: "Upcoming", selectedTeam: selectedTeam)
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
    
    // MARK: - Modal Presentation Helper (UPDATED with team selection support)
    
    private func presentBetModal(for game: Game, type: String, selectedTeam: String? = nil) {
        print("🎯 \(type) game selected: \(game.homeTeam) vs \(game.awayTeam)")
        selectedGame = game
        preselectedTeam = selectedTeam
        showBetModal = true
        print("✅ Modal data set - game: \(game.id), preselected team: \(selectedTeam ?? "none")")
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
