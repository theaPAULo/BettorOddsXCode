//
//  GameRepository.swift
//  BettorOdds
//
//  Version: 2.8.0 - FIXED: League-specific caching and cross-league deletion
//  Updated: June 2025
//
//  CHANGES:
//  - Fixed cache collision between leagues
//  - Prevented cross-league game deletion in syncGames
//  - Added league-specific caching structure
//

import Foundation
import FirebaseFirestore

class GameRepository: Repository {
    // MARK: - Properties
    typealias T = Game
    
    let cacheFilename = "games.cache"
    let cacheExpiryTime: TimeInterval = 300 // 5 minutes
    
    private let gameService: GameService
    private var listeners: [String: ListenerRegistration] = [:]
    
    // FIXED: League-specific caching to prevent collision
    private var cachedGamesByLeague: [String: [String: Game]] = [:] // [league: [gameId: Game]]
    private var scoreCache: [String: GameScore] = [:]

    
    // MARK: - Initialization
    init() {
        self.gameService = GameService()
        loadCachedGames()
    }
    
    // MARK: - Repository Protocol Methods
    
    func fetch(id: String) async throws -> Game? {
        // Try cache first - search across all leagues
        for leagueGames in cachedGamesByLeague.values {
            if let cachedGame = leagueGames[id], isCacheValid() {
                return cachedGame
            }
        }
        
        // If not in cache or cache invalid, fetch from network
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        do {
            let game = try await gameService.fetchGame(gameId: id)
            
            // Update league-specific cache
            if cachedGamesByLeague[game.league] == nil {
                cachedGamesByLeague[game.league] = [:]
            }
            cachedGamesByLeague[game.league]?[game.id] = game
            try saveCachedGames()
            
            return game
        } catch {
            // If not found, return nil instead of throwing
            if case RepositoryError.itemNotFound = error {
                return nil
            }
            throw error
        }
    }
    
    func save(_ game: Game) async throws {
        guard NetworkMonitor.shared.isConnected else {
            throw DatabaseError.networkError
        }
        
        try await gameService.saveGame(game)
        
        // Update league-specific cache
        if cachedGamesByLeague[game.league] == nil {
            cachedGamesByLeague[game.league] = [:]
        }
        cachedGamesByLeague[game.league]?[game.id] = game
        try saveCachedGames()
    }
    
    func remove(id: String) async throws {
        // Remove from cache across all leagues
        for league in cachedGamesByLeague.keys {
            cachedGamesByLeague[league]?.removeValue(forKey: id)
        }
        try saveCachedGames()
        
        // Note: In this implementation, we don't actually delete games from the server
        // as they're managed by the odds service. This is just for cache management.
    }
    
    func clearCache() throws {
        cachedGamesByLeague.removeAll()
        try saveCachedGames()
    }
    
    // MARK: - League-Specific Methods
    
    /// FIXED: Fetches games for a specific league with proper league-specific caching
    /// - Parameter league: The league to fetch games for
    /// - Returns: Array of games
    func fetchGames(league: String) async throws -> [Game] {
        print("🔍 Fetching \(league) games from cache/network...")
        
        guard NetworkMonitor.shared.isConnected else {
            let cachedGames = cachedGamesByLeague[league]?.values.compactMap { $0 } ?? []
            print("📱 Offline: Returning \(cachedGames.count) cached \(league) games")
            return cachedGames.sorted { $0.time < $1.time }
        }
        
        let games = try await gameService.fetchGames(league: league)
        print("🌐 Fetched \(games.count) \(league) games from network")
        
        // Update league-specific cache
        if cachedGamesByLeague[league] == nil {
            cachedGamesByLeague[league] = [:]
        }
        
        // Clear existing cache for this league and repopulate
        cachedGamesByLeague[league] = [:]
        for game in games {
            cachedGamesByLeague[league]?[game.id] = game
        }
        
        try saveCachedGames()
        
        return games
    }
    
    /// FIXED: Syncs games from The Odds API to Firestore with league-specific deletion
    /// - Parameter games: Array of games to sync
    /// Syncs games and updates statuses based on The Odds API data
    func syncGames(_ games: [Game]) async throws {
        guard !games.isEmpty else {
            print("⚠️ No games to sync")
            return
        }
        
        let syncingLeague = games.first?.league ?? "Unknown"
        print("🔄 Starting league-specific sync for \(syncingLeague) with \(games.count) games")
        
        // OPTIMIZATION 1: Use a single batch for all operations
        let batch = FirebaseConfig.shared.db.batch()
        
        // OPTIMIZATION 2: Get existing games in parallel with batch preparation
        async let existingGamesSnapshot = FirebaseConfig.shared.db.collection("games").getDocuments()
        
        // Get active game IDs
        let activeGameIds = Set(games.map { $0.id })
        
        // Wait for existing games data
        let snapshot = try await existingGamesSnapshot
        print("📚 Found \(snapshot.documents.count) existing games in Firestore")
        
        // FIXED: Only remove games from the SAME league that are not in active games
        var removedGameCount = 0
        let gamesToRemove = snapshot.documents.filter { doc in
            let gameId = doc.documentID
            let gameData = doc.data()
            let gameLeague = gameData["league"] as? String ?? ""
            
            // Only remove games from the SAME league that are not in current active games
            return gameLeague == syncingLeague && !activeGameIds.contains(gameId)
        }
        
        // OPTIMIZATION 4: Reduced logging for bulk operations
        if !gamesToRemove.isEmpty {
            print("🗑️ Removing \(gamesToRemove.count) outdated \(syncingLeague) games (keeping other leagues intact)")
            
            for document in gamesToRemove {
                let gameId = document.documentID
                let gameRef = FirebaseConfig.shared.db.collection("games").document(gameId)
                
                batch.deleteDocument(gameRef)
                // Also remove score if it exists
                let scoreRef = FirebaseConfig.shared.db.collection("scores").document(gameId)
                batch.deleteDocument(scoreRef)
                removedGameCount += 1
            }
        }
        
        // OPTIMIZATION 5: Process current games efficiently
        for game in games {
            let gameRef = FirebaseConfig.shared.db.collection("games").document(game.id)
            var gameData = game.toDictionary()
            
            // Check if game exists and preserve locked settings
            if let existingDoc = snapshot.documents.first(where: { $0.documentID == game.id }) {
                let existingData = existingDoc.data()
                
                // Preserve spread if game is locked
                if let isLocked = existingData["isLocked"] as? Bool,
                   isLocked == true,
                   let lockedSpread = existingData["spread"] as? Double {
                    gameData["spread"] = lockedSpread
                    print("🔒 Preserving locked spread for game \(game.id)")
                }
                
                // Preserve admin settings
                preserveAdminSettings(existingData: existingData, gameData: &gameData)
            }
            
            batch.setData(gameData, forDocument: gameRef, merge: true)
        }
        
        // OPTIMIZATION 6: Single commit for all operations
        try await batch.commit()
        
        print("""
            ✅ League-specific sync completed for \(syncingLeague):
            - Active games synced: \(games.count)
            - Games removed: \(removedGameCount)
            - Other leagues: Untouched
            """)
    }
    
    // MARK: - Cache Methods
    
    /// FIXED: Load league-specific cached games
    private func loadCachedGames() {
        do {
            print("📂 Attempting to load games from cache...")
            let data = try loadFromCache()
            
            // FIXED: Direct decode of the league structure without extra nesting
            cachedGamesByLeague = try JSONDecoder().decode([String: [String: Game]].self, from: data)
            
            let totalGames = cachedGamesByLeague.values.reduce(0) { $0 + $1.count }
            let leagueInfo = cachedGamesByLeague.mapValues { $0.count }
            print("✅ Successfully loaded \(totalGames) games from cache across \(cachedGamesByLeague.keys.count) leagues: \(leagueInfo)")
        } catch {
            if (error as NSError).domain == NSCocoaErrorDomain &&
               (error as NSError).code == 260 {
                print("ℹ️ No cache file found - this is normal on first run")
            } else {
                print("⚠️ Failed to load games cache: \(error)")
            }
            cachedGamesByLeague = [:]
        }
    }

    /// FIXED: Save league-specific cached games
    private func saveCachedGames() throws {
        let totalGames = cachedGamesByLeague.values.reduce(0) { $0 + $1.count }
        let leagueInfo = cachedGamesByLeague.mapValues { $0.count }
        print("💾 Saving \(totalGames) games to cache across \(cachedGamesByLeague.keys.count) leagues: \(leagueInfo)")
        
        // FIXED: Direct encode of the league structure
        let data = try JSONEncoder().encode(cachedGamesByLeague)
        try saveToCache(data)
        print("✅ Successfully saved league-specific games to cache")
    }
    
    // MARK: - Real-time Updates
    
    /// Sets up a real-time listener for game updates
    /// - Parameters:
    ///   - gameId: The ID of the game to listen to
    ///   - handler: Closure to handle game updates
    /// - Returns: Listener registration that can be used to remove the listener
    func listenToGameUpdates(gameId: String, handler: @escaping (Game?) -> Void) {
        Task {
            let listener = await gameService.listenToGameUpdates(gameId: gameId) { game in
                handler(game)
                
                // Update league-specific cache if game exists
                if let game = game {
                    if self.cachedGamesByLeague[game.league] == nil {
                        self.cachedGamesByLeague[game.league] = [:]
                    }
                    self.cachedGamesByLeague[game.league]?[game.id] = game
                    try? self.saveCachedGames()
                }
            }
            
            listeners[gameId] = listener
        }
    }
    
    // MARK: - Cache and Storage Methods
    
    /// Saves data to cache
    func saveToCache(_ data: Data) throws {
        // Ensure cache directory exists
        try FileManager.default.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        // Save the data
        try data.write(to: cacheURL)
    }

    /// Loads data from cache
    func loadFromCache() throws -> Data {
        // Check if cache file exists
        guard FileManager.default.fileExists(atPath: cacheURL.path) else {
            throw NSError(
                domain: NSCocoaErrorDomain,
                code: 260,
                userInfo: [
                    NSFilePathErrorKey: cacheURL.path,
                    NSLocalizedDescriptionKey: "Cache file does not exist"
                ]
            )
        }
        
        return try Data(contentsOf: cacheURL)
    }
    
    /// Score management methods
    func saveScore(_ score: GameScore) async throws {
        print("💾 Saving score for game \(score.gameId)...")
        
        try await FirebaseConfig.shared.db.collection("scores")
            .document(score.gameId)
            .setData(score.toDictionary())
        
        // Update cache
        scoreCache[score.gameId] = score
        
        print("✅ Successfully saved score")
    }

    func getScore(for gameId: String) async throws -> GameScore? {
        // Try cache first
        if let cachedScore = scoreCache[gameId] {
            return cachedScore
        }
        
        // Fetch from Firestore
        let document = try await FirebaseConfig.shared.db.collection("scores")
            .document(gameId)
            .getDocument()
        
        if document.exists {
            let score = GameScore.from(document)
            scoreCache[gameId] = score
            return score
        }
        
        return nil
    }
    
    // MARK: - Helper Methods
    
    /// Preserves admin settings when syncing games
    private func preserveAdminSettings(existingData: [String: Any], gameData: inout [String: Any]) {
        // Preserve admin-set values
        if let isFeatured = existingData["isFeatured"] as? Bool {
            gameData["isFeatured"] = isFeatured
        }
        
        if let manuallyFeatured = existingData["manuallyFeatured"] as? Bool {
            gameData["manuallyFeatured"] = manuallyFeatured
        }
        
        if let isVisible = existingData["isVisible"] as? Bool {
            gameData["isVisible"] = isVisible
        }
        
        if let isLocked = existingData["isLocked"] as? Bool {
            gameData["isLocked"] = isLocked
        }
        
        if let lastUpdatedBy = existingData["lastUpdatedBy"] as? String {
            gameData["lastUpdatedBy"] = lastUpdatedBy
        }
        
        if let lastUpdatedAt = existingData["lastUpdatedAt"] {
            gameData["lastUpdatedAt"] = lastUpdatedAt
        }
    }
    
    /// Get debug info about cached games
    func getCacheDebugInfo() -> [String: Int] {
        return cachedGamesByLeague.mapValues { $0.count }
    }
}
