//
//  GamesView.swift
//  BettorOdds
//
//  Version: 5.0.0 - COMPLETE: Fixed lock icons, sorting, and featured game logic
//  Updated: June 2025
//

import SwiftUI
import UIKit

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
                // Enhanced animated background
                enhancedAnimatedBackground
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        headerSection
                            .modifier(ScrollOffsetModifier(coordinateSpace: "scroll", offset: $scrollOffset))
                        
                        // FIXED: Featured Game (only for future, unlocked games)
                        if let featuredGame = viewModel.featuredGame, !featuredGame.isLocked && !featuredGame.shouldBeLocked {
                            featuredGameWithAnimatedBorder(game: featuredGame)
                        }
                        
                        // FIXED: Sorted Games Section - Active games first, locked games at bottom
                        sortedGamesSection
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
                    refreshIndicator
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(item: Binding<IdentifiableGame?>(
            get: { selectedGame.map(IdentifiableGame.init) },
            set: { _ in
                selectedGame = nil
                preselectedTeam = nil
            }
        )) { gameWrapper in
            BetModal(
                game: gameWrapper.game,
                user: authViewModel.user ?? User.guest,
                isPresented: .constant(true)
            )
        }
        .onAppear {
            setupInitialState()
        }
        .onChange(of: selectedLeague) { _, newLeague in
            Task {
                await viewModel.changeLeague(to: newLeague)
            }
        }
    }
    
    // MARK: - FIXED: Sorted Games Section
    private var sortedGamesSection: some View {
        LazyVStack(spacing: 16) {
            // First show active (unlocked) games
            ForEach(Array(activeGames.enumerated()), id: \.element.id) { index, game in
                FixedGameCard(
                    game: game,
                    isFeatured: false,
                    onSelect: { selectedTeam in
                        presentBetModal(for: game, selectedTeam: selectedTeam)
                    }
                )
                .scaleEffect(cardsAppeared ? 1.0 : 0.9)
                .opacity(cardsAppeared ? 1.0 : 0.0)
                .animation(
                    .spring(response: 0.8, dampingFraction: 0.8).delay(Double(index) * 0.1 + 0.5),
                    value: cardsAppeared
                )
            }
            
            // FIXED: Then show locked games at the bottom with visual separation
            if !lockedGames.isEmpty {
                lockedGamesSection
            }
        }
    }
    
    // MARK: - FIXED: Locked Games Section
    private var lockedGamesSection: some View {
        VStack(spacing: 16) {
            // Section divider
            HStack {
                VStack {
                    Divider()
                        .background(Color.white.opacity(0.3))
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.red)
                    
                    Text("LOCKED GAMES")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.red.opacity(0.1))
                        .overlay(
                            Capsule()
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
                
                VStack {
                    Divider()
                        .background(Color.white.opacity(0.3))
                }
            }
            .padding(.vertical, 8)
            
            // Locked games
            ForEach(Array(lockedGames.enumerated()), id: \.element.id) { index, game in
                FixedGameCard(
                    game: game,
                    isFeatured: false,
                    onSelect: { _ in
                        // No action for locked games - just haptic feedback
                        HapticManager.impact(.heavy)
                    }
                )
                .opacity(0.6) // Visual indication that it's locked
                .scaleEffect(cardsAppeared ? 1.0 : 0.9)
                .animation(
                    .spring(response: 0.8, dampingFraction: 0.8).delay(Double(activeGames.count + index) * 0.1 + 0.7),
                    value: cardsAppeared
                )
            }
        }
    }
    
    // MARK: - FIXED: Computed Properties for Game Sorting
    private var activeGames: [Game] {
        let featuredGameId = viewModel.featuredGame?.id
        return viewModel.games
            .filter { game in
                // Exclude featured game and only show unlocked games
                game.id != featuredGameId && !game.isLocked && !game.shouldBeLocked
            }
            .sorted { game1, game2 in
                // Sort by game time (earliest first)
                game1.time < game2.time
            }
    }
    
    private var lockedGames: [Game] {
        return viewModel.games
            .filter { game in
                // Only show locked games
                game.isLocked || game.shouldBeLocked
            }
            .sorted { game1, game2 in
                // Sort locked games by time as well
                game1.time < game2.time
            }
    }
    
    // MARK: - Enhanced Background
    private var enhancedAnimatedBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.06, green: 0.13, blue: 0.15),
                Color(red: 0.13, green: 0.23, blue: 0.26),
                Color(red: 0.17, green: 0.33, blue: 0.39)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .hueRotation(.degrees(scrollOffset / 3))
        .animation(.easeOut(duration: 0.3), value: scrollOffset)
        .ignoresSafeArea()
    }
    
    // MARK: - Enhanced Header Section with Balance Cards and Daily Limit
    private var headerSection: some View {
        VStack(spacing: 20) {
            // App title
            HStack {
                Text("BettorOdds")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("🎯")
                    .font(.system(size: 24))
            }
            
            // RESTORED: Balance Cards Row
            HStack(spacing: 16) {
                EnhancedCoinBalanceCard(type: .yellow, balance: authViewModel.user?.yellowCoins ?? 0)
                EnhancedCoinBalanceCard(type: .green, balance: authViewModel.user?.greenCoins ?? 0)
            }
            
            // RESTORED: Daily Limit Section
            dailyLimitSection
            
            // League selector
            leagueSelector
        }
    }
    
    // MARK: - RESTORED: Enhanced Coin Balance Cards
    private func EnhancedCoinBalanceCard(type: CoinType, balance: Int) -> some View {
        HStack(spacing: 12) {
            Group {
                if type == .yellow {
                    Text("🟡")
                        .font(.system(size: 20))
                } else {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 16))
                        .foregroundColor(tealColor)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(balance)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text(type == .yellow ? "Play Coins" : "Real Coins")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            type == .yellow ? Color.yellow.opacity(0.3) : tealColor.opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
    }
    
    // MARK: - RESTORED: Daily Limit Section
    private var dailyLimitSection: some View {
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
    
    private var leagueSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(availableLeagues, id: \.self) { league in
                    Button(action: {
                        selectedLeague = league
                        HapticManager.impact(.light)
                    }) {
                        Text(league)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(selectedLeague == league ? .black : .white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedLeague == league ? tealColor : Color.white.opacity(0.1))
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                selectedLeague == league ? Color.clear : tealColor.opacity(0.3),
                                                lineWidth: 1
                                            )
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Featured Game with Border
    private func featuredGameWithAnimatedBorder(game: Game) -> some View {
        ZStack {
            FixedGameCard(
                game: game,
                isFeatured: true,
                onSelect: { selectedTeam in
                    presentBetModal(for: game, selectedTeam: selectedTeam)
                }
            )
            .overlay(animatedBorderGlow)
        }
        .scaleEffect(cardsAppeared ? 1.0 : 0.0)
        .animation(
            .spring(response: 0.8, dampingFraction: 0.8).delay(0.3),
            value: cardsAppeared
        )
    }
    
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
                .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                value: borderGlow
            )
            .onAppear {
                borderGlow = true
            }
    }
    
    private var refreshIndicator: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: tealColor))
            Text("Refreshing games...")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))
    }
    
    // MARK: - Helper Methods
    private func setupInitialState() {
        Task {
            await viewModel.changeLeague(to: selectedLeague)
            withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
                cardsAppeared = true
            }
        }
    }
    
    private func performRefresh() async {
        isRefreshing = true
        await viewModel.forceRefresh()
        try? await Task.sleep(nanoseconds: 500_000_000)
        withAnimation(.easeInOut(duration: 0.3)) {
            isRefreshing = false
        }
    }
    
    private func presentBetModal(for game: Game, selectedTeam: String?) {
        if !game.isLocked && !game.shouldBeLocked {
            selectedGame = game
            preselectedTeam = selectedTeam
        }
    }
}

// MARK: - ENHANCED: FixedGameCard with Vibrant Team Colors (No Black Middle) - FIXED VERSION
// Replace the existing FixedGameCard in Views/Games/GamesView.swift

struct FixedGameCard: View {
    let game: Game
    let isFeatured: Bool
    let onSelect: (String?) -> Void
    
    private let tealColor = Color(red: 0.0, green: 0.9, blue: 0.79)
    
    var body: some View {
        VStack(spacing: 0) {
            // FIXED: Header with lock indicator
            headerWithLockStatus
                .padding(.horizontal, 16)
                .padding(.top, 16)
            
            // Teams section
            enhancedTeamsSection
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                .padding(.top, 12)
        }
        .background(enhancedCardBackground) // ✅ FIXED: Using enhanced background
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(borderOverlay)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowOffset)
        .scaleEffect(isFeatured ? 1.02 : 1.0)
        .opacity(gameOpacity)
    }
    
    // MARK: - ENHANCED: Vibrant Card Background (NO BLACK MIDDLE!)
    private var enhancedCardBackground: some View {
        // ✅ ENHANCEMENT 1: Use getEnhancedTeamColors for better colors
        let awayColors = TeamColors.getEnhancedTeamColors(game.awayTeam)
        let homeColors = TeamColors.getEnhancedTeamColors(game.homeTeam)
        
        return LinearGradient(
            colors: [
                // ✅ ENHANCEMENT 2: Start with more vibrant away team colors
                enhanceColor(awayColors.primary, saturation: 1.4, brightness: 0.15).opacity(0.95),
                enhanceColor(awayColors.primary, saturation: 1.2, brightness: 0.1).opacity(0.8),
                enhanceColor(awayColors.secondary, saturation: 1.1, brightness: 0.08).opacity(0.6),
                
                // ✅ ENHANCEMENT 3: Replace black with blended team colors!
                Color.clear.opacity(0.1), // Subtle transparency instead of black
                blendedTeamColors(awayColors, homeColors).opacity(0.4), // Blended middle section
                
                // ✅ ENHANCEMENT 4: Transition to vibrant home team colors
                enhanceColor(homeColors.secondary, saturation: 1.1, brightness: 0.08).opacity(0.6),
                enhanceColor(homeColors.primary, saturation: 1.2, brightness: 0.1).opacity(0.8),
                enhanceColor(homeColors.primary, saturation: 1.4, brightness: 0.15).opacity(0.95)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        // ✅ ENHANCEMENT 5: Add subtle glow overlay for extra vibrancy
        .overlay(
            LinearGradient(
                colors: [
                    enhanceColor(awayColors.primary, saturation: 1.3).opacity(0.08),
                    Color.clear,
                    enhanceColor(homeColors.primary, saturation: 1.3).opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.overlay)
        )
    }
    
    // ✅ FIXED: Blended team colors for middle section (safe unwrapping)
    private func blendedTeamColors(_ away: TeamColors, _ home: TeamColors) -> Color {
        // Create a sophisticated blend of both team's colors using safe color mixing
        let awayUIColor = UIColor(away.primary)
        let homeUIColor = UIColor(home.primary)
        
        var awayR: CGFloat = 0, awayG: CGFloat = 0, awayB: CGFloat = 0, awayA: CGFloat = 0
        var homeR: CGFloat = 0, homeG: CGFloat = 0, homeB: CGFloat = 0, homeA: CGFloat = 0
        
        awayUIColor.getRed(&awayR, green: &awayG, blue: &awayB, alpha: &awayA)
        homeUIColor.getRed(&homeR, green: &homeG, blue: &homeB, alpha: &homeA)
        
        // Blend the RGB values
        let blendedR = (awayR + homeR) / 2
        let blendedG = (awayG + homeG) / 2
        let blendedB = (awayB + homeB) / 2
        
        return Color(red: Double(blendedR), green: Double(blendedG), blue: Double(blendedB))
    }
    
    // MARK: - Enhanced Color Helper (More Vibrant)
    private func enhanceColor(_ color: Color, saturation: Double = 1.0, brightness: Double = 0.0) -> Color {
        let uiColor = UIColor(color)
        var hue: CGFloat = 0
        var saturationValue: CGFloat = 0
        var brightnessValue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturationValue, brightness: &brightnessValue, alpha: &alpha)
        
        // ✅ ENHANCEMENT 6: More aggressive saturation and brightness enhancement
        let newSaturation = min(1.0, saturationValue * saturation)
        let newBrightness = min(1.0, max(0.15, brightnessValue + brightness)) // Ensure minimum brightness
        
        return Color(
            hue: Double(hue),
            saturation: Double(newSaturation),
            brightness: Double(newBrightness),
            opacity: Double(alpha)
        )
    }
    
    // MARK: - ✅ FIXED: Teams Section Using Existing Structure
    
    private var enhancedTeamsSection: some View {
        HStack(spacing: 0) {
            // Away team
            teamSide(
                teamName: game.awayTeam,
                spread: game.awaySpread,
                colors: TeamColors.getEnhancedTeamColors(game.awayTeam), // ✅ Use enhanced colors
                isHome: false
            )
            
            // VS indicator with lock awareness
            vsIndicatorWithLock
            
            // Home team
            teamSide(
                teamName: game.homeTeam,
                spread: game.homeSpread,
                colors: TeamColors.getEnhancedTeamColors(game.homeTeam), // ✅ Use enhanced colors
                isHome: true
            )
        }
    }
    
    // ✅ FIXED: Using existing teamSide function signature - spread is String, not Double
    private func teamSide(teamName: String, spread: String, colors: TeamColors, isHome: Bool) -> some View {
        Button(action: {
            if !game.isLocked && !game.shouldBeLocked {
                onSelect(teamName)
                HapticManager.impact(.medium)
            } else {
                HapticManager.impact(.heavy)
            }
        }) {
            VStack(spacing: 12) {
                Text(teamName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                
                // ✅ FIXED: Use spread directly since it's already formatted as String
                Text(spread)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(game.isLocked || game.shouldBeLocked)
    }
    
    // ✅ FIXED: VS Indicator with Lock Support
    private var vsIndicatorWithLock: some View {
        VStack(spacing: 6) {
            if game.isLocked || game.shouldBeLocked {
                // Show lock icon for locked games
                Image(systemName: "lock.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.red.opacity(0.9))
            } else {
                // Show @ symbol for unlocked games
                Text("@")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(width: 30)
    }
    
    // MARK: - Header Implementation
    
    private var headerWithLockStatus: some View {
        HStack {
            // League badge
            Text(game.league)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(leagueBadgeBackground)
            
            Spacer()
            
            // Time and lock status
            VStack(alignment: .trailing, spacing: 2) {
                if game.isLocked || game.shouldBeLocked {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.red)
                        Text("LOCKED")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.red)
                    }
                } else {
                    Text(formatGameTime(game.time))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
    }
    
    // MARK: - Styling Properties
    
    private var gameOpacity: Double {
        game.isLocked || game.shouldBeLocked ? 0.6 : 1.0
    }
    
    private var shadowColor: Color {
        if game.isLocked || game.shouldBeLocked {
            return .red.opacity(0.3)
        } else if isFeatured {
            return tealColor.opacity(0.4)
        } else {
            return .black.opacity(0.3)
        }
    }
    
    private var shadowRadius: CGFloat {
        return (game.isLocked || game.shouldBeLocked) ? 12 : (isFeatured ? 15 : 8)
    }
    
    private var shadowOffset: CGFloat {
        return (game.isLocked || game.shouldBeLocked) ? 6 : 4
    }
    
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                (game.isLocked || game.shouldBeLocked) ?
                    Color.red.opacity(0.5) : Color.white.opacity(0.15),
                lineWidth: (game.isLocked || game.shouldBeLocked) ? 2 : 1
            )
    }
    
    private var leagueBadgeBackground: some View {
        Capsule()
            .fill(Color.white.opacity(0.15))
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
    }
    
    // MARK: - ✅ FIXED: Helper Methods
    
    private func formatGameTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
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
