//
//  GamesView.swift
//  BettorOdds
//
//  Version: 2.5.0 - Clean solution using fullScreenCover instead of sheet
//

import SwiftUI

struct GamesView: View {
    // MARK: - Properties
    @StateObject private var viewModel = GamesViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var selectedGameForBetting: Game? = nil  // Renamed for clarity
    @State private var showBetModal = false
    @State private var selectedLeague = "NBA"
    @State private var globalSelectedTeam: (gameId: String, team: TeamSelection)? = nil
    @State private var scrollOffset: CGFloat = 0
    @State private var isViewReady = false
    
    let leagues = ["NBA", "NFL"]
    
    // Background gradient colors
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color("Primary").opacity(0.2),
                Color.white.opacity(0.1),
                Color("Primary").opacity(0.2)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated Background
                backgroundGradient
                    .hueRotation(.degrees(scrollOffset / 2))
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Enhanced Header
                    VStack(spacing: 8) {
                        Text("BettorOdds")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color("Primary"))
                            .shadow(color: Color("Primary").opacity(0.3), radius: 2, x: 0, y: 2)
                        
                        // Balance Display
                        HStack(spacing: 16) {
                            CoinBalanceView(
                                emoji: "🟡",
                                amount: authViewModel.user?.yellowCoins ?? 0
                            )
                            CoinBalanceView(
                                emoji: "💚",
                                amount: authViewModel.user?.greenCoins ?? 0
                            )
                            
                            // Daily Limit Progress
                            DailyLimitProgressView(
                                used: authViewModel.user?.dailyGreenCoinsUsed ?? 0
                            )
                        }
                        .padding(.horizontal)
                        
                        // League Selection
                        HStack(spacing: 12) {
                            ForEach(leagues, id: \.self) { league in
                                LeagueButton(
                                    league: league,
                                    isSelected: selectedLeague == league
                                ) {
                                    selectedLeague = league
                                    print("🏈 Selected league: \(league)")
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 8)
                    
                    // Games Content
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Featured Game
                            if let featured = viewModel.featuredGame {
                                FeaturedGameCard(
                                    game: featured,
                                    onSelect: {
                                        showBettingModal(for: featured)
                                    }
                                )
                                .padding(.horizontal)
                            }
                            
                            // Display rest of the games
                            let filteredGames = viewModel.games.filter { game in
                                let shouldShow = game.isVisible &&
                                game.league == selectedLeague &&
                                game.id != viewModel.featuredGame?.id
                                
                                return shouldShow
                            }.sorted { $0.sortPriority == $1.sortPriority ?
                                $0.time < $1.time :
                                $0.sortPriority < $1.sortPriority }
                            
                            ForEach(filteredGames) { game in
                                GameCard(
                                    game: game,
                                    isFeatured: false,
                                    onSelect: {
                                        showBettingModal(for: game)
                                    },
                                    globalSelectedTeam: $globalSelectedTeam
                                )
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    .refreshable {
                        print("♻️ Pull-to-refresh triggered")
                        await viewModel.refreshGames()
                    }
                    .modifier(ScrollOffsetModifier(coordinateSpace: "scroll", offset: $scrollOffset))
                    .coordinateSpace(name: "scroll")
                }
            }
            .onAppear {
                print("📱 Games screen appeared - refreshing data")
                isViewReady = true
                Task {
                    await viewModel.refreshGames()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                print("📱 App entering foreground - refreshing games")
                Task {
                    await viewModel.refreshGames()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        // CLEAN SOLUTION: Use fullScreenCover which has better state management
        .fullScreenCover(item: $selectedGameForBetting, onDismiss: {
            print("🎲 BetModal dismissed - clearing selectedGameForBetting")
            selectedGameForBetting = nil
        }) { game in
            BetModalView(game: game, user: authViewModel.user!)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Shows betting modal for the selected game
    private func showBettingModal(for game: Game) {
        print("🎮 Showing betting modal for: \(game.homeTeam) vs \(game.awayTeam)")
        
        guard authViewModel.user != nil else {
            print("❌ No authenticated user")
            return
        }
        
        // This approach uses the item-based fullScreenCover which handles state better
        selectedGameForBetting = game
    }
}

// MARK: - Wrapper View for BetModal

struct BetModalView: View {
    let game: Game
    let user: User
    @Environment(\.dismiss) private var dismiss
    @State private var showModal = true  // Internal state for the BetModal
    
    var body: some View {
        BetModal(
            game: game,
            user: user,
            isPresented: $showModal
        )
        .onAppear {
            print("✅ BetModalView appeared successfully!")
            print("🎮 Game: \(game.homeTeam) vs \(game.awayTeam)")
        }
        .onChange(of: showModal) { _, newValue in
            // When BetModal sets showModal to false, dismiss the fullScreenCover
            if !newValue {
                print("🎲 BetModal requested dismissal")
                dismiss()
            }
        }
    }
}

// MARK: - Supporting Views

struct CoinBalanceView: View {
    let emoji: String
    let amount: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Text(emoji)
                .font(.system(size: 18))
            Text("\(amount)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct DailyLimitProgressView: View {
    let used: Int
    let limit: Int = 100
    
    var progress: CGFloat {
        min(CGFloat(used) / CGFloat(limit), 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Daily Limit")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                    
                    Rectangle()
                        .fill(Color("Primary"))
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 4)
            .cornerRadius(2)
            
            Text("💚 \(used)/\(limit)")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(height: 40)
    }
}

struct LeagueButton: View {
    let league: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(league)
                .font(.system(size: 16, weight: .semibold))
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color("Primary") : Color.gray.opacity(0.1))
                        .shadow(color: isSelected ? Color("Primary").opacity(0.5) : .clear, radius: 6, x: 0, y: 3)
                )
                .foregroundColor(isSelected ? .white : Color("Primary"))
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color("Primary").opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scroll Offset Tracking

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ScrollOffsetModifier: ViewModifier {
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

// MARK: - Preview

#Preview {
    GamesView()
        .environmentObject(AuthenticationViewModel())
}
