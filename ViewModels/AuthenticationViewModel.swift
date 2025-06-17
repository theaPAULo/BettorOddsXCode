//
//  AuthenticationViewModel.swift
//  BettorOdds
//
//  Version: 3.0.0 - Optimized with Dependency Injection and better error handling
//  Updated: June 2025
//

import Foundation
import SwiftUI
import FirebaseCore
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
    case error(String)
    
    var isSignedIn: Bool {
        if case .signedIn = self { return true }
        return false
    }
}

@MainActor
class AuthenticationViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var user: User?
    @Published var authState: AuthState = .loading
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // MARK: - Dependencies (Using Dependency Injection)
    @Inject private var userRepository: UserRepository
    
    // MARK: - Private Properties
    private let auth = Auth.auth()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var appleSignInCoordinator: AppleSignInCoordinator?
    
    // MARK: - Initialization
    init() {
        print("🔐 AuthenticationViewModel initialized with DI")
        setupAuthStateListener()
        checkAuthState()
    }
    
    deinit {
        if let listener = authStateListener {
            auth.removeStateDidChangeListener(listener)
        }
        print("🗑️ AuthenticationViewModel deinitialized")
    }
    
    // MARK: - Public Methods
    
    /// Checks current authentication state
    func checkAuthState() {
        guard let firebaseUser = auth.currentUser else {
            print("🔐 No authenticated user found")
            authState = .signedOut
            user = nil
            return
        }
        
        print("🔐 Found authenticated user: \(firebaseUser.uid)")
        authState = .loading
        
        Task {
            await loadUserData(firebaseUser: firebaseUser)
        }
    }
    
    /// Signs in with Google
    func signInWithGoogle() {
        setLoading(true, message: "Signing in with Google...")
        
        Task {
            do {
                let result = try await performGoogleSignIn()
                await handleSuccessfulAuth(result.user, isNewUser: result.additionalUserInfo?.isNewUser ?? false)
            } catch {
                await handleAuthError(error, context: "Google Sign-In")
            }
        }
    }
    
    /// Signs in with Apple
    func signInWithApple() {
        setLoading(true, message: "Signing in with Apple...")
        
        appleSignInCoordinator = AppleSignInCoordinator { [weak self] result in
            Task { [weak self] in
                switch result {
                case .success(let authResult):
                    await self?.handleSuccessfulAuth(authResult.user, isNewUser: authResult.additionalUserInfo?.isNewUser ?? false)
                case .failure(let error):
                    await self?.handleAuthError(error, context: "Apple Sign-In")
                }
            }
        }
        
        appleSignInCoordinator?.startSignInWithAppleFlow()
    }
    
    /// Signs out the current user
    func signOut() {
        setLoading(true, message: "Signing out...")
        
        Task {
            do {
                try auth.signOut()
                
                // Clear user data
                user = nil
                authState = .signedOut
                
                // Clear any cached data
                clearUserSession()
                
                print("✅ User signed out successfully")
                setLoading(false)
                
            } catch {
                await handleAuthError(error, context: "Sign Out")
            }
        }
    }
    
    /// Updates user data in repository
    func updateUser(_ updatedUser: User) async {
        guard user?.id == updatedUser.id else {
            print("❌ Cannot update user - ID mismatch")
            return
        }
        
        do {
            try await userRepository.save(updatedUser)
            user = updatedUser
            print("✅ User updated successfully")
        } catch {
            await handleAuthError(error, context: "Update User")
        }
    }
    
    /// Deletes user account
    func deleteAccount() async {
        guard let currentUser = auth.currentUser,
              let user = user else {
            await handleAuthError(AppError.userNotFound, context: "Delete Account")
            return
        }
        
        setLoading(true, message: "Deleting account...")
        
        do {
            // Delete user data from Firestore
            try await userRepository.remove(id: user.id)
            
            // Delete Firebase Auth user
            try await currentUser.delete()
            
            // Clear local state
            self.user = nil
            authState = .signedOut
            clearUserSession()
            
            print("✅ Account deleted successfully")
            setLoading(false)
            
        } catch {
            await handleAuthError(error, context: "Delete Account")
        }
    }
    
    // MARK: - Private Methods
    
    /// Sets up auth state listener
    private func setupAuthStateListener() {
        authStateListener = auth.addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { [weak self] in
                await MainActor.run {
                    if let firebaseUser = firebaseUser {
                        print("🔐 Auth state changed: User signed in")
                        self?.authState = .loading
                        Task {
                            await self?.loadUserData(firebaseUser: firebaseUser)
                        }
                    } else {
                        print("🔐 Auth state changed: User signed out")
                        self?.authState = .signedOut
                        self?.user = nil
                    }
                }
            }
        }
    }
    
    /// Loads user data from repository
    private func loadUserData(firebaseUser: FirebaseAuth.User) async {
        do {
            if let existingUser = try await userRepository.fetch(id: firebaseUser.uid) {
                // Update user with latest Firebase info
                var updatedUser = existingUser
                updatedUser.displayName = firebaseUser.displayName
                updatedUser.profileImageURL = firebaseUser.photoURL?.absoluteString
                
                user = updatedUser
                authState = .signedIn
                print("✅ Existing user loaded: \(existingUser.displayName ?? "Unknown")")
                
                // Update in repository if needed
                if updatedUser.displayName != existingUser.displayName ||
                   updatedUser.profileImageURL != existingUser.profileImageURL {
                    try await userRepository.save(updatedUser)
                }
                
            } else {
                // Create new user
                let newUser = User(
                    id: firebaseUser.uid,
                    displayName: firebaseUser.displayName,
                    profileImageURL: firebaseUser.photoURL?.absoluteString,
                    authProvider: getAuthProvider(firebaseUser)
                )
                
                try await userRepository.save(newUser)
                user = newUser
                authState = .signedIn
                print("✅ New user created: \(newUser.displayName ?? "Unknown")")
            }
            
            setLoading(false)
            
        } catch {
            await handleAuthError(error, context: "Load User Data")
        }
    }
    
    /// Performs Google Sign-In
    private func performGoogleSignIn() async throws -> AuthDataResult {
        // Get the root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw AppError.authProviderError("Cannot find root view controller")
        }
        
        // Configure Google Sign-In
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AppError.authProviderError("Firebase client ID not found")
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Perform Google Sign-In
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        
        guard let idToken = result.user.idToken?.tokenString else {
            throw AppError.authProviderError("Failed to get ID token")
        }
        
        let accessToken = result.user.accessToken.tokenString
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        // Sign in to Firebase
        let authResult = try await auth.signIn(with: credential)
        
        return authResult
    }
    
    /// Handles successful authentication
    private func handleSuccessfulAuth(_ firebaseUser: FirebaseAuth.User, isNewUser: Bool) async {
        print("✅ Authentication successful for: \(firebaseUser.displayName ?? "Unknown")")
        
        if isNewUser {
            print("🎉 New user detected - will create user profile")
        }
        
        await loadUserData(firebaseUser: firebaseUser)
    }
    
    /// Handles authentication errors
    private func handleAuthError(_ error: Error, context: String) async {
        print("❌ \(context) error: \(error.localizedDescription)")
        
        await MainActor.run {
            self.errorMessage = error.localizedDescription
            self.showError = true
            self.authState = .error(error.localizedDescription)
            self.setLoading(false)
        }
    }
    
    /// Gets auth provider from Firebase user
    private func getAuthProvider(_ firebaseUser: FirebaseAuth.User) -> String {
        if let providerData = firebaseUser.providerData.first {
            return providerData.providerID
        }
        return "unknown"
    }
    
    /// Sets loading state with optional message
    private func setLoading(_ loading: Bool, message: String? = nil) {
        isLoading = loading
        if let message = message {
            print("🔄 \(message)")
        }
    }
    
    /// Clears user session data
    private func clearUserSession() {
        // Clear any cached data, preferences, etc.
        UserDefaults.standard.removeObject(forKey: "lastAdminAuth")
        
        // You can add more session cleanup here
        print("🧹 User session cleared")
    }
    
    // MARK: - Admin Helper Methods
    
    /// Checks if current user is admin
    var isAdmin: Bool {
        return user?.adminRole == .admin
    }
    
    /// Checks if current user can access admin features
    var canAccessAdmin: Bool {
        return isAdmin && authState.isSignedIn
    }
    
    /// Gets user's admin capabilities
    var adminCapabilities: AdminCapabilities? {
        guard let user = user, user.adminRole == .admin else { return nil }
        
        return AdminCapabilities(
            canManageUsers: user.adminRole.canManageUsers,
            canManageBets: user.adminRole.canManageBets,
            canViewAnalytics: user.adminRole.canViewAnalytics,
            canConfigureSystem: user.adminRole.canConfigureSystem
        )
    }
}

// MARK: - Admin Capabilities Model

struct AdminCapabilities {
    let canManageUsers: Bool
    let canManageBets: Bool
    let canViewAnalytics: Bool
    let canConfigureSystem: Bool
    
    var hasAnyCapability: Bool {
        return canManageUsers || canManageBets || canViewAnalytics || canConfigureSystem
    }
}

// MARK: - Apple Sign-In Coordinator

class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    private let completion: (Result<AuthDataResult, Error>) -> Void
    private var currentNonce: String?
    
    init(completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        self.completion = completion
        super.init()
    }
    
    func startSignInWithAppleFlow() {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    // MARK: - ASAuthorizationControllerDelegate
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                completion(.failure(AppError.authProviderError("Invalid state: A login callback was received, but no login request was sent.")))
                return
            }
            
            guard let appleIDToken = appleIDCredential.identityToken else {
                completion(.failure(AppError.authProviderError("Unable to fetch identity token")))
                return
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                completion(.failure(AppError.authProviderError("Unable to serialize token string from data")))
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                    idToken: idTokenString,
                                                    rawNonce: nonce)
            
            Task {
                do {
                    let result = try await Auth.auth().signIn(with: credential)
                    self.completion(.success(result))
                } catch {
                    self.completion(.failure(error))
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
    
    // MARK: - ASAuthorizationControllerPresentationContextProviding
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIWindow()
        }
        return window
    }
    
    // MARK: - Helper Methods
    
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
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}
