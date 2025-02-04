import Foundation
import FirebaseFirestore

class GameRepository: Repository {
    // MARK: - Properties
    typealias T = Game
    
    let cacheFilename = "games.cache"
    let cacheExpiryTime: TimeInterval = 300 // 5 minutes
    
    private let gameService: GameService
    private var listeners: [String: ListenerRegistration] = [:]
    private var cachedGames: [String: Game] = [:]
    private var scoreCache: [String: GameScore] = [:]

    
    // MARK: - Initialization
    init() {
        self.gameService = GameService()
        loadCachedGames()
    }
    
    // MARK: - Repository Protocol Methods
    
    func fetch(id: String) async throws -> Game? {
        // Try cache first
        if let cachedGame = cachedGames[id], isCacheValid() {
            return cachedGame
        }
        
        // If not in cache or cache invalid, fetch from network
        guard NetworkMonitor.shared.isConnected else {
            throw RepositoryError.networkError
        }
        
        do {
            let game = try await gameService.fetchGame(gameId: id)
            cachedGames[id] = game
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
        cachedGames[game.id] = game
        try saveCachedGames()
    }
    
    func remove(id: String) async throws {
        // Remove from cache
        cachedGames.removeValue(forKey: id)
        try saveCachedGames()
        
        // Note: In this implementation, we don't actually delete games from the server
        // as they're managed by the odds service. This is just for cache management.
    }
    
    func clearCache() throws {
        cachedGames.removeAll()
        try saveCachedGames()
    }
    
    // MARK: - Cache Methods
    
    private func loadCachedGames() {
        do {
            print("📂 Attempting to load games from cache...")
            let data = try loadFromCache()
            let container = try JSONDecoder().decode(CacheContainer<Game>.self, from: data)
            cachedGames = container.items
            print("✅ Successfully loaded \(cachedGames.count) games from cache")
        } catch {
            if (error as NSError).domain == NSCocoaErrorDomain &&
               (error as NSError).code == 260 {
                print("ℹ️ No cache file found - this is normal on first run")
            } else {
                print("⚠️ Failed to load games cache: \(error)")
            }
            cachedGames = [:]
        }
    }

    private func saveCachedGames() throws {
        print("💾 Saving games to cache...")
        let container = CacheContainer(items: cachedGames)
        let data = try JSONEncoder().encode(container)
        try saveToCache(data)
        print("✅ Successfully saved \(cachedGames.count) games to cache")
    }
    
    // MARK: - Additional Methods
    
    /// Fetches games for a specific league
    /// - Parameter league: The league to fetch games for
    /// - Returns: Array of games
    func fetchGames(league: String) async throws -> [Game] {
        guard NetworkMonitor.shared.isConnected else {
            return cachedGames.values
                .filter { $0.league == league }
                .sorted { $0.time < $1.time }
        }
        
        let games = try await gameService.fetchGames(league: league)
        
        // Update cache
        for game in games {
            cachedGames[game.id] = game
        }
        try saveCachedGames()
        
        return games
    }
    
    // Add this method to GameRepository.swift

    // Add this method to GameRepository class in GameRepository.swift

    // Add this method to GameRepository class in GameRepository.swift

    /// Syncs games from The Odds API to Firestore
    /// - Parameter games: Array of games to sync
    // Add this method to GameRepository class

    /// Syncs games from The Odds API to Firestore and removes expired games
    /// - Parameter games: Array of games to sync
    /// Syncs games and updates statuses based on The Odds API data
    func syncGames(_ games: [Game]) async throws {
        print("🔄 Starting game sync with \(games.count) games")
        let batch = FirebaseConfig.shared.db.batch()
        
        // Get existing games
        let snapshot = try await FirebaseConfig.shared.db.collection("games").getDocuments()
        print("📚 Found \(snapshot.documents.count) existing games in Firestore")
        
        // Get active game IDs
        let activeGameIds = Set(games.map { $0.id })
        
        // Track removed games
        var removedGameCount = 0
        
        // First pass - handle existing games
        for document in snapshot.documents {
            let gameId = document.documentID
            let gameRef = FirebaseConfig.shared.db.collection("games").document(gameId)
            
            if !activeGameIds.contains(gameId) {
                // Game no longer in API - check if we need to keep it for score resolution
                if let scoreDoc = try? await FirebaseConfig.shared.db.collection("scores")
                    .document(gameId)
                    .getDocument(),
                   let score = GameScore.from(scoreDoc),
                   !score.shouldRemove {
                    // Keep game for score resolution
                    print("🎲 Keeping completed game \(gameId) for score resolution")
                    continue
                }
                
                // Game is done and resolved - remove it
                print("🗑️ Removing finished game: \(gameId)")
                batch.deleteDocument(gameRef)
                
                // Also remove score if it exists
                let scoreRef = FirebaseConfig.shared.db.collection("scores").document(gameId)
                batch.deleteDocument(scoreRef)
                
                removedGameCount += 1
            }
        }
        
        // Second pass - update current games
        for game in games {
            print("📥 Processing game: \(game.id)")
            let gameRef = FirebaseConfig.shared.db.collection("games").document(game.id)
            var gameData = game.toDictionary()
            
            if let existingDoc = snapshot.documents.first(where: { $0.documentID == game.id }) {
                let existingData = existingDoc.data()
                
                // Preserve spread if game is locked
                if let isLocked = existingData["isLocked"] as? Bool,
                   isLocked == true,
                   let lockedSpread = existingData["spread"] as? Double {
                    gameData["spread"] = lockedSpread
                    print("🔒 Preserved locked spread \(lockedSpread) for game \(game.id)")
                }
                
                // Preserve admin settings
                preserveAdminSettings(existingData: existingData, gameData: &gameData)
            }
            
            batch.setData(gameData, forDocument: gameRef, merge: true)
        }
        
        try await batch.commit()
        print("""
            ✅ Sync completed:
            - Active games synced: \(games.count)
            - Games removed: \(removedGameCount)
            """)
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
                
                // Update cache if game exists
                if let game = game {
                    self.cachedGames[game.id] = game
                    try? self.saveCachedGames()
                }
            }
            
            listeners[gameId] = listener
        }
    }
    
    // Update these methods in the Repository protocol extension

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
        // Check cache first
        if let cached = scoreCache[gameId] {
            return cached
        }
        
        print("🔍 Looking up score for game \(gameId)")
        
        // Try Firestore
        let snapshot = try await FirebaseConfig.shared.db.collection("scores")
            .document(gameId)
            .getDocument()
        
        guard let score = GameScore.from(snapshot) else {
            print("⚠️ No score found for game \(gameId)")
            return nil
        }
        
        // Update cache
        scoreCache[gameId] = score
        
        print("✅ Found score: Home \(score.homeScore) - Away \(score.awayScore)")
        return score
    }
    
    private func preserveAdminSettings(existingData: [String: Any], gameData: inout [String: Any]) {
        // Preserve manual settings we want to keep
        let settingsToPreserve = [
            "manuallyFeatured",
            "isFeatured",
            "isVisible",
            "lastUpdatedBy",
            "lastUpdatedAt"
        ]
        
        for setting in settingsToPreserve {
            if let value = existingData[setting] {
                gameData[setting] = value
            }
        }
    }
    
    /// Removes a specific game listener
    /// - Parameter gameId: The ID of the game to stop listening to
    func removeListener(for gameId: String) {
        listeners[gameId]?.remove()
        listeners.removeValue(forKey: gameId)
    }
    
    /// Removes all game listeners
    func removeAllListeners() {
        listeners.values.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    // MARK: - Cleanup
    deinit {
        removeAllListeners()
    }
}
