//
//  BetRepository.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Version: 1.0.0
//

import Foundation

class BetRepository: Repository {
    // MARK: - Properties
    typealias T = Bet
    
    let cacheFilename = "bets.cache"
    let cacheExpiryTime: TimeInterval = 1800 // 30 minutes
    private let betService: BetService
    
    // Cache container
    private var cachedBets: [String: Bet] = [:]
    private var pendingBets: [Bet] = []
    
    // MARK: - Initialization
    init() {
        self.betService = BetService()
        loadCachedBets()
        loadPendingBets()
    }
    
    // MARK: - Repository Methods
    
    /// Fetches a bet by ID
    /// - Parameter id: The bet's ID
    /// - Returns: The bet
    func fetch(id: String) async throws -> Bet {
        // Try cache first
        if let cachedBet = cachedBets[id], isCacheValid() {
            return cachedBet
        }
        
        // If not in cache or offline, fetch from network
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        let bet = try await betService.fetchBet(betId: id)
        
        // Save to cache
        cachedBets[id] = bet
        try saveCachedBets()
        
        return bet
    }
    
    /// Places a new bet
    /// - Parameter bet: The bet to place
    func save(_ bet: Bet) async throws {
        guard NetworkMonitor.shared.isConnected else {
            // Queue for offline
            try queueOfflineBet(bet)
            throw RepositoryError.networkError
        }
        
        // Save to network
        let savedBet = try await betService.placeBet(bet)
        
        // Update cache
        cachedBets[savedBet.id] = savedBet
        try saveCachedBets()
    }
    
    /// Removes a bet (cancellation)
    /// - Parameter id: The bet's ID
    func remove(id: String) async throws {
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        // Cancel bet on network
        try await betService.cancelBet(id)
        
        // Remove from cache
        cachedBets.removeValue(forKey: id)
        try saveCachedBets()
    }
    
    /// Clears the bet cache
    func clearCache() throws {
        cachedBets.removeAll()
        try saveCachedBets()
    }
    
    // MARK: - Cache Methods
    
    private func loadCachedBets() {
        do {
            let data = try loadFromCache()
            let container = try JSONDecoder().decode(CacheContainer<Bet>.self, from: data)
            cachedBets = container.items
        } catch {
            cachedBets = [:]
        }
    }
    
    private func saveCachedBets() throws {
        let container = CacheContainer(items: cachedBets)
        let data = try JSONEncoder().encode(container)
        try saveToCache(data)
    }
    
    // MARK: - Additional Methods
    
    /// Fetches all bets for a user
    /// - Parameter userId: The user's ID
    /// - Returns: Array of bets
    func fetchUserBets(userId: String) async throws -> [Bet] {
        guard NetworkMonitor.shared.isConnected else {
            return cachedBets.values
                .filter { $0.userId == userId }
                .sorted { $0.createdAt > $1.createdAt }
        }
        
        let bets = try await betService.fetchUserBets(userId: userId)
        
        // Cache each bet
        for bet in bets {
            cachedBets[bet.id] = bet
        }
        try saveCachedBets()
        
        return bets
    }
    
    /// Updates bet status and processes winnings if applicable
    /// - Parameters:
    ///   - betId: The bet's ID
    ///   - status: The new status
    func updateBetStatus(betId: String, status: BetStatus) async throws {
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        try await betService.updateBetStatus(betId: betId, status: status)
        
        // Invalidate cache for this bet
        cachedBets.removeValue(forKey: betId)
        try saveCachedBets()
    }
    
    // MARK: - Offline Support Methods
    
    private func loadPendingBets() {
        let pendingBetsURL = cacheDirectory.appendingPathComponent("pending_bets.cache")
        do {
            let data = try Data(contentsOf: pendingBetsURL)
            pendingBets = try JSONDecoder().decode([Bet].self, from: data)
        } catch {
            pendingBets = []
        }
    }
    
    private func savePendingBets() throws {
        let pendingBetsURL = cacheDirectory.appendingPathComponent("pending_bets.cache")
        let data = try JSONEncoder().encode(pendingBets)
        try data.write(to: pendingBetsURL)
    }
    
    /// Queues a bet for later submission when online
    private func queueOfflineBet(_ bet: Bet) throws {
        pendingBets.append(bet)
        try savePendingBets()
    }
    
    /// Processes any queued bets when coming back online
    func processQueuedBets() async throws {
        for bet in pendingBets {
            do {
                try await save(bet)
            } catch {
                print("Failed to process queued bet: \(error.localizedDescription)")
            }
        }
        
        // Clear the queue
        pendingBets.removeAll()
        try savePendingBets()
    }
}
