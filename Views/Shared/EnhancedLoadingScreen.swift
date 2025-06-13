//
//  EnhancedLoadingScreen.swift
//  BettorOdds
//
//  Created by Paul Soni on 6/13/25.
//


//
//  EnhancedLoadingScreen.swift
//  BettorOdds
//
//  Created by Claude on 6/13/25
//  Version: 1.0.0 - Beautiful loading screen with AppIcon and teal theme
//

import SwiftUI

struct EnhancedLoadingScreen: View {
    @State private var isAnimating = false
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var textOpacity: Double = 0.7
    
    var body: some View {
        ZStack {
            // Animated background gradient
            AnimatedGradientBackground()
                .ignoresSafeArea()
            
            VStack(spacing: AppTheme.Spacing.xl) {
                Spacer()
                
                // App Icon with animations
                appIconSection
                
                // App Title
                Text("BettorOdds")
                    .font(AppTheme.Typography.appTitle)
                    .foregroundColor(AppTheme.Colors.primary)
                    .fontWeight(.bold)
                    .opacity(textOpacity)
                    .animation(
                        Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: textOpacity
                    )
                
                Spacer()
                
                // Loading indicator
                loadingIndicator
                
                Spacer()
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - App Icon Section
    
    private var appIconSection: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .stroke(
                    AppTheme.Colors.primary.opacity(0.3),
                    lineWidth: 3
                )
                .frame(width: 140, height: 140)
                .scaleEffect(pulseScale)
                .animation(
                    Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: pulseScale
                )
            
            // Middle glow ring
            Circle()
                .stroke(
                    AppTheme.Colors.primary.opacity(0.5),
                    lineWidth: 2
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(rotationAngle))
                .animation(
                    Animation.linear(duration: 3.0).repeatForever(autoreverses: false),
                    value: rotationAngle
                )
            
            // App Icon Container
            ZStack {
                // Background circle with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.Colors.primary,
                                AppTheme.Colors.primaryDark
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(
                        color: AppTheme.Colors.primary.opacity(0.5),
                        radius: 20,
                        x: 0,
                        y: 10
                    )
                
                // App Icon Image (using your AppIcon)
                Image("AppIcon") // This will use your existing AppIcon from Assets
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 90, height: 90)
                    .cornerRadius(20)
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .animation(
                        Animation.spring(response: 0.8, dampingFraction: 0.6).delay(0.2),
                        value: isAnimating
                    )
            }
        }
    }
    
    // MARK: - Loading Indicator
    
    private var loadingIndicator: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Custom loading dots
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(AppTheme.Colors.primary)
                        .frame(width: 12, height: 12)
                        .scaleEffect(isAnimating ? 1.0 : 0.5)
                        .animation(
                            Animation.easeInOut(duration: 0.8)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: isAnimating
                        )
                }
            }
            
            // Loading text
            Text("Loading your games...")
                .font(AppTheme.Typography.callout)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .opacity(textOpacity)
        }
    }
    
    // MARK: - Methods
    
    private func startAnimations() {
        // Start all animations
        withAnimation(.easeInOut(duration: 0.8)) {
            isAnimating = true
        }
        
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.1
        }
        
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            textOpacity = 1.0
        }
    }
}

// MARK: - Animated Background

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [
                AppTheme.Colors.background,
                AppTheme.Colors.backgroundSecondary,
                AppTheme.Colors.background
            ],
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .animation(
            Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true),
            value: animateGradient
        )
        .onAppear {
            animateGradient = true
        }
    }
}

// MARK: - Usage in ContentView

struct EnhancedContentView: View {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        Group {
            switch authViewModel.authState {
            case .loading:
                // Show enhanced loading screen
                EnhancedLoadingScreen()
                    .onAppear {
                        // Force auth check after brief delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            authViewModel.checkAuthState()
                        }
                    }
            
            case .signedIn:
                // Show main app interface
                MainTabView()
                    .environmentObject(authViewModel)
            
            case .signedOut:
                // Show login screen
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                authViewModel.checkAuthState()
            }
        }
    }
}

// MARK: - Enhanced Tab View

struct EnhancedMainTabView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        TabView {
            // Games Tab
            EnhancedGamesView()
                .tabItem {
                    Image(systemName: "gamecontroller.fill")
                    Text("Games")
                }
                .tag(0)
            
            // My Bets Tab
            EnhancedMyBetsView()
                .tabItem {
                    Image(systemName: "list.bullet.rectangle.fill")
                    Text("My Bets")
                }
                .tag(1)
            
            // Profile Tab
            EnhancedProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(2)
        }
        .accentColor(AppTheme.Colors.primary)
        .background(AppTheme.Colors.background)
    }
}

// MARK: - Preview

#Preview {
    EnhancedLoadingScreen()
}