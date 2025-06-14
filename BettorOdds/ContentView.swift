//
//  ContentView.swift
//  BettorOdds
//
//  Version: 2.0.0 - Updated for Google/Apple Sign-In authentication
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        Group {
            switch authViewModel.authState {
            case .loading:
                // Show loading screen while checking auth state
                LoadingView()
                    .onAppear {
                        // Force auth check after brief delay to ensure proper initialization
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            authViewModel.checkAuthState()
                        }
                    }
            
            case .signedIn:
                // Show main app interface when user is authenticated
                MainTabView()
                    .environmentObject(authViewModel)
            
            case .signedOut:
                // Show login screen when user is not authenticated
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                // Recheck auth state when app becomes active
                authViewModel.checkAuthState()
            }
        }
    }
}

// Keep existing LoadingView struct unchanged
struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Same animated background as login
            LinearGradient(
                gradient: Gradient(colors: [
                    Color("Primary").opacity(0.2),
                    Color.white.opacity(0.1),
                    Color("Primary").opacity(0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // App logo while loading
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color("Primary"),
                                    Color("Primary").opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                    
                    VStack(spacing: 2) {
                        Text("🎲")
                            .font(.system(size: 28))
                        Text("BO")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color("Primary")))
                    .scaleEffect(1.2)
                
                Text("Loading...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever()) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    ContentView()
}
