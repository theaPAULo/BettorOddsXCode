//
//  LoginView.swift
//  BettorOdds
//
//  Created by Claude on 1/31/25.
//  Version: 3.0.1 - Fixed compiler timeout issue with simplified background
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    // MARK: - Properties
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingError = false
    
    // MARK: - Computed Properties
    
    // Break down complex gradient into separate computed property
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.primary.opacity(0.2),
                Color.white.opacity(0.1),
                Color.primary.opacity(0.2)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
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
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Simplified Background
                backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Top spacer for better centering
                        Spacer()
                            .frame(height: geometry.size.height * 0.15)
                        
                        // Logo and Welcome Section
                        logoAndWelcomeSection
                        
                        // Sign-In Buttons Section
                        signInButtonsSection
                        
                        // Terms and Privacy
                        termsAndPrivacySection
                        
                        // Bottom spacer
                        Spacer()
                            .frame(height: geometry.size.height * 0.1)
                    }
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
        .onChange(of: authViewModel.errorMessage) { errorMessage in
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
                
                Text("BettorOdds")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(Color.primary)
                    .shadow(color: Color.primary.opacity(0.3), radius: 2, x: 0, y: 2)
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
            .overlay(googleButtonOverlay)
        }
        .disabled(authViewModel.isLoading)
    }
    
    private var googleButtonBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var googleButtonOverlay: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
    }
    
    private var loadingIndicator: some View {
        HStack(spacing: 8) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.primary))
                .scaleEffect(0.8)
            
            Text("Signing in...")
                .font(.system(size: 14))
                .foregroundColor(Color("TextSecondary"))
        }
        .padding(.top, 8)
    }
    
    private var termsAndPrivacySection: some View {
        VStack(spacing: 8) {
            Text("By signing in, you agree to our")
                .font(.system(size: 12))
                .foregroundColor(Color("TextSecondary"))
            
            HStack(spacing: 4) {
                Button("Terms of Service") {
                    // Handle terms of service tap
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.primary)
                
                Text("and")
                    .font(.system(size: 12))
                    .foregroundColor(Color("TextSecondary"))
                
                Button("Privacy Policy") {
                    // Handle privacy policy tap
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.primary)
            }
        }
        .padding(.top, 32)
        .padding(.horizontal, 32)
    }
}

// MARK: - Preview
#Preview {
    LoginView()
        .environmentObject(AuthenticationViewModel())
}
