//
//  LoginView.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/26/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isKeyboardVisible = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Logo and Title
                    VStack(spacing: 8) {
                        Text("BettorOdds")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color("TextPrimary"))
                        
                        Text("Sign in to continue")
                            .font(.system(size: 16))
                            .foregroundColor(Color("TextSecondary"))
                    }
                    .padding(.top, 60)
                    
                    // Login Form
                    VStack(spacing: 16) {
                        // Email Field
                        VStack(alignment: .leading) {
                            Text("Email")
                                .font(.caption)
                                .foregroundColor(Color("TextSecondary"))
                            TextField("", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
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
                                        .textContentType(.password)
                                } else {
                                    SecureField("", text: $password)
                                        .textContentType(.password)
                                }
                                
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(Color("TextSecondary"))
                                }
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Error Message
                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Login Button
                    Button(action: {
                        authViewModel.signIn(email: email, password: password)
                    }) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Sign In")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color("Primary"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                    .disabled(authViewModel.isLoading)
                    
                    // Forgot Password
                    Button(action: {
                        // Navigate to forgot password
                    }) {
                        Text("Forgot Password?")
                            .foregroundColor(Color("Primary"))
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Spacer()
                    
                    // Register Link
                    NavigationLink(destination: RegisterView()) {
                        HStack {
                            Text("Don't have an account?")
                                .foregroundColor(Color("TextSecondary"))
                            Text("Sign Up")
                                .foregroundColor(Color("Primary"))
                                .fontWeight(.medium)
                        }
                        .font(.system(size: 16))
                    }
                    .padding(.bottom, isKeyboardVisible ? 20 : 40)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            setupKeyboardNotifications()
        }
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
    LoginView()
        .environmentObject(AuthenticationViewModel())
}
