//
//  ForgotPasswordView.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/26/25.
//  Version: 2.0.0 - Updated for EnhancedTheme compatibility
//

import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Header
                    VStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 64))
                            .foregroundColor(Color.primary)
                        
                        Text("Reset Password")
                            .font(AppTheme.Typography.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Text("Enter your email address and we'll send you a link to reset your password.")
                            .font(AppTheme.Typography.callout)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Spacing.md)
                    }
                    
                    // Email Input
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("Email Address")
                            .font(AppTheme.Typography.callout)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .fontWeight(.medium)
                        
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    
                    // Error Message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.error)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Spacing.md)
                    }
                    
                    // Send Reset Link Button
                    Button(action: sendResetLink) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .tint(.white)
                            } else {
                                Text("Send Reset Link")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.primary)
                        .foregroundColor(.white)
                        .cornerRadius(AppTheme.CornerRadius.medium)
                        .shadow(
                            color: AppTheme.Shadow.medium.color,
                            radius: AppTheme.Shadow.medium.radius,
                            x: AppTheme.Shadow.medium.x,
                            y: AppTheme.Shadow.medium.y
                        )
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .disabled(isLoading || email.isEmpty)
                    
                    Spacer()
                }
                .padding(.top, AppTheme.Spacing.xl)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
        .alert("Password Reset Link Sent", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Check your email for instructions to reset your password.")
        }
    }
    
    private func sendResetLink() {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                showSuccess = true
            }
        }
    }
}

#Preview {
    ForgotPasswordView()
}
