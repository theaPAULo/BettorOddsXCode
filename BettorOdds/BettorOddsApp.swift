// File: BettorOddsApp.swift
// Version: 1.0
// Description: Main app entry point and Firebase configuration

import SwiftUI
import FirebaseCore

@main
struct BettorOddsApp: App {
    // Initialize Firebase when app launches
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
