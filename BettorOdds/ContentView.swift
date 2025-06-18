//
//  ContentView.swift
//  BettorOdds
//
//  Version: 3.0.0 - REDESIGNED: Unified authentication and loading system
//  Updated: June 2025
//  Changes:
//  - Single source of truth for auth states
//  - Eliminated competing loading states
//  - Smooth transitions with no overlapping text
//  - Professional loading animations
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        ZStack {
            // Main content based on auth state
            Group {
                switch authViewModel.authState {
                case .loading:
                    // Show unified loading screen
                    UnifiedLoadingScreen()
                    
                case .signedIn:
                    // User is authenticated - show main app
                    MainTabView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.9)),
                            removal: .opacity
                        ))
                    
                case .signedOut:
                    // User is not authenticated - show login
                    EnhancedLoginView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                    
                case .error(let errorMessage):
                    // Show error state with retry option
                    AuthErrorView(errorMessage: errorMessage) {
                        Task {
                            await authViewModel.checkAuthState()
                        }
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.6), value: authViewModel.authState)
        }
        .onAppear {
            // Only check auth state if we're in initial loading
            if case .loading = authViewModel.authState {
                Task {
                    // Small delay to prevent flickering
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                    await authViewModel.checkAuthState()
                }
            }
        }
    }
}

// MARK: - Unified Loading Screen

struct UnifiedLoadingScreen: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var textOpacity: Double = 0.0
    @State private var dotAnimation = false
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            // Elegant background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.05, green: 0.1, blue: 0.15),
                    Color(red: 0.1, green: 0.15, blue: 0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Modern logo design
                modernLogoSection
                
                // Elegant loading indicator
                elegantLoadingIndicator
            }
        }
        .onAppear {
            startLoadingAnimations()
        }
    }
    
    private var modernLogoSection: some View {
        VStack(spacing: 20) {
            // Sleek logo container
            ZStack {
                // Background glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .opacity(pulseAnimation ? 0.6 : 0.9)
                    .animation(
                        .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
                
                // Main logo circle
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 1.0, green: 0.84, blue: 0.0),
                                Color(red: 1.0, green: 0.65, blue: 0.0),
                                Color(red: 0.8, green: 0.5, blue: 0.0)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.5), radius: 20, x: 0, y: 8)
                
                // Icon
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
            }
            .scaleEffect(logoScale)
            .animation(.spring(response: 0.8, dampingFraction: 0.6), value: logoScale)
            
            // App name with sophisticated typography
            Text("BettorOdds")
                .font(.system(size: 28, weight: .light, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white,
                            Color.white.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(textOpacity)
                .animation(.easeInOut(duration: 1.0).delay(0.5), value: textOpacity)
        }
    }
    
    private var elegantLoadingIndicator: some View {
        VStack(spacing: 16) {
            // Custom animated dots
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 8, height: 8)
                        .scaleEffect(dotAnimation ? 1.3 : 0.7)
                        .opacity(dotAnimation ? 1.0 : 0.4)
                        .animation(
                            .easeInOut(duration: 0.8)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: dotAnimation
                        )
                }
            }
            
            // Loading text
            Text("Initializing...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .opacity(textOpacity)
        }
    }
    
    private func startLoadingAnimations() {
        // Logo scale animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1)) {
            logoScale = 1.0
        }
        
        // Text fade in
        withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
            textOpacity = 1.0
        }
        
        // Dot animation
        withAnimation(.easeInOut(duration: 0.8).delay(0.7)) {
            dotAnimation = true
        }
        
        // Pulse animation
        withAnimation(.easeInOut(duration: 2.0).delay(1.0)) {
            pulseAnimation = true
        }
    }
}

// MARK: - Auth Error View

struct AuthErrorView: View {
    let errorMessage: String
    let onRetry: () -> Void
    
    @State private var showingDetails = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.1, green: 0.05, blue: 0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Error icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                    .shadow(color: .orange.opacity(0.5), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 16) {
                    Text("Connection Issue")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("We're having trouble connecting to our servers")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    // Show error details toggle
                    Button(action: { showingDetails.toggle() }) {
                        HStack(spacing: 8) {
                            Text(showingDetails ? "Hide Details" : "Show Details")
                            Image(systemName: showingDetails ? "chevron.up" : "chevron.down")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.orange)
                    }
                    
                    if showingDetails {
                        Text(errorMessage)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                
                // Retry button
                Button(action: onRetry) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: 200)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.orange,
                                Color.orange.opacity(0.8)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(1.0)
                .onTapGesture {
                    // Add haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    onRetry()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showingDetails)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationViewModel())
}
