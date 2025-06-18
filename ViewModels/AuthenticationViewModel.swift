//
//  AuthenticationViewModel.swift - Orphaned Auth Fix
//  BettorOdds
//
//  Version: 3.3.0 - FIXED: Handles orphaned authentication (user in Auth but not Firestore)
//  Updated: June 2025
//  Changes:
//  - Added specific handling for orphaned auth states
//  - Enhanced user creation with detailed logging
//  - Direct Firestore user creation as fallback
//  - Manual user creation option
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
    case loading        // Initial app load / checking auth
    case signedIn       // User authenticated
    case signedOut      // User not authenticated
    case error(String)  // Error occurred
    case retrying       // Retrying failed operation
    case orphanedAuth   // User exists in Auth but not in Firestore
    
    var isSignedIn: Bool {
        if case .signedIn = self { return true }
        return false
    }
    
    var isLoading: Bool {
        switch self {
        case .loading, .retrying:
            return true
        default:
            return false
        }
    }
}

@MainActor
class AuthenticationViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var user: User?
    @Published var authState: AuthState = .loading
    @Published var isLoading = false  // For individual operations (sign in/out)
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var retryCount = 0
    @Published var orphanedFirebaseUser: FirebaseAuth.User?
    
    // MARK: - Dependencies (Using Dependency Injection)
    @Inject private var userRepository: UserRepository
    
    // MARK: - Private Properties
    private let auth = Auth.auth()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var appleSignInCoordinator: AppleSignInCoordinator?
    private var isInitialized = false
    private let maxRetries = 3
    private let db = Firestore.firestore()
    
    // MARK: - Initialization
    init() {
        print("🔐 AuthenticationViewModel initialized")
        
        // SAFETY: Delay actual setup to ensure DI container is ready
        Task {
            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
            await initializeAfterDI()
        }
    }
    
    deinit {
        if let listener = authStateListener {
            auth.removeStateDidChangeListener(listener)
        }
        print("🗑️ AuthenticationViewModel deinitialized")
    }
    
    // MARK: - Private Initialization
    
    /// Initialize after DI container is ready
    private func initializeAfterDI() async {
        guard !isInitialized else { return }
        
        await MainActor.run {
            setupAuthStateListener()
            isInitialized = true
            print("✅ AuthenticationViewModel fully initialized")
        }
    }
    
    // MARK: - Public Methods
    
    /// Checks current authentication state
    func checkAuthState() async {
        // SAFETY: Don't proceed if not properly initialized
        guard isInitialized else {
            print("⚠️ AuthenticationViewModel not yet initialized, delaying checkAuthState")
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            await checkAuthState()
            return
        }
        
        print("🔐 Checking authentication state...")
        
        guard let firebaseUser = auth.currentUser else {
            print("🔐 No authenticated user found")
            authState = .signedOut
            user = nil
            return
        }
        
        print("🔐 Found authenticated user: \(firebaseUser.uid)")
        
        // Load user data with specific orphaned auth handling
        await handleAuthenticatedUser(firebaseUser: firebaseUser)
    }
    
    /// ENHANCED: Handle authenticated user with orphaned auth detection
    private func handleAuthenticatedUser(firebaseUser: FirebaseAuth.User) async {
        do {
            print("📱 Attempting to load user data for: \(firebaseUser.uid)")
            
            // Try to fetch existing user
            if let existingUser = try await userRepository.fetch(id: firebaseUser.uid) {
                print("✅ Found existing user in Firestore: \(existingUser.displayName ?? "Unknown")")
                
                // Update user with latest Firebase info
                var updatedUser = existingUser
                updatedUser.displayName = firebaseUser.displayName
                updatedUser.profileImageURL = firebaseUser.photoURL?.absoluteString
                
                user = updatedUser
                authState = .signedIn
                
                // Update in repository if needed
                if updatedUser.displayName != existingUser.displayName ||
                   updatedUser.profileImageURL != existingUser.profileImageURL {
                    try await userRepository.save(updatedUser)
                    print("📝 Updated user profile with latest Firebase data")
                }
                
            } else {
                print("❌ User document not found in Firestore - creating new user")
                await handleOrphanedAuth(firebaseUser: firebaseUser)
            }
            
        } catch {
            print("❌ Error in handleAuthenticatedUser: \(error.localizedDescription)")
            await handleOrphanedAuth(firebaseUser: firebaseUser)
        }
    }
    
    /// ENHANCED: Handle orphaned authentication (user in Auth but not in Firestore)
    private func handleOrphanedAuth(firebaseUser: FirebaseAuth.User) async {
        print("🚨 Detected orphaned authentication - user exists in Auth but not in Firestore")
        
        // Store the Firebase user for recovery
        orphanedFirebaseUser = firebaseUser
        
        // Try to create user document directly in Firestore
        await attemptDirectUserCreation(firebaseUser: firebaseUser)
    }
    
    /// ENHANCED: Attempt direct user creation in Firestore
    private func attemptDirectUserCreation(firebaseUser: FirebaseAuth.User) async {
        print("🛠️ Attempting direct user creation in Firestore...")
        
        do {
            // Create user object
            let newUser = User(
                id: firebaseUser.uid,
                displayName: firebaseUser.displayName ?? "User",
                profileImageURL: firebaseUser.photoURL?.absoluteString,
                authProvider: getAuthProvider(firebaseUser)
            )
            
            print("📝 Creating user document: \(newUser.id)")
            print("📧 Email: \(firebaseUser.email ?? "No email")")
            print("👤 Display name: \(newUser.displayName)")
            print("🔗 Auth provider: \(newUser.authProvider)")
            
            // Try direct Firestore creation
            let userDocument = db.collection("users").document(firebaseUser.uid)
            try await userDocument.setData(newUser.toDictionary())
            
            print("✅ Successfully created user document directly in Firestore")
            
            // Set user and transition to signed in
            user = newUser
            authState = .signedIn
            orphanedFirebaseUser = nil
            
        } catch {
            print("❌ Direct user creation failed: \(error.localizedDescription)")
            
            // Show orphaned auth state for manual recovery
            await MainActor.run {
                self.authState = .orphanedAuth
                self.errorMessage = """
                Your account exists but your profile is missing.
                
                Error: \(error.localizedDescription)
                
                This can happen due to network issues during initial setup.
                """
            }
        }
    }
    
    /// ENHANCED: Manual user creation for orphaned auth recovery
    func createOrphanedUserProfile() async {
        guard let firebaseUser = orphanedFirebaseUser else {
            print("❌ No orphaned Firebase user found")
            return
        }
        
        print("🔧 Manual orphaned user profile creation requested")
        authState = .loading
        
        await attemptDirectUserCreation(firebaseUser: firebaseUser)
    }
    
    /// ENHANCED: Force clean sign out for orphaned auth recovery
    func forceCleanSignOut() async {
        print("🚨 Force clean sign out requested for orphaned auth")
        
        do {
            // Sign out from Firebase Auth
            try auth.signOut()
            
            // Clear all state
            user = nil
            authState = .signedOut
            errorMessage = nil
            showError = false
            retryCount = 0
            orphanedFirebaseUser = nil
            
            clearUserSession()
            print("✅ Force clean sign out completed")
            
        } catch {
            print("❌ Force sign out failed: \(error.localizedDescription)")
            // Even if sign out fails, reset to signed out state
            authState = .signedOut
            user = nil
            orphanedFirebaseUser = nil
        }
    }
    
    /// Signs in with Google
    func signInWithGoogle() {
        guard isInitialized else {
            handleError("Authentication system not ready. Please try again.", context: "Google Sign-In")
            return
        }
        
        guard !isLoading else {
            print("⚠️ Sign-in already in progress")
            return
        }
        
        setOperationLoading(true, message: "Signing in with Google...")
        
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
        guard isInitialized else {
            handleError("Authentication system not ready. Please try again.", context: "Apple Sign-In")
            return
        }
        
        guard !isLoading else {
            print("⚠️ Sign-in already in progress")
            return
        }
        
        setOperationLoading(true, message: "Signing in with Apple...")
        
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
        guard isInitialized else {
            handleError("Authentication system not ready. Please try again.", context: "Sign Out")
            return
        }
        
        guard !isLoading else {
            print("⚠️ Sign-out already in progress")
            return
        }
        
        setOperationLoading(true, message: "Signing out...")
        
        Task {
            do {
                try auth.signOut()
                
                // Clear user data
                user = nil
                authState = .signedOut
                retryCount = 0
                orphanedFirebaseUser = nil
                
                // Clear any cached data
                clearUserSession()
                
                print("✅ User signed out successfully")
                setOperationLoading(false)
                
            } catch {
                await handleAuthError(error, context: "Sign Out")
            }
        }
    }
    
    /// Updates user data in repository
    func updateUser(_ updatedUser: User) async {
        guard isInitialized else {
            handleError("Authentication system not ready. Please try again.", context: "Update User")
            return
        }
        
        guard user?.id == updatedUser.id else {
            handleError("Cannot update user - ID mismatch", context: "Update User")
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
        guard isInitialized else {
            handleError("Authentication system not ready. Please try again.", context: "Delete Account")
            return
        }
        
        guard let currentUser = auth.currentUser,
              let user = user else {
            await handleAuthError(AppError.userNotFound, context: "Delete Account")
            return
        }
        
        setOperationLoading(true, message: "Deleting account...")
        
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
            setOperationLoading(false)
            
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
                        // Don't set to loading here if we're already signed in
                        if self?.authState != .signedIn {
                            self?.authState = .loading
                        }
                        Task {
                            await self?.handleAuthenticatedUser(firebaseUser: firebaseUser)
                        }
                    } else {
                        print("🔐 Auth state changed: User signed out")
                        self?.authState = .signedOut
                        self?.user = nil
                        self?.retryCount = 0
                        self?.orphanedFirebaseUser = nil
                    }
                }
            }
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
        
        await handleAuthenticatedUser(firebaseUser: firebaseUser)
    }
    
    /// Handles authentication errors
    private func handleAuthError(_ error: Error, context: String) async {
        print("❌ \(context) error: \(error.localizedDescription)")
        
        await MainActor.run {
            self.errorMessage = error.localizedDescription
            self.showError = true
            // Don't set authState to error unless it's a critical auth issue
            // For operation errors, keep current state but stop loading
            self.setOperationLoading(false)
        }
    }
    
    /// Handle errors without async context
    private func handleError(_ message: String, context: String) {
        print("❌ \(context) error: \(message)")
        self.errorMessage = message
        self.showError = true
        self.setOperationLoading(false)
    }
    
    /// Gets auth provider from Firebase user
    private func getAuthProvider(_ firebaseUser: FirebaseAuth.User) -> String {
        if let providerData = firebaseUser.providerData.first {
            return providerData.providerID
        }
        return "unknown"
    }
    
    /// Sets loading state for individual operations (not app-level auth state)
    private func setOperationLoading(_ loading: Bool, message: String? = nil) {
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
                    completion(.success(result))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
    
    // MARK: - ASAuthorizationControllerPresentationContextProviding
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first { $0.isKeyWindow } ?? UIWindow()
    }
    
    // MARK: - Helper Methods
    
    private func randomNonceString(length: Int = 32) -> String {
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
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}
