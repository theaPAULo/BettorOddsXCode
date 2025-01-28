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
        #if DEBUG
        // TEMPORARY: Auto-login for testing
        setupTestUser()
        #else
        // In production, check for existing auth state
        checkAuthState()
        #endif
    }
    
    // MARK: - Public Methods
    
    /// Signs in a user with email and password
    /// - Parameters:
    ///   - email: User's email
    ///   - password: User's password
    func signIn(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        #if DEBUG
        // Simulate network delay in debug
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.isLoading = false
            self?.user = User(id: "test-user-id", email: email)
            self?.authState = .signedIn
        }
        #else
        // Actual Firebase authentication
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
        #endif
    }
    
    /// Signs up a new user
    /// - Parameters:
    ///   - email: User's email
    ///   - password: User's password
    ///   - userData: Additional user data
    func signUp(email: String, password: String, userData: [String: Any]) {
        isLoading = true
        errorMessage = nil
        
        #if DEBUG
        // Simulate network delay in debug
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.isLoading = false
            self?.user = User(id: "test-user-id", email: email)
            self?.authState = .signedIn
        }
        #else
        // Actual Firebase authentication and user creation
        Task {
            do {
                let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
                let userId = authResult.user.uid
                
                // Create user document in Firestore
                var userDoc = userData
                userDoc["id"] = userId
                userDoc["email"] = email
                
                try await db.collection("users").document(userId).setData(userDoc)
                try await fetchUser(userId: userId)
                authState = .signedIn
            } catch {
                errorMessage = error.localizedDescription
                authState = .signedOut
            }
            isLoading = false
        }
        #endif
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
    private func fetchUser(userId: String) async throws {
        let document = try await db.collection("users").document(userId).getDocument()
        if let user = User(document: document) {
            self.user = user
        } else {
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
