//
//  AuthenticationViewModel.swift
//  BettorOdds
//
//  Created by Claude on 1/31/25.
//  Version: 3.0.0 - Completely rewritten for Google/Apple Sign-In
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import AuthenticationServices
import SwiftUI

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
        checkAuthState()
    }
    
    // MARK: - Google Sign-In
    
    /// Signs in with Google
    func signInWithGoogle() {
        isLoading = true
        errorMessage = nil
        
        // Get the root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Unable to find root view controller"
            isLoading = false
            return
        }
        
        // Configure Google Sign-In
        guard let clientID = getGoogleClientID() else {
            errorMessage = "Google Sign-In configuration error"
            isLoading = false
            return
        }
        
        // Create Google Sign-In configuration
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Start the sign-in flow
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "Google Sign-In failed: \(error.localizedDescription)"
                    self.isLoading = false
                    return
                }
                
                guard let user = result?.user,
                      let idToken = user.idToken?.tokenString else {
                    self.errorMessage = "Failed to get Google user information"
                    self.isLoading = false
                    return
                }
                
                // Create Firebase credential
                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: user.accessToken.tokenString
                )
                
                // Sign in to Firebase
                do {
                    let authResult = try await Auth.auth().signIn(with: credential)
                    try await self.handleAuthenticationSuccess(
                        firebaseUser: authResult.user,
                        authProvider: "google.com"
                    )
                } catch {
                    self.errorMessage = "Firebase authentication failed: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Apple Sign-In
    
    /// Signs in with Apple
    func signInWithApple() {
        isLoading = true
        errorMessage = nil
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        
        // Create a coordinator to handle the Apple Sign-In flow
        let coordinator = AppleSignInCoordinator { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                
                switch result {
                case .success(let authResult):
                    do {
                        try await self.handleAuthenticationSuccess(
                            firebaseUser: authResult,
                            authProvider: "apple.com"
                        )
                    } catch {
                        self.errorMessage = "Firebase authentication failed: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                    
                case .failure(let error):
                    self.errorMessage = "Apple Sign-In failed: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
        
        authorizationController.delegate = coordinator
        authorizationController.presentationContextProvider = coordinator
        authorizationController.performRequests()
        
        // Keep coordinator alive
        self.appleSignInCoordinator = coordinator
    }
    
    // Keep reference to coordinator
    private var appleSignInCoordinator: AppleSignInCoordinator?
    
    // MARK: - Common Authentication Handling
    
    /// Handles successful authentication from either provider
    private func handleAuthenticationSuccess(firebaseUser: FirebaseAuth.User, authProvider: String) async throws {
        print("🔐 Authentication successful with provider: \(authProvider)")
        print("🆔 User ID: \(firebaseUser.uid)")
        
        // Check if user already exists in Firestore
        let userDoc = try await db.collection("users").document(firebaseUser.uid).getDocument()
        
        if userDoc.exists {
            // Existing user - fetch their data
            print("👤 Existing user found")
            try await fetchUser(userId: firebaseUser.uid)
        } else {
            // New user - create their profile
            print("👤 New user - creating profile")
            try await createNewUser(firebaseUser: firebaseUser, authProvider: authProvider)
        }
        
        authState = .signedIn
        isLoading = false
        print("✅ Authentication flow completed successfully")
    }
    
    /// Creates a new user profile in Firestore
    private func createNewUser(firebaseUser: FirebaseAuth.User, authProvider: String) async throws {
        let newUser = User(
            id: firebaseUser.uid,
            displayName: firebaseUser.displayName,
            profileImageURL: firebaseUser.photoURL?.absoluteString,
            authProvider: authProvider
        )
        
        // Save to Firestore
        try await db.collection("users").document(firebaseUser.uid).setData(newUser.toDictionary())
        
        // Set local user
        self.user = newUser
        
        print("✅ New user profile created successfully")
    }
    
    // MARK: - User Management
    
    /// Fetches user data from Firestore
    private func fetchUser(userId: String) async throws {
        print("🔍 Fetching user data for ID: \(userId)")
        let document = try await db.collection("users").document(userId).getDocument()
        
        if let user = User(document: document) {
            self.user = user
            print("👤 User data fetched successfully")
        } else {
            print("❌ Failed to parse user data")
            throw NSError(domain: "", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to parse user data"
            ])
        }
    }
    
    /// Updates user data in Firestore
    func updateUser(_ updatedUser: User) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let data = updatedUser.toDictionary()
            try await db.collection("users").document(updatedUser.id).updateData(data)
            self.user = updatedUser
            print("✅ User data updated successfully")
        } catch {
            errorMessage = "Failed to update user: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Sign Out
    
    /// Signs out the current user
    func signOut() {
        do {
            // Sign out from Firebase
            try Auth.auth().signOut()
            
            // Sign out from Google if needed
            GIDSignIn.sharedInstance.signOut()
            
            // Clear local user data
            user = nil
            authState = .signedOut
            errorMessage = nil
            
            print("✅ User signed out successfully")
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Sign out error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Authentication State Management
    
    /// Checks current authentication state
    func checkAuthState() {
        print("🔍 Checking authentication state...")
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
                self.authState = .signedOut
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Gets Google Client ID from GoogleService-Info.plist
    private func getGoogleClientID() -> String? {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            print("❌ Failed to get Google Client ID from GoogleService-Info.plist")
            return nil
        }
        return clientId
    }
}

// MARK: - Apple Sign-In Coordinator

class AppleSignInCoordinator: NSObject {
    private let completion: (Result<FirebaseAuth.User, Error>) -> Void
    
    init(completion: @escaping (Result<FirebaseAuth.User, Error>) -> Void) {
        self.completion = completion
        super.init()
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            completion(.failure(NSError(domain: "AppleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Apple ID credential"])))
            return
        }
        
        guard let nonce = currentNonce,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            completion(.failure(NSError(domain: "AppleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identity token"])))
            return
        }
        
        // Create Firebase credential
        let credential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: idTokenString,
            rawNonce: nonce
        )
        
        // Sign in with Firebase
        Task {
            do {
                let authResult = try await Auth.auth().signIn(with: credential)
                completion(.success(authResult.user))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
    
    // Generate nonce for Apple Sign-In security
    private var currentNonce: String? {
        return randomNonceString()
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}

// MARK: - Auth State Enum
enum AuthState {
    case signedIn
    case signedOut
    case loading
}
