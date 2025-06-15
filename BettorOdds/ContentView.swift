//
//  ContentView.swift
//  BettorOdds
//
//  Version: 2.7.2 - Fixed hex color conflicts by removing conflicting extension
//  Updated: June 2025
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var isCheckingAuth = true
    
    var body: some View {
        Group {
            if isCheckingAuth {
                // Show loading screen while checking authentication
                LoadingView()
            } else if authViewModel.user != nil {
                // User is authenticated - show main app
                MainTabView()
            } else {
                // User is not authenticated - show login
                LoginView()
            }
        }
        .onAppear {
            checkAuthenticationState()
        }
        // FIXED: Removed onChange that required User to be Equatable
        // Instead, we'll observe authState which is simpler
        .onChange(of: authViewModel.authState) { _, authState in
            if authState == .signedIn || authState == .signedOut {
                isCheckingAuth = false
            }
        }
    }
    
    private func checkAuthenticationState() {
        Task {
            // FIXED: Call the correct method name
            authViewModel.checkAuthState()
            await MainActor.run {
                isCheckingAuth = false
            }
        }
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            // FIXED: Use proper background color
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // App logo with gold gradient - FIXED: Use direct color values
                Text("BettorOdds")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.84, blue: 0.0),    // Gold #FFD700
                                Color(red: 1.0, green: 0.65, blue: 0.0),    // Orange-gold #FFA500
                                Color(red: 1.0, green: 0.55, blue: 0.0)     // Darker orange #FF8C00
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.primary)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationViewModel())
}
