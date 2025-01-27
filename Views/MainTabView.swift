//
//  MainTabView.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/26/25.
//


// File: Views/MainTabView.swift
// Version: 1.0
// Description: Main tab navigation for the authenticated app experience

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
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
        }
        .accentColor(AppTheme.primary) // Tab bar tint color
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

#Preview {
    MainTabView()
        .environmentObject(AuthenticationViewModel())
}