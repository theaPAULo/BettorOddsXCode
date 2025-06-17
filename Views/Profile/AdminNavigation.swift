//
//  AdminNavigation.swift
//  BettorOdds
//
//  Version: 1.1.0 - FIXED: Use AuthenticationViewModel user instead of separate query
//  Updated: June 2025
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class AdminNavigation: ObservableObject {
    @Published var requiresAuth = false
    @Published var isAuthenticated = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    static let shared = AdminNavigation()
    
    /// Checks if admin features are accessible - FIXED VERSION
    func checkAdminAccess(user: User?) async {
        print("🔍 AdminNavigation: Checking admin access...")
        
        // FIXED: Use the user from AuthenticationViewModel instead of separate query
        guard let user = user else {
            print("❌ AdminNavigation: No user provided")
            await MainActor.run {
                requiresAuth = false
                isAuthenticated = false
            }
            return
        }
        
        print("🔍 AdminNavigation: User admin role = \(user.adminRole.rawValue)")
        
        // Check if user is admin
        if user.adminRole == .admin {
            print("✅ AdminNavigation: User is admin, checking session...")
            
            // Check if current session is valid
            if TwoFactorAuth.shared.verifyAdminSession() {
                print("✅ AdminNavigation: Valid admin session found")
                await MainActor.run {
                    isAuthenticated = true
                    requiresAuth = false
                }
            } else {
                print("⚠️ AdminNavigation: No valid session, requiring auth")
                await MainActor.run {
                    requiresAuth = true
                    isAuthenticated = false
                }
            }
        } else {
            print("❌ AdminNavigation: User is not admin (role: \(user.adminRole.rawValue))")
            await MainActor.run {
                requiresAuth = false
                isAuthenticated = false
            }
        }
    }
    
    /// Authenticates admin access
    func authenticateAdmin() async {
        print("🔐 AdminNavigation: Starting admin authentication...")
        
        do {
            let success = try await TwoFactorAuth.shared.authenticateAdmin()
            if success {
                TwoFactorAuth.shared.updateAdminSession()
                print("✅ AdminNavigation: Admin authentication successful")
                await MainActor.run {
                    isAuthenticated = true
                    requiresAuth = false
                }
            } else {
                print("❌ AdminNavigation: Admin authentication failed")
                await MainActor.run {
                    errorMessage = "Authentication failed"
                    showError = true
                }
            }
        } catch {
            print("❌ AdminNavigation: Admin authentication error: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    /// Logs out of admin session
    func logoutAdmin() {
        TwoFactorAuth.shared.clearAdminSession()
        isAuthenticated = false
        requiresAuth = true
        print("🔐 AdminNavigation: Admin logged out")
    }
}
