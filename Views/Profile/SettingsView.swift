import SwiftUI

struct SettingsView: View {
    // MARK: - Properties
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    // App Settings
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    
    // Security Settings
    @State private var requireBiometrics = true
    @State private var showingBiometricPrompt = false
    @State private var showingDisableBiometricsAlert = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                // Appearance Section
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                }
                
                // Security Section
                if BiometricHelper.shared.canUseBiometrics {
                    Section(
                        header: Text("Security"),
                        footer: Text("When enabled, biometric authentication will be required for all real money transactions.")
                    ) {
                        Toggle("Require \(BiometricHelper.shared.biometricType.description)", isOn: $requireBiometrics)
                            .onChange(of: requireBiometrics) { newValue in
                                handleBiometricToggle(isEnabled: newValue)
                            }
                    }
                }
                
                // Notifications Section
                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                }
                
                // App Info Section
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Biometric Status")
                        Spacer()
                        Text(BiometricHelper.shared.biometricType.description)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            // Biometric authentication sheet
            .sheet(isPresented: $showingBiometricPrompt) {
                BiometricPrompt(
                    title: "Confirm Settings Change",
                    subtitle: "Authenticate to change security settings"
                ) { success in
                    if success {
                        // Update the user's preferences
                        if let user = authViewModel.user {
                            Task {
                                await updateUserPreferences(for: user)
                            }
                        }
                    } else {
                        // Revert the toggle if authentication fails
                        requireBiometrics = !requireBiometrics
                    }
                }
            }
            // Alert for disabling biometrics
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
        .onAppear {
            // Load current user preference when view appears
            if let user = authViewModel.user {
                requireBiometrics = user.preferences.requireBiometricsForGreenCoins
            }
        }
    }
    
    // MARK: - Methods
    private func handleBiometricToggle(isEnabled: Bool) {
        if !isEnabled {
            // Show warning alert when trying to disable biometrics
            showingDisableBiometricsAlert = true
        } else {
            // Show biometric prompt when enabling
            showingBiometricPrompt = true
        }
    }
    
    private func updateUserPreferences(for user: User) async {
        do {
            // Create new preferences
            let newPreferences = UserPreferences(
                useBiometrics: requireBiometrics,
                darkMode: isDarkMode,
                notificationsEnabled: notificationsEnabled,
                requireBiometricsForGreenCoins: requireBiometrics
            )
            
            // Create updated user
            var updatedUser = user
            updatedUser.preferences = newPreferences
            
            // Update user in Firebase
            try await authViewModel.updateUser(updatedUser)
            
            // Provide success feedback
            await MainActor.run {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        } catch {
            // Handle error and revert toggle
            await MainActor.run {
                requireBiometrics = !requireBiometrics
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environmentObject(AuthenticationViewModel())
}
