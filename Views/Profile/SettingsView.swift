//
//  SettingsView.swift
//  BettorOdds
//
//  Created by Claude on 1/31/25.
//  Version: 2.0.0
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    // App Settings
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("rememberMe") private var rememberMe = false
    
    // Security Settings
    @State private var requireBiometrics = true
    @State private var showingBiometricPrompt = false
    @State private var showingDisableBiometricsAlert = false
    @State private var preferences: UserPreferences
    
    // MARK: - Initialization
    init() {
        // Initialize preferences from current user if available
        if let currentUser = try? AuthenticationViewModel().user {
            _preferences = State(initialValue: currentUser.preferences)
        } else {
            _preferences = State(initialValue: UserPreferences())
        }
    }
    
    var body: some View {
        NavigationView {
            List {
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
                        // Save Credentials Toggle
                        HStack {
                            Label("Save Login Credentials", systemImage: "key.fill")
                                .foregroundColor(.textPrimary)
                            Spacer()
                            Toggle("", isOn: $preferences.saveCredentials)
                                .tint(.primary)
                        }
                        
                        // Remember Me Toggle
                        HStack {
                            Label("Remember Me", systemImage: "person.fill.checkmark")
                                .foregroundColor(.textPrimary)
                            Spacer()
                            Toggle("", isOn: $preferences.rememberMe)
                                .tint(.primary)
                        }
                        
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
                        Toggle("", isOn: $preferences.notificationsEnabled)
                            .tint(.primary)
                    }
                } header: {
                    Text("Notifications")
                        .foregroundColor(.textSecondary)
                } footer: {
                    Text("Receive updates about your bets and important events")
                        .foregroundColor(.textSecondary)
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
                
                // Danger Zone
                Section {
                    Button(action: {
                        // Clear app data
                    }) {
                        Label("Clear App Data", systemImage: "trash.fill")
                            .foregroundColor(.statusError)
                    }
                    Button(action: {
                        authViewModel.signOut()
                        dismiss()
                    }) {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.statusError)
                    }
                } header: {
                    Text("Danger Zone")
                        .foregroundColor(.statusError)
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
            updatedUser.preferences = preferences
            
            try await authViewModel.updateUser(updatedUser)
            
            // Save remember me state
            UserDefaults.standard.set(preferences.rememberMe, forKey: "rememberMe")
            
            await MainActor.run {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        } catch {
            await MainActor.run {
                requireBiometrics = !requireBiometrics
                let generator = UINotificationFeedbackGenerator()
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
