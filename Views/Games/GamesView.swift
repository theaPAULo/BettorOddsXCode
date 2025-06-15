//
//  Enhanced GamesView.swift - Matching Profile Style
//  Replace your entire GamesView.swift with this
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
                        
                        // Featured Game Card
                        if let featuredGame = viewModel.featuredGame {
                            featuredGameSection(game: featuredGame)
                        }
                        
                        // Upcoming Games Section
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
        }
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
    
    // MARK: - Header Section (SUBTLE GOLD)
    
    private var headerSection: some View {
        VStack(spacing: 24) {
            // App Title with SUBTLE GOLD GRADIENT
            HStack(spacing: 8) {
                Text("BettorOdds")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white,                                    // Pure white at start
                                Color.white,                                    // Stay white for most of the text
                                Color.white.opacity(0.95),                     // Very subtle transition
                                Color(red: 1.0, green: 0.98, blue: 0.9),      // Tiny hint of warmth
                                Color(red: 1.0, green: 0.92, blue: 0.8)       // Subtle gold at the very end
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                
                // BRIGHT TEAL DOT
                Circle()
                    .fill(tealColor)
                    .frame(width: 12, height: 12)
                    .shadow(color: tealColor.opacity(0.6), radius: 4, x: 0, y: 0)
            }
            
            // Balance Cards Row - PROFILE STYLE
            HStack(spacing: 16) {
                // Play Coins
                CoinBalanceCard(type: .yellow, balance: authViewModel.user?.yellowCoins ?? 0)
                
                // Real Coins
                CoinBalanceCard(type: .green, balance: authViewModel.user?.greenCoins ?? 0)
            }
            
            // Daily Limit - PROFILE STYLE CARD
            VStack(spacing: 12) {
                HStack {
                    Text("Daily Limit")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
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
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.1),
                        Color.white.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            
            // League Selection - PROFILE STYLE
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
    
    // MARK: - Featured Game Section
    
    private func featuredGameSection(game: Game) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Featured Game")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            GameCard(
                game: game,
                isFeatured: true,
                onSelect: {
                    selectedGame = game
                    showBetModal = true
                },
                globalSelectedTeam: .constant(nil)
            )
        }
        .scaleEffect(cardsAppeared ? 1.0 : 0.9)
        .opacity(cardsAppeared ? 1.0 : 0.0)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2), value: cardsAppeared)
    }
    
    // MARK: - Upcoming Games Section
    
    private var upcomingGamesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Upcoming Games")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Subtle teal accent
                Rectangle()
                    .fill(tealColor)
                    .frame(width: 40, height: 3)
                    .cornerRadius(2)
            }
            
            LazyVStack(spacing: 16) {
                ForEach(Array(viewModel.games.enumerated()), id: \.element.id) { index, game in
                    if !game.isFeatured {
                        GameCard(
                            game: game,
                            isFeatured: false,
                            onSelect: {
                                selectedGame = game
                                showBetModal = true
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

// MARK: - ScrollOffset Modifier (matching ProfileView)

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

// MARK: - CoinBalanceCard (matching ProfileView style)

struct CoinBalanceCard: View {
    let type: CoinType
    let balance: Int
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(type == .yellow ? "🟡" : "💚")
                    .font(.system(size: 24))
                Spacer()
                Text(balance.formatted())
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            
            HStack {
                Text(type == .yellow ? "Play Coins" : "Real Coins")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.1),
                    Color.white.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(type == .yellow ?
                    Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3) :
                    Color(red: 0.0, green: 0.9, blue: 0.79).opacity(0.3),
                    lineWidth: 1)
        )
    }
}

#Preview {
    GamesView()
        .environmentObject(AuthenticationViewModel())
}
