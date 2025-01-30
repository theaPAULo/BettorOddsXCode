// File: Models/User.swift
// Version: 1.0
// Description: Core user model for the BettorOdds app

import Foundation
import FirebaseFirestore

// MARK: - Admin Role Enum
enum AdminRole: String, Codable {
    case none = "none"
    case admin = "admin"
    
    var canManageUsers: Bool { self == .admin }
    var canManageBets: Bool { self == .admin }
    var canViewAnalytics: Bool { self == .admin }
    var canConfigureSystem: Bool { self == .admin }
}

struct User: Identifiable, Codable {
    var id: String
    var email: String
    var dateJoined: Date
    var yellowCoins: Int
    var greenCoins: Int
    var dailyGreenCoinsUsed: Int
    var isPremium: Bool
    var lastBetDate: Date?
    var preferences: UserPreferences
    var adminRole: AdminRole = .none
    var isEmailVerified: Bool = false
    var lastAdminAction: Date?
    
    // Computed property for remaining daily limit
    var remainingDailyGreenCoins: Int {
        let dailyLimit = 100
        return max(0, dailyLimit - dailyGreenCoinsUsed)
    }
    
    // Default initializer
    init(id: String, email: String) {
        self.id = id
        self.email = email
        self.dateJoined = Date()
        self.yellowCoins = 100  // Starting bonus
        self.greenCoins = 0
        self.dailyGreenCoinsUsed = 0
        self.isPremium = false
        self.lastBetDate = Date()
        self.preferences = UserPreferences()
    }
    
    // Initialize from Firestore document
    init?(document: DocumentSnapshot) {
            guard let data = document.data() else { return nil }
            
            self.id = document.documentID
            self.email = data["email"] as? String ?? ""
            self.dateJoined = (data["dateJoined"] as? Timestamp)?.dateValue() ?? Date()
            self.yellowCoins = data["yellowCoins"] as? Int ?? 0
            self.greenCoins = data["greenCoins"] as? Int ?? 0
            self.dailyGreenCoinsUsed = data["dailyGreenCoinsUsed"] as? Int ?? 0
            self.isPremium = data["isPremium"] as? Bool ?? false
            self.lastBetDate = (data["lastBetDate"] as? Timestamp)?.dateValue() ?? Date()
            
            // Parse admin role
        if let adminRoleString = data["adminRole"] as? String {
            self.adminRole = AdminRole(rawValue: adminRoleString) ?? .none
            print("📱 Parsed admin role from Firestore: \(adminRoleString) -> \(self.adminRole)")
        }
        // Handle preferences
        if let prefsData = data["preferences"] as? [String: Any] {
            self.preferences = UserPreferences(
                useBiometrics: prefsData["useBiometrics"] as? Bool ?? false,
                darkMode: prefsData["darkMode"] as? Bool ?? false,
                notificationsEnabled: prefsData["notificationsEnabled"] as? Bool ?? true,
                requireBiometricsForGreenCoins: prefsData["requireBiometricsForGreenCoins"] as? Bool ?? true
            )
        } else {
            self.preferences = UserPreferences()
        }
    }
    
    // Convert to dictionary for Firestore
    func toDictionary() -> [String: Any] {
        return [
            "email": email,
            "dateJoined": dateJoined,
            "yellowCoins": yellowCoins,
            "greenCoins": greenCoins,
            "dailyGreenCoinsUsed": dailyGreenCoinsUsed,
            "isPremium": isPremium,
            "lastBetDate": lastBetDate,
            "preferences": [
                "useBiometrics": preferences.useBiometrics,
                "darkMode": preferences.darkMode,
                "notificationsEnabled": preferences.notificationsEnabled,
                "requireBiometricsForGreenCoins": preferences.requireBiometricsForGreenCoins
            ]
        ]
    }
}

// User preferences for app settings
struct UserPreferences: Codable {
    var useBiometrics: Bool
    var darkMode: Bool
    var notificationsEnabled: Bool
    var requireBiometricsForGreenCoins: Bool
    
    init() {
        self.useBiometrics = false
        self.darkMode = false
        self.notificationsEnabled = true
        self.requireBiometricsForGreenCoins = true
    }
    
    init(useBiometrics: Bool, darkMode: Bool, notificationsEnabled: Bool, requireBiometricsForGreenCoins: Bool) {
        self.useBiometrics = useBiometrics
        self.darkMode = darkMode
        self.notificationsEnabled = notificationsEnabled
        self.requireBiometricsForGreenCoins = requireBiometricsForGreenCoins
    }
}
