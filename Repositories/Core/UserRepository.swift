//
//  UserRepository.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Version: 1.0.0
//

import Foundation

class UserRepository: Repository {
    // MARK: - Properties
    typealias T = User
    
    let cacheFilename = "users.cache"
    let cacheExpiryTime: TimeInterval = 3600 // 1 hour
    private let userService: UserService
    
    // Cache container
    private var cachedUsers: [String: User] = [:]
    
    // MARK: - Initialization
    init() {
        self.userService = UserService()
        loadCachedUsers()
    }
    
    // MARK: - Repository Methods
    
    /// Fetches a user by ID
    /// - Parameter id: The user's ID
    /// - Returns: The user
    func fetch(id: String) async throws -> User {
        // Try cache first
        if let cachedUser = cachedUsers[id], isCacheValid() {
            return cachedUser
        }
        
        // If not in cache or offline, fetch from network
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        let user = try await userService.fetchUser(userId: id)
        
        // Save to cache
        cachedUsers[id] = user
        try saveCachedUsers()
        
        return user
    }
    
    /// Saves a user
    /// - Parameter user: The user to save
    func save(_ user: User) async throws {
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        // Save to network
        let savedUser = try await userService.updateUser(user)
        
        // Update cache
        cachedUsers[user.id] = savedUser
        try saveCachedUsers()
    }
    
    /// Removes a user
    /// - Parameter id: The user's ID
    func remove(id: String) async throws {
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        // Remove from network
        try await userService.deleteUser(userId: id)
        
        // Remove from cache
        cachedUsers.removeValue(forKey: id)
        try saveCachedUsers()
    }
    
    /// Clears the user cache
    func clearCache() throws {
        cachedUsers.removeAll()
        try saveCachedUsers()
    }
    
    // MARK: - Cache Methods
    
    private func loadCachedUsers() {
        do {
            let data = try loadFromCache()
            let container = try JSONDecoder().decode(CacheContainer<User>.self, from: data)
            cachedUsers = container.items
        } catch {
            cachedUsers = [:]
        }
    }
    
    private func saveCachedUsers() throws {
        let container = CacheContainer(items: cachedUsers)
        let data = try JSONEncoder().encode(container)
        try saveToCache(data)
    }
    
    // MARK: - Additional Methods
    
    /// Updates user balance
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - coinType: Type of coin to update
    ///   - amount: Amount to change
    func updateBalance(userId: String, coinType: CoinType, amount: Int) async throws {
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        try await userService.updateBalance(
            userId: userId,
            coinType: coinType,
            amount: amount
        )
        
        // Invalidate cache for this user
        cachedUsers.removeValue(forKey: userId)
        try saveCachedUsers()
    }
    
    /// Updates user preferences
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - preferences: New preferences
    func updatePreferences(userId: String, preferences: UserPreferences) async throws {
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        try await userService.updatePreferences(
            userId: userId,
            preferences: preferences
        )
        
        // Invalidate cache for this user
        cachedUsers.removeValue(forKey: userId)
        try saveCachedUsers()
    }
    
    /// Updates daily green coins usage
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - amount: Amount to add to daily usage
    func updateDailyGreenCoinsUsage(userId: String, amount: Int) async throws {
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        try await userService.updateDailyGreenCoinsUsage(
            userId: userId,
            amount: amount
        )
        
        // Invalidate cache for this user
        cachedUsers.removeValue(forKey: userId)
        try saveCachedUsers()
    }
}
