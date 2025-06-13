//
//  GamesViewModel.swift
//  BettorOdds
//
//  Created by Claude on 6/13/25
//  Version: 2.2.0 - Simplified to work with existing repository methods
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class GamesViewModel: ListViewModel<Game> {
    
    // MARK: - Published Properties
    @Published private(set) var featuredGame: Game?
    @Published var balance: Double = 1000.0
    @Published var dailyBetsTotal: Double = 0.0
    
    // MARK: - Private Properties
    private let refreshInterval: TimeInterval = 300 // 5 minutes
    private var refreshTask: Task<Void, Never>?
    private let gameRepository = GameRepository()
    private let oddsService = OddsService.shared
    private let scoreService = ScoreService.shared
    
    // MARK: - Computed Properties
    
    /// Returns only games that should be visible to users
    override var filteredItems: [Game] {
        return items
            .filter { $0.isVisible }
            .sorted { game1, game2 in
                // Sort by priority: featured first, then by time
                if game1.isFeatured != game2.isFeatured {
                    return game1.isFeatured
                }
                return game1.time < game2.time
            }
    }
    
    /// Convenience accessor for games
    var games: [Game] {
        return filteredItems
    }

    // MARK: - Initialization
    
    override init() {
        super.init()
        setupRefreshTimer()
        
        // Load cached data immediately
        Task {
            await loadCachedGames()
        }
    }
    
    // MARK: - Public Methods
    
    /// Loads items (required by base class)
    override func loadItems() async {
        await refreshGames()
    }
    
    /// Refreshes games data from The Odds API and syncs to Firebase
    func refreshGames() async {
        guard !isLoading else {
            print("🔄 Refresh already in progress, skipping")
            return
        }
        
        await executeAsync({
            print("🔄 Starting games refresh from The Odds API")
            
            // 1. Fetch fresh games from The Odds API
            let freshGames = try await self.oddsService.fetchGames()
            print("📊 Fetched \(freshGames.count) games from The Odds API")
            
            // 2. Sync games to Firebase
            print("💾 Syncing games to Firebase")
            try await self.gameRepository.syncGames(freshGames)
            
            // 3. Fetch scores for completed games (non-critical)
            await self.fetchScoresNonCritical()
            
            // 4. Load updated games from Firebase using existing method
            let loadedGames = try await self.gameRepository.fetchGames(league: "NBA")
            print("📚 Loaded \(loadedGames.count) games from Firebase")
            
            return loadedGames
            
        }, onSuccess: { [weak self] (loadedGames: [Game]) in
            self?.items = loadedGames.filter { $0.isVisible }
            self?.updateFeaturedGame()
            print("✅ Games refresh completed successfully")
            
        }, onError: { [weak self] error in
            print("❌ Games refresh error: \(error.localizedDescription)")
            // Try to load cached games as fallback
            Task { [weak self] in
                await self?.loadCachedGames()
            }
        })
    }
    
    /// Manually refreshes games (for pull-to-refresh)
    override func refresh() async {
        await refreshGames()
    }
    
    // MARK: - Private Methods
    
    /// Loads cached games as a fallback
    private func loadCachedGames() async {
        do {
            let cachedGames = try await gameRepository.fetchGames(league: "NBA")
            if !cachedGames.isEmpty {
                items = cachedGames.filter { $0.isVisible }
                updateFeaturedGame()
                print("📂 Loaded \(cachedGames.count) cached games")
            } else {
                print("ℹ️ No cached games found")
            }
        } catch {
            print("❌ Error loading cached games: \(error)")
        }
    }
    
    /// Fetches scores without failing the entire refresh process
    private func fetchScoresNonCritical() async {
        do {
            try await scoreService.fetchScores(sport: "basketball_nba")
            print("✅ Score fetching completed successfully")
        } catch {
            // Don't let score fetching errors stop the entire game loading process
            print("⚠️ Score fetching failed (non-critical): \(error.localizedDescription)")
        }
    }
    
    /// Updates the featured game based on business logic
    private func updateFeaturedGame() {
        print("🔍 Looking for featured game...")
        
        // First check for manually featured games
        if let manuallyFeatured = items.first(where: { $0.manuallyFeatured && $0.isVisible }) {
            featuredGame = manuallyFeatured
            print("⭐️ Found manually featured game: \(manuallyFeatured.id)")
            return
        }
        
        // Fall back to auto-selection based on bet count
        featuredGame = items
            .filter { $0.isVisible && !$0.shouldBeLocked && !$0.isLocked }
            .max(by: { $0.totalBets < $1.totalBets })
        
        if let selected = featuredGame {
            print("✨ Auto-selected featured game: \(selected.id)")
        } else {
            print("❌ No featured game selected")
        }
    }
    
    /// Sets up automatic refresh timer
    private func setupRefreshTimer() {
        print("⏰ Setting up refresh timer with interval: \(refreshInterval) seconds")
        
        // Cancel any existing refresh task
        refreshTask?.cancel()
        
        // Create new refresh task
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                // Wait for the interval
                try? await Task.sleep(nanoseconds: UInt64(refreshInterval * 1_000_000_000))
                
                // Check if we're still alive and refresh
                guard !Task.isCancelled else { break }
                await self?.refreshGames()
            }
        }
    }
    
    // MARK: - Game Management Methods (for admin features)
    
    /// Toggles a game's locked status (admin only)
    func toggleGameLock(_ game: Game) async {
        await executeAsync({
            // Update the game directly in Firebase using the same pattern as AdminGameManagementViewModel
            let db = Firestore.firestore()
            try await db.collection("games").document(game.id)
                .updateData([
                    "isLocked": !game.isLocked,
                    "lastUpdatedAt": Timestamp(date: Date()),
                    "lastUpdatedBy": Auth.auth().currentUser?.uid ?? "unknown"
                ])
            
            // Update local copy
            var updatedGame = game
            updatedGame.isLocked = !game.isLocked
            return updatedGame
            
        }, onSuccess: { [weak self] (updatedGame: Game) in
            self?.updateItem(updatedGame)
            print("🔓 Toggled lock for game \(game.id)")
        })
    }
    
    /// Toggles a game's visibility (admin only)
    func toggleGameVisibility(_ game: Game) async {
        await executeAsync({
            // Update the game directly in Firebase
            let db = Firestore.firestore()
            try await db.collection("games").document(game.id)
                .updateData([
                    "isVisible": !game.isVisible,
                    "lastUpdatedAt": Timestamp(date: Date()),
                    "lastUpdatedBy": Auth.auth().currentUser?.uid ?? "unknown"
                ])
            
            // Update local copy
            var updatedGame = game
            updatedGame.isVisible = !game.isVisible
            return updatedGame
            
        }, onSuccess: { [weak self] (updatedGame: Game) in
            if updatedGame.isVisible {
                self?.updateItem(updatedGame)
            } else {
                self?.removeItem(updatedGame)
            }
            print("👁️ Toggled visibility for game \(game.id)")
        })
    }
    
    /// Sets a game as featured (admin only)
    func setFeaturedGame(_ game: Game) async {
        await executeAsync({
            let db = Firestore.firestore()
            
            // First, remove featured status from all other games
            for existingGame in self.items {
                if existingGame.manuallyFeatured && existingGame.id != game.id {
                    try await db.collection("games").document(existingGame.id)
                        .updateData([
                            "isFeatured": false,
                            "manuallyFeatured": false,
                            "lastUpdatedAt": Timestamp(date: Date()),
                            "lastUpdatedBy": Auth.auth().currentUser?.uid ?? "unknown"
                        ])
                }
            }
            
            // Then set the new featured game
            try await db.collection("games").document(game.id)
                .updateData([
                    "isFeatured": true,
                    "manuallyFeatured": true,
                    "lastUpdatedAt": Timestamp(date: Date()),
                    "lastUpdatedBy": Auth.auth().currentUser?.uid ?? "unknown"
                ])
            
            return game
            
        }, onSuccess: { [weak self] (_: Game) in
            // Update all games in the list
            self?.items = self?.items.map { existingGame in
                var updatedGame = existingGame
                if existingGame.id == game.id {
                    updatedGame.manuallyFeatured = true
                    updatedGame.isFeatured = true
                } else {
                    updatedGame.manuallyFeatured = false
                    updatedGame.isFeatured = false
                }
                return updatedGame
            } ?? []
            
            self?.updateFeaturedGame()
            print("⭐️ Set featured game: \(game.id)")
        })
    }
    
    // MARK: - Cleanup
    
    deinit {
        print("🧹 Cleaning up GamesViewModel")
        refreshTask?.cancel()
    }
}
