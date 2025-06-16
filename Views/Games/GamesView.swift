//
//  GamesView.swift
//  BettorOdds
//
//  Version: 4.1.0 - Complete clean implementation with modal fix
//  Replace entire file with this version
//  Updated: June 2025
//

import SwiftUI

struct GamesView: View {
    @StateObject private var viewModel = GamesViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var selectedLeague = "NBA"
    @State private var selectedGame: Game?
    @State private var preselectedTeam: String?
    @State private var scrollOffset: CGFloat = 0
    @State private var isRefreshing = false
    
    // Animation states
    @State private var cardsAppeared = false
    @State private var borderGlow = false
    
    // TEAL COLOR DEFINITION - Your signature brand color
    private let tealColor = Color(red: 0.0, green: 0.9, blue: 0.79)
    
    // Available leagues for horizontal scrolling
    private let availableLeagues = ["NBA", "NFL", "MLB", "NHL", "NCAAF", "NCAAB"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // ENHANCED ANIMATED BACKGROUND - More dynamic (inline to avoid duplicate)
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.06, green: 0.13, blue: 0.15),
                        Color(red: 0.13, green: 0.23, blue: 0.26),
                        Color(red: 0.17, green: 0.33, blue: 0.39)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .hueRotation(.degrees(scrollOffset / 3)) // More subtle hue rotation
                .animation(.easeOut(duration: 0.3), value: scrollOffset)
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        headerSection
                            .modifier(ScrollOffsetModifier(coordinateSpace: "scroll", offset: $scrollOffset))
                        
                        // Featured Game Card with Animated Border (NO "Upcoming Games" text)
                        if let featuredGame = viewModel.featuredGame {
                            featuredGameWithAnimatedBorder(game: featuredGame)
                        }
                        
                        // Regular Games Section - REMOVED "Upcoming Games" title as requested
                        gamesSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
                .coordinateSpace(name: "scroll")
                .refreshable {
                    await performRefresh()
                }
                
                // Pull-to-refresh indicator
                if isRefreshing {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.2)
                            .progressViewStyle(CircularProgressViewStyle(tint: tealColor))
                        Text("Refreshing odds...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
                    .transition(.opacity)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1)) {
                cardsAppeared = true
            }
            // Start border animation immediately when view appears
            borderGlow = true
        }
        // FIXED: Use only the item-based sheet presentation (consistent with existing working code)
        .sheet(item: Binding<IdentifiableGame?>(
            get: { selectedGame.map(IdentifiableGame.init) },
            set: { _ in
                selectedGame = nil
                preselectedTeam = nil
            }
        )) { gameWrapper in
            BetModal(
                game: gameWrapper.game,
                user: authViewModel.user ?? User.preview,
                isPresented: Binding(
                    get: { selectedGame != nil },
                    set: { newValue in
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
    
    // MARK: - Header Section (Enhanced)
    
    private var headerSection: some View {
        VStack(spacing: 24) {
            // App Title with enhanced styling
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
            
            // Balance Cards Row - Enhanced with teal heart
            HStack(spacing: 16) {
                EnhancedCoinBalanceCard(type: .yellow, balance: authViewModel.user?.yellowCoins ?? 0)
                EnhancedCoinBalanceCard(type: .green, balance: authViewModel.user?.greenCoins ?? 0)
            }
            
            // Daily Limit - Subtle style as requested
            dailyLimitSection
            
            // League Selection - NEW: Horizontal scrollable as requested
            horizontalLeagueSelection
        }
    }
    
    // MARK: - Enhanced Daily Limit Section
    
    private var dailyLimitSection: some View {
        HStack {
            Text("Daily Limit")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 12))
                    .foregroundColor(tealColor) // Using teal for heart as requested
                
                Text("$\(authViewModel.user?.dailyGreenCoinsUsed ?? 0)/100")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(tealColor)
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - NEW: Horizontal League Selection (Thinner, Scrollable)
    
    private var horizontalLeagueSelection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(availableLeagues, id: \.self) { league in
                    Button(action: {
                        Task {
                            selectedLeague = league
                            await viewModel.changeLeague(to: league)
                            HapticManager.impact(.medium)
                        }
                    }) {
                        Text(league)
                            .font(.system(size: 14, weight: .bold)) // Smaller font for thinner buttons
                            .foregroundColor(selectedLeague == league ? .black : .white)
                            .frame(minWidth: 60) // Minimum width but flexible
                            .frame(height: 36) // Thinner height as requested
                            .padding(.horizontal, 16)
                            .background(leagueButtonBackground(isSelected: selectedLeague == league))
                            .clipShape(RoundedRectangle(cornerRadius: 18)) // More rounded for thinner buttons
                    }
                    .scaleEffect(selectedLeague == league ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedLeague == league)
                }
            }
            .padding(.horizontal, 20)
        }
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
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true),
                value: borderGlow
            )
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
                ) {
                    borderGlow.toggle()
                }
            }
    }
    
    // MARK: - Games Section (NO "Upcoming Games" title as requested)
    
    private var gamesSection: some View {
        LazyVStack(spacing: 16) {
            // No section title - direct display of games
            ForEach(Array(nonFeaturedGames.enumerated()), id: \.element.id) { index, game in
                GameCard(
                    game: game,
                    isFeatured: false,
                    onSelect: { selectedTeam in
                        presentBetModal(for: game, type: "Regular", selectedTeam: selectedTeam)
                    },
                    globalSelectedTeam: .constant(nil)
                )
                .scaleEffect(cardsAppeared ? 1.0 : 0.9)
                .opacity(cardsAppeared ? 1.0 : 0.0)
                .animation(
                    .spring(response: 0.8, dampingFraction: 0.8).delay(Double(index) * 0.1 + 0.5),
                    value: cardsAppeared
                )
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
    
    private func presentBetModal(for game: Game, type: String, selectedTeam: String? = nil) {
        print("🎯 \(type) game selected: \(game.homeTeam) vs \(game.awayTeam)")
        selectedGame = game
        preselectedTeam = selectedTeam
        print("✅ Modal data set - game: \(game.id), preselected team: \(selectedTeam ?? "none")")
    }
    
    // MARK: - Enhanced Refresh Function
    
    private func performRefresh() async {
        withAnimation(.easeInOut(duration: 0.3)) {
            isRefreshing = true
        }
        
        await viewModel.refreshGames()
        HapticManager.impact(.light)
        
        // Small delay for better UX
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isRefreshing = false
        }
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
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Enhanced Coin Balance Card (with teal heart)

struct EnhancedCoinBalanceCard: View {
    let type: CoinType
    let balance: Int
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // CHANGED: Using teal for green coin heart as requested
                Text(type == .yellow ? "🟡" : "💚")
                    .font(.system(size: 24))
                    .foregroundColor(type == .green ? Color(red: 0.0, green: 0.9, blue: 0.79) : nil)
                
                Spacer()
                
                Text(balance.formatted())
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            
            HStack {
                Text(type == .yellow ? "Play Coins" : "Real Coins")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            type == .green ?
                                Color(red: 0.0, green: 0.9, blue: 0.79).opacity(0.3) :
                                Color.yellow.opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
}

// MARK: - Supporting Structures

struct IdentifiableGame: Identifiable {
    let id = UUID()
    let game: Game
}

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
