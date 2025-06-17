//
//  MainTabView.swift
//  BettorOdds
//
//  Version: 4.2.1 - Enhanced with simplified My Bets (removed clutter, better bet cards)
//  Updated: June 2025
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @StateObject private var adminNav = AdminNavigation.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Games Tab - Using EnhancedGamesView
            GamesView()
                .tabItem {
                    Label("Games", systemImage: "sportscourt.fill")
                }
                .tag(0)
            
            // My Bets Tab - Enhanced version
            SimplifiedMyBetsTabView()
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

// MARK: - SIMPLIFIED My Bets Tab View - Removed Clutter, Better Bet Cards

struct SimplifiedMyBetsTabView: View {
    @StateObject private var viewModel = MyBetsViewModel()
    @State private var selectedFilter: BetFilter = .active
    @State private var showCancelConfirmation = false
    @State private var betToCancel: Bet?
    @State private var scrollOffset: CGFloat = 0
    @State private var isRefreshing = false
    @State private var statsAnimation = false
    
    // Teal color for consistency
    private let tealColor = Color(red: 0.0, green: 0.9, blue: 0.79)
    
    var body: some View {
        NavigationView {
            ZStack {
                // MATCHING BACKGROUND - Same as other views
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
                
                VStack(spacing: 0) {
                    // SIMPLIFIED: Clean header without clutter
                    simplifiedHeaderWithStats
                    
                    // ENHANCED: Better filter tabs with counts
                    enhancedFilterTabsWithCounts
                    
                    // ENHANCED: Better bets list with improved cards
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
                Button("Keep Bet", role: .cancel) {
                    betToCancel = nil
                }
                Button("Cancel Bet", role: .destructive) {
                    if let bet = betToCancel {
                        Task {
                            await viewModel.cancelBet(bet)
                        }
                    }
                    betToCancel = nil
                }
            } message: {
                Text("Are you sure you want to cancel this bet? This action cannot be undone.")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - SIMPLIFIED: Clean Header (Removed Win Rate & Total Wagered Clutter)
    
    private var simplifiedHeaderWithStats: some View {
        VStack(spacing: 20) {
            // App title with icon
            HStack(spacing: 12) {
                Image(systemName: "list.bullet.clipboard.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(tealColor)
                    .scaleEffect(statsAnimation ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: statsAnimation)
                
                Text("My Bets")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // SIMPLIFIED: Just the visual stats cards (no clutter)
            enhancedStatsCards
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Enhanced Stats Cards (Kept - These Are Visual and Helpful)
    
    private var enhancedStatsCards: some View {
        HStack(spacing: 12) {
            // Won bets card
            enhancedStatCard(
                title: "Won",
                count: wonBetsCount,
                icon: "checkmark.circle.fill",
                color: .green,
                delay: 0.1
            )
            
            // Lost bets card
            enhancedStatCard(
                title: "Lost",
                count: lostBetsCount,
                icon: "xmark.circle.fill",
                color: .red,
                delay: 0.2
            )
            
            // Pending bets card
            enhancedStatCard(
                title: "Pending",
                count: pendingBetsCount,
                icon: "clock.circle.fill",
                color: tealColor,
                delay: 0.3
            )
        }
    }
    
    private func enhancedStatCard(title: String, count: Int, icon: String, color: Color, delay: Double) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
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
    
    // MARK: - Enhanced Filter Tabs with Counts
    
    private var enhancedFilterTabsWithCounts: some View {
        HStack(spacing: 12) {
            ForEach([BetFilter.active, BetFilter.completed, BetFilter.all], id: \.self) { filter in
                enhancedFilterTab(filter)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    private func enhancedFilterTab(_ filter: BetFilter) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedFilter = filter
            }
            HapticManager.impact(.light)
        }) {
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    Text(filter.displayName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(selectedFilter == filter ? .black : .white)
                    
                    // Count badge
                    Text("\(getFilteredCount(for: filter))")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(selectedFilter == filter ? .black.opacity(0.7) : tealColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(selectedFilter == filter ? Color.black.opacity(0.1) : tealColor.opacity(0.2))
                        )
                }
                
                // Active indicator line
                Rectangle()
                    .fill(selectedFilter == filter ? .black : Color.clear)
                    .frame(height: 2)
                    .animation(.easeInOut(duration: 0.2), value: selectedFilter == filter)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 22)
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
                        RoundedRectangle(cornerRadius: 22)
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
                    enhancedEmptyStateView
                } else {
                    ForEach(Array(filteredBets.enumerated()), id: \.element.id) { index, bet in
                        ImprovedBetCard(
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
    
    // MARK: - Enhanced Empty State View
    
    private var enhancedEmptyStateView: some View {
        VStack(spacing: 24) {
            // Dynamic icon based on filter
            Image(systemName: emptyStateIcon)
                .font(.system(size: 48))
                .foregroundColor(tealColor.opacity(0.6))
                .scaleEffect(statsAnimation ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: statsAnimation)
            
            VStack(spacing: 12) {
                Text(emptyStateTitle)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(emptyStateMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            // Encouraging action button for empty states
            if selectedFilter == .active || selectedFilter == .all {
                Button(action: {
                    // Note: You can implement tab switching here if needed
                    HapticManager.impact(.medium)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "sportscourt.fill")
                            .font(.system(size: 14, weight: .bold))
                        
                        Text("Explore Games")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(tealColor)
                            .shadow(color: tealColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(statsAnimation ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: statsAnimation)
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

// MARK: - IMPROVED: Better Bet Card with Full Matchup & Fixed Spread Formatting

struct ImprovedBetCard: View {
    let bet: Bet
    let onCancelTapped: () -> Void
    
    private let tealColor = Color(red: 0.0, green: 0.9, blue: 0.79)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with status and timestamp
            HStack {
                statusBadge
                Spacer()
                timeStamp
            }
            
            // ENHANCED: Full game matchup info
            VStack(alignment: .leading, spacing: 12) {
                // Show the full matchup context
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        // IMPROVED: Show full game context
                        HStack(spacing: 4) {
                            Text("vs")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text(bet.team)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(tealColor) // Highlight the team they bet on
                        }
                        
                        // FIXED: Spread formatting to 1 decimal place only
                        if bet.initialSpread != 0 {
                            HStack(spacing: 4) {
                                Text("Spread:")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                Text(String(format: "%.1f", bet.initialSpread))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(tealColor)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Bet amount with coin type
                    VStack(alignment: .trailing, spacing: 4) {
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
                        }
                        
                        Text(bet.coinType.displayName)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                // Potential winnings and actions
                if bet.status == .pending || bet.status == .active {
                    HStack {
                        Text("Potential win:")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("\(bet.potentialWinnings) coins")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        // Cancel button for pending bets
                        if bet.status == .pending {
                            Button("Cancel") {
                                onCancelTapped()
                            }
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(statusBorderColor, lineWidth: 1)
                )
        )
    }
    
    private var statusBadge: some View {
        Text(bet.status.rawValue)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(statusTextColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(statusColor.opacity(0.2))
                    .overlay(
                        Capsule()
                            .stroke(statusColor, lineWidth: 1)
                    )
            )
    }
    
    private var timeStamp: some View {
        Text(bet.createdAt.formatted(.dateTime.month().day().hour().minute()))
            .font(.system(size: 11))
            .foregroundColor(.white.opacity(0.6))
    }
    
    private var statusColor: Color {
        switch bet.status {
        case .won:
            return .green
        case .lost:
            return .red
        case .pending, .active, .partiallyMatched, .fullyMatched:
            return tealColor
        case .cancelled:
            return .gray
        }
    }
    
    private var statusTextColor: Color {
        switch bet.status {
        case .won, .lost:
            return .white
        default:
            return statusColor
        }
    }
    
    private var statusBorderColor: Color {
        statusColor.opacity(0.3)
    }
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
