// File: BettorOddsApp.swift
// Version: 1.0
// Description: Main app entry point and Firebase configuration

import SwiftUI
import FirebaseCore

@main
struct BettorOddsApp: App {
    // Initialize Firebase when app launches
    init() {
        // Initialize Firebase configuration
        FirebaseConfig.shared
        
        #if DEBUG
        // Print the path to help locate GoogleService-Info.plist
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
            print("📝 Found GoogleService-Info.plist at: \(path)")
        } else {
            print("❌ GoogleService-Info.plist not found in bundle!")
        }
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
