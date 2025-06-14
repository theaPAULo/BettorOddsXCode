//
//  BiometricPrompt.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Version: 1.2.0 - Fixed typography reference
//

import SwiftUI

struct BiometricPrompt: View {
    // MARK: - Properties
    let title: String
    let subtitle: String
    let onAuthenticate: (Bool) -> Void
    
    @State private var isAuthenticating = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initialization
    init(
        title: String = "Authentication Required",
        subtitle: String = "Please authenticate to continue",
        onAuthenticate: @escaping (Bool) -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.onAuthenticate = onAuthenticate
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Biometric Icon
                Image(systemName: BiometricHelper.shared.biometricType.systemImageName)
                    .font(.system(size: 64))
                    .foregroundColor(AppTheme.Colors.primary)
                
                // Title and Subtitle
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text(title)
                        .font(AppTheme.Typography.title2)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(AppTheme.Typography.callout)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                // Error Message
                if let error = errorMessage {
                    Text(error)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.error)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(AppTheme.Colors.error.opacity(0.1))
                        .cornerRadius(AppTheme.CornerRadius.medium)
                }
                
                // Authenticate Button
                Button(action: authenticate) {
                    HStack {
                        if isAuthenticating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Authenticate with \(BiometricHelper.shared.biometricType.description)")
                                .font(AppTheme.Typography.bodyBold) // Fixed: using bodyBold instead of button
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(AppTheme.Colors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                    .shadow(
                        color: AppTheme.Shadow.medium.color,
                        radius: AppTheme.Shadow.medium.radius,
                        x: AppTheme.Shadow.medium.x,
                        y: AppTheme.Shadow.medium.y
                    )
                }
                .disabled(isAuthenticating)
                
                // Cancel Button
                Button("Cancel") {
                    onAuthenticate(false)
                    dismiss()
                }
                .font(AppTheme.Typography.callout)
                .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding(AppTheme.Spacing.lg)
            .onAppear(perform: authenticate)
        }
    }
    
    // MARK: - Methods
    private func authenticate() {
        // Don't proceed if already authenticating
        guard !isAuthenticating else { return }
        
        // Check if biometrics are available
        guard BiometricHelper.shared.canUseBiometrics else {
            errorMessage = "Biometric authentication is not available"
            onAuthenticate(false)
            return
        }
        
        // Start authentication
        isAuthenticating = true
        errorMessage = nil
        
        Task {
            // Provide haptic feedback
            HapticManager.impact(.medium)
            
            // Attempt authentication
            let (success, error) = await BiometricHelper.shared.authenticate(
                reason: "Authenticate to continue"
            )
            
            // Update UI on main thread
            await MainActor.run {
                isAuthenticating = false
                errorMessage = error
                
                if success {
                    HapticManager.notification(.success)
                    onAuthenticate(true)
                    dismiss()
                } else {
                    HapticManager.notification(.error)
                }
            }
        }
    }
}

#Preview {
    BiometricPrompt { success in
        print("Authentication result: \(success)")
    }
}
