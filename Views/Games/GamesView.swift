//
//  GamesView.swift - Fixed All Compilation Issues
//  BettorOdds
//
//  Version: 3.0.1 - Fixed all compilation errors
//

import SwiftUI

struct GamesView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @StateObject private var gamesViewModel = GamesViewModel()
    @State private var showingBetSheet = false
    @State private var selectedGame: Game?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Enhanced background with teal accents
                backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Header Section with Teal Accents
                        headerSection
                        
                        // League Selection with Teal
                        leagueSelector
                        
                        // Featured Game Card
                        if let featuredGame = gamesViewModel.featuredGame {
                            featuredGameCard(featuredGame)
                        }
                        
                        // Section Header with Teal Accent
                        upcomingGamesHeader
                        
                        // Games List
                        gamesListSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
                .refreshable {
                    await gamesViewModel.refresh()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await gamesViewModel.loadItems()
            }
        }
        .sheet(isPresented: $showingBetSheet) {
            if let selectedGame = selectedGame,
               let user = authViewModel.user {
                BetModal(
                    game: selectedGame,
                    user: user,
                    isPresented: $showingBetSheet
                )
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.13, blue: 0.15),
                Color(red: 0.08, green: 0.18, blue: 0.20),
                Color(red: 0.10, green: 0.23, blue: 0.26)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                // App name with teal accent
                HStack(spacing: 8) {
                    Text("BettorOdds")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Teal accent dot
                    Circle()
                        .fill(Color("Primary"))
                        .frame(width: 8, height: 8)
                        .glow(color: Color("Primary"), radius: 4)
                }
                
                // Subtitle with better typography
                Text("Live Sports Betting")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.8))
            }
            
            Spacer()
            
            // Coin balances with teal accents
            coinBalancesView
        }
        .padding(.top, 20)
    }
    
    private var coinBalancesView: some View {
        HStack(spacing: 16) {
            // Yellow Coins
            coinBalance(
                icon: "🟡",
                amount: String(Int(authViewModel.user?.yellowCoins ?? 0)),
                label: "Play Coins",
                accentColor: Color.yellow
            )
            
            // Green Coins with teal accent
            coinBalance(
                icon: "💚",
                amount: String(Int(authViewModel.user?.greenCoins ?? 0)),
                label: "Real Coins",
                accentColor: Color("Primary")
            )
        }
    }
    
    private func coinBalance(icon: String, amount: String, label: String, accentColor: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Text(icon)
                    .font(.system(size: 16))
                Text(amount)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(accentColor.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(accentColor.opacity(0.5), lineWidth: 1)
                    )
            )
            
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(Color.white.opacity(0.7))
        }
    }
    
    // MARK: - League Selector
    
    private var leagueSelector: some View {
        VStack(spacing: 12) {
            // Daily Limit with teal accent
            dailyLimitView
            
            // League buttons
            HStack(spacing: 16) {
                leagueButton("NBA", isSelected: gamesViewModel.selectedLeague == "NBA")
                leagueButton("NFL", isSelected: gamesViewModel.selectedLeague == "NFL")
            }
        }
    }
    
    private var dailyLimitView: some View {
        HStack {
            Text("Daily Limit")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
            
            HStack(spacing: 8) {
                // Teal heart icon
                Image(systemName: "heart.fill")
                    .foregroundColor(Color("Primary"))
                    .font(.system(size: 14))
                    .glow(color: Color("Primary"), radius: 2)
                
                Text("$\(Int(gamesViewModel.dailyBetsTotal))/100")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color("Primary"))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color("Primary").opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color("Primary").opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    private func leagueButton(_ league: String, isSelected: Bool) -> some View {
        Button(action: {
            Task {
                await gamesViewModel.changeLeague(to: league)
            }
        }) {
            Text(league)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isSelected ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color("Primary") : Color.white.opacity(0.1))
                        .glow(color: isSelected ? Color("Primary") : .clear, radius: isSelected ? 8 : 0)
                )
        }
    }
    
    // MARK: - Section Header
    
    private var upcomingGamesHeader: some View {
        HStack {
            Text("Upcoming Games")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
            
            // Teal accent line
            Rectangle()
                .fill(Color("Primary"))
                .frame(width: 40, height: 3)
                .cornerRadius(1.5)
                .glow(color: Color("Primary"), radius: 2)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Featured Game Card
    
    private func featuredGameCard(_ game: Game) -> some View {
        Button(action: {
            selectedGame = game
            showingBetSheet = true
        }) {
            VStack(spacing: 0) {
                // Featured badge with teal glow
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.black)
                            .font(.system(size: 12))
                        Text("Featured")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color("Primary"))
                    .cornerRadius(12)
                    .glow(color: Color("Primary"), radius: 6)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Game content
                gameCardContent(game, isFeatured: true)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Games List
    
    private var gamesListSection: some View {
        LazyVStack(spacing: 16) {
            ForEach(gamesViewModel.games.filter { !$0.isFeatured }) { game in
                Button(action: {
                    selectedGame = game
                    showingBetSheet = true
                }) {
                    gameCardContent(game, isFeatured: false)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private func gameCardContent(_ game: Game, isFeatured: Bool) -> some View {
        VStack(spacing: 16) {
            // Teams and spread
            HStack {
                // Away team
                teamView(
                    name: game.awayTeam,
                    colors: game.awayTeamColors,
                    spread: game.spread > 0 ? "+\(String(format: "%.1f", game.spread))" : nil
                )
                
                Spacer()
                
                // VS indicator with teal accent
                Text("@")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color("Primary"))
                    .glow(color: Color("Primary"), radius: 2)
                
                Spacer()
                
                // Home team
                teamView(
                    name: game.homeTeam,
                    colors: game.homeTeamColors,
                    spread: game.spread < 0 ? String(format: "%.1f", game.spread) : nil
                )
            }
            
            // Game time and info
            gameInfoView(game, isFeatured: isFeatured)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isFeatured ?
                      LinearGradient(colors: [Color("Primary").opacity(0.2), Color("Primary").opacity(0.1)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing) :
                      LinearGradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isFeatured ? Color("Primary").opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .glow(color: isFeatured ? Color("Primary") : .clear, radius: isFeatured ? 8 : 0)
    }
    
    private func teamView(name: String, colors: TeamColors, spread: String?) -> some View {
        VStack(spacing: 8) {
            Text(name)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            if let spread = spread {
                Text(spread)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color("Primary"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color("Primary").opacity(0.2))
                    )
            }
        }
    }
    
    private func gameInfoView(_ game: Game, isFeatured: Bool) -> some View {
        HStack {
            // Time
            Text(game.time, style: .time)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            // Bet count with teal accent
            HStack(spacing: 4) {
                Image(systemName: "person.2.fill")
                    .foregroundColor(Color("Primary"))
                    .font(.system(size: 12))
                Text("\(game.totalBets)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Color("Primary"))
            }
        }
    }
}

// MARK: - Glow Effect Extension

extension View {
    func glow(color: Color, radius: CGFloat) -> some View {
        self
            .shadow(color: color, radius: radius / 3)
            .shadow(color: color, radius: radius / 3)
            .shadow(color: color, radius: radius / 3)
    }
}

#Preview {
    GamesView()
        .environmentObject(AuthenticationViewModel())
}
