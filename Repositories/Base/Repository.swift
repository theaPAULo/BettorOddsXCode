import Foundation

// MARK: - Repository Protocol
protocol Repository {
    associatedtype T: Codable
    
    /// The cache filename used by the repository
    var cacheFilename: String { get }
    
    /// Time to keep items in cache (in seconds)
    var cacheExpiryTime: TimeInterval { get }
    
    /// Fetches an item by its ID
    func fetch(id: String) async throws -> T
    
    /// Saves an item
    func save(_ item: T) async throws
    
    /// Removes an item
    func remove(id: String) async throws
    
    /// Clears all cached data
    func clearCache() throws
}

// MARK: - Cache Configuration
extension Repository {
    /// Gets the cache directory URL
    var cacheDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }
    
    /// Gets the cache file URL
    var cacheURL: URL {
        cacheDirectory.appendingPathComponent(cacheFilename)
    }
    
    /// Saves data to cache
    func saveToCache(_ data: Data) throws {
        try data.write(to: cacheURL)
    }
    
    /// Loads data from cache
    func loadFromCache() throws -> Data {
        try Data(contentsOf: cacheURL)
    }
    
    /// Checks if cache is valid
    func isCacheValid() -> Bool {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: cacheURL.path),
              let modificationDate = attributes[.modificationDate] as? Date else {
            return false
        }
        
        let cacheAge = Date().timeIntervalSince(modificationDate)
        return cacheAge < cacheExpiryTime
    }
}

// MARK: - Network Status
class NetworkMonitor {
    static let shared = NetworkMonitor()
    
    var isConnected: Bool {
        // Implementation would check actual network connectivity
        return true
    }
}

// MARK: - Cache Keys
struct CacheKeys {
    static let userPrefix = "user_"
    static let betPrefix = "bet_"
    static let gamePrefix = "game_"
    static let transactionPrefix = "transaction_"
    
    static func userKey(_ id: String) -> String {
        return userPrefix + id
    }
    
    static func betKey(_ id: String) -> String {
        return betPrefix + id
    }
    
    static func gameKey(_ id: String) -> String {
        return gamePrefix + id
    }
    
    static func transactionKey(_ id: String) -> String {
        return transactionPrefix + id
    }
}

// MARK: - Cache Container
struct CacheContainer<T: Codable>: Codable {
    let items: [String: T]
    let timestamp: Date
    
    init(items: [String: T]) {
        self.items = items
        self.timestamp = Date()
    }
}
