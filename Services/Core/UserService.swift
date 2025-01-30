import Foundation
import FirebaseFirestore
import FirebaseAuth

actor UserService {
    // MARK: - Properties
    private let db = FirebaseConfig.shared.db
    private let auth = FirebaseConfig.shared.auth
    
    // MARK: - CRUD Operations
    
    /// Creates a new user document in Firestore
    /// - Parameter user: The user to create
    /// - Returns: The created user
    func createUser(_ user: User) async throws -> User {
        let data = user.toDictionary()
        try await db.collection("users").document(user.id).setData(data)
        return user
    }
    
    /// Fetches a user document from Firestore
    /// - Parameter userId: The ID of the user to fetch
    /// - Returns: The fetched user
    func fetchUser(userId: String) async throws -> User {
        let document = try await db.collection("users").document(userId).getDocument()
        
        guard let user = User(document: document) else {
            throw DatabaseError.documentNotFound
        }
        
        return user
    }
    
    /// Updates a user document in Firestore
    /// - Parameter user: The user to update
    /// - Returns: The updated user
    func updateUser(_ user: User) async throws -> User {
        let data = user.toDictionary()
        try await db.collection("users").document(user.id).updateData(data)
        return user
    }
    
    /// Deletes a user document from Firestore
    /// - Parameter userId: The ID of the user to delete
    func deleteUser(userId: String) async throws {
        try await db.collection("users").document(userId).delete()
    }
    
    // MARK: - Balance Operations
    
    /// Updates user's coin balance
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - coinType: The type of coin to update
    ///   - amount: The amount to change (positive for increase, negative for decrease)
    func updateBalance(userId: String, coinType: CoinType, amount: Int) async throws {
        let userRef = db.collection("users").document(userId)
        
        return try await withCheckedThrowingContinuation { continuation in
            db.runTransaction({ [weak self] (transaction, errorPointer) -> Any? in
                guard self != nil else { return nil }
                
                do {
                    let userDocument = try transaction.getDocument(userRef)
                    guard var user = User(document: userDocument) else {
                        throw DatabaseError.documentNotFound
                    }
                    
                    // Update the appropriate balance
                    switch coinType {
                    case .yellow:
                        user.yellowCoins += amount
                        guard user.yellowCoins >= 0 else {
                            throw DatabaseError.insufficientFunds
                        }
                    case .green:
                        user.greenCoins += amount
                        guard user.greenCoins >= 0 else {
                            throw DatabaseError.insufficientFunds
                        }
                    }
                    
                    // Update the document
                    transaction.updateData(user.toDictionary(), forDocument: userRef)
                    return nil
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }, completion: { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            })
        }
    }
    
    // MARK: - Daily Limit Operations
    
    /// Updates user's daily green coins usage
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - amount: The amount to add to daily usage
    func updateDailyGreenCoinsUsage(userId: String, amount: Int) async throws {
        let userRef = db.collection("users").document(userId)
        
        return try await withCheckedThrowingContinuation { continuation in
            db.runTransaction({ [weak self] (transaction, errorPointer) -> Any? in
                guard self != nil else { return nil }
                
                do {
                    let userDocument = try transaction.getDocument(userRef)
                    guard var user = User(document: userDocument) else {
                        throw DatabaseError.documentNotFound
                    }
                    
                    // Check if we need to reset daily usage (new day)
                    if let lastBetDate = user.lastBetDate {
                        if !Calendar.current.isDateInToday(lastBetDate) {
                            user.dailyGreenCoinsUsed = 0
                        }
                    } else {
                        // If lastBetDate is nil, this is their first bet
                        user.dailyGreenCoinsUsed = 0
                    }
                    
                    // Update daily usage
                    user.dailyGreenCoinsUsed += amount
                    user.lastBetDate = Date()
                    
                    // Verify daily limit
                    guard user.dailyGreenCoinsUsed <= 100 else {
                        throw DatabaseError.dailyLimitExceeded
                    }
                    
                    // Update the document
                    transaction.updateData(user.toDictionary(), forDocument: userRef)
                    return nil
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }, completion: { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            })
        }
    }
    
    // MARK: - Preference Operations
    
    /// Updates user preferences
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - preferences: The new preferences
    func updatePreferences(userId: String, preferences: UserPreferences) async throws {
        let data = [
            "preferences": [
                "useBiometrics": preferences.useBiometrics,
                "darkMode": preferences.darkMode,
                "notificationsEnabled": preferences.notificationsEnabled,
                "requireBiometricsForGreenCoins": preferences.requireBiometricsForGreenCoins
            ]
        ]
        
        try await db.collection("users").document(userId).updateData(data)
    }
    
    // MARK: - Helper Methods
    
    /// Checks if user has sufficient funds for a transaction
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - coinType: Type of coin to check
    ///   - amount: Amount needed
    /// - Returns: Boolean indicating if user has sufficient funds
    func hasSufficientFunds(userId: String, coinType: CoinType, amount: Int) async throws -> Bool {
        let user = try await fetchUser(userId: userId)
        
        switch coinType {
        case .yellow:
            return user.yellowCoins >= amount
        case .green:
            return user.greenCoins >= amount
        }
    }
    
    /// Checks if user has remaining daily limit for green coins
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - amount: Amount to check
    /// - Returns: Boolean indicating if transaction is within daily limit
    func isWithinDailyLimit(userId: String, amount: Int) async throws -> Bool {
        let user = try await fetchUser(userId: userId)
        return (user.dailyGreenCoinsUsed + amount) <= 100
    }
}
