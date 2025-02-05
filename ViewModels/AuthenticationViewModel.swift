
//  AuthenticationViewModel.swift
//  BettorOdds
//
//  Created by Claude on 1/31/25.
//  Version: 2.2.0 - Added phone verification support
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine
import SwiftUI

@MainActor
class AuthenticationViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var user: User?
    @Published var authState: AuthState = .loading
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Phone verification properties
    @Published var verificationID: String?
    @Published var isPhoneVerified = false
    private var resendTimer: Timer?
    private var resendCountdown: Int = 30
    
    // MARK: - Private Properties
    private let db = Firestore.firestore()
    
    // MARK: - Initialization
    init() {
        checkAuthState()
    }
    
    // MARK: - Phone Verification Methods
    
    /// Sends verification code to provided phone number
    /// - Parameter phoneNumber: Phone number in E.164 format (+1XXXXXXXXXX)
    func sendVerificationCode(to phoneNumber: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("📱 Attempting to send verification code to: \(phoneNumber)")
            
            let verificationID = try await PhoneAuthProvider.provider()
                .verifyPhoneNumber(phoneNumber, uiDelegate: nil)
            
            self.verificationID = verificationID
            self.authState = .pendingPhoneVerification
            print("✉️ Verification code sent successfully")
            
        } catch {
            print("❌ Error sending verification code: \(error.localizedDescription)")
            errorMessage = handlePhoneAuthError(error)
        }
        
        isLoading = false
    }
    
    /// Verifies the code entered by user
    /// - Parameter code: 6-digit verification code
    func verifyCode(_ code: String) async {
        guard let verificationID = verificationID else {
            errorMessage = "Please request a new verification code"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔍 Verifying phone code...")
            
            let credential = PhoneAuthProvider.provider().credential(
                withVerificationID: verificationID,
                verificationCode: code
            )
            
            let authResult = try await Auth.auth().signIn(with: credential)
            try await handlePhoneAuthSuccess(userId: authResult.user.uid)
            
            self.isPhoneVerified = true
            self.authState = .signedIn
            print("✅ Phone verification successful")
            
        } catch {
            print("❌ Error verifying code: \(error.localizedDescription)")
            errorMessage = handlePhoneAuthError(error)
        }
        
        isLoading = false
    }
    
    /// Handles successful phone authentication
    private func handlePhoneAuthSuccess(userId: String) async throws {
        print("👤 Handling successful phone auth for user: \(userId)")
        
        let userDoc = try await db.collection("users").document(userId).getDocument()
        
        if userDoc.exists {
            try await fetchUser(userId: userId)
            print("✅ Existing user document fetched")
        } else {
            let newUser = User(
                id: userId,
                email: "",
                phoneNumber: self.verificationID
            )
            
            try await db.collection("users").document(userId).setData(newUser.toDictionary())
            self.user = newUser
            print("✅ New user document created")
        }
    }
    
    private func handlePhoneAuthError(_ error: Error) -> String {
        let nsError = error as NSError
        switch nsError.code {
        case AuthErrorCode.invalidPhoneNumber.rawValue:
            return "Please enter a valid phone number"
        case AuthErrorCode.quotaExceeded.rawValue:
            return "Too many attempts. Please try again later"
        case AuthErrorCode.invalidVerificationCode.rawValue:
            return "Invalid verification code. Please try again"
        case AuthErrorCode.sessionExpired.rawValue:
            return "Code expired. Please request a new one"
        default:
            return "An error occurred. Please try again"
        }
    }
    
    // MARK: - Public Methods
    
    /// Signs in a user with email and password
    /// - Parameters:
    ///   - email: User's email
    ///   - password: User's password
    ///   - saveCredentials: Whether to save credentials to keychain
    func signIn(email: String, password: String, saveCredentials: Bool = false) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Validate email
                if !EmailValidator.isValid(email) {
                    throw NSError(domain: "", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "Please enter a valid email address"
                    ])
                }
                
                // Attempt sign in
                let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
                try await fetchUser(userId: authResult.user.uid)
                
                // Save credentials if requested
                if saveCredentials {
                    try KeychainHelper.shared.saveCredentials(email: email, password: password)
                }
                
                authState = .signedIn
                
            } catch {
                errorMessage = error.localizedDescription
                authState = .signedOut
            }
            isLoading = false
        }
    }
    
    /// Signs out the current user
    func signOut() {
        do {
            try Auth.auth().signOut()
            
            // Clear saved credentials
            try? KeychainHelper.shared.deleteCredentials()
            
            // Clear user data
            user = nil
            authState = .signedOut
            
            // Clear Remember Me if not enabled
            if !UserDefaults.standard.bool(forKey: "rememberMe") {
                UserDefaults.standard.removeObject(forKey: "savedEmail")
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Updates user data in Firestore
    /// - Parameter updatedUser: The updated user object
    func updateUser(_ updatedUser: User) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let data = updatedUser.toDictionary()
            try await db.collection("users").document(updatedUser.id).updateData(data)
            self.user = updatedUser
        } catch {
            errorMessage = "Failed to update user: \(error.localizedDescription)"
            throw error
        }
    }
    /// Signs up a new user
        func signUp(email: String, password: String, userData: [String: Any]) {
            isLoading = true
            errorMessage = nil
            
            print("Starting signup process for email: \(email)")
            print("User data structure: \(userData)")
            
            Task {
                do {
                    // 1. Create Firebase Auth user
                    print("Attempting to create Firebase Auth user...")
                    let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
                    let userId = authResult.user.uid
                    print("Successfully created Firebase Auth user with ID: \(userId)")
                    
                    // 2. Convert dates to Timestamps for Firestore
                    var firestoreData = userData
                    if let dateJoined = userData["dateJoined"] as? Date {
                        firestoreData["dateJoined"] = Timestamp(date: dateJoined)
                    }
                    if let dateOfBirth = userData["dateOfBirth"] as? Date {
                        firestoreData["dateOfBirth"] = Timestamp(date: dateOfBirth)
                    }
                    if let lastBetDate = userData["lastBetDate"] as? Date {
                        firestoreData["lastBetDate"] = Timestamp(date: lastBetDate)
                    }
                    
                    firestoreData["id"] = userId
                    firestoreData["email"] = email
                    
                    print("Attempting to create Firestore document...")
                    
                    // 3. Create Firestore document
                    try await db.collection("users").document(userId).setData(firestoreData)
                    print("Successfully created Firestore document")
                    
                    // 4. Fetch user data
                    print("Fetching user data...")
                    try await fetchUser(userId: userId)
                    print("Successfully fetched user data")
                    
                    await MainActor.run {
                        self.authState = .signedIn
                        self.isLoading = false
                    }
                } catch {
                    print("❌ Detailed error information:")
                    print("Error domain: \((error as NSError).domain)")
                    print("Error code: \((error as NSError).code)")
                    print("Error description: \(error.localizedDescription)")
                    print("Full error: \(error)")
                    
                    if let authError = error as? AuthErrorCode {
                        switch authError.code {
                        case .emailAlreadyInUse:
                            errorMessage = "This email is already registered. Please sign in or use a different email."
                        case .invalidEmail:
                            errorMessage = "Please enter a valid email address."
                        case .weakPassword:
                            errorMessage = "Password is too weak. Please choose a stronger password."
                        default:
                            errorMessage = error.localizedDescription
                        }
                    } else {
                        errorMessage = error.localizedDescription
                    }
                    
                    await MainActor.run {
                        self.authState = .signedOut
                        self.isLoading = false
                    }
                }
            }
        }
    // MARK: - Private Methods
    
    /// Checks current authentication state
    func checkAuthState() {
        print("🔍 Checking auth state...")
        authState = .loading
        
        // Brief delay to ensure Firebase is initialized
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let currentUser = Auth.auth().currentUser {
                print("👤 Found existing user: \(currentUser.uid)")
                Task {
                    do {
                        try await self.fetchUser(userId: currentUser.uid)
                        self.authState = .signedIn
                        print("✅ User authenticated successfully")
                    } catch {
                        print("❌ Error fetching user: \(error)")
                        self.authState = .signedOut
                    }
                }
            } else {
                print("👤 No existing user found")
                //
                //  AuthenticationViewModel.swift (continued)
                //  BettorOdds
                //
                //  Created by Claude on 1/31/25.
                //  Version: 2.1.0
                //

                                // Try to sign in with saved credentials if Remember Me is enabled
                                if UserDefaults.standard.bool(forKey: "rememberMe") {
                                    if let credentials = try? KeychainHelper.shared.loadCredentials() {
                                        Task {
                                            await self.signIn(
                                                email: credentials.email,
                                                password: credentials.password,
                                                saveCredentials: true
                                            )
                                        }
                                    } else {
                                        self.authState = .signedOut
                                    }
                                } else {
                                    self.authState = .signedOut
                                }
                            }
                        }
                    }
                    
                    /// Fetches user data from Firestore
                    /// - Parameter userId: The ID of the user to fetch
                    private func fetchUser(userId: String) async throws {
                        print("🔍 Fetching user data for ID: \(userId)")
                        let document = try await db.collection("users").document(userId).getDocument()
                        
                        // Debug: Print raw document data
                        if let data = document.data() {
                            print("📄 Raw user data:", data)
                            if let adminRole = data["adminRole"] as? String {
                                print("👑 Admin role found:", adminRole)
                            } else {
                                print("❌ No admin role found in user data")
                            }
                        }
                        
                        if let user = User(document: document) {
                            self.user = user
                            print("👤 User parsed successfully. Admin role:", user.adminRole.rawValue)
                        } else {
                            print("❌ Failed to parse user data")
                            throw NSError(domain: "", code: -1, userInfo: [
                                NSLocalizedDescriptionKey: "Failed to parse user data"
                            ])
                        }
                    }
                    
                    /// Attempts to restore the previous session
                    private func restoreSession() {
                        if let credentials = try? KeychainHelper.shared.loadCredentials(),
                           UserDefaults.standard.bool(forKey: "rememberMe") {
                            Task {
                                await signIn(
                                    email: credentials.email,
                                    password: credentials.password,
                                    saveCredentials: true
                                )
                            }
                        }
                    }
                    
                    /// Resets a user's password
                    /// - Parameter email: The email address to send the reset link to
                    func resetPassword(email: String) async throws {
                        guard EmailValidator.isValid(email) else {
                            throw NSError(domain: "", code: -1, userInfo: [
                                NSLocalizedDescriptionKey: "Please enter a valid email address"
                            ])
                        }
                        
                        try await Auth.auth().sendPasswordReset(withEmail: email)
                        

                    }
    deinit {
        resendTimer?.invalidate()
    }
}



// MARK: - Auth State Enum
enum AuthState {
    case signedIn
    case signedOut
    case loading
    case phoneVerification
    case pendingPhoneVerification
}
