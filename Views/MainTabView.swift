//
//  MainTabView.swift
//  BettorOdds
//
//  Version: 2.5.0 - Fixed view names and references
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @StateObject private var adminNav = AdminNavigation.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Games Tab - Using EnhancedGamesView
            EnhancedGamesView()
                .tabItem {
                    Label("Games", systemImage: "sportscourt.fill")
                }
                .tag(0)
            
            // My Bets Tab - Using MyBetsView (not EnhancedMyBetsView)
            MyBetsView()
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
        .accentColor(AppTheme.Colors.primary)
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
        .onChange(of: selectedTab) { _ in
            HapticManager.impact(.light)
        }
    }
}

// MARK: - Admin Auth View

struct AdminAuthView: View {
    @StateObject private var adminNav = AdminNavigation.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppTheme.Spacing.lg) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 50))
                    .foregroundColor(AppTheme.Colors.primary)
                
                Text("Admin Authentication Required")
                    .font(AppTheme.Typography.title2)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("Please authenticate to access admin features")
                    .font(AppTheme.Typography.callout)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                
                Button("Authenticate") {
                    Task {
                        await adminNav.authenticateAdmin()
                    }
                }
                .primaryButtonStyle()
            }
            .padding(AppTheme.Spacing.lg)
            .navigationTitle("Admin Access")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationViewModel())
}
