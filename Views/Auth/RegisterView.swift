//
//  RegisterView.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/26/25.
//

import SwiftUI

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
                        .foregroundColor(Color("TextSecondary"))
                }
                .padding(.top, 40)
                
                // Form Fields
                VStack(spacing: 16) {
                    // Email Field
                    VStack(alignment: .leading) {
                        Text("Email")
                            .font(.caption)
                            .foregroundColor(Color("TextSecondary"))
                        TextField("", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    // Password Field
                    VStack(alignment: .leading) {
                        Text("Password")
                            .font(.caption)
                            .foregroundColor(Color("TextSecondary"))
                        HStack {
                            if showPassword {
                                TextField("", text: $password)
                            } else {
                                SecureField("", text: $password)
                            }
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(Color("TextSecondary"))
                            }
                        }
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Confirm Password Field
                    VStack(alignment: .leading) {
                        Text("Confirm Password")
                            .font(.caption)
                            .foregroundColor(Color("TextSecondary"))
                        HStack {
                            if showConfirmPassword {
                                TextField("", text: $confirmPassword)
                            } else {
                                SecureField("", text: $confirmPassword)
                            }
                            Button(action: { showConfirmPassword.toggle() }) {
                                Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(Color("TextSecondary"))
                            }
                        }
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Date of Birth
                    VStack(alignment: .leading) {
                        Text("Date of Birth")
                            .font(.caption)
                            .foregroundColor(Color("TextSecondary"))
                        DatePicker("", selection: $dateOfBirth,
                                 in: ...Date(),
                                 displayedComponents: .date)
                            .labelsHidden()
                    }
                    
                    if !isOver18 {
                        Text("You must be 18 or older to register")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding(.horizontal)
                
                // Error Message
                if let error = authViewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
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
                    .foregroundColor(Color("TextSecondary"))
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
        .onAppear {
            setupKeyboardNotifications()
        }
    }
    
    private func handleRegistration() {
        let userData = [
            "email": email,
            "dateOfBirth": dateOfBirth,
            "dateJoined": Date(),
            "yellowCoins": 100,  // Starting bonus
            "greenCoins": 0,
            "dailyGreenCoinsUsed": 0,
            "isPremium": false
        ] as [String : Any]
        
        authViewModel.signUp(email: email, password: password, userData: userData)
    }
    
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
            isKeyboardVisible = true
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            isKeyboardVisible = false
        }
    }
}

#Preview {
    RegisterView()
        .environmentObject(AuthenticationViewModel())
}
