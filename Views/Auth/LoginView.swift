//
//  LoginView.swift
//  BettorOdds
//
//  Version: 2.7.0 - Fixed iOS 17 onChange deprecation warning
//  Updated: June 2025
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingError = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                backgroundGradient
                    .ignoresSafeArea()
                
                // Main content
                VStack(spacing: 0) {
                    // Logo and welcome section
                    logoAndWelcomeSection
                        .frame(height: geometry.size.height * 0.5)
                    
                    // Sign-in buttons section
                    signInButtonsSection
                        .frame(height: geometry.size.height * 0.4)
                    
                    // Spacer to push content up
                    Spacer()
                        .frame(height: geometry.size.height * 0.1)
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
        // FIXED: Updated onChange for iOS 17 compatibility
        .onChange(of: authViewModel.errorMessage) { _, errorMessage in
            showingError = errorMessage != nil
        }
    }
    
    // MARK: - View Components
    
    private var logoAndWelcomeSection: some View {
        VStack(spacing: 24) {
            // App Logo
            VStack(spacing: 16) {
                // Logo placeholder - you can replace with actual logo
                ZStack {
                    Circle()
                        .fill(logoGradient)
                        .frame(width: 120, height: 120)
                        .shadow(color: Color.primary.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    VStack(spacing: 4) {
                        Text("🎲")
                            .font(.system(size: 40))
                        Text("BO")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                // SUGGESTION: Restored the gold gradient BettorOdds title you liked!
                Text("BettorOdds")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "FFD700"), // Gold
                                Color(hex: "FFA500"), // Orange-gold
                                Color(hex: "FF8C00")  // Darker orange
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 2)
            }
            
            // Welcome message
            VStack(spacing: 8) {
                Text("Sign in & start cooking")
                    .font(.system(size: 16))
                    .foregroundColor(Color("TextSecondary"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
    
    private var signInButtonsSection: some View {
        VStack(spacing: 20) {
            // Apple Sign-In Button
            appleSignInButton
            
            // Google Sign-In Button
            googleSignInButton
            
            // Loading indicator
            if authViewModel.isLoading {
                loadingIndicator
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 48)
    }
    
    private var appleSignInButton: some View {
        SignInWithAppleButton(
            onRequest: { request in
                request.requestedScopes = [.fullName, .email]
            },
            onCompletion: { result in
                // This is handled by the AuthenticationViewModel
                // We'll trigger the sign-in through our view model instead
            }
        )
        .frame(height: 56)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .onTapGesture {
            authViewModel.signInWithApple()
        }
    }
    
    private var googleSignInButton: some View {
        Button(action: {
            authViewModel.signInWithGoogle()
        }) {
            HStack(spacing: 12) {
                // Google Logo
                Image(systemName: "globe")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color("TextPrimary"))
                
                Text("Continue with Google")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color("TextPrimary"))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(googleButtonBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .disabled(authViewModel.isLoading)
    }
    
    private var loadingIndicator: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
            
            Text("Signing in...")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(.top, 16)
    }
    
    // MARK: - Computed Properties
    
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color("BackgroundPrimary"),
                Color("BackgroundSecondary").opacity(0.8)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var logoGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.primary,
                Color.primary.opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var googleButtonBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color("BackgroundPrimary"))
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
    }
}

// MARK: - Color Extension for Hex Support

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationViewModel())
}
