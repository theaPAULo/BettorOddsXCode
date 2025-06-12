//
//  LoginView.swift
//  BettorOdds
//
//  Created by Claude on 1/31/25.
//  Version: 3.0.0 - Completely redesigned for Google/Apple Sign-In
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    // MARK: - Properties
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingError = false
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("Primary").opacity(0.2),
                        Color.white.opacity(0.1),
                        Color("Primary").opacity(0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Top spacer for better centering
                        Spacer()
                            .frame(height: geometry.size.height * 0.15)
                        
                        // Logo and Welcome Section
                        VStack(spacing: 24) {
                            // App Logo
                            VStack(spacing: 16) {
                                // Logo placeholder - you can replace with actual logo
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color("Primary"),
                                                    Color("Primary").opacity(0.8)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 120, height: 120)
                                        .shadow(color: Color("Primary").opacity(0.3), radius: 20, x: 0, y: 10)
                                    
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
                                    .foregroundColor(Color("Primary"))
                                    .shadow(color: Color("Primary").opacity(0.3), radius: 2, x: 0, y: 2)
                            }
                            
                            // Welcome message
                            VStack(spacing: 8) {
                                Text("Welcome Back")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                                
                                Text("Sign in to start betting with friends")
                                    .font(.system(size: 16))
                                    .foregroundColor(.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                        }
                        
                        // Sign-In Buttons Section
                        VStack(spacing: 20) {
                            // Apple Sign-In Button
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
                            
                            // Google Sign-In Button
                            Button(action: {
                                authViewModel.signInWithGoogle()
                            }) {
                                HStack(spacing: 12) {
                                    // Google Logo
                                    Image(systemName: "globe")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.textPrimary)
                                    
                                    Text("Continue with Google")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.textPrimary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            }
                            .disabled(authViewModel.isLoading)
                            
                            // Loading indicator
                            if authViewModel.isLoading {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color("Primary")))
                                        .scaleEffect(0.8)
                                    
                                    Text("Signing in...")
                                        .font(.system(size: 14))
                                        .foregroundColor(.textSecondary)
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 48)
                        
                        // Terms and Privacy
                        VStack(spacing: 8) {
                            Text("By signing in, you agree to our")
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                            
                            HStack(spacing: 4) {
                                Button("Terms of Service") {
                                    // Handle terms of service tap
                                }
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color("Primary"))
                                
                                Text("and")
                                    .font(.system(size: 12))
                                    .foregroundColor(.textSecondary)
                                
                                Button("Privacy Policy") {
                                    // Handle privacy policy tap
                                }
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color("Primary"))
                            }
                        }
                        .padding(.top, 32)
                        .padding(.horizontal, 32)
                        
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
}

// MARK: - Preview
#Preview {
    LoginView()
        .environmentObject(AuthenticationViewModel())
}
