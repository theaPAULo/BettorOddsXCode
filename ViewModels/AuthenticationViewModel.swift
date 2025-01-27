//
//  AuthenticationViewModel.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/26/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

// Define the authentication states
enum AuthState {
    case signedIn
    case signedOut
    case loading
}

class AuthenticationViewModel: ObservableObject {
    @Published var user: User?
    @Published var authState: AuthState = .loading
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    init() {
        // TEMPORARY: Auto-login for testing
        let testUser = User(
            id: "test-user-id",
            email: "test@email.com"
        )
        self.user = testUser
        self.authState = .signedIn
    }
    
    func signIn(email: String, password: String) {
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.isLoading = false
            self?.user = User(id: "test-user-id", email: email)
            self?.authState = .signedIn
        }
    }
    
    func signUp(email: String, password: String, userData: [String: Any]) {
        isLoading = true
        errorMessage = nil
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.isLoading = false
            
            // Create a test user with the provided email
            let newUser = User(
                id: "test-user-id",
                email: email
            )
            
            self?.user = newUser
            self?.authState = .signedIn
        }
    }
    
    func signOut() {
        self.user = nil
        self.authState = .signedOut
    }
}
