//
//  BettorOddsApp.swift
//  BettorOdds
//
//  Version: 3.1.0 - FIXED: Updated LoadingView reference to UnifiedLoadingScreen
//  Updated: June 2025
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import UserNotifications

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Initialize Firebase configuration
        _ = FirebaseConfig.shared
        print("🔥 Firebase initialized")
        
        return true
    }
    
    // Handle URL schemes for Google Sign-In
    func application(_ application: UIApplication,
                    open url: URL,
                    options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if Auth.auth().canHandle(url) {
            return true
        }
        return false
    }
}

// MARK: - Main App
@main
struct BettorOddsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var showLaunch = true
    @State private var isDependencyContainerReady = false
    
    // CRITICAL FIX: Create AuthViewModel as StateObject once DI is ready
    @StateObject private var authViewModel: AuthenticationViewModel = {
        // This will be properly initialized after DI container is ready
        print("🔐 Creating AuthenticationViewModel StateObject")
        return AuthenticationViewModel()
    }()
    
    @StateObject private var darkModeManager = DarkModeManager()
    
    // CRITICAL FIX: Initialize DI Container FIRST, before any ViewModels
    private let dependencyContainer = DependencyContainer.shared
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isDependencyContainerReady {
                    // FIXED: Use the StateObject AuthViewModel directly
                    ContentView()
                        .environmentObject(authViewModel)
                        .environmentObject(darkModeManager)
                } else {
                    // FIXED: Use UnifiedLoadingScreen instead of old LoadingView
                    UnifiedLoadingScreen()
                }
                
                if showLaunch {
                    LaunchScreen() // Use existing LaunchScreen
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                setupApp()
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Sets up the app on first launch
    private func setupApp() {
        print("🚀 BettorOdds starting up...")
        
        // CRITICAL: Wait for DI container to be ready before showing main UI
        Task {
            // Small delay to ensure DI container is fully initialized
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            await MainActor.run {
                isDependencyContainerReady = true
                print("🔧 Dependency injection ready")
            }
            
            // Setup launch screen timer
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.5)) {
                    showLaunch = false
                }
                print("🎬 Launch screen dismissed")
            }
        }
        
        // Setup app-wide configurations
        setupAppearance()
        
        #if DEBUG
        print("🐛 Running in DEBUG mode")
        #endif
    }
    
    /// Configures app-wide appearance
    private func setupAppearance() {
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Configure navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor.clear
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        
        print("🎨 App appearance configured")
    }
}
