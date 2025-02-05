//
//  ContentView.swift
//  BettorOdds
//
//  Version: 1.2.0 - Added phone verification support
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
                
            case .phoneVerification:
                // Show phone verification screen
                PhoneVerificationView()
                    .environmentObject(authViewModel)
                
            case .pendingPhoneVerification:
                // Keep showing phone verification screen but in code entry state
                PhoneVerificationView()
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
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            
            Text("Loading...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    ContentView()
}
