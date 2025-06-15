//
//  AuthenticationViewModel.swift
//  BettorOdds
//
//  Version: 2.7.1 - Fixed GIDConfiguration optional binding issue
//  Updated: June 2025
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import AuthenticationServices
import CryptoKit

// MARK: - Authentication State
enum AuthState: Equatable {
    case loading
    case signedIn
    case signedOut
}

@MainActor
class AuthenticationViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var user: User?
    @Published var authState: AuthState = .loading
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let db = Firestore.firestore()
    
    // Keep reference to Apple Sign-In coordinator
    private var appleSignInCoordinator: AppleSignInCoordinator?
    
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
        
        // Get Google Client ID
        guard let clientID = getGoogleClientID() else {
            errorMessage = "Google configuration not found"
            isLoading = false
            return
        }
        
        // FIXED: GIDConfiguration initializer doesn't return optional
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Sign in
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            Task { @MainActor in
                if let error = error {
                    self?.errorMessage = "Google Sign-In failed: \(error.localizedDescription)"
                    self?.isLoading = false
                    return
                }
                
                guard let result = result,
                      let idToken = result.user.idToken?.tokenString else {
                    self?.errorMessage = "Failed to get ID token from Google"
                    self?.isLoading = false
                    return
                }
                
                let accessToken = result.user.accessToken.tokenString
                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
                
                // Sign in to Firebase
                await self?.signInToFirebase(with: credential, authProvider: "google.com")
            }
        }
    }
    
    // MARK: - Apple Sign-In
    
    /// Signs in with Apple
    func signInWithApple() {
        isLoading = true
        errorMessage = nil
        
        appleSignInCoordinator = AppleSignInCoordinator { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let credential):
                    await self?.signInWithAppleCredential(credential)
                case .failure(let error):
                    self?.errorMessage = "Apple Sign-In failed: \(error.localizedDescription)"
                    self?.isLoading = false
                }
            }
        }
        
        appleSignInCoordinator?.signIn()
    }
    
    // MARK: - Apple Sign-In Helper Methods
    
    private func signInWithAppleCredential(_ credential: ASAuthorizationAppleIDCredential) async {
        guard let idToken = credential.identityToken,
              let idTokenString = String(data: idToken, encoding: .utf8) else {
            await MainActor.run {
                self.errorMessage = "Failed to get ID token from Apple"
                self.isLoading = false
            }
            return
        }
        
        // Generate nonce for security
        let rawNonce = generateNonce()
        
        // FIXED: Use the new credential method instead of deprecated one
        let oauthCredential = OAuthProvider.credential(
            providerID: AuthProviderID.apple,
            idToken: idTokenString,
            rawNonce: rawNonce,
            accessToken: nil
        )
        
        await signInToFirebase(with: oauthCredential, authProvider: "apple.com")
    }
    
    // MARK: - Firebase Authentication
    
    /// Signs in to Firebase with the provided credential
    private func signInToFirebase(with credential: AuthCredential, authProvider: String) async {
        do {
            let result = try await Auth.auth().signIn(with: credential)
            
            // Check if user exists in Firestore
            let userDoc = try await db.collection("users").document(result.user.uid).getDocument()
            
            if userDoc.exists {
                // Existing user - fetch their data
                print("👤 Existing user found")
                try await fetchUser(userId: result.user.uid)
            } else {
                // New user - create their profile
                print("👤 New user - creating profile")
                try await createNewUser(firebaseUser: result.user, authProvider: authProvider)
            }
            
            authState = .signedIn
            isLoading = false
            print("✅ Authentication flow completed successfully")
        } catch {
            errorMessage = "Authentication failed: \(error.localizedDescription)"
            isLoading = false
            print("❌ Authentication error: \(error)")
        }
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
                        await MainActor.run {
                            self.authState = .signedIn
                        }
                        print("✅ User authenticated successfully")
                    } catch {
                        print("❌ Error fetching user: \(error)")
                        await MainActor.run {
                            self.authState = .signedOut
                        }
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
            return nil
        }
        return clientId
    }
    
    // Helper method to generate secure nonce
    private func generateNonce(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
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
    
    // Helper method for SHA256 hashing
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }
    
    // Helper method to extract name from Apple credential
    private func extractNameFromAppleCredential(_ credential: ASAuthorizationAppleIDCredential) -> String {
        if let fullName = credential.fullName {
            let firstName = fullName.givenName ?? ""
            let lastName = fullName.familyName ?? ""
            return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return "Apple User"
    }
}

// MARK: - Apple Sign-In Coordinator

class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var completion: (Result<ASAuthorizationAppleIDCredential, Error>) -> Void
    
    init(completion: @escaping (Result<ASAuthorizationAppleIDCredential, Error>) -> Void) {
        self.completion = completion
        super.init()
    }
    
    func signIn() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    // MARK: - ASAuthorizationControllerDelegate
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            completion(.success(appleIDCredential))
        } else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid credential type"])))
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
    
    // MARK: - ASAuthorizationControllerPresentationContextProviding
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("Unable to find presentation anchor")
        }
        return window
    }
}
