//
//  SettingsView.swift
//  BettorOdds
//
//  Created by Claude on 1/31/25.
//  Version: 3.2.0 - Fixed compiler type-checking issue by breaking down complex views
//

import SwiftUI
import UIKit  // Required for UINotificationFeedbackGenerator

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    // App Settings
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    
    // Local state for user preferences
    @State private var requireBiometrics = true
    @State private var showingBiometricPrompt = false
    @State private var showingDisableBiometricsAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // Account Information Section
                accountSection
                
                // App Preferences Section
                preferencesSection
                
                // Security Section
                securitySection
                
                // About Section
                aboutSection
                
                // Account Actions Section
                accountActionsSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color("Primary"))
                }
            }
            .onAppear {
                loadUserPreferences()
            }
            // Biometric Authentication Alerts
            .alert("Enable Biometric Authentication", isPresented: $showingBiometricPrompt) {
                Button("Cancel", role: .cancel) {
                    requireBiometrics = false
                }
                Button("Enable") {
                    Task {
                        await enableBiometrics()
                    }
                }
            } message: {
                Text("Use Face ID or Touch ID to secure your Green Coin transactions?")
            }
            .alert("Disable Biometric Authentication", isPresented: $showingDisableBiometricsAlert) {
                Button("Cancel", role: .cancel) {
                    requireBiometrics = true
                }
                Button("Disable", role: .destructive) {
                    Task {
                        await disableBiometrics()
                    }
                }
            } message: {
                Text("Disabling biometric authentication will reduce the security of your real money transactions. Are you sure you want to continue?")
            }
        }
    }
}

// MARK: - View Components

extension SettingsView {
    
    /// Account information section
    private var accountSection: some View {
        Section("Account") {
            if let user = authViewModel.user {
                AccountInfoRow(user: user)
            }
        }
    }
    
    /// App preferences section
    private var preferencesSection: some View {
        Section("Preferences") {
            // Dark Mode Toggle
            PreferenceRow(
                icon: "moon.fill",
                title: "Dark Mode",
                isOn: $isDarkMode
            )
            
            // Notifications Toggle
            PreferenceRow(
                icon: "bell.fill",
                title: "Push Notifications",
                isOn: $notificationsEnabled
            )
        }
    }
    
    /// Security settings section
    private var securitySection: some View {
        Section("Security") {
            BiometricRow(
                isEnabled: $requireBiometrics,
                onToggle: handleBiometricToggle
            )
        }
    }
    
    /// About section
    private var aboutSection: some View {
        Section("About") {
            InfoRow(title: "Version", value: "3.2.0")
            InfoRow(title: "Build", value: "1")
            
            Button(action: {
                // Handle contact support
            }) {
                ActionRow(
                    icon: "envelope",
                    title: "Contact Support",
                    showChevron: true
                )
            }
        }
    }
    
    /// Account actions section
    private var accountActionsSection: some View {
        Section {
            Button(action: {
                Task {
                    await authViewModel.signOut()
                }
            }) {
                ActionRow(
                    icon: "rectangle.portrait.and.arrow.right",
                    title: "Sign Out",
                    isDestructive: true
                )
            }
        }
    }
}



// MARK: - Helper Methods

extension SettingsView {
    
    /// Loads current user preferences
    private func loadUserPreferences() {
        if let user = authViewModel.user {
            requireBiometrics = user.preferences.requireBiometricsForGreenCoins
        }
    }
    
    /// Handles the biometric toggle change
    private func handleBiometricToggle(isEnabled: Bool) {
        if !isEnabled {
            showingDisableBiometricsAlert = true
        } else {
            showingBiometricPrompt = true
        }
    }
    
    /// Enables biometric authentication
    private func enableBiometrics() async {
        await savePreferences()
    }
    
    /// Disables biometric authentication
    private func disableBiometrics() async {
        await savePreferences()
    }
    
    /// Saves user preferences to Firebase
    private func savePreferences() {
        if let user = authViewModel.user {
            Task {
                await updateUserPreferences(for: user)
            }
        }
    }
    
    /// Updates user preferences in Firebase
    private func updateUserPreferences(for user: User) async {
        do {
            var updatedUser = user
            updatedUser.preferences.requireBiometricsForGreenCoins = requireBiometrics
            
            try await authViewModel.updateUser(updatedUser)
            
            // Success feedback
            await MainActor.run {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        } catch {
            // Error feedback and revert toggle
            await MainActor.run {
                requireBiometrics = !requireBiometrics
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            }
        }
    }
}

// MARK: - Supporting Views

/// Displays user account information
struct AccountInfoRow: View {
    let user: User
    
    var body: some View {
        HStack {
            // Profile image or avatar
            ProfileImageView(user: user)
            
            // User details
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName ?? "Unknown User")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                AuthProviderView(user: user)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

/// Profile image view component
struct ProfileImageView: View {
    let user: User
    
    var body: some View {
        Group {
            if let profileImageURL = user.profileImageURL,
               let url = URL(string: profileImageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } placeholder: {
                    DefaultProfileImage(user: user)
                }
            } else {
                DefaultProfileImage(user: user)
            }
        }
    }
}

/// Default profile image when no URL is available
struct DefaultProfileImage: View {
    let user: User
    
    var body: some View {
        Circle()
            .fill(Color("Primary").opacity(0.2))
            .frame(width: 40, height: 40)
            .overlay(
                Text(user.displayName?.prefix(1).uppercased() ?? "U")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color("Primary"))
            )
    }
}

/// Auth provider display component
struct AuthProviderView: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: user.authProvider == "google.com" ? "globe" : "applelogo")
                .font(.system(size: 12))
            Text(user.authProvider == "google.com" ? "Google" : "Apple")
                .font(.caption)
        }
        .foregroundColor(.textSecondary)
    }
}

/// Preference toggle row component
struct PreferenceRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color("Primary"))
                .frame(width: 20)
            
            Text(title)
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color("Primary")))
        }
    }
}

/// Biometric authentication row component
struct BiometricRow: View {
    @Binding var isEnabled: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "faceid")
                .foregroundColor(Color("Primary"))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Biometric Authentication")
                    .foregroundColor(.textPrimary)
                Text("Required for Green Coin transactions")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .toggleStyle(SwitchToggleStyle(tint: Color("Primary")))
                .onChange(of: isEnabled) { _, newValue in
                    onToggle(newValue)
                }
        }
    }
}

/// Action row component for buttons
struct ActionRow: View {
    let icon: String
    let title: String
    var showChevron: Bool = false
    var isDestructive: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isDestructive ? .red : Color("Primary"))
                .frame(width: 20)
            
            Text(title)
                .foregroundColor(isDestructive ? .red : .textPrimary)
            
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

/// Info row component for displaying key-value pairs
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.textPrimary)
            Spacer()
            Text(value)
                .foregroundColor(.textSecondary)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(AuthenticationViewModel())
}
