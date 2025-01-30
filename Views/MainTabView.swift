//
//  MainTabView.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/26/25.
//  Version: 2.1.0
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @StateObject private var adminNav = AdminNavigation.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Games Tab
            NavigationView {
                GamesView()
            }
            .tabItem {
                Label("Games", systemImage: "sportscourt.fill")
            }
            .tag(0)
            
            // My Bets Tab
            NavigationView {
                MyBetsView()
            }
            .tabItem {
                Label("My Bets", systemImage: "list.bullet.clipboard")
            }
            .tag(1)
            
            // Profile Tab
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
            .tag(2)
            
            // Admin Tab (only shown for admin users)
            if authViewModel.user?.adminRole == .admin {
                NavigationView {
                    AdminDashboardView()
                        .onAppear {
                            Task {
                                await adminNav.checkAdminAccess()
                            }
                        }
                }
                .tabItem {
                    Label("Admin", systemImage: "shield.fill")
                }
                .tag(3)
            }
        }
        .accentColor(AppTheme.Brand.primary) // Tab bar tint color
        .sheet(isPresented: $adminNav.requiresAuth) {
            AdminAuthView()
        }
        .alert("Error", isPresented: $adminNav.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(adminNav.errorMessage ?? "An unknown error occurred")
        }
        .onAppear {
            // Configure tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            UITabBar.appearance().scrollEdgeAppearance = appearance
            
            // Add haptic feedback for tab selection
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
        }
        .onChange(of: selectedTab) { _ in
            // Provide haptic feedback on tab change
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
}

// Admin Authentication View
struct AdminAuthView: View {
    @StateObject private var adminNav = AdminNavigation.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "shield.fill")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.Brand.primary)
            
            Text("Admin Authentication Required")
                .font(.headline)
            
            Text("Please authenticate to access admin features")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button("Authenticate") {
                Task {
                    await adminNav.authenticateAdmin()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationViewModel())
}
