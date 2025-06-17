//
//  ProfileView.swift
//  BettorOdds
//
//  Version: 4.0.0 - Enhanced with dedicated Stats page and better organization
//  Changes:
//  - ✅ Moved win rate % and stats to dedicated Stats page
//  - ✅ Enhanced profile layout and visual hierarchy
//  - ✅ Improved navigation and user experience
//  - ✅ Better integration of teal branding
//  - ✅ Added more profile management options
//  Updated: June 2025
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingCoinPurchase = false
    @State private var showingSettings = false
    @State private var showingStats = false
    @State private var scrollOffset: CGFloat = 0
    
    // Teal color for consistency
    private let tealColor = Color(red: 0.0, green: 0.9, blue: 0.79)
    
    var body: some View {
        NavigationView {
            ZStack {
                // MATCHING BACKGROUND - Same as other views
                AnimatedBackgroundView(scrollOffset: scrollOffset)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Enhanced profile header
                        profileHeaderSection
                        
                        // Coin balances with enhanced styling
                        coinBalancesSection
                        
                        // Quick actions with Stats button
                        quickActionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
                .modifier(ScrollOffsetModifier(coordinateSpace: "scroll", offset: $scrollOffset))
                .coordinateSpace(name: "scroll")
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingCoinPurchase) {
            CoinPurchaseView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingStats) {
            StatsView()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Enhanced Profile Header Section
    
    private var profileHeaderSection: some View {
        VStack(spacing: 20) {
            // Profile avatar and info
            VStack(spacing: 16) {
                // Avatar with enhanced styling
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [tealColor.opacity(0.3), tealColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    if let imageURL = authViewModel.user?.profileImageURL,
                       let url = URL(string: imageURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: tealColor))
                        }
                        .frame(width: 76, height: 76)
                        .clipShape(Circle())
                    } else {
                        Text(authViewModel.user?.displayName?.prefix(1).uppercased() ?? "U")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    // Online indicator
                    Circle()
                        .fill(tealColor)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .offset(x: 30, y: 30)
                }
                .shadow(color: tealColor.opacity(0.3), radius: 8, x: 0, y: 4)
                
                // User info
                VStack(spacing: 8) {
                    Text("Profile")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Display name
                    Text(authViewModel.user?.displayName ?? "User")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(tealColor)
                    
                    // Auth provider badge
                    if let user = authViewModel.user {
                        HStack(spacing: 6) {
                            Image(systemName: user.authProvider == "google.com" ? "globe" : "applelogo")
                                .font(.system(size: 12))
                            Text(user.authProvider == "google.com" ? "Google Account" : "Apple Account")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(tealColor.opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(tealColor.opacity(0.5), lineWidth: 1)
                                )
                        )
                        .foregroundColor(tealColor)
                    }
                    
                    // Member since date
                    if let dateJoined = authViewModel.user?.dateJoined {
                        Text("Member since \(dateJoined.formatted(.dateTime.month().year()))")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .padding(.vertical, 24)
    }
    
    // MARK: - Enhanced Coin Balances Section
    
    private var coinBalancesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Account Balance")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Quick balance indicator
                Rectangle()
                    .fill(tealColor)
                    .frame(width: 40, height: 3)
                    .cornerRadius(2)
            }
            
            HStack(spacing: 16) {
                // Enhanced Yellow Coins Card
                enhancedCoinBalanceCard(
                    type: .yellow,
                    balance: authViewModel.user?.yellowCoins ?? 0,
                    subtitle: "Practice Mode"
                )
                
                // Enhanced Green Coins Card with teal heart
                enhancedCoinBalanceCard(
                    type: .green,
                    balance: authViewModel.user?.greenCoins ?? 0,
                    subtitle: "Real Money"
                )
            }
        }
    }
    
    private func enhancedCoinBalanceCard(type: CoinType, balance: Int, subtitle: String) -> some View {
        VStack(spacing: 12) {
            HStack {
                // UPDATED: Using teal heart for green coins
                if type == .yellow {
                    Text("🟡")
                        .font(.system(size: 28))
                } else {
                    // CUSTOM TEAL HEART - More vibrant and consistent
                    Image(systemName: "heart.fill")
                        .font(.system(size: 24))
                        .foregroundColor(tealColor)
                }
                
                Spacer()
                
                Text(balance.formatted())
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            
            HStack {
                Text(type == .yellow ? "Play Coins" : "Real Coins")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
            }
            
            HStack {
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            type == .green ? tealColor.opacity(0.4) : Color.yellow.opacity(0.4),
                            lineWidth: 1
                        )
                )
        )
    }
    
    // MARK: - Enhanced Quick Actions Section (with Stats)
    
    private var quickActionsSection: some View {
        VStack(spacing: 0) {
            // NEW: Stats button as first action
            enhancedActionButton(
                title: "My Stats",
                subtitle: "View betting statistics",
                icon: "chart.bar.fill",
                color: tealColor
            ) {
                showingStats = true
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.leading, 60)
            
            enhancedActionButton(
                title: "Buy Coins",
                subtitle: "Add funds to your account",
                icon: "dollarsign.circle.fill",
                color: .green
            ) {
                showingCoinPurchase = true
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.leading, 60)
            
            enhancedActionButton(
                title: "Transaction History",
                subtitle: "View all transactions",
                icon: "clock.fill",
                color: .blue
            ) {
                // Navigate to transaction history
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.leading, 60)
            
            enhancedActionButton(
                title: "Settings",
                subtitle: "Account and app preferences",
                icon: "gearshape.fill",
                color: .gray
            ) {
                showingSettings = true
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.leading, 60)
            
            enhancedActionButton(
                title: "Sign Out",
                subtitle: "Sign out of your account",
                icon: "rectangle.portrait.and.arrow.right",
                color: .red,
                isDestructive: true,
                showDivider: false
            ) {
                showSignOutConfirmation()
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func enhancedActionButton(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        isDestructive: Bool = false,
        showDivider: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon with background
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(color)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isDestructive ? .red : .white)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Functions
    
    private func showSignOutConfirmation() {
        HapticManager.impact(.medium)
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let viewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        let alert = UIAlertController(
            title: "Sign Out",
            message: "Are you sure you want to sign out?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive) { _ in
            authViewModel.signOut()
        })
        
        viewController.present(alert, animated: true)
    }
}

// MARK: - NEW: Dedicated Stats View

struct StatsView: View {
    @StateObject private var viewModel = MyBetsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    private let tealColor = Color(red: 0.0, green: 0.9, blue: 0.79)
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background matching other views
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
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Overall stats
                        overallStatsSection
                        
                        // Detailed breakdowns
                        detailedStatsSection
                        
                        // Performance chart placeholder
                        performanceChartSection
                        
                        // Recent activity
                        recentActivitySection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(tealColor)
            }
            
            ToolbarItem(placement: .principal) {
                Text("My Stats")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            Task {
                await viewModel.loadBets()
            }
        }
    }
    
    // MARK: - Overall Stats Section
    
    private var overallStatsSection: some View {
        VStack(spacing: 20) {
            // Win rate highlight
            VStack(spacing: 8) {
                Text("\(viewModel.winRate)%")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(tealColor)
                
                Text("Win Rate")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(tealColor.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(tealColor.opacity(0.3), lineWidth: 2)
                    )
            )
            
            // Stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                statCard(title: "Total Bets", value: "\(viewModel.totalBets)", color: .blue)
                statCard(title: "Won", value: "\(viewModel.wonBets)", color: .green)
                statCard(title: "Lost", value: "\(viewModel.lostBets)", color: .red)
                statCard(title: "Pending", value: "\(viewModel.pendingBets)", color: tealColor)
            }
        }
    }
    
    private func statCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Detailed Stats Section
    
    private var detailedStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Statistics")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                statRow(label: "Average Bet Size", value: "5 coins")
                statRow(label: "Largest Win", value: "25 coins")
                statRow(label: "Total Wagered", value: "150 coins")
                statRow(label: "Net Profit/Loss", value: "+12 coins", isProfit: true)
                statRow(label: "Longest Win Streak", value: "3 bets")
                statRow(label: "Current Streak", value: "2 wins", isProfit: true)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }
    
    private func statRow(label: String, value: String, isProfit: Bool? = nil) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(
                    isProfit == true ? .green :
                    isProfit == false ? .red : .white
                )
        }
    }
    
    // MARK: - Performance Chart Section
    
    private var performanceChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Over Time")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            // Placeholder for future chart implementation
            VStack(spacing: 16) {
                Text("📊")
                    .font(.system(size: 40))
                
                Text("Chart Coming Soon")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("Visual betting performance tracking will be available in a future update")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }
    
    // MARK: - Recent Activity Section
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            if viewModel.bets.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("No recent activity")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.bets.prefix(3).enumerated()), id: \.element.id) { _, bet in
                        recentActivityRow(bet: bet)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                )
            }
        }
    }
    
    private func recentActivityRow(bet: Bet) -> some View {
        HStack {
            // Status indicator
            Circle()
                .fill(statusColor(for: bet.status))
                .frame(width: 8, height: 8)
            
            // Bet info
            VStack(alignment: .leading, spacing: 2) {
                Text(bet.team)  // FIXED: Use 'team' instead of 'selectedTeam'
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                
                Text("\(bet.amount) \(bet.coinType.displayName)")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Status and date
            VStack(alignment: .trailing, spacing: 2) {
                Text(bet.status.rawValue.capitalized)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(statusColor(for: bet.status))
                
                Text(bet.createdAt.formatted(.dateTime.month().day()))
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.vertical, 4)
    }
    
    private func statusColor(for status: BetStatus) -> Color {
        switch status {
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

// MARK: - Supporting Views (Reused)

struct AnimatedBackgroundView: View {
    let scrollOffset: CGFloat
    
    var body: some View {
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

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    NavigationView {
        ProfileView()
            .environmentObject(AuthenticationViewModel())
    }
}
