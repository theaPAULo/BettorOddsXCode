//
//  LoadingScreen.swift
//  BettorOdds
//
//  Version: 1.0.0 - Clean and simple loading screen with app branding
//  Updated: June 2025

import SwiftUI

struct LoadingScreen: View {
    @State private var isAnimating = false
    @State private var textOpacity = 0.0
    @State private var logoScale = 0.8
    
    var body: some View {
        ZStack {
            // Background gradient
            AppTheme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // App Icon or Logo Area
                logoSection
                
                // App Name
                appNameSection
                
                // Loading Indicator
                loadingIndicator
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Logo Section
    
    private var logoSection: some View {
        Group {
            // You can replace this with your actual app icon
            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.Colors.primary, AppTheme.Colors.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(logoScale)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: logoScale)
        }
    }
    
    // MARK: - App Name Section
    
    private var appNameSection: some View {
        VStack(spacing: 8) {
            // Main app name with gradient
            Text("BettorOdds")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            AppTheme.Colors.primary,
                            AppTheme.Colors.secondary,
                            AppTheme.Colors.accent
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .opacity(textOpacity)
                .animation(.easeInOut(duration: 0.8), value: textOpacity)
            
            // Tagline
            Text("Smart Sports Betting")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .opacity(textOpacity)
                .animation(.easeInOut(duration: 0.8).delay(0.2), value: textOpacity)
        }
    }
    
    // MARK: - Loading Indicator
    
    private var loadingIndicator: some View {
        VStack(spacing: 16) {
            // Custom animated dots
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(AppTheme.Colors.primary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(isAnimating ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: isAnimating
                        )
                }
            }
            
            Text("Loading...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .opacity(textOpacity)
                .animation(.easeInOut(duration: 0.8).delay(0.4), value: textOpacity)
        }
    }
    
    // MARK: - Animation Controls
    
    private func startAnimations() {
        // Logo animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
            logoScale = 1.0
        }
        
        // Text fade in
        withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
            textOpacity = 1.0
        }
        
        // Loading dots animation
        withAnimation(.easeInOut(duration: 0.6).delay(0.5)) {
            isAnimating = true
        }
    }
}

// MARK: - Alternative Loading Screen with App Icon

struct AppIconLoadingScreen: View {
    @State private var isRotating = false
    @State private var textOpacity = 0.0
    @State private var scale = 0.3
    
    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // App Icon (if you have one in Assets)
                Image("AppIcon") // Replace with your actual app icon asset name
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [AppTheme.Colors.primary, AppTheme.Colors.secondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(isRotating ? 360 : 0))
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false), value: isRotating)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: scale)
                
                Text("BettorOdds")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(textOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                scale = 1.0
            }
            
            withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
                textOpacity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isRotating = true
            }
        }
    }
}

// MARK: - Minimal Loading Screen

struct MinimalLoadingScreen: View {
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("BettorOdds")
                    .font(.system(size: 40, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.Colors.primary, AppTheme.Colors.secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                // Progress bar
                RoundedRectangle(cornerRadius: 2)
                    .frame(width: 200, height: 4)
                    .foregroundColor(.white.opacity(0.2))
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .frame(width: 200 * animationProgress, height: 4)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppTheme.Colors.primary, AppTheme.Colors.secondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0)) {
                animationProgress = 1.0
            }
        }
    }
}

// MARK: - Preview

#Preview("Main Loading") {
    LoadingScreen()
}

#Preview("App Icon Loading") {
    AppIconLoadingScreen()
}

#Preview("Minimal Loading") {
    MinimalLoadingScreen()
}
