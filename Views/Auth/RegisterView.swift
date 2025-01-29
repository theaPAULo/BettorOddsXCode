import SwiftUI
import FirebaseFirestore

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Environment(\.dismiss) var dismiss
    
    // Form fields
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var dateOfBirth = Date()
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var isKeyboardVisible = false
    
    // Validation
    private var isFormValid: Bool {
        let emailIsValid = email.contains("@") && email.contains(".")
        let passwordIsValid = password.count >= 8
        let passwordsMatch = password == confirmPassword
        return emailIsValid && passwordIsValid && passwordsMatch && isOver18
    }
    
    // Age verification
    private var isOver18: Bool {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year],
                                                  from: dateOfBirth,
                                                  to: Date())
        return ageComponents.year ?? 0 >= 18
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Create Account")
                        .font(.system(size: 32, weight: .bold))
                    Text("Sign up to start betting")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Form Fields
                VStack(spacing: 16) {
                    // Email Field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Password")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            if showPassword {
                                TextField("Enter your password", text: $password)
                                    .textContentType(.newPassword)
                            } else {
                                SecureField("Enter your password", text: $password)
                                    .textContentType(.newPassword)
                            }
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Confirm Password Field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Confirm Password")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            if showConfirmPassword {
                                TextField("Confirm your password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                            } else {
                                SecureField("Confirm your password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                            }
                            Button(action: { showConfirmPassword.toggle() }) {
                                Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Date of Birth
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Date of Birth")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        DatePicker("", selection: $dateOfBirth,
                                 in: ...Date(),
                                 displayedComponents: .date)
                            .labelsHidden()
                    }
                }
                .padding(.horizontal)
                
                if !isOver18 {
                    Text("You must be 18 or older to register")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                // Error Message
                if let error = authViewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Register Button
                Button(action: handleRegistration) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Create Account")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isFormValid ? Color("Primary") : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal)
                .disabled(!isFormValid || authViewModel.isLoading)
                
                // Terms and Privacy
                Text("By creating an account, you agree to our Terms of Service and Privacy Policy")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Login Link
                HStack {
                    Text("Already have an account?")
                    Button("Sign In") {
                        dismiss()
                    }
                    .foregroundColor(Color("Primary"))
                }
                .padding(.vertical)
            }
        }
    }
    
    private func handleRegistration() {
        print("Starting registration process...")  // Debug log
        
        // Validate email
        guard email.contains("@") && email.contains(".") else {
            authViewModel.errorMessage = "Please enter a valid email address"
            return
        }
        
        // Validate password
        guard password.count >= 6 else {
            authViewModel.errorMessage = "Password must be at least 6 characters"
            return
        }
        
        // Validate passwords match
        guard password == confirmPassword else {
            authViewModel.errorMessage = "Passwords do not match"
            return
        }
        
        // Validate age
        guard isOver18 else {
            authViewModel.errorMessage = "You must be 18 or older to register"
            return
        }
        
        print("Validation passed, preparing user data...")  // Debug log
        
        let userData = [
            "email": email,
            "dateJoined": Date(),
            "dateOfBirth": dateOfBirth,
            "yellowCoins": 100,  // Starting bonus
            "greenCoins": 0,
            "dailyGreenCoinsUsed": 0,
            "isPremium": false,
            "lastBetDate": Date(),
            "preferences": [
                "useBiometrics": false,
                "darkMode": false,
                "notificationsEnabled": true,
                "requireBiometricsForGreenCoins": true
            ]
        ] as [String : Any]
        
        authViewModel.signUp(email: email, password: password, userData: userData)
    }
}

#Preview {
    RegisterView()
        .environmentObject(AuthenticationViewModel())
}
