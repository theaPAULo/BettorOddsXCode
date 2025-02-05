//
//  User.swift
//  BettorOdds
//
//  Created by Claude on 1/31/25.
//  Version: 2.1.0 - Added phone verification support
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
    var saveCredentials: Bool
    var rememberMe: Bool
    
    init(useBiometrics: Bool = false,
         darkMode: Bool = false,
         notificationsEnabled: Bool = true,
         requireBiometricsForGreenCoins: Bool = true,
         saveCredentials: Bool = true,
         rememberMe: Bool = false) {
        self.useBiometrics = useBiometrics
        self.darkMode = darkMode
        self.notificationsEnabled = notificationsEnabled
        self.requireBiometricsForGreenCoins = requireBiometricsForGreenCoins
        self.saveCredentials = saveCredentials
        self.rememberMe = rememberMe
    }
}

// MARK: - User Model
struct User: Codable, Identifiable {
    // MARK: - Properties
    var id: String
    var email: String
    var dateJoined: Date
    var yellowCoins: Int
    var greenCoins: Int
    var dailyGreenCoinsUsed: Int
    var isPremium: Bool
    var lastBetDate: Date?
    var preferences: UserPreferences
    var adminRole: AdminRole
    var isEmailVerified: Bool
    var lastAdminAction: Date?
    // New properties for phone verification
    var phoneNumber: String?
    var isPhoneVerified: Bool
    var remainingDailyGreenCoins: Int {
        let dailyLimit = 100
        return max(0, dailyLimit - dailyGreenCoinsUsed)
    }
    
    // MARK: - Coding Keys
    private enum CodingKeys: String, CodingKey {
        case id, email, dateJoined, yellowCoins, greenCoins
        case dailyGreenCoinsUsed, isPremium, lastBetDate
        case preferences, adminRole, isEmailVerified, lastAdminAction
        case phoneNumber, isPhoneVerified
    }
    
    // MARK: - Initialization
    init(id: String, email: String, phoneNumber: String? = nil) {
        self.id = id
        self.email = email
        self.dateJoined = Date()
        self.yellowCoins = 100  // Starting bonus
        self.greenCoins = 0
        self.dailyGreenCoinsUsed = 0
        self.isPremium = false
        self.lastBetDate = Date()
        self.preferences = UserPreferences()
        self.adminRole = .none
        self.isEmailVerified = false
        self.lastAdminAction = nil
        self.phoneNumber = phoneNumber
        self.isPhoneVerified = phoneNumber != nil
    }
    
    // MARK: - Firestore Initialization
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        
        self.id = document.documentID
        self.email = data["email"] as? String ?? ""
        self.dateJoined = (data["dateJoined"] as? Timestamp)?.dateValue() ?? Date()
        self.yellowCoins = data["yellowCoins"] as? Int ?? 0
        self.greenCoins = data["greenCoins"] as? Int ?? 0
        self.dailyGreenCoinsUsed = data["dailyGreenCoinsUsed"] as? Int ?? 0
        self.isPremium = data["isPremium"] as? Bool ?? false
        self.lastBetDate = (data["lastBetDate"] as? Timestamp)?.dateValue()
        self.isEmailVerified = data["isEmailVerified"] as? Bool ?? false
        self.lastAdminAction = (data["lastAdminAction"] as? Timestamp)?.dateValue()
        self.phoneNumber = data["phoneNumber"] as? String
        self.isPhoneVerified = data["isPhoneVerified"] as? Bool ?? false
        
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
                requireBiometricsForGreenCoins: prefsData["requireBiometricsForGreenCoins"] as? Bool ?? true,
                saveCredentials: prefsData["saveCredentials"] as? Bool ?? true,
                rememberMe: prefsData["rememberMe"] as? Bool ?? false
            )
        } else {
            self.preferences = UserPreferences()
        }
    }
    
    // MARK: - Firestore Conversion
    func toDictionary() -> [String: Any] {
        return [
            "email": email,
            "dateJoined": Timestamp(date: dateJoined),
            "yellowCoins": yellowCoins,
            "greenCoins": greenCoins,
            "dailyGreenCoinsUsed": dailyGreenCoinsUsed,
            "isPremium": isPremium,
            "lastBetDate": lastBetDate.map { Timestamp(date: $0) } as Any,
            "adminRole": adminRole.rawValue,
            "isEmailVerified": isEmailVerified,
            "lastAdminAction": lastAdminAction.map { Timestamp(date: $0) } as Any,
            "phoneNumber": phoneNumber as Any,
            "isPhoneVerified": isPhoneVerified,
            "preferences": [
                "useBiometrics": preferences.useBiometrics,
                "darkMode": preferences.darkMode,
                "notificationsEnabled": preferences.notificationsEnabled,
                "requireBiometricsForGreenCoins": preferences.requireBiometricsForGreenCoins,
                "saveCredentials": preferences.saveCredentials,
                "rememberMe": preferences.rememberMe
            ]
        ]
    }
}
