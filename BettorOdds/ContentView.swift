//
//  ContentView.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/26/25.
//


// File: ContentView.swift
// Version: 1.0
// Description: Root view of the application that handles authentication state and navigation

import SwiftUI

struct ContentView: View {
    // Inject the authentication view model that will be used throughout the app
    @StateObject private var authViewModel = AuthenticationViewModel()
    
    var body: some View {
        // Use a Group to conditionally render either auth flow or main app
        Group {
            switch authViewModel.authState {
            case .loading:
                // Show loading screen while checking auth state
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle())
            
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
    }
}

// Preview provider for SwiftUI canvas
#Preview {
    ContentView()
}
