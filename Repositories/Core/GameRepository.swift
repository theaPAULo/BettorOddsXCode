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
    
    // MARK: - Initialization
    init() {
        self.gameService = GameService()
        loadCachedGames()
    }
    
    // MARK: - Repository Protocol Methods
    
    func fetch(id: String) async throws -> Game {
        // Try cache first
        if let cachedGame = cachedGames[id], isCacheValid() {
            return cachedGame
        }
        
        // If not in cache or cache invalid, fetch from network
        guard NetworkMonitor.shared.isConnected else {
            throw DatabaseError.networkError
        }
        
        let game = try await gameService.fetchGame(gameId: id)
        cachedGames[id] = game
        try saveCachedGames()
        return game
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
            let data = try loadFromCache()
            let container = try JSONDecoder().decode(CacheContainer<Game>.self, from: data)
            cachedGames = container.items
        } catch {
            print("Failed to load games cache: \(error)")
            cachedGames = [:]
        }
    }
    
    private func saveCachedGames() throws {
        let container = CacheContainer(items: cachedGames)
        let data = try JSONEncoder().encode(container)
        try saveToCache(data)
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
