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
        .accentColor(.primary)  // FIXED: Use .primary instead of AppTheme.Colors.primary
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

struct MyBetsTabView: View {
    @StateObject private var viewModel = MyBetsViewModel()
    @State private var selectedFilter: BetFilter = .active
    @State private var showCancelConfirmation = false
    @State private var betToCancel: Bet?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.13, blue: 0.15),
                        Color(red: 0.13, green: 0.23, blue: 0.26),
                        Color(red: 0.17, green: 0.33, blue: 0.39)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with stats
                    headerSection
                    
                    // Filter tabs
                    filterTabsSection
                    
                    // Bets list
                    betsListSection
                }
            }
            .navigationTitle("My Bets")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task {
                    await viewModel.loadBets()
                }
            }
            .alert("Cancel Bet", isPresented: $showCancelConfirmation) {
                Button("Keep Bet", role: .cancel) { }
                Button("Cancel Bet", role: .destructive) {
                    if let bet = betToCancel {
                        Task {
                            await viewModel.cancelBet(bet)
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to cancel this bet? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Text("\(viewModel.totalBets) total • \(viewModel.winRate)% win rate")
                .font(.callout)
                .foregroundColor(.white.opacity(0.8))
            
            HStack(spacing: 16) {
                statCard(title: "Won", count: viewModel.wonBets, color: .green, icon: "checkmark.circle.fill")
                statCard(title: "Lost", count: viewModel.lostBets, color: .red, icon: "xmark.circle.fill")
                statCard(title: "Pending", count: viewModel.pendingBets, color: .primary, icon: "clock.fill")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
    }
    
    private func statCard(title: String, count: Int, color: Color, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.title2)
                .foregroundColor(.white)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
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
    
    private var filterTabsSection: some View {
        HStack(spacing: 0) {
            filterTab(.active, title: "Active")
            filterTab(.completed, title: "Completed")
            filterTab(.all, title: "All")
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    private func filterTab(_ filter: BetFilter, title: String) -> some View {
        Button(action: {
            selectedFilter = filter
            HapticManager.selection()
        }) {
            Text(title)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(selectedFilter == filter ? .white : .white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedFilter == filter ? Color.primary.opacity(0.8) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var betsListSection: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredBets) { bet in
                    BetCard(
                        bet: bet,
                        onCancelTapped: {
                            betToCancel = bet
                            showCancelConfirmation = true
                        }
                    )
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var filteredBets: [Bet] {
        switch selectedFilter {
        case .active:
            return viewModel.bets.filter { $0.status == .pending || $0.status == .active }
        case .completed:
            return viewModel.bets.filter { $0.status == .won || $0.status == .lost }
        case .all:
            return viewModel.bets
        }
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
