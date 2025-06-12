//
//  User.swift
//  BettorOdds
//
//  Created by Claude on 1/31/25.
//  Version: 3.0.0 - Updated for Google/Apple Sign-In authentication
//

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

// MARK: - User Preferences
struct UserPreferences: Codable {
    var useBiometrics: Bool
    var darkMode: Bool
    var notificationsEnabled: Bool
    var requireBiometricsForGreenCoins: Bool
    
    init(useBiometrics: Bool = false,
         darkMode: Bool = false,
         notificationsEnabled: Bool = true,
         requireBiometricsForGreenCoins: Bool = true) {
        self.useBiometrics = useBiometrics
        self.darkMode = darkMode
        self.notificationsEnabled = notificationsEnabled
        self.requireBiometricsForGreenCoins = requireBiometricsForGreenCoins
    }
}

// MARK: - User Model
struct User: Codable, Identifiable {
    // MARK: - Properties
    var id: String                      // Firebase UID from Google/Apple Sign-In
    var displayName: String?            // Optional display name from provider
    var profileImageURL: String?        // Optional profile image from provider
    var authProvider: String            // "google.com" or "apple.com"
    var dateJoined: Date
    var yellowCoins: Int
    var greenCoins: Int
    var dailyGreenCoinsUsed: Int
    var isPremium: Bool
    var lastBetDate: Date?
    var preferences: UserPreferences
    var adminRole: AdminRole
    var lastAdminAction: Date?
    
    var remainingDailyGreenCoins: Int {
        let dailyLimit = 100
        return max(0, dailyLimit - dailyGreenCoinsUsed)
    }
    
    // MARK: - Coding Keys
    private enum CodingKeys: String, CodingKey {
        case id, displayName, profileImageURL, authProvider
        case dateJoined, yellowCoins, greenCoins
        case dailyGreenCoinsUsed, isPremium, lastBetDate
        case preferences, adminRole, lastAdminAction
    }
    
    // MARK: - Initialization
    init(id: String, displayName: String? = nil, profileImageURL: String? = nil, authProvider: String) {
        self.id = id
        self.displayName = displayName
        self.profileImageURL = profileImageURL
        self.authProvider = authProvider
        self.dateJoined = Date()
        self.yellowCoins = 100  // Starting bonus
        self.greenCoins = 0
        self.dailyGreenCoinsUsed = 0
        self.isPremium = false
        self.lastBetDate = Date()
        self.preferences = UserPreferences()
        self.adminRole = .none
        self.lastAdminAction = nil
    }
    
    // MARK: - Firestore Initialization
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        
        self.id = document.documentID
        self.displayName = data["displayName"] as? String
        self.profileImageURL = data["profileImageURL"] as? String
        self.authProvider = data["authProvider"] as? String ?? "unknown"
        self.dateJoined = (data["dateJoined"] as? Timestamp)?.dateValue() ?? Date()
        self.yellowCoins = data["yellowCoins"] as? Int ?? 0
        self.greenCoins = data["greenCoins"] as? Int ?? 0
        self.dailyGreenCoinsUsed = data["dailyGreenCoinsUsed"] as? Int ?? 0
        self.isPremium = data["isPremium"] as? Bool ?? false
        self.lastBetDate = (data["lastBetDate"] as? Timestamp)?.dateValue()
        self.lastAdminAction = (data["lastAdminAction"] as? Timestamp)?.dateValue()
        
        // Parse admin role
        if let adminRoleString = data["adminRole"] as? String {
            self.adminRole = AdminRole(rawValue: adminRoleString) ?? .none
        } else {
            self.adminRole = .none
        }
        
        // Parse preferences
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
    
    // MARK: - Firestore Conversion
    func toDictionary() -> [String: Any] {
        return [
            "displayName": displayName as Any,
            "profileImageURL": profileImageURL as Any,
            "authProvider": authProvider,
            "dateJoined": Timestamp(date: dateJoined),
            "yellowCoins": yellowCoins,
            "greenCoins": greenCoins,
            "dailyGreenCoinsUsed": dailyGreenCoinsUsed,
            "isPremium": isPremium,
            "lastBetDate": lastBetDate.map { Timestamp(date: $0) } as Any,
            "adminRole": adminRole.rawValue,
            "lastAdminAction": lastAdminAction.map { Timestamp(date: $0) } as Any,
            "preferences": [
                "useBiometrics": preferences.useBiometrics,
                "darkMode": preferences.darkMode,
                "notificationsEnabled": preferences.notificationsEnabled,
                "requireBiometricsForGreenCoins": preferences.requireBiometricsForGreenCoins
            ]
        ]
    }
}
