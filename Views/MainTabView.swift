//
//  MainTabView.swift
//  BettorOdds
//
//  Version: 5.0.0 - COMPLETE: Fixed filter wrapping, enhanced bet cards, working explore button
//  Updated: June 2025
//

import SwiftUI
import FirebaseFirestore

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @StateObject private var adminNav = AdminNavigation.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Games Tab - Using our fixed GamesView
            GamesView()
                .tabItem {
                    Label("Games", systemImage: "sportscourt.fill")
                }
                .tag(0)
            
            // My Bets Tab - Enhanced version with tab navigation binding
            SimplifiedMyBetsTabView(selectedTab: $selectedTab)
                .tabItem {
                    Label("My Bets", systemImage: "list.bullet.clipboard")
                }
                .tag(1)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(2)
            
            // Admin Tab (only if user is admin)
            if authViewModel.user?.adminRole == .admin {
                AdminDashboardView()
                    .onAppear {
                        Task {
                            // Pass the user to the admin check
                            await adminNav.checkAdminAccess(user: authViewModel.user)
                        }
                    }
                    .tabItem {
                        Label("Admin", systemImage: "shield.fill")
                    }
                    .tag(3)
            }
        }
        .accentColor(.primary)
        .sheet(isPresented: $adminNav.requiresAuth) {
            AdminAuthView()
        }
        .alert("Error", isPresented: $adminNav.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(adminNav.errorMessage ?? "An unknown error occurred")
        }
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            UITabBar.appearance().scrollEdgeAppearance = appearance
            
            HapticManager.impact(.light)
        }
        .onChange(of: selectedTab) { _, _ in
            HapticManager.impact(.light)
        }
    }
}

// MARK: - FIXED: My Bets Tab View with Enhanced Bet Cards and Working Navigation

struct SimplifiedMyBetsTabView: View {
    @StateObject private var viewModel = MyBetsViewModel()
    @State private var selectedFilter: BetFilter = .active
    @State private var showCancelConfirmation = false
    @State private var betToCancel: Bet?
    @State private var isRefreshing = false
    @State private var statsAnimation = false
    
    // FIXED: Tab navigation binding
    @Binding var selectedTab: Int
    
    private let tealColor = Color(red: 0.0, green: 0.9, blue: 0.79)
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.06, green: 0.13, blue: 0.15),
                        Color(red: 0.13, green: 0.23, blue: 0.26),
                        Color(red: 0.17, green: 0.33, blue: 0.39)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Stats Overview
                    enhancedStatsOverview
                        .padding(.bottom, 20)
                    
                    // FIXED: Filter tabs (no more wrapping)
                    fixedFilterTabsWithCounts
                    
                    // Bets List
                    enhancedBetsListSection
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    await viewModel.loadBets()
                    startStatsAnimation()
                }
            }
            .refreshable {
                await performRefresh()
            }
            .alert("Cancel Bet", isPresented: $showCancelConfirmation) {
                Button("Cancel Bet", role: .destructive) {
                    if let bet = betToCancel {
                        Task {
                            await viewModel.cancelBet(bet)
                        }
                    }
                }
                Button("Keep Bet", role: .cancel) {}
            } message: {
                Text("Are you sure you want to cancel this bet? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("My Bets")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.white)
                
                Text("Track your betting journey")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Text("🎯")
                .font(.system(size: 24))
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Enhanced Stats Overview
    
    private var enhancedStatsOverview: some View {
        HStack(spacing: 12) {
            enhancedStatCard("Won", count: wonBetsCount, color: .green, delay: 0.0)
            enhancedStatCard("Lost", count: lostBetsCount, color: .red, delay: 0.3)
            enhancedStatCard("Active", count: pendingBetsCount, color: tealColor, delay: 0.6)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    private func enhancedStatCard(_ title: String, count: Int, color: Color, delay: Double) -> some View {
        VStack(spacing: 8) {
            Image(systemName: iconForStat(title))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
                .scaleEffect(statsAnimation ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(delay), value: statsAnimation)
            
            Text("\(count)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func iconForStat(_ title: String) -> String {
        switch title {
        case "Won":
            return "checkmark.circle.fill"
        case "Lost":
            return "xmark.circle.fill"
        case "Active":
            return "clock.fill"
        default:
            return "sportscourt.fill"
        }
    }
    
    // MARK: - FIXED: Filter Tabs (No More Wrapping)
    
    private var fixedFilterTabsWithCounts: some View {
        HStack(spacing: 12) {
            // FIXED: Use shorter text and better sizing
            fixedFilterTab(.active, "Active")
            fixedFilterTab(.completed, "Done") // SHORTENED to prevent wrapping
            fixedFilterTab(.all, "All")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    private func fixedFilterTab(_ filter: BetFilter, _ displayText: String) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedFilter = filter
            }
            HapticManager.impact(.light)
        }) {
            VStack(spacing: 6) {
                // FIXED: Single line with proper constraints (REMOVED the line indicator)
                HStack(spacing: 4) {
                    Text(displayText)
                        .font(.system(size: 13, weight: .bold)) // Slightly smaller font
                        .foregroundColor(selectedFilter == filter ? .black : .white)
                        .lineLimit(1) // CRITICAL: Prevent wrapping
                        .minimumScaleFactor(0.8) // Allow slight scaling if needed
                    
                    // Count badge
                    Text("\(getFilteredCount(for: filter))")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(selectedFilter == filter ? .black.opacity(0.7) : tealColor)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(
                            Capsule()
                                .fill(selectedFilter == filter ? Color.black.opacity(0.1) : tealColor.opacity(0.2))
                        )
                }
                
                // REMOVED: The line indicator that was causing the visual issue
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50) // FIXED: Consistent height
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(
                        selectedFilter == filter ?
                            LinearGradient(
                                colors: [tealColor, tealColor.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            ) :
                            LinearGradient(
                                colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(
                                selectedFilter == filter ? tealColor : Color.white.opacity(0.2),
                                lineWidth: selectedFilter == filter ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(selectedFilter == filter ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedFilter == filter)
    }
    
    // MARK: - Enhanced Bets List
    
    private var enhancedBetsListSection: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.isLoading {
                    enhancedLoadingView
                } else if filteredBets.isEmpty {
                    // FIXED: Enhanced empty state with working explore button
                    enhancedEmptyStateView
                } else {
                    ForEach(Array(filteredBets.enumerated()), id: \.element.id) { index, bet in
                        // ENHANCED: Use new bet card with full matchup
                        EnhancedBetCard(
                            bet: bet,
                            onCancelTapped: {
                                betToCancel = bet
                                showCancelConfirmation = true
                            }
                        )
                        .scaleEffect(1.0)
                        .opacity(1.0)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.05),
                            value: viewModel.bets.count
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .coordinateSpace(name: "scroll")
    }
    
    // MARK: - Enhanced Loading View
    
    private var enhancedLoadingView: some View {
        VStack(spacing: 20) {
            // Animated loading icon
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 32))
                .foregroundColor(tealColor)
                .rotationEffect(.degrees(statsAnimation ? 360 : 0))
                .animation(.linear(duration: 2.0).repeatForever(autoreverses: false), value: statsAnimation)
            
            Text("Loading your bets...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - FIXED: Enhanced Empty State with Working Explore Button
    
    private var enhancedEmptyStateView: some View {
        VStack(spacing: 24) {
            // Dynamic icon based on filter
            Image(systemName: emptyStateIcon)
                .font(.system(size: 48))
                .foregroundColor(tealColor.opacity(0.6))
                .scaleEffect(statsAnimation ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: statsAnimation)
            
            // Title and message
            VStack(spacing: 12) {
                Text(emptyStateTitle)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(emptyStateMessage)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
            }
            
            // FIXED: Working explore button (only for active/all filters)
            if selectedFilter == .active || selectedFilter == .all {
                Button(action: {
                    // Navigate to Games tab
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = 0
                    }
                    HapticManager.impact(.medium)
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Explore Games")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [tealColor, tealColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(
                                color: tealColor.opacity(0.4),
                                radius: 12,
                                x: 0,
                                y: 6
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 40)
    }
    
    // MARK: - Computed Properties
    
    private var filteredBets: [Bet] {
        switch selectedFilter {
        case .active:
            return viewModel.bets.filter {
                $0.status == .pending || $0.status == .active || $0.status == .partiallyMatched || $0.status == .fullyMatched
            }
        case .completed:
            return viewModel.bets.filter {
                $0.status == .won || $0.status == .lost || $0.status == .cancelled
            }
        case .all:
            return viewModel.bets
        }
    }
    
    private var wonBetsCount: Int {
        viewModel.bets.filter { $0.status == .won }.count
    }
    
    private var lostBetsCount: Int {
        viewModel.bets.filter { $0.status == .lost }.count
    }
    
    private var pendingBetsCount: Int {
        viewModel.bets.filter {
            $0.status == .pending || $0.status == .active || $0.status == .partiallyMatched || $0.status == .fullyMatched
        }.count
    }
    
    private var emptyStateIcon: String {
        switch selectedFilter {
        case .active:
            return "clock.badge.exclamationmark"
        case .completed:
            return "checkmark.circle"
        case .all:
            return "sportscourt"
        }
    }
    
    private var emptyStateTitle: String {
        switch selectedFilter {
        case .active:
            return "No Active Bets"
        case .completed:
            return "No Completed Bets"
        case .all:
            return "Ready to Start Betting?"
        }
    }
    
    private var emptyStateMessage: String {
        switch selectedFilter {
        case .active:
            return "You don't have any active bets right now. Head to Games to place your next winning bet!"
        case .completed:
            return "You haven't completed any bets yet. Your betting history will appear here once games are finished."
        case .all:
            return "This is where all your betting action will live! Start with some practice bets using Play Coins, then move to Real Coins when you're ready."
        }
    }
    
    // MARK: - Helper Functions
    
    private func getFilteredCount(for filter: BetFilter) -> Int {
        switch filter {
        case .active:
            return pendingBetsCount
        case .completed:
            return wonBetsCount + lostBetsCount + viewModel.bets.filter { $0.status == .cancelled }.count
        case .all:
            return viewModel.bets.count
        }
    }
    
    private func startStatsAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            statsAnimation = true
        }
    }
    
    private func performRefresh() async {
        withAnimation(.easeInOut(duration: 0.3)) {
            isRefreshing = true
        }
        
        await viewModel.loadBets()
        HapticManager.impact(.light)
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isRefreshing = false
        }
    }
}

// MARK: - ENHANCED: Bet Card with Full Matchup Display
struct EnhancedBetCard: View {
    let bet: Bet
    let onCancelTapped: () -> Void
    
    @StateObject private var gameLoader = GameDataLoader()
    
    private let tealColor = Color(red: 0.0, green: 0.9, blue: 0.79)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with status and timestamp
            HStack {
                statusBadge
                Spacer()
                timeStamp
            }
            
            // ENHANCED: Full game matchup info with opponent
            VStack(alignment: .leading, spacing: 12) {
                // Show the complete matchup
                if let gameInfo = gameLoader.gameInfo {
                    fullMatchupDisplay(gameInfo: gameInfo)
                } else {
                    // Fallback display while loading
                    fallbackDisplay
                }
                
                // Bet details
                betDetailsSection
            }
            
            // Potential winnings and actions
            if bet.status == .pending || bet.status == .active {
                actionsSection
            }
        }
        .padding(20)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
        .onAppear {
            Task {
                await gameLoader.loadGameInfo(for: bet.gameId)
            }
        }
    }
    
    // MARK: - IMPROVED: Full Matchup Display with Better Layout
    private func fullMatchupDisplay(gameInfo: GameInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // IMPROVED: Compact game matchup header
            HStack {
                Text("MATCHUP")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                Text(gameInfo.league)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(tealColor)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(tealColor.opacity(0.2)))
            }
            
            // IMPROVED: More compact team vs team display
            VStack(spacing: 6) {
                // Away team row
                HStack(spacing: 8) {
                    Text("Away")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 30, alignment: .leading)
                    
                    Text(gameInfo.awayTeam)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(bet.team == gameInfo.awayTeam ? tealColor : .white.opacity(0.7))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Spacer()
                    
                    Text(formattedGameTime(gameInfo.gameTime))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                // Home team row
                HStack(spacing: 8) {
                    Text("Home")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 30, alignment: .leading)
                    
                    Text(gameInfo.homeTeam)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(bet.team == gameInfo.homeTeam ? tealColor : .white.opacity(0.7))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Spacer()
                    
                    Text(formattedGameDate(gameInfo.gameTime))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // IMPROVED: More compact bet highlight
            HStack(spacing: 4) {
                Text("YOUR BET:")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(bet.team)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(tealColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                if bet.initialSpread != 0 {
                    Text(spreadDisplay)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
        }
        .padding(10) // Reduced padding
        .background(
            RoundedRectangle(cornerRadius: 10) // Slightly smaller corner radius
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - IMPROVED: Fallback Display (while loading)
    private var fallbackDisplay: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("MATCHUP")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                ProgressView()
                    .scaleEffect(0.6)
                    .progressViewStyle(CircularProgressViewStyle(tint: tealColor))
            }
            
            HStack(spacing: 4) {
                Text("YOUR BET:")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(bet.team)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(tealColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                if bet.initialSpread != 0 {
                    Text(spreadDisplay)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
        }
        .padding(10) // Match the main display padding
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Computed Properties
    private var statusBadge: some View {
        Text(bet.status.rawValue.uppercased())
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(bet.status.color.opacity(0.8))
                    .overlay(
                        Capsule()
                            .stroke(bet.status.color, lineWidth: 1)
                    )
            )
    }
    
    private var timeStamp: some View {
        Text(formatTimestamp(bet.createdAt))
            .font(.system(size: 11))
            .foregroundColor(.white.opacity(0.6))
    }
    
    private var spreadDisplay: String {
        let spread = bet.initialSpread
        if spread > 0 {
            return "+\(String(format: "%.1f", spread))"
        } else {
            return String(format: "%.1f", spread)
        }
    }
    
    private var betDetailsSection: some View {
        HStack {
            HStack(spacing: 4) {
                Group {
                    if bet.coinType == .yellow {
                        Text("🟡")
                            .font(.system(size: 14))
                    } else {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14))
                            .foregroundColor(tealColor)
                    }
                }
                
                Text("\(bet.amount)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text(bet.coinType.displayName)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            if bet.status == .won || bet.status == .lost {
                HStack(spacing: 4) {
                    Text(bet.status == .won ? "WON:" : "LOST:")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(bet.status == .won ? .green : .red)
                    
                    Text("\(bet.status == .won ? bet.potentialWinnings : 0)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(bet.status == .won ? .green : .red)
                }
            }
        }
    }
    
    private var actionsSection: some View {
        HStack {
            Text("Potential win:")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
            
            Text("\(bet.potentialWinnings) coins")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.green)
            
            Spacer()
            
            if bet.status == .pending {
                Button("Cancel") {
                    onCancelTapped()
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .stroke(.red, lineWidth: 1)
                )
            }
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.08),
                        Color.white.opacity(0.04)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
    
    private var shadowColor: Color {
        switch bet.status {
        case .won:
            return .green.opacity(0.3)
        case .lost:
            return .red.opacity(0.3)
        case .active:
            return tealColor.opacity(0.3)
        default:
            return .black.opacity(0.2)
        }
    }
    
    // MARK: - Helper Methods
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d 'at' h:mm a"
        return formatter.string(from: date)
    }
    
    private func formattedGameDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func formattedGameTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Game Data Loader
@MainActor
class GameDataLoader: ObservableObject {
    @Published var gameInfo: GameInfo?
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    
    func loadGameInfo(for gameId: String) async {
        guard !isLoading else { return }
        
        isLoading = true
        
        do {
            let document = try await db.collection("games").document(gameId).getDocument()
            
            if let data = document.data() {
                gameInfo = GameInfo(
                    homeTeam: data["homeTeam"] as? String ?? "Unknown",
                    awayTeam: data["awayTeam"] as? String ?? "Unknown",
                    league: data["league"] as? String ?? "Unknown",
                    gameTime: (data["time"] as? Timestamp)?.dateValue() ?? Date()
                )
            }
        } catch {
            print("Error loading game info: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - Game Info Model
struct GameInfo {
    let homeTeam: String
    let awayTeam: String
    let league: String
    let gameTime: Date
}

// MARK: - BetFilter Definition
enum BetFilter: CaseIterable {
    case active
    case completed
    case all
    
    var displayName: String {
        switch self {
        case .active:
            return "Active"
        case .completed:
            return "Completed"
        case .all:
            return "All"
        }
    }
}

// MARK: - Admin Auth View
struct AdminAuthView: View {
    @StateObject private var adminNav = AdminNavigation.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.primary)
                
                Text("Admin Authentication Required")
                    .font(.title2)
                    .foregroundColor(.primary)
                
                Text("Please authenticate to access admin features")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Authenticate") {
                    Task {
                        await adminNav.authenticateAdmin()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.primary)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(32)
            .navigationTitle("Admin Access")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
        .environmentObject(AuthenticationViewModel())
}
