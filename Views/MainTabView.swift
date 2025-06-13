//
//  MainTabView.swift
//  BettorOdds
//
//  Version: 2.3.0 - Fixed theme compatibility and added missing view imports
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @StateObject private var adminNav = AdminNavigation.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Games Tab - NO NavigationView wrapper
            GamesView()
                .tabItem {
                    Label("Games", systemImage: "sportscourt.fill")
                }
                .tag(0)
            
            // My Bets Tab - NO NavigationView wrapper
            MyBetsView()
                .tabItem {
                    Label("My Bets", systemImage: "list.bullet.clipboard")
                }
                .tag(1)
            
            // Profile Tab - NO NavigationView wrapper
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(2)
            
            // Admin Tab - NO NavigationView wrapper
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

// Keep AdminAuthView with NavigationView since it's in a sheet
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

// Note: GamesView, MyBetsView, ProfileView, and AdminDashboardView
// are defined in their respective files in the Views folder
