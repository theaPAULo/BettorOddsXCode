//
//  PhoneVerificationView.swift
//  BettorOdds
//
//  Created by Paul Soni on 2/5/25.
//


//
//  PhoneVerificationView.swift
//  BettorOdds
//
//  Created by Paul Soni on 2/5/25
//  Version: 1.0.0
//

import SwiftUI
import FirebaseAuth

struct PhoneVerificationView: View {
    // MARK: - Properties
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var isCodeSent = false
    @FocusState private var isPhoneFocused: Bool
    @FocusState private var isCodeFocused: Bool
    
    // MARK: - Phone Formatting
    private func formatPhoneNumber(_ number: String) -> String {
        let cleaned = number.filter { $0.isNumber }
        guard cleaned.count <= 10 else { return phoneNumber }
        
        var result = ""
        for (index, char) in cleaned.enumerated() {
            if index == 0 {
                result = "(" + String(char)
            } else if index == 3 {
                result += ") " + String(char)
            } else if index == 6 {
                result += "-" + String(char)
            } else {
                result += String(char)
            }
        }
        return result
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color("Primary"))
                    
                    Text(isCodeSent ? "Enter Verification Code" : "Phone Verification")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text(isCodeSent ? 
                         "Enter the code we sent to your phone" :
                         "We'll send you a code to verify your phone number")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                // Phone Input Section
                if !isCodeSent {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone Number")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("(555) 555-5555", text: $phoneNumber)
                            .keyboardType(.numberPad)
                            .textContentType(.telephoneNumber)
                            .focused($isPhoneFocused)
                            .onChange(of: phoneNumber) { newValue in
                                phoneNumber = formatPhoneNumber(newValue)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                // Verification Code Section
                if isCodeSent {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Verification Code")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter 6-digit code", text: $verificationCode)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .focused($isCodeFocused)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                // Action Button
                CustomButton(
                    title: isCodeSent ? "Verify Code" : "Send Code",
                    action: {
                        if isCodeSent {
                            Task {
                                await authViewModel.verifyCode(verificationCode)
                            }
                        } else {
                            let formattedNumber = "+1" + phoneNumber.filter { $0.isNumber }
                            Task {
                                await authViewModel.sendVerificationCode(to: formattedNumber)
                                withAnimation {
                                    isCodeSent = true
                                    isCodeFocused = true
                                }
                            }
                        }
                    },
                    isLoading: authViewModel.isLoading,
                    disabled: isCodeSent ? 
                        verificationCode.count != 6 : 
                        phoneNumber.filter { $0.isNumber }.count != 10
                )
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarItems(leading: Button("Cancel") { dismiss() })
        }
        .alert("Error", isPresented: .constant(authViewModel.errorMessage != nil)) {
            Button("OK") {
                authViewModel.errorMessage = nil
            }
        } message: {
            if let error = authViewModel.errorMessage {
                Text(error)
            }
        }
    }
}

// MARK: - Preview Provider
#Preview {
    PhoneVerificationView()
        .environmentObject(AuthenticationViewModel())
}