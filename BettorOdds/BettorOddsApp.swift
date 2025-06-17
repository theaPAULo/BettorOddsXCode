//
//  BettorOddsApp.swift
//  BettorOdds
//
//  Version: 3.0.0 - Enhanced with Dependency Injection and optimized initialization
//  Updated: June 2025
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import UserNotifications

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Initialize Firebase configuration
        _ = FirebaseConfig.shared
        print("🔥 Firebase initialized")
        
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Request notification permissions
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions) { granted, error in
                if let error = error {
                    print("❌ Notification permission error: \(error)")
                } else {
                    print("✅ Notification permission granted: \(granted)")
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
        
        return true
    }
    
    // Handle URL schemes
    func application(_ application: UIApplication,
                    open url: URL,
                    options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if Auth.auth().canHandle(url) {
            return true
        }
        return false
    }
    
    // Handle remote notifications - IMPORTANT for Firebase Phone Auth
    func application(_ application: UIApplication,
                    didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("📱 Received remote notification")
        
        // Forward the notification to Firebase Auth
        if Auth.auth().canHandleNotification(userInfo) {
            print("✅ Firebase can handle notification")
            completionHandler(.noData)
            return
        }
        
        print("❌ Firebase cannot handle notification")
        completionHandler(.newData)
    }
    
    // Handle APNs token
    func application(_ application: UIApplication,
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("📱 Received APNs token")
        Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
    }
    
    // Handle APNs registration errors
    func application(_ application: UIApplication,
                    didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error)")
    }
    
    // UNUserNotificationCenterDelegate methods
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([[.banner, .sound]])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}

// MARK: - Main App
@main
struct BettorOddsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var darkModeManager = DarkModeManager() // Use existing DarkModeManager
    @State private var showLaunch = true
    
    // Initialize DI Container early - CRITICAL for dependency injection
    private let dependencyContainer = DependencyContainer.shared
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(authViewModel)
                    .environmentObject(darkModeManager)
                
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
        
        // Setup launch screen timer
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeOut(duration: 0.5)) {
                showLaunch = false
            }
            print("🎬 Launch screen dismissed")
        }
        
        // Log DI container status
        print("🔧 Dependency injection ready")
        
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
