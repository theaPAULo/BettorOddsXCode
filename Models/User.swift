// File: Models/User.swift
// Version: 1.0
// Description: Core user model for the BettorOdds app

import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    var id: String    // Instead of @DocumentID
    var email: String
    var dateJoined: Date
    var yellowCoins: Int
    var greenCoins: Int
    var dailyGreenCoinsUsed: Int
    var isPremium: Bool
    
    // Computed property for remaining daily limit
    var remainingDailyGreenCoins: Int {
        let dailyLimit = 100 // Move to constants later
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
    }
    
    // Convert to dictionary for Firestore
    func toDictionary() -> [String: Any] {
        return [
            "email": email,
            "dateJoined": dateJoined,
            "yellowCoins": yellowCoins,
            "greenCoins": greenCoins,
            "dailyGreenCoinsUsed": dailyGreenCoinsUsed,
            "isPremium": isPremium
        ]
    }
}

// User preferences for app settings
struct UserPreferences: Codable {
    var useBiometrics: Bool
    var darkMode: Bool
    var notificationsEnabled: Bool
    
    init() {
        self.useBiometrics = false
        self.darkMode = false
        self.notificationsEnabled = true
    }
}
