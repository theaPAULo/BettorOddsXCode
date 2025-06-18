//
//  ContentView.swift
//  BettorOdds
//
//  Version: 3.2.0 - ENHANCED: Orphaned authentication recovery UI
//  Updated: June 2025
//  Changes:
//  - Added orphaned auth state handling
//  - Manual user profile creation option
//  - Enhanced error recovery with specific messaging
//  - Clean sign out option for orphaned auth
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
                    
                case .retrying:
                    // Show retry loading screen with progress
                    RetryLoadingScreen(retryCount: authViewModel.retryCount)
                    
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
                    
                case .orphanedAuth:
                    // Show orphaned auth recovery screen
                    OrphanedAuthRecoveryView()
                        .transition(.opacity)
                    
                case .error(let errorMessage):
                    // Show enhanced error state with recovery options
                    EnhancedAuthErrorView(
                        errorMessage: errorMessage,
                        onRetry: {
                            Task {
                                await authViewModel.checkAuthState()
                            }
                        },
                        onForceSignOut: {
                            Task {
                                await authViewModel.forceCleanSignOut()
                            }
                        }
                    )
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

// MARK: - Orphaned Auth Recovery View

struct OrphanedAuthRecoveryView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var isCreatingProfile = false
    
    var body: some View {
        ZStack {
            // Background with problem indication
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.1, green: 0.05, blue: 0.0),
                    Color(red: 0.15, green: 0.08, blue: 0.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Icon indicating missing profile
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.orange,
                                    Color.orange.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 16) {
                    Text("Profile Setup Needed")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Your account is signed in, but your profile is missing.")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Text("This can happen due to network issues during initial setup.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    // Show user info if available
                    if let firebaseUser = authViewModel.orphanedFirebaseUser {
                        VStack(spacing: 8) {
                            if let email = firebaseUser.email {
                                Text("Account: \(email)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Text("User ID: \(String(firebaseUser.uid.prefix(8)))...")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                VStack(spacing: 16) {
                    // Create profile button
                    Button(action: {
                        isCreatingProfile = true
                        Task {
                            await authViewModel.createOrphanedUserProfile()
                            isCreatingProfile = false
                        }
                    }) {
                        HStack(spacing: 12) {
                            if isCreatingProfile {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "plus.circle.fill")
                            }
                            Text(isCreatingProfile ? "Creating Profile..." : "Create My Profile")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.0, green: 0.9, blue: 0.79),
                                    Color(red: 0.0, green: 0.8, blue: 0.7)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: Color(red: 0.0, green: 0.9, blue: 0.79).opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isCreatingProfile)
                    
                    // Alternative: Clean sign out
                    Button(action: {
                        Task {
                            await authViewModel.forceCleanSignOut()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.right.square")
                            Text("Sign Out & Try Again")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 32)
                
                // Additional help text
                VStack(spacing: 8) {
                    Text("Need help?")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("If you continue to have issues, try signing out and signing back in with a different method.")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 48)
                }
            }
        }
    }
}

// MARK: - Unified Loading Screen (Updated)

struct UnifiedLoadingScreen: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var textOpacity: Double = 0.0
    @State private var dotAnimation = false
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            // Elegant background gradient with teal accent
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.0, green: 0.08, blue: 0.1),
                    Color(red: 0.0, green: 0.12, blue: 0.15)
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
                // Background glow effect with teal
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.0, green: 0.9, blue: 0.79).opacity(0.3),
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
                
                // Main logo circle with teal gradient
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.0, green: 0.9, blue: 0.79),
                                Color(red: 0.0, green: 0.8, blue: 0.7),
                                Color(red: 0.0, green: 0.7, blue: 0.6)
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
                    .shadow(color: Color(red: 0.0, green: 0.9, blue: 0.79).opacity(0.5), radius: 20, x: 0, y: 8)
                
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
            Text("Checking your account...")
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

// MARK: - Retry Loading Screen (Updated)

struct RetryLoadingScreen: View {
    let retryCount: Int
    @State private var progressAnimation = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.0, green: 0.08, blue: 0.1),
                    Color(red: 0.0, green: 0.12, blue: 0.15)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Logo with retry indication
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.0, green: 0.9, blue: 0.79),
                                    Color(red: 0.0, green: 0.8, blue: 0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(progressAnimation ? 360 : 0))
                        .animation(.linear(duration: 2.0).repeatForever(autoreverses: false), value: progressAnimation)
                }
                
                VStack(spacing: 16) {
                    Text("Reconnecting...")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Attempt \(retryCount)")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("Checking your connection and loading your profile")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
        }
        .onAppear {
            progressAnimation = true
        }
    }
}

// MARK: - Enhanced Auth Error View (Updated)

struct EnhancedAuthErrorView: View {
    let errorMessage: String
    let onRetry: () -> Void
    let onForceSignOut: () -> Void
    
    @State private var showingDetails = false
    @State private var showingSignOutConfirmation = false
    
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
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                    .shadow(color: .orange.opacity(0.5), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 16) {
                    Text("Connection Problem")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("We're having trouble loading your profile")
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
                
                VStack(spacing: 16) {
                    // Retry button
                    Button(action: onRetry) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.clockwise")
                            Text("Try Again")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
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
                    
                    // Force sign out button
                    Button(action: { showingSignOutConfirmation = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.right.square")
                            Text("Sign Out & Try Different Account")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 32)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showingDetails)
        .alert("Sign Out?", isPresented: $showingSignOutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                onForceSignOut()
            }
        } message: {
            Text("This will sign you out and return you to the login screen. You can then try signing in again.")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationViewModel())
}
