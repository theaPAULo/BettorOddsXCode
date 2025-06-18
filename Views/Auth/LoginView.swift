//
//  EnhancedLoginView.swift
//  BettorOdds
//
//  Version: 3.0.0 - REDESIGNED: Clean, modern login with no overlapping text
//  Updated: June 2025
//  Changes:
//  - Removed duplicate "BettorOdds" text (handled by ContentView now)
//  - Streamlined loading states
//  - Modern, clean design
//  - Improved user experience with haptic feedback
//

import SwiftUI
import AuthenticationServices

struct EnhancedLoginView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingError = false
    @State private var cardOffset: CGFloat = 300
    @State private var cardOpacity: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Sophisticated background
                sophisticatedBackground
                
                // Main content
                VStack(spacing: 0) {
                    // Hero section (top 40% of screen)
                    heroSection
                        .frame(height: geometry.size.height * 0.4)
                    
                    // Login card section (bottom 60% of screen)
                    loginCardSection
                        .frame(height: geometry.size.height * 0.6)
                }
                
                // Loading overlay (only for sign-in operations, not app loading)
                if authViewModel.isLoading {
                    signInLoadingOverlay
                }
            }
        }
        .alert("Sign In Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {
                authViewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .onChange(of: authViewModel.errorMessage) { _, errorMessage in
            showingError = errorMessage != nil
        }
        .onAppear {
            startLoginAnimations()
        }
    }
    
    // MARK: - Background
    
    private var sophisticatedBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.black, location: 0.0),
                    .init(color: Color(red: 0.05, green: 0.1, blue: 0.15), location: 0.4),
                    .init(color: Color(red: 0.1, green: 0.15, blue: 0.25), location: 0.7),
                    .init(color: Color(red: 0.08, green: 0.12, blue: 0.2), location: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle pattern overlay
            backgroundPattern
        }
        .ignoresSafeArea()
    }
    
    private var backgroundPattern: some View {
        ZStack {
            // Floating orbs for visual interest
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.0, green: 0.9, blue: 0.79).opacity(0.1),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 50,
                            endRadius: 150
                        )
                    )
                    .frame(width: 200, height: 200)
                    .offset(
                        x: index == 0 ? -100 : (index == 1 ? 150 : -50),
                        y: index == 0 ? -200 : (index == 1 ? 100 : 300)
                    )
                    .blur(radius: 1)
            }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Compact logo (no "BettorOdds" text - that's handled by loading screen)
            modernCompactLogo
            
            // Welcome message
            welcomeMessage
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    private var modernCompactLogo: some View {
        ZStack {
            // Subtle glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.0, green: 0.9, blue: 0.79).opacity(0.3),  // Teal glow
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 30,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
            
            // Main logo
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            // CHANGE THESE FROM GOLD TO TEAL:
                            Color(red: 0.0, green: 0.9, blue: 0.79),    // Bright teal
                            Color(red: 0.0, green: 0.8, blue: 0.7),     // Medium teal
                            Color(red: 0.0, green: 0.7, blue: 0.6)      // Darker teal
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: Color(red: 0.0, green: 0.9, blue: 0.79).opacity(0.4), radius: 15, x: 0, y: 8)
            
            // Icon
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
        }
    }
    
    private var welcomeMessage: some View {
        VStack(spacing: 12) {
            Text("BettorOdds?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Ethical betting made easy.")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Login Card Section
    
    private var loginCardSection: some View {
        VStack(spacing: 0) {
            // Modern card container
            VStack(spacing: 32) {
                // Card header
                cardHeader
                
                // Sign-in buttons
                signInButtons
                
                Spacer()
            }
            .padding(.top, 40)
            .padding(.horizontal, 32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                ZStack {
                    // Card background
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color.black.opacity(0.7))
                    
                    // Subtle border
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                    
                    // Glass effect
                    RoundedRectangle(cornerRadius: 32)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color.white.opacity(0.1), location: 0.0),
                                    .init(color: Color.clear, location: 0.3),
                                    .init(color: Color.clear, location: 1.0)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .offset(y: cardOffset)
            .opacity(cardOpacity)
            .animation(.spring(response: 0.8, dampingFraction: 0.8), value: cardOffset)
            .animation(.easeInOut(duration: 0.6), value: cardOpacity)
        }
    }
    
    private var cardHeader: some View {
        VStack(spacing: 16) {
            Text("Sign In & Let's Start Cookin'")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
        }
    }
    
    private var signInButtons: some View {
        VStack(spacing: 20) {
            // Apple Sign-In Button
            modernAppleSignInButton
            
            // Google Sign-In Button
            modernGoogleSignInButton
        }
    }
    
    private var modernAppleSignInButton: some View {
        Button(action: {
            triggerHapticFeedback()
            authViewModel.signInWithApple()
        }) {
            HStack(spacing: 12) {
                Image(systemName: "applelogo")
                    .font(.system(size: 18, weight: .medium))
                
                Text("Sign In with Apple")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.black)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(ModernButtonStyle())
        .disabled(authViewModel.isLoading)
    }
    
    private var modernGoogleSignInButton: some View {
        Button(action: {
            triggerHapticFeedback()
            authViewModel.signInWithGoogle()
        }) {
            HStack(spacing: 12) {
                Image("GoogleIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)

                
                Text("Sign In with Google")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.white)
            .cornerRadius(14)
        }
        .buttonStyle(ModernButtonStyle())
        .disabled(authViewModel.isLoading)
    }
    
    // MARK: - Sign-In Loading Overlay
    
    private var signInLoadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Spinning indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                
                Text("Signing you in...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Animation Functions
    
    private func startLoginAnimations() {
        // Animate card entrance
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
            cardOffset = 0
        }
        
        withAnimation(.easeInOut(duration: 0.6).delay(0.4)) {
            cardOpacity = 1.0
        }
    }
    
    private func triggerHapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}


struct GoogleLogoView: View {
    var body: some View {
        ZStack {
            // White background
            Circle()
                .fill(Color.white)
                .frame(width: 20, height: 20)
            
            // Create the "G" with distinct Google colors
            ZStack {
                // Blue part (main part of G)
                Text("G")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(red: 0.26, green: 0.52, blue: 0.96)) // Google blue
                    .mask(
                        Rectangle()
                            .frame(width: 12, height: 8)
                            .offset(x: -2, y: -2)
                    )
                
                // Red part (bottom of G)
                Text("G")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(red: 0.92, green: 0.26, blue: 0.21)) // Google red
                    .mask(
                        Rectangle()
                            .frame(width: 12, height: 4)
                            .offset(x: -2, y: 2)
                    )
            }
        }
    }
}

// MARK: - Modern Button Style

struct ModernButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    EnhancedLoginView()
        .environmentObject(AuthenticationViewModel())
}
