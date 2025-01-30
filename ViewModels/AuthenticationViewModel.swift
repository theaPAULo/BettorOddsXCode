//
//  AuthenticationViewModel.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/26/25.
//  Version: 2.0.0
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine
import SwiftUI

/// Represents possible authentication states
enum AuthState {
    case signedIn
    case signedOut
    case loading
}

/// ViewModel handling all authentication-related operations
@MainActor
class AuthenticationViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var user: User?
    @Published var authState: AuthState = .loading
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let db = Firestore.firestore()
    
    // MARK: - Initialization
    init() {
        // Check for existing auth state
        checkAuthState()
    }
    
    // MARK: - Public Methods
    
    /// Signs in a user with email and password
    /// - Parameters:
    ///   - email: User's email
    ///   - password: User's password
    func signIn(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
                try await fetchUser(userId: authResult.user.uid)
                authState = .signedIn
            } catch {
                errorMessage = error.localizedDescription
                authState = .signedOut
            }
            isLoading = false
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
    
    /// Signs out the current user
    func signOut() {
        #if DEBUG
        user = nil
        authState = .signedOut
        #else
        do {
            try Auth.auth().signOut()
            user = nil
            authState = .signedOut
        } catch {
            errorMessage = error.localizedDescription
        }
        #endif
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
            errorMessage = "Failed to update user preferences: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    /// Fetches user data from Firestore
    /// - Parameter userId: The ID of the user to fetch
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
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse user data"])
            }
    }
    
    /// Checks current authentication state
    private func checkAuthState() {
        if let currentUser = Auth.auth().currentUser {
            Task {
                try? await fetchUser(userId: currentUser.uid)
                authState = .signedIn
            }
        } else {
            authState = .signedOut
        }
    }
    
    /// Sets up a test user for debug builds
    private func setupTestUser() {
        let testUser = User(
            id: "test-user-id",
            email: "test@email.com"
        )
        self.user = testUser
        self.authState = .signedIn
    }
}
