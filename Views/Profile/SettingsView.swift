//
//  SettingsView.swift
//  BettorOdds
//
//  Created by Claude on 1/31/25.
//  Version: 3.0.0 - Updated for Google/Apple Sign-In authentication
//

import SwiftUI

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
                Section {
                    if let user = authViewModel.user {
                        HStack {
                            // Profile image or avatar
                            if let profileImageURL = user.profileImageURL,
                               let url = URL(string: profileImageURL) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                } placeholder: {
                                    Circle()
                                        .fill(Color("Primary").opacity(0.2))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Text(user.displayName?.prefix(1).uppercased() ?? "U")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(Color("Primary"))
                                        )
                                }
                            } else {
                                Circle()
                                    .fill(Color("Primary").opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(user.displayName?.prefix(1).uppercased() ?? "U")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(Color("Primary"))
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.displayName ?? "Unknown User")
                                    .font(.headline)
                                    .foregroundColor(.textPrimary)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: user.authProvider == "google.com" ? "globe" : "applelogo")
                                        .font(.system(size: 12))
                                    Text(user.authProvider == "google.com" ? "Google Account" : "Apple Account")
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(.textSecondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Account")
                        .foregroundColor(.textSecondary)
                }
                
                // Appearance Section
                Section {
                    HStack {
                        Label("Dark Mode", systemImage: "moon.fill")
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Toggle("", isOn: $isDarkMode)
                            .tint(.primary)
                    }
                } header: {
                    Text("Appearance")
                        .foregroundColor(.textSecondary)
                } footer: {
                    Text("Changes app theme between light and dark mode")
                        .foregroundColor(.textSecondary)
                }
                
                // Security Section
                if BiometricHelper.shared.canUseBiometrics {
                    Section {
                        HStack {
                            Label(
                                "Require \(BiometricHelper.shared.biometricType.description)",
                                systemImage: BiometricHelper.shared.biometricType.systemImageName
                            )
                            .foregroundColor(.textPrimary)
                            Spacer()
                            Toggle("", isOn: $requireBiometrics)
                                .tint(.primary)
                        }
                    } header: {
                        Text("Security")
                            .foregroundColor(.textSecondary)
                    } footer: {
                        Text("When enabled, biometric authentication will be required for all real money transactions.")
                            .foregroundColor(.textSecondary)
                    }
                    .onChange(of: requireBiometrics) { newValue in
                        handleBiometricToggle(isEnabled: newValue)
                    }
                }
                
                // Notifications Section
                Section {
                    HStack {
                        Label("Enable Notifications", systemImage: "bell.fill")
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Toggle("", isOn: $notificationsEnabled)
                            .tint(.primary)
                    }
                } header: {
                    Text("Notifications")
                        .foregroundColor(.textSecondary)
                } footer: {
                    Text("Receive updates about your bets and important events")
                        .foregroundColor(.textSecondary)
                }
                
                // Coin Balances Section
                if let user = authViewModel.user {
                    Section {
                        HStack {
                            Label("Play Coins", systemImage: "gamecontroller")
                                .foregroundColor(.textPrimary)
                            Spacer()
                            Text("🟡 \(user.yellowCoins)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.textPrimary)
                        }
                        
                        HStack {
                            Label("Real Coins", systemImage: "dollarsign")
                                .foregroundColor(.textPrimary)
                            Spacer()
                            Text("💚 \(user.greenCoins)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.textPrimary)
                        }
                        
                        HStack {
                            Label("Daily Limit Used", systemImage: "chart.bar")
                                .foregroundColor(.textPrimary)
                            Spacer()
                            Text("\(user.dailyGreenCoinsUsed)/100")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(user.dailyGreenCoinsUsed > 80 ? .statusWarning : .textPrimary)
                        }
                    } header: {
                        Text("Coin Balances")
                            .foregroundColor(.textSecondary)
                    }
                }
                
                // App Info Section
                Section {
                    InfoRow(title: "Version", value: "1.0.0")
                    InfoRow(
                        title: "Biometric Status",
                        value: BiometricHelper.shared.biometricType.description
                    )
                    
                    Button(action: {
                        // Open privacy policy
                    }) {
                        Label("Privacy Policy", systemImage: "doc.text.fill")
                            .foregroundColor(.textPrimary)
                    }
                    
                    Button(action: {
                        // Open terms of service
                    }) {
                        Label("Terms of Service", systemImage: "doc.text.fill")
                            .foregroundColor(.textPrimary)
                    }
                } header: {
                    Text("About")
                        .foregroundColor(.textSecondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.backgroundPrimary)
            .scrollContentBackground(.hidden)
            .navigationBarItems(trailing: Button("Done") {
                savePreferences()
                dismiss()
            })
            .sheet(isPresented: $showingBiometricPrompt) {
                BiometricPrompt(
                    title: "Confirm Settings Change",
                    subtitle: "Authenticate to change security settings"
                ) { success in
                    if success {
                        if let user = authViewModel.user {
                            Task {
                                await updateUserPreferences(for: user)
                            }
                        }
                    } else {
                        requireBiometrics = !requireBiometrics
                    }
                }
            }
            .alert("Disable Biometric Authentication?", isPresented: $showingDisableBiometricsAlert) {
                Button("Cancel", role: .cancel) {
                    requireBiometrics = true
                }
                Button("Disable", role: .destructive) {
                    showingBiometricPrompt = true
                }
            } message: {
                Text("Disabling biometric authentication will reduce the security of your real money transactions. Are you sure you want to continue?")
            }
            .onAppear {
                // Load current user preferences
                if let user = authViewModel.user {
                    requireBiometrics = user.preferences.requireBiometricsForGreenCoins
                }
            }
        }
    }
    
    private func handleBiometricToggle(isEnabled: Bool) {
        if !isEnabled {
            showingDisableBiometricsAlert = true
        } else {
            showingBiometricPrompt = true
        }
    }
    
    private func savePreferences() {
        if let user = authViewModel.user {
            Task {
                await updateUserPreferences(for: user)
            }
        }
    }
    
    private func updateUserPreferences(for user: User) async {
        do {
            var updatedUser = user
            updatedUser.preferences.requireBiometricsForGreenCoins = requireBiometrics
            
            try await authViewModel.updateUser(updatedUser)
            
            await MainActor.run {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        } catch {
            await MainActor.run {
                requireBiometrics = !requireBiometrics
                let generator = UINotificationFeedGenerator()
                generator.notificationOccurred(.error)
            }
        }
    }
}

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

#Preview {
    SettingsView()
        .environmentObject(AuthenticationViewModel())
}
