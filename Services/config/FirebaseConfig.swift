//
//  FirebaseConfig.swift
//  BettorOdds
//
//  Version: 2.7.1 - Fixed Int64 conversion issue and deprecated Firebase methods
//  Updated: June 2025
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import UserNotifications

/// Manages Firebase configuration and initialization
class FirebaseConfig {
    // MARK: - Singleton
    static let shared = FirebaseConfig()
    
    // MARK: - Properties
    let db: Firestore
    let auth: Auth
    let storage: Storage
    
    // MARK: - Initialization
    private init() {
        // Check if Firebase is already configured
        if FirebaseApp.app() == nil {
            // Configure Firebase only if not already configured
            FirebaseApp.configure()
            print("✅ Firebase app configured")
            
            // Request notification permissions
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    print("❌ Notification permission error: \(error)")
                } else {
                    print("✅ Notification permission granted: \(granted)")
                }
            }
            
            #if DEBUG
            print("🔧 Running in DEBUG mode")
            #endif
        }
        
        // Initialize Firebase services
        self.db = Firestore.firestore()
        self.auth = Auth.auth()
        self.storage = Storage.storage()
        
        // FIXED: Configure Firestore settings using new cacheSettings API
        let settings = FirestoreSettings()
        
        // FIXED: Use new cacheSettings instead of deprecated properties
        // Convert to NSNumber for compatibility
        let unlimited = NSNumber(value: FirestoreCacheSizeUnlimited)
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: unlimited)
        
        self.db.settings = settings
        
        print("✅ Firebase services initialized")
        configureDebugSettings()
    }
    
    // MARK: - Collection References
    
    /// Returns a reference to the users collection
    var usersCollection: CollectionReference {
        return db.collection("users")
    }
    
    /// Returns a reference to the bets collection
    var betsCollection: CollectionReference {
        return db.collection("bets")
    }
    
    /// Returns a reference to the transactions collection
    var transactionsCollection: CollectionReference {
        return db.collection("transactions")
    }
    
    /// Returns a reference to the games collection
    var gamesCollection: CollectionReference {
        return db.collection("games")
    }
    
    /// Returns a reference to the settings collection
    var settingsCollection: CollectionReference {
        return db.collection("settings")
    }
    
    // MARK: - Debug Configuration
    private func configureDebugSettings() {
        #if DEBUG
        let settings = FirestoreSettings()
        // FIXED: Use new cacheSettings API for debug mode
        settings.cacheSettings = MemoryCacheSettings()
        db.settings = settings
        print("🔧 Debug settings configured for Firestore")
        #endif
    }
}
