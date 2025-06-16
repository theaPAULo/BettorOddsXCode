//
//  MainTabView.swift
//  BettorOdds
//
//  Version: 2.6.0 - Fixed MyBetsView reference and other issues
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
            
            // My Bets Tab - Create a simple wrapper to avoid import issues
            MyBetsTabView()
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
                            await adminNav.checkAdminAccess()
                        }
                    }
                    .tabItem {
                        Label("Admin", systemImage: "shield.fill")
                    }
                    .tag(3)
            }
        }
        .accentColor(.primary)  // FIXED: Use .primary instead of Color.primary
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
        .onChange(of: selectedTab) { _, _ in  // FIXED: Added parameter names for iOS 17 compatibility
            HapticManager.impact(.light)
        }
    }
}

// MARK: - My Bets Tab Wrapper (FIXED: Create wrapper to avoid import issues)

// MARK: - Enhanced My Bets Tab Wrapper
// Replace the existing MyBetsTabView in MainTabView.swift with this enhanced version

struct MyBetsTabView: View {
    @StateObject private var viewModel = MyBetsViewModel()
    @State private var selectedFilter: BetFilter = .active
    @State private var showCancelConfirmation = false
    @State private var betToCancel: Bet?
    @State private var scrollOffset: CGFloat = 0
    @State private var isRefreshing = false
    
    // Teal color for consistency
    private let tealColor = Color(red: 0.0, green: 0.9, blue: 0.79)
    
    var body: some View {
        NavigationView {
            ZStack {
                // MATCHING BACKGROUND - Same as Games and Profile views
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
                    // Enhanced header with teal accents
                    enhancedHeaderSection
                    
                    // IMPROVED: Filter tabs with better spacing
                    improvedFilterTabsSection
                    
                    // Enhanced bets list
                    enhancedBetsListSection
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    await viewModel.loadBets()
                }
            }
            // FIXED: Single cancel confirmation (removed duplicate)
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
            .refreshable {
                await performRefresh()
            }
        }
    }
    
    // MARK: - Enhanced Header Section
    
    private var enhancedHeaderSection: some View {
        VStack(spacing: 20) {
            // Title with teal accent
            HStack(spacing: 8) {
                Text("My Bets")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                Circle()
                    .fill(tealColor)
                    .frame(width: 12, height: 12)
                    .shadow(color: tealColor.opacity(0.6), radius: 4, x: 0, y: 0)
            }
            
            // Stats summary
            VStack(spacing: 12) {
                Text("\(viewModel.totalBets) total • \(viewModel.winRate)% win rate")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                // Enhanced stats cards
                HStack(spacing: 16) {
                    enhancedStatCard(
                        title: "Won",
                        count: viewModel.wonBets,
                        color: .green,
                        icon: "checkmark.circle.fill"
                    )
                    enhancedStatCard(
                        title: "Lost",
                        count: viewModel.lostBets,
                        color: .red,
                        icon: "xmark.circle.fill"
                    )
                    enhancedStatCard(
                        title: "Pending",
                        count: viewModel.pendingBets,
                        color: tealColor,
                        icon: "clock.fill"
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .modifier(ScrollOffsetModifier(coordinateSpace: "scroll", offset: $scrollOffset))
    }
    
    private func enhancedStatCard(title: String, count: Int, color: Color, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - IMPROVED Filter Tabs Section (Better Spacing)
    
    private var improvedFilterTabsSection: some View {
        HStack(spacing: 8) { // Reduced spacing for better fit
            filterTab(.active, title: "Active")
            filterTab(.completed, title: "Completed")
            filterTab(.all, title: "All")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private func filterTab(_ filter: BetFilter, title: String) -> some View {
        Button(action: {
            selectedFilter = filter
            HapticManager.selection()
        }) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(selectedFilter == filter ? .black : .white.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedFilter == filter ?
                              tealColor :
                              Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    selectedFilter == filter ?
                                        tealColor :
                                        Color.white.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(selectedFilter == filter ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedFilter == filter)
    }
    
    // MARK: - Enhanced Bets List Section
    
    private var enhancedBetsListSection: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.isLoading {
                    loadingView
                } else if filteredBets.isEmpty {
                    emptyStateView
                } else {
                    ForEach(Array(filteredBets.enumerated()), id: \.element.id) { index, bet in
                        EnhancedBetCard(
                            bet: bet,
                            onCancelTapped: {
                                // FIXED: Single confirmation trigger
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
    
    // MARK: - Supporting Views
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: tealColor))
            
            Text("Loading your bets...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 48))
                .foregroundColor(tealColor.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Bets Found")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text(emptyStateMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 40)
    }
    
    private var emptyStateMessage: String {
        switch selectedFilter {
        case .active:
            return "You don't have any active bets. Go to Games to place your first bet!"
        case .completed:
            return "You haven't completed any bets yet. Your betting history will appear here."
        case .all:
            return "You haven't placed any bets yet. Head to the Games tab to get started!"
        }
    }
    
    // MARK: - Helper Functions
    
    private func performRefresh() async {
        withAnimation(.easeInOut(duration: 0.3)) {
            isRefreshing = true
        }
        
        await viewModel.loadBets()
        HapticManager.impact(.light)
        
        // Small delay for better UX
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isRefreshing = false
        }
    }
}

// MARK: - Enhanced Bet Card

struct EnhancedBetCard: View {
    let bet: Bet
    let onCancelTapped: () -> Void
    
    private let tealColor = Color(red: 0.0, green: 0.9, blue: 0.79)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with status
            HStack {
                statusBadge
                Spacer()
                Text(bet.createdAt.formatted(.dateTime.month().day().hour().minute()))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Game info - FIXED: Using correct 'team' property
            VStack(alignment: .leading, spacing: 8) {
                Text(bet.team)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                if bet.initialSpread != 0 {
                    Text("Spread: \(bet.initialSpread > 0 ? "+" : "")\(bet.initialSpread, specifier: "%.1f")")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // Bet details
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bet Amount")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                    
                    HStack(spacing: 4) {
                        Text(bet.coinType == .yellow ? "🟡" : "💚")
                            .font(.system(size: 16))
                        
                        Text("\(bet.amount)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Potential Win")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("\(bet.potentialWinnings)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(tealColor)
                }
            }
            
            // Cancel button (only for pending bets)
            if bet.canBeCancelled {
                Button(action: onCancelTapped) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                        Text("Cancel Bet")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(statusColor.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var statusBadge: some View {
        Text(bet.status.rawValue.capitalized)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(statusColor.opacity(0.3))
                    .overlay(
                        Capsule()
                            .stroke(statusColor, lineWidth: 1)
                    )
            )
    }
    
    private var statusColor: Color {
        switch bet.status {
        case .won:
            return .green
        case .lost:
            return .red
        case .pending, .active:
            return tealColor
        case .cancelled:
            return .gray
        case .partiallyMatched, .fullyMatched:  // FIXED: Added missing cases
            return .blue
        }
    }
}

// MARK: - Supporting Views and Modifiers (Reused)

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

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
// MARK: - Bet Filter Enum

enum BetFilter {
    case active, completed, all
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

#Preview {
    MainTabView()
        .environmentObject(AuthenticationViewModel())
}
