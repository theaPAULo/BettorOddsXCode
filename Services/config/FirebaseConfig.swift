import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import FirebaseAppCheck

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
            // Configure App Check for Debug
            #if DEBUG
            let appCheckProviderFactory = AppCheckDebugProviderFactory()
            AppCheck.setAppCheckProviderFactory(appCheckProviderFactory)
            print("✅ Debug App Check provider configured")
            #else

            // For production, we'll use device check
            if #available(iOS 14.0, *) {
                let providerFactory = DeviceCheckProviderFactory()
                AppCheck.setAppCheckProviderFactory(providerFactory)
            }
            #endif
            
            // Configure Firebase
            FirebaseApp.configure()
        }
        
        // Initialize Firebase services
        self.db = Firestore.firestore()
        self.auth = Auth.auth()
        self.storage = Storage.storage()
        
        // Configure Firestore settings
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true // Enable offline persistence
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited // Unlimited cache size
        self.db.settings = settings
        
        print("✅ Firebase configuration completed")
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
    
    // MARK: - Development Configuration
    #if DEBUG
    func configureDevelopment() {
        let settings = FirestoreSettings()
        settings.host = "localhost:8080"
        settings.isPersistenceEnabled = false
        settings.isSSLEnabled = false
        db.settings = settings
        print("🔧 Firebase configured for development")
    }
    #endif
}
